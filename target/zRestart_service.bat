@echo off
setlocal enabledelayedexpansion

REM ==========================
REM Schedule: Daily @ 2:00 AM
REM ==========================

set "BASE_PATH=%cd%"
set "CONFIG_FILE=%BASE_PATH%\Config\config_flow.json"

REM === Get the service name from config_flow.json ===
FOR /F "tokens=*" %%i IN ('powershell -NoProfile -Command "(Get-Content '%CONFIG_FILE%' | ConvertFrom-Json).'node-red-service-name'"') DO SET "SERVICE_NAME=%%i"

if "%SERVICE_NAME%"=="" (
    echo [ERROR] Could not retrieve service name from config.
    exit /b 1
)

echo.
echo [INFO] Service to restart: %SERVICE_NAME%

REM === Stop the service ===
echo [INFO] Stopping service: %SERVICE_NAME%
:STOP_SERVICE
sc stop "%SERVICE_NAME%" >nul

REM Wait ~10 seconds
ping 127.0.0.1 -n 10 >nul

REM Check if service is stopped
sc query "%SERVICE_NAME%" | find /I "STATE" | find /I "STOPPED" >nul
if errorlevel 1 (
    echo [INFO] Waiting for service to stop...
    goto STOP_SERVICE
)

echo [INFO] Service stopped successfully.

REM === Start the service ===
ping 127.0.0.1 -n 5 >nul
echo [INFO] Starting service: %SERVICE_NAME%
net start "%SERVICE_NAME%"

if errorlevel 1 (
    echo [ERROR] Failed to start the service.
    exit /b 1
)

echo [SUCCESS] Service restarted successfully.

endlocal




@REM REM To be scheduled in Windows : Every Day @ 2:00 am

@REM REM Set COUNTER=0
@REM REM set CYCLES=2

@REM :stop
@REM sc stop ENT_eCommerce_portal_API-win32-x64-UI_API

@REM REM if %COUNTER% EQU %Cycles% taskkill /IM "ENT_eCommerce_portal_API.exe" /F

@REM REM set /A COUNTER+=1


@REM rem cause a ~10 second sleep before checking the service state
@REM ping 127.0.0.1 -n 10 -w 1000 > nul

@REM REM sc query ENT_eCommerce_portal_API-win32-x64-UI_API | find /I "STATE" | find "STOPPED"
@REM REM if errorlevel 1 goto :stop
@REM REM goto :start

@REM :start
@REM net start | find /i "ENT_eCommerce_portal_API-win32-x64-UI_API">nul && goto :start
@REM sc start ENT_eCommerce_portal_API-win32-x64-UI_API