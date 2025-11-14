# NekoRelease Complete Guide

Complete usage guide for NekoRelease with examples, workflows, and best practices.

## Table of Contents

- [Basic Usage](#basic-usage)
- [Package Managers](#package-managers)
- [Update Modes](#update-modes)
- [Configuration File](#configuration-file)
- [Examples](#examples)
- [vcpkg Workflows](#vcpkg-workflows)
- [Conan Workflows](#conan-workflows)
- [Validation & Testing](#validation--testing)
- [Advanced Features](#advanced-features)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## Basic Usage

### Simple Release

```powershell
# Create tag, release, and generate package files
.\NekoRelease.ps1 -Version "v1.0.0"
```

### Preview First (Dry Run)

```powershell
# See what would happen without making changes
.\NekoRelease.ps1 -Version "v1.0.0" -DryRun
```

### Specific Package Managers

```powershell
# vcpkg only
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("vcpkg")

# Conan only
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("Conan")

# Both
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("vcpkg", "Conan")
```

### Skip Git Operations

```powershell
# Only generate package files (tag already exists)
.\NekoRelease.ps1 -Version "v1.0.0" -SkipGitTag -SkipRelease
```

---

## Package Managers

### vcpkg

**Hash Algorithm:** SHA512 (automatically calculated)

**Generated Files:**
```
packages/vcpkg/mylib/
├── portfile.cmake    # Build instructions with SHA512
├── vcpkg.json        # Port metadata
└── usage             # Usage information
```

**Example portfile.cmake:**
```cmake
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO username/mylib
    REF v1.0.0
    SHA512 0a0632aa80eb3d6392a26be05b494b445b37b7069b9b319ff70d72505e345bdb1d140c0366c73f0134562eca6768b0078132f268eac460467278451761f80b36
    HEAD_REF main
)
```

### Conan

**Hash Algorithm:** SHA256 (automatically calculated)

**Directory Structure:** ConanCenter standard
```
packages/Conan/mylib/
├── config.yml        # Package configuration
└── all/
    ├── conanfile.py   # Recipe
    └── conandata.yml  # Version data with SHA256
```

**Example conandata.yml:**
```yaml
sources:
  "1.0.0":
    url: "https://github.com/username/mylib/archive/refs/tags/v1.0.0.tar.gz"
    sha256: "6e7312ac15fc9ec4f07238018e92d8bc43656e3f126ace7a80e5921ad064fff2"
```

---

## Update Modes

### Auto Mode (Default)

Automatically decide whether to update or create files:
- If files exist → update them
- If files don't exist → create them

```powershell
.\NekoRelease.ps1 -Version "v1.1.0"  # Mode is "Auto" by default
```

### Update Mode

Only update existing files, preserve custom modifications:

```powershell
.\NekoRelease.ps1 -Version "v1.2.0" -Mode "Update"
```

**What gets updated:**
- vcpkg: `REF` and `SHA512` in portfile.cmake, `version` in vcpkg.json
- Conan: `version` in conanfile.py, adds new version entry in conandata.yml

**What's preserved:**
- Custom dependencies
- Build configurations
- Comments

### Create Mode

Always create new files, backup existing ones:

```powershell
.\NekoRelease.ps1 -Version "v2.0.0" -Mode "Create"
```

Existing files are backed up with `.backup` extension.

---

## Configuration File

### Creating .nekorelease.json

Store default settings in project root:

```json
{
  "packageName": "mylib",
  "repositoryUrl": "https://github.com/username/mylib",
  "packageManagers": ["vcpkg", "Conan"],
  "mode": "Auto",
  "outputPaths": {
    "vcpkg": "./packages/vcpkg",
    "Conan": "./packages/conan"
  }
}
```

### Using Configuration

```powershell
# Uses .nekorelease.json automatically
.\NekoRelease.ps1 -Version "v1.0.0"

# Override with command-line parameters
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("vcpkg")

# Use custom config file
.\NekoRelease.ps1 -Version "v1.0.0" -ConfigFile "custom.json"
```

---

## Examples

### Example 1: First Time Release

```powershell
# 1. Preview
.\NekoRelease.ps1 -Version "v1.0.0" -DryRun -LogFile "preview.log"

# 2. Review the log
code preview.log

# 3. Execute
.\NekoRelease.ps1 -Version "v1.0.0"

# 4. Validate
.\Test-NekoPackages.ps1
```

### Example 2: Patch Release

```powershell
# Update version and hashes
.\NekoRelease.ps1 -Version "v1.0.1" -Mode "Update"
```

### Example 3: Package Files Only

```powershell
# 1. Create tag manually
git tag -a v1.5.0 -m "Release v1.5.0"
git push origin v1.5.0

# 2. Create release on GitHub (with custom notes)

# 3. Generate package files
.\NekoRelease.ps1 -Version "v1.5.0" -SkipGitTag -SkipRelease
```

### Example 4: CI/CD Pipeline

```yaml
# .github/workflows/release.yml
name: Release

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
        run: echo "VERSION=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT
      
      - name: Generate packages
        run: |
          .\NekoRelease.ps1 `
            -Version "${{ steps.version.outputs.VERSION }}" `
            -PackageManagers @("vcpkg", "Conan") `
            -LogFile "release.log"
      
      - name: Validate
        run: .\Test-NekoPackages.ps1 -ValidateOnly
      
      - name: Upload packages
        uses: actions/upload-artifact@v3
        with:
          name: packages
          path: packages/
```

### Example 5: Multiple Projects

```powershell
# Update package files across multiple C++ libraries
$projects = @(
    @{ Path = "C:\Projects\LibA"; Version = "v1.5.0" },
    @{ Path = "C:\Projects\LibB"; Version = "v2.1.0" },
    @{ Path = "C:\Projects\LibC"; Version = "v0.9.0" }
)

foreach ($project in $projects) {
    Write-Host "`nUpdating $($project.Path)..." -ForegroundColor Cyan
    
    Push-Location $project.Path
    
    .\NekoRelease.ps1 `
        -Version $project.Version `
        -PackageManagers @("vcpkg", "Conan") `
        -Mode "Update"
    
    Pop-Location
}
```

---

## vcpkg Workflows

### Submit to vcpkg Registry

```powershell
# 1. Generate port files
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("vcpkg")

# 2. Copy to vcpkg registry
Copy-Item -Recurse packages\vcpkg\mylib C:\vcpkg\ports\

# 3. Test the port
cd C:\vcpkg
.\vcpkg install mylib --overlay-ports=ports

# 4. Update version database
.\vcpkg x-add-version mylib

# 5. Create PR to microsoft/vcpkg
```

### Update Existing Port

```powershell
$version = "v2.3.0"
$vcpkgRegistry = "C:\vcpkg-registry"
$portName = "mylib"

# 1. Generate updated port files
.\NekoRelease.ps1 `
    -Version $version `
    -PackageManagers @("vcpkg") `
    -OutputPaths @{ "vcpkg" = "$vcpkgRegistry\ports\$portName" } `
    -Mode "Update"

# 2. Update version database
cd $vcpkgRegistry
.\vcpkg x-add-version $portName

# 3. Test
.\vcpkg remove $portName
.\vcpkg install $portName
```

### Custom Port Configuration

```powershell
# 1. Generate base port
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("vcpkg")

# 2. Edit portfile.cmake for custom options
$portfile = "packages\vcpkg\mylib\portfile.cmake"
# Add custom build options, dependencies, etc.

# 3. Test locally
vcpkg install mylib --overlay-ports=packages\vcpkg
```

---

## Conan Workflows

### Submit to Conan Center

```powershell
# 1. Generate recipe (ConanCenter structure)
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("Conan")

# 2. Test locally
cd packages\Conan\mylib
conan create all --version=1.0.0

# 3. Copy to Conan Center Index fork
$recipePath = "C:\conan-center-index\recipes\mylib"
Copy-Item -Recurse packages\Conan\mylib\* $recipePath\

# 4. Create PR to conan-io/conan-center-index
```

### Add New Version to Recipe

```powershell
# 1. Generate updated recipe (adds new version to conandata.yml)
.\NekoRelease.ps1 `
    -Version "v2.0.0" `
    -PackageManagers @("Conan") `
    -Mode "Update"

# conandata.yml now contains:
# sources:
#   "1.0.0": { url: "...", sha256: "..." }
#   "2.0.0": { url: "...", sha256: "..." }  # ← New

# 2. Test new version
conan create packages\Conan\mylib\all --version=2.0.0
```

### Local Development

```powershell
# 1. Generate recipe
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("Conan")

# 2. Export to local cache
cd packages\Conan\mylib
conan export all mylib/1.0.0@

# 3. Use in another project
cd C:\MyProject
# Add to conanfile.txt:
# [requires]
# mylib/1.0.0

conan install . --build=missing
```

---

## Validation & Testing

### Basic Validation

```powershell
# Validate all generated packages
.\Test-NekoPackages.ps1

# Output shows:
# ✓ vcpkg port structure
# ✓ SHA512 hash present
# ✓ Conan recipe syntax
# ✓ SHA256 hash present
```

### Specific Package Manager

```powershell
# Validate only vcpkg
.\Test-NekoPackages.ps1 -PackageManagers @("vcpkg")

# Validate only Conan
.\Test-NekoPackages.ps1 -PackageManagers @("Conan")
```

### Verbose Output

```powershell
# Show detailed validation information
.\Test-NekoPackages.ps1 -Verbose
```

### Validation Only (Skip Tests)

```powershell
# Only validate structure, skip installation tests
.\Test-NekoPackages.ps1 -ValidateOnly
```

### Understanding Output

**Success:**
```
✓ Found portfile.cmake
  ✓ SHA512: 0a0632aa...
  ✓ vcpkg_from_github present
✓ Found vcpkg.json
  ✓ name: mylib
  ✓ version: 1.0.0
```

**Failure:**
```
✗ Missing SHA512 hash in portfile.cmake
✗ Invalid JSON in vcpkg.json
```

### Common Validation Issues

**Issue:** Missing hash
```powershell
# Solution: Ensure release assets are uploaded
.\NekoRelease.ps1 -Version "v1.0.0" -SkipGitTag -SkipRelease
```

**Issue:** Invalid JSON/YAML
```powershell
# Check syntax manually
Get-Content packages\vcpkg\mylib\vcpkg.json | ConvertFrom-Json
Get-Content packages\Conan\mylib\all\conandata.yml
```

---

## Advanced Features

### Dry Run Mode

Preview all operations without making changes:

```powershell
.\NekoRelease.ps1 -Version "v1.0.0" -DryRun
```

**Shows:**
- Git tag that would be created
- Release that would be created
- Package files that would be generated
- Files that would be backed up

### Logging

Enable detailed logging for debugging:

```powershell
.\NekoRelease.ps1 -Version "v1.0.0" -LogFile "release.log"

# Combine with dry run
.\NekoRelease.ps1 -Version "v1.0.0" -DryRun -LogFile "preview.log"
```

**Log contains:**
- Timestamp for each operation
- Configuration loaded
- Files created/updated
- Git operations
- Hash calculations

### Debug Output

Show detailed debug messages:

```powershell
.\NekoRelease.ps1 -Version "v1.0.0" -DebugOutput
```

### Custom Output Paths

Specify custom output directories:

```powershell
.\NekoRelease.ps1 `
    -Version "v1.0.0" `
    -OutputPaths @{
        "vcpkg" = "C:\vcpkg\ports\mylib"
        "Conan" = "C:\conan-recipes"
    }
```

### Package Name Override

Use different name than repository:

```powershell
.\NekoRelease.ps1 `
    -Version "v1.0.0" `
    -PackageName "awesome-lib"
```

---

## Troubleshooting

### GitHub CLI Not Found

**Error:** `gh command not found`

**Solution 1:** Install GitHub CLI
```powershell
winget install GitHub.cli
gh auth login
```

**Solution 2:** Provide URL manually
```powershell
.\NekoRelease.ps1 `
    -Version "v1.0.0" `
    -RepositoryUrl "https://github.com/username/repo"
```

### Hash Not Filled

**Error:** Package files contain empty hash fields

**Solution:** Ensure release assets are uploaded
```powershell
# 1. Create release first (wait for assets)
# 2. Then generate package files
.\NekoRelease.ps1 -Version "v1.0.0" -SkipGitTag -SkipRelease
```

### Tag Already Exists

**Error:** `tag already exists`

**Solution:** Delete and recreate
```powershell
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
.\NekoRelease.ps1 -Version "v1.0.0"
```

### Validation Failed

**Error:** `.\Test-NekoPackages.ps1` shows errors

**Solution:** Check detailed output
```powershell
.\Test-NekoPackages.ps1 -Verbose
# Review specific error messages
# Fix issues in generated files
# Re-validate
```

### PowerShell Execution Policy

**Error:** `cannot be loaded because running scripts is disabled`

**Solution:** Set execution policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Best Practices

### 1. Always Use Configuration Files

Store defaults in `.nekorelease.json` for consistent releases:

```json
{
  "packageName": "mylib",
  "repositoryUrl": "https://github.com/username/mylib",
  "packageManagers": ["vcpkg", "Conan"],
  "mode": "Auto"
}
```

### 2. Preview Before Executing

Use dry run for important releases:

```powershell
.\NekoRelease.ps1 -Version "v2.0.0" -DryRun
# Review output
.\NekoRelease.ps1 -Version "v2.0.0"
```

### 3. Always Validate

Validate packages before submission:

```powershell
.\NekoRelease.ps1 -Version "v1.0.0"
.\Test-NekoPackages.ps1 -Verbose
```

### 4. Test Locally

Test package installations before submitting:

```powershell
# vcpkg
vcpkg install mylib --overlay-ports=packages\vcpkg

# Conan
conan create packages\Conan\mylib\all --version=1.0.0
```

### 5. Use Logging in CI/CD

Enable logging for automated releases:

```powershell
.\NekoRelease.ps1 -Version "v1.0.0" -LogFile "release.log"
```

### 6. Version Control Package Files

Commit generated files to track changes:

```powershell
git add packages/
git commit -m "chore: update package files to v1.0.0"
```

### 7. Update Mode for Existing Packages

Use Update mode to preserve customizations:

```powershell
.\NekoRelease.ps1 -Version "v1.1.0" -Mode "Update"
```

### 8. Keep Tools Updated

Regularly update vcpkg, Conan, and other tools:

```powershell
# vcpkg
cd C:\vcpkg
git pull

# Conan
pip install --upgrade conan
```

---

## Quick Reference

### All Scripts

**NekoRelease.ps1** - Main release automation
```powershell
.\NekoRelease.ps1 -Version "v1.0.0" [options]
```

**Test-NekoPackages.ps1** - Validation and testing
```powershell
.\Test-NekoPackages.ps1 [options]
```

**Release-WithValidation.ps1** - Complete workflow
```powershell
.\Release-WithValidation.ps1 -Version "v1.0.0"
```

### Common Commands

```powershell
# Preview
.\NekoRelease.ps1 -Version "v1.0.0" -DryRun

# Execute
.\NekoRelease.ps1 -Version "v1.0.0"

# Validate
.\Test-NekoPackages.ps1

# Package files only
.\NekoRelease.ps1 -Version "v1.0.0" -SkipGitTag -SkipRelease

# Update existing files
.\NekoRelease.ps1 -Version "v1.1.0" -Mode "Update"

# With logging
.\NekoRelease.ps1 -Version "v1.0.0" -LogFile "release.log"
```

### Decision Tree

**Need to release a new version?**
→ `.\Release-WithValidation.ps1 -Version "vX.Y.Z"`

**Just generate package files?**
→ `.\NekoRelease.ps1 -Version "vX.Y.Z" -SkipGitTag -SkipRelease`

**Want to preview first?**
→ `.\NekoRelease.ps1 -Version "vX.Y.Z" -DryRun`

**Need to validate?**
→ `.\Test-NekoPackages.ps1`

**Something broke?**
→ `.\Test-NekoPackages.ps1 -Verbose` + `.\NekoRelease.ps1 -DebugOutput`

---

## See Also

- **[README.md](README.md)** - Quick start and overview
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines
- **[CHANGELOG.md](CHANGELOG.md)** - Version history
- **[vcpkg Documentation](https://vcpkg.io/)** - vcpkg official docs
- **[Conan Documentation](https://docs.conan.io/)** - Conan official docs
