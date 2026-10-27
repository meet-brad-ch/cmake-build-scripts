@echo off
setlocal EnableDelayedExpansion

REM The script's own directory, kept before the argument loop: shift also moves %0
set "SCRIPT_DIR=%~dp0"

REM ============================================================================
REM Generic CMake Configuration Script for Windows
REM ============================================================================
REM Configures a CMake project using Visual Studio toolchain and Ninja generator
REM Works with any CMake-based project - just place in a 'tools' subdirectory
REM
REM Usage:
REM   configure.bat [build_type] [generator] [--dir NAME] [-- CMAKE_ARGS...]
REM
REM Arguments:
REM   build_type  - Debug or Release (default: Release)
REM   generator   - "Ninja" or "Visual Studio" (default: Ninja)
REM   --dir NAME  - Use the build directory build-NAME instead of build-<build_type>.
REM                 NAME contains only letters, digits, '_', '.' and '-'.
REM   CMAKE_ARGS  - Additional CMake arguments (after --)
REM
REM Examples:
REM   configure.bat Release
REM   configure.bat Debug Ninja
REM   configure.bat Release Ninja -- -DENABLE_CUDA=OFF
REM   configure.bat Release Ninja --dir tests -- -DBUILD_TESTS=ON
REM ============================================================================

REM Parse arguments: the positional build type and generator, --dir NAME at any place before --,
REM and the extra CMake args (everything after --)
set BUILD_TYPE=
set GENERATOR=
set DIR_NAME=
set CMAKE_EXTRA_ARGS=
:parse_args
if "%~1"=="" goto :done_parsing
if "%~1"=="--" goto :parse_extra
if "%~1"=="--dir" (
    if "%~2"=="" (
        echo [configure] ERROR: --dir needs a directory name
        exit /b 1
    )
    set "DIR_NAME=%~2"
    shift
    shift
    goto :parse_args
)
if not defined BUILD_TYPE (
    set "BUILD_TYPE=%~1"
    shift
    goto :parse_args
)
if not defined GENERATOR (
    set "GENERATOR=%~1"
    shift
    goto :parse_args
)
echo [configure] ERROR: Unknown argument "%~1"
echo [configure] Usage: configure.bat [build_type] [generator] [--dir NAME] [-- CMAKE_ARGS...]
exit /b 1
:parse_extra
REM Take the raw text after " -- " from %*: cmd splits arguments at '=', so a rebuilt
REM token list turns -DFOO=ON into -DFOO ON
set "ALL_ARGS=%*"
if "!ALL_ARGS:~0,3!"=="-- " (
    set "CMAKE_EXTRA_ARGS=!ALL_ARGS:~3!"
) else (
    set "CMAKE_EXTRA_ARGS=!ALL_ARGS:* -- =!"
    if "!CMAKE_EXTRA_ARGS!"=="!ALL_ARGS!" set CMAKE_EXTRA_ARGS=
)
:done_parsing
if not defined BUILD_TYPE set BUILD_TYPE=Release
if not defined GENERATOR set GENERATOR=Ninja

REM Define paths - assumes this script is in 'tools' subdirectory
set PROJECT_ROOT=%SCRIPT_DIR%..
set BUILD_DIR=%PROJECT_ROOT%\build-%BUILD_TYPE%
if defined DIR_NAME (
    REM The name must stay one directory below the project root: only letters, digits, '_', '.' and '-'.
    REM Every allowed character is a delimiter, so a token remains only if another character is present.
    if "!DIR_NAME!"=="." goto :bad_dir_name
    if "!DIR_NAME!"==".." goto :bad_dir_name
    for /f "delims=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-" %%c in ("!DIR_NAME!") do goto :bad_dir_name
    set "BUILD_DIR=%PROJECT_ROOT%\build-!DIR_NAME!"
)

REM Setup VS environment (after the argument checks, so a wrong call fails at once)
call "%SCRIPT_DIR%setup_vs_env.bat"
if errorlevel 1 (
    echo.
    echo [configure] ERROR: Cannot continue without Visual Studio
    echo [configure] Configuration aborted.
    echo.
    exit /b 1
)

echo.
echo [configure] ============================================
echo [configure] CMake Configuration
echo [configure] ============================================
echo [configure] Build Type:  %BUILD_TYPE%
echo [configure] Generator:   %GENERATOR%
echo [configure] Project:     %PROJECT_ROOT%
echo [configure] Build Dir:   %BUILD_DIR%
if not "%CMAKE_EXTRA_ARGS%"=="" echo [configure] Extra Args: %CMAKE_EXTRA_ARGS%
echo [configure] ============================================
echo.

REM Verify CMakeLists.txt exists
if not exist "%PROJECT_ROOT%\CMakeLists.txt" (
    echo [configure] ERROR: CMakeLists.txt not found in %PROJECT_ROOT%
    echo [configure] Make sure this script is in a 'tools' subdirectory of your CMake project
    exit /b 1
)

REM Create and enter build directory
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
cd /d "%BUILD_DIR%"

REM Run CMake configuration
echo [configure] Running CMake...
echo.

if /i "%GENERATOR%"=="Ninja" (
    cmake -G Ninja -DCMAKE_BUILD_TYPE=%BUILD_TYPE% %CMAKE_EXTRA_ARGS% "%PROJECT_ROOT%"
) else if /i "%GENERATOR%"=="Visual Studio" (
    cmake -G "%VS_GENERATOR%" -A x64 %CMAKE_EXTRA_ARGS% "%PROJECT_ROOT%"
) else (
    echo [configure] ERROR: Unknown generator "%GENERATOR%"
    echo [configure] Valid options: Ninja, "Visual Studio"
    exit /b 1
)

if errorlevel 1 (
    echo.
    echo [configure] ERROR: CMake configuration failed
    exit /b 1
)

echo.
echo [configure] ============================================
echo [configure] Configuration complete!
echo [configure] Build directory: %BUILD_DIR%
echo [configure] ============================================
echo.

exit /b 0

:bad_dir_name
echo [configure] ERROR: Invalid --dir name "!DIR_NAME!"
echo [configure] Use only letters, digits, '_', '.' and '-' (not "." or "..")
exit /b 1
