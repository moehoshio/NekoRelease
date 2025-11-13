# Contributing to NekoRelease

Thank you for considering contributing to NekoRelease! This document provides guidelines and instructions for contributing.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:

- Clear description of the problem
- Steps to reproduce
- Expected behavior
- Actual behavior
- PowerShell version (`$PSVersionTable.PSVersion`)
- Operating system
- Relevant error messages or logs

**Example:**

```
## Bug Report

**Description:** vcpkg port generation fails when project name contains hyphens

**Steps to Reproduce:**
1. Run `.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("vcpkg")`
2. Project name is "my-project"

**Expected:** Port should be generated with valid name
**Actual:** Error about invalid port name

**Environment:**
- PowerShell: 7.3.0
- OS: Windows 11
- Git: 2.40.0

**Error Message:**
```
Error: Invalid port name 'my-project'
```
```

### Suggesting Features

Feature requests are welcome! Please include:

- Clear description of the feature
- Use case or motivation
- Examples of how it would work
- Any alternatives you've considered

**Example:**

```
## Feature Request

**Feature:** Support for Homebrew package manager

**Motivation:** Many macOS developers use Homebrew for package management

**Proposed Usage:**
```powershell
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("Homebrew")
```

**Output:** Generate `Formula/myproject.rb`
```

### Submitting Pull Requests

1. **Fork the repository**
2. **Create a feature branch**
   ```powershell
   git checkout -b feature/my-new-feature
   ```
3. **Make your changes**
4. **Test thoroughly**
   ```powershell
   # Test the main script
   .\NekoRelease.ps1 -Version "v0.1.0-test" -DryRun
   
   # Test validation
   .\Test-NekoPackages.ps1 -Verbose
   ```
5. **Update documentation** if needed
6. **Commit your changes**
   ```powershell
   git commit -m "feat: add support for Homebrew package manager"
   ```
7. **Push to your fork**
   ```powershell
   git push origin feature/my-new-feature
   ```
8. **Create a Pull Request**

### Commit Message Convention

We use conventional commits format:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**

```
feat(vcpkg): add support for version constraints

Allows specifying version constraints in vcpkg.json
for more flexible dependency management.
```

```
fix(conan): handle special characters in package name

Package names with hyphens or underscores are now
properly escaped in conanfile.py.
```

```
docs(readme): add troubleshooting section for Windows

Added common Windows-specific issues and solutions.
```

## Development Guidelines

### Code Style

**PowerShell Best Practices:**

1. **Use approved verbs** for function names
   ```powershell
   # Good
   function Get-PackageInfo { }
   
   # Bad
   function Fetch-PackageInfo { }
   ```

2. **Use PascalCase** for function names
   ```powershell
   # Good
   function Test-PackageStructure { }
   
   # Bad
   function test_package_structure { }
   ```

3. **Use camelCase** for variables
   ```powershell
   # Good
   $packageName = "myproject"
   
   # Bad
   $package_name = "myproject"
   ```

4. **Add comment-based help** for functions
   ```powershell
   <#
   .SYNOPSIS
       Short description
   
   .DESCRIPTION
       Detailed description
   
   .PARAMETER ParamName
       Parameter description
   
   .EXAMPLE
       Example usage
   #>
   function MyFunction {
       param([string]$ParamName)
   }
   ```

5. **Use strict mode**
   ```powershell
   Set-StrictMode -Version Latest
   ```

6. **Handle errors properly**
   ```powershell
   try {
       # Code that might fail
   } catch {
       Write-Error "Detailed error message: $($_.Exception.Message)"
       return $false
   }
   ```

### Adding a New Package Manager

To add support for a new package manager:

1. **Create generation function** in `NekoRelease.ps1`:

   ```powershell
   function Generate-MyPackageManager {
       param(
           [string]$PackageName,
           [string]$Version,
           [string]$OutputPath,
           [string]$Url,
           [string]$Hash
       )
       
       # Create output directory
       if (-not (Test-Path $OutputPath)) {
           New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
       }
       
       # Generate package files
       $content = @"
   # Package file content
   name: $PackageName
   version: $Version
   url: $Url
   hash: $Hash
   "@
       
       $filePath = Join-Path $OutputPath "package.yaml"
       $content | Out-File -FilePath $filePath -Encoding utf8
       
       Write-Success "Generated MyPackageManager package at: $filePath"
   }
   ```

