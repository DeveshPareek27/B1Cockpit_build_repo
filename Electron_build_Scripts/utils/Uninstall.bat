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





@REM @echo off
@REM SET BASE_PATH=%cd%
@REM SET DEFAULT_SERVICE_NAME=ENT_B1_Cockpit-win32-x64-UI_API
@REM FOR /F "tokens=*" %%i IN ('powershell -NoProfile -Command "(Get-Content '%BASE_PATH%\Config\config_flow.json' | ConvertFrom-Json).\"node-red-service-name\""') DO SET CURRENT_SERVICE_NAME=%%i

@REM IF "%CURRENT_SERVICE_NAME%"=="" (
@REM     SET NODE_RED_SERVICE_NAME=%DEFAULT_SERVICE_NAME%
@REM ) ELSE IF /I "%CURRENT_SERVICE_NAME%"=="null" (
@REM     SET NODE_RED_SERVICE_NAME=%DEFAULT_SERVICE_NAME%
@REM ) ELSE (
@REM     SET NODE_RED_SERVICE_NAME=%CURRENT_SERVICE_NAME%
@REM )

@REM @REM SET NODE_RED_SERVICE_NAME=ENT_B1_Cockpit-win32-x64-UI_API
@REM SET NODE_RED_SERVICE_DESCRIPTION=Entitec-%NODE_RED_SERVICE_NAME%
@REM SET NSSM_DIR=%BASE_PATH%\ENT_B1_Cockpit-win32-x64
@REM SET NODE_RED_DIR=%BASE_PATH%\ENT_B1_Cockpit-win32-x64
@REM REM !! SENZA SPAZI !!

@REM set /p choice=Are you sure you want to uninstall? (Y/N)
@REM if /i "%choice%"=="Y" (
@REM     REM %NSSM_DIR%\nssm stop %NODE_RED_SERVICE_NAME%
@REM     SC stop "%NODE_RED_SERVICE_NAME%"
@REM     timeout /t 2 >nul
@REM     REM %NSSM_DIR%\nssm remove %NODE_RED_SERVICE_NAME%
@REM     SC delete "%NODE_RED_SERVICE_NAME%"
@REM     timeout /t 2 >nul
@REM     rmdir /s /q "%BASE_PATH%\ENT_B1_Cockpit-win32-x64"

@REM     set /p choice2=Do you want to keep configuration the future use or delete it? (K/D)
@REM     if /i "%choice2%"=="K" (
@REM         echo Keeping the configuration for the future use...
@REM         timeout /t 2 >nul
@REM     ) else if /i "%choice2%"=="D" (
@REM         set /p confirm=Are you sure you want to delete the configuration? (Enter 1234 to confirm)
@REM         if "%confirm%"=="1234" (
@REM             echo Deleting configuration...
@REM             rmdir /s /q "%BASE_PATH%\Config"
@REM             echo Deleted!!
@REM         ) else (
@REM             REM echo Command cancelled.
@REM         )
@REM         del /f "%BASE_PATH%\Install.bat"
@REM 	    REM del /f "%BASE_PATH%\zRestart_service.bat"
@REM 		del /f "%BASE_PATH%\Reconfig.bat"
@REM 		del /f "%BASE_PATH%\Auto_Restart_Cockpit.bat"
@REM         del /f "%BASE_PATH%\Uninstall.bat"
@REM     ) else (
@REM         REM echo Invalid choice. Please enter K or D.
@REM     )
@REM ) else (
@REM     REM echo Cancelled.
@REM )