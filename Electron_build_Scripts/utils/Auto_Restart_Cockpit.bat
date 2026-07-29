@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Auto Restart Script B1 Cockpit

set "BASE_PATH=%~dp0"
set "CONFIG_FILE=%BASE_PATH%Config\config_flow.json"
set "LOG_FILE=%BASE_PATH%Auto_Restart_Cockpit.log"

call :LOG "============================================================"
call :LOG "Auto Restart Script Started"

if not exist "%CONFIG_FILE%" (
    echo [ERROR] Config file not found.
    call :LOG "[ERROR] Config file not found: %CONFIG_FILE%"
    exit /b 1
)

call :LOG "[INFO] Reading configuration..."

REM ----------------------------
REM Read Service Name
REM ----------------------------
for /f "usebackq delims=" %%S in (`
powershell -NoProfile -Command "(Get-Content '%CONFIG_FILE%' | ConvertFrom-Json).'node-red-service-name'"
`) do (
    set "SERVICE_NAME=%%S"
)

REM ----------------------------
REM Read HTTP/HTTPS
REM ----------------------------
for /f "usebackq delims=" %%S in (`
powershell -NoProfile -Command "$c=Get-Content '%CONFIG_FILE%'|ConvertFrom-Json; if($c.https -eq $true){'https'}else{'http'}"
`) do (
    set "METHOD=%%S"
)

REM ----------------------------
REM Read Port
REM ----------------------------
for /f "usebackq delims=" %%S in (`
powershell -NoProfile -Command "(Get-Content '%CONFIG_FILE%' | ConvertFrom-Json).PORT"
`) do (
    set "PORT=%%S"
)

call :LOG "[INFO] Configuration loaded."
call :LOG "SERVICE_NAME=%SERVICE_NAME%"
call :LOG "METHOD=%METHOD%"
call :LOG "PORT=%PORT%"

if "%SERVICE_NAME%"=="" (
    echo [ERROR] Service name is empty.
    call :LOG "[ERROR] Service name is empty."
    exit /b 1
)

if /I "%SERVICE_NAME%"=="null" (
    echo [ERROR] Service name is null.
    call :LOG "[ERROR] Service name is null."
    exit /b 1
)

if "%PORT%"=="" (
    echo [ERROR] Port not found.
    call :LOG "[ERROR] Port not found."
    exit /b 1
)

sc query "%SERVICE_NAME%" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Service "%SERVICE_NAME%" not found.
    call :LOG "[ERROR] Service not found."
    exit /b 1
)

call :LOG "[INFO] Parameter = %~1"

if /I "%~1"=="scan"          goto :SCAN
if /I "%~1"=="force"         goto :FORCE_RESTART
if /I "%~1"=="delayed_start" goto :DELAYED_START
if "%~1"==""                 goto :FORCE_RESTART

echo [ERROR] Invalid parameter.
call :LOG "[ERROR] Invalid parameter: %~1"
exit /b 1

:FORCE_RESTART

call :LOG "[INFO] FORCE_RESTART"

sc query "%SERVICE_NAME%" | findstr /I "RUNNING" >nul

if not errorlevel 1 (

    call :LOG "[INFO] Service currently RUNNING."

    powershell -NoProfile -WindowStyle Hidden -Command ^
    "Start-Process cmd -ArgumentList '/c ""!BASE_PATH!Auto_Restart_Cockpit.bat"" delayed_start' -WindowStyle Hidden"

    call :LOG "[INFO] Sending STOP command."

    echo [INFO] Stopping service...
    sc stop "%SERVICE_NAME%"

    exit /b 0

) else (

    call :LOG "[INFO] Service already stopped."

    echo [INFO] Starting service...
    sc start "%SERVICE_NAME%"

    goto :VERIFY
)

:DELAYED_START

call :LOG "[INFO] Waiting 8 seconds."

timeout /t 8 /nobreak >nul

call :LOG "[INFO] Starting service."

echo [INFO] Starting service...
sc start "%SERVICE_NAME%"

exit /b 0

