@echo off
setlocal enabledelayedexpansion

REM === Load variables from config.env ===
for /f "tokens=1,* delims==" %%A in (0_0_Config.env) do (
    set %%A=%%B
)

REM Step 1: Navigate to build/release-builds
cd /d "%~dp0\..\%Build_Dir%\release-builds"
echo [INFO] Current directory: %cd%

REM Step 2: Create Config folder
if not exist Config (
    mkdir Config
)

REM Step 3: Create base config_flow.json
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

REM Step 4: Inject appropriate port values using PowerShell

echo [INFO] Adding PORT for ENT_B1_Cockpit...
powershell -Command "$c = Get-Content 'Config\config_flow.json' -Raw | ConvertFrom-Json; $c | Add-Member -NotePropertyName port -NotePropertyValue '3000'; $c | ConvertTo-Json -Depth 10 | Set-Content 'Config\config_flow.json'"


REM Step 5: Create required subfolders
mkdir "Config\log_flows"



REM Step 7: Copy nssm.exe if it exists
if exist "..\nssm.exe" (
    echo [INFO] Copying nssm.exe...
    copy "..\nssm.exe" "%PROJECT%-win32-x64\nssm.exe" >nul
    echo [INFO] Copied: %cd%\Config\nssm.exe
) else (
    echo [WARN] nssm.exe not found in parent folder.
)

REM === Copy ENT_RED_CustomNodes ===
echo [INFO] Copying ENT_B1_Scripts to build folder...
xcopy /s /e /y "%API_PATH%\ENT_B1_Scripts\*" "%PROJECT%-win32-x64\projects\ENT_B1_Scripts\" >nul
echo "%BUILD_DIR%\%PROJECT%-win32-x64\projects\ENT_B1_Scripts\*"

xcopy "D:\Projects_BUILD\B1CockPit\B1_Cockpit_new\Electron_build_Scripts\electron_files\bin" "%BUILD_DIR%\%PROJECT%-win32-x64\bin" /E /I /Y >nul

REM Step 7: Copy entire Config folder to all *-win32-x64 folders
echo [INFO] Copying Config folder to all release builds...
for /d %%D in (*-win32-x64) do (
    xcopy /E /I /Y "Config" "%%D\Config" >nul
)

echo ✅ Configuration complete.
pause

