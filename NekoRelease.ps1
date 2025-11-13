[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, HelpMessage="Repository path (folder containing .git)")]
    [string]$RepositoryPath = (Get-Location).Path,
    
    [Parameter(Mandatory=$false, HelpMessage="Version number")]
    [string]$Version = "",
    
    [Parameter(Mandatory=$false, HelpMessage="Package managers to generate files for")]
    [ValidateSet("Chocolatey", "Scoop", "Winget", "vcpkg", "Conan", "Meson", "Buckaroo", "CPM", "All")]
    [string[]]$PackageManagers = @(),
    
    [Parameter(Mandatory=$false, HelpMessage="Package file output paths")]
    [hashtable]$OutputPaths = @{},
    
    [Parameter(Mandatory=$false, HelpMessage="Repository URL (e.g., https://github.com/user/repo)")]
    [string]$RepositoryUrl = "",
    
    [Parameter(Mandatory=$false, HelpMessage="Update mode: update existing files or create new ones")]
    [ValidateSet("Auto", "Update", "Create")]
    [string]$Mode = "Auto",
    
    [Parameter(Mandatory=$false, HelpMessage="Package name (default: detected from repository)")]
    [string]$PackageName = "",
    
    [Parameter(Mandatory=$false, HelpMessage="Configuration file path")]
    [string]$ConfigFile = ".nekorelease.json",
    
    [Parameter(Mandatory=$false, HelpMessage="Dry run mode - preview changes without executing")]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false, HelpMessage="Enable verbose logging to file")]
    [string]$LogFile = "",
    
    [Parameter(Mandatory=$false, HelpMessage="Skip Git tag creation (only generate package files)")]
    [switch]$SkipGitTag,
    
    [Parameter(Mandatory=$false, HelpMessage="Skip Release creation (only create tag)")]
    [switch]$SkipRelease
)

# ================================================================================
# NekoRelease - Fast Release Tool for Neko Ecosystem
# ================================================================================

$ErrorActionPreference = "Stop"

# Global script state
$script:DryRunMode = $DryRun
$script:LogFilePath = $LogFile

# Color output functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
    Write-Log $Message
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" "Green"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ $Message" "Cyan"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠ $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" "Red"
}

function Write-Log {
    param([string]$Message)
    
    if (-not [string]::IsNullOrWhiteSpace($script:LogFilePath)) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] $Message"
        Add-Content -Path $script:LogFilePath -Value $logEntry -Encoding UTF8
    }
}

function Write-DryRun {
    param([string]$Action)
    
    if ($script:DryRunMode) {
        Write-ColorOutput "[DRY RUN] $Action" "Magenta"
        return $true
    }
    return $false
}

# ================================================================================
# Configuration File Support
# ================================================================================

function Read-ConfigFile {
    param([string]$ConfigPath)
    
    if (-not (Test-Path $ConfigPath)) {
        Write-Info "No configuration file found at: $ConfigPath"
        return $null
    }
    
    Write-Info "Loading configuration from: $ConfigPath"
    
    try {
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        Write-Success "Configuration loaded successfully"
        return $config
    } catch {
        Write-Warning "Failed to parse configuration file: $_"
        return $null
    }
}

function Merge-ConfigWithParams {
    param(
        [object]$Config,
        [hashtable]$Params
    )
    
    if ($null -eq $Config) {
        return
    }
    
    # Merge configuration with command-line parameters
    # Command-line parameters take precedence
    
    if ($Config.packageName -and [string]::IsNullOrWhiteSpace($Params.PackageName)) {
        $script:PackageName = $Config.packageName
        Write-Info "Using package name from config: $script:PackageName"
    }
    
    if ($Config.repositoryUrl -and [string]::IsNullOrWhiteSpace($Params.RepositoryUrl)) {
        $script:RepositoryUrl = $Config.repositoryUrl
        Write-Info "Using repository URL from config: $script:RepositoryUrl"
    }
    
    if ($Config.packageManagers -and $Params.PackageManagers.Count -eq 0) {
        $script:PackageManagers = $Config.packageManagers
        Write-Info "Using package managers from config: $($script:PackageManagers -join ', ')"
    }
    
    if ($Config.mode -and $Params.Mode -eq "Auto") {
        $script:Mode = $Config.mode
        Write-Info "Using mode from config: $script:Mode"
    }
    
    if ($Config.outputPaths -and $Params.OutputPaths.Count -eq 0) {
        $script:OutputPaths = @{}
        foreach ($prop in $Config.outputPaths.PSObject.Properties) {
            $script:OutputPaths[$prop.Name] = $prop.Value
        }
        Write-Info "Using output paths from config"
    }
}

function Get-PackageName {
    param([string]$RepoUrl)
    
    if (-not [string]::IsNullOrWhiteSpace($script:PackageName)) {
        return $script:PackageName
    }
    
    # Try to extract package name from repository URL
    if ($RepoUrl -match '/([^/]+?)(?:\.git)?$') {
        $extracted = $Matches[1]
        Write-Info "Detected package name from repository: $extracted"
        return $extracted.ToLower()
    }
    
    # Fallback to directory name
    $dirName = Split-Path -Leaf (Get-Location).Path
    Write-Info "Using directory name as package name: $dirName"
    return $dirName.ToLower()
}

# ================================================================================
# Git Remote URL Detection
# ================================================================================

