# cmake-build-scripts

Generic CMake build wrapper scripts for Windows and Linux/macOS. Designed to be added as a git submodule to any CMake-based project.

## Features

- **Cross-platform**: Windows (batch) and Linux/macOS (bash) scripts
- **Auto-detection**: Finds Visual Studio, Ninja, Make automatically
- **Parallel builds**: Uses all available CPU cores
- **CMake passthrough**: Forward custom flags to CMake with `--` syntax
- **Zero configuration**: Works out-of-the-box with any CMake 3.20+ project

## Requirements

| Platform | Requirements |
|----------|-------------|
| **Windows** | Visual Studio 2022, CMake 3.20+, Ninja (recommended) |
| **Linux** | GCC 9+ or Clang 10+, CMake 3.20+, Ninja or Make |
| **macOS** | Xcode Command Line Tools, CMake 3.20+, Ninja or Make |

## Installation

Add as a git submodule to your project's `tools/` directory:

```bash
cd your-project
git submodule add https://github.com/yourname/cmake-build-scripts tools
git commit -m "Add cmake-build-scripts submodule"
```

For existing projects, clone with submodules:

```bash
git clone --recurse-submodules https://github.com/yourname/your-project
```

## Usage

### Configure

Generates build files in `build-<type>/` directory.

**Windows:**
```batch
cd tools
configure.bat [Release|Debug] [Ninja|"Visual Studio"] [-- CMAKE_ARGS...]
```

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

Builds specified target(s).

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
