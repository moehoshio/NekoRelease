# Advanced Features Guide

This document covers advanced features and configurations for NekoRelease.

## Configuration File

### Creating a Configuration File

Create a `.nekorelease.json` file in your project root to store default settings:

```json
{
  "packageName": "myproject",
  "repositoryUrl": "https://github.com/username/myproject",
  "packageManagers": [
    "vcpkg",
    "Conan",
    "Meson"
  ],
  "mode": "Auto",
  "outputPaths": {
    "vcpkg": "./packages/vcpkg",
    "Conan": "./packages/conan",
    "Meson": "./packages/meson"
  }
}
```

### Using the Configuration File

```powershell
# Uses .nekorelease.json in current directory
.\NekoRelease.ps1 -Version "v1.0.0"

# Specify custom config file
.\NekoRelease.ps1 -Version "v1.0.0" -ConfigFile "custom-config.json"

# Command-line parameters override config file
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("vcpkg") -Mode "Update"
```

### Configuration Options

| Field | Type | Description |
|-------|------|-------------|
| `packageName` | String | Package name (auto-detected if not specified) |
| `repositoryUrl` | String | Repository URL |
| `packageManagers` | Array | Default package managers to generate |
| `mode` | String | Default mode: `Auto`, `Update`, or `Create` |
| `outputPaths` | Object | Output paths for each package manager |

## Dry Run Mode

Preview what NekoRelease would do without making any changes:

```powershell
# Preview all operations
.\NekoRelease.ps1 -Version "v1.0.0" -DryRun

# Preview with specific package managers
.\NekoRelease.ps1 `
    -Version "v1.0.0" `
    -PackageManagers @("vcpkg", "Conan") `
    -DryRun
```

**What Dry Run Shows:**

- Git tag that would be created
- Release that would be created
- Package files that would be generated
- Output paths for each package manager
- Files that would be backed up

**Use Cases:**

- Testing configuration before actual release
- Verifying output paths
- Checking which files would be updated
- CI/CD pipeline validation

## Logging

Enable detailed logging to a file for debugging and audit:

```powershell
# Enable logging
.\NekoRelease.ps1 -Version "v1.0.0" -LogFile "release.log"

# Combine with dry run for safe testing
.\NekoRelease.ps1 -Version "v1.0.0" -DryRun -LogFile "dry-run.log"
```

**Log Contents:**

- Timestamp for each operation
- Configuration loaded
- Files created/updated
- Git operations
- Hash calculations
- Errors and warnings

**Example Log:**

```
[2025-11-14 10:30:15] === NekoRelease Session Started ===
[2025-11-14 10:30:15] ℹ Loading configuration from: .nekorelease.json
[2025-11-14 10:30:15] ✓ Configuration loaded successfully
[2025-11-14 10:30:15] ✓ Repository path: C:\Projects\MyLib
[2025-11-14 10:30:16] ✓ Detected repository URL: https://github.com/user/mylib
[2025-11-14 10:30:16] ✓ Version: v1.0.0
[2025-11-14 10:30:16] ℹ Detected package name from repository: mylib
```

## Package Name Customization

By default, NekoRelease detects the package name from your repository URL or directory name. You can override this:

```powershell
# Specify package name
.\NekoRelease.ps1 -Version "v1.0.0" -PackageName "awesome-lib"

# Via config file
{
  "packageName": "awesome-lib"
}
```

**Package Name Usage:**

- vcpkg port directory name
- Conan package name
- Meson project name
- All generated files

## Skip Options

### Skip Git Tag

Only generate package files without creating Git tag:

```powershell
.\NekoRelease.ps1 `
    -Version "v1.0.0" `
    -PackageManagers @("vcpkg", "Conan") `
    -SkipGitTag
```

**Use Cases:**

- Tag already created manually
- Testing package file generation
- Regenerating files for existing release

### Skip Release

Create tag but don't create release (useful for preparing release manually):

```powershell
.\NekoRelease.ps1 `
    -Version "v1.0.0" `
    -SkipRelease
```

**Use Cases:**

- Create tag first, release later
- Manual release creation with custom notes
- Pre-release tags

### Skip Both

Only generate package files:

```powershell
.\NekoRelease.ps1 `
    -Version "v1.0.0" `
    -PackageManagers @("vcpkg", "Conan") `
    -SkipGitTag `
    -SkipRelease
```

## Complete Workflow Examples

### Example 1: Fully Automated Release

```powershell
# .nekorelease.json
{
  "packageName": "mylib",
  "packageManagers": ["vcpkg", "Conan", "Meson"],
  "mode": "Auto"
}

# Single command release
.\NekoRelease.ps1 -Version "v1.2.0"
```

### Example 2: Dry Run → Review → Execute

```powershell
# 1. Preview
.\NekoRelease.ps1 -Version "v2.0.0" -DryRun -LogFile "preview.log"

# 2. Review the log
code preview.log

# 3. Execute if looks good
.\NekoRelease.ps1 -Version "v2.0.0" -LogFile "release.log"
```

### Example 3: Package Files Only Workflow

