#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Cross-platform build script for UVAtlas (Windows and Linux)

.DESCRIPTION
    Builds UVAtlas for both Windows and Linux platforms with separate output directories.
    Supports building library only or with command-line tools.

.PARAMETER Platform
    Target platform: Windows, Linux, or Both (default: Both)

.PARAMETER Configuration
    Build configuration: Debug, Release, or Both (default: Release)

.PARAMETER Architecture
    Target architecture: x64, arm64, or Both (default: x64)

.PARAMETER BuildTools
    Build command-line tools in addition to library (default: false)

.PARAMETER Clean
    Clean build directories before building

.PARAMETER VerboseOutput
    Enable verbose output

.PARAMETER Help
    Show this help message

.EXAMPLE
    .\build-cross.ps1
    # Builds both Windows and Linux x64 Release versions

.EXAMPLE
    .\build-cross.ps1 -Platform Windows -Configuration Debug -BuildTools
    # Builds Windows x64 Debug with command-line tools

.EXAMPLE
    .\build-cross.ps1 -Platform Linux -Architecture arm64
    # Builds Linux ARM64 Release version
#>

param(
    [Parameter()]
    [ValidateSet("Windows", "Linux", "Both")]
    [string]$Platform = "Both",
    
    [Parameter()]
    [ValidateSet("Debug", "Release", "Both")]
    [string]$Configuration = "Release",
    
    [Parameter()]
    [ValidateSet("x64", "arm64", "Both")]
    [string]$Architecture = "x64",
    
    [Parameter()]
    [switch]$BuildTools,
    
    [Parameter()]
    [switch]$Clean,
    
    [Parameter()]
    [switch]$VerboseOutput,
    
    [Parameter()]
    [switch]$Help
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Cyan = "Cyan"

function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Red
}

function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    # Check CMake
    try {
        $cmakeVersion = cmake --version 2>$null | Select-Object -First 1
        if ($cmakeVersion) {
            Write-Success "CMake found: $cmakeVersion"
        } else {
            throw "CMake not found"
        }
    } catch {
        Write-Error "CMake not found. Please install CMake."
        return $false
    }
    
    # Check Ninja
    try {
        $ninjaVersion = ninja --version 2>$null
        if ($ninjaVersion) {
            Write-Success "Ninja found: $ninjaVersion"
        } else {
            throw "Ninja not found"
        }
    } catch {
        Write-Error "Ninja not found. Please install Ninja: winget install Ninja-build.Ninja"
        return $false
    }
    
    return $true
}

function Get-PresetName {
    param(
        [string]$Platform,
        [string]$Configuration,
        [string]$Architecture,
        [bool]$BuildTools
    )
    
    $preset = "$Architecture-$Configuration"
    
    if ($Platform -eq "Linux") {
        $preset += "-Linux"
    }
    
    if ($BuildTools) {
        $preset += "-VCPKG"
    }
    
    return $preset
}

function Invoke-Build {
    param(
        [string]$Preset,
        [string]$Platform,
        [bool]$Verbose
    )
    
    $buildDir = "out/build/$Preset"
    $installDir = "out/install/$Preset"
    
    Write-Status "Building $Platform version with preset: $Preset"
    Write-Status "Build directory: $buildDir"
    
    # Configure
    $configureArgs = @("--preset", $Preset)
    if ($Verbose) { $configureArgs += "--log-level=VERBOSE" }
    
    Write-Status "Configuring with: cmake $($configureArgs -join ' ')"
    $result = cmake $configureArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Configuration failed for $Preset"
        return $false
    }
    
    # Build
    $buildArgs = @("--build", $buildDir)
    if ($Verbose) { $buildArgs += "--verbose" }
    
    Write-Status "Building with: cmake $($buildArgs -join ' ')"
    $result = cmake $buildArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed for $Preset"
        return $false
    }
    
    # Install
    $installArgs = @("--install", $buildDir)
    if ($Verbose) { $installArgs += "--verbose" }
    
    Write-Status "Installing with: cmake $($installArgs -join ' ')"
    $result = cmake $installArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Install failed for $Preset"
        return $false
    }
    
    Write-Success "Successfully built $Platform version: $Preset"
    return $true
}

