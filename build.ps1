#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build script for UVAtlas project

.DESCRIPTION
    This script builds the UVAtlas library and optionally the UVAtlasTool executable.
    Supports multiple platforms, architectures, and compilers.

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

.EXAMPLE
    .\build.ps1
    # Builds Release x64 with MSVC

.EXAMPLE
    .\build.ps1 -Configuration Debug -Platform x64 -BuildTools
    # Builds Debug x64 with MSVC including tools

.EXAMPLE
    .\build.ps1 -Configuration Release -Platform arm64 -Compiler Clang
    # Builds Release ARM64 with Clang

.EXAMPLE
    .\build.ps1 -Clean -Install -Test
    # Cleans, builds, installs, and tests
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
    [switch]$Help
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check if command exists
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-ColorOutput "Checking prerequisites..." "Cyan"
    
    # Check CMake
    if (-not (Test-Command "cmake")) {
        Write-ColorOutput "ERROR: CMake not found. Please install CMake 3.20 or later." "Red"
        return $false
    }
    
    # Check Ninja
    if (-not (Test-Command "ninja")) {
        Write-ColorOutput "WARNING: Ninja not found. Install Ninja for faster builds." "Yellow"
        Write-ColorOutput "  Install via: winget install Ninja-build.Ninja" "Yellow"
        Write-ColorOutput "  Or download from: https://github.com/ninja-build/ninja/releases" "Yellow"
    } else {
        $ninjaVersion = & ninja --version 2>$null
        if ($ninjaVersion) {
            Write-ColorOutput "Found Ninja version: $ninjaVersion" "Green"
        }
    }
    
    # Check vcpkg if building tools
    if ($BuildTools) {
        if (-not $env:VCPKG_ROOT) {
            Write-ColorOutput "WARNING: VCPKG_ROOT environment variable not set. Tools may not build correctly." "Yellow"
        }
    }
    
    # Check Visual Studio if using MSVC
    if ($Compiler -eq "MSVC") {
        $vsPath = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath 2>$null
        if (-not $vsPath) {
            Write-ColorOutput "WARNING: Visual Studio not found. MSVC builds may fail." "Yellow"
        }
    }
    
    return $true
}

# Function to determine preset name
function Get-PresetName {
    $preset = "$Platform-$Configuration"
    
    if ($BuildTools) {
        $preset += "-VCPKG"
    }
    
    switch ($Compiler) {
        "Clang" { $preset += "-Clang" }
        "MinGW" { $preset += "-MinGW" }
        "ICC" { $preset += "-ICC" }
        "ICX" { $preset += "-ICX" }
    }
    
    return $preset
}

# Function to clean build directory
function Clear-BuildDirectory {
    Write-ColorOutput "Cleaning build directory..." "Cyan"
    
    $buildDir = "out"
    if (Test-Path $buildDir) {
        Remove-Item -Path $buildDir -Recurse -Force
        Write-ColorOutput "Build directory cleaned." "Green"
    }
}

# Function to configure build
function Invoke-Configure {
    param([string]$Preset)
    
    Write-ColorOutput "Configuring build with preset: $Preset" "Cyan"
    
    $cmakeArgs = @(
        "--preset", $Preset
    )
    
    if ($VerboseOutput) {
        $cmakeArgs += "--verbose"
    }
    
    $result = & cmake @cmakeArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "ERROR: CMake configuration failed!" "Red"
        return $false
    }
    
    Write-ColorOutput "Configuration completed successfully." "Green"
    return $true
}

# Function to build project
function Invoke-Build {
    param([string]$Preset)
    
    Write-ColorOutput "Building project..." "Cyan"
    
    # Use the build directory from the configure preset
    $buildDir = "out/build/$Preset"
    
    $cmakeArgs = @(
        "--build", $buildDir
    )
    
    if ($VerboseOutput) {
        $cmakeArgs += "--verbose"
    }
    
    $result = & cmake @cmakeArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "ERROR: Build failed!" "Red"
        return $false
    }
    
    Write-ColorOutput "Build completed successfully." "Green"
    return $true
}

