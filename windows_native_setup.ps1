# Windows Native Home Server Setup
# Установка домашнего сервера на чистой Windows 11 Home

Write-Host "Installing home server on Windows 11 Home (Native)..." -ForegroundColor Green
Write-Host "System: Ryzen 7 5700U, 8GB RAM" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan

# Create server directory
$ServerDir = "C:\server"
if (!(Test-Path $ServerDir)) {
    New-Item -ItemType Directory -Path $ServerDir -Force
    Write-Host "Created server directory: $ServerDir" -ForegroundColor Green
}

# Copy project files
Write-Host "Copying project files..." -ForegroundColor Yellow
Copy-Item -Path ".\*" -Destination $ServerDir -Recurse -Force -Exclude "*.ps1", "*.bat", "*.md", "*.txt"
Write-Host "Project files copied to $ServerDir" -ForegroundColor Green

# Create Python virtual environment
Write-Host "Setting up Python environment..." -ForegroundColor Yellow
$PythonPath = "C:\Python311"
$VenvPath = "$ServerDir\venv"

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

# Create virtual environment
if (!(Test-Path $VenvPath)) {
    python -m venv $VenvPath
    Write-Host "Virtual environment created" -ForegroundColor Green
}

# Install requirements
Write-Host "Installing Python packages..." -ForegroundColor Yellow
& "$VenvPath\Scripts\Activate.ps1"

# Install packages from requirements.txt if it exists
if (Test-Path "requirements.txt") {
    pip install -r requirements.txt
    Write-Host "Packages from requirements.txt installed" -ForegroundColor Green
} else {
    # Install basic packages if requirements.txt doesn't exist
    pip install flask flask-sqlalchemy werkzeug pyTelegramBotAPI gunicorn psutil
    Write-Host "Basic packages installed" -ForegroundColor Green
}

# Create server management scripts
Write-Host "Creating management scripts..." -ForegroundColor Yellow

# Start server script
$StartScript = @"
@echo off
cd /d C:\server
echo Starting Home Server...
echo.
echo Server will be available at:
echo - Web: http://localhost:5000
echo - Admin: http://localhost:5000/admin
echo.
echo Press Ctrl+C to stop server
echo.
call venv\Scripts\activate.bat
python bot.py
pause
"@
Set-Content -Path "$ServerDir\start_server.bat" -Value $StartScript

# Stop server script
$StopScript = @"
@echo off
echo Stopping Home Server...
taskkill /f /im python.exe 2>nul
echo Server stopped.
pause
"@
Set-Content -Path "$ServerDir\stop_server.bat" -Value $StopScript

# Status script
$StatusScript = @"
@echo off
echo Home Server Status:
echo.
netstat -an | findstr :5000
echo.
if %errorlevel%==0 (
    echo Server is RUNNING on port 5000
) else (
    echo Server is NOT RUNNING
)
echo.
pause
"@
Set-Content -Path "$ServerDir\status_server.bat" -Value $StatusScript

# Create Windows Service (optional)
$ServiceScript = @"
@echo off
echo Installing Home Server as Windows Service...
echo.
sc create "HomeServer" binPath= "C:\server\venv\Scripts\python.exe C:\server\bot.py" start= auto
sc description "HomeServer" "Home Server Web Application"
sc start "HomeServer"
echo.
echo Service installed and started!
echo To manage service:
echo - Start: sc start HomeServer
echo - Stop: sc stop HomeServer
echo - Remove: sc delete HomeServer
echo.
pause
"@
Set-Content -Path "$ServerDir\install_service.bat" -Value $ServiceScript

Write-Host "Management scripts created" -ForegroundColor Green

# Configure Windows Firewall
Write-Host "Configuring firewall..." -ForegroundColor Yellow

# Remove existing rules if they exist
Remove-NetFirewallRule -DisplayName "Home Server Web" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "Home Server SSH" -ErrorAction SilentlyContinue

# Create new firewall rules
New-NetFirewallRule -DisplayName "Home Server Web" -Direction Inbound -Protocol TCP -LocalPort 5000 -Action Allow
New-NetFirewallRule -DisplayName "Home Server SSH" -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow

Write-Host "Firewall configured" -ForegroundColor Green

# Create autostart shortcut
Write-Host "Setting up autostart..." -ForegroundColor Yellow
$StartupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$ShortcutPath = "$StartupFolder\HomeServer.lnk"

try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = "$ServerDir\start_server.bat"
    $Shortcut.WorkingDirectory = $ServerDir
    $Shortcut.Description = "Home Server"
    $Shortcut.Save()
    Write-Host "Autostart configured!" -ForegroundColor Green
} catch {
    Write-Host "Could not create autostart shortcut (run as admin for this)" -ForegroundColor Yellow
}

# Create configuration file
$ConfigContent = @"
# Home Server Configuration
# Windows Native Setup

[Server]
Host = 0.0.0.0
Port = 5000
Debug = False

[Database]
Path = C:\server\users.db

[Security]
SecretKey = your-secret-key-change-this
AdminPassword = admin123

[Paths]
Templates = C:\server\templates
Static = C:\server\img
"@
Set-Content -Path "$ServerDir\config.ini" -Value $ConfigContent

# Create README
$ReadmeContent = @"
# Home Server - Windows Native Setup

## Quick Start
1. Double-click: `start_server.bat`
2. Open browser: http://localhost:5000
3. Admin panel: http://localhost:5000/admin

## Management Scripts
- `start_server.bat` - Start the server
- `stop_server.bat` - Stop the server  
- `status_server.bat` - Check server status
- `install_service.bat` - Install as Windows service

## Files
- `bot.py` - Main server application
- `templates/` - HTML templates
- `img/` - Static images
- `users.db` - SQLite database

## Configuration
Edit `config.ini` to change settings:
- Port number
- Admin password
- Database path

## Troubleshooting
- Check Windows Firewall settings
- Ensure Python 3.11+ is installed
- Run as Administrator if needed

## Service Installation (Optional)
Run `install_service.bat` as Administrator to install as Windows service.
"@
Set-Content -Path "$ServerDir\README.md" -Value $ReadmeContent

Write-Host "Configuration files created" -ForegroundColor Green

Write-Host "Installation completed!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Start server: C:\server\start_server.bat" -ForegroundColor White
Write-Host "2. Open browser: http://localhost:5000" -ForegroundColor White
Write-Host "3. Admin panel: http://localhost:5000/admin" -ForegroundColor White
Write-Host "4. Read: C:\server\README.md" -ForegroundColor White
Write-Host "================================================" -ForegroundColor Cyan

Read-Host "Press Enter to continue..." 