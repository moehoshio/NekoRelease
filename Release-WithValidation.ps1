<#
.SYNOPSIS
    Complete release workflow with validation and testing.

.DESCRIPTION
    This script demonstrates the complete release workflow:
    1. Generate packages with NekoRelease
    2. Validate package structure
    3. Test installation (where supported)
    4. Report results

.PARAMETER Version
    Version to release (e.g., v1.0.0)

.PARAMETER ConfigFile
    Configuration file for NekoRelease (default: .nekorelease.json)

.PARAMETER SkipValidation
    Skip package validation

.PARAMETER SkipTesting
    Skip installation testing

.EXAMPLE
    .\Release-WithValidation.ps1 -Version "v1.0.0"
    Complete release with validation and testing

.EXAMPLE
    .\Release-WithValidation.ps1 -Version "v1.0.0" -SkipTesting
    Release and validate, but skip installation tests
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Version,

    [Parameter()]
    [string]$ConfigFile = ".nekorelease.json",

    [Parameter()]
    [switch]$SkipValidation,

    [Parameter()]
    [switch]$SkipTesting,

    [Parameter()]
    [switch]$SkipGitTag,

    [Parameter()]
    [switch]$SkipRelease,

    [Parameter()]
    [string[]]$PackageManagers,

    [Parameter()]
    [string]$PackageName,

    [Parameter()]
    [switch]$Interactive
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  $($Message.PadRight(61))║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Failure {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

# Header
Write-Host "`n"
Write-Host "██████╗ ███████╗██╗     ███████╗ █████╗ ███████╗███████╗" -ForegroundColor Magenta
Write-Host "██╔══██╗██╔════╝██║     ██╔════╝██╔══██╗██╔════╝██╔════╝" -ForegroundColor Magenta
Write-Host "██████╔╝█████╗  ██║     █████╗  ███████║███████╗█████╗  " -ForegroundColor Magenta
Write-Host "██╔══██╗██╔══╝  ██║     ██╔══╝  ██╔══██║╚════██║██╔══╝  " -ForegroundColor Magenta
Write-Host "██║  ██║███████╗███████╗███████╗██║  ██║███████║███████╗" -ForegroundColor Magenta
Write-Host "╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝" -ForegroundColor Magenta
Write-Host "          Complete Workflow with Validation              " -ForegroundColor Cyan
Write-Host "`n"

# Step 1: Generate packages
Write-Step "STEP 1/3: Generating Packages"

Write-Host "Version: $Version" -ForegroundColor Yellow
Write-Host "Config:  $ConfigFile" -ForegroundColor Yellow
Write-Host ""

$releaseArgs = @{}
$releaseArgs['Version'] = $Version

if (Test-Path $ConfigFile) {
    $releaseArgs['ConfigFile'] = $ConfigFile
    Write-Host "Using configuration file: $ConfigFile" -ForegroundColor Cyan
} else {
    Write-Host "No configuration file found, using defaults" -ForegroundColor Yellow
}

# Add optional switches
if ($SkipGitTag) { $releaseArgs['SkipGitTag'] = $true }
if ($SkipRelease) { $releaseArgs['SkipRelease'] = $true }
if ($PSBoundParameters.ContainsKey('PackageManagers')) { $releaseArgs['PackageManagers'] = $PackageManagers }
if ($PSBoundParameters.ContainsKey('PackageName')) { $releaseArgs['PackageName'] = $PackageName }
if ($PSBoundParameters.ContainsKey('Interactive')) { $releaseArgs['Interactive'] = $Interactive }

try {
    & ".\NekoRelease.ps1" @releaseArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Package generation completed successfully"
    } else {
        Write-Failure "Package generation failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
} catch {
    Write-Failure "Package generation failed: $($_.Exception.Message)"
    exit 1
}

# Step 2: Validate packages
if (-not $SkipValidation) {
    Write-Step "STEP 2/3: Validating Packages"
    
    $validateArgs = @()
    
    if ($SkipTesting) {
        $validateArgs += "-ValidateOnly"
    }
    
    try {
        & ".\Test-NekoPackages.ps1" @validateArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Package validation completed successfully"
        } else {
            Write-Failure "Package validation failed with exit code $LASTEXITCODE"
            Write-Host "`nPlease review the validation errors above and fix the issues." -ForegroundColor Yellow
            Write-Host "You can re-run NekoRelease to regenerate packages after fixing." -ForegroundColor Yellow
            exit $LASTEXITCODE
        }
    } catch {
        Write-Failure "Package validation failed: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Host "`nℹ Skipping validation (use without -SkipValidation to enable)" -ForegroundColor Yellow
}

# Step 3: Summary
Write-Step "STEP 3/3: Summary"

Write-Host "Release workflow completed for version: " -NoNewline
Write-Host "$Version" -ForegroundColor Green

Write-Host "`nGenerated packages are in: " -NoNewline
Write-Host ".\packages" -ForegroundColor Cyan

if (Test-Path ".\packages") {
    Write-Host "`nPackage directories:" -ForegroundColor Yellow
    Get-ChildItem -Path ".\packages" -Directory | ForEach-Object {
        Write-Host "  • $($_.Name)" -ForegroundColor Cyan
    }
}

Write-Host "`n"
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "                    RELEASE SUCCESSFUL! 🎉                      " -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "`n"

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review generated package files in .\packages" -ForegroundColor White
Write-Host "  2. Test packages locally (if you haven't already)" -ForegroundColor White
Write-Host "  3. Submit packages to respective repositories:" -ForegroundColor White
Write-Host "     • vcpkg: Create PR to microsoft/vcpkg" -ForegroundColor Cyan
Write-Host "     • Conan: Submit to ConanCenter" -ForegroundColor Cyan
Write-Host "     • Scoop: Create PR to bucket repository" -ForegroundColor Cyan
Write-Host "     • Chocolatey: Upload to chocolatey.org" -ForegroundColor Cyan
Write-Host "     • Winget: Create PR to microsoft/winget-pkgs" -ForegroundColor Cyan
Write-Host "`n"

exit 0
