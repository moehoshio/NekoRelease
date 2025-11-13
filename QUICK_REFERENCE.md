# Quick Reference

## Scripts

### NekoRelease.ps1

**Purpose:** Main release automation script

**Basic Usage:**
```powershell
.\NekoRelease.ps1 -Version "v1.0.0"
```

**Common Options:**
```powershell
# With configuration file
.\NekoRelease.ps1 -Version "v1.0.0" -ConfigFile .nekorelease.json

# Dry run (preview)
.\NekoRelease.ps1 -Version "v1.0.0" -DryRun

# Specific package managers
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("vcpkg", "Conan")

# Skip git tag/release
.\NekoRelease.ps1 -Version "v1.0.0" -SkipGitTag -SkipRelease

# With logging
.\NekoRelease.ps1 -Version "v1.0.0" -LogFile "release.log"
```

**Key Parameters:**
- `-Version` - Version to release (required)
- `-PackageManagers` - Which package managers to generate files for
- `-Mode` - Auto/Update/Create mode
- `-ConfigFile` - Configuration file path
- `-DryRun` - Preview without making changes
- `-SkipGitTag` - Skip tag creation
- `-SkipRelease` - Skip release creation
- `-LogFile` - Log file path

---

### Test-NekoPackages.ps1

**Purpose:** Validate and test generated packages

**Basic Usage:**
```powershell
.\Test-NekoPackages.ps1
```

**Common Options:**
```powershell
# Validate only (skip installation tests)
.\Test-NekoPackages.ps1 -ValidateOnly

# Test specific package managers
.\Test-NekoPackages.ps1 -PackageManagers @("vcpkg", "Conan")

# Verbose output
.\Test-NekoPackages.ps1 -Verbose

# Custom package path
.\Test-NekoPackages.ps1 -PackagePath "C:\path\to\packages"
```

**Key Parameters:**
- `-PackagePath` - Path to packages directory
- `-PackageManagers` - Which package managers to test
- `-ValidateOnly` - Skip installation tests
- `-Verbose` - Show detailed output

---

### Release-WithValidation.ps1

**Purpose:** Complete workflow with validation

**Basic Usage:**
```powershell
.\Release-WithValidation.ps1 -Version "v1.0.0"
```

**Common Options:**
```powershell
# With configuration file
.\Release-WithValidation.ps1 -Version "v1.0.0" -ConfigFile .nekorelease.json

# Skip validation
.\Release-WithValidation.ps1 -Version "v1.0.0" -SkipValidation

# Skip testing
.\Release-WithValidation.ps1 -Version "v1.0.0" -SkipTesting
```

**Key Parameters:**
- `-Version` - Version to release (required)
- `-ConfigFile` - Configuration file path
- `-SkipValidation` - Skip package validation
- `-SkipTesting` - Skip installation testing

---

## Workflows

### 1. Basic Release

```powershell
# Step 1: Generate packages
.\NekoRelease.ps1 -Version "v1.0.0"

# Step 2: Validate
.\Test-NekoPackages.ps1

# Done!
```

### 2. Safe Release (with Preview)

```powershell
# Step 1: Preview
.\NekoRelease.ps1 -Version "v1.0.0" -DryRun

# Step 2: Review and execute
.\NekoRelease.ps1 -Version "v1.0.0"

# Step 3: Validate
.\Test-NekoPackages.ps1
```

### 3. One-Command Release

```powershell
# All-in-one with validation
.\Release-WithValidation.ps1 -Version "v1.0.0"
```

### 4. Package-Only Workflow

```powershell
# Step 1: Create tag manually
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# Step 2: Generate package files only
.\NekoRelease.ps1 -Version "v1.0.0" -SkipGitTag -SkipRelease

# Step 3: Validate
.\Test-NekoPackages.ps1
```

### 5. C++ Library Release

```powershell
# Generate C++ package manager files
.\NekoRelease.ps1 `
    -Version "v1.0.0" `
    -PackageManagers @("vcpkg", "Conan", "Meson", "CPM")

# Validate with testing
.\Test-NekoPackages.ps1 -PackageManagers @("vcpkg", "Conan")
```

---

## Configuration File (.nekorelease.json)

**Location:** Project root

**Template:**
```json
{
  "packageName": "myproject",
  "repositoryUrl": "https://github.com/username/myproject",
  "packageManagers": ["vcpkg", "Conan", "Scoop"],
  "mode": "Auto",
  "outputPaths": {
    "vcpkg": "./packages/vcpkg",
    "Conan": "./packages/conan",
    "Scoop": "./packages/scoop"
  }
}
```

**Create from example:**
```powershell
Copy-Item .nekorelease.example.json .nekorelease.json
code .nekorelease.json  # Edit with your settings
```

---

## Package Managers

### Supported

| Package Manager | Testing Support | Use Case |
|----------------|----------------|-----------|
| **Chocolatey** | ❌ | Windows applications |
| **Scoop** | ✅ | Windows CLI tools |
| **Winget** | ❌ | Windows applications |
| **vcpkg** | ✅ | C/C++ libraries |
| **Conan** | ✅ | C/C++ libraries |
| **Meson** | ❌ | C/C++ libraries |
| **Buckaroo** | ❌ | C++ libraries |
| **CPM** | ✅ | C++ libraries (CMake) |

### Specify in Command

```powershell
-PackageManagers @("vcpkg", "Conan", "Scoop")
```

### Specify in Config

```json
{
  "packageManagers": ["vcpkg", "Conan", "Scoop"]
}
```

---

## Modes

### Auto (Default)

- Updates existing files
- Creates new files if they don't exist
- **Use when:** Regular version updates

### Update

- Only updates existing files
- Skips if files don't exist
- **Use when:** Bumping versions in package repositories

### Create

- Always creates new files
- Backs up existing files with `.backup` extension
- **Use when:** First-time setup or major changes

**Specify:**
```powershell
-Mode "Update"
```

---

## Common Commands

### First Time Setup

```powershell
# 1. Copy example config
Copy-Item .nekorelease.example.json .nekorelease.json

# 2. Edit config
code .nekorelease.json

# 3. Test with dry run
.\NekoRelease.ps1 -Version "v0.1.0" -DryRun

# 4. Generate packages
.\NekoRelease.ps1 -Version "v0.1.0"

# 5. Validate
.\Test-NekoPackages.ps1
```

### Update Existing Release

```powershell
# Using Auto mode (default)
.\NekoRelease.ps1 -Version "v1.1.0"
.\Test-NekoPackages.ps1
```

### Fix Validation Issues

```powershell
# 1. Identify issues
.\Test-NekoPackages.ps1 -Verbose

# 2. Regenerate specific package
.\NekoRelease.ps1 `
    -Version "v1.0.0" `
    -PackageManagers @("vcpkg") `
    -SkipGitTag `
    -SkipRelease `
    -Mode "Create"

# 3. Re-validate
.\Test-NekoPackages.ps1 -PackageManagers @("vcpkg")
```

### Local Testing

```powershell
# Test vcpkg port locally
vcpkg install myproject --overlay-ports=.\packages\vcpkg

# Test Conan recipe locally
conan create .\packages\conan

# Test Scoop manifest locally
scoop install .\packages\scoop\myproject.json

# Test CPM configuration
cmake -DCPM_SOURCE_CACHE=.cpm -P .\packages\cpm\myproject.cmake
```

---

## Troubleshooting

### Issue: "GitHub CLI not installed"

```powershell
# Option 1: Install GitHub CLI
winget install GitHub.cli
gh auth login

# Option 2: Provide URL manually
.\NekoRelease.ps1 -RepositoryUrl "https://github.com/user/repo"
```

### Issue: "Validation failed"

```powershell
# See detailed errors
.\Test-NekoPackages.ps1 -Verbose

# Check specific package
code .\packages\vcpkg\portfile.cmake

# Regenerate
.\NekoRelease.ps1 -Version "v1.0.0" -SkipGitTag -SkipRelease
```

### Issue: "Tag already exists"

```powershell
# Delete and recreate
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
.\NekoRelease.ps1 -Version "v1.0.0"
```

### Issue: "Missing hash"

```powershell
# Ensure release assets are uploaded first
# Then regenerate packages
.\NekoRelease.ps1 -Version "v1.0.0" -SkipGitTag -SkipRelease
```

---

## Exit Codes

Both `NekoRelease.ps1` and `Test-NekoPackages.ps1` return:

- `0` - Success
- `1` - Failure

Use in CI/CD:
```yaml
- name: Release
  run: .\Release-WithValidation.ps1 -Version "${{ env.VERSION }}"
  # Automatically fails build if exit code is 1
```

---

## Documentation

- **README.md** - Main documentation
- **EXAMPLES.md** - Usage examples
- **CPP_EXAMPLES.md** - C++ package manager examples
- **UPDATE_MODE_EXAMPLES.md** - Update mode workflows
- **ADVANCED_FEATURES.md** - Configuration, dry run, logging
- **TESTING.md** - Validation and testing guide
- **QUICK_REFERENCE.md** - This file

---

## Get Help

```powershell
# Show help for any script
Get-Help .\NekoRelease.ps1 -Full
Get-Help .\Test-NekoPackages.ps1 -Full
Get-Help .\Release-WithValidation.ps1 -Full

# Show parameter details
Get-Help .\NekoRelease.ps1 -Parameter Version
```

---

## Tips

1. **Always use configuration files** for consistent releases
2. **Always dry run first** for major versions
3. **Always validate** before submitting to repositories
4. **Use logging** in CI/CD for debugging
5. **Test locally** when package manager supports it
6. **Keep tools updated** (vcpkg, Conan, etc.)

---

## Quick Decision Tree

**Need to release a new version?**
→ `.\Release-WithValidation.ps1 -Version "vX.Y.Z"`

**Just want to generate package files?**
→ `.\NekoRelease.ps1 -Version "vX.Y.Z" -SkipGitTag -SkipRelease`

**Want to preview first?**
→ `.\NekoRelease.ps1 -Version "vX.Y.Z" -DryRun`

**Need to validate existing packages?**
→ `.\Test-NekoPackages.ps1`

**Something broke?**
→ `.\Test-NekoPackages.ps1 -Verbose` to see what's wrong

**First time using?**
→ Read **README.md** and **EXAMPLES.md**