```powershell
# 1. Create and push tag manually
git tag -a v1.5.0 -m "Release v1.5.0"
git push origin v1.5.0

# 2. Create release manually on GitHub
# (Add custom release notes, attach binaries, etc.)

# 3. Generate package files only
.\NekoRelease.ps1 `
    -Version "v1.5.0" `
    -PackageManagers @("vcpkg", "Conan", "Meson", "CPM") `
    -SkipGitTag `
    -SkipRelease
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
      
      - name: Dry Run
        run: |
          .\NekoRelease.ps1 `
            -Version "${{ steps.version.outputs.VERSION }}" `
            -DryRun `
            -LogFile "dry-run.log" `
            -ConfigFile ".nekorelease.json"
      
      - name: Upload Dry Run Log
        uses: actions/upload-artifact@v3
        with:
          name: dry-run-log
          path: dry-run.log
      
      - name: Generate Package Files
        run: |
          .\NekoRelease.ps1 `
            -Version "${{ steps.version.outputs.VERSION }}" `
            -SkipGitTag `
            -LogFile "release.log" `
            -ConfigFile ".nekorelease.json"
      
      - name: Upload Package Files
        uses: actions/upload-artifact@v3
        with:
          name: package-files
          path: packages/
```

### Example 5: Multi-Project Monorepo

```powershell
# config-lib-a.json
{
  "packageName": "lib-a",
  "packageManagers": ["vcpkg", "Conan"],
  "outputPaths": {
    "vcpkg": "./packages/lib-a/vcpkg",
    "Conan": "./packages/lib-a/conan"
  }
}

# config-lib-b.json
{
  "packageName": "lib-b",
  "packageManagers": ["Meson", "CPM"],
  "outputPaths": {
    "Meson": "./packages/lib-b/meson",
    "CPM": "./packages/lib-b/cpm"
  }
}

# Release script
$projects = @(
    @{ Config = "config-lib-a.json"; Version = "v1.0.0" },
    @{ Config = "config-lib-b.json"; Version = "v2.0.0" }
)

foreach ($proj in $projects) {
    Write-Host "`nProcessing $($proj.Config)..." -ForegroundColor Cyan
    
    .\NekoRelease.ps1 `
        -Version $proj.Version `
        -ConfigFile $proj.Config `
        -SkipGitTag `
        -LogFile "release-$($proj.Config -replace '\.json$', '.log')"
}
```

## Best Practices

### 1. Use Configuration Files

Store common settings in `.nekorelease.json`:

```json
{
  "packageManagers": ["vcpkg", "Conan"],
  "mode": "Auto",
  "outputPaths": {
    "vcpkg": "./vcpkg-ports",
    "Conan": "./conan-recipes"
  }
}
```

Add to `.gitignore` if it contains sensitive info, or commit it for team consistency.

### 2. Always Dry Run for Major Releases

```powershell
# Major version release
.\NekoRelease.ps1 -Version "v2.0.0" -DryRun

# Review, then execute
.\NekoRelease.ps1 -Version "v2.0.0"
```

### 3. Use Logging for CI/CD

```powershell
.\NekoRelease.ps1 -Version $VERSION -LogFile "release-$VERSION.log"
```

Upload logs as artifacts for troubleshooting.

### 4. Separate Git Operations from Package Generation

```powershell
# In pre-release hook: Create tag only
.\NekoRelease.ps1 -Version "v1.0.0" -SkipRelease

# After manual review: Generate packages
.\NekoRelease.ps1 -Version "v1.0.0" -SkipGitTag -SkipRelease
```

### 5. Version Control Your Configuration

```bash
git add .nekorelease.json
git commit -m "chore: add NekoRelease configuration"
```

## Troubleshooting

### Dry Run Shows Unexpected Operations

Check your configuration file:

```powershell
# Verify config loading
.\NekoRelease.ps1 -Version "v1.0.0" -DryRun -LogFile "debug.log"

# Review log for config values
Select-String -Path "debug.log" -Pattern "config|Using"
```

### Package Name Not Detected Correctly

Explicitly specify package name:

```powershell
.\NekoRelease.ps1 -Version "v1.0.0" -PackageName "correct-name"

# Or in config file
{
  "packageName": "correct-name"
}
```

### Configuration Not Loading

Check file path and format:

```powershell
# Test JSON validity
Get-Content .nekorelease.json | ConvertFrom-Json

# Use absolute path
.\NekoRelease.ps1 -ConfigFile "C:\full\path\to\config.json"
```

### Logs Not Generated

Ensure log file path is writable:

```powershell
# Use absolute path
.\NekoRelease.ps1 -LogFile "C:\Logs\release.log"

# Check directory exists
New-Item -ItemType Directory -Path "C:\Logs" -Force
```

## Security Considerations

### Sensitive Information in Config

If your config contains sensitive URLs or paths:

```bash
# .gitignore
.nekorelease.json
.nekorelease.local.json

# Commit example instead
.nekorelease.example.json
```

### Log Files

Logs may contain repository URLs and paths:

```bash
# .gitignore
*.log
release-*.log
```

### Dry Run in CI

Always run dry run before actual release in automated pipelines:

```yaml
- name: Safety Check
  run: NekoRelease.ps1 -DryRun -Version $VERSION
  
- name: Approve
  # Manual approval step
  
- name: Release
  run: NekoRelease.ps1 -Version $VERSION
```
