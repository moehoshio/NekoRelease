# Update Mode Examples

This document provides examples of using NekoRelease's update/create modes for managing package files across different versions.

## Understanding the Modes

### Auto Mode (Recommended)

The default mode that intelligently handles both scenarios:

- **Files exist**: Updates version, hash, and URLs
- **Files don't exist**: Creates new files with full content

```powershell
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("vcpkg", "Conan")
# First run: Creates all files

.\NekoRelease.ps1 -Version "v1.1.0" -PackageManagers @("vcpkg", "Conan")
# Second run: Updates existing files
```

### Update Mode

Only updates existing files, preserves custom modifications:

```powershell
.\NekoRelease.ps1 -Version "v1.2.0" -PackageManagers @("vcpkg") -Mode "Update"
```

**What gets updated:**

- vcpkg: `REF` and `SHA512` in `portfile.cmake`, `version` in `vcpkg.json`
- Conan: `version` in `conanfile.py`, adds/updates version entry in `conandata.yml`
- Meson: `version` in `meson.build`, `source_url` and `source_hash` in `.wrap`
- Others: Version numbers and hashes

**What's preserved:**

- Custom dependencies
- Build configurations
- Comments and documentation
- Directory structure

### Create Mode

Forces creation of new files, backs up existing ones:

```powershell
.\NekoRelease.ps1 -Version "v2.0.0" -PackageManagers @("Conan") -Mode "Create"
# Existing files backed up as .backup
```

## Workflow Examples

### Example 1: Initial Release

```powershell
# First release - create all package files
.\NekoRelease.ps1 `
    -Version "v1.0.0" `
    -PackageManagers @("vcpkg", "Conan", "Meson", "CPM") `
    -Mode "Auto"
```

**Result:**

```
packages/
├── vcpkg/
│   └── nekorelease/
│       ├── vcpkg.json (created)
│       └── portfile.cmake (created)
├── Conan/
│   ├── conanfile.py (created)
│   └── conandata.yml (created)
├── Meson/
│   ├── nekorelease.wrap (created)
│   └── meson.build (created)
└── CPM/
    ├── CPMAddNekoRelease.cmake (created)
    └── FindNekoRelease.cmake (created)
```

### Example 2: Patch Release Update

```powershell
# Patch release - update version and hashes
.\NekoRelease.ps1 `
    -Version "v1.0.1" `
    -PackageManagers @("vcpkg", "Conan", "Meson", "CPM") `
    -Mode "Update"
```

**What happens:**

- vcpkg `portfile.cmake`: `REF v1.0.0` → `REF v1.0.1`
- Conan `conanfile.py`: `version = "1.0.0"` → `version = "1.0.1"`
- Conan `conandata.yml`: Adds new version `1.0.1` entry
- Meson `.wrap`: Updates `source_url` and `source_hash`
- CPM `.cmake`: Updates `VERSION` and `GIT_TAG`

### Example 3: Major Version with Custom Changes

```powershell
# Major version - create new files to review changes
.\NekoRelease.ps1 `
    -Version "v2.0.0" `
    -PackageManagers @("vcpkg", "Conan") `
    -Mode "Create"

# Review the new files
code packages/vcpkg/nekorelease/portfile.cmake
code packages/Conan/conanfile.py

# Restore from backup if needed
# Copy-Item packages/Conan/conanfile.py.backup packages/Conan/conanfile.py
```

### Example 4: Continuous Integration

```powershell
# CI/CD pipeline for automatic version updates
param([string]$NewVersion)

# 1. Build and test
cmake -B build
cmake --build build
ctest --test-dir build

# 2. Update package files
.\NekoRelease.ps1 `
    -Version $NewVersion `
    -PackageManagers @("vcpkg", "Conan", "Meson") `
    -Mode "Update"

# 3. Commit changes
git add packages/
git commit -m "chore: update package files to $NewVersion"
git push
```

### Example 5: Multiple Repository Maintenance

```powershell
# Update package files across multiple projects
$projects = @(
    @{ Path = "C:\Projects\LibA"; Version = "v1.5.0"; Managers = @("vcpkg", "Conan") },
    @{ Path = "C:\Projects\LibB"; Version = "v2.1.0"; Managers = @("Meson", "CPM") },
    @{ Path = "C:\Projects\LibC"; Version = "v0.9.0"; Managers = @("vcpkg", "Buckaroo") }
)

foreach ($project in $projects) {
    Write-Host "`nUpdating $($project.Path)..." -ForegroundColor Cyan
    
    Push-Location $project.Path
    
    .\NekoRelease.ps1 `
        -Version $project.Version `
        -PackageManagers $project.Managers `
        -Mode "Update"
    
    Pop-Location
}
```

## vcpkg Update Workflow

### Scenario: Update vcpkg Port Version

```powershell
# Initial setup
$vcpkgRegistry = "C:\vcpkg-registry"
$portName = "mylibrary"

# 1. Generate updated port files
.\NekoRelease.ps1 `
    -Version "v2.3.0" `
    -PackageManagers @("vcpkg") `
    -OutputPaths @{ "vcpkg" = "$vcpkgRegistry\ports\$portName" } `
    -Mode "Update"

# 2. Update version database
cd $vcpkgRegistry
.\vcpkg x-add-version $portName

# 3. Test the port
.\vcpkg remove $portName
.\vcpkg install $portName --overlay-ports=ports

# 4. Commit
git add .
git commit -m "[$portName] Update to 2.3.0"
```

### Customizing vcpkg Port After Update

