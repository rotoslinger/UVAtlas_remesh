# UVAtlas Build Guide

This guide explains how to build UVAtlas for different platforms without conflicts between Windows and Linux builds.

## Overview

The UVAtlas project supports multiple build scripts that are designed to work together without stomping on each other's build outputs:

- **Windows builds**: Use `build.ps1` (PowerShell) or `build.bat` (Batch)
- **Linux/WSL builds**: Use `build.sh` or `build-linux.sh`
- **Unified builds**: Use `build-unified.sh` (automatically detects platform)

## Build Directory Structure

All builds use the same `out/` directory structure, but with different preset names to avoid conflicts:

```
out/
├── build/
│   ├── x64-Release/           # Windows builds (no suffix)
│   ├── x64-Release-Linux/     # Linux builds (with -Linux suffix)
│   ├── x64-Debug-VCPKG/       # Windows with tools
│   ├── x64-Debug-Linux-VCPKG/ # Linux with tools
│   └── ...
└── install/
    ├── x64-Release/
    ├── x64-Release-Linux/
    └── ...
```

## Platform-Specific Build Scripts

### Windows Builds

**PowerShell (Recommended):**
```powershell
# Basic build
.\build.ps1

# Debug build with tools
.\build.ps1 -Configuration Debug -BuildTools

# ARM64 build with Clang
.\build.ps1 -Platform arm64 -Compiler Clang
```

**Batch:**
```cmd
# Basic build
build.bat

# Debug build with tools
build.bat --debug --tools

# ARM64 build with Clang
build.bat --release --arm64 --clang
```

### Linux/WSL Builds

**Main shell script:**
```bash
# Basic build
./build.sh

# Debug build with tools
./build.sh --debug --tools

# ARM64 build with Clang
./build.sh --release --arm64 --clang
```

**Linux-specific script:**
```bash
# Basic Linux build
./build-linux.sh

# Debug build with tools
./build-linux.sh --debug --tools

# ARM64 build
./build-linux.sh --arm64 --clean
```

### Unified Build Script

The `build-unified.sh` script automatically detects your platform and uses the appropriate settings:

```bash
# Automatically detects platform and uses correct presets
./build-unified.sh

# Debug build with tools
./build-unified.sh --debug --tools

# ARM64 build with Clang
./build-unified.sh --release --arm64 --clang
```

## CMake Presets

The project uses CMake presets to ensure consistent builds across platforms:

### Windows Presets
- `x64-Release` - Standard Windows x64 Release build
- `x64-Debug` - Standard Windows x64 Debug build
- `x64-Release-VCPKG` - Windows build with tools (requires vcpkg)
- `arm64-Release` - Windows ARM64 build
- `arm64ec-Release` - Windows ARM64EC build

### Linux Presets
- `x64-Release-Linux` - Linux x64 Release build
- `x64-Debug-Linux` - Linux x64 Debug build
- `x64-Release-Linux-VCPKG` - Linux build with tools
- `arm64-Release-Linux` - Linux ARM64 build

## Prerequisites

### Windows
- Visual Studio 2019 or later (for MSVC builds)
- CMake 3.20 or later
- Ninja (optional, for faster builds)
- vcpkg (for building tools)

### Linux/WSL
- GCC or Clang
- CMake 3.20 or later
- Ninja (optional, for faster builds)
- vcpkg (for building tools)

## Environment Setup

### Windows
```powershell
# Set up vcpkg (if building tools)
$env:VCPKG_ROOT = "C:\path\to\vcpkg"

# Set up Visual Studio environment
& "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
```

### Linux/WSL
```bash
# Set up vcpkg (if building tools)
export VCPKG_ROOT=~/vcpkg

# Install dependencies
sudo apt update
sudo apt install build-essential cmake ninja-build git pkg-config
```

## Build Examples

### Building Library Only

**Windows:**
```powershell
.\build.ps1 -Configuration Release -Platform x64
```

**Linux:**
```bash
./build.sh --release --x64
```

### Building with Tools

**Windows:**
```powershell
.\build.ps1 -Configuration Release -Platform x64 -BuildTools
```

**Linux:**
```bash
./build.sh --release --x64 --tools
```

### Cross-Platform Development

If you're developing on both Windows and Linux (e.g., using WSL), you can build for both platforms without conflicts:

```bash
# In WSL - builds to out/build/x64-Release-Linux/
./build.sh --release --x64

# In Windows PowerShell - builds to out/build/x64-Release/
.\build.ps1 -Configuration Release -Platform x64
```

Both builds will coexist in the same `out/` directory with different preset names.

## Troubleshooting

### Build Conflicts
If you encounter build conflicts, ensure you're using the correct script for your platform:
- Use `build.ps1` or `build.bat` on Windows
- Use `build.sh` or `build-linux.sh` on Linux/WSL
- Use `build-unified.sh` for automatic platform detection

### Missing Dependencies
- **Windows**: Install Visual Studio Build Tools or Visual Studio Community
- **Linux**: Install build-essential package
- **Tools**: Set up vcpkg and install required packages

### CMake Errors
- Ensure CMake 3.20 or later is installed
- Check that the correct preset is being used for your platform
- Verify that all required dependencies are installed

## Build Output Locations

After a successful build, you'll find the artifacts in:

- **Libraries**: `out/build/{preset}/lib/`
- **Executables**: `out/build/{preset}/bin/`
- **Headers**: `out/install/{preset}/include/`

The exact path depends on the preset used (e.g., `out/build/x64-Release/` for Windows or `out/build/x64-Release-Linux/` for Linux).

## Advanced Usage

### Custom Build Configurations

You can create custom build configurations by modifying `CMakePresets.json` or using CMake directly:

```bash
# Custom CMake configuration
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release -DPLATFORM=x64
cmake --build build
```

### Continuous Integration

For CI/CD pipelines, use the appropriate script for your build environment:

```yaml
# GitHub Actions example
- name: Build on Windows
  run: .\build.ps1 -Configuration Release -Platform x64

- name: Build on Linux
  run: ./build.sh --release --x64
```

## Summary

The UVAtlas build system is designed to support cross-platform development without conflicts. The key points are:

1. **Use platform-specific scripts** or the unified script
2. **Different presets** ensure builds don't conflict
3. **Shared output directory** with preset-based subdirectories
4. **Consistent interface** across all build scripts

This setup allows you to develop and build on both Windows and Linux without worrying about build conflicts.
