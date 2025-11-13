# C++ Package Manager Examples

This document provides specific examples for using NekoRelease with C++ package managers (vcpkg and Conan).

## vcpkg Examples

### Example 1: Basic vcpkg Port Generation

```powershell
# Generate vcpkg port files
.\NekoRelease.ps1 `
    -Version "v1.0.0" `
    -RepositoryUrl "https://github.com/myorg/mycpplib" `
    -PackageManagers @("vcpkg")
```

This generates:
- `packages/vcpkg/nekorelease/vcpkg.json`
- `packages/vcpkg/nekorelease/portfile.cmake`

### Example 2: vcpkg with Custom Output Path

```powershell
# Output to vcpkg registry directory
.\NekoRelease.ps1 `
    -Version "v2.0.0" `
    -PackageManagers @("vcpkg") `
    -OutputPaths @{
        "vcpkg" = "C:\vcpkg\ports"
    }
```

### Example 3: Submit to vcpkg Registry

After generating the port files:

```powershell
# 1. Generate the port
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("vcpkg")

# 2. Copy to vcpkg registry
Copy-Item -Recurse packages\vcpkg\nekorelease C:\vcpkg\ports\

# 3. Test the port
cd C:\vcpkg
.\vcpkg install nekorelease

# 4. Submit to vcpkg repository
# Follow instructions at: https://github.com/microsoft/vcpkg/blob/master/docs/maintainers/ports/vcpkg-port-submissions.md
```

### Example 4: vcpkg Version Update Workflow

```powershell
# Update existing vcpkg port
$version = "v1.2.3"

# Generate new port files
.\NekoRelease.ps1 `
    -Version $version `
    -RepositoryUrl "https://github.com/myorg/mycpplib" `
    -PackageManagers @("vcpkg") `
    -OutputPaths @{
        "vcpkg" = ".\vcpkg-registry\ports"
    }

# Update version in vcpkg registry
# The portfile.cmake and vcpkg.json are now ready to commit
```

## Conan Examples

### Example 1: Basic Conan Recipe Generation

```powershell
# Generate Conan recipe
.\NekoRelease.ps1 `
    -Version "v1.0.0" `
    -RepositoryUrl "https://github.com/myorg/mycpplib" `
    -PackageManagers @("Conan")
```

This generates:
- `packages/Conan/conanfile.py`
- `packages/Conan/conandata.yml`

### Example 2: Conan with Custom Output

```powershell
# Output to Conan recipe directory
.\NekoRelease.ps1 `
    -Version "v2.1.0" `
    -PackageManagers @("Conan") `
    -OutputPaths @{
        "Conan" = "C:\conan-recipes\nekorelease\all"
    }
```

### Example 3: Test Conan Recipe Locally

```powershell
# 1. Generate the recipe
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("Conan")

# 2. Navigate to recipe directory
cd packages\Conan

# 3. Create the package
conan create . --version=1.0.0

# 4. Test in a project
cd C:\MyProject
# Add to conanfile.txt:
# [requires]
# nekorelease/1.0.0

conan install . --build=missing
```

### Example 4: Submit to Conan Center

```powershell
# 1. Generate recipe
.\NekoRelease.ps1 `
    -Version "v1.0.0" `
    -RepositoryUrl "https://github.com/myorg/mycpplib" `
    -PackageManagers @("Conan") `
    -OutputPaths @{
        "Conan" = "C:\conan-center-index\recipes\mycpplib\all"
    }

# 2. Follow Conan Center submission guidelines
# https://github.com/conan-io/conan-center-index/blob/master/docs/how_to_add_packages.md
```

## Combined Examples

### Example 1: Both vcpkg and Conan

```powershell
# Generate both C++ package manager files
.\NekoRelease.ps1 `
    -Version "v1.5.0" `
    -RepositoryUrl "https://github.com/myorg/awesomelib" `
    -PackageManagers @("vcpkg", "Conan")
```

### Example 2: Full C++ Library Release

```powershell
param([string]$Version)

# Complete C++ library release workflow
Write-Host "Releasing C++ library: $Version" -ForegroundColor Cyan

# 1. Build and test
Write-Host "`n[1/5] Building and testing..." -ForegroundColor Yellow
cmake -B build -S .
cmake --build build
ctest --test-dir build

# 2. Update documentation
Write-Host "`n[2/5] Updating documentation..." -ForegroundColor Yellow
# doxygen Doxyfile

# 3. Commit changes
Write-Host "`n[3/5] Committing changes..." -ForegroundColor Yellow
git add .
git commit -m "Release $Version"
git push origin main

# 4. Create release and generate package files
Write-Host "`n[4/5] Creating release..." -ForegroundColor Yellow
.\NekoRelease.ps1 `
    -Version $Version `
    -PackageManagers @("vcpkg", "Conan")

# 5. Post-release tasks
Write-Host "`n[5/5] Post-release tasks..." -ForegroundColor Yellow
Write-Host "Package files generated:"
Write-Host "  - vcpkg: packages\vcpkg\nekorelease\"
Write-Host "  - Conan: packages\Conan\"
Write-Host "`nNext steps:"
Write-Host "  1. Test vcpkg port: vcpkg install nekorelease"
Write-Host "  2. Test Conan recipe: conan create packages\Conan --version=$($Version -replace '^v', '')"
Write-Host "  3. Submit to package registries"

