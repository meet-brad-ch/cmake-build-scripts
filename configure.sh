#!/bin/bash
# CMake Configuration Script
# Cross-platform configuration for Linux and macOS
#
# Usage:
#   ./configure.sh [Release|Debug] [-- CMAKE_ARGS...]
#
# Examples:
#   ./configure.sh                          # Configure Release build
#   ./configure.sh Debug                    # Configure Debug build
#   ./configure.sh Release -- -DFOO=ON      # Pass custom CMake flags
#
# This script automatically:
#   - Configures build type (Release or Debug)
#   - Sets up Ninja build system if available (falls back to Make)
#   - Creates build directory with proper naming

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================

# Get script directory (works even when sourced or executed via symlink)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Parse arguments - extract build type and CMAKE_ARGS
BUILD_TYPE="Release"
CMAKE_EXTRA_ARGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --)
            shift
            CMAKE_EXTRA_ARGS="$@"
            break
            ;;
        Release|Debug)
            BUILD_TYPE="$1"
            shift
            ;;
        *)
            echo "Error: Unknown argument '$1'"
            echo "Usage: $0 [Release|Debug] [-- CMAKE_ARGS...]"
            exit 1
            ;;
    esac
done

# Build directory naming
BUILD_DIR="$PROJECT_ROOT/build-$BUILD_TYPE"

# ============================================================================
# System Detection
# ============================================================================

echo "========================================"
echo "CMake Configuration Script"
echo "========================================"
echo ""
echo "System Information:"
echo "  OS: $(uname -s)"
echo "  Architecture: $(uname -m)"
echo "  Build Type: $BUILD_TYPE"
echo ""

# ============================================================================
# CMake Detection
# ============================================================================

if ! command -v cmake &> /dev/null; then
    echo "Error: CMake not found"
    echo ""
    echo "On Ubuntu/Debian:"
    echo "  sudo apt-get install cmake"
    echo ""
    echo "On macOS:"
    echo "  brew install cmake"
    echo ""
    echo "Required: CMake 3.20 or higher"
    exit 1
fi

CMAKE_VERSION=$(cmake --version | head -n1 | cut -d' ' -f3)
echo "CMake: $CMAKE_VERSION"

# Check minimum CMake version (3.20)
CMAKE_MAJOR=$(echo $CMAKE_VERSION | cut -d'.' -f1)
CMAKE_MINOR=$(echo $CMAKE_VERSION | cut -d'.' -f2)

if [ "$CMAKE_MAJOR" -lt 3 ] || { [ "$CMAKE_MAJOR" -eq 3 ] && [ "$CMAKE_MINOR" -lt 20 ]; }; then
    echo "Error: CMake 3.20 or higher required (found $CMAKE_VERSION)"
    exit 1
fi

# ============================================================================
# Build System Detection (Ninja vs Make)
# ============================================================================

if command -v ninja &> /dev/null; then
    GENERATOR="Ninja"
    echo "Build System: Ninja (fast parallel builds)"
else
    GENERATOR="Unix Makefiles"
    echo "Build System: Make (consider installing ninja for faster builds)"
    echo "  sudo apt-get install ninja-build"
fi

echo ""

# ============================================================================
# Create Build Directory
# ============================================================================

echo "========================================"
echo "Creating Build Directory"
echo "========================================"
echo ""

if [ -d "$BUILD_DIR" ]; then
    echo "Build directory exists: $BUILD_DIR"
    echo "Removing existing build directory..."
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"
echo "Created: $BUILD_DIR"
echo ""

# ============================================================================
# Run CMake Configuration
# ============================================================================

echo "========================================"
echo "Running CMake Configuration"
echo "========================================"
echo ""

if [ -n "$CMAKE_EXTRA_ARGS" ]; then
    echo "Extra CMake args: $CMAKE_EXTRA_ARGS"
    echo ""
fi

cd "$BUILD_DIR"

cmake \
    -G "$GENERATOR" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    $CMAKE_EXTRA_ARGS \
    "$PROJECT_ROOT"

# ============================================================================
# Configuration Summary
# ============================================================================

echo ""
echo "========================================"
echo "Configuration Complete"
echo "========================================"
echo ""
echo "Build directory: $BUILD_DIR"
echo "Build type: $BUILD_TYPE"
echo "Generator: $GENERATOR"
echo ""
