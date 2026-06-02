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
cd temp
set "BASE_PATH=%cd%"
SET BUILD_DATE=%date:~10,4%/%date:~4,2%/%date:~7,2% %time:~0,2%:%time:~3,2%

for /f "delims=" %%v in ('powershell -Command "(Get-Content -Raw -Path '%UI5_PATH%/version.json' | ConvertFrom-Json).version"') do set VERSION=%%v
echo 🔖 Version: %VERSION%
REM === Set and store version.json path in config.env ===
@REM set "APP_VERSION"=%VERSION%"
@REM echo APP_VERSION=!APP_VERSION!>>"%~dp0config.env"
@REM echo [INFO] version.json path saved to config.env


SET FILE_WITH_VERSION=%BASE_PATH%\webapp\view\Login.view.xml
SET FILE_WITH_VERSION2=%BASE_PATH%\webapp\fragments\UserInfo.fragment.xml

CALL powershell -Command "(gc %FILE_WITH_VERSION%) -replace 'Version 1.0.0', 'Version %VERSION%' | Out-File -encoding ASCII %FILE_WITH_VERSION%"
CALL powershell -Command "(gc %FILE_WITH_VERSION%) -replace '2021/03/31', '%BUILD_DATE%' | Out-File -encoding ASCII %FILE_WITH_VERSION%"

CALL powershell -Command "(gc %FILE_WITH_VERSION2%) -replace 'Version 1.0.0', 'Version %VERSION%' | Out-File -encoding ASCII %FILE_WITH_VERSION2%"
CALL powershell -Command "(gc %FILE_WITH_VERSION2%) -replace '2021/03/31', '%BUILD_DATE%' | Out-File -encoding ASCII %FILE_WITH_VERSION2%"

echo 🔧 Running npm run build...
npm run build
IF %ERRORLEVEL% NEQ 0 (
    echo ❌ npm run build failed. Aborting.
    pause
    exit /b %ERRORLEVEL%
)



echo ✅ Build complete and folder cleaned.

endlocal