# Function to install project
function Invoke-Install {
    param([string]$Preset)
    
    Write-ColorOutput "Installing project..." "Cyan"
    
    # Use the build directory from the configure preset
    $buildDir = "out/build/$Preset"
    
    $cmakeArgs = @(
        "--install", $buildDir
    )
    
    if ($VerboseOutput) {
        $cmakeArgs += "--verbose"
    }
    
    $result = & cmake @cmakeArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "ERROR: Installation failed!" "Red"
        return $false
    }
    
    Write-ColorOutput "Installation completed successfully." "Green"
    return $true
}

# Function to run tests
function Invoke-Test {
    param([string]$Preset)
    
    Write-ColorOutput "Running tests..." "Cyan"
    
    $cmakeArgs = @(
        "--preset", $Preset
    )
    
    $result = & ctest @cmakeArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "WARNING: Some tests failed!" "Yellow"
        return $false
    }
    
    Write-ColorOutput "All tests passed." "Green"
    return $true
}

# Function to show build information
function Show-BuildInfo {
    Write-ColorOutput "`nBuild Configuration:" "Cyan"
    Write-ColorOutput "  Configuration: $Configuration" "White"
    Write-ColorOutput "  Platform: $Platform" "White"
    Write-ColorOutput "  Compiler: $Compiler" "White"
    Write-ColorOutput "  Build Tools: $BuildTools" "White"
    Write-ColorOutput "  Clean: $Clean" "White"
    Write-ColorOutput "  Install: $Install" "White"
    Write-ColorOutput "  Test: $Test" "White"
    Write-ColorOutput "  Verbose: $VerboseOutput" "White"
    Write-ColorOutput ""
}

# Main execution
function Main {
    # Show help if requested
    if ($Help) {
        Get-Help $PSCommandPath -Full
        return
    }
    
    Write-ColorOutput "UVAtlas Build Script" "Green"
    Write-ColorOutput "===================" "Green"
    
    Show-BuildInfo
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    # Get preset name
    $preset = Get-PresetName
    Write-ColorOutput "Using preset: $preset" "Cyan"
    
    # Clean if requested
    if ($Clean) {
        Clear-BuildDirectory
    }
    
    # Configure
    if (-not (Invoke-Configure -Preset $preset)) {
        exit 1
    }
    
    # Build
    if (-not (Invoke-Build -Preset $preset)) {
        exit 1
    }
    
    # Install if requested
    if ($Install) {
        if (-not (Invoke-Install -Preset $preset)) {
            exit 1
        }
    }
    
    # Test if requested
    if ($Test) {
        Invoke-Test -Preset $preset
    }
    
    Write-ColorOutput "`nBuild completed successfully!" "Green"
    
    # Show output locations
    $buildDir = "out/build/$preset"
    $installDir = "out/install/$preset"
    
    if (Test-Path $buildDir) {
        Write-ColorOutput "`nBuild artifacts:" "Cyan"
        Write-ColorOutput "  Build directory: $buildDir" "White"
        if (Test-Path "$buildDir/bin") {
            Write-ColorOutput "  Binaries: $buildDir/bin" "White"
        }
        if (Test-Path "$buildDir/lib") {
            Write-ColorOutput "  Libraries: $buildDir/lib" "White"
        }
    }
    
    if ($Install -and (Test-Path $installDir)) {
        Write-ColorOutput "`nInstalled artifacts:" "Cyan"
        Write-ColorOutput "  Install directory: $installDir" "White"
        if (Test-Path "$installDir/bin") {
            Write-ColorOutput "  Binaries: $installDir/bin" "White"
        }
        if (Test-Path "$installDir/lib") {
            Write-ColorOutput "  Libraries: $installDir/lib" "White"
        }
        if (Test-Path "$installDir/include") {
            Write-ColorOutput "  Headers: $installDir/include" "White"
        }
    }
}

# Run main function
Main
