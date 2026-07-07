@echo off
setlocal enabledelayedexpansion

SET BASE_PATH=%cd%
SET DEFAULT_PORT=3000
SET DEFAULT_SERVICE_NAME=ENT_B1_Cockpit-win32-x64-UI_API


SET SOURCE_CONFIG_DIR=%BASE_PATH%\ENT_B1_Cockpit-win32-x64\Config
SET TARGET_CONFIG_DIR=%BASE_PATH%\Config

if not exist "%TARGET_CONFIG_DIR%" (
    echo [INFO] Target Config folder not found. Creating...
    xcopy "%SOURCE_CONFIG_DIR%" "%TARGET_CONFIG_DIR%" /E /I /Y >nul
    echo [INFO] Config folder created successfully.
) else (
    echo [INFO] Config folder already exists. Checking individual files...
    for %%F in ("%SOURCE_CONFIG_DIR%\*") do (
        set "SRC_FILE=%%~fF"
        set "DEST_FILE=%TARGET_CONFIG_DIR%\%%~nxF"

        if not exist "!DEST_FILE!" (
            echo [INFO] File "%%~nxF" missing, fetching...
            copy /Y "!SRC_FILE!" "!DEST_FILE!" >nul
            echo [INFO] Fetched missing file: %%~nxF
        ) else (
            echo [WARN] File "%%~nxF" already exists.
            choice /C YN /M "Do you want to overwrite %%~nxF?"
            if errorlevel 2 (
                REM echo [WARN] You chose not to overwrite %%~nxF.
                echo [WARN] Skipping this file may cause unexpected issues.
                echo [WARN] Proceeding without overwriting is solely your responsibility.
                choice /C YN /M "Do you still want to skip overwriting %%~nxF?"
                if errorlevel 2 (
                    echo [INFO] Overwriting %%~nxF anyway for consistency...
                    copy /Y "!SRC_FILE!" "!DEST_FILE!" >nul
                    echo [INFO] Overwritten file: %%~nxF
                ) else (
                    echo [INFO] Proceeding without overwriting %%~nxF...
                )
            ) else (
                echo [INFO] Overwriting %%~nxF...
                copy /Y "!SRC_FILE!" "!DEST_FILE!" >nul
                echo [INFO] Overwritten file: %%~nxF
            )
        )
    )
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


@REM servy service install configuration

REM =====================================================
REM Servy Configuration
REM =====================================================

SET SERVY_DIR=%BASE_PATH%\ENT_B1_Cockpit-win32-x64\servy-8.4-net48-x64-portable
SET SERVY_CLI=%SERVY_DIR%\servy-cli.exe
SET NODE_RED_DIR=%BASE_PATH%\ENT_B1_Cockpit-win32-x64
SET NODE_RED_SERVICE_DESCRIPTION=Entitec-%NODE_RED_SERVICE_NAME%-PORT-%NODE_RED_PORT%
SET NODE_RED_LAUNCHER=%NODE_RED_DIR%\ENT_B1_Cockpit.exe




IF NOT EXIST "%NODE_RED_DIR%\log_flows" (
    mkdir "%NODE_RED_DIR%\log_flows"
)

echo.
echo Installing Windows Service...

"%SERVY_CLI%" install ^
    --name="%NODE_RED_SERVICE_NAME%" ^
    --displayName="%NODE_RED_SERVICE_NAME%" ^
    --description="%NODE_RED_SERVICE_DESCRIPTION%" ^
    --path="%NODE_RED_LAUNCHER%" ^
    --startupDir="%NODE_RED_DIR%" ^
    --startupType="Automatic"

IF ERRORLEVEL 1 (
    echo.
    echo Failed to install the Windows Service.
    pause
    exit /b 1
)

echo.
echo Starting Windows Service...

"%SERVY_CLI%" start --name="%NODE_RED_SERVICE_NAME%"

IF ERRORLEVEL 1 (
    echo.
    echo Failed to start the Windows Service.
    pause
    exit /b 1
)

echo.
echo Service installed and started successfully.

endlocal
