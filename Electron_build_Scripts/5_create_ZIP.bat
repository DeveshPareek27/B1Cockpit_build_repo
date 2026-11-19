@echo off
setlocal enabledelayedexpansion

REM === Load variables from config.env ===
for /f "tokens=1,* delims==" %%A in (0_0_Config.env) do (
    set %%A=%%B
)

REM BASE_PATH is current directory
SET BASE_PATH=%cd%
echo BASE_PATH is: %BASE_PATH%

REM Navigate to 7-Zip directory
cd %BASE_PATH%\utils\7-Zip

@REM set VERSION_FILE_PATH = %BASE_PATH%\..\%Build_Dir%\release-builds\%PROJECT%-win32-x64\projects\ENT_B1_Cockpit

for /f "delims=" %%v in ('powershell -Command "(Get-Content -Raw -Path '%UI5_PATH%/version.json' | ConvertFrom-Json).version"') do set VERSION=%%v
echo 🔖 Version: %VERSION%
REM Set version
set "version=%VERSION%"
@REM read form verison file
echo Version is: %version%

set "INSTALLER_FILE=%BASE_PATH%\%PROJECT%-Installer-%version%.exe"
set "PAYLOAD_MANIFEST=%BASE_PATH%\..\%Build_Dir%\release-builds\checksums.sha256"

REM SHA-256 manifest of everything packed into the installer (checked by Install.bat).
REM Keep this file list identical to the 7z file list below.
powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE_PATH%\utils\New-Checksums.ps1" -OutFile "%PAYLOAD_MANIFEST%" ^
   "%BASE_PATH%\..\%Build_Dir%\release-builds\%PROJECT%-win32-x64" ^
   "%BASE_PATH%\utils\Install.bat" ^
   "%BASE_PATH%\utils\Uninstall.bat" ^
   "%BASE_PATH%\utils\Auto_Restart_Cockpit.bat" ^
   "%BASE_PATH%\utils\Reconfig.bat" ^
   "%BASE_PATH%\utils\Verify-Checksums.ps1"
if %errorlevel% neq 0 (
    echo [ERROR] Payload checksum generation failed.
    cd %BASE_PATH%
    exit /b 1
)

REM "7z a" appends to an existing archive, so start from a clean file
if exist "%INSTALLER_FILE%" del /f /q "%INSTALLER_FILE%"

REM Use projectName from config file
7z a -sfx "%INSTALLER_FILE%" ^
   "%BASE_PATH%\..\%Build_Dir%\release-builds\%PROJECT%-win32-x64" ^
   "%BASE_PATH%\utils\Install.bat" ^
   "%BASE_PATH%\utils\Uninstall.bat" ^
   "%BASE_PATH%\utils\Auto_Restart_Cockpit.bat" ^
   "%BASE_PATH%\utils\Reconfig.bat" ^
   "%BASE_PATH%\utils\Verify-Checksums.ps1" ^
   "%PAYLOAD_MANIFEST%"
if %errorlevel% neq 0 (
    echo [ERROR] Installer creation failed.
    cd %BASE_PATH%
    exit /b 1
)

REM SHA-256 of the installer for download verification (.sha256 + .json)
powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE_PATH%\utils\New-Checksums.ps1" -Installer "%INSTALLER_FILE%" -Product "%PROJECT%" -Version "%version%" -PayloadManifest "%PAYLOAD_MANIFEST%"

REM Return to base path
cd %BASE_PATH%

endlocal
