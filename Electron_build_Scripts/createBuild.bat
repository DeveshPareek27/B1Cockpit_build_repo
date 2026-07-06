@echo off
setlocal enabledelayedexpansion



REM ===================================================================
REM LOAD CONFIGURATION
REM ===================================================================
echo [STEP 0] Loading configuration from 0_0_Config.env...
for /f "usebackq tokens=1,* delims==" %%A in ("%~dp00_0_Config.env") do (
    set %%A=%%B
)
echo [INFO] Configuration loaded.
echo [DEBUG] PROJECT=%PROJECT%
echo [DEBUG] UI5_PATH=%UI5_PATH%
echo [DEBUG] API_PATH=%API_PATH%
echo.

REM ===================================================================
REM SET PATHS
REM ===================================================================
cd /d "%~dp0"
cd ..
set "BASE_DIR=%cd%"
set "BUILD_DIR=%BASE_DIR%\%Build_Dir%"
set "ELECTRON_SCRIPT_PATH=%~dp0"

REM Safety guard: abort if config failed to load (Build_Dir would be empty)
if "%Build_Dir%"=="" (
    echo [ERROR] Build_Dir is empty - config file failed to load. Aborting to prevent data loss.
    exit /b 1
)

echo [INFO] Base Directory: %BASE_DIR%
echo [INFO] Build Directory: %BUILD_DIR%
echo.

REM ===================================================================
REM SCRIPT 1: CLEAN BUILD DIRECTORY
REM ===================================================================
echo [STEP 1] Cleaning build directory...
if not exist "%BUILD_DIR%" (
    echo [WARN] Build directory "%BUILD_DIR%" not found. Skipping clean.
    goto :step2
)
cd /d "%BUILD_DIR%"
echo [INFO] Cleaning everything in build directory "%BUILD_DIR%"...
for /D %%D in (*) do (
    echo [INFO] Deleting folder: %%D
    rmdir /s /q "%%D" 2>nul
)
for %%F in (*) do (
    echo [INFO] Deleting file: %%F
    del /q "%%F" 2>nul
)
echo [INFO] Build directory cleaned.
echo.

:step2
REM ===================================================================
REM SCRIPT 2: CREATE BUILD STRUCTURE & COPY FILES
REM ===================================================================
echo [STEP 2] Creating build structure...

echo [INFO] UI5 Path: %UI5_PATH%
echo [INFO] API Path: %API_PATH%
echo [INFO] Build Directory: %BUILD_DIR%

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%BUILD_DIR%\API" mkdir "%BUILD_DIR%\API"

echo [INFO] Copying flow.json...
echo [DEBUG] UI5_PATH=%UI5_PATH%

set "FLOW_JSON_PATH=%UI5_PATH%\flow.json"

echo [DEBUG] FLOW_JSON_PATH=!FLOW_JSON_PATH!

if exist "!FLOW_JSON_PATH!" (
    echo [DEBUG] flow.json found
    copy /y "!FLOW_JSON_PATH!" "%BUILD_DIR%\flow.json" >nul
) else (
    echo [DEBUG] flow.json NOT found
    dir "%UI5_PATH%"
    exit /b 1
)

echo [INFO] Copying ENT_RED_CustomNodes to build\API...
xcopy /s /e /y "%API_PATH%\ENT_RED_CustomNodes\*" "%BUILD_DIR%\API\ENT_RED_CustomNodes\" >nul
echo [INFO] Build structure created.
echo.

REM ===================================================================
REM SCRIPT 3: COPY ELECTRON FILES & GENERATE MAIN.JS
REM ===================================================================
echo [STEP 3] Preparing Electron files...

echo [INFO] PROJECT: %PROJECT%
echo [INFO] APPLICATION_PORT: %APPLICATION_PORT%

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
copy /Y "%ELECTRON_SCRIPT_PATH%electron_files\preload.js" "%BUILD_DIR%\" >nul
copy /y "%ELECTRON_SCRIPT_PATH%electron_files\nssm.exe" "%BUILD_DIR%\" >nul