```powershell
# Update base files
.\NekoRelease.ps1 -Version "v1.2.0" -PackageManagers @("vcpkg") -Mode "Update"

# Manually customize portfile.cmake
$portfile = "packages\vcpkg\nekorelease\portfile.cmake"
$content = Get-Content $portfile -Raw

# Add custom build options
$content = $content -replace 'vcpkg_cmake_configure\(', @'
vcpkg_cmake_configure(
    OPTIONS
        -DBUILD_SHARED_LIBS=OFF
        -DENABLE_TESTS=OFF
'@

Set-Content $portfile -Value $content
```

## Conan Update Workflow

### Scenario: Add New Version to Conan Center Recipe

```powershell
# 1. Generate updated recipe
.\NekoRelease.ps1 `
    -Version "v3.1.0" `
    -PackageManagers @("Conan") `
    -OutputPaths @{ "Conan" = "C:\conan-center-index\recipes\mylibrary\all" } `
    -Mode "Update"

# Check conandata.yml - should have new version entry:
# sources:
#   "3.0.0":
#     url: "..."
#     sha256: "..."
#   "3.1.0":   <-- New entry added
#     url: "..."
#     sha256: "..."

# 2. Test locally
cd C:\conan-center-index\recipes\mylibrary
conan create all --version=3.1.0

# 3. Submit PR
cd C:\conan-center-index
git checkout -b mylibrary-3.1.0
git add recipes/mylibrary/
git commit -m "[mylibrary] Add version 3.1.0"
git push origin mylibrary-3.1.0
```

### Preserving Custom Conan Recipe Settings

```powershell
# Update preserves custom settings in conanfile.py
.\NekoRelease.ps1 -Version "v1.5.0" -PackageManagers @("Conan") -Mode "Update"

# Your custom dependencies, options, and requirements are preserved:
# - self.requires("fmt/9.1.0") - PRESERVED
# - Custom options - PRESERVED
# - Build helpers - PRESERVED
# Only version, url, homepage updated
```

## Meson WrapDB Workflow

```powershell
# 1. Create/update wrap file
.\NekoRelease.ps1 `
    -Version "v1.4.0" `
    -PackageManagers @("Meson") `
    -Mode "Auto"

# 2. Use in your Meson project
# In your project's meson.build:
# mylib_dep = dependency('nekorelease', fallback: ['nekorelease', 'nekorelease_dep'])

# 3. Copy wrap file to subprojects
Copy-Item packages\Meson\nekorelease.wrap myproject\subprojects\
```

## Buckaroo Workflow

```powershell
# 1. Update buckaroo.json
.\NekoRelease.ps1 -Version "v2.0.0" -PackageManagers @("Buckaroo") -Mode "Update"

# 2. Publish to Buckaroo registry
cd packages\Buckaroo
buckaroo upgrade
buckaroo publish
```

## CPM Workflow

```powershell
# 1. Generate CPM configuration
.\NekoRelease.ps1 -Version "v1.3.0" -PackageManagers @("CPM") -Mode "Update"

# 2. Use in CMakeLists.txt
# include(cmake/CPM.cmake)
# include(CPMAddNekoRelease.cmake)

# 3. Alternative: Copy to project
Copy-Item packages\CPM\CPMAddNekoRelease.cmake MyProject\cmake\
```

## Advanced: Selective Updates

### Update Only Specific Fields

```powershell
# Custom script to update only hash, not version
$portfile = "packages\vcpkg\nekorelease\portfile.cmake"
$newHash = "NEW_SHA512_HASH_HERE"

$content = Get-Content $portfile -Raw
$content = $content -replace 'SHA512\s+\S+', "SHA512 $newHash"
Set-Content $portfile -Value $content
```

### Batch Update Multiple Versions

```powershell
# Update all C++ package managers for multiple versions
$versions = @("v1.0.0", "v1.1.0", "v1.2.0")

foreach ($version in $versions) {
    Write-Host "Processing $version..." -ForegroundColor Yellow
    
    .\NekoRelease.ps1 `
        -Version $version `
        -PackageManagers @("vcpkg", "Conan", "Meson") `
        -Mode "Auto" `
        -OutputPaths @{
            "vcpkg" = "releases\$version\vcpkg"
            "Conan" = "releases\$version\conan"
            "Meson" = "releases\$version\meson"
        }
}
```

## Troubleshooting

### File Not Updated in Update Mode

```powershell
# Check if file exists
Test-Path "packages\vcpkg\nekorelease\portfile.cmake"

# If false, use Auto or Create mode
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("vcpkg") -Mode "Auto"
```

### Restoring from Backup

```powershell
# If Create mode backed up files
Get-ChildItem packages\ -Recurse -Filter "*.backup" | ForEach-Object {
    $original = $_.FullName -replace '\.backup$', ''
    Copy-Item $_.FullName $original -Force
    Write-Host "Restored: $original"
}
```

### Verifying Updates

```powershell
# After update, verify changes
git diff packages/

# Review specific files
code packages\vcpkg\nekorelease\portfile.cmake
code packages\Conan\conandata.yml
```

## Best Practices

1. **Use Auto Mode by Default**
   - Handles both creation and updates intelligently
   - Safest option for regular releases

2. **Use Update Mode for CI/CD**
   - Prevents accidental file recreation
   - Faster as it skips creation logic

3. **Use Create Mode for Major Changes**
   - Review changes before committing
   - Keep backups of previous configurations

4. **Test After Updates**
   ```powershell
   # vcpkg
   vcpkg install mylib --overlay-ports=packages\vcpkg
   
   # Conan
   conan create packages\Conan --version=1.2.3
   
   # Meson
   meson setup build --wipe
   meson compile -C build
   ```

5. **Version Control Package Files**
   ```powershell
   git add packages/
   git commit -m "chore: update package files to v1.2.3"
   ```
