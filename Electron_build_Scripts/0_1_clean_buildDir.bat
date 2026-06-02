@echo off
setlocal enabledelayedexpansion

REM === Load variables from config.env ===
for /f "tokens=1,* delims==" %%A in (0_0_Config.env) do (
    set %%A=%%B
)

REM Navigate to script directory
cd /d "%~dp0"
cd ..

REM Check if Build_Dir exists
if not exist "%Build_Dir%" (
    echo ❌ ERROR: Build directory "%Build_Dir%" not found.
    pause
    exit /b 1
)

cd "%Build_Dir%"

echo 🧹 Cleaning everything in build directory "%Build_Dir%"...

REM Delete all folders
for /D %%D in (*) do (
    echo Deleting folder: %%D
    rmdir /s /q "%%D"
)

REM Delete all files
for %%F in (*) do (
    echo Deleting file: %%F
    del /q "%%F"
)

echo ✅ Build directory fully cleaned.
pause
endlocal