echo [INFO] Preparing main.js...
cd /d "%BUILD_DIR%"
if exist "%ELECTRON_SCRIPT_PATH%electron_files\main_b1Cockpit_template.js" (
    copy /Y "%ELECTRON_SCRIPT_PATH%electron_files\main_b1Cockpit_template.js" "main-template.js" >nul
    copy /Y "%ELECTRON_SCRIPT_PATH%electron_files\package-template.json" "package.json" >nul
) else (
    echo [ERROR] main_b1cockpit.js not found. Exiting...
    if not defined CI pause
    exit /b 1
)

xcopy /E /I /Y "%ELECTRON_SCRIPT_PATH%utils\yo-pilot.utils" "%BUILD_DIR%\API\ENT_RED_CustomNodes\yo-pilot\yo-pilot.utils" >nul
CALL powershell -Command "(gc 'main-template.js') | Out-File -encoding ASCII 'main.js'"
del main-template.js >nul
echo [INFO] Electron files prepared.
echo.

REM ===================================================================
REM SCRIPT 4: NPM INSTALL IN BUILD DIRECTORY
REM ===================================================================
echo [STEP 4] Running npm install in build directory...
cd /d "%BUILD_DIR%"
echo [INFO] Current directory: %cd%
call npm install
if %errorlevel% neq 0 (
    echo [ERROR] npm install failed.
    if not defined CI pause
    exit /b %errorlevel%
)
echo [INFO] npm install completed.
echo.

REM ===================================================================
REM SCRIPT 5: ELECTRON PACKAGER - CREATE EXE
REM ===================================================================
echo [STEP 5] Creating Electron EXE...
cd /d "%BUILD_DIR%"
echo [INFO] Current directory: %cd%

set "productName=%PROJECT%"
set "appVersion=1.0.0"

for /f "delims=" %%v in ('powershell -Command "(Get-Content -Raw -Path \"%UI5_PATH%\version.json\" | ConvertFrom-Json).version"') do (
    set "VERSION=%%v"
)
echo [INFO] Extracted version: !VERSION!

CALL powershell -Command "((Get-Content 'package.json') -replace '@version', '!VERSION!') | Set-Content -Encoding ASCII 'package.json'"

echo [INFO] Running electron-packager for product: %productName%
call npx electron-packager . "%productName%" --overwrite --asar --platform=win32 --arch=x64 --prune=true --out=release-builds --win32metadata.CompanyName='Entitec' --win32metadata.ProductName="%productName%" --version-string.CompanyName='Entitec' --version-string.FileDescription='B1_Cockpit' --version-string.FileVersion="!VERSION!" --version-string.ProductVersion="!VERSION!" --version-string.ProductName="%productName%"

if %errorlevel% neq 0 (
    echo [ERROR] EXE packaging failed with error code: %errorlevel%
    if not defined CI pause
    exit /b %errorlevel%
)
echo [INFO] EXE created successfully.
echo [INFO] Continuing to next step...
echo.

REM ===================================================================
REM SCRIPT 6: SETUP TEMP FOLDER FOR UI BUILD
REM ===================================================================
echo [STEP 6] Setting up temp folder for UI build...
cd /d "%BASE_DIR%"
if exist temp rmdir /s /q temp
mkdir temp

echo [INFO] Copying webapp folder...
xcopy /s /e /y "%UI5_PATH%\webapp\*" "temp\webapp\" >nul
if exist "%BASE_DIR%\target\package.json" (
    copy /Y "%BASE_DIR%\target\package.json" "temp\package.json" >nul
) else (
    copy /Y "%ELECTRON_SCRIPT_PATH%utils\package.json" "temp\package.json" >nul
)

if exist "%BASE_DIR%\target\ui5.yaml" (
    copy /Y "%BASE_DIR%\target\ui5.yaml" "temp\ui5.yaml" >nul
) else (
    copy /Y "%ELECTRON_SCRIPT_PATH%utils\ui5.yaml" "temp\ui5.yaml" >nul
)