function Get-GitRemoteUrl {
    param([string]$RepoPath)
    
    Push-Location $RepoPath
    
    try {
        # Get the remote URL
        $remoteUrl = git config --get remote.origin.url 2>$null
        
        if ([string]::IsNullOrWhiteSpace($remoteUrl)) {
            Write-Warning "No Git remote URL found"
            return $null
        }
        
        # Convert SSH URL to HTTPS if needed
        # git@github.com:user/repo.git -> https://github.com/user/repo
        if ($remoteUrl -match "^git@([^:]+):(.+?)(?:\.git)?$") {
            $host = $Matches[1]
            $path = $Matches[2]
            $remoteUrl = "https://$host/$path"
        }
        # Remove .git suffix if present
        elseif ($remoteUrl -match "^(https?://.+?)(?:\.git)?$") {
            $remoteUrl = $Matches[1]
        }
        
        return $remoteUrl
        
    } finally {
        Pop-Location
    }
}

function Get-ReleaseCreationUrl {
    param(
        [string]$RepoUrl,
        [string]$TagVersion
    )
    
    # GitHub: https://github.com/user/repo/releases/new?tag=v1.0.0
    if ($RepoUrl -match "github\.com") {
        return "$RepoUrl/releases/new?tag=$TagVersion"
    }
    # GitLab: https://gitlab.com/user/repo/-/releases/new?tag_name=v1.0.0
    elseif ($RepoUrl -match "gitlab\.com") {
        return "$RepoUrl/-/releases/new?tag_name=$TagVersion"
    }
    # Gitea/Forgejo: https://gitea.com/user/repo/releases/new
    elseif ($RepoUrl -match "gitea|forgejo") {
        return "$RepoUrl/releases/new"
    }
    # Generic
    else {
        return "$RepoUrl/releases/new"
    }
}

# ================================================================================
# File Update Utilities
# ================================================================================

function Test-ShouldUpdateFile {
    param(
        [string]$FilePath,
        [string]$Mode
    )
    
    $fileExists = Test-Path $FilePath
    
    switch ($Mode) {
        "Auto" {
            return $fileExists
        }
        "Update" {
            if (-not $fileExists) {
                Write-Warning "Update mode specified but file does not exist: $FilePath"
                return $false
            }
            return $true
        }
        "Create" {
            if ($fileExists) {
                Write-Warning "Create mode specified but file already exists: $FilePath"
                Write-Info "Backing up existing file..."
                if (-not (Write-DryRun "Would backup: $FilePath -> $FilePath.backup")) {
                    Copy-Item -Path $FilePath -Destination "$FilePath.backup" -Force
                }
            }
            return $false
        }
    }
    
    return $false
}

function Update-JsonField {
    param(
        [string]$FilePath,
        [string]$Field,
        [string]$Value
    )
    
    $content = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
    $content.$Field = $Value
    $content | ConvertTo-Json -Depth 10 | Set-Content -Path $FilePath -Encoding UTF8
}

function Update-YamlField {
    param(
        [string]$FilePath,
        [string]$Pattern,
        [string]$Replacement
    )
    
    $content = Get-Content -Path $FilePath -Raw
    $content = $content -replace $Pattern, $Replacement
    Set-Content -Path $FilePath -Value $content -Encoding UTF8
}

function Update-FileContent {
    param(
        [string]$FilePath,
        [hashtable]$Replacements
    )
    
    $content = Get-Content -Path $FilePath -Raw
    
    foreach ($key in $Replacements.Keys) {
        $content = $content -replace $key, $Replacements[$key]
    }
    
    Set-Content -Path $FilePath -Value $content -Encoding UTF8
}

# ================================================================================
# Parameter Validation and Collection
# ================================================================================

function Get-UserInput {
    param(
        [string]$Prompt,
        [string]$Default = "",
        [bool]$Required = $true
    )
    
    $promptText = if ($Default) { "$Prompt [$Default]" } else { $Prompt }
    
    do {
        $input = Read-Host -Prompt $promptText
        
        if ([string]::IsNullOrWhiteSpace($input)) {
            if ($Default) {
                return $Default
            } elseif (-not $Required) {
                return ""
            } else {
                Write-Warning "This field is required"
            }
        } else {
            return $input
        }
    } while ($Required)
}

function Validate-Repository {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Error "Repository path does not exist: $Path"
        return $false
    }
    
    $gitPath = Join-Path $Path ".git"
    if (-not (Test-Path $gitPath)) {
        Write-Error "The specified path is not a Git repository: $Path"
        return $false
    }
    
    return $true
}

# ================================================================================
# Git Operations
# ================================================================================

function Publish-GitTag {
    param(
        [string]$RepoPath,
        [string]$TagVersion
    )
    
    Write-Info "Switching to repository directory: $RepoPath"
    Push-Location $RepoPath
    
    try {
        # Check Git status
        $status = git status --porcelain
        if ($status) {
            Write-Warning "Repository has uncommitted changes, it's recommended to commit first"
            $continue = Read-Host "Continue anyway? (y/n)"
            if ($continue -ne 'y') {
                return $false
            }
        }
        
        # Create tag
        Write-Info "Creating Git tag: $TagVersion"
        git tag -a $TagVersion -m "Release $TagVersion"
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create tag"
            return $false
        }
        
        Write-Success "Tag created successfully: $TagVersion"
        
        # Push tag
        Write-Info "Pushing tag to remote repository..."
        git push origin $TagVersion
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to push tag"
            return $false
        }
        
        Write-Success "Tag pushed successfully"
        return $true
        
    } finally {
        Pop-Location
    }
}

function Create-GitHubRelease {
    param(
        [string]$RepoPath,
        [string]$TagVersion,
        [string]$RepoUrl
    )
    
    Write-Info "Preparing to create release: $TagVersion"
    
    # Check if gh CLI is installed
    $ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
    
    if ($ghInstalled) {
        Write-Info "GitHub CLI detected, attempting to create release..."
        
        Push-Location $RepoPath
        
        try {
            # Create Release
            gh release create $TagVersion --title "Release $TagVersion" --generate-notes
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "GitHub Release created successfully"
                return $true
            } else {
                Write-Warning "Failed to create release via GitHub CLI"
            }
            
        } finally {
            Pop-Location
        }
    }
    
    # Fallback: provide manual URL
    if ($RepoUrl) {
        $releaseUrl = Get-ReleaseCreationUrl -RepoUrl $RepoUrl -TagVersion $TagVersion
        
        Write-ColorOutput "`n========================================" "Yellow"
        Write-Info "Please create the release manually:"
        Write-ColorOutput "  $releaseUrl" "Cyan"
        Write-ColorOutput "========================================`n" "Yellow"
        
        $openBrowser = Read-Host "Open URL in browser? (y/n)"
        if ($openBrowser -eq 'y') {
            Start-Process $releaseUrl
        }
        
        $confirm = Read-Host "Press Enter after creating the release (or 'skip' to skip hash calculation)"
        return ($confirm -ne 'skip')
    } else {
        Write-Warning "GitHub CLI not installed and no repository URL provided"
        Write-Info "Install GitHub CLI: https://cli.github.com/"
        Write-Info "Or provide repository URL with -RepositoryUrl parameter"
        return $false
    }
}

# ================================================================================
# Hash Calculation
# ================================================================================

function Get-ReleaseAssets {
    param(
        [string]$RepoPath,
        [string]$TagVersion
    )
    
    Push-Location $RepoPath
    
    try {
        Write-Info "Getting release asset list..."
        
        $assets = gh release view $TagVersion --json assets --jq '.assets[] | {name: .name, url: .url}'
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to get release assets"
            return @()
        }
        
        return $assets | ConvertFrom-Json
        
    } finally {
        Pop-Location
    }
}

function Calculate-FileHash {
    param(
        [string]$FilePath,
        [string]$Algorithm = "SHA256"
    )
    
    Write-Info "Calculating file hash: $FilePath"
    
    $hash = Get-FileHash -Path $FilePath -Algorithm $Algorithm
    
    Write-Success "Hash: $($hash.Hash)"
    
    return $hash.Hash
}

function Download-AndHashReleaseAssets {
    param(
        [string]$RepoPath,
        [string]$TagVersion,
        [string]$DownloadPath = (Join-Path $PWD "downloads")
    )
    
    if (-not (Test-Path $DownloadPath)) {
        New-Item -ItemType Directory -Path $DownloadPath -Force | Out-Null
    }
    
    Push-Location $RepoPath
    
    try {
        Write-Info "Downloading and calculating hashes for release assets..."
        
        # Download all assets
        gh release download $TagVersion -D $DownloadPath
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to download release assets"
            return @{}
        }
        
        # Calculate hashes
        $hashes = @{}
        $files = Get-ChildItem -Path $DownloadPath -File
        
        foreach ($file in $files) {
            $hash = Calculate-FileHash -FilePath $file.FullName
            $hashes[$file.Name] = $hash
        }
        
        return $hashes
        
    } finally {
        Pop-Location
    }
}

# ================================================================================
# Package Manager File Generation
# ================================================================================

function Generate-ChocolateyPackage {
    param(
        [string]$Version,
        [hashtable]$Hashes,
        [string]$OutputPath
    )
    
    Write-Info "Generating Chocolatey package configuration..."
    
    $nuspecPath = Join-Path $OutputPath "nekorelease.nuspec"
    $installScriptPath = Join-Path $OutputPath "tools\chocolateyinstall.ps1"
    
    if (-not (Test-Path (Join-Path $OutputPath "tools"))) {
        New-Item -ItemType Directory -Path (Join-Path $OutputPath "tools") -Force | Out-Null
    }
    
    # Generate .nuspec
    $nuspecContent = @"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>nekorelease</id>
    <version>$Version</version>
    <title>NekoRelease</title>
    <authors>Neko Team</authors>
    <description>Fast release tool for Neko ecosystem</description>
    <tags>neko release automation</tags>
  </metadata>
</package>
"@
    
    Set-Content -Path $nuspecPath -Value $nuspecContent -Encoding UTF8
    
    Write-Success "Chocolatey package configuration generated: $OutputPath"
}

function Generate-ScoopManifest {
    param(
        [string]$Version,
        [hashtable]$Hashes,
        [string]$OutputPath,
        [string]$DownloadUrl = ""
    )
    
    Write-Info "Generating Scoop manifest..."
    
    $manifestPath = Join-Path $OutputPath "nekorelease.json"
    
    # Get first hash if available
    $hash = if ($Hashes.Count -gt 0) { $Hashes.Values | Select-Object -First 1 } else { "REPLACE_WITH_HASH" }
    
    $manifest = @{
        version = $Version
        description = "Fast release tool for Neko ecosystem"
        homepage = "https://github.com/yourusername/NekoRelease"
        license = "MIT"
        url = if ($DownloadUrl) { $DownloadUrl } else { "REPLACE_WITH_DOWNLOAD_URL" }
        hash = $hash
        bin = "NekoRelease.ps1"
    }
    
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding UTF8
    
    Write-Success "Scoop manifest generated: $manifestPath"
}

