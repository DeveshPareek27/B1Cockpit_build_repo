@echo off
SET BASE_PATH=%cd%
SET DEFAULT_SERVICE_NAME=ENT_B1_Cockpit-win32-x64-UI_API
FOR /F "tokens=*" %%i IN ('powershell -NoProfile -Command "(Get-Content '%BASE_PATH%\Config\config_flow.json' | ConvertFrom-Json).\"node-red-service-name\""') DO SET CURRENT_SERVICE_NAME=%%i

IF "%CURRENT_SERVICE_NAME%"=="" (
    SET NODE_RED_SERVICE_NAME=%DEFAULT_SERVICE_NAME%
) ELSE IF /I "%CURRENT_SERVICE_NAME%"=="null" (
    SET NODE_RED_SERVICE_NAME=%DEFAULT_SERVICE_NAME%
) ELSE (
    SET NODE_RED_SERVICE_NAME=%CURRENT_SERVICE_NAME%
)

@REM SET NODE_RED_SERVICE_NAME=ENT_B1_Cockpit-win32-x64-UI_API
SET NODE_RED_SERVICE_DESCRIPTION=Entitec-%NODE_RED_SERVICE_NAME%
SET NSSM_DIR=%BASE_PATH%\ENT_B1_Cockpit-win32-x64
SET NODE_RED_DIR=%BASE_PATH%\ENT_B1_Cockpit-win32-x64
REM !! SENZA SPAZI !!

set /p choice=Are you sure you want to uninstall? (Y/N)
if /i "%choice%"=="Y" (
    REM %NSSM_DIR%\nssm stop %NODE_RED_SERVICE_NAME%
    SC stop "%NODE_RED_SERVICE_NAME%"
    timeout /t 2 >nul
    REM %NSSM_DIR%\nssm remove %NODE_RED_SERVICE_NAME%
    SC delete "%NODE_RED_SERVICE_NAME%"
    timeout /t 2 >nul
    rmdir /s /q "%BASE_PATH%\ENT_B1_Cockpit-win32-x64"
    
    set /p choice2=Do you want to keep configuration the future use or delete it? (K/D)
    if /i "%choice2%"=="K" (
        echo Keeping the configuration for the future use...
        timeout /t 2 >nul
    ) else if /i "%choice2%"=="D" (
        set /p confirm=Are you sure you want to delete the configuration? (Enter 1234 to confirm)
        if "%confirm%"=="1234" (
            echo Deleting configuration...
            rmdir /s /q "%BASE_PATH%\Config"
            echo Deleted!!
        ) else (
            REM echo Command cancelled.
        )
        del /f "%BASE_PATH%\Install.bat"
	    REM del /f "%BASE_PATH%\zRestart_service.bat"
		del /f "%BASE_PATH%\Reconfig.bat"
		del /f "%BASE_PATH%\Auto_Restart_Cockpit.bat"
        del /f "%BASE_PATH%\Uninstall.bat"
    ) else (
        REM echo Invalid choice. Please enter K or D.
    )
) else (
    REM echo Cancelled.
)