@echo off
setlocal enabledelayedexpansion

SET BASE_PATH=%cd%
SET DEFAULT_PORT=3000
SET DEFAULT_SERVICE_NAME=ENT_B1_Cockpit-win32-x64-UI_API

REM Create the config directory if it doesn't exist
@REM mkdir Config 2>nul
@REM if not exist "%BASE_PATH%\Config\config_flow.json" (
@REM     copy "%BASE_PATH%\ENT_B1_Cockpit-win32-x64\config_flow-template.json" "%BASE_PATH%\Config\config_flow.json"
@REM )

REM Read current values from config_flow.json
rem FOR /F "tokens=*" %%i IN ('powershell -NoProfile -Command "(Get-Content \"%BASE_PATH%\Config\config_flow.json\" | ConvertFrom-Json).'node-red-service-name'"') DO SET CURRENT_SERVICE_NAME=%%i
rem FOR /F "tokens=*" %%i IN ('powershell -NoProfile -Command "(Get-Content \"%BASE_PATH%\Config\config_flow.json\" | ConvertFrom-Json).port"') DO SET CURRENT_PORT=%%i
REM === Copy entire folder ===
REM Check if the target Config folder exists
if not exist "!BASE_PATH!\Config" (
    echo [INFO] Target folder not found. Copying...
    xcopy "!BASE_PATH!\ENT_B1_Cockpit-win32-x64\Config" "!BASE_PATH!\Config" /E /I /Y
    echo [INFO] ✅ Config folder copied to "!BASE_PATH!\Config"
) else (
    echo [INFO] ✅ Target folder already exists. Skipping copy.
)

FOR /F "tokens=*" %%i IN ('powershell -NoProfile -Command "$config = Get-Content \"%BASE_PATH%\Config\config_flow.json\" | ConvertFrom-Json; if ($config.PSObject.Properties.Name -contains \"node-red-service-name\") { $config.\"node-red-service-name\" } else { \"\" }"') DO SET CURRENT_SERVICE_NAME=%%i

FOR /F "tokens=*" %%i IN ('powershell -NoProfile -Command "$config = Get-Content \"%BASE_PATH%\Config\config_flow.json\" | ConvertFrom-Json; if ($config.PSObject.Properties.Name -contains \"port\") { $config.port } else { \"\" }"') DO SET CURRENT_PORT=%%i


REM Handle null or empty current service name
IF "%CURRENT_SERVICE_NAME%"=="" (
    SET CURRENT_SERVICE_NAME_VALID=0
) ELSE IF /I "%CURRENT_SERVICE_NAME%"=="null" (
    SET CURRENT_SERVICE_NAME_VALID=0
) ELSE IF "%CURRENT_SERVICE_NAME%"=="%DEFAULT_SERVICE_NAME%" (
    SET CURRENT_SERVICE_NAME_VALID=0
) ELSE (
    SET CURRENT_SERVICE_NAME_VALID=1
)

REM Handle null or empty current port
IF "%CURRENT_PORT%"=="" (
    SET CURRENT_PORT_VALID=0
) ELSE IF /I "%CURRENT_PORT%"=="null" (
    SET CURRENT_PORT_VALID=0
) ELSE IF "%CURRENT_PORT%"=="%DEFAULT_PORT%" (
	SET CURRENT_PORT_VALID=0
)ELSE (
    SET CURRENT_PORT_VALID=1
)

:CHOOSE_SERVICE_NAME
echo.
echo Choose an option for service name:
echo 	D - Use default: %DEFAULT_SERVICE_NAME%
SET SERVICE_CHOICE_TEXT=D

IF %CURRENT_SERVICE_NAME_VALID%==1 (
    echo 	L - Use last configured: %CURRENT_SERVICE_NAME%
    SET SERVICE_CHOICE_TEXT=!SERVICE_CHOICE_TEXT!/L
)
echo 	N - Enter a new service name
SET SERVICE_CHOICE_TEXT=!SERVICE_CHOICE_TEXT!/N

set /P SERVICE_CHOICE="Enter your choice (!SERVICE_CHOICE_TEXT!): "


IF /I "%SERVICE_CHOICE%"=="D" (
    SET NODE_RED_SERVICE_NAME=%DEFAULT_SERVICE_NAME%
) ELSE IF /I "%SERVICE_CHOICE%"=="L" (
    IF %CURRENT_SERVICE_NAME_VALID%==1 (
        SET NODE_RED_SERVICE_NAME=%CURRENT_SERVICE_NAME%
    ) ELSE (
        echo.
        echo No valid last configured service name found.
        goto CHOOSE_SERVICE_NAME
    )
) ELSE IF /I "%SERVICE_CHOICE%"=="N" (
    SET /P NODE_RED_SERVICE_NAME="Enter new service name: "
) ELSE (
    echo.
    echo Invalid choice. Please try again.
    goto CHOOSE_SERVICE_NAME
)

REM Check if service name already exists
powershell -NoProfile -Command "if (Get-Service -Name '%NODE_RED_SERVICE_NAME%' -ErrorAction SilentlyContinue) { exit 1 }"
IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo A service with the same name already exists. Please enter a unique name.
    goto CHOOSE_SERVICE_NAME
)

:CHOOSE_PORT
echo.
echo Choose an option for port:
echo 	D - Use default: %DEFAULT_PORT%
SET PORT_CHOICE_TEXT=D

IF %CURRENT_PORT_VALID%==1 (
    echo 	L - Use last configured: %CURRENT_PORT%
    SET PORT_CHOICE_TEXT=!PORT_CHOICE_TEXT!/L
)
echo 	N - Enter a new port
SET PORT_CHOICE_TEXT=!PORT_CHOICE_TEXT!/N

set /P PORT_CHOICE="Enter your choice (!PORT_CHOICE_TEXT!): "


IF /I "%PORT_CHOICE%"=="D" (
    SET NODE_RED_PORT=%DEFAULT_PORT%
) ELSE IF /I "%PORT_CHOICE%"=="L" (
    IF %CURRENT_PORT_VALID%==1 (
        SET NODE_RED_PORT=%CURRENT_PORT%
    ) ELSE (
        echo.
        echo No valid last configured port found.
        goto CHOOSE_PORT
    )
) ELSE IF /I "%PORT_CHOICE%"=="N" (
    SET /P NODE_RED_PORT="Enter new port: "
) ELSE (
    echo.
    echo Invalid choice. Please try again.
    goto CHOOSE_PORT
)

REM Check if port is in use
powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort %NODE_RED_PORT% -ErrorAction SilentlyContinue) { exit 1 }"
IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo The provided port is already in use. Please choose a different port.
    goto CHOOSE_PORT
)

SET NODE_RED_SERVICE_DESCRIPTION=Entitec-%NODE_RED_SERVICE_NAME%-PORT-%NODE_RED_PORT%
SET NSSM_DIR=%BASE_PATH%\ENT_B1_Cockpit-win32-x64
SET NODE_RED_DIR=%BASE_PATH%\ENT_B1_Cockpit-win32-x64

REM Update config_flow.json with new values
rem powershell -NoProfile -Command "$config = Get-Content '%BASE_PATH%\Config\config_flow.json' | ConvertFrom-Json; $config.'node-red-service-name' = '%NODE_RED_SERVICE_NAME%'; $config.port = %NODE_RED_PORT%; $config | ConvertTo-Json -Depth 5 | Set-Content '%BASE_PATH%\Config\config_flow.json'"
powershell -NoProfile -Command "$config = Get-Content '%BASE_PATH%\Config\config_flow.json' | ConvertFrom-Json; if (-not ($config.PSObject.Properties.Name -contains 'node-red-service-name')) { $config | Add-Member -NotePropertyName 'node-red-service-name' -NotePropertyValue '' }; if (-not ($config.PSObject.Properties.Name -contains 'port')) { $config | Add-Member -NotePropertyName 'port' -NotePropertyValue 0 }; $config.'node-red-service-name' = '%NODE_RED_SERVICE_NAME%'; $config.port = %NODE_RED_PORT%; $config | ConvertTo-Json -Depth 5 | Set-Content '%BASE_PATH%\Config\config_flow.json'"


SET NODE_RED_SERVICE_LOG=%NODE_RED_DIR%\node_red_service_console.txt
SET NODE_RED_LAUNCHER=%NODE_RED_DIR%\ENT_B1_Cockpit.exe

"%NSSM_DIR%\nssm" install "%NODE_RED_SERVICE_NAME%" "%NODE_RED_LAUNCHER%"
"%NSSM_DIR%\nssm" set "%NODE_RED_SERVICE_NAME%" AppDirectory "%NODE_RED_DIR%"
"%NSSM_DIR%\nssm" set "%NODE_RED_SERVICE_NAME%" AppParameters " > \"%NODE_RED_SERVICE_LOG%\""
"%NSSM_DIR%\nssm" set "%NODE_RED_SERVICE_NAME%" Description "%NODE_RED_SERVICE_DESCRIPTION%"

timeout /t 5 /nobreak >nul
"%NSSM_DIR%\nssm" start "%NODE_RED_SERVICE_NAME%"

endlocal
