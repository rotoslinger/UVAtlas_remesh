#!/usr/bin/env pwsh
<#
.SYNOPSIS
    UVAtlas build script with automatic environment setup

.DESCRIPTION
    This script automatically sets up the build environment and runs the build.

.PARAMETER Configuration
    Build configuration: Debug, Release (default: Release)

.PARAMETER Platform
    Target platform: x64, x86, arm64, arm64ec (default: x64)

.PARAMETER Compiler
    Compiler to use: MSVC, Clang, MinGW, ICC, ICX (default: MSVC)

.PARAMETER BuildTools
    Build the UVAtlasTool executable (requires vcpkg dependencies)

.PARAMETER Clean
    Clean build directory before building

.PARAMETER Install
    Install the built artifacts

.PARAMETER Test
    Run tests after building

.PARAMETER Verbose
    Enable verbose output

.PARAMETER SkipEnvSetup
    Skip environment setup (use existing environment)

.EXAMPLE
    .\build-auto.ps1
    # Builds Release x64 with MSVC

.EXAMPLE
    .\build-auto.ps1 -Configuration Debug -Compiler Clang
    # Builds Debug x64 with Clang
#>

param(
    [Parameter()]
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",
    
    [Parameter()]
    [ValidateSet("x64", "x86", "arm64", "arm64ec")]
    [string]$Platform = "x64",
    
    [Parameter()]
    [ValidateSet("MSVC", "Clang", "MinGW", "ICC", "ICX")]
    [string]$Compiler = "MSVC",
    
    [Parameter()]
    [switch]$BuildTools,
    
    [Parameter()]
    [switch]$Clean,
    
    [Parameter()]
    [switch]$Install,
    
    [Parameter()]
    [switch]$Test,
    
    [Parameter()]
    [switch]$VerboseOutput,
    
    [Parameter()]
    [switch]$SkipEnvSetup
)

# Set up environment if not skipped
if (-not $SkipEnvSetup) {
    Write-Host "Setting up build environment..." -ForegroundColor Cyan
    
    # Source environment configuration if it exists
    if (Test-Path "build-env.ps1") {
        . "build-env.ps1"
        Write-Host "Environment configuration loaded" -ForegroundColor Green
    } else {
        Write-Host "No environment configuration found. Run setup-env.ps1 first." -ForegroundColor Yellow
    }
}

# Build arguments for the main build script
$buildArgs = @()

if ($Configuration -ne "Release") { $buildArgs += "-Configuration", $Configuration }
if ($Platform -ne "x64") { $buildArgs += "-Platform", $Platform }
if ($Compiler -ne "MSVC") { $buildArgs += "-Compiler", $Compiler }
if ($BuildTools) { $buildArgs += "-BuildTools" }
if ($Clean) { $buildArgs += "-Clean" }
if ($Install) { $buildArgs += "-Install" }
if ($Test) { $buildArgs += "-Test" }
if ($VerboseOutput) { $buildArgs += "-VerboseOutput" }

# Run the main build script
& ".\build.ps1" @buildArgs
