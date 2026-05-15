@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Auto Restart Script B1 Cockpit

set "BASE_PATH=%~dp0"
set "CONFIG_FILE=%BASE_PATH%Config\config_flow.json"

if not exist "%CONFIG_FILE%" (
    echo [ERROR] Config file not found.
    exit /b 1
)

for /f "usebackq delims=" %%S in (`
    powershell -NoProfile -Command ^
    "$c = Get-Content '%CONFIG_FILE%' | ConvertFrom-Json; $c.'node-red-service-name'"
`) do set "SERVICE_NAME=%%S"

if "%SERVICE_NAME%"=="" (
    echo [ERROR] Service name is empty.
    exit /b 1
)
if /i "%SERVICE_NAME%"=="null" (
    echo [ERROR] Service name is null in config.
    exit /b 1
)

sc query "%SERVICE_NAME%" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Service "%SERVICE_NAME%" not found on this machine.
    exit /b 1
)

REM --- Check parameter ---
if /i "%~1"=="scan"          goto :SCAN
if /i "%~1"=="force"         goto :FORCE_RESTART
if /i "%~1"=="delayed_start" goto :DELAYED_START
if "%~1"==""                 goto :FORCE_RESTART

REM --- Unknown parameter ---
echo [ERROR] Invalid parameter: %~1
exit /b 1

:FORCE_RESTART
sc query "%SERVICE_NAME%" | findstr /I "RUNNING" >nul
if not errorlevel 1 (
    powershell -NoProfile -WindowStyle Hidden -Command "Start-Process cmd -ArgumentList '/c ""!BASE_PATH!Auto_Restart_Cockpit.bat"" delayed_start' -WindowStyle Hidden"
    echo [INFO] Stopping service...
    sc stop "%SERVICE_NAME%"
    exit /b 0
) else (
    echo [INFO] Service not running. Starting directly...
    sc start "%SERVICE_NAME%"
    goto :VERIFY
)

:DELAYED_START
timeout /t 8 /nobreak >nul
echo [INFO] Starting service...
sc start "%SERVICE_NAME%"
exit /b 0

:SCAN
sc query "%SERVICE_NAME%" | findstr /I "RUNNING" >nul
if not errorlevel 1 (
    echo [INFO] Service already running. Nothing to do.
    exit /b 0
) else (
    echo [INFO] Service is stopped. Restarting...
    sc start "%SERVICE_NAME%"
    goto :VERIFY
)

:VERIFY
set "VWAIT=0"
:VERIFY_LOOP
sc query "%SERVICE_NAME%" | findstr /I "RUNNING" >nul
if not errorlevel 1 (
    echo [INFO] Service started successfully.
    exit /b 0
)
set /a VWAIT+=1
if !VWAIT! GEQ 30 (
    echo [ERROR] Service failed to start after 30 seconds.
    exit /b 1
)
timeout /t 1 /nobreak >nul
goto :VERIFY_LOOP