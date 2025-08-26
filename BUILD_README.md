# UVAtlas Build Guide

This guide explains how to build the UVAtlas project using the provided build scripts.

## Prerequisites

### Required
- **CMake** (3.15 or later)
- **C++ Compiler**
  - **Windows**: Visual Studio 2019/2022 with MSVC, or Clang
  - **Linux**: GCC, Clang, or ICC
  - **macOS**: Xcode Command Line Tools, Clang, or ICC

### Optional (for faster builds)
- **Ninja**
  - **Windows**: `winget install Ninja-build.Ninja` or download from [releases](https://github.com/ninja-build/ninja/releases)
  - **Ubuntu/Debian**: `sudo apt-get install ninja-build`
  - **macOS**: `brew install ninja`

### For UVAtlasTool (command-line tool)
- **vcpkg** with dependencies: `directxmath`, `directx-headers`, `directxtex`, `directxmesh`, `eigen3`, `spectra`

## Quick Start

### 1. Environment Setup (Recommended)
Run the environment setup script to automatically detect and configure your build environment:

```powershell
# Windows
.\setup-env.ps1

# Linux/macOS
./setup-env.sh
```

This script will:
- Detect installed compilers (Visual Studio, Clang, etc.)
- Find build tools (CMake, Ninja)
- Configure environment variables
- Generate build script wrappers

### 2. Build the Project

#### Using the automatic build script (recommended):
```powershell
# Windows - builds Release x64 with MSVC by default
.\build-auto.ps1

# With custom options
.\build-auto.ps1 -Configuration Debug -Compiler Clang -BuildTools
```

#### Using the main build script:
```powershell
# Windows
.\build.ps1 -Compiler MSVC -Configuration Release

# Linux/macOS
./build.sh --compiler=gcc --configuration=Release
```

#### Using batch file (Windows):
```batch
build.bat -c Release -p x64 -compiler MSVC
```

## Build Options

### Configuration
- `Debug` - Debug build with symbols
- `Release` - Optimized release build (default)

### Platform
- `x64` - 64-bit x86 (default)
- `x86` - 32-bit x86
- `arm64` - 64-bit ARM
- `arm64ec` - ARM64 emulation compatible

### Compiler
- `MSVC` - Microsoft Visual C++ (default on Windows)
- `Clang` - LLVM Clang
- `MinGW` - MinGW-w64 GCC
- `ICC` - Intel C++ Compiler
- `ICX` - Intel oneAPI DPC++ Compiler

### Additional Options
- `-BuildTools` - Build the UVAtlasTool executable (requires vcpkg)
- `-Clean` - Clean build directory before building
- `-Install` - Install built artifacts
- `-Test` - Run tests after building
- `-VerboseOutput` - Enable verbose output

## Examples

### Basic Release Build
```powershell
.\build-auto.ps1
```

### Debug Build with Clang
```powershell
.\build-auto.ps1 -Configuration Debug -Compiler Clang
```

### Build with Tools and Install
```powershell
.\build-auto.ps1 -BuildTools -Install
```

### Clean Build with Verbose Output
```powershell
.\build-auto.ps1 -Clean -VerboseOutput
```

## Build Output Structure

```
out/
├── build/
│   ├── x64-Release/          # Build artifacts
│   │   ├── lib/
│   │   │   └── UVAtlas.lib   # Main library
│   │   ├── bin/
│   │   │   └── uvatlastool.exe # Command-line tool (if built)
│   │   └── CMakeFiles/       # CMake generated files
│   └── x64-Debug/            # Debug build artifacts
└── install/                  # Installed files (if -Install used)
```

## Troubleshooting

### Common Issues

#### 1. Compiler Not Found
**Error**: `The CMAKE_CXX_COMPILER is not a full path and was not found in the PATH`

**Solution**: 
- Run `.\setup-env.ps1` to detect and configure compilers
- For MSVC on Windows, use `.\build-msvc.ps1` which sets up the Visual Studio environment

#### 2. Ninja Not Found
**Error**: `CMake Error: CMake was unable to find a build program corresponding to "Ninja"`

**Solution**: Install Ninja:
```powershell
winget install Ninja-build.Ninja
```

#### 3. Missing Dependencies for UVAtlasTool
**Error**: `Could not find package: directxmath`

**Solution**: Install vcpkg dependencies:
```bash
vcpkg install directxmath directx-headers directxtex directxmesh eigen3 spectra
```

#### 4. Permission Issues
**Error**: Access denied when installing tools

**Solution**: Run PowerShell as Administrator for tool installation:
```powershell
.\setup-env.ps1 -InstallMissing
```

### Environment Setup

The environment setup script (`setup-env.ps1`) automatically:
- Detects Visual Studio installations
- Finds Clang/LLVM installations
- Locates CMake and Ninja
- Configures PATH and environment variables
- Generates build script wrappers

### Manual Environment Setup

If automatic setup fails, you can manually configure:

#### Windows with MSVC
```powershell
# Set up Visual Studio environment
& "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
.\build.ps1 -Compiler MSVC
```

#### Windows with Clang
```powershell
# Add Clang to PATH
$env:PATH = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\Llvm\bin;" + $env:PATH
$env:CXX = "clang-cl.exe"
.\build.ps1 -Compiler Clang
```

## CMake Presets

The project uses CMake presets for different configurations. Available presets:

- `x64-Release` - Default release build
- `x64-Debug` - Debug build
- `x64-Release-Clang` - Release with Clang
- `x64-Release-VCPKG` - Release with vcpkg dependencies
- And many more for different platforms and compilers

## Contributing

When adding new build configurations:
1. Update `CMakePresets.json` with new presets
2. Test with different compilers and platforms
3. Update this README with new options
4. Ensure the build scripts handle the new configurations

## Support

For build issues:
1. Check the troubleshooting section above
2. Run `.\setup-env.ps1` to diagnose environment issues
3. Use `-VerboseOutput` for detailed build information
4. Check the CMake output for specific error messages
