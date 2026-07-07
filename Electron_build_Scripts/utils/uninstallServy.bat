@echo off
setlocal

REM =====================================================
REM Base Path
REM =====================================================
SET "BASE_PATH=%~dp0"
SET "BASE_PATH=%BASE_PATH:~0,-1%"

SET "DEFAULT_SERVICE_NAME=ENT_B1_Cockpit-win32-x64-UI_API"

REM =====================================================
REM Read service name from config
REM =====================================================
FOR /F "tokens=*" %%i IN (
    'powershell -NoProfile -Command "(Get-Content ''%BASE_PATH%\Config\config_flow.json'' | ConvertFrom-Json).\"node-red-service-name\""'
) DO SET "CURRENT_SERVICE_NAME=%%i"

IF "%CURRENT_SERVICE_NAME%"=="" (
    SET "NODE_RED_SERVICE_NAME=%DEFAULT_SERVICE_NAME%"
) ELSE IF /I "%CURRENT_SERVICE_NAME%"=="null" (
    SET "NODE_RED_SERVICE_NAME=%DEFAULT_SERVICE_NAME%"
) ELSE (
    SET "NODE_RED_SERVICE_NAME=%CURRENT_SERVICE_NAME%"
)

REM =====================================================
REM Servy Configuration
REM =====================================================
SET "SERVY_DIR=%BASE_PATH%\ENT_B1_Cockpit-win32-x64\servy-8.4-net48-x64-portable"
SET "SERVY_CLI=%SERVY_DIR%\servy-cli.exe"

echo.
echo =====================================================
echo Service : %NODE_RED_SERVICE_NAME%
echo =====================================================
echo.

set /P choice=Are you sure you want to uninstall? (Y/N):

if /I not "%choice%"=="Y" (
    echo.
    echo Uninstall cancelled.
    goto :EOF
)

echo.
echo Checking if the service exists...

sc query "%NODE_RED_SERVICE_NAME%" >nul 2>&1

IF ERRORLEVEL 1 (
    echo.
    echo Service "%NODE_RED_SERVICE_NAME%" was not found.
    echo Nothing to uninstall.
    pause
    endlocal
    exit /b 0
) ELSE (

    echo.
    echo Stopping service...

    "%SERVY_CLI%" stop --name="%NODE_RED_SERVICE_NAME%"

    timeout /t 3 /nobreak >nul

    echo.
    echo Removing service...

    "%SERVY_CLI%" uninstall --name="%NODE_RED_SERVICE_NAME%"

    IF ERRORLEVEL 1 (
        echo.
        echo Failed to uninstall the service.
    ) ELSE (
        echo.
        echo Service removed successfully.
    )

    timeout /t 2 /nobreak >nul
)

echo.
echo Removing application files...

IF EXIST "%BASE_PATH%\ENT_B1_Cockpit-win32-x64" (
    rmdir /S /Q "%BASE_PATH%\ENT_B1_Cockpit-win32-x64"
    echo Application files removed.
) ELSE (
    echo Application folder not found.
)

echo.
set /P choice2=Do you want to keep the configuration for future use or delete it? (K/D):

IF /I "%choice2%"=="K" (

    echo Keeping configuration...

) ELSE IF /I "%choice2%"=="D" (

    echo.
    set /P confirm=Enter 1234 to permanently delete the configuration:

    IF "%confirm%"=="1234" (

        IF EXIST "%BASE_PATH%\Config" (
            rmdir /S /Q "%BASE_PATH%\Config"
            echo Configuration deleted.
        )

        del /F /Q "%BASE_PATH%\Install.bat" 2>nul
        del /F /Q "%BASE_PATH%\Reconfig.bat" 2>nul
        del /F /Q "%BASE_PATH%\Auto_Restart_Cockpit.bat" 2>nul
        del /F /Q "%BASE_PATH%\Uninstall.bat" 2>nul

    ) ELSE (
        echo Invalid confirmation. Configuration was not deleted.
    )

) ELSE (
    echo Invalid option. Keeping configuration.
)

echo.
echo Uninstall completed.
pause

endlocal