:SCAN

call :LOG "[INFO] SCAN mode."

sc query "%SERVICE_NAME%" | findstr /I "RUNNING" >nul

if errorlevel 1 (

    call :LOG "[INFO] Service STOPPED."

    echo [INFO] Service stopped. Starting...
    sc start "%SERVICE_NAME%"

    goto :VERIFY

)

call :LOG "[INFO] Service RUNNING."

echo [INFO] Checking application health...

call :CHECK_APP_HEALTH

if errorlevel 1 (

    call :LOG "[WARN] Health check FAILED."

    echo [WARN] Restarting service...

    goto :FORCE_RESTART

)

call :LOG "[INFO] Health check PASSED."

echo [INFO] Application healthy.

exit /b 0

:CHECK_APP_HEALTH

set "STATUS_FILE=%TEMP%\appstatus_%RANDOM%.txt"

call :LOG "[INFO] Calling %METHOD%://localhost:%PORT%/api/appStatusCheck"

curl -k -s -o nul -w "%%{http_code}" "%METHOD%://localhost:%PORT%/api/appStatusCheck" > "%STATUS_FILE%"

set "CURL_EXIT=%ERRORLEVEL%"

call :LOG "[INFO] Curl Exit=%CURL_EXIT%"

if not "%CURL_EXIT%"=="0" (

    call :LOG "[ERROR] Curl failed."

    if exist "%STATUS_FILE%" del "%STATUS_FILE%"

    exit /b 1

)

set "HTTP_STATUS="

set /p HTTP_STATUS=<"%STATUS_FILE%"

if exist "%STATUS_FILE%" del "%STATUS_FILE%"

call :LOG "[INFO] HTTP Status=%HTTP_STATUS%"

if "%HTTP_STATUS%"=="200" (

    call :LOG "[INFO] Application healthy."

    exit /b 0

)

call :LOG "[WARN] Application unhealthy."

exit /b 1

:VERIFY

call :LOG "[INFO] Verifying startup."

set "VWAIT=0"

:VERIFY_LOOP

sc query "%SERVICE_NAME%" | findstr /I "RUNNING" >nul

if not errorlevel 1 (

    call :LOG "[INFO] Service started."

    echo [INFO] Service started successfully.

    exit /b 0

)

set /a VWAIT+=1

call :LOG "[INFO] Verify attempt !VWAIT!/30"

if !VWAIT! GEQ 30 (

    call :LOG "[ERROR] Startup timeout."

    echo [ERROR] Service failed to start.

    exit /b 1

)

timeout /t 1 /nobreak >nul

goto :VERIFY_LOOP

:LOG
echo [%date% %time%] %~1>>"%LOG_FILE%"
exit /b





@REM @echo off
@REM setlocal EnableExtensions EnableDelayedExpansion

@REM REM Auto Restart Script B1 Cockpit

@REM set "BASE_PATH=%~dp0"
@REM set "CONFIG_FILE=%BASE_PATH%Config\config_flow.json"

@REM if not exist "%CONFIG_FILE%" (
@REM     echo [ERROR] Config file not found.
@REM     exit /b 1
@REM )

@REM for /f "usebackq tokens=1,2,3 delims=|" %%A in (`
@REM powershell -NoProfile -Command ^
@REM "$c = Get-Content '%CONFIG_FILE%' | ConvertFrom-Json; ^
@REM $protocol = if($c.https -eq $true){'https'}else{'http'}; ^
@REM Write-Output ($c.'node-red-service-name' + '|' + $protocol + '|' + $c.port)"
@REM `) do (
@REM     set "SERVICE_NAME=%%A"
@REM     set "METHOD=%%B"
@REM     set "PORT=%%C"
@REM )

@REM @REM for /f "usebackq delims=" %%S in (`
@REM @REM     powershell -NoProfile -Command ^
@REM @REM     "$c = Get-Content '%CONFIG_FILE%' | ConvertFrom-Json; $c.'node-red-service-name'"
@REM @REM `) do set "SERVICE_NAME=%%S"

@REM if "%SERVICE_NAME%"=="" (
@REM     echo [ERROR] Service name is empty.
@REM     exit /b 1
@REM )
@REM if /i "%SERVICE_NAME%"=="null" (
@REM     echo [ERROR] Service name is null in config.
@REM     exit /b 1
@REM )

@REM sc query "%SERVICE_NAME%" >nul 2>&1
@REM if errorlevel 1 (
@REM     echo [ERROR] Service "%SERVICE_NAME%" not found on this machine.
@REM     exit /b 1
@REM )

@REM REM --- Check parameter ---
@REM if /i "%~1"=="scan"          goto :SCAN
@REM if /i "%~1"=="force"         goto :FORCE_RESTART
@REM if /i "%~1"=="delayed_start" goto :DELAYED_START
@REM if "%~1"==""                 goto :FORCE_RESTART

@REM REM --- Unknown parameter ---
@REM echo [ERROR] Invalid parameter: %~1
@REM exit /b 1

@REM :FORCE_RESTART
@REM sc query "%SERVICE_NAME%" | findstr /I "RUNNING" >nul
@REM if not errorlevel 1 (
@REM     powershell -NoProfile -WindowStyle Hidden -Command "Start-Process cmd -ArgumentList '/c ""!BASE_PATH!Auto_Restart_Cockpit.bat"" delayed_start' -WindowStyle Hidden"
@REM     echo [INFO] Stopping service...
@REM     sc stop "%SERVICE_NAME%"
@REM     exit /b 0
@REM ) else (
@REM     echo [INFO] Service not running. Starting directly...
@REM     sc start "%SERVICE_NAME%"
@REM     goto :VERIFY
@REM )

@REM :DELAYED_START
@REM timeout /t 8 /nobreak >nul
@REM echo [INFO] Starting service...
@REM sc start "%SERVICE_NAME%"
@REM exit /b 0

@REM :SCAN
@REM sc query "%SERVICE_NAME%" | findstr /I "RUNNING" >nul
@REM if not errorlevel 1 (
@REM     @REM echo [INFO] Service already running. Nothing to do.
@REM     echo [INFO] Service is running. Checking application health...

@REM     call :CHECK_APP_HEALTH

@REM     if errorlevel 1 (
@REM         echo [WARN] Application health check failed. Restarting service...
@REM         goto :FORCE_RESTART
@REM     )

@REM     echo [INFO] Application health check passed.
@REM     exit /b 0
@REM ) else (
@REM     echo [INFO] Service is stopped. Restarting...
@REM     sc start "%SERVICE_NAME%"
@REM     goto :VERIFY
@REM )

@REM :CHECK_APP_HEALTH
@REM set "STATUS_FILE=%TEMP%\app_status_%RANDOM%.txt"

@REM curl -k -s -o nul -w "%%{http_code}" "%METHOD%://localhost:%PORT%/api/appStatusCheck" > "%STATUS_FILE%"

@REM if errorlevel 1 (
@REM     if exist "%STATUS_FILE%" del "%STATUS_FILE%" >nul 2>&1
@REM     exit /b 1
@REM )

@REM set "HTTP_STATUS="
@REM set /p HTTP_STATUS=<"%STATUS_FILE%"
@REM del "%STATUS_FILE%" >nul 2>&1

@REM if "%HTTP_STATUS%"=="200" (
@REM     exit /b 0
@REM )

@REM exit /b 1

@REM :VERIFY
@REM set "VWAIT=0"
@REM :VERIFY_LOOP
@REM sc query "%SERVICE_NAME%" | findstr /I "RUNNING" >nul
@REM if not errorlevel 1 (
@REM     echo [INFO] Service started successfully.
@REM     exit /b 0
@REM )
@REM set /a VWAIT+=1
@REM if !VWAIT! GEQ 30 (
@REM     echo [ERROR] Service failed to start after 30 seconds.
@REM     exit /b 1
@REM )
@REM timeout /t 1 /nobreak >nul
@REM goto :VERIFY_LOOP