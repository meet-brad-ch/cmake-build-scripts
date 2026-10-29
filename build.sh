#!/bin/bash
# CMake Build Script for Linux/macOS
# Wrapper around CMake build system
#
# Usage:
#   ./build.sh [target] [Release|Debug] [--dir NAME] [--source DIR]
#
# Examples:
#   ./build.sh                    # Build all targets (Release)
#   ./build.sh <target>           # Build specific target
#   ./build.sh all Debug          # Build everything in Debug mode
#   ./build.sh all Release --dir tests   # Build in build-tests
#   ./build.sh all Release --source ../other   # Build the project ../other
#
# --dir NAME uses the build directory build-NAME instead of build-<type>.
# NAME contains only letters, digits, '_', '.' and '-'.
# --source DIR is the CMake project that configure.sh configured with --source DIR (default: the folder above this
# script's folder). A relative DIR is relative to the current directory.

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Parse arguments: the positional target and build type, and --dir NAME and --source DIR at any place
POSITIONAL=()
DIR_NAME=""
SOURCE_DIR=""
while [[ $# -gt 0 ]]; do
    case $1 in
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
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done
if [[ ${#POSITIONAL[@]} -gt 2 ]]; then
    echo "Error: Unknown argument '${POSITIONAL[2]}'"
    echo "Usage: $0 [target] [Release|Debug] [--dir NAME] [--source DIR]"
    exit 1
fi

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
TARGET="${POSITIONAL[0]:-all}"
BUILD_TYPE="${POSITIONAL[1]:-Release}"

# Validate build type
if [[ "$BUILD_TYPE" != "Release" && "$BUILD_TYPE" != "Debug" ]]; then
    echo "Error: Build type must be 'Release' or 'Debug'"
    echo "Usage: $0 [target] [Release|Debug] [--dir NAME] [--source DIR]"
    exit 1
fi

BUILD_DIR="$PROJECT_ROOT/build-$BUILD_TYPE"
CONFIGURE_HINT="./configure.sh $BUILD_TYPE"
if [[ -n "$SOURCE_DIR" ]]; then
    CONFIGURE_HINT="$CONFIGURE_HINT --source $PROJECT_ROOT"
fi
if [[ -n "$DIR_NAME" ]]; then
    if [[ ! "$DIR_NAME" =~ ^[A-Za-z0-9_.-]+$ || "$DIR_NAME" == "." || "$DIR_NAME" == ".." ]]; then
        echo "Error: Invalid --dir name '$DIR_NAME'"
        echo "Use only letters, digits, '_', '.' and '-' (not '.' or '..')"
        exit 1
    fi
    BUILD_DIR="$PROJECT_ROOT/build-$DIR_NAME"
    CONFIGURE_HINT="$CONFIGURE_HINT --dir $DIR_NAME"
fi

# ============================================================================
# Pre-flight Checks
# ============================================================================

# Check if build directory exists
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory not found: $BUILD_DIR"
    echo ""
    echo "Please run configuration first:"
    echo "  cd tools && $CONFIGURE_HINT"
    exit 1
fi

# Check if CMakeCache.txt exists
if [ ! -f "$BUILD_DIR/CMakeCache.txt" ]; then
    echo "Error: CMake configuration not found in $BUILD_DIR"
    echo ""
    echo "Please run configuration first:"
    echo "  cd tools && $CONFIGURE_HINT"
    exit 1
fi

# ============================================================================
# Detect Build System and CPU Count
# ============================================================================

# Detect generator from CMakeCache.txt
GENERATOR=$(grep "CMAKE_GENERATOR:" "$BUILD_DIR/CMakeCache.txt" | cut -d'=' -f2)

# Detect CPU count for parallel builds
if command -v nproc &> /dev/null; then
    NPROC=$(nproc)
elif [ -f /proc/cpuinfo ]; then
    NPROC=$(grep -c ^processor /proc/cpuinfo)
else
    NPROC=4  # Default fallback
fi

# ============================================================================
# Build Information
# ============================================================================

echo ""
echo "============================================"
echo "Build Configuration"
echo "============================================"
echo "Target:     $TARGET"
echo "Build Type: $BUILD_TYPE"
echo "Build Dir:  $BUILD_DIR"
echo "Generator:  $GENERATOR"
echo "Jobs:       $NPROC"
echo "============================================"
echo ""

# ============================================================================
# Build
# ============================================================================

echo "Building..."
echo ""

cd "$BUILD_DIR"

# Use cmake --build for cross-platform compatibility. The exit code is taken with ||: under set -e a failing
# command on its own would end the script before the report below, and after 'if !' $? is the negated status.
BUILD_EXIT_CODE=0
cmake --build . --target "$TARGET" --config "$BUILD_TYPE" -j "$NPROC" || BUILD_EXIT_CODE=$?

echo ""

# ============================================================================
# Build Result
# ============================================================================

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo "============================================"
    echo "SUCCESS: Build completed for '$TARGET'"
    echo "============================================"
    echo ""
    exit 0
else
    echo "============================================"
    echo "FAILED: Build failed for '$TARGET'"
    echo "============================================"
    echo ""
    echo "Build directory: $BUILD_DIR"
    echo "Exit code: $BUILD_EXIT_CODE"
    echo ""
    exit $BUILD_EXIT_CODE
fi
