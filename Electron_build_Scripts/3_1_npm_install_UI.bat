@echo off
setlocal enabledelayedexpansion

REM === Load variables from config.env ===
for /f "tokens=1,* delims==" %%A in (0_0_Config.env) do (
    set %%A=%%B
)

REM Navigate to UI folder inside build
cd /d "%~dp0"
cd ..
@REM cd %Build_Dir%
@REM cd ..
mkdir temp

REM === Copy webapp folder from UI5_PATH ===
echo [INFO] Copying webapp folder from UI5_PATH...
xcopy /s /e /y "%UI5_PATH%\webapp\*" "temp\webapp\" >nul


echo [INFO] Copying package.json...
copy /Y "%~dp0utils\package.json" "temp\package.json" >nul

echo [INFO] Copying ui5.yaml...
copy /Y "%~dp0utils\ui5.yaml" "temp\ui5.yaml" >nul

echo [INFO] Copying moveToDist.js...
copy /Y "%~dp0utils\moveToDist.js" "temp\moveToDist.js" >nul

cd temp
echo Running npm install in %Build_Dir% directory...
call npm install

if %errorlevel% neq 0 (
    echo ❌ npm install failed.
    pause
    exit /b %errorlevel%
)

echo ✅ npm install completed successfully.

