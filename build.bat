@echo off
setlocal EnableDelayedExpansion

REM The script's own directory, kept before the argument loop: shift also moves %0
set "SCRIPT_DIR=%~dp0"

REM ============================================================================
REM Generic CMake Build Script for Windows
REM ============================================================================
REM Builds specified CMake target using Visual Studio toolchain
REM Works with any CMake-based project - just place in a 'tools' subdirectory
REM
REM Usage:
REM   build.bat <target> [build_type] [jobs] [--dir NAME]
REM
REM Arguments:
REM   target     - CMake target name (required, or "all" for everything)
REM   build_type - Debug or Release (default: Release)
REM   jobs       - Number of parallel jobs (default: auto-detected)
REM   --dir NAME - Use the build directory build-NAME instead of build-<build_type>.
REM                NAME contains only letters, digits, '_', '.' and '-'.
REM
REM Examples:
REM   build.bat all              # Build all targets (Release)
REM   build.bat <target>          # Build specific target
REM   build.bat clean            # Clean build artifacts
REM   build.bat <target> Debug    # Build in Debug mode
REM   build.bat all Release 8    # Build with 8 parallel jobs
REM   build.bat all Release --dir tests   # Build in build-tests
REM ============================================================================

REM Parse arguments: the positional target, build type and jobs, and --dir NAME at any place
set TARGET=
set BUILD_TYPE=
set JOBS=
set DIR_NAME=
:parse_args
if "%~1"=="" goto :done_parsing
if "%~1"=="--dir" (
    if "%~2"=="" (
        echo [build] ERROR: --dir needs a directory name
        exit /b 1
    )
    set "DIR_NAME=%~2"
    shift
    shift
    goto :parse_args
)
if not defined TARGET (
    set "TARGET=%~1"
    shift
    goto :parse_args
)
if not defined BUILD_TYPE (
    set "BUILD_TYPE=%~1"
    shift
    goto :parse_args
)
if not defined JOBS (
    set "JOBS=%~1"
    shift
    goto :parse_args
)
echo [build] ERROR: Unknown argument "%~1"
echo [build] Usage: build.bat ^<target^> [build_type] [jobs] [--dir NAME]
exit /b 1
:done_parsing

REM Check for target argument
if not defined TARGET (
    echo.
    echo [build] ERROR: No target specified
    echo.
    echo Usage: build.bat ^<target^> [build_type] [jobs] [--dir NAME]
    echo.
    echo Examples:
    echo   build.bat all           # Build everything
    echo   build.bat ^<target^>       # Build specific target
    echo   build.bat clean         # Clean artifacts
    echo.
    exit /b 1
)

if not defined BUILD_TYPE set BUILD_TYPE=Release
if not defined JOBS set JOBS=%NUMBER_OF_PROCESSORS%

REM Define paths - assumes this script is in 'tools' subdirectory
set PROJECT_ROOT=%SCRIPT_DIR%..
set BUILD_DIR=%PROJECT_ROOT%\build-%BUILD_TYPE%
set CONFIGURE_HINT=configure.bat %BUILD_TYPE%
if defined DIR_NAME (
    REM The name must stay one directory below the project root: only letters, digits, '_', '.' and '-'.
    REM Every allowed character is a delimiter, so a token remains only if another character is present.
    if "!DIR_NAME!"=="." goto :bad_dir_name
    if "!DIR_NAME!"==".." goto :bad_dir_name
    for /f "delims=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-" %%c in ("!DIR_NAME!") do goto :bad_dir_name
    set "BUILD_DIR=%PROJECT_ROOT%\build-!DIR_NAME!"
    set "CONFIGURE_HINT=configure.bat %BUILD_TYPE% --dir !DIR_NAME!"
)

REM Check if build directory exists
if not exist "%BUILD_DIR%\CMakeCache.txt" (
    echo.
    echo [build] ============================================
    echo [build] ERROR: Build directory not configured
    echo [build] ============================================
    echo [build] Build directory: %BUILD_DIR%
    echo.
    echo [build] Please run configure.bat first:
    echo [build]   cd %SCRIPT_DIR%
    echo [build]   !CONFIGURE_HINT!
    echo.
    exit /b 1
)

REM Setup VS environment (after the argument and directory checks, so a wrong call fails at once)
call "%SCRIPT_DIR%setup_vs_env.bat"
if errorlevel 1 (
    echo.
    echo [build] ERROR: Cannot continue without Visual Studio
    echo [build] Build aborted.
    echo.
    exit /b 1
)

echo.
echo [build] ============================================
echo [build] Build Configuration
echo [build] ============================================
echo [build] Target:     %TARGET%
echo [build] Build Type: %BUILD_TYPE%
echo [build] Build Dir:  %BUILD_DIR%
echo [build] Jobs:       %JOBS%
echo [build] ============================================
echo.

REM Navigate to build directory
cd /d "%BUILD_DIR%"

REM Build the target
echo [build] Building...
echo.

cmake --build . --target %TARGET% -j %JOBS%

if errorlevel 1 (
    echo.
    echo [build] ============================================
    echo [build] ERROR: Build failed for target '%TARGET%'
    echo [build] ============================================
    exit /b 1
)

echo.
echo [build] ============================================
echo [build] SUCCESS: Build completed for '%TARGET%'
echo [build] ============================================

exit /b 0

:bad_dir_name
echo [build] ERROR: Invalid --dir name "!DIR_NAME!"
echo [build] Use only letters, digits, '_', '.' and '-' (not "." or "..")
exit /b 1
