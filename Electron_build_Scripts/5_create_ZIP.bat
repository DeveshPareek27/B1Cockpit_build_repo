@echo off
setlocal enabledelayedexpansion

REM === Load variables from config.env ===
for /f "tokens=1,* delims==" %%A in (0_0_Config.env) do (
    set %%A=%%B
)

REM BASE_PATH is current directory
SET BASE_PATH=%cd%
echo BASE_PATH is: %BASE_PATH%

REM Navigate to 7-Zip directory
cd %BASE_PATH%\utils\7-Zip

@REM set VERSION_FILE_PATH = %BASE_PATH%\..\%Build_Dir%\release-builds\%PROJECT%-win32-x64\projects\ENT_B1_Cockpit

for /f "delims=" %%v in ('powershell -Command "(Get-Content -Raw -Path '%UI5_PATH%/version.json' | ConvertFrom-Json).version"') do set VERSION=%%v
echo 🔖 Version: %VERSION%
REM Set version
set "version=%VERSION%"
@REM read form verison file
echo Version is: %version%

REM Use projectName from config file
7z a -sfx "%BASE_PATH%\%PROJECT%-Installer-%version%.exe" ^
   "%BASE_PATH%\..\%Build_Dir%\release-builds\%PROJECT%-win32-x64" ^
   "%BASE_PATH%\utils\Install.bat" ^
   "%BASE_PATH%\utils\Uninstall.bat" ^
   "%BASE_PATH%\utils\Auto_Restart_Cockpit.bat" ^
   "%BASE_PATH%\utils\Reconfig.bat"

REM Return to base path
cd %BASE_PATH%

endlocal
