# Telegram Bot Hosting Setup for Windows
# Настройка хостинга Telegram бота на Windows

Write-Host "Setting up Telegram Bot Hosting on Windows..." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan

# Create bot directory
$BotDir = "C:\bot"
if (!(Test-Path $BotDir)) {
    New-Item -ItemType Directory -Path $BotDir -Force
    Write-Host "Created bot directory: $BotDir" -ForegroundColor Green
}

# Copy bot files
Write-Host "Copying bot files..." -ForegroundColor Yellow
Copy-Item -Path ".\bot.py" -Destination "$BotDir\bot.py" -Force
Copy-Item -Path ".\requirements.txt" -Destination "$BotDir\requirements.txt" -Force
Copy-Item -Path ".\users.db" -Destination "$BotDir\users.db" -Force -ErrorAction SilentlyContinue
Write-Host "Bot files copied to $BotDir" -ForegroundColor Green

# Create Python virtual environment for bot
Write-Host "Setting up Python environment for bot..." -ForegroundColor Yellow
$BotVenvPath = "$BotDir\venv"

# Check if Python is installed
if (!(Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Python not found. Installing Python 3.11..." -ForegroundColor Yellow
    
    # Download Python installer
    $PythonUrl = "https://www.python.org/ftp/python/3.11.8/python-3.11.8-amd64.exe"
    $PythonInstaller = "$env:TEMP\python-3.11.8-amd64.exe"
    
    Invoke-WebRequest -Uri $PythonUrl -OutFile $PythonInstaller
    Start-Process -FilePath $PythonInstaller -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1" -Wait
    Remove-Item $PythonInstaller
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Create virtual environment for bot
if (!(Test-Path $BotVenvPath)) {
    python -m venv $BotVenvPath
    Write-Host "Bot virtual environment created" -ForegroundColor Green
}

# Install bot requirements
Write-Host "Installing bot packages..." -ForegroundColor Yellow
& "$BotVenvPath\Scripts\Activate.ps1"
pip install -r "$BotDir\requirements.txt"
Write-Host "Bot packages installed" -ForegroundColor Green

# Create bot management scripts
Write-Host "Creating bot management scripts..." -ForegroundColor Yellow

# Start bot script
$StartBotScript = @"
@echo off
cd /d C:\bot
echo Starting Telegram Bot...
echo.
echo Bot is running...
echo Press Ctrl+C to stop bot
echo.
call venv\Scripts\activate.bat
python bot.py
pause
"@
Set-Content -Path "$BotDir\start_bot.bat" -Value $StartBotScript

# Stop bot script
$StopBotScript = @"
@echo off
echo Stopping Telegram Bot...
taskkill /f /im python.exe 2>nul
echo Bot stopped.
pause
"@
Set-Content -Path "$BotDir\stop_bot.bat" -Value $StopBotScript

# Status bot script
$StatusBotScript = @"
@echo off
echo Telegram Bot Status:
echo.
tasklist | findstr python.exe
echo.
if %errorlevel%==0 (
    echo Bot is RUNNING
) else (
    echo Bot is NOT RUNNING
)
echo.
pause
"@
Set-Content -Path "$BotDir\status_bot.bat" -Value $StatusBotScript

# Create Windows Service for bot
$BotServiceScript = @"
@echo off
echo Installing Telegram Bot as Windows Service...
echo.
sc create "TelegramBot" binPath= "C:\bot\venv\Scripts\python.exe C:\bot\bot.py" start= auto
sc description "TelegramBot" "Telegram Bot Service"
sc start "TelegramBot"
echo.
echo Bot service installed and started!
echo To manage service:
echo - Start: sc start TelegramBot
echo - Stop: sc stop TelegramBot
echo - Remove: sc delete TelegramBot
echo.
pause
"@
Set-Content -Path "$BotDir\install_bot_service.bat" -Value $BotServiceScript

# Create bot configuration
$BotConfigContent = @"
# Telegram Bot Configuration

[Bot]
Token = 7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w
Username = your_bot_username

[Database]
Path = C:\bot\users.db

[Logging]
Level = INFO
File = C:\bot\bot.log

[Security]
AdminUsers = 123456789,987654321
"@
Set-Content -Path "$BotDir\bot_config.ini" -Value $BotConfigContent

# Create bot launcher with auto-restart
$BotLauncherScript = @"
@echo off
cd /d C:\bot
echo Telegram Bot Launcher
echo ====================
echo.
echo Starting bot with auto-restart...
echo.

:start
echo [%date% %time%] Starting bot...
call venv\Scripts\activate.bat
python bot.py

echo.
echo [%date% %time%] Bot stopped. Restarting in 5 seconds...
timeout /t 5 /nobreak >nul
goto start
"@
Set-Content -Path "$BotDir\bot_launcher.bat" -Value $BotLauncherScript

# Create systemd-style service file (for advanced users)
$BotServiceFile = @"
[Unit]
Description=Telegram Bot Service
After=network.target

[Service]
Type=simple
User=SYSTEM
WorkingDirectory=C:\bot
ExecStart=C:\bot\venv\Scripts\python.exe C:\bot\bot.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
"@
Set-Content -Path "$BotDir\telegram-bot.service" -Value $BotServiceFile

Write-Host "Bot management scripts created" -ForegroundColor Green

# Create autostart for bot
Write-Host "Setting up bot autostart..." -ForegroundColor Yellow
$StartupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$BotShortcutPath = "$StartupFolder\TelegramBot.lnk"

try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($BotShortcutPath)
    $Shortcut.TargetPath = "$BotDir\bot_launcher.bat"
    $Shortcut.WorkingDirectory = $BotDir
    $Shortcut.Description = "Telegram Bot"
    $Shortcut.Save()
    Write-Host "Bot autostart configured!" -ForegroundColor Green
} catch {
    Write-Host "Could not create bot autostart shortcut (run as admin for this)" -ForegroundColor Yellow
}

# Create bot README
$BotReadmeContent = @"
# Telegram Bot Hosting - Windows Setup

## Quick Start
1. Double-click: `start_bot.bat`
2. Bot will start running
3. Check logs in console

## Management Scripts
- `start_bot.bat` - Start the bot
- `stop_bot.bat` - Stop the bot  
- `status_bot.bat` - Check bot status
- `bot_launcher.bat` - Start with auto-restart
- `install_bot_service.bat` - Install as Windows service

## Files
- `bot.py` - Main bot application
- `users.db` - SQLite database
- `bot_config.ini` - Configuration file
- `bot.log` - Log file (created automatically)

## Configuration
Edit `bot_config.ini` to change settings:
- Bot token
- Admin users
- Logging level

## Service Installation (Optional)
Run `install_bot_service.bat` as Administrator to install as Windows service.

## Auto-restart
Use `bot_launcher.bat` for automatic restart on crash.

## Troubleshooting
- Check bot token in bot.py
- Ensure Python 3.11+ is installed
- Run as Administrator if needed
- Check Windows Firewall settings

## Logs
Bot logs are displayed in console. For file logging, edit bot_config.ini.
"@
Set-Content -Path "$BotDir\README.md" -Value $BotReadmeContent

Write-Host "Bot configuration files created" -ForegroundColor Green

# Create combined launcher (both web server and bot)
$CombinedLauncherScript = @"
@echo off
echo Home Server + Telegram Bot Launcher
echo ===================================
echo.
echo Starting both services...
echo.

cd /d C:\server
start "Web Server" cmd /k "start_server.bat"

cd /d C:\bot
start "Telegram Bot" cmd /k "bot_launcher.bat"

echo.
echo Both services started!
echo - Web Server: http://localhost:5000
echo - Telegram Bot: Running
echo.
echo Press any key to close this window...
pause >nul
"@
Set-Content -Path "C:\server\start_all.bat" -Value $CombinedLauncherScript

Write-Host "Combined launcher created" -ForegroundColor Green

Write-Host "Bot hosting setup completed!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Start bot: C:\bot\start_bot.bat" -ForegroundColor White
Write-Host "2. Start with auto-restart: C:\bot\bot_launcher.bat" -ForegroundColor White
Write-Host "3. Install as service: C:\bot\install_bot_service.bat (as admin)" -ForegroundColor White
Write-Host "4. Start both (web + bot): C:\server\start_all.bat" -ForegroundColor White
Write-Host "5. Read: C:\bot\README.md" -ForegroundColor White
Write-Host "================================================" -ForegroundColor Cyan

Read-Host "Press Enter to continue..." 