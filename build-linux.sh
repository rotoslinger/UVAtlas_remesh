#!/bin/bash

# Linux UVAtlas Build Script
# Supports both native Linux builds and cross-compilation

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

# Default values
PLATFORM="Linux"
CONFIGURATION="Release"
ARCHITECTURE="x64"
BUILD_TOOLS=false
CLEAN=false
VERBOSE=false
HELP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            CONFIGURATION="Debug"
            shift
            ;;
        --release)
            CONFIGURATION="Release"
            shift
            ;;
        --x64)
            ARCHITECTURE="x64"
            shift
            ;;
        --arm64)
            ARCHITECTURE="arm64"
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
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            HELP=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

show_help() {
    echo "Linux UVAtlas Build Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --debug              Build Debug configuration (default: Release)"
    echo "  --release            Build Release configuration"
    echo "  --x64                Build for x64 architecture (default)"
    echo "  --arm64              Build for ARM64 architecture"
    echo "  --tools              Build command-line tools (requires vcpkg)"
    echo "  --clean              Clean build directories before building"
    echo "  --verbose            Enable verbose output"
    echo "  --help, -h           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build Linux x64 Release"
    echo "  $0 --debug --tools    # Build Linux x64 Debug with tools"
    echo "  $0 --arm64 --clean    # Build Linux ARM64 Release (clean build)"
}

if [ "$HELP" = true ]; then
    show_help
    exit 0
fi

test_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check CMake
    if ! command -v cmake &> /dev/null; then
        print_error "CMake not found. Please install CMake."
        return 1
    fi
    cmake_version=$(cmake --version | head -n1)
    print_success "CMake found: $cmake_version"
    
    # Check Ninja
    if ! command -v ninja &> /dev/null; then
        print_error "Ninja not found. Please install Ninja."
        return 1
    fi
    ninja_version=$(ninja --version)
    print_success "Ninja found: $ninja_version"
    
    # Check compiler
    if ! command -v g++ &> /dev/null; then
        print_error "G++ compiler not found. Please install build-essential."
        return 1
    fi
    gcc_version=$(g++ --version | head -n1)
    print_success "G++ found: $gcc_version"
    
    # Check vcpkg if building tools
    if [ "$BUILD_TOOLS" = true ]; then
        if [ -z "$VCPKG_ROOT" ]; then
            print_warning "VCPKG_ROOT not set. Will try to find vcpkg in common locations."
            # Try to find vcpkg
            for vcpkg_path in ~/vcpkg /opt/vcpkg /usr/local/vcpkg; do
                if [ -d "$vcpkg_path" ] && [ -f "$vcpkg_path/scripts/buildsystems/vcpkg.cmake" ]; then
                    export VCPKG_ROOT="$vcpkg_path"
                    print_success "Found vcpkg at: $VCPKG_ROOT"
                    break
                fi
            done
            
            if [ -z "$VCPKG_ROOT" ]; then
                print_error "vcpkg not found. Please install vcpkg or set VCPKG_ROOT."
                print_status "Install vcpkg: git clone https://github.com/microsoft/vcpkg.git && cd vcpkg && ./bootstrap-vcpkg.sh"
                return 1
            fi
        else
            if [ ! -f "$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" ]; then
                print_error "Invalid VCPKG_ROOT: $VCPKG_ROOT"
                return 1
            fi
            print_success "Using vcpkg at: $VCPKG_ROOT"
        fi
    fi
    
    return 0
}

get_preset_name() {
    local preset="$ARCHITECTURE-$CONFIGURATION-Linux"
    
    if [ "$BUILD_TOOLS" = true ]; then
        preset="$preset-VCPKG"
    fi
    
    echo "$preset"
}

invoke_build() {
    local preset="$1"
    local build_dir="out/build/$preset"
    local install_dir="out/install/$preset"
    
    print_status "Building Linux version with preset: $preset"
    print_status "Build directory: $build_dir"
    
    # Configure
    local configure_args=("--preset" "$preset")
    if [ "$VERBOSE" = true ]; then
        configure_args+=("--log-level=VERBOSE")
    fi
    
    print_status "Configuring with: cmake ${configure_args[*]}"
    if ! cmake "${configure_args[@]}"; then
        print_error "Configuration failed for $preset"
        return 1
    fi
    
    # Build
    local build_args=("--build" "$build_dir")
    if [ "$VERBOSE" = true ]; then
        build_args+=("--verbose")
    fi
    
    print_status "Building with: cmake ${build_args[*]}"
    if ! cmake "${build_args[@]}"; then
        print_error "Build failed for $preset"
        return 1
    fi
    
    # Install
    local install_args=("--install" "$build_dir")
    if [ "$VERBOSE" = true ]; then
        install_args+=("--verbose")
    fi
    
    print_status "Installing with: cmake ${install_args[*]}"
    if ! cmake "${install_args[@]}"; then
        print_error "Install failed for $preset"
        return 1
    fi
    
    print_success "Successfully built Linux version: $preset"
    return 0
}

show_build_results() {
    print_status "Build Results Summary:"
    echo ""
    
    local preset=$(get_preset_name)
    local build_dir="out/build/$preset"
    local install_dir="out/install/$preset"
    
    if [ -d "$build_dir" ]; then
        echo -e "${GREEN}✅ Linux $ARCHITECTURE $CONFIGURATION${NC}"
        echo -e "${CYAN}   Build: $build_dir${NC}"
        echo -e "${CYAN}   Install: $install_dir${NC}"
        
        # Show library files
        local lib_dir="$build_dir/lib"
        if [ -d "$lib_dir" ]; then
            echo -e "${YELLOW}   Libraries:${NC}"
            ls -1 "$lib_dir" | while read file; do
                echo "     $file"
            done
        fi
        
        # Show executable files
        local bin_dir="$build_dir/bin"
        if [ -d "$bin_dir" ]; then
            echo -e "${YELLOW}   Executables:${NC}"
            ls -1 "$bin_dir" | while read file; do
                echo "     $file"
            done
        fi
        
        echo ""
    else
        echo -e "${RED}❌ Linux $ARCHITECTURE $CONFIGURATION - Not built${NC}"
    fi
}

main() {
    echo -e "${CYAN}🚀 Linux UVAtlas Build Script${NC}"
    echo -e "${YELLOW}Platform: $PLATFORM${NC}"
    echo -e "${YELLOW}Configuration: $CONFIGURATION${NC}"
    echo -e "${YELLOW}Architecture: $ARCHITECTURE${NC}"
    echo -e "${YELLOW}Build Tools: $BUILD_TOOLS${NC}"
    echo ""
    
    # Check prerequisites
    if ! test_prerequisites; then
        exit 1
    fi
    
    # Clean if requested
    if [ "$CLEAN" = true ]; then
        print_status "Cleaning build directories..."
        if [ -d "out" ]; then
            rm -rf out
            print_success "Cleaned build directories"
        fi
    fi
    
    # Build
    local preset=$(get_preset_name)
    print_status "Building Linux $ARCHITECTURE $CONFIGURATION..."
    
    if invoke_build "$preset"; then
        print_success "Build completed successfully!"
        show_build_results
        exit 0
    else
        print_error "Build failed. Check the output above for details."
        exit 1
    fi
}

# Run the main function
main
