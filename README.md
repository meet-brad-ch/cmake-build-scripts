# cmake-build-scripts

[![CI](https://github.com/meet-brad-ch/cmake-build-scripts/actions/workflows/ci.yml/badge.svg)](https://github.com/meet-brad-ch/cmake-build-scripts/actions/workflows/ci.yml)
![CMake](https://img.shields.io/badge/CMake-3.20%2B-blue)
![Platforms](https://img.shields.io/badge/platforms-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Generic CMake build wrapper scripts for Windows and Linux/macOS. Add them to any CMake-based project as a git submodule.

## Features

- **Cross-platform**: Windows (batch) and Linux/macOS (bash) scripts
- **Auto-detection**: Finds Visual Studio (2026 or 2022, any edition), Ninja, and Make
- **Parallel builds**: Uses all available CPU cores
- **CMake passthrough**: Forwards custom flags to CMake after `--`
- **No configuration**: Works with any CMake 3.20+ project without setup

## Requirements

| Platform | Requirements |
|----------|-------------|
| **Windows** | Visual Studio 2026 or 2022 (Community, Professional, Enterprise, or BuildTools), CMake 3.20+, Ninja (recommended) |
| **Linux** | GCC 9+ or Clang 10+, CMake 3.20+, Ninja or Make |
| **macOS** | Xcode Command Line Tools, CMake 3.20+, Ninja or Make |

## Installation

Add as a git submodule to your project's `tools/` directory:

```bash
cd your-project
git submodule add https://github.com/meet-brad-ch/cmake-build-scripts tools
git commit -m "Add cmake-build-scripts submodule"
```

For existing projects, clone with submodules:

```bash
git clone --recurse-submodules https://github.com/yourname/your-project
```

## Usage

### Configure

Generates build files in the `build-<type>/` directory.

**Windows:**
```batch
cd tools
configure.bat [Release|Debug] [Ninja|"Visual Studio"] [-- CMAKE_ARGS...]
```

> **Note:** run the `.bat` scripts from `cmd.exe` or PowerShell, not from Git Bash. Git Bash invokes batch files through a bridge that leaves `%~dp0` empty. The scripts then cannot find their own directory.

**Linux/macOS:**
```bash
cd tools
./configure.sh [Release|Debug] [-- CMAKE_ARGS...]
```

**Examples:**
```bash
# Basic Release build
./configure.bat Release
./configure.sh Release

# Debug build
./configure.bat Debug
./configure.sh Debug

# With custom CMake flags
./configure.bat Release Ninja -- -DBUILD_TESTS=OFF -DENABLE_GPU=ON
./configure.sh Release -- -DBUILD_TESTS=OFF
```

### Build

Builds the specified target.

**Windows:**
```batch
cd tools
build.bat <target> [Release|Debug] [jobs]
```

**Linux/macOS:**
```bash
cd tools
./build.sh [target] [Release|Debug]
```

**Examples:**
```bash
# Build all targets
./build.bat all Release
./build.sh all

# Build specific target
./build.bat MyApp Release
./build.sh MyApp

# Build with specific job count (Windows)
./build.bat all Release 8

# Clean build artifacts
./build.bat clean
./build.sh clean
```

## Scripts Reference

| Script | Platform | Purpose |
|--------|----------|---------|
| `configure.bat` | Windows | Configure CMake with VS/Ninja |
| `configure.sh` | Linux/macOS | Configure CMake with Ninja/Make |
| `build.bat` | Windows | Build targets |
| `build.sh` | Linux/macOS | Build targets |
| `setup_vs_env.bat` | Windows | Initialize VS environment (internal) |

## Directory Structure

After configuration, your project will have:

```
your-project/
├── CMakeLists.txt
├── src/
├── build-Release/        # Created by configure
│   ├── bin/
│   └── lib/
├── build-Debug/          # Created by configure (if Debug)
└── tools/                # This submodule
    ├── configure.bat
    ├── configure.sh
    ├── build.bat
    ├── build.sh
    ├── setup_vs_env.bat
    └── README.md
```

## Updating

To update the scripts in your project:

```bash
cd tools
git pull origin main
cd ..
git add tools
git commit -m "Update cmake-build-scripts"
```

## License

MIT License - Use freely in any project.
