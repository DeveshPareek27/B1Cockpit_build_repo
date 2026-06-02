@echo off
setlocal enabledelayedexpansion

REM === Load variables from config.env ===
for /f "tokens=1,* delims==" %%A in (0_0_Config.env) do (
    set %%A=%%B
)

REM === Set base and release directories ===
cd /d "%~dp0"
cd ..
set "BASE_DIR=%cd%"
set "RELEASE_DIR=%BASE_DIR%\%Build_Dir%\release-builds\ENT_B1_Cockpit-win32-x64"

echo 🔍 Searching for '%PROJECT%_*' folders in: %RELEASE_DIR%

REM === Create target webapp folder ===
mkdir "%RELEASE_DIR%\projects\ENT_B1_Cockpit\webapp"

REM === Copy the content from temp/dist to the webapp folder ===
set "SOURCE_PATH=%BASE_DIR%\temp\dist"
set "TARGET_PATH=%RELEASE_DIR%\projects\ENT_B1_Cockpit\webapp"

if exist "%SOURCE_PATH%" (
    echo 🚚 Copying from "%SOURCE_PATH%" to "%TARGET_PATH%"...
    xcopy "%SOURCE_PATH%\*" "%TARGET_PATH%\" /E /I /Y
    echo ✅ Files copied successfully.

    REM === Delete the temp folder after copy ===
    set "TEMP_FOLDER=%BASE_DIR%\temp"
    if exist "!TEMP_FOLDER!" (
        echo 🧹 Deleting temp folder: "!TEMP_FOLDER!"...
        rmdir /S /Q "!TEMP_FOLDER!"
        echo 🗑️ Temp folder deleted.
    ) else (
        echo ⚠️ Temp folder not found.
    )
) else (
    echo ❌ Source path "%SOURCE_PATH%" does not exist.
)

echo [INFO] Copying version JSON file to build directory...
xcopy  /y "%UI5_PATH%\version.json" "%RELEASE_DIR%\projects\ENT_B1_Cockpit\" >nul


echo ✅ Done.
endlocal
pause