2. **Add validation function** in `Test-NekoPackages.ps1`:

   ```powershell
   function Test-MyPackageManager {
       param([string]$Path)
       
       Write-SectionHeader "Validating MyPackageManager Package"
       
       $packageFile = Join-Path $Path "package.yaml"
       $issues = @()
       
       if (-not (Test-Path $packageFile)) {
           $issues += "Missing package.yaml"
       } else {
           Write-Success "Found package.yaml"
           
           # Validate content
           $content = Get-Content $packageFile -Raw
           
           if ($content -notmatch "name:") {
               $issues += "Missing 'name' field"
           }
           
           # Add more validation...
       }
       
       return @{
           Valid = ($issues.Count -eq 0)
           Issues = $issues
           CanTest = $false  # or $true if testing is supported
           TestCommand = $null  # or test command if supported
       }
   }
   ```

3. **Update main switch statements** in both scripts

4. **Add to ValidateSet** in parameters:
   ```powershell
   [ValidateSet("Chocolatey", "Scoop", "Winget", "vcpkg", "Conan", "Meson", "Buckaroo", "CPM", "MyPackageManager")]
   ```

5. **Update documentation**:
   - Add to README.md package manager list
   - Create example in EXAMPLES.md
   - Add validation details in TESTING.md

6. **Test thoroughly**:
   ```powershell
   # Test generation
   .\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("MyPackageManager")
   
   # Test validation
   .\Test-NekoPackages.ps1 -PackageManagers @("MyPackageManager") -Verbose
   ```

### Testing

**Before submitting a PR, test:**

1. **Main functionality**
   ```powershell
   .\NekoRelease.ps1 -Version "v0.1.0-test" -DryRun
   ```

2. **All package managers**
   ```powershell
   .\NekoRelease.ps1 `
       -Version "v0.1.0-test" `
       -PackageManagers @("Chocolatey", "Scoop", "Winget", "vcpkg", "Conan", "Meson", "Buckaroo", "CPM")
   ```

3. **Validation**
   ```powershell
   .\Test-NekoPackages.ps1 -Verbose
   ```

4. **Different modes**
   ```powershell
   .\NekoRelease.ps1 -Version "v0.1.0-test" -Mode "Create"
   .\NekoRelease.ps1 -Version "v0.1.0-test" -Mode "Update"
   .\NekoRelease.ps1 -Version "v0.1.0-test" -Mode "Auto"
   ```

5. **Edge cases**
   - Empty repository
   - No remote URL
   - Special characters in names
   - Missing files
   - Invalid configurations

### Documentation

**When adding features, update:**

- `README.md` - Main features and parameters
- `EXAMPLES.md` - Add usage examples
- `QUICK_REFERENCE.md` - Add quick commands
- `TESTING.md` - If adding validation
- `CHANGELOG.md` - Document the change
- Function help comments

**Documentation style:**

- Use clear, concise language
- Provide code examples
- Include expected output
- Show both success and failure cases
- Use proper markdown formatting

## Project Structure

```
NekoRelease/
├── NekoRelease.ps1              # Main script
├── Test-NekoPackages.ps1        # Validation script
├── Release-WithValidation.ps1   # Workflow script
├── .nekorelease.example.json    # Config template
├── README.md                    # Main docs
├── EXAMPLES.md                  # Usage examples
├── CPP_EXAMPLES.md              # C++ examples
├── UPDATE_MODE_EXAMPLES.md      # Mode examples
├── ADVANCED_FEATURES.md         # Advanced guide
├── TESTING.md                   # Testing guide
├── QUICK_REFERENCE.md           # Quick reference
├── PROJECT_OVERVIEW.md          # Project overview
├── CHANGELOG.md                 # Version history
├── CONTRIBUTING.md              # This file
└── LICENSE                      # MIT License
```

## Getting Help

- Check existing issues
- Review documentation
- Ask in discussions (if available)
- Create a new issue with questions

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the code, not the person
- Help others learn and grow

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Recognition

Contributors will be recognized in:
- README.md contributors section (if created)
- CHANGELOG.md for their contributions
- Git commit history

Thank you for contributing to NekoRelease! 🎉