Write-Host "`n✓ Release complete!" -ForegroundColor Green
```

Usage:
```powershell
.\cpp-release.ps1 -Version "v2.0.0"
```

### Example 3: Multi-Platform C++ Library

```powershell
# Release with platform-specific considerations
.\NekoRelease.ps1 `
    -Version "v1.0.0" `
    -RepositoryUrl "https://github.com/myorg/crossplatformlib" `
    -PackageManagers @("vcpkg", "Conan")

# After generation, customize the files for platform specifics:
# - Edit portfile.cmake for vcpkg-specific build options
# - Edit conanfile.py for Conan platform settings
```

## Advanced Scenarios

### Scenario 1: Header-Only Library

For header-only libraries, you might want to customize the generated files:

```powershell
# 1. Generate base files
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("vcpkg", "Conan")

# 2. Manually edit portfile.cmake
# Change from:
#   vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
# To:
#   set(VCPKG_BUILD_TYPE release)

# 3. Manually edit conanfile.py
# Add:
#   package_type = "header-library"
#   no_copy_source = True
```

### Scenario 2: Library with Dependencies

```powershell
# Generate package files
.\NekoRelease.ps1 -Version "v1.0.0" -PackageManagers @("vcpkg", "Conan")

# Then edit vcpkg.json to add dependencies:
# {
#   "name": "nekorelease",
#   "version": "1.0.0",
#   "dependencies": [
#     "fmt",
#     "spdlog"
#   ]
# }

# And edit conanfile.py:
# def requirements(self):
#     self.requires("fmt/9.1.0")
#     self.requires("spdlog/1.11.0")
```

### Scenario 3: Automated Registry Submission

```powershell
# Complete automation script for vcpkg submission
param([string]$Version)

$repo = "myorg/mycpplib"
$vcpkgFork = "C:\vcpkg-fork"

# 1. Release and generate
.\NekoRelease.ps1 -Version $Version -PackageManagers @("vcpkg")

# 2. Copy to vcpkg fork
$portName = "mycpplib"
Copy-Item -Recurse "packages\vcpkg\nekorelease" "$vcpkgFork\ports\$portName"

# 3. Update versions
cd $vcpkgFork
.\vcpkg x-add-version $portName

# 4. Test
.\vcpkg install $portName

# 5. Create PR
git checkout -b "update-$portName-$Version"
git add .
git commit -m "[$portName] Update to $Version"
git push origin "update-$portName-$Version"

# 6. Create GitHub PR
gh pr create --title "[$portName] Update to $Version" --body "Update $portName to version $Version"
```

## Integration with CMake

### Example: CMakeLists.txt for vcpkg

```cmake
cmake_minimum_required(VERSION 3.20)
project(MyProject VERSION 1.0.0)

# Find package installed via vcpkg
find_package(nekorelease CONFIG REQUIRED)

add_executable(myapp main.cpp)
target_link_libraries(myapp PRIVATE nekorelease::nekorelease)
```

### Example: Using Conan with CMake

```cmake
cmake_minimum_required(VERSION 3.20)
project(MyProject VERSION 1.0.0)

# Conan integration
include(${CMAKE_BINARY_DIR}/conan_toolchain.cmake)

find_package(nekorelease REQUIRED)

add_executable(myapp main.cpp)
target_link_libraries(myapp PRIVATE nekorelease::nekorelease)
```

## Troubleshooting

### vcpkg Hash Mismatch

If vcpkg reports SHA512 hash mismatch:

```powershell
# 1. Download the source archive
$version = "v1.0.0"
$url = "https://github.com/myorg/mycpplib/archive/refs/tags/$version.tar.gz"
Invoke-WebRequest -Uri $url -OutFile "source.tar.gz"

# 2. Calculate SHA512
$hash = Get-FileHash -Path "source.tar.gz" -Algorithm SHA512
Write-Host "SHA512: $($hash.Hash)"

# 3. Update portfile.cmake with correct hash
```

### Conan Recipe Testing

```powershell
# Test recipe with verbose output
conan create packages\Conan --version=1.0.0 -vv

# Test with specific profile
conan create packages\Conan --version=1.0.0 --profile=default

# Test build on different configurations
conan create packages\Conan --version=1.0.0 -s build_type=Debug
conan create packages\Conan --version=1.0.0 -s build_type=Release
```

## Best Practices

1. **Version Consistency**: Always remove the 'v' prefix for C++ package managers
   ```powershell
   # Good: 1.0.0 (for vcpkg and Conan)
   # Not: v1.0.0
   ```

2. **Test Before Submission**: Always test locally before submitting to registries
   ```powershell
   # vcpkg
   vcpkg install nekorelease --overlay-ports=packages\vcpkg
   
   # Conan
   conan create packages\Conan --version=1.0.0
   ```

3. **Follow Registry Guidelines**:
   - vcpkg: <https://github.com/microsoft/vcpkg/tree/master/docs/maintainers>
   - Conan Center: <https://github.com/conan-io/conan-center-index/tree/master/docs>

4. **Keep Package Files Updated**: Re-generate after each release
   ```powershell
   .\NekoRelease.ps1 -Version $newVersion -PackageManagers @("vcpkg", "Conan")
   ```