if exist "%BASE_DIR%\target\moveToDist.js" (
    copy /Y "%BASE_DIR%\target\moveToDist.js" "temp\moveToDist.js" >nul
) else (
    copy /Y "%ELECTRON_SCRIPT_PATH%utils\moveToDist.js" "temp\moveToDist.js" >nul
)

cd temp
echo [INFO] Running npm install in temp directory...
call npm install
if %errorlevel% neq 0 (
    echo [ERROR] npm install failed.
    if not defined CI pause
    exit /b %errorlevel%
)
echo [INFO] Temp folder setup complete.
echo.

REM ===================================================================
REM SCRIPT 7: BUILD UI (NPM RUN BUILD)
REM ===================================================================
echo [STEP 7] Building UI...
cd /d "%BASE_DIR%\temp"
set "TEMP_PATH=%cd%"

SET BUILD_DATE=%date:~10,4%/%date:~4,2%/%date:~7,2% %time:~0,2%:%time:~3,2%
for /f "delims=" %%v in ('powershell -Command "(Get-Content -Raw -Path '%UI5_PATH%/version.json' | ConvertFrom-Json).version"') do set VERSION=%%v
echo [INFO] Version: %VERSION%

SET FILE_WITH_VERSION=%TEMP_PATH%\webapp\view\Login.view.xml
SET FILE_WITH_VERSION2=%TEMP_PATH%\webapp\fragments\UserInfo.fragment.xml
CALL powershell -Command "(gc '%FILE_WITH_VERSION%') -replace 'Version 1.0.0', 'Version %VERSION%' | Out-File -encoding ASCII '%FILE_WITH_VERSION%'"
CALL powershell -Command "(gc '%FILE_WITH_VERSION%') -replace '2021/03/31', '%BUILD_DATE%' | Out-File -encoding ASCII '%FILE_WITH_VERSION%'"
CALL powershell -Command "(gc '%FILE_WITH_VERSION2%') -replace 'Version 1.0.0', 'Version %VERSION%' | Out-File -encoding ASCII '%FILE_WITH_VERSION2%'"
CALL powershell -Command "(gc '%FILE_WITH_VERSION2%') -replace '2021/03/31', '%BUILD_DATE%' | Out-File -encoding ASCII '%FILE_WITH_VERSION2%'"

echo [INFO] Running npm run build...
call npm run build
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] npm run build failed. Aborting.
    if not defined CI pause
    exit /b %ERRORLEVEL%
)
echo [INFO] UI build complete.
echo.

REM ===================================================================
REM SCRIPT 8: COPY BUILT FILES & CLEANUP TEMP
REM ===================================================================
echo [STEP 8] Copying built files to release...
set "RELEASE_DIR=%BUILD_DIR%\release-builds\%PROJECT%-win32-x64"

mkdir "%RELEASE_DIR%\projects\ENT_B1_Cockpit\webapp" 2>nul

set "SOURCE_PATH=%BASE_DIR%\temp\dist"
set "TARGET_PATH=%RELEASE_DIR%\projects\ENT_B1_Cockpit\webapp"

if exist "%SOURCE_PATH%" (
    echo [INFO] Copying from "%SOURCE_PATH%" to "%TARGET_PATH%"...
    xcopy "%SOURCE_PATH%\*" "%TARGET_PATH%\" /E /I /Y
    echo [INFO] Files copied successfully.

    set "TEMP_FOLDER=%BASE_DIR%\temp"
    if exist "!TEMP_FOLDER!" (
        echo [INFO] Deleting temp folder...
        rmdir /S /Q "!TEMP_FOLDER!"
        echo [INFO] Temp folder deleted.
    )
) else (
    echo [ERROR] Source path "%SOURCE_PATH%" does not exist.
)

echo [INFO] Copying version.json...
xcopy /y "%UI5_PATH%\version.json" "%RELEASE_DIR%\projects\ENT_B1_Cockpit\" >nul
echo [INFO] Files copied and temp cleaned.
echo.

REM ===================================================================
REM SCRIPT 9: CREATE CONFIG FOLDER STRUCTURE
REM ===================================================================
echo [STEP 9] Creating configuration structure...
cd /d "%BUILD_DIR%\release-builds"

if not exist Config mkdir Config

