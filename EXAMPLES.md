# NekoRelease Usage Examples

## Example 1: Basic Release Workflow

```powershell
# Navigate to your project directory
cd C:\Projects\MyApp

# Run NekoRelease
C:\more\code\moehoshio\NekoRelease\NekoRelease.ps1

# The script will prompt:
# Repository path [C:\Projects\MyApp]: (Press Enter to use default)
# Version number (e.g., v1.0.0): v1.0.0
# Select package managers: (optional, press Enter to skip)
```

## Example 2: Release Specific Version to Scoop

```powershell
.\NekoRelease.ps1 -Version "v2.3.1" -PackageManagers @("Scoop")
```

This will:

1. Create Git tag `v2.3.1`
2. Push tag to remote
3. Create GitHub Release (or provide creation URL)
4. Download release assets and calculate hashes
5. Generate `nekorelease.json` in `packages\Scoop\` directory

## Example 3: Release to All Package Managers

```powershell
.\NekoRelease.ps1 `
    -Version "v3.0.0" `
    -PackageManagers @("Chocolatey", "Scoop", "Winget")
```

## Example 4: Custom Output Paths

```powershell
.\NekoRelease.ps1 `
    -Version "v1.5.0" `
    -PackageManagers @("Scoop", "Winget") `
    -OutputPaths @{
        "Scoop" = "D:\Releases\v1.5.0\Scoop"
        "Winget" = "D:\Releases\v1.5.0\Winget"
    }
```

## Example 5: Release Beta Version

```powershell
.\NekoRelease.ps1 -Version "v2.0.0-beta.3"
```

## Example 6: Cross-Project Release

```powershell
# Release a specific repository from any location
.\NekoRelease.ps1 `
    -RepositoryPath "C:\Projects\AnotherProject" `
    -Version "v4.2.1" `
    -PackageManagers @("Scoop")
```

## Example 7: Manual Repository URL

```powershell
# When remote URL cannot be auto-detected or for custom Git hosts
.\NekoRelease.ps1 `
    -RepositoryPath "C:\Projects\MyApp" `
    -RepositoryUrl "https://git.company.com/team/project" `
    -Version "v1.0.0"
```

## Example 8: GitLab Release

```powershell
.\NekoRelease.ps1 `
    -RepositoryUrl "https://gitlab.com/myuser/myproject" `
    -Version "v2.5.0" `
    -PackageManagers @("Scoop")
```

## Example 9: Gitea/Forgejo Release

```powershell
.\NekoRelease.ps1 `
    -RepositoryUrl "https://gitea.example.com/myorg/myrepo" `
    -Version "v1.3.0"
```

## Typical Workflow

### Prepare for Release

```powershell
# 1. Ensure all changes are committed
git status
git add .
git commit -m "Prepare for release v1.2.0"

# 2. Push to remote
git push origin main

# 3. Execute release
.\NekoRelease.ps1 -Version "v1.2.0" -PackageManagers @("Scoop", "Winget")
```

### Post-Release Verification

```powershell
# Check tags
git tag -l

# Check generated files
ls .\packages\Scoop\
ls .\packages\Winget\

# Check downloaded assets and hashes
ls .\downloads\v1.2.0\
```

## Automation Script Example

Create a `release.ps1` to automate the complete workflow:

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

Write-Host "Starting release process: $Version" -ForegroundColor Cyan

# 1. Run tests
Write-Host "`n[1/5] Running tests..." -ForegroundColor Yellow
# Invoke-Pester .\tests\

# 2. Update version in files (if you have version files)
Write-Host "`n[2/5] Updating version..." -ForegroundColor Yellow
# (Get-Content .\version.txt) -replace '.*', $Version | Set-Content .\version.txt

# 3. Update changelog
Write-Host "`n[3/5] Updating changelog..." -ForegroundColor Yellow
# Add-Content -Path .\CHANGELOG.md -Value "`n## $Version - $(Get-Date -Format 'yyyy-MM-dd')`n"

# 4. Commit changes
Write-Host "`n[4/5] Committing changes..." -ForegroundColor Yellow
git add .
git commit -m "Release $Version"
git push origin main

# 5. Execute NekoRelease
Write-Host "`n[5/5] Publishing release..." -ForegroundColor Yellow
.\NekoRelease.ps1 `
    -Version $Version `
    -PackageManagers @("Chocolatey", "Scoop", "Winget")

Write-Host "`n✓ Release complete!" -ForegroundColor Green
```

Usage:

```powershell
.\release.ps1 -Version "v1.3.0"
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Release

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to release (e.g., v1.0.0)'
        required: true

jobs:
  release:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install GitHub CLI
        run: |
          choco install gh -y
          gh auth login --with-token <<< "${{ secrets.GITHUB_TOKEN }}"
      
      - name: Run NekoRelease
        run: |
          .\NekoRelease.ps1 `
            -Version "${{ github.event.inputs.version }}" `
            -PackageManagers @("Scoop", "Winget")
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: package-files
          path: packages/
```

### GitLab CI

```yaml
release:
  stage: deploy
  only:
    - tags
  script:
    - |
      pwsh -Command "
        .\NekoRelease.ps1 `
          -Version '$CI_COMMIT_TAG' `
          -RepositoryUrl '$CI_PROJECT_URL' `
          -PackageManagers @('Scoop', 'Winget')
      "
  artifacts:
    paths:
      - packages/
```

## Advanced Scenarios

### Multi-Repository Release

Create a script to release multiple related repositories:

```powershell
$repos = @(
    @{ Path = "C:\Projects\Repo1"; Version = "v1.0.0" },
    @{ Path = "C:\Projects\Repo2"; Version = "v2.0.0" },
    @{ Path = "C:\Projects\Repo3"; Version = "v1.5.0" }
)

foreach ($repo in $repos) {
    Write-Host "`nReleasing $($repo.Path)..." -ForegroundColor Cyan
    
    .\NekoRelease.ps1 `
        -RepositoryPath $repo.Path `
        -Version $repo.Version `
        -PackageManagers @("Scoop")
}
```

### Conditional Package Generation

```powershell
# Only generate packages for stable releases (not pre-release)
param([string]$Version)

$isStable = $Version -notmatch '-(alpha|beta|rc)'

$managers = if ($isStable) {
    @("Chocolatey", "Scoop", "Winget")
} else {
    @()  # No package files for pre-releases
}

.\NekoRelease.ps1 `
    -Version $Version `
    -PackageManagers $managers
```

### Version Bumping Helper

```powershell
# Get current version from git tags
$currentVersion = git describe --tags --abbrev=0 2>$null

if ($currentVersion) {
    Write-Host "Current version: $currentVersion"
    
    # Parse and bump version (simple example)
    if ($currentVersion -match 'v?(\d+)\.(\d+)\.(\d+)') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        $patch = [int]$Matches[3]
        
        Write-Host "Bump type:"
        Write-Host "  1. Major ($major.x.x -> $($major+1).0.0)"
        Write-Host "  2. Minor (x.$minor.x -> $major.$($minor+1).0)"
        Write-Host "  3. Patch (x.x.$patch -> $major.$minor.$($patch+1))"
        
        $choice = Read-Host "Select"
        
        $newVersion = switch ($choice) {
            "1" { "v$($major+1).0.0" }
            "2" { "v$major.$($minor+1).0" }
            "3" { "v$major.$minor.$($patch+1)" }
        }
        
        Write-Host "New version: $newVersion"
        
        .\NekoRelease.ps1 -Version $newVersion
    }
} else {
    Write-Host "No previous version found, starting with v1.0.0"
    .\NekoRelease.ps1 -Version "v1.0.0"
}
```

## Example 11: Release with Validation

```powershell
# Use the integrated workflow script
.\Release-WithValidation.ps1 -Version "v1.0.0"

# This will:
# 1. Generate packages with NekoRelease
# 2. Validate package structure
# 3. Test installation (where supported)
# 4. Report results

# Or do it manually step by step:

# Step 1: Generate packages
.\NekoRelease.ps1 -Version "v1.0.0" -ConfigFile .nekorelease.json

# Step 2: Validate and test
.\Test-NekoPackages.ps1 -Verbose

# Step 3: If validation passes, submit to repositories
```

## Example 12: Validation Only Workflow

```powershell
# Generate packages
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("vcpkg", "Conan")

# Validate without testing installation
.\Test-NekoPackages.ps1 -ValidateOnly

# Review validation results and fix issues if needed

# Test specific package manager
.\Test-NekoPackages.ps1 -PackageManagers @("vcpkg") -Verbose
```

## Example 13: CI/CD with Validation

```yaml
# .github/workflows/release-with-validation.yml
name: Release with Validation

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: windows-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Extract version
        id: version
        shell: pwsh
        run: |
          $version = "${{ github.ref }}" -replace 'refs/tags/', ''
          echo "VERSION=$version" >> $env:GITHUB_OUTPUT
      
      - name: Generate packages
        shell: pwsh
        run: |
          .\NekoRelease.ps1 `
            -Version "${{ steps.version.outputs.VERSION }}" `
            -ConfigFile .nekorelease.json `
            -LogFile "release.log"
      
      - name: Validate packages
        shell: pwsh
        run: |
          .\Test-NekoPackages.ps1 -ValidateOnly -Verbose
      
      - name: Upload packages
        if: success()
        uses: actions/upload-artifact@v3
        with:
          name: packages-${{ steps.version.outputs.VERSION }}
          path: packages/
      
      - name: Upload logs
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: logs
          path: |
            release.log
            *.log
```

## Example 14: Pre-Release Validation

```powershell
# Before creating release, validate package generation

# 1. Dry run to preview
.\NekoRelease.ps1 -Version "v2.0.0" -DryRun -LogFile "preview.log"

# 2. Review preview log
code preview.log

# 3. Actually generate packages (skip git tag and release)
.\NekoRelease.ps1 `
    -Version "v2.0.0" `
    -SkipGitTag `
    -SkipRelease `
    -LogFile "generate.log"

# 4. Validate generated packages
.\Test-NekoPackages.ps1 -Verbose

# 5. If validation passes, create tag and release
git tag -a v2.0.0 -m "Release v2.0.0"
git push origin v2.0.0
# Create release on GitHub manually
```

## Troubleshooting Examples

### Debug Mode

```powershell
# Enable verbose output
$VerbosePreference = "Continue"
.\NekoRelease.ps1 -Version "v1.0.0" -Verbose
```

### Dry Run (Test Without Publishing)

```powershell
# Use built-in dry run mode
.\NekoRelease.ps1 -Version "v1.0.0" -DryRun

# Review what would happen, then execute for real
.\NekoRelease.ps1 -Version "v1.0.0"
```

### Validate Package Structure

```powershell
# Check if generated packages are valid
.\Test-NekoPackages.ps1 -Verbose

# Validate specific package manager
.\Test-NekoPackages.ps1 -PackageManagers @("vcpkg") -Verbose

# Only validate, don't test installation
.\Test-NekoPackages.ps1 -ValidateOnly
```

### Handle Failed Release

```powershell
# If release failed mid-way, clean up and retry

# Delete local tag
git tag -d v1.0.0

# Delete remote tag if it was pushed
git push origin :refs/tags/v1.0.0

# Retry
.\NekoRelease.ps1 -Version "v1.0.0"
```

### Fix Validation Issues

```powershell
# 1. Run validation to identify issues
.\Test-NekoPackages.ps1 -Verbose

# 2. Review specific package file
code .\packages\vcpkg\portfile.cmake

# 3. Regenerate packages after fixing
.\NekoRelease.ps1 `
    -Version "v1.0.0" `
    -PackageManagers @("vcpkg") `
    -SkipGitTag `
    -SkipRelease `
    -Mode "Create"

# 4. Re-validate
.\Test-NekoPackages.ps1 -PackageManagers @("vcpkg") -Verbose
```
