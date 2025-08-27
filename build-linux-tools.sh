#!/bin/bash

# Linux build script for UVAtlas with command-line tools
set -e

echo "Building UVAtlas for Linux with command-line tools..."

# Set up paths
VCPKG_ROOT="/home/harri/vcpkg"
CMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"

echo "VCPKG_ROOT: $VCPKG_ROOT"
echo "Toolchain: $CMAKE_TOOLCHAIN_FILE"

# Build directory
BUILD_DIR="out/build/x64-Release-Linux-Tools"
INSTALL_DIR="out/install/x64-Release-Linux-Tools"

echo "Build directory: $BUILD_DIR"
echo "Install directory: $INSTALL_DIR"

# Configure with tools enabled
echo "Configuring build with tools..."
cmake -S . -B "$BUILD_DIR" -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX="$(pwd)/${INSTALL_DIR}" \
    -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
    -DBUILD_TOOLS=ON

# Build
echo "Building..."
cmake --build "$BUILD_DIR"

# Install
echo "Installing..."
cmake --install "$BUILD_DIR"

echo "Build completed successfully!"
echo "Library location: $BUILD_DIR/lib/libUVAtlas.a"
echo "Tool location: $BUILD_DIR/bin/uvatlastool"
