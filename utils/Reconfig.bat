@echo off
setlocal enabledelayedexpansion

set "base_path=%cd%"

echo.
echo NOTE :- The service name cannot be changed once it has been created.
echo           - Run the Uninstall.bat file and select 'K' to keep the configuration.
echo           - Run the Install.bat file to create the service with the new name.
echo.

echo Choose an option:
echo    P - Change the port
echo    Q - Quit
set /p choice=Enter your choice (P/Q): 

REM Handle user input
if /i "!choice!"=="P" (
    set /p new_port=Enter the new port: 
    if "!new_port!"=="" (
        echo Port is not provided.
        exit /b 1
    )

    REM Check if new port is available
    powershell -NoProfile -Command ^
        "if (Get-NetTCPConnection -LocalPort !new_port! -ErrorAction SilentlyContinue) { Write-Host 'Port !new_port! is in use'; exit 1 } else { Write-Host 'Port !new_port! is available' }"
    
    if !ERRORLEVEL! NEQ 0 (
        echo.
        echo The provided port is already in use. Please choose a different port.
        exit /b 1
    )

    REM Read the current port from the config file
    for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "(Get-Content '%base_path%\Config\config_flow.json' | ConvertFrom-Json).port"`) do (
        set "CURRENT_PORT=%%i"
    )
    echo Current PORT: !CURRENT_PORT!

    REM Replace old port with new port in the config file
    echo Updating the port in config file...
    powershell -NoProfile -Command ^
        "$path = '%base_path%\Config\config_flow.json';" ^
        "$content = Get-Content $path;" ^
        "$updated = $content -replace '\"port\":\s*\d+', '\"port\": !new_port!';" ^
        "Set-Content -Path $path -Value $updated"

    REM Get the current service name from config
     FOR /F "tokens=*" %%i IN ('powershell -NoProfile -Command "(Get-Content '!base_path!\Config\config_flow.json' | ConvertFrom-Json).\"node-red-service-name\""') DO SET CURRENT_SERVICE_NAME=%%i
    echo Service Name: !CURRENT_SERVICE_NAME!

    REM Update service description and restart the service
    powershell -Command "sc.exe description '!CURRENT_SERVICE_NAME!' '!CURRENT_SERVICE_NAME!_PORT-!new_port!'"
    powershell -Command "Restart-Service -Name '!CURRENT_SERVICE_NAME!'"

    echo.
    echo Port updated to !new_port! in config and service restarted.

) else if /i "!choice!"=="Q" (
    exit /b 0
) else (
    echo Invalid choice. Please enter P or Q.
    exit /b 1
)
