# NekoRelease Project Overview

## Project Structure

```
NekoRelease/
├── Scripts/
│   ├── NekoRelease.ps1              # Main release automation script
│   ├── Test-NekoPackages.ps1        # Validation and testing script
│   └── Release-WithValidation.ps1   # Complete workflow script
│
├── Configuration/
│   └── .nekorelease.example.json    # Configuration file template
│
├── Documentation/
│   ├── README.md                    # Main documentation
│   ├── QUICK_REFERENCE.md           # Quick command reference
│   ├── EXAMPLES.md                  # Usage examples
│   ├── CPP_EXAMPLES.md              # C++ specific examples
│   ├── UPDATE_MODE_EXAMPLES.md      # Update mode workflows
│   ├── ADVANCED_FEATURES.md         # Advanced features guide
│   └── TESTING.md                   # Validation and testing guide
│
└── LICENSE                          # MIT License
```

## File Descriptions

### Scripts

#### NekoRelease.ps1
**Purpose:** Core release automation tool

**Features:**
- Creates and pushes Git tags
- Creates GitHub/GitLab/Gitea releases
- Downloads and hashes release assets
- Generates package manager files
- Supports 8 package managers
- Configuration file support
- Dry run mode
- Logging

**Size:** ~1400 lines
**Parameters:** 11

#### Test-NekoPackages.ps1
**Purpose:** Package validation and testing

**Features:**
- Validates package structure
- Checks file formats
- Verifies required fields
- Tests local installation (Scoop, vcpkg, Conan, CPM)
- Auto-detects package managers
- Detailed error reporting

**Size:** ~900 lines
**Parameters:** 4

#### Release-WithValidation.ps1
**Purpose:** Integrated workflow script

**Features:**
- Combines NekoRelease + Test-NekoPackages
- Complete release workflow
- Beautiful console output
- Next steps guidance

**Size:** ~200 lines
**Parameters:** 4

### Configuration

#### .nekorelease.example.json
**Purpose:** Configuration template

**Contains:**
- Package name
- Repository URL
- Default package managers
- Default mode
- Output paths

**Usage:**
```powershell
Copy-Item .nekorelease.example.json .nekorelease.json
# Edit .nekorelease.json with your settings
```

### Documentation

#### README.md
**Purpose:** Main entry point documentation

**Sections:**
- Features overview
- Prerequisites
- Quick start
- Parameter reference
- Configuration file
- Dry run mode
- Logging
- Skip options
- Usage examples
- Package manager outputs
- Workflow
- Platform support
- Troubleshooting

**Target Audience:** All users

#### QUICK_REFERENCE.md
**Purpose:** Fast lookup reference

**Sections:**
- All scripts with common commands
- Workflows
- Configuration file
- Package managers
- Modes
- Common commands
- Troubleshooting
- Exit codes
- Tips
- Decision tree

**Target Audience:** Experienced users needing quick answers

#### EXAMPLES.md
**Purpose:** Practical usage examples

**Contains:**
- 14+ examples
- Basic to advanced
- CI/CD integration
- Troubleshooting examples
- Release with validation workflows

**Target Audience:** Users learning the tool

#### CPP_EXAMPLES.md
**Purpose:** C++ ecosystem specific examples

**Sections:**
- vcpkg workflows
- Conan workflows
- Meson workflows
- Buckaroo workflows
- CPM workflows
- Local development
- CI/CD for C++ projects

**Target Audience:** C++ developers

#### UPDATE_MODE_EXAMPLES.md
**Purpose:** Mode system documentation

**Sections:**
- Auto mode examples
- Update mode examples
- Create mode examples
- Real-world scenarios
- Best practices

**Target Audience:** Users managing existing packages

#### ADVANCED_FEATURES.md
**Purpose:** Deep dive into advanced features

**Sections:**
- Configuration files (detailed)
- Dry run mode
- Logging system
- Package name customization
- Skip options
- Complete workflow examples
- Multi-project monorepo
- Best practices
- Security considerations

**Target Audience:** Power users, CI/CD implementers

#### TESTING.md
**Purpose:** Validation and testing guide

**Sections:**
- Validation checks (all 8 package managers)
- Testing support matrix
- Examples
- Understanding output
- Common issues
- Prerequisites
- Integration with NekoRelease
- Best practices

**Target Audience:** Quality assurance, package maintainers

## Supported Package Managers

### Windows Package Managers

| Manager | Files Generated | Validation | Testing |
|---------|----------------|------------|---------|
| **Chocolatey** | `.nuspec`, `chocolateyinstall.ps1` | ✅ | ❌ |
| **Scoop** | `.json` | ✅ | ✅ |
| **Winget** | `.yaml` | ✅ | ❌ |

### C++ Package Managers

| Manager | Files Generated | Validation | Testing |
|---------|----------------|------------|---------|
| **vcpkg** | `portfile.cmake`, `vcpkg.json`, `usage` | ✅ | ✅ |
| **Conan** | `conanfile.py`, `conandata.yml` | ✅ | ✅ |
| **Meson** | `.wrap` | ✅ | ❌ |
| **Buckaroo** | `buckaroo.json` | ✅ | ❌ |
| **CPM** | `.cmake` | ✅ | ✅ |

## Key Features

### 1. Release Automation
- Automatic Git tag creation and pushing
- GitHub/GitLab/Gitea release creation
- Multi-platform support

### 2. Hash Calculation
- Automatic download of release assets
- SHA256 hash calculation
- SHA512 for vcpkg

### 3. Package Generation
- 8 package managers supported
- Smart template system
- Auto/Update/Create modes

### 4. Configuration Management
- JSON configuration file
- CLI parameter override
- Package name auto-detection

### 5. Safety Features
- Dry run mode
- Logging to file
- Skip flags (tag/release)
- Validation before submission

### 6. Validation & Testing
- Structure validation
- Format checking
- Local installation testing
- Detailed error reporting

## Usage Patterns

### For New Projects

```
1. Copy .nekorelease.example.json → .nekorelease.json
2. Edit configuration
3. NekoRelease.ps1 -Version "v0.1.0" -DryRun (preview)
4. NekoRelease.ps1 -Version "v0.1.0" (execute)
5. Test-NekoPackages.ps1 (validate)
```

### For Existing Projects

```
1. NekoRelease.ps1 -Version "vX.Y.Z"
2. Test-NekoPackages.ps1
```

### For CI/CD

```
1. Release-WithValidation.ps1 -Version "$VERSION"
   (or use individual scripts with proper error handling)
```

## Technology Stack

- **Language:** PowerShell 5.1+/Core 7+
- **Dependencies:** Git, optional GitHub CLI
- **File Formats:** JSON, YAML, XML, Python, CMake, Meson
- **Hashing:** SHA256, SHA512
- **Platforms:** Windows, Linux (PowerShell Core), macOS (PowerShell Core)

## Development Stats

- **Total Lines of Code:** ~2500+ lines
- **Scripts:** 3
- **Documentation Files:** 7
- **Examples:** 50+
- **Supported Package Managers:** 8
- **Validation Functions:** 8
- **Test Functions:** 4

## Version History

### v1.0 (Current)
- ✅ Core release automation
- ✅ 8 package managers
- ✅ Configuration file support
- ✅ Dry run mode
- ✅ Logging system
- ✅ Package name customization
- ✅ Skip flags
- ✅ Validation and testing
- ✅ Complete documentation

## License

MIT License - See [LICENSE](LICENSE)

## Contributors

Project generated with AI assistance.

## Getting Started

### For First-Time Users
1. Read [README.md](README.md)
2. Review [EXAMPLES.md](EXAMPLES.md)
3. Try basic release workflow

### For C++ Developers
1. Read [README.md](README.md)
2. Review [CPP_EXAMPLES.md](CPP_EXAMPLES.md)
3. Try vcpkg or Conan workflow

### For CI/CD Engineers
1. Read [ADVANCED_FEATURES.md](ADVANCED_FEATURES.md)
2. Review CI/CD examples in [EXAMPLES.md](EXAMPLES.md)
3. Implement automated workflow

### For Package Maintainers
1. Read [UPDATE_MODE_EXAMPLES.md](UPDATE_MODE_EXAMPLES.md)
2. Review [TESTING.md](TESTING.md)
3. Set up validation pipeline

## Documentation Reading Order

### Beginner Path
1. README.md - Understand what NekoRelease does
2. EXAMPLES.md - See basic usage
3. QUICK_REFERENCE.md - Learn common commands

### Intermediate Path
1. README.md - Full feature overview
2. EXAMPLES.md - Try various examples
3. UPDATE_MODE_EXAMPLES.md - Understand modes
4. TESTING.md - Learn validation

### Advanced Path
1. README.md - Quick review
2. ADVANCED_FEATURES.md - Deep dive
3. TESTING.md - Validation strategies
4. CPP_EXAMPLES.md (if using C++)
5. QUICK_REFERENCE.md - Fast lookup

### CI/CD Implementation Path
1. README.md - Feature overview
2. ADVANCED_FEATURES.md - Configuration & logging
3. TESTING.md - Validation in pipelines
4. EXAMPLES.md - CI/CD examples
5. QUICK_REFERENCE.md - Command reference

## Support Matrix

### Operating Systems
- ✅ Windows 10/11
- ✅ Windows Server 2016+
- ✅ Linux (with PowerShell Core)
- ✅ macOS (with PowerShell Core)

### PowerShell Versions
- ✅ PowerShell 5.1 (Windows)
- ✅ PowerShell Core 7.x (all platforms)

### Git Hosting Platforms
- ✅ GitHub
- ✅ GitLab
- ✅ Gitea
- ✅ Forgejo

## Future Enhancements (Potential)

- Template system for custom package formats
- Multi-asset support (different architectures)
- Error recovery/rollback mechanism
- Interactive mode improvements
- Additional package managers
- Web UI for configuration

## Feedback and Contributions

Issues and Pull Requests welcome at the GitHub repository!

---

**Quick Links:**
- [Main Documentation](README.md)
- [Quick Reference](QUICK_REFERENCE.md)
- [Examples](EXAMPLES.md)
- [Testing Guide](TESTING.md)
