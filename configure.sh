#!/bin/bash
# CMake Configuration Script
# Cross-platform configuration for Linux and macOS
#
# Usage:
#   ./configure.sh [Release|Debug] [--dir NAME] [--source DIR] [-- CMAKE_ARGS...]
#
# Examples:
#   ./configure.sh                          # Configure Release build
#   ./configure.sh Debug                    # Configure Debug build
#   ./configure.sh Release -- -DFOO=ON      # Pass custom CMake flags
#   ./configure.sh Release --dir tests -- -DBUILD_TESTS=ON   # Configure in build-tests
#   ./configure.sh Release --source ../other -- "-DTOOL_PATH=/opt/my tool"   # Configure ../other
#
# --dir NAME uses the build directory build-NAME instead of build-<type>.
# NAME contains only letters, digits, '_', '.' and '-'.
# --source DIR is the CMake project to configure (default: the folder above this script's folder). A relative DIR is
# relative to the current directory. The build directory is in DIR.
# Each CMake argument after -- reaches CMake as one argument, also when it holds a space.
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

# Parse arguments - extract build type and CMAKE_ARGS
BUILD_TYPE="Release"
DIR_NAME=""
SOURCE_DIR=""
# An array: each argument after -- stays one argument, also with a space in it
CMAKE_EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --)
            shift
            CMAKE_EXTRA_ARGS=("$@")
            break
            ;;
        --dir)
            if [[ $# -lt 2 || -z "$2" ]]; then
                echo "Error: --dir needs a directory name"
                exit 1
            fi
            DIR_NAME="$2"
            shift 2
            ;;
        --source)
            if [[ $# -lt 2 || -z "$2" ]]; then
                echo "Error: --source needs a directory"
                exit 1
            fi
            SOURCE_DIR="$2"
            shift 2
            ;;
        Release|Debug)
            BUILD_TYPE="$1"
            shift
            ;;
        *)
            echo "Error: Unknown argument '$1'"
            echo "Usage: $0 [Release|Debug] [--dir NAME] [--source DIR] [-- CMAKE_ARGS...]"
            exit 1
            ;;
    esac
done

# The project: --source DIR, or the folder above this script's folder (the 'tools' layout)
if [[ -n "$SOURCE_DIR" ]]; then
    if [[ ! -d "$SOURCE_DIR" ]]; then
        echo "Error: --source directory not found: $SOURCE_DIR"
        exit 1
    fi
    PROJECT_ROOT="$( cd "$SOURCE_DIR" && pwd )"
else
    PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
fi
if [[ ! -f "$PROJECT_ROOT/CMakeLists.txt" ]]; then
    echo "Error: CMakeLists.txt not found in $PROJECT_ROOT"
    echo "Give the project with --source DIR, or put this script in a 'tools' subdirectory of the project"
    exit 1
fi

# Build directory naming. The script removes an existing build directory below,
# so a --dir name must stay one directory below the project root.
BUILD_DIR="$PROJECT_ROOT/build-$BUILD_TYPE"
if [[ -n "$DIR_NAME" ]]; then
    if [[ ! "$DIR_NAME" =~ ^[A-Za-z0-9_.-]+$ || "$DIR_NAME" == "." || "$DIR_NAME" == ".." ]]; then
        echo "Error: Invalid --dir name '$DIR_NAME'"
        echo "Use only letters, digits, '_', '.' and '-' (not '.' or '..')"
        exit 1
    fi
    BUILD_DIR="$PROJECT_ROOT/build-$DIR_NAME"
fi

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

if [[ ${#CMAKE_EXTRA_ARGS[@]} -gt 0 ]]; then
    echo "Extra CMake args: ${CMAKE_EXTRA_ARGS[*]}"
    echo ""
fi

cd "$BUILD_DIR"

cmake \
    -G "$GENERATOR" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    "${CMAKE_EXTRA_ARGS[@]}" \
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
