@echo off
setlocal enabledelayedexpansion
SET BASE_PATH=%cd%

REM === Load variables from config.env ===
for /f "tokens=1,* delims==" %%A in (0_0_Config.env) do (
    set %%A=%%B
)

for /f "delims=" %%v in ('powershell -Command "(Get-Content -Raw -Path '%UI5_PATH%/version.json' | ConvertFrom-Json).version"') do set VERSION=%%v
echo 🔖 Version: %VERSION%

@REM not usefull
@REM for /f "delims=" %%v in ('powershell -Command "(Get-Content -Raw -Path '%BASE_PATH%/b_BUILD/package.json' | ConvertFrom-Json).version"') do set version=%%v

copy %BASE_PATH%\ENT_B1_Cockpit-Installer-%VERSION%.exe %COPY_DEST_PATH% /Y

cd %BASE_PATH%