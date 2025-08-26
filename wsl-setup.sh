#!/bin/bash

# WSL UVAtlas Build Setup Script
# Run this script in WSL to set up the build environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Starting WSL UVAtlas build setup..."

# Step 1: Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 2: Install build dependencies
print_status "Installing build dependencies..."
sudo apt install -y build-essential cmake ninja-build git pkg-config libssl-dev

# Step 3: Install vcpkg
print_status "Setting up vcpkg..."
cd ~
if [ ! -d "vcpkg" ]; then
    git clone https://github.com/microsoft/vcpkg.git
fi
cd vcpkg
./bootstrap-vcpkg.sh

# Step 4: Install UVAtlas dependencies
print_status "Installing UVAtlas dependencies..."
./vcpkg install directxmath directx-headers directxtex directxmesh eigen3 spectra

# Step 5: Set up environment variables
print_status "Setting up environment variables..."
export VCPKG_ROOT=$(pwd)
export CMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake

# Add to bashrc for permanent setup
if ! grep -q "VCPKG_ROOT" ~/.bashrc; then
    echo 'export VCPKG_ROOT=~/vcpkg' >> ~/.bashrc
    echo 'export CMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake' >> ~/.bashrc
    print_success "Environment variables added to ~/.bashrc"
fi

# Step 6: Clone UVAtlas (if not already present)
print_status "Setting up UVAtlas repository..."
cd ~
if [ ! -d "UVAtlas" ]; then
    git clone https://github.com/microsoft/UVAtlas.git
fi
cd UVAtlas

# Step 7: Make build script executable
chmod +x build.sh

# Step 8: Build the library
print_status "Building UVAtlas library..."
./build.sh --release --x64

if [ $? -eq 0 ]; then
    print_success "Library build completed successfully!"
    
    # Step 9: Try building with tools
    print_status "Attempting to build command-line tools..."
    ./build.sh --release --x64 --tools
    
    if [ $? -eq 0 ]; then
        print_success "Command-line tools built successfully!"
    else
        print_warning "Command-line tools failed to build (expected due to DirectX dependencies)"
    fi
else
    print_error "Library build failed!"
    exit 1
fi

# Step 10: Show results
print_status "Build results:"
echo ""
if [ -d "out/build/x64-Release/lib" ]; then
    echo "Library files:"
    ls -la out/build/x64-Release/lib/
    echo ""
fi

if [ -d "out/build/x64-Release/bin" ]; then
    echo "Executable files:"
    ls -la out/build/x64-Release/bin/
    echo ""
fi

print_success "Setup complete! You can now use UVAtlas in WSL."
print_status "Library location: ~/UVAtlas/out/build/x64-Release/lib/"
print_status "To use in your projects, include: -I~/UVAtlas/UVAtlas/inc -L~/UVAtlas/out/build/x64-Release/lib -lUVAtlas"
