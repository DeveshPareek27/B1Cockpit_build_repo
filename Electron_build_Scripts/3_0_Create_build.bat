@echo off
setlocal enabledelayedexpansion

REM === Load paths from config.env ===
for /f "tokens=1,* delims==" %%A in (0_0_Config.env) do (
    set %%A=%%B
)

REM Ask user for the product name
set "productName=%PROJECT%"

REM Set a default version number (can be pulled from package.json if needed)
set "appVersion=1.0.0"

REM Navigate to build directory
cd /d "%~dp0\..\%Build_Dir%"
echo Current directory: %cd%



REM Set the Version variable
for /f "delims=" %%v in ('powershell -Command "(Get-Content -Raw -Path \"%UI5_PATH%\version.json\" | ConvertFrom-Json).version"') do (
    set "VERSION=%%v"
)
echo Extracted version: !VERSION!

Rem updating the verison string in the package json 
cd /d "%~dp0\..\%Build_Dir%"
CALL powershell -Command "((Get-Content 'package.json') -replace '@version', '%VERSION%') | Set-Content -Encoding ASCII 'package.json'"


REM Run electron-packager with the user input via npx
echo Running electron-packager for product: %productName%
npx electron-packager . "%productName%" ^
  --overwrite --asar --platform=win32 --arch=x64 --prune=true ^
  --out=release-builds ^
  --win32metadata.CompanyName='Entitec'  ^
  --win32metadata.ProductName="%productName%" ^
  --version-string.CompanyName='Entitec' ^
  --version-string.FileDescription='B1_Cockpit' ^
  --version-string.FileVersion="%VERSION%" ^
  --version-string.ProductVersion="%VERSION%" ^
  --version-string.ProductName="%productName%"  

if %errorlevel% neq 0 (
    echo ❌ EXE packaging failed.
    pause
    exit /b %errorlevel%
)

echo ✅ EXE successfully created for "%productName%".
pause







@REM @echo off
@REM setlocal

@REM REM Ask user for the product name
@REM set /p productName=Enter Product Name (e.g., Ecommerce-app): 

@REM REM Navigate to build directory
@REM cd /d "%~dp0\..\build"
@REM echo Current directory: %cd%

@REM REM Run electron-packager with the user input via npx
@REM echo Running electron-packager for product: %productName%
@REM npx electron-packager . "%productName%" --overwrite --asar --platform=win32 --arch=x64 --prune=true --out=release-builds --version-string.CompanyName=CE --version-string.FileDescription=CE --version-string.ProductName="%productName%"

@REM if %errorlevel% neq 0 (
@REM     echo ❌ EXE packaging failed.
@REM     pause
@REM     exit /b %errorlevel%
@REM )

@REM echo ✅ EXE successfully created for "%productName%".
@REM pause
