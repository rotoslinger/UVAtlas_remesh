# Test build script for UVAtlas with Clang

# Set up environment
$env:PATH = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\Llvm\bin;" + $env:PATH
$env:CXX = "clang-cl.exe"

Write-Host "Environment set up:" -ForegroundColor Green
Write-Host "PATH includes Clang: $($env:PATH -like '*Llvm\bin*')" -ForegroundColor White
Write-Host "CXX set to: $env:CXX" -ForegroundColor White

# Test if clang-cl is available
if (Get-Command clang-cl -ErrorAction SilentlyContinue) {
    Write-Host "clang-cl found: $(clang-cl --version | Select-Object -First 1)" -ForegroundColor Green
} else {
    Write-Host "clang-cl not found in PATH" -ForegroundColor Red
    exit 1
}

# Run the build
Write-Host "`nStarting build..." -ForegroundColor Cyan
& ".\build.ps1" -Compiler Clang
