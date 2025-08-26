@echo off
setlocal enabledelayedexpansion

REM UVAtlas Build Script (Batch Version)
REM ====================================

REM Default values
set CONFIGURATION=Release
set PLATFORM=x64
set COMPILER=MSVC
set BUILD_TOOLS=false
set CLEAN=false
set INSTALL=false
set TEST=false
set VERBOSE=false

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :main
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="--debug" set CONFIGURATION=Debug
if /i "%~1"=="--release" set CONFIGURATION=Release
if /i "%~1"=="--x64" set PLATFORM=x64
if /i "%~1"=="--x86" set PLATFORM=x86
if /i "%~1"=="--arm64" set PLATFORM=arm64
if /i "%~1"=="--arm64ec" set PLATFORM=arm64ec
if /i "%~1"=="--msvc" set COMPILER=MSVC
if /i "%~1"=="--clang" set COMPILER=Clang
if /i "%~1"=="--mingw" set COMPILER=MinGW
if /i "%~1"=="--icc" set COMPILER=ICC
if /i "%~1"=="--icx" set COMPILER=ICX
if /i "%~1"=="--tools" set BUILD_TOOLS=true
if /i "%~1"=="--clean" set CLEAN=true
if /i "%~1"=="--install" set INSTALL=true
if /i "%~1"=="--test" set TEST=true
if /i "%~1"=="--verbose" set VERBOSE=true
shift
goto :parse_args

:show_help
echo UVAtlas Build Script
echo ===================
echo.
echo Usage: build.bat [options]
echo.
echo Options:
echo   --debug, --release    Build configuration (default: release)
echo   --x64, --x86, --arm64, --arm64ec  Target platform (default: x64)
echo   --msvc, --clang, --mingw, --icc, --icx  Compiler (default: msvc)
echo   --tools               Build UVAtlasTool executable
echo   --clean               Clean build directory before building
echo   --install             Install built artifacts
echo   --test                Run tests after building
echo   --verbose             Enable verbose output
echo   --help, -h            Show this help message
echo.
echo Examples:
echo   build.bat
echo   build.bat --debug --x64 --tools
echo   build.bat --release --arm64 --clang
echo   build.bat --clean --install --test
echo.
exit /b 0

:main
echo UVAtlas Build Script
echo ===================
echo.
echo Build Configuration:
echo   Configuration: %CONFIGURATION%
echo   Platform: %PLATFORM%
echo   Compiler: %COMPILER%
echo   Build Tools: %BUILD_TOOLS%
echo   Clean: %CLEAN%
echo   Install: %INSTALL%
echo   Test: %TEST%
echo   Verbose: %VERBOSE%
echo.

REM Check prerequisites
echo Checking prerequisites...
cmake --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: CMake not found. Please install CMake 3.20 or later.
    exit /b 1
)

ninja --version >nul 2>&1
if errorlevel 1 (
    echo WARNING: Ninja not found. Install Ninja for faster builds.
    echo   Install via: winget install Ninja-build.Ninja
    echo   Or download from: https://github.com/ninja-build/ninja/releases
) else (
    for /f "tokens=*" %%i in ('ninja --version 2^>nul') do (
        echo Found Ninja version: %%i
    )
)

if "%BUILD_TOOLS%"=="true" (
    if not defined VCPKG_ROOT (
        echo WARNING: VCPKG_ROOT environment variable not set. Tools may not build correctly.
    )
)

REM Determine preset name
set PRESET=%PLATFORM%-%CONFIGURATION%
if "%BUILD_TOOLS%"=="true" set PRESET=%PRESET%-VCPKG
if not "%COMPILER%"=="MSVC" set PRESET=%PRESET%-%COMPILER%

echo Using preset: %PRESET%
echo.

REM Clean if requested
if "%CLEAN%"=="true" (
    echo Cleaning build directory...
    if exist out rmdir /s /q out
    echo Build directory cleaned.
    echo.
)

REM Configure
echo Configuring build with preset: %PRESET%
set CMAKE_ARGS=--preset %PRESET%
if "%VERBOSE%"=="true" set CMAKE_ARGS=%CMAKE_ARGS% --verbose

cmake %CMAKE_ARGS%
if errorlevel 1 (
    echo ERROR: CMake configuration failed!
    exit /b 1
)
echo Configuration completed successfully.
echo.

REM Build
echo Building project...
set CMAKE_ARGS=--build --preset %PRESET%
if "%VERBOSE%"=="true" set CMAKE_ARGS=%CMAKE_ARGS% --verbose

cmake %CMAKE_ARGS%
if errorlevel 1 (
    echo ERROR: Build failed!
    exit /b 1
)
echo Build completed successfully.
echo.

REM Install if requested
if "%INSTALL%"=="true" (
    echo Installing project...
    set CMAKE_ARGS=--install --preset %PRESET%
    if "%VERBOSE%"=="true" set CMAKE_ARGS=%CMAKE_ARGS% --verbose

    cmake %CMAKE_ARGS%
    if errorlevel 1 (
        echo ERROR: Installation failed!
        exit /b 1
    )
    echo Installation completed successfully.
    echo.
)

REM Test if requested
if "%TEST%"=="true" (
    echo Running tests...
    ctest --preset %PRESET%
    if errorlevel 1 (
        echo WARNING: Some tests failed!
    ) else (
        echo All tests passed.
    )
    echo.
)

echo Build completed successfully!
echo.

REM Show output locations
set BUILD_DIR=out\build\%PRESET%
set INSTALL_DIR=out\install\%PRESET%

if exist "%BUILD_DIR%" (
    echo Build artifacts:
    echo   Build directory: %BUILD_DIR%
    if exist "%BUILD_DIR%\bin" echo   Binaries: %BUILD_DIR%\bin
    if exist "%BUILD_DIR%\lib" echo   Libraries: %BUILD_DIR%\lib
    echo.
)

if "%INSTALL%"=="true" if exist "%INSTALL_DIR%" (
    echo Installed artifacts:
    echo   Install directory: %INSTALL_DIR%
    if exist "%INSTALL_DIR%\bin" echo   Binaries: %INSTALL_DIR%\bin
    if exist "%INSTALL_DIR%\lib" echo   Libraries: %INSTALL_DIR%\lib
    if exist "%INSTALL_DIR%\include" echo   Headers: %INSTALL_DIR%\include
    echo.
)

endlocal
