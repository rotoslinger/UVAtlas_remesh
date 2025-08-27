#!/bin/bash

# UVAtlas Unified Build Script
# ============================
# This script can build for both Windows (WSL) and Linux, using appropriate
# presets and build directories to avoid conflicts.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Default values
CONFIGURATION="Release"
PLATFORM="x64"
COMPILER="MSVC"
BUILD_TOOLS=false
CLEAN=false
INSTALL=false
TEST=false
VERBOSE=false

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to detect platform
detect_platform() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Check if we're in WSL
        if grep -qi microsoft /proc/version 2>/dev/null; then
            echo "wsl"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Function to show help
show_help() {
    echo "UVAtlas Unified Build Script"
    echo "============================"
    echo
    echo "Usage: ./build-unified.sh [options]"
    echo
    echo "This script automatically detects your platform and uses appropriate build settings."
    echo
    echo "Options:"
    echo "  --debug, --release    Build configuration (default: release)"
    echo "  --x64, --x86, --arm64, --arm64ec  Target platform (default: x64)"
    echo "  --msvc, --clang, --mingw, --icc, --icx  Compiler (default: msvc)"
    echo "  --tools               Build UVAtlasTool executable"
    echo "  --clean               Clean build directory before building"
    echo "  --install             Install built artifacts"
    echo "  --test                Run tests after building"
    echo "  --verbose             Enable verbose output"
    echo "  --help, -h            Show this help message"
    echo
    echo "Examples:"
    echo "  ./build-unified.sh"
    echo "  ./build-unified.sh --debug --x64 --tools"
    echo "  ./build-unified.sh --release --arm64 --clang"
    echo "  ./build-unified.sh --clean --install --test"
    echo
    exit 0
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    local platform=$1
    print_color $CYAN "Checking prerequisites for $platform..."
    
    # Check CMake
    if ! command_exists cmake; then
        print_color $RED "ERROR: CMake not found. Please install CMake 3.20 or later."
        return 1
    fi
    
    # Check Ninja
    if ! command_exists ninja; then
        print_color $YELLOW "WARNING: Ninja not found. Install Ninja for faster builds."
        if [[ "$platform" == "wsl" || "$platform" == "linux" ]]; then
            print_color $YELLOW "  Install via: sudo apt-get install ninja-build (Ubuntu/Debian)"
        else
            print_color $YELLOW "  Install via: winget install Ninja-build.Ninja (Windows)"
        fi
        print_color $YELLOW "  Or download from: https://github.com/ninja-build/ninja/releases"
    else
        ninja_version=$(ninja --version 2>/dev/null)
        if [ -n "$ninja_version" ]; then
            print_color $GREEN "Found Ninja version: $ninja_version"
        fi
    fi
    
    # Check vcpkg if building tools
    if [ "$BUILD_TOOLS" = true ]; then
        if [ -z "$VCPKG_ROOT" ]; then
            print_color $YELLOW "WARNING: VCPKG_ROOT environment variable not set. Tools may not build correctly."
        fi
    fi
    
    # Platform-specific checks
    if [[ "$platform" == "wsl" ]]; then
        # Check for Visual Studio in WSL
        if [ "$COMPILER" = "MSVC" ]; then
            if ! command_exists cl.exe; then
                print_color $YELLOW "WARNING: MSVC compiler not found. Make sure Visual Studio is installed and vcvars is sourced."
            fi
        fi
    fi
    
    return 0
}

# Function to determine preset name based on platform
get_preset_name() {
    local platform=$1
    local preset="$PLATFORM-$CONFIGURATION"
    
    if [[ "$platform" == "wsl" || "$platform" == "linux" ]]; then
        # Use Linux presets (library-only for cross-compilation)
        preset="${preset}-Linux-Library"
    fi
    # Windows presets don't need a suffix
    
    if [ "$BUILD_TOOLS" = true ]; then
        preset="${preset}-VCPKG"
    fi
    
    case $COMPILER in
        "Clang") preset="${preset}-Clang" ;;
        "MinGW") preset="${preset}-MinGW" ;;
        "ICC") preset="${preset}-ICC" ;;
        "ICX") preset="${preset}-ICX" ;;
    esac
    
    echo "$preset"
}

# Function to clean build directory
clean_build_directory() {
    print_color $CYAN "Cleaning build directory..."
    
    if [ -d "out" ]; then
        rm -rf out
        print_color $GREEN "Build directory cleaned."
    fi
}

# Function to configure build
configure_build() {
    local preset=$1
    print_color $CYAN "Configuring build with preset: $preset"
    
    local cmake_args=("--preset" "$preset")
    
    if [ "$VERBOSE" = true ]; then
        cmake_args+=("--verbose")
    fi
    
    if ! cmake "${cmake_args[@]}"; then
        print_color $RED "ERROR: CMake configuration failed!"
        return 1
    fi
    
    print_color $GREEN "Configuration completed successfully."
    return 0
}