function Generate-WingetManifest {
    param(
        [string]$Version,
        [hashtable]$Hashes,
        [string]$OutputPath,
        [string]$DownloadUrl = ""
    )
    
    Write-Info "Generating Winget manifest..."
    
    $manifestPath = Join-Path $OutputPath "nekorelease.yaml"
    
    # Get first hash if available
    $hash = if ($Hashes.Count -gt 0) { $Hashes.Values | Select-Object -First 1 } else { "REPLACE_WITH_HASH" }
    
    $manifestContent = @"
PackageIdentifier: Neko.NekoRelease
PackageVersion: $Version
PackageName: NekoRelease
Publisher: Neko Team
License: MIT
ShortDescription: Fast release tool for Neko ecosystem
Installers:
  - Architecture: x64
    InstallerType: portable
    InstallerUrl: $(if ($DownloadUrl) { $DownloadUrl } else { "REPLACE_WITH_DOWNLOAD_URL" })
    InstallerSha256: $hash
ManifestType: singleton
ManifestVersion: 1.0.0
"@
    
    Set-Content -Path $manifestPath -Value $manifestContent -Encoding UTF8
    
    Write-Success "Winget manifest generated: $manifestPath"
}

function Generate-VcpkgPort {
    param(
        [string]$PackageName,
        [string]$Version,
        [hashtable]$Hashes,
        [string]$OutputPath,
        [string]$DownloadUrl = "",
        [string]$RepoUrl = ""
    )
    
    Write-Info "Generating vcpkg port files..."
    
    # Create port directory structure
    $portDir = Join-Path $OutputPath $PackageName
    if (-not (Test-Path $portDir)) {
        New-Item -ItemType Directory -Path $portDir -Force | Out-Null
    }
    
    # Get first hash if available
    $hash = if ($Hashes.Count -gt 0) { $Hashes.Values | Select-Object -First 1 } else { "0000000000000000000000000000000000000000000000000000000000000000" }
    
    # Clean version (remove 'v' prefix for vcpkg)
    $cleanVersion = $Version -replace '^v', ''
    
    # Generate vcpkg.json (manifest)
    $vcpkgJsonPath = Join-Path $portDir "vcpkg.json"
    
    $shouldUpdateJson = Test-ShouldUpdateFile -FilePath $vcpkgJsonPath -Mode $script:Mode
    
    if ($shouldUpdateJson) {
        # Update existing vcpkg.json
        $existingJson = Get-Content -Path $vcpkgJsonPath -Raw | ConvertFrom-Json
        $existingJson.version = $cleanVersion
        if ($RepoUrl) {
            $existingJson.homepage = $RepoUrl
        }
        $existingJson | ConvertTo-Json -Depth 10 | Set-Content -Path $vcpkgJsonPath -Encoding UTF8
        Write-Info "  - vcpkg.json (updated)"
    } else {
        # Create new vcpkg.json
        $vcpkgJson = @{
            name = $PackageName
            version = $cleanVersion
            description = "Fast release tool for Neko ecosystem"
            homepage = if ($RepoUrl) { $RepoUrl } else { "https://github.com/yourusername/NekoRelease" }
            license = "MIT"
            dependencies = @()
        }
        $vcpkgJson | ConvertTo-Json -Depth 10 | Set-Content -Path $vcpkgJsonPath -Encoding UTF8
        Write-Info "  - vcpkg.json (created)"
    }
    
    # Generate portfile.cmake
    $portfilePath = Join-Path $portDir "portfile.cmake"
    
    $shouldUpdatePortfile = Test-ShouldUpdateFile -FilePath $portfilePath -Mode $script:Mode
    
    # Extract repo info from URL
    $repoPath = "yourusername/nekorelease"
    if ($RepoUrl -match 'github\.com/([^/]+/[^/]+?)(?:\.git)?$') {
        $repoPath = $Matches[1]
    }
    
    if ($shouldUpdatePortfile) {
        # Update existing portfile.cmake
        Update-FileContent -FilePath $portfilePath -Replacements @{
            "REF\s+\S+" = "REF $Version"
            "SHA512\s+\S+" = "SHA512 $hash"
        }
        Write-Info "  - portfile.cmake (updated)"
    } else {
        # Create new portfile.cmake
        $portfileContent = @"
vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO $repoPath
    REF $Version
    SHA512 $hash
    HEAD_REF main
)

vcpkg_cmake_configure(
    SOURCE_PATH `${SOURCE_PATH}
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup()

file(REMOVE_RECURSE "`${CURRENT_PACKAGES_DIR}/debug/include")
file(INSTALL "`${SOURCE_PATH}/LICENSE" DESTINATION "`${CURRENT_PACKAGES_DIR}/share/`${PORT}" RENAME copyright)
"@
        
        Set-Content -Path $portfilePath -Value $portfileContent -Encoding UTF8
        Write-Info "  - portfile.cmake (created)"
    }
    
    Write-Success "vcpkg port files generated: $portDir"
}

