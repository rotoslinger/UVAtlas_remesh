#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Environment setup script for UVAtlas project

.DESCRIPTION
    This script automatically detects and configures the build environment for UVAtlas.
    It finds Visual Studio, Clang, Ninja, and other required tools.

.PARAMETER Force
    Force re-detection of tools even if already found

.PARAMETER InstallMissing
    Automatically install missing tools (requires admin privileges)

.EXAMPLE
    .\setup-env.ps1
    # Detect and configure environment

.EXAMPLE
    .\setup-env.ps1 -InstallMissing
    # Detect, configure, and install missing tools
#>

param(
    [Parameter()]
    [switch]$Force,
    
    [Parameter()]
    [switch]$InstallMissing
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

# Function to find Visual Studio installation
function Find-VisualStudio {
    Write-ColorOutput "Searching for Visual Studio..." "Cyan"
    
    $vsPath = $null
    
    # Try vswhere first
    if (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe") {
        $vsPath = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath 2>$null
    }
    
    if (-not $vsPath) {
        # Try common installation paths
        $commonPaths = @(
            "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community",
            "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional",
            "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise",
            "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community",
            "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional",
            "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise"
        )
        
        foreach ($path in $commonPaths) {
            if (Test-Path $path) {
                $vsPath = $path
                break
            }
        }
    }
    
    if ($vsPath) {
        Write-ColorOutput "Found Visual Studio at: $vsPath" "Green"
        return $vsPath
    } else {
        Write-ColorOutput "Visual Studio not found" "Yellow"
        return $null
    }
}

# Function to find Clang installation
function Find-Clang {
    Write-ColorOutput "Searching for Clang..." "Cyan"
    
    # Check if clang is in PATH
    if (Test-Command "clang") {
        $version = & clang --version 2>$null
        Write-ColorOutput "Found Clang in PATH: $($version.Split("`n")[0])" "Green"
        return $true
    }
    
    # Check if clang-cl is in PATH
    if (Test-Command "clang-cl") {
        $version = & clang-cl --version 2>$null
        Write-ColorOutput "Found Clang-cl in PATH: $($version.Split("`n")[0])" "Green"
        return $true
    }
    
    # Search in Visual Studio LLVM installation
    $vsPath = Find-VisualStudio
    if ($vsPath) {
        $clangPaths = @(
            "$vsPath\VC\Tools\Llvm\bin\clang.exe",
            "$vsPath\VC\Tools\Llvm\x64\bin\clang.exe",
            "$vsPath\VC\Tools\Llvm\ARM64\bin\clang.exe"
        )
        
        foreach ($clangPath in $clangPaths) {
            if (Test-Path $clangPath) {
                $version = & $clangPath --version 2>$null
                Write-ColorOutput "Found Clang in Visual Studio: $($version.Split("`n")[0])" "Green"
                Write-ColorOutput "  Path: $clangPath" "White"
                return $clangPath
            }
        }
    }
    
    # Search in common installation locations
    $searchPaths = @(
        "${env:ProgramFiles}\LLVM\bin",
        "${env:ProgramFiles(x86)}\LLVM\bin",
        "${env:LOCALAPPDATA}\Programs\LLVM\bin"
    )
    
    foreach ($searchPath in $searchPaths) {
        $clangPath = Join-Path $searchPath "clang.exe"
        if (Test-Path $clangPath) {
            $version = & $clangPath --version 2>$null
            Write-ColorOutput "Found Clang at: $clangPath" "Green"
            Write-ColorOutput "  Version: $($version.Split("`n")[0])" "White"
            return $clangPath
        }
    }
    
    Write-ColorOutput "Clang not found" "Yellow"
    return $null
}

# Function to find Ninja
function Find-Ninja {
    Write-ColorOutput "Searching for Ninja..." "Cyan"
    
    if (Test-Command "ninja") {
        $version = & ninja --version 2>$null
        Write-ColorOutput "Found Ninja: $version" "Green"
        return $true
    }
    
    Write-ColorOutput "Ninja not found" "Yellow"
    return $false
}

# Function to find CMake
function Find-CMake {
    Write-ColorOutput "Searching for CMake..." "Cyan"
    
    if (Test-Command "cmake") {
        $version = & cmake --version 2>$null
        Write-ColorOutput "Found CMake: $($version.Split("`n")[0])" "Green"
        return $true
    }
    
    Write-ColorOutput "CMake not found" "Red"
    return $false
}

# Function to install missing tools
function Install-MissingTools {
    param([hashtable]$MissingTools)
    
    if ($MissingTools.Count -eq 0) {
        Write-ColorOutput "All required tools are available!" "Green"
        return
    }
    
    Write-ColorOutput "`nMissing tools detected:" "Yellow"
    foreach ($tool in $MissingTools.Keys) {
        Write-ColorOutput "  - $tool" "Yellow"
    }
    
    if (-not $InstallMissing) {
        Write-ColorOutput "`nTo install missing tools, run: .\setup-env.ps1 -InstallMissing" "Cyan"
        return
    }
    
    Write-ColorOutput "`nInstalling missing tools..." "Cyan"
    
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if (-not $isAdmin) {
        Write-ColorOutput "WARNING: Some installations may require administrator privileges" "Yellow"
    }
    
    foreach ($tool in $MissingTools.Keys) {
        Write-ColorOutput "Installing $tool..." "Cyan"
        
        switch ($tool) {
            "Ninja" {
                try {
                    & winget install Ninja-build.Ninja
                    Write-ColorOutput "Ninja installed successfully" "Green"
                }
                catch {
                    Write-ColorOutput "Failed to install Ninja: $($_.Exception.Message)" "Red"
                }
            }
            "Clang" {
                try {
                    & winget install LLVM.LLVM
                    Write-ColorOutput "Clang installed successfully" "Green"
                }
                catch {
                    Write-ColorOutput "Failed to install Clang: $($_.Exception.Message)" "Red"
                }
            }
            "CMake" {
                try {
                    & winget install Kitware.CMake
                    Write-ColorOutput "CMake installed successfully" "Green"
                }
                catch {
                    Write-ColorOutput "Failed to install CMake: $($_.Exception.Message)" "Red"
                }
            }
        }
    }
}

# Function to set up environment variables
function Set-EnvironmentVariables {
    param(
        [string]$VsPath,
        [string]$ClangPath
    )
    
    Write-ColorOutput "`nSetting up environment variables..." "Cyan"
    
    $envVars = @{}
    
    # Set up Visual Studio environment
    if ($VsPath) {
        $vcvarsPath = Join-Path $VsPath "VC\Auxiliary\Build\vcvars64.bat"
        if (Test-Path $vcvarsPath) {
            Write-ColorOutput "Visual Studio environment available at: $vcvarsPath" "Green"
            $envVars["VS_PATH"] = $VsPath
            $envVars["VCVARS_PATH"] = $vcvarsPath
        }
    }
    
    # Set up Clang environment
    if ($ClangPath) {
        $clangDir = Split-Path $ClangPath -Parent
        Write-ColorOutput "Clang environment available at: $clangDir" "Green"
        $envVars["CLANG_PATH"] = $ClangPath
        $envVars["CLANG_DIR"] = $clangDir
    }
    
    # Save environment variables to a file for the build scripts to use
    $envFile = "build-env.ps1"
    $envContent = @"
# Auto-generated environment configuration
# Generated by setup-env.ps1

"@
    
    foreach ($key in $envVars.Keys) {
        $envContent += "`n`$env:$key = `"$($envVars[$key])`""
    }
    
    $envContent += @"

# Add tools to PATH if not already present
"@
    
    if ($VsPath) {
        $vsToolsPath = Join-Path $VsPath "VC\Tools\MSVC"
        if (Test-Path $vsToolsPath) {
            $msvcVersion = Get-ChildItem $vsToolsPath | Sort-Object Name -Descending | Select-Object -First 1
            if ($msvcVersion) {
                $msvcBinPath = Join-Path $msvcVersion.FullName "bin\Hostx64\x64"
                if (Test-Path $msvcBinPath) {
                    $envContent += "`nif (`$env:PATH -notlike `"*$msvcBinPath*`") {"
                    $envContent += "`n    `$env:PATH = `"$msvcBinPath;`" + `$env:PATH"
                    $envContent += "`n}"
                }
            }
        }
    }
    
    if ($ClangPath) {
        $clangDir = Split-Path $ClangPath -Parent
        $envContent += "`nif (`$env:PATH -notlike `"*$clangDir*`") {"
        $envContent += "`n    `$env:PATH = `"$clangDir;`" + `$env:PATH"
        $envContent += "`n}"
    }
    
    Set-Content -Path $envFile -Value $envContent
    Write-ColorOutput "Environment configuration saved to: $envFile" "Green"
}

# Function to generate build script wrapper
function New-BuildScriptWrapper {
    Write-ColorOutput "`nGenerating build script wrapper..." "Cyan"
    
    $wrapperContent = @"
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
    [string]`$Configuration = "Release",
    
    [Parameter()]
    [ValidateSet("x64", "x86", "arm64", "arm64ec")]
    [string]`$Platform = "x64",
    
    [Parameter()]
    [ValidateSet("MSVC", "Clang", "MinGW", "ICC", "ICX")]
    [string]`$Compiler = "MSVC",
    
    [Parameter()]
    [switch]`$BuildTools,
    
    [Parameter()]
    [switch]`$Clean,
    
    [Parameter()]
    [switch]`$Install,
    
    [Parameter()]
    [switch]`$Test,
    
    [Parameter()]
    [switch]`$VerboseOutput,
    
    [Parameter()]
    [switch]`$SkipEnvSetup
)

# Set up environment if not skipped
if (-not `$SkipEnvSetup) {
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
`$buildArgs = @()

if (`$Configuration -ne "Release") { `$buildArgs += "-Configuration", `$Configuration }
if (`$Platform -ne "x64") { `$buildArgs += "-Platform", `$Platform }
if (`$Compiler -ne "MSVC") { `$buildArgs += "-Compiler", `$Compiler }
if (`$BuildTools) { `$buildArgs += "-BuildTools" }
if (`$Clean) { `$buildArgs += "-Clean" }
if (`$Install) { `$buildArgs += "-Install" }
if (`$Test) { `$buildArgs += "-Test" }
if (`$VerboseOutput) { `$buildArgs += "-VerboseOutput" }

# Run the main build script
& ".\build.ps1" @buildArgs
"@
    
    Set-Content -Path "build-auto.ps1" -Value $wrapperContent
    Write-ColorOutput "Build script wrapper created: build-auto.ps1" "Green"
}

# Main execution
function Main {
    Write-ColorOutput "UVAtlas Environment Setup" "Green"
    Write-ColorOutput "=========================" "Green"
    Write-ColorOutput ""
    
    # Detect tools
    $cmakeFound = Find-CMake
    $ninjaFound = Find-Ninja
    $vsPath = Find-VisualStudio
    $clangPath = Find-Clang
    
    # Check for missing tools
    $missingTools = @{}
    
    if (-not $cmakeFound) {
        $missingTools["CMake"] = $true
    }
    
    if (-not $ninjaFound) {
        $missingTools["Ninja"] = $true
    }
    
    if (-not $clangPath -and -not $vsPath) {
        $missingTools["Clang"] = $true
    }
    
    # Install missing tools if requested
    Install-MissingTools -MissingTools $missingTools
    
    # Set up environment variables
    Set-EnvironmentVariables -VsPath $vsPath -ClangPath $clangPath
    
    # Generate build script wrapper
    New-BuildScriptWrapper
    
    Write-ColorOutput "`nEnvironment setup completed!" "Green"
    Write-ColorOutput "`nNext steps:" "Cyan"
    Write-ColorOutput "1. Run: .\build-auto.ps1" "White"
    Write-ColorOutput "2. Or run: .\build.ps1 (after sourcing build-env.ps1)" "White"
    Write-ColorOutput "3. For help: .\build-auto.ps1 -?" "White"
}

# Run main function
Main
