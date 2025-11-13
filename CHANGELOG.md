# Changelog

All notable changes to NekoRelease will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-14

### Added

#### Core Features
- **Release Automation**: Automatic Git tag creation and pushing
- **GitHub Release Creation**: Support for gh CLI and manual URL provision
- **Multi-Platform Support**: GitHub, GitLab, Gitea, Forgejo
- **Hash Calculation**: Automatic download and SHA256/SHA512 hash calculation
- **8 Package Managers**: Chocolatey, Scoop, Winget, vcpkg, Conan, Meson WrapDB, Buckaroo, CPM

#### Advanced Features
- **Configuration File Support**: `.nekorelease.json` for storing default settings
- **Dry Run Mode**: Preview changes without executing (`-DryRun` parameter)
- **Logging System**: File-based logging for debugging and audit (`-LogFile` parameter)
- **Package Name Customization**: Auto-detection and override (`-PackageName` parameter)
- **Skip Flags**: Granular control with `-SkipGitTag` and `-SkipRelease`

#### Mode System
- **Auto Mode**: Automatically detect and update existing files or create new ones
- **Update Mode**: Only update existing package files
- **Create Mode**: Always create new files with backup of existing ones

#### Validation & Testing
- **Test-NekoPackages.ps1**: Comprehensive validation and testing script
- **Structure Validation**: Check package file formats and required fields
- **Content Validation**: Verify package manager specific requirements
- **Installation Testing**: Local installation tests for Scoop, vcpkg, Conan, CPM
- **Release-WithValidation.ps1**: Integrated workflow script

#### Scripts
- `NekoRelease.ps1` - Main release automation script (~1400 lines)
- `Test-NekoPackages.ps1` - Validation and testing script (~900 lines)
- `Release-WithValidation.ps1` - Complete workflow script (~200 lines)

#### Documentation
- `README.md` - Main documentation with comprehensive guide
- `QUICK_REFERENCE.md` - Fast lookup reference for all commands
- `EXAMPLES.md` - 14+ practical usage examples
- `CPP_EXAMPLES.md` - C++ package manager specific workflows
- `UPDATE_MODE_EXAMPLES.md` - Mode system documentation and examples
- `ADVANCED_FEATURES.md` - Deep dive into configuration, dry run, logging
- `TESTING.md` - Validation and testing guide
- `PROJECT_OVERVIEW.md` - Complete project structure and overview

#### Configuration
- `.nekorelease.example.json` - Configuration file template
- Support for CLI parameter override of config values

### Package Manager Support

#### Windows Package Managers
- **Chocolatey**: `.nuspec` and `chocolateyinstall.ps1` generation
- **Scoop**: JSON manifest generation with validation and local testing
- **Winget**: YAML manifest generation with validation

#### C++ Package Managers
- **vcpkg**: Complete port generation (`portfile.cmake`, `vcpkg.json`, `usage`)
- **Conan**: Recipe generation (`conanfile.py`, `conandata.yml`)
- **Meson WrapDB**: Wrap file generation for both wrap-file and wrap-git
- **Buckaroo**: JSON manifest generation
- **CPM**: CMake configuration generation with CPMAddPackage

### Validation Features

#### All Package Managers
- File structure validation
- Required field checking
- Format validation (JSON, YAML, XML, Python, CMake)
- Placeholder detection
- Hash format verification

#### Testing Support
- ✅ Scoop: Local manifest installation testing
- ✅ vcpkg: Overlay ports validation with dry-run
- ✅ Conan: Recipe export validation
- ✅ CPM: CMake configuration syntax testing

### Features by Component

#### NekoRelease.ps1
- 11 parameters for full customization
- Git remote URL auto-detection with SSH→HTTPS conversion
- Colored console output for better readability
- Smart file updating that preserves custom modifications
- Backup system for Create mode
- Error handling and validation
- Support for interactive and non-interactive modes

#### Test-NekoPackages.ps1
- Auto-detection of package managers in output directory
- Detailed validation output with success/warning/error indicators
- Verbose mode for debugging
- Summary reporting with pass/fail counts
- Exit codes suitable for CI/CD pipelines
- Support for selective testing

#### Release-WithValidation.ps1
- Beautiful ASCII art console output
- Three-step workflow (Generate → Validate → Summary)
- Automatic error handling and reporting
- Next steps guidance
- Skip options for flexible workflows

### Documentation Highlights
- 50+ examples across all documentation files
- Complete API reference for all parameters
- Troubleshooting guides with solutions
- Best practices and tips
- CI/CD integration examples
- Security considerations

### Platform Support
- ✅ Windows 10/11 with PowerShell 5.1+
- ✅ Windows Server 2016+ with PowerShell 5.1+
- ✅ Linux with PowerShell Core 7+
- ✅ macOS with PowerShell Core 7+

### Dependencies
- Required: Git
- Optional: GitHub CLI (`gh`) for GitHub release creation
- Optional: Package managers for local testing (scoop, vcpkg, conan, cmake)

---

## [Future Enhancements]

### Under Consideration
- Template system for custom package formats
- Multi-asset support for different platforms/architectures
- Error recovery and rollback mechanism
- Interactive configuration wizard
- Additional package managers (apt, yum, brew, cargo, npm)
- Web UI for configuration
- Package submission automation
- Version bump automation from git history
- Changelog generation
- Release notes generation from commits

---

## Development Notes

### Technology Stack
- PowerShell 5.1+ / PowerShell Core 7+
- JSON, YAML, XML parsing
- CMake, Meson, Python file generation
- SHA256, SHA512 hashing
- Git integration
- GitHub CLI integration

### Code Statistics (v1.0.0)
- Total Lines: ~2500+
- Scripts: 3
- Functions: 30+
- Documentation Files: 8
- Examples: 50+
- Supported Package Managers: 8
- Validation Functions: 8
- Test Functions: 4

### Development Timeline
- Initial release automation: Core Git and release functionality
- Package manager expansion: Added 8 package managers with smart templates
- Mode system: Implemented Auto/Update/Create modes
- Advanced features: Configuration files, dry run, logging, skip flags
- Validation system: Complete testing and validation framework
- Documentation: Comprehensive guides and examples

---

## License

MIT License - See [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- Project generated with AI assistance
- Inspired by the need for streamlined release automation
- Built for the Neko ecosystem

---

**For detailed usage instructions, see [README.md](README.md)**

**For quick commands, see [QUICK_REFERENCE.md](QUICK_REFERENCE.md)**

**For examples, see [EXAMPLES.md](EXAMPLES.md)**
