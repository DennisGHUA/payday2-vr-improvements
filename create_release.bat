@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

echo ===== VR Improvements Mod / VRplus Continued Release Builder =====

REM --- Configuration ---
SET "OUTPUT_SUBDIR=release"
SET "TEMP_DIR=%OUTPUT_SUBDIR%\__vrplus_temp__"
SET "EXCLUDE_DIRS=.git .idea .vscode PD2SRC release %TEMP_DIR%"
SET "EXCLUDE_FILES=.gitignore create_release.bat" 
SET "GITHUB_META_URL=https://raw.githubusercontent.com/DennisGHUA/payday2-vr-improvements/master/updates_meta.json"
SET "TEMP_GITHUB_META=%OUTPUT_SUBDIR%\__vrplus_temp__github_meta.json"
REM --- End Configuration ---

REM Create output directory
IF NOT EXIST "%OUTPUT_SUBDIR%" (
    ECHO Creating output directory...
    MKDIR "%OUTPUT_SUBDIR%" 2>nul
    IF ERRORLEVEL 1 (
        ECHO Warning: Failed to create directory. Try running as Administrator.
    )
)

REM Get version from mod.txt
FOR /F "tokens=2 delims=:, " %%V IN ('findstr /C:"\"version\"" mod.txt') DO (
    SET VERSION=%%V
    SET VERSION=!VERSION:"=!
    ECHO Local version from mod.txt: !VERSION!
)

IF "!VERSION!"=="" (
    ECHO No version found in mod.txt
    GOTO END_SCRIPT
)

REM Create temp directory for GitHub version check
IF NOT EXIST "!TEMP_DIR!" MKDIR "!TEMP_DIR!" 2>nul
IF ERRORLEVEL 1 (
    ECHO Failed to create temp directory. Exiting.
    GOTO END_SCRIPT
)

REM Download GitHub updates_meta.json to check version
ECHO Checking GitHub version...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "Invoke-WebRequest -Uri '!GITHUB_META_URL!' -OutFile '!TEMP_GITHUB_META!'" 2>nul

IF ERRORLEVEL 1 (
    ECHO Warning: Failed to download GitHub version information.
    ECHO Building with local version: !VERSION!
) ELSE (
    REM Extract GitHub version
    FOR /F "tokens=2 delims=:, " %%G IN ('findstr /C:"\"version\"" "!TEMP_GITHUB_META!"') DO (
        SET GITHUB_VERSION=%%G
        SET GITHUB_VERSION=!GITHUB_VERSION:"=!
        SET GITHUB_VERSION=!GITHUB_VERSION: =!
        ECHO GitHub version: !GITHUB_VERSION!
    )
      IF "!GITHUB_VERSION!"=="" (
        ECHO Warning: Could not find version in GitHub metadata.
        ECHO Building with local version: !VERSION!
    ) ELSE IF "!VERSION!" EQU "!GITHUB_VERSION!" (
        ECHO ERROR: Version match detected!
        ECHO Local version:  !VERSION!
        ECHO GitHub version: !GITHUB_VERSION!
        ECHO The version in mod.txt must be different than the one in GitHub updates_meta.json
        ECHO Build failed.
        GOTO CLEANUP_AND_EXIT
    ) ELSE (
        ECHO Version check passed: !VERSION! is different from GitHub version.
    )
)

SET "ARCHIVE_NAME=vrplus_!VERSION!.zip"
SET "ARCHIVE_FULL_PATH=!OUTPUT_SUBDIR!\!ARCHIVE_NAME!"

REM Set up temp directory structure
IF EXIST "!TEMP_DIR!" RMDIR /S /Q "!TEMP_DIR!" 2>nul
MKDIR "!TEMP_DIR!" 2>nul
IF ERRORLEVEL 1 (
    ECHO Failed to create temp directory. Exiting.
    GOTO END_SCRIPT
)

REM Create vrplus folder inside temp dir for final structure
SET "TEMP_VRPLUS_DIR=!TEMP_DIR!\vrplus"
MKDIR "!TEMP_VRPLUS_DIR!" 2>nul
IF ERRORLEVEL 1 (
    ECHO Failed to create vrplus folder. Exiting.
    GOTO END_SCRIPT
)

ECHO Copying files to temp folder...

REM Build exclude arguments
SET ROBOCOPY_XD_ARGS=
FOR %%D IN (!EXCLUDE_DIRS!) DO SET ROBOCOPY_XD_ARGS=!ROBOCOPY_XD_ARGS! %%D

SET ROBOCOPY_XF_ARGS=
FOR %%F IN (!EXCLUDE_FILES!) DO SET ROBOCOPY_XF_ARGS=!ROBOCOPY_XF_ARGS! %%F

REM Copy files using robocopy directly to the vrplus folder
robocopy . "!TEMP_VRPLUS_DIR!" /E /XD !ROBOCOPY_XD_ARGS! /XF !ROBOCOPY_XF_ARGS! /NFL /NDL /NJH /NJS /R:2 /W:5

SET ROBOCOPY_ERROR=!ERRORLEVEL!
IF !ROBOCOPY_ERROR! GEQ 8 (
    ECHO Robocopy error: !ROBOCOPY_ERROR!
    ECHO Copy process failed. Exiting.
    GOTO CLEANUP_AND_EXIT
)

REM Check if temp directory is empty
dir /a /b "!TEMP_VRPLUS_DIR!" | findstr . > nul
IF ERRORLEVEL 1 (
    ECHO No files were copied. Exiting.
    GOTO CLEANUP_AND_EXIT
)

:CREATE_ZIP
ECHO Creating ZIP: !ARCHIVE_NAME!

REM Create ZIP archive (the vrplus folder is already set up)
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '!TEMP_DIR!\*' -DestinationPath '!ARCHIVE_FULL_PATH!' -Force" 2>nul

IF ERRORLEVEL 1 (
    ECHO ZIP creation failed. Files in: !TEMP_VRPLUS_DIR!
) ELSE (
    ECHO Created: !ARCHIVE_FULL_PATH!
)

:CLEANUP_AND_EXIT
ECHO Cleaning up...
IF EXIST "!TEMP_DIR!" RMDIR /S /Q "!TEMP_DIR!" 2>nul
IF EXIST "!TEMP_GITHUB_META!" DEL /F /Q "!TEMP_GITHUB_META!" 2>nul

:END_SCRIPT
ECHO ====== Done! ======
ENDLOCAL
