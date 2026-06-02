@echo off
setlocal enabledelayedexpansion

REM === Load variables from config.env ===
for /f "tokens=1,* delims==" %%A in (0_0_Config.env) do (
    set %%A=%%B
)

REM Navigate to the build directory
cd /d "%~dp0\..\%Build_Dir%"

echo Running npm install in %Build_Dir% directory...
call npm install

if %errorlevel% neq 0 (
    echo ❌ npm install failed.
    pause
    exit /b %errorlevel%
)

echo ✅ npm install completed successfully.

