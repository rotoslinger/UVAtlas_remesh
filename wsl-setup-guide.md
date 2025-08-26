# WSL UVAtlas Build Setup Guide

This guide will help you set up and build UVAtlas in WSL (Windows Subsystem for Linux).

## Prerequisites

1. **WSL2 installed** with Ubuntu (recommended)
2. **Git** (should be available by default)
3. **Basic Linux knowledge**

## Step 1: Open WSL Terminal

```bash
# From Windows PowerShell or Command Prompt
wsl

# Or open Ubuntu from Start Menu
```

## Step 2: Update System and Install Dependencies

```bash
# Update package list
sudo apt update && sudo apt upgrade -y

# Install build essentials
sudo apt install -y build-essential cmake ninja-build git

# Install additional dependencies
sudo apt install -y pkg-config libssl-dev
```

## Step 3: Install vcpkg and Dependencies

```bash
# Clone vcpkg
cd ~
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg

# Bootstrap vcpkg
./bootstrap-vcpkg.sh

# Install required packages
./vcpkg install directxmath directx-headers directxtex directxmesh eigen3 spectra

# Set up environment variables
export VCPKG_ROOT=$(pwd)
export CMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake

# Add to your shell profile (for permanent setup)
echo 'export VCPKG_ROOT=~/vcpkg' >> ~/.bashrc
echo 'export CMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake' >> ~/.bashrc
source ~/.bashrc
```

## Step 4: Clone and Build UVAtlas

```bash
# Clone UVAtlas repository
cd ~
git clone https://github.com/microsoft/UVAtlas.git
cd UVAtlas

# Make build script executable
chmod +x build.sh

# Build the library (without tools first)
./build.sh --release --x64

# If successful, try building with tools
./build.sh --release --x64 --tools
```

## Step 5: Test the Build

```bash
# Check if library was built
ls -la out/build/x64-Release/lib/

# If tools were built successfully
ls -la out/build/x64-Release/bin/
```

## Troubleshooting

### Issue 1: DirectX Dependencies Not Found
```bash
# Make sure vcpkg is properly set up
echo $VCPKG_ROOT
echo $CMAKE_TOOLCHAIN_FILE

# Reinstall dependencies if needed
cd ~/vcpkg
./vcpkg remove directxmath directx-headers directxtex directxmesh eigen3 spectra
./vcpkg install directxmath directx-headers directxtex directxmesh eigen3 spectra
```

### Issue 2: CMake Not Found
```bash
# Install CMake if missing
sudo apt install cmake

# Or install latest version
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
sudo apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main"
sudo apt update
sudo apt install cmake
```

### Issue 3: Ninja Not Found
```bash
# Install Ninja
sudo apt install ninja-build
```

## Alternative: Build Without Tools

If the command-line tool fails to build due to DirectX dependencies:

```bash
# Build just the library
./build.sh --release --x64

# Create a simple test program
cat > test_uvatlas.cpp << 'EOF'
#include "UVAtlas.h"
#include <iostream>

int main() {
    std::cout << "UVAtlas library loaded successfully!" << std::endl;
    std::cout << "Version: " << UVATLAS_VERSION << std::endl;
    return 0;
}
EOF

# Compile test program
g++ -std=c++17 -IUVAtlas/inc -Lout/build/x64-Release/lib -lUVAtlas test_uvatlas.cpp -o test_uvatlas
./test_uvatlas
```

## Using the Built Library

### From WSL:
```bash
# The library will be in:
# ~/UVAtlas/out/build/x64-Release/lib/libUVAtlas.a
```

### From Windows:
```bash
# You can access WSL files from Windows at:
# \\wsl$\Ubuntu\home\yourusername\UVAtlas\out\build\x64-Release\lib\
```

## Next Steps

1. **Test the build** with a simple mesh file
2. **Integrate into your project** if needed
3. **Create your own command-line wrapper** if the official tool doesn't build

## Notes

- The DirectX dependencies might cause issues on Linux
- The core library should build successfully
- You may need to create your own command-line interface
- Performance might be different from Windows builds
