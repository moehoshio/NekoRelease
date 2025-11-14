# NekoRelease

> PowerShell automation tool for C++ library releases and package manager integration

NekoRelease automates the entire release workflow for C++ libraries: creating Git tags, publishing GitHub releases, downloading assets, calculating hashes, and generating package manager configuration files.

**🎯 Supports:** vcpkg (SHA512) • Conan (SHA256, ConanCenter structure)

---

## ✨ Features

- **Automated Release Workflow** - Create tags, publish releases, download assets
- **Hash Calculation** - Automatically calculate SHA512 (vcpkg) and SHA256 (Conan) 
- **Package Files Generation** - vcpkg ports and Conan recipes with proper structure
- **Smart Update Mode** - Auto-detect and update existing files or create new ones
- **Configuration File Support** - Store defaults in `.nekorelease.json`
- **Dry Run & Logging** - Preview changes and debug with detailed logs

## 📋 Prerequisites

- **PowerShell 5.1+** or **PowerShell Core 7+**
- **Git** - For repository operations
- **GitHub CLI (gh)** - For creating releases (optional, can provide URL manually)

## 🚀 Quick Start

### 1. Basic Release

```powershell
# Simple release with all defaults
.\NekoRelease.ps1 -Version "v1.0.0"
```

This will:
1. Create and push Git tag `v1.0.0`
2. Create GitHub release
3. Download release assets
4. Calculate hashes (SHA256 + SHA512)
5. Generate package files in `packages/`

### 2. Specific Package Managers

```powershell
# Generate only vcpkg port
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("vcpkg")

# Generate both vcpkg and Conan
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("vcpkg", "Conan")
```

### 3. Preview Mode (Dry Run)

```powershell
# Preview what would happen without making changes
.\NekoRelease.ps1 -Version "v1.0.0" -DryRun
```

### 4. Using Configuration File

Create `.nekorelease.json`:
```json
{
  "packageName": "mylib",
  "repositoryUrl": "https://github.com/username/mylib",
  "packageManagers": ["vcpkg", "Conan"],
  "mode": "Auto"
}
```

Then simply:
```powershell
.\NekoRelease.ps1 -Version "v1.0.0"
```

## 📦 Generated Files

### vcpkg

```
packages/vcpkg/mylib/
├── portfile.cmake    # Build instructions with SHA512 hash
├── vcpkg.json        # Port metadata
└── usage             # Usage instructions
```

### Conan (ConanCenter Structure)

```
packages/Conan/mylib/
├── config.yml        # Package configuration
└── all/
    ├── conanfile.py   # Recipe with SHA256 hash
    └── conandata.yml  # Version data
```

## 🔧 Common Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-Version` | Version to release (required) | `"v1.0.0"` |
| `-PackageManagers` | Which package managers | `@("vcpkg", "Conan")` |
| `-Mode` | Update mode | `"Auto"`, `"Update"`, `"Create"` |
| `-ConfigFile` | Config file path | `".nekorelease.json"` |
| `-DryRun` | Preview without changes | Switch parameter |
| `-SkipGitTag` | Skip tag creation | Switch parameter |
| `-SkipRelease` | Skip release creation | Switch parameter |
| `-LogFile` | Enable logging | `"release.log"` |
| `-DebugOutput` | Show debug messages | Switch parameter |

## 💡 Common Workflows

### First Release

```powershell
# 1. Preview first
.\NekoRelease.ps1 -Version "v1.0.0" -DryRun

# 2. Execute
.\NekoRelease.ps1 -Version "v1.0.0"

# 3. Validate
.\Test-NekoPackages.ps1
```

### Update Existing Version

```powershell
# Update package files for existing release
.\NekoRelease.ps1 -Version "v1.0.0" -SkipGitTag -SkipRelease -Mode "Update"
```

### Package Files Only

```powershell
# Only generate package files (no Git operations)
.\NekoRelease.ps1 -Version "v1.0.0" -SkipGitTag -SkipRelease
```

### With Validation

```powershell
# Complete workflow with validation
.\Release-WithValidation.ps1 -Version "v1.0.0"
```

## 🎯 Update Modes

- **Auto** (default) - Update existing files or create new ones
- **Update** - Only update existing files, skip if missing
- **Create** - Always create new files, backup existing ones

```powershell
.\NekoRelease.ps1 -Version "v1.2.0" -Mode "Update"
```

## ✅ Validation & Testing

Validate generated package files:

```powershell
# Validate all packages
.\Test-NekoPackages.ps1

# Validate specific package manager
.\Test-NekoPackages.ps1 -PackageManagers @("vcpkg")

# Validation only (skip installation tests)
.\Test-NekoPackages.ps1 -ValidateOnly
```

## 🔍 Troubleshooting

### Hash Not Filled

Ensure release assets are uploaded before generating packages:
```powershell
# Create release first, then generate packages
.\NekoRelease.ps1 -Version "v1.0.0" -SkipGitTag -SkipRelease
```

### GitHub CLI Not Found

Provide repository URL manually:
```powershell
.\NekoRelease.ps1 -Version "v1.0.0" -RepositoryUrl "https://github.com/user/repo"
```

### Debug Issues

Enable debug output:
```powershell
.\NekoRelease.ps1 -Version "v1.0.0" -DebugOutput -LogFile "debug.log"
```

## 📚 Documentation

- **[GUIDE.md](GUIDE.md)** - Complete usage guide with examples
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute
- **[CHANGELOG.md](CHANGELOG.md)** - Version history

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

## 🔗 Links

- **Repository**: [github.com/moehoshio/NekoRelease](https://github.com/moehoshio/NekoRelease)
- **Issues**: [Report a bug](https://github.com/moehoshio/NekoRelease/issues)
- **vcpkg**: [microsoft/vcpkg](https://github.com/microsoft/vcpkg)
- **Conan**: [conan.io](https://conan.io/)
