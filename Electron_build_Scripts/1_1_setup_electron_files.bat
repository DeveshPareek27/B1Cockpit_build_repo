@echo off
setlocal enabledelayedexpansion

REM === Load variables from config.env ===
for /f "tokens=1,* delims==" %%A in (0_0_Config.env) do (
    set %%A=%%B
)

REM === Go to script's parent directory ===
cd /d "%~dp0"
set "ELECTRON_SCRIPT_PATH=%~dp0"
cd ..
echo %cd%


REM === Set build directory ===
set "BUILD_DIR=%cd%\%Build_Dir%"

REM === Confirm loaded values ===
echo [INFO] PROJECT: %PROJECT%
echo [INFO] APPLICATION_PORT: %APPLICATION_PORT%
echo [INFO] Build Directory: %BUILD_DIR%
echo.

REM === Create build directory if not exists ===
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

copy /Y "%ELECTRON_SCRIPT_PATH%\electron_files\preload.js" "%BUILD_DIR%\" >nul
copy /y "%ELECTRON_SCRIPT_PATH%\electron_files\nssm.exe" "%BUILD_DIR%\" >nul



REM === Generate main.js from appropriate template ===
echo [INFO] Preparing main.js...

cd /d "%BUILD_DIR%"


if exist "%ELECTRON_SCRIPT_PATH%electron_files\main_b1Cockpit_template.js" (
    echo [INFO] Using main_b1cockpit.js as template.
    copy /Y "%ELECTRON_SCRIPT_PATH%electron_files\main_b1Cockpit_template.js" "main-template.js" >nul
    copy /Y "%ELECTRON_SCRIPT_PATH%electron_files\package-template.json" "package.json" >nul
) else (
    echo [ERROR] main_b1cockpit.js not found. Exiting...
    pause
    exit /b 1
)

REM == Copy the yo-pilot file to custom-nodes
xcopy /E /I /Y "%ELECTRON_SCRIPT_PATH%\utils\yo-pilot.utils" "%BUILD_DIR%\API\ENT_RED_CustomNodes\yo-pilot\yo-pilot.utils" >nul



CALL powershell -Command "(gc 'main-template.js')  | Out-File -encoding ASCII 'main.js'"

REM === Cleanup ===
del main-template.js >nul
cd /d "%~dp0"

echo.
echo [SUCCESS] main.js created successfully in build folder.
pause
endlocal
