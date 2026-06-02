@echo off
setlocal enabledelayedexpansion

REM === Load paths from config.env ===
for /f "tokens=1,* delims==" %%A in (0_0_Config.env) do (
    set %%A=%%B
)

REM === Define build directory (one level outside current dir) ===
cd /d "%~dp0"
cd ..
set BUILD_DIR=%cd%\%Build_Dir%

REM === Confirm loaded paths ===
echo [INFO] UI5 Path: %UI5_PATH%
echo [INFO] API Path: %API_PATH%
echo [INFO] Build Directory: %BUILD_DIR%
echo.

REM === Create build folder structure ===
echo [INFO] Creating build directory...
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
@REM if not exist "%BUILD_DIR%\UI" mkdir "%BUILD_DIR%\UI"
if not exist "%BUILD_DIR%\API" mkdir "%BUILD_DIR%\API"


echo [INFO] flow.json copy...
set "FLOW_JSON_PATH=%UI5_PATH%\flow.json"

if exist "!FLOW_JSON_PATH!" (
    echo [INFO] Copying user-provided flow.json...
    copy /y "!FLOW_JSON_PATH!" "%BUILD_DIR%\flow.json" >nul

    
) else (
    echo [ERROR] Provided flow.json path does not exist. Exiting...
    pause
    exit /b 1
)


REM === Copy ENT_RED_CustomNodes ===
echo [INFO] Copying ENT_RED_CustomNodes to build\API...
xcopy /s /e /y "%API_PATH%\ENT_RED_CustomNodes\*" "%BUILD_DIR%\API\ENT_RED_CustomNodes\" >nul
echo "%API_PATH%\ENT_RED_CustomNodes\*"



echo.
echo [SUCCESS] Build structure created at: %BUILD_DIR%
pause
endlocal