(
    echo {
    echo     "description": "API ENVIRONMENT",
    echo     "b1-sl-config": {
    echo         "serviceLayerUrl": null,
    echo         "companyName": null,
    echo         "password": null,
    echo         "maxPageSize": null,
    echo         "logFilePath": null
    echo     },
    echo     "hana-db-connection": {
    echo         "server": null,
    echo         "port": null,
    echo         "database": null,
    echo         "userName": null,
    echo         "password": null,
    echo         "maxRecordSet": null,
    echo         "logFilePath": "",
    echo         "dedicated_config_override": true
    echo     }
    echo }
) > "Config\config_flow.json"

echo [INFO] Adding PORT configuration...
powershell -Command "$c = Get-Content 'Config\config_flow.json' -Raw | ConvertFrom-Json; $c | Add-Member -NotePropertyName port -NotePropertyValue '3000'; $c | ConvertTo-Json -Depth 10 | Set-Content 'Config\config_flow.json'"

mkdir "Config\log_flows" 2>nul

@REM if exist "%BUILD_DIR%\nssm.exe" (
@REM     echo [INFO] Copying nssm.exe...
@REM     copy "%BUILD_DIR%\nssm.exe" "%PROJECT%-win32-x64\nssm.exe" >nul
@REM )

if exist "%BUILD_DIR%\servy-8.4-net48-x64-portable\" (
    echo [INFO] Copying Servy...

    xcopy "%BUILD_DIR%\servy-8.4-net48-x64-portable" ^
          "%PROJECT%-win32-x64\servy-8.4-net48-x64-portable\" ^
          /E /I /Y >nul
)

echo [INFO] Copying ENT_B1_Scripts...
xcopy /s /e /y "%API_PATH%\ENT_B1_Scripts\*" "%PROJECT%-win32-x64\projects\ENT_B1_Scripts\" >nul
xcopy "%ELECTRON_SCRIPT_PATH%electron_files\bin" "%PROJECT%-win32-x64\bin" /E /I /Y >nul

echo [INFO] Copying Config folder to all release builds...
for /d %%D in (*-win32-x64) do (
    xcopy /E /I /Y "Config" "%%D\Config" >nul
)
echo [INFO] Configuration structure created.
echo.

REM ===================================================================
REM SCRIPT 10: CREATE INSTALLER WITH 7-ZIP
REM ===================================================================
echo [STEP 10] Creating installer...
cd /d "%ELECTRON_SCRIPT_PATH%utils\7-Zip"

for /f "delims=" %%v in ('powershell -Command "(Get-Content -Raw -Path '%UI5_PATH%/version.json' | ConvertFrom-Json).version"') do set VERSION=%%v
echo [INFO] Version: %VERSION%

set "version=%VERSION%"
echo [INFO] Creating installer: %PROJECT%-Installer-%version%.exe

7z a -sfx "%ELECTRON_SCRIPT_PATH%\%PROJECT%-Installer-%version%.exe" "%BUILD_DIR%\release-builds\%PROJECT%-win32-x64" "%ELECTRON_SCRIPT_PATH%utils\Install.bat" "%ELECTRON_SCRIPT_PATH%utils\Uninstall.bat" "%ELECTRON_SCRIPT_PATH%utils\Auto_Restart_Cockpit.bat" "%ELECTRON_SCRIPT_PATH%utils\Reconfig.bat"

cd /d "%ELECTRON_SCRIPT_PATH%"


REM ===================================================================
REM SCRIPT 11: Copy this installer file to B1cockpit build folder
REM ===================================================================
@REM xcopy /E /I /Y "%ELECTRON_SCRIPT_PATH%\%PROJECT%-Installer-%version%.exe" "D:\Projects_BUILD\B1CockPit\B1Cockpit_Builds" >nul

echo.
echo ========================================
echo [SUCCESS] BUILD COMPLETE!
echo ========================================
echo [INFO] Installer created: %PROJECT%-Installer-%version%.exe
echo [INFO] Location: %ELECTRON_SCRIPT_PATH%
echo ========================================
if not defined CI pause
endlocal