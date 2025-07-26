@echo off
echo Installing Home Server on Windows 11 Home (Native)...
echo.
echo This will install everything on Windows without Linux/WSL2
echo.
pause

powershell -ExecutionPolicy Bypass -File "windows_native_setup.ps1"

echo.
echo Installation completed!
echo Press any key to exit...
pause >nul 