# Function to build project
build_project() {
    local preset=$1
    print_color $CYAN "Building project..."
    
    local cmake_args=("--build" "--preset" "$preset")
    
    if [ "$VERBOSE" = true ]; then
        cmake_args+=("--verbose")
    fi
    
    if ! cmake "${cmake_args[@]}"; then
        print_color $RED "ERROR: Build failed!"
        return 1
    fi
    
    print_color $GREEN "Build completed successfully."
    return 0
}

# Function to install project
install_project() {
    local preset=$1
    print_color $CYAN "Installing project..."
    
    local cmake_args=("--install" "--preset" "$preset")
    
    if [ "$VERBOSE" = true ]; then
        cmake_args+=("--verbose")
    fi
    
    if ! cmake "${cmake_args[@]}"; then
        print_color $RED "ERROR: Installation failed!"
        return 1
    fi
    
    print_color $GREEN "Installation completed successfully."
    return 0
}

# Function to run tests
run_tests() {
    local preset=$1
    print_color $CYAN "Running tests..."
    
    if ! ctest --preset "$preset"; then
        print_color $YELLOW "WARNING: Some tests failed!"
        return 1
    fi
    
    print_color $GREEN "All tests passed."
    return 0
}

# Function to show build information
show_build_info() {
    local platform=$1
    print_color $CYAN ""
    print_color $CYAN "Build Configuration:"
    print_color $WHITE "  Detected Platform: $platform"
    print_color $WHITE "  Configuration: $CONFIGURATION"
    print_color $WHITE "  Target Platform: $PLATFORM"
    print_color $WHITE "  Compiler: $COMPILER"
    print_color $WHITE "  Build Tools: $BUILD_TOOLS"
    print_color $WHITE "  Clean: $CLEAN"
    print_color $WHITE "  Install: $INSTALL"
    print_color $WHITE "  Test: $TEST"
    print_color $WHITE "  Verbose: $VERBOSE"
    echo
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            ;;
        --debug)
            CONFIGURATION="Debug"
            shift
            ;;
        --release)
            CONFIGURATION="Release"
            shift
            ;;
        --x64)
            PLATFORM="x64"
            shift
            ;;
        --x86)
            PLATFORM="x86"
            shift
            ;;
        --arm64)
            PLATFORM="arm64"
            shift
            ;;
        --arm64ec)
            PLATFORM="arm64ec"
            shift
            ;;
        --msvc)
            COMPILER="MSVC"
            shift
            ;;
        --clang)
            COMPILER="Clang"
            shift
            ;;
        --mingw)
            COMPILER="MinGW"
            shift
            ;;
        --icc)
            COMPILER="ICC"
            shift
            ;;
        --icx)
            COMPILER="ICX"
            shift
            ;;
        --tools)
            BUILD_TOOLS=true
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --install)
            INSTALL=true
            shift
            ;;
        --test)
            TEST=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            print_color $RED "Unknown option: $1"
            show_help
            ;;
    esac
done

# Main execution
main() {
    local platform=$(detect_platform)
    
    print_color $GREEN "UVAtlas Unified Build Script"
    print_color $GREEN "============================"
    
    show_build_info "$platform"
    
    # Check prerequisites
    if ! check_prerequisites "$platform"; then
        exit 1
    fi
    
    # Get preset name
    preset=$(get_preset_name "$platform")
    print_color $CYAN "Using preset: $preset"
    echo
    
    # Clean if requested
    if [ "$CLEAN" = true ]; then
        clean_build_directory
    fi
    
    # Configure
    if ! configure_build "$preset"; then
        exit 1
    fi
    echo
    
    # Build
    if ! build_project "$preset"; then
        exit 1
    fi
    echo
    
    # Install if requested
    if [ "$INSTALL" = true ]; then
        if ! install_project "$preset"; then
            exit 1
        fi
        echo
    fi
    
    # Test if requested
    if [ "$TEST" = true ]; then
        run_tests "$preset"
        echo
    fi
    
    print_color $GREEN "Build completed successfully!"
    echo
    
    # Show output locations
    build_dir="out/build/$preset"
    install_dir="out/install/$preset"
    
    if [ -d "$build_dir" ]; then
        print_color $CYAN "Build artifacts:"
        print_color $WHITE "  Build directory: $build_dir"
        if [ -d "$build_dir/bin" ]; then
            print_color $WHITE "  Binaries: $build_dir/bin"
        fi
        if [ -d "$build_dir/lib" ]; then
            print_color $WHITE "  Libraries: $build_dir/lib"
        fi
        echo
    fi
    
    if [ "$INSTALL" = true ] && [ -d "$install_dir" ]; then
        print_color $CYAN "Installed artifacts:"
        print_color $WHITE "  Install directory: $install_dir"
        if [ -d "$install_dir/bin" ]; then
            print_color $WHITE "  Binaries: $install_dir/bin"
        fi
        if [ -d "$install_dir/lib" ]; then
            print_color $WHITE "  Libraries: $install_dir/lib"
        fi
        if [ -d "$install_dir/include" ]; then
            print_color $WHITE "  Headers: $install_dir/include"
        fi
        echo
    fi
}

# Run main function
main