function Show-BuildResults {
    Write-Status "Build Results Summary:"
    Write-Host ""
    
    $platforms = if ($Platform -eq "Both") { @("Windows", "Linux") } else { @($Platform) }
    $configs = if ($Configuration -eq "Both") { @("Debug", "Release") } else { @($Configuration) }
    $archs = if ($Architecture -eq "Both") { @("x64", "arm64") } else { @($Architecture) }
    
    foreach ($p in $platforms) {
        foreach ($c in $configs) {
            foreach ($a in $archs) {
                $preset = Get-PresetName -Platform $p -Configuration $c -Architecture $a -BuildTools $BuildTools
                $buildDir = "out/build/$preset"
                $installDir = "out/install/$preset"
                
                if (Test-Path $buildDir) {
                    Write-Host "✅ $p $a $c" -ForegroundColor $Green
                    Write-Host "   Build: $buildDir" -ForegroundColor $Cyan
                    Write-Host "   Install: $installDir" -ForegroundColor $Cyan
                    
                    # Show library files
                    $libDir = "$buildDir/lib"
                    if (Test-Path $libDir) {
                        Write-Host "   Libraries:" -ForegroundColor $Yellow
                        Get-ChildItem $libDir -Name | ForEach-Object { Write-Host "     $_" }
                    }
                    
                    # Show executable files
                    $binDir = "$buildDir/bin"
                    if (Test-Path $binDir) {
                        Write-Host "   Executables:" -ForegroundColor $Yellow
                        Get-ChildItem $binDir -Name | ForEach-Object { Write-Host "     $_" }
                    }
                    
                    Write-Host ""
                } else {
                    Write-Host "❌ $p $a $c - Not built" -ForegroundColor $Red
                }
            }
        }
    }
}

function Main {
    if ($Help) {
        Get-Help $PSCommandPath -Full
        return
    }
    
    Write-Host "🚀 UVAtlas Cross-Platform Build Script" -ForegroundColor $Cyan
    Write-Host "Platform: $Platform" -ForegroundColor $Yellow
    Write-Host "Configuration: $Configuration" -ForegroundColor $Yellow
    Write-Host "Architecture: $Architecture" -ForegroundColor $Yellow
    Write-Host "Build Tools: $BuildTools" -ForegroundColor $Yellow
    Write-Host ""
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    # Clean if requested
    if ($Clean) {
        Write-Status "Cleaning build directories..."
        if (Test-Path "out") {
            Remove-Item -Recurse -Force "out"
            Write-Success "Cleaned build directories"
        }
    }
    
    # Determine what to build
    $platforms = if ($Platform -eq "Both") { @("Windows", "Linux") } else { @($Platform) }
    $configs = if ($Configuration -eq "Both") { @("Debug", "Release") } else { @($Configuration) }
    $archs = if ($Architecture -eq "Both") { @("x64", "arm64") } else { @($Architecture) }
    
    $successCount = 0
    $totalCount = 0
    
    # Build each combination
    foreach ($p in $platforms) {
        foreach ($c in $configs) {
            foreach ($a in $archs) {
                $totalCount++
                $preset = Get-PresetName -Platform $p -Configuration $c -Architecture $a -BuildTools $BuildTools
                
                Write-Host "🔨 Building $p $a $c..." -ForegroundColor $Cyan
                if (Invoke-Build -Preset $preset -Platform $p -Verbose $VerboseOutput) {
                    $successCount++
                }
                Write-Host ""
            }
        }
    }
    
    # Show results
    Write-Host "📊 Build Summary: $successCount/$totalCount builds successful" -ForegroundColor $(if ($successCount -eq $totalCount) { $Green } else { $Yellow })
    Show-BuildResults
    
    if ($successCount -eq $totalCount) {
        Write-Success "All builds completed successfully!"
        exit 0
    } else {
        Write-Error "Some builds failed. Check the output above for details."
        exit 1
    }
}

# Run the main function
Main