function Generate-ConanRecipe {
    param(
        [string]$PackageName,
        [string]$Version,
        [hashtable]$Hashes,
        [string]$OutputPath,
        [string]$DownloadUrl = "",
        [string]$RepoUrl = ""
    )
    
    Write-Info "Generating Conan recipe..."
    
    # Get first hash if available
    $hash = if ($Hashes.Count -gt 0) { $Hashes.Values | Select-Object -First 1 } else { "REPLACE_WITH_HASH" }
    
    # Clean version (remove 'v' prefix)
    $cleanVersion = $Version -replace '^v', ''
    
    # Generate class name from package name (PascalCase)
    $className = ($PackageName -split '-' | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join ''
    
    # Generate conanfile.py
    $conanfilePath = Join-Path $OutputPath "conanfile.py"
    $conanfileContent = @"
from conan import ConanFile
from conan.tools.cmake import CMake, CMakeToolchain, cmake_layout
from conan.tools.files import get, copy
import os


class ${className}Conan(ConanFile):
    name = "$PackageName"
    version = "$cleanVersion"
    description = "Fast release tool for Neko ecosystem"
    license = "MIT"
    url = "$(if ($RepoUrl) { $RepoUrl } else { 'https://github.com/yourusername/NekoRelease' })"
    homepage = "$(if ($RepoUrl) { $RepoUrl } else { 'https://github.com/yourusername/NekoRelease' })"
    topics = ("release", "automation", "neko")
    
    settings = "os", "compiler", "build_type", "arch"
    options = {
        "shared": [True, False],
        "fPIC": [True, False]
    }
    default_options = {
        "shared": False,
        "fPIC": True
    }
    
    exports_sources = "CMakeLists.txt", "src/*", "include/*", "LICENSE"
    
    def config_options(self):
        if self.settings.os == "Windows":
            del self.options.fPIC
    
    def configure(self):
        if self.options.shared:
            del self.options.fPIC
    
    def layout(self):
        cmake_layout(self)
    
    def source(self):
        get(self, **self.conan_data["sources"][self.version], strip_root=True)
    
    def generate(self):
        tc = CMakeToolchain(self)
        tc.generate()
    
    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()
    
    def package(self):
        copy(self, "LICENSE", src=self.source_folder, dst=os.path.join(self.package_folder, "licenses"))
        cmake = CMake(self)
        cmake.install()
    
    def package_info(self):
        self.cpp_info.libs = ["nekorelease"]
"@
    
    $shouldUpdateConanfile = Test-ShouldUpdateFile -FilePath $conanfilePath -Mode $script:Mode
    
    if ($shouldUpdateConanfile) {
        # Update existing conanfile.py
        Update-FileContent -FilePath $conanfilePath -Replacements @{
            'version\s*=\s*"[^"]*"' = "version = `"$cleanVersion`""
            'url\s*=\s*"[^"]*"' = "url = `"$(if ($RepoUrl) { $RepoUrl } else { 'https://github.com/yourusername/NekoRelease' })`""
            'homepage\s*=\s*"[^"]*"' = "homepage = `"$(if ($RepoUrl) { $RepoUrl } else { 'https://github.com/yourusername/NekoRelease' })`""
        }
        Write-Info "  - conanfile.py (updated)"
    } else {
        # Create new conanfile.py
        Set-Content -Path $conanfilePath -Value $conanfileContent -Encoding UTF8
        Write-Info "  - conanfile.py (created)"
    }
    
    # Generate conandata.yml
    $conandataPath = Join-Path $OutputPath "conandata.yml"
    
    $shouldUpdateConandata = Test-ShouldUpdateFile -FilePath $conandataPath -Mode $script:Mode
    
    if ($shouldUpdateConandata) {
        # Update existing conandata.yml - add new version entry
        $existingContent = Get-Content -Path $conandataPath -Raw
        $newEntry = @"

  "$cleanVersion":
    url: "$(if ($DownloadUrl) { $DownloadUrl } else { "https://github.com/yourusername/NekoRelease/archive/refs/tags/$Version.tar.gz" })"
    sha256: "$hash"
"@
        
        # Check if version already exists
        if ($existingContent -match "`"$cleanVersion`"") {
            # Update existing version entry
            Update-FileContent -FilePath $conandataPath -Replacements @{
                "`"$cleanVersion`":\s*\n\s*url:\s*`"[^`"]*`"" = "`"$cleanVersion`":`n    url: `"$(if ($DownloadUrl) { $DownloadUrl } else { "https://github.com/yourusername/NekoRelease/archive/refs/tags/$Version.tar.gz" })`""
                "sha256:\s*`"[^`"]*`"" = "sha256: `"$hash`""
            }
        } else {
            # Append new version entry
            Add-Content -Path $conandataPath -Value $newEntry
        }
        Write-Info "  - conandata.yml (updated)"
    } else {
        # Create new conandata.yml
        $conandataContent = @"
sources:
  "$cleanVersion":
    url: "$(if ($DownloadUrl) { $DownloadUrl } else { "https://github.com/yourusername/NekoRelease/archive/refs/tags/$Version.tar.gz" })"
    sha256: "$hash"
"@
        Set-Content -Path $conandataPath -Value $conandataContent -Encoding UTF8
        Write-Info "  - conandata.yml (created)"
    }
    
    Write-Success "Conan recipe generated: $OutputPath"
}

function Generate-MesonWrap {
    param(
        [string]$Version,
        [hashtable]$Hashes,
        [string]$OutputPath,
        [string]$DownloadUrl = "",
        [string]$RepoUrl = ""
    )
    
    Write-Info "Generating Meson WrapDB files..."
    
    # Get first hash if available
    $hash = if ($Hashes.Count -gt 0) { $Hashes.Values | Select-Object -First 1 } else { "REPLACE_WITH_HASH" }
    
    # Clean version
    $cleanVersion = $Version -replace '^v', ''
    
    # Generate .wrap file
    $wrapPath = Join-Path $OutputPath "nekorelease.wrap"
    
    # Extract repo info from URL
    $repoMatch = $RepoUrl -match 'github\.com/([^/]+)/([^/]+)'
    $organization = if ($repoMatch) { $Matches[1] } else { "yourusername" }
    $repository = if ($repoMatch) { $Matches[2] } else { "nekorelease" }
    
    $wrapContent = @"
[wrap-file]
directory = nekorelease-$cleanVersion

source_url = $(if ($DownloadUrl) { $DownloadUrl } else { "https://github.com/$organization/$repository/archive/refs/tags/$Version.tar.gz" })
source_filename = nekorelease-$cleanVersion.tar.gz
source_hash = $hash

[provide]
nekorelease = nekorelease_dep
"@
    
    Set-Content -Path $wrapPath -Value $wrapContent -Encoding UTF8
    
    # Generate meson.build (basic template)
    $mesonBuildPath = Join-Path $OutputPath "meson.build"
    
    $shouldUpdate = Test-ShouldUpdateFile -FilePath $mesonBuildPath -Mode $script:Mode
    
    if (-not $shouldUpdate) {
        $mesonBuildContent = @"
project('nekorelease', 'cpp',
  version : '$cleanVersion',
  license : 'MIT',
  default_options : ['cpp_std=c++17']
)

# Dependencies
# Add your dependencies here

# Library sources
nekorelease_sources = files(
  # Add your source files here
)

# Build library
nekorelease_lib = library('nekorelease',
  nekorelease_sources,
  install : true
)

# Declare dependency
nekorelease_dep = declare_dependency(
  link_with : nekorelease_lib,
  include_directories : include_directories('include')
)

# Install headers
install_subdir('include/nekorelease',
  install_dir : get_option('includedir')
)
"@
        
        Set-Content -Path $mesonBuildPath -Value $mesonBuildContent -Encoding UTF8
        Write-Info "  - meson.build (template created)"
    } else {
        Update-FileContent -FilePath $mesonBuildPath -Replacements @{
            "version\s*:\s*'[^']*'" = "version : '$cleanVersion'"
        }
        Write-Info "  - meson.build (version updated)"
    }
    
    Write-Success "Meson WrapDB files generated: $OutputPath"
    Write-Info "  - nekorelease.wrap"
}

function Generate-BuckarooManifest {
    param(
        [string]$Version,
        [hashtable]$Hashes,
        [string]$OutputPath,
        [string]$RepoUrl = ""
    )
    
    Write-Info "Generating Buckaroo manifest..."
    
    # Clean version
    $cleanVersion = $Version -replace '^v', ''
    
    # Generate buckaroo.json
    $buckarooPath = Join-Path $OutputPath "buckaroo.json"
    
    $shouldUpdate = Test-ShouldUpdateFile -FilePath $buckarooPath -Mode $script:Mode
    
    $buckarooContent = @{
        name = "nekorelease"
        version = $cleanVersion
        license = "MIT"
        dependencies = @{}
    }
    
    if ($shouldUpdate) {
        # Read existing and update version
        $existing = Get-Content -Path $buckarooPath -Raw | ConvertFrom-Json
        $existing.version = $cleanVersion
        $existing | ConvertTo-Json -Depth 10 | Set-Content -Path $buckarooPath -Encoding UTF8
        Write-Info "  - buckaroo.json (updated)"
    } else {
        $buckarooContent | ConvertTo-Json -Depth 10 | Set-Content -Path $buckarooPath -Encoding UTF8
        Write-Info "  - buckaroo.json (created)"
    }
    
    # Generate BUCK file (template)
    $buckPath = Join-Path $OutputPath "BUCK"
    
    if (-not (Test-Path $buckPath)) {
        $buckContent = @"
cxx_library(
  name = 'nekorelease',
  header_namespace = 'nekorelease',
  exported_headers = subdir_glob([
    ('include', '**/*.hpp'),
    ('include', '**/*.h'),
  ]),
  srcs = glob(['src/**/*.cpp']),
  visibility = [
    'PUBLIC',
  ],
)
"@
        
        Set-Content -Path $buckPath -Value $buckContent -Encoding UTF8
        Write-Info "  - BUCK (created)"
    }
    
    Write-Success "Buckaroo manifest generated: $OutputPath"
}

function Generate-CPMPackage {
    param(
        [string]$Version,
        [hashtable]$Hashes,
        [string]$OutputPath,
        [string]$RepoUrl = ""
    )
    
    Write-Info "Generating CPM (CMake Package Manager) configuration..."
    
    # Clean version
    $cleanVersion = $Version -replace '^v', ''
    
    # Generate CPM.cmake snippet
    $cpmPath = Join-Path $OutputPath "CPMAddNekoRelease.cmake"
    
    # Get first hash if available
    $hash = if ($Hashes.Count -gt 0) { $Hashes.Values | Select-Object -First 1 } else { "REPLACE_WITH_HASH" }
    
    $cpmContent = @"
# CPM.cmake configuration for NekoRelease
# Include this file in your CMakeLists.txt

CPMAddPackage(
  NAME nekorelease
  VERSION $cleanVersion
  GITHUB_REPOSITORY $(if ($RepoUrl -match 'github\.com/(.+)') { $Matches[1] } else { "yourusername/nekorelease" })
  GIT_TAG $Version
  OPTIONS
    "BUILD_TESTS OFF"
    "BUILD_EXAMPLES OFF"
)

# Alternative: Use URL with hash verification
# CPMAddPackage(
#   NAME nekorelease
#   VERSION $cleanVersion
#   URL $(if ($RepoUrl) { "$RepoUrl/archive/refs/tags/$Version.tar.gz" } else { "https://github.com/yourusername/nekorelease/archive/refs/tags/$Version.tar.gz" })
#   URL_HASH SHA256=$hash
# )
"@
    
    Set-Content -Path $cpmPath -Value $cpmContent -Encoding UTF8
    
    # Generate FindNekoRelease.cmake (optional)
    $findPath = Join-Path $OutputPath "FindNekoRelease.cmake"
    
    if (-not (Test-Path $findPath)) {
        $findContent = @"
# FindNekoRelease.cmake
# Finds the NekoRelease library

find_package(PkgConfig)
pkg_check_modules(PC_NEKORELEASE QUIET nekorelease)

find_path(NEKORELEASE_INCLUDE_DIR
  NAMES nekorelease/nekorelease.hpp
  PATHS `${PC_NEKORELEASE_INCLUDE_DIRS}
  PATH_SUFFIXES nekorelease
)

find_library(NEKORELEASE_LIBRARY
  NAMES nekorelease
  PATHS `${PC_NEKORELEASE_LIBRARY_DIRS}
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(NekoRelease
  REQUIRED_VARS NEKORELEASE_LIBRARY NEKORELEASE_INCLUDE_DIR
  VERSION_VAR PC_NEKORELEASE_VERSION
)

if(NEKORELEASE_FOUND)
  set(NEKORELEASE_LIBRARIES `${NEKORELEASE_LIBRARY})
  set(NEKORELEASE_INCLUDE_DIRS `${NEKORELEASE_INCLUDE_DIR})
  
  if(NOT TARGET NekoRelease::NekoRelease)
    add_library(NekoRelease::NekoRelease UNKNOWN IMPORTED)
    set_target_properties(NekoRelease::NekoRelease PROPERTIES
      IMPORTED_LOCATION "`${NEKORELEASE_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "`${NEKORELEASE_INCLUDE_DIR}"
    )
  endif()
endif()

mark_as_advanced(NEKORELEASE_INCLUDE_DIR NEKORELEASE_LIBRARY)
"@
        
        Set-Content -Path $findPath -Value $findContent -Encoding UTF8
        Write-Info "  - FindNekoRelease.cmake (created)"
    }
    
    Write-Success "CPM configuration generated: $OutputPath"
    Write-Info "  - CPMAddNekoRelease.cmake"
}

function Generate-PackageFiles {
    param(
        [string]$Version,
        [hashtable]$Hashes,
        [string[]]$Managers,
        [hashtable]$OutputPaths
    )
    
    foreach ($manager in $Managers) {
        $outputPath = if ($OutputPaths.ContainsKey($manager)) {
            $OutputPaths[$manager]
        } else {
            Join-Path $PWD "packages\$manager"
        }
        
        if (-not (Test-Path $outputPath)) {
            New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
        }
        
        switch ($manager) {
            "Chocolatey" {
                Generate-ChocolateyPackage -Version $Version -Hashes $Hashes -OutputPath $outputPath
            }
            "Scoop" {
                Generate-ScoopManifest -Version $Version -Hashes $Hashes -OutputPath $outputPath
            }
            "Winget" {
                Generate-WingetManifest -Version $Version -Hashes $Hashes -OutputPath $outputPath
            }
            "vcpkg" {
                Generate-VcpkgPort -PackageName $script:PackageName -Version $Version -Hashes $Hashes -OutputPath $outputPath -RepoUrl $script:RepositoryUrl
            }
            "Conan" {
                Generate-ConanRecipe -PackageName $script:PackageName -Version $Version -Hashes $Hashes -OutputPath $outputPath -RepoUrl $script:RepositoryUrl
            }
            "Meson" {
                Generate-MesonWrap -Version $Version -Hashes $Hashes -OutputPath $outputPath -RepoUrl $script:RepositoryUrl
            }
            "Buckaroo" {
                Generate-BuckarooManifest -Version $Version -Hashes $Hashes -OutputPath $outputPath -RepoUrl $script:RepositoryUrl
            }
            "CPM" {
                Generate-CPMPackage -Version $Version -Hashes $Hashes -OutputPath $outputPath -RepoUrl $script:RepositoryUrl
            }
        }
    }
}

# ================================================================================
# Main Program
# ================================================================================

function Main {
    Write-ColorOutput "`n========================================" "Magenta"
    Write-ColorOutput "  NekoRelease - Fast Release Tool" "Magenta"
    Write-ColorOutput "========================================`n" "Magenta"
    
    # Initialize logging
    if (-not [string]::IsNullOrWhiteSpace($LogFile)) {
        $script:LogFilePath = $LogFile
        Write-Info "Logging to: $LogFile"
        Write-Log "=== NekoRelease Session Started ==="
    }
    
    # Dry run mode
    if ($script:DryRunMode) {
        Write-ColorOutput "`n🔍 DRY RUN MODE ENABLED - No changes will be made`n" "Magenta"
    }
    
    # Load configuration file
    $configPath = if ([System.IO.Path]::IsPathRooted($ConfigFile)) {
        $ConfigFile
    } else {
        Join-Path $RepositoryPath $ConfigFile
    }
    
    $config = Read-ConfigFile -ConfigPath $configPath
    
    # Merge config with parameters
    $params = @{
        PackageName = $PackageName
        RepositoryUrl = $RepositoryUrl
        PackageManagers = $PackageManagers
        Mode = $Mode
        OutputPaths = $OutputPaths
    }
    
    Merge-ConfigWithParams -Config $config -Params $params
    
    # Validate and collect repository path
    if ([string]::IsNullOrWhiteSpace($RepositoryPath)) {
        $RepositoryPath = Get-UserInput -Prompt "Repository path" -Default (Get-Location).Path
    }
    
    if (-not (Validate-Repository -Path $RepositoryPath)) {
        exit 1
    }
    
    Write-Success "Repository path: $RepositoryPath"
    
    # Get or collect repository URL
    if ([string]::IsNullOrWhiteSpace($script:RepositoryUrl)) {
        $detectedUrl = Get-GitRemoteUrl -RepoPath $RepositoryPath
        
        if ($detectedUrl) {
            Write-Success "Detected repository URL: $detectedUrl"
            $script:RepositoryUrl = $detectedUrl
        } else {
            $script:RepositoryUrl = Get-UserInput -Prompt "Repository URL (e.g., https://github.com/user/repo)" -Required $false
        }
    }
    
    # Collect version number
    if ([string]::IsNullOrWhiteSpace($Version)) {
        $Version = Get-UserInput -Prompt "Version number (e.g., v1.0.0)"
    }
    
    Write-Success "Version: $Version"
    
    # Get package name
    $script:PackageName = Get-PackageName -RepoUrl $script:RepositoryUrl
    Write-Success "Package name: $script:PackageName"
    
    # Collect package manager selection
    if ($PackageManagers.Count -eq 0) {
        Write-Info "`nAvailable package managers:"
        Write-Host "  1. Chocolatey (Windows)"
        Write-Host "  2. Scoop (Windows)"
        Write-Host "  3. Winget (Windows)"
        Write-Host "  4. vcpkg (C++)"
        Write-Host "  5. Conan (C++)"
        Write-Host "  6. Meson WrapDB (C++)"
        Write-Host "  7. Buckaroo (C++)"
        Write-Host "  8. CPM (CMake Package Manager)"
        Write-Host "  9. All"
        
        $choice = Get-UserInput -Prompt "Select package managers (comma-separated numbers, or Enter to skip)" -Required $false
        
        if (-not [string]::IsNullOrWhiteSpace($choice)) {
            $choices = $choice -split ',' | ForEach-Object { $_.Trim() }
            
            foreach ($c in $choices) {
                switch ($c) {
                    "1" { $PackageManagers += "Chocolatey" }
                    "2" { $PackageManagers += "Scoop" }
                    "3" { $PackageManagers += "Winget" }
                    "4" { $PackageManagers += "vcpkg" }
                    "5" { $PackageManagers += "Conan" }
                    "6" { $PackageManagers += "Meson" }
                    "7" { $PackageManagers += "Buckaroo" }
                    "8" { $PackageManagers += "CPM" }
                    "9" { $PackageManagers = @("Chocolatey", "Scoop", "Winget", "vcpkg", "Conan", "Meson", "Buckaroo", "CPM"); break }
                }
            }
        }
    }
    
    # Set Mode for file operations
    $script:Mode = $Mode
    
    # Step 1: Publish Git Tag (unless skipped)
    $tagSuccess = $true
    if (-not $SkipGitTag) {
        Write-Info "`n[Step 1/3] Publishing Git tag"
        
        if (Write-DryRun "Would create and push Git tag: $Version") {
            $tagSuccess = $true
        } else {
            $tagSuccess = Publish-GitTag -RepoPath $RepositoryPath -TagVersion $Version
            
            if (-not $tagSuccess) {
                Write-Error "Publishing failed"
                exit 1
            }
        }
    } else {
        Write-Info "`n[Step 1/3] Skipping Git tag creation"
    }
    
    # Step 2: Create GitHub Release (unless skipped)
    $releaseSuccess = $false
    if (-not $SkipRelease -and $tagSuccess) {
        Write-Info "`n[Step 2/3] Creating release"
        
        if (Write-DryRun "Would create GitHub/GitLab release for: $Version") {
            $releaseSuccess = $false  # Skip download in dry run
        } else {
            $releaseSuccess = Create-GitHubRelease -RepoPath $RepositoryPath -TagVersion $Version -RepoUrl $script:RepositoryUrl
        }
    } else {
        Write-Info "`n[Step 2/3] Skipping release creation"
    }
    # Step 3: Download and calculate hashes
    $hashes = @{}
    if ($releaseSuccess) {
        Write-Info "`n[Step 3/3] Downloading and calculating hashes"
        $downloadPath = Join-Path $PWD "downloads\$Version"
        $hashes = Download-AndHashReleaseAssets -RepoPath $RepositoryPath -TagVersion $Version -DownloadPath $downloadPath
        
        if ($hashes.Count -gt 0) {
            Write-Success "`nHash calculation completed:"
            foreach ($file in $hashes.Keys) {
                Write-Host "  $file : $($hashes[$file])" -ForegroundColor Gray
            }
        }
    } else {
        Write-Warning "Skipping hash calculation (no release created)"
    }
    
    # Step 4: Generate package manager files
    if ($PackageManagers.Count -gt 0) {
        Write-Info "`nGenerating package manager files..."
        
        if (Write-DryRun "Would generate package files for: $($PackageManagers -join ', ')") {
            foreach ($manager in $PackageManagers) {
                $outputPath = if ($OutputPaths.ContainsKey($manager)) {
                    $OutputPaths[$manager]
                } else {
                    Join-Path $PWD "packages\$manager"
                }
                Write-Info "  - $manager -> $outputPath"
            }
        } else {
            Generate-PackageFiles -Version $Version -Hashes $hashes -Managers $PackageManagers -OutputPaths $OutputPaths
        }
    }
    
    Write-ColorOutput "`n========================================" "Green"
    if ($script:DryRunMode) {
        Write-ColorOutput "🔍 DRY RUN COMPLETED - No changes were made" "Magenta"
    } else {
        Write-Success "Release completed!"
    }
    Write-ColorOutput "========================================`n" "Green"
    
    # Display summary
    if ($script:RepositoryUrl) {
        $releaseUrl = "$($script:RepositoryUrl)/releases/tag/$Version"
        Write-Info "Release URL: $releaseUrl"
    }
}

# Execute main program
Main
