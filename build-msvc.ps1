# Build script for UVAtlas with MSVC using Visual Studio environment

Write-Host "Setting up Visual Studio environment..." -ForegroundColor Cyan

# Path to Visual Studio vcvars64.bat
$vcvarsPath = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

if (-not (Test-Path $vcvarsPath)) {
    Write-Host "Visual Studio vcvars64.bat not found at: $vcvarsPath" -ForegroundColor Red
    exit 1
}

Write-Host "Found vcvars64.bat at: $vcvarsPath" -ForegroundColor Green

# Create a temporary batch file to set up environment and run build
$tempBatch = @"
@echo off
call "$vcvarsPath"
echo Environment set up. Starting build...
powershell -ExecutionPolicy Bypass -File build.ps1 -Compiler MSVC
"@

$tempBatchPath = "temp_build.bat"
Set-Content -Path $tempBatchPath -Value $tempBatch

Write-Host "Running build with Visual Studio environment..." -ForegroundColor Cyan
& cmd /c $tempBatchPath

# Clean up
Remove-Item $tempBatchPath -ErrorAction SilentlyContinue
