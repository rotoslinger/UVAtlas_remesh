#!/bin/bash

# Simple WSL build script for UVAtlas
set -e

# Set VCPKG_ROOT if not provided (default WSL location)
if [[ -z "$VCPKG_ROOT" ]]; then
    VCPKG_ROOT="/home/harri/vcpkg"
    echo "VCPKG_ROOT not set, using default: $VCPKG_ROOT"
fi

echo "Building UVAtlas for Linux using WSL..."
echo "VCPKG_ROOT: $VCPKG_ROOT"

# Set up environment
CMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"

# Build directory
BUILD_DIR="out/build/x64-Release-Linux-Library"
INSTALL_DIR="out/install/x64-Release-Linux-Library"

echo "Build directory: $BUILD_DIR"
echo "Install directory: $INSTALL_DIR"

# Configure
echo "Configuring build..."
cmake -S . -B "$BUILD_DIR" -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX="$(pwd)/${INSTALL_DIR}" \
    -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE"

# Build
echo "Building..."
cmake --build "$BUILD_DIR"

echo "Build completed successfully!"
echo "Library location: $BUILD_DIR/lib/libUVAtlas.a"
