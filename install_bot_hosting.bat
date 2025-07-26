@echo off
echo Installing Telegram Bot Hosting on Windows...
echo.
echo This will set up a complete bot hosting environment
echo.
pause

powershell -ExecutionPolicy Bypass -File "bot_hosting_setup.ps1"

echo.
echo Bot hosting installation completed!
echo Press any key to exit...
pause >nul 