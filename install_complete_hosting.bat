@echo off
echo ========================================
echo Complete Home Server + Bot Hosting Setup
echo ========================================
echo.
echo This will install:
echo - Web Server (Flask)
echo - Telegram Bot Hosting
echo - Management Scripts
echo - Auto-startup
echo.
pause

echo.
echo Step 1: Installing Web Server...
powershell -ExecutionPolicy Bypass -File "windows_native_setup.ps1"

echo.
echo Step 2: Installing Telegram Bot Hosting...
powershell -ExecutionPolicy Bypass -File "bot_hosting_setup.ps1"

echo.
echo ========================================
echo Installation Completed Successfully!
echo ========================================
echo.
echo What was installed:
echo.
echo Web Server (C:\server\):
echo - start_server.bat
echo - stop_server.bat
echo - status_server.bat
echo.
echo Telegram Bot (C:\bot\):
echo - start_bot.bat
echo - stop_bot.bat
echo - bot_launcher.bat (auto-restart)
echo - install_bot_service.bat
echo.
echo Combined Launcher:
echo - C:\server\start_all.bat (starts both)
echo.
echo Quick Start:
echo 1. C:\server\start_all.bat - Start everything
echo 2. http://localhost:5000 - Web interface
echo 3. Check bot in Telegram
echo.
echo Press any key to exit...
pause >nul 