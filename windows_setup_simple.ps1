# Windows 11 Home Server Setup
# Ryzen 7 5700U, 8GB RAM

Write-Host "Installing home server on Windows 11 Home..." -ForegroundColor Green
Write-Host "System: Ryzen 7 5700U, 8GB RAM" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Yellow

# Check admin rights
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Administrator rights required!" -ForegroundColor Red
    Write-Host "Run PowerShell as Administrator" -ForegroundColor Yellow
    pause
    exit
}

# Create server directory
$serverPath = "C:\server"
if (!(Test-Path $serverPath)) {
    Write-Host "Creating server directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $serverPath -Force
}

# Copy project files
Write-Host "Copying project files..." -ForegroundColor Yellow
$currentDir = Get-Location
Copy-Item -Path "$currentDir\*" -Destination $serverPath -Recurse -Force

# Enable WSL2
Write-Host "Enabling WSL2..." -ForegroundColor Yellow
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

Write-Host "WSL2 enabled!" -ForegroundColor Green
Write-Host "Restart required to complete WSL2 installation" -ForegroundColor Red
$restart = Read-Host "Restart computer now? (y/n)"
if ($restart -eq 'y' -or $restart -eq 'Y') {
    Restart-Computer -Force
}

# Create management scripts
Write-Host "Creating management scripts..." -ForegroundColor Yellow

# start_server.ps1
$startServerScript = @"
# Start home server
Write-Host "Starting server..." -ForegroundColor Green

# Start WSL2 services
wsl -u root service nginx start
wsl -u root supervisorctl start all

# Start web control panel
Start-Process -FilePath "powershell" -ArgumentList "-ExecutionPolicy Bypass -File `"$serverPath\server_control.ps1`"" -WindowStyle Minimized

Write-Host "Server started!" -ForegroundColor Green
Write-Host "Web panel: http://localhost:8080" -ForegroundColor Cyan
Write-Host "Website: http://localhost:5000" -ForegroundColor Cyan
"@
$startServerScript | Out-File -FilePath "$serverPath\start_server.ps1" -Encoding UTF8

# stop_server.ps1
$stopServerScript = @"
# Stop home server
Write-Host "Stopping server..." -ForegroundColor Yellow

# Stop WSL2 services
wsl -u root service nginx stop
wsl -u root supervisorctl stop all

# Stop web panel
Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object {`$_.ProcessName -eq "python"} | Stop-Process -Force

Write-Host "Server stopped!" -ForegroundColor Green
"@
$stopServerScript | Out-File -FilePath "$serverPath\stop_server.ps1" -Encoding UTF8

# status_server.ps1
$statusServerScript = @"
# Server status
Write-Host "Server status:" -ForegroundColor Cyan

# WSL2 services status
Write-Host "WSL2 services:" -ForegroundColor Yellow
wsl -u root service nginx status
wsl -u root supervisorctl status

# System info
Write-Host "System:" -ForegroundColor Yellow
`$cpu = Get-Counter "\Processor(_Total)\% Processor Time"
`$ram = Get-Counter "\Memory\Available MBytes"
`$totalRam = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1MB
`$usedRam = `$totalRam - `$ram.CounterSamples[0].CookedValue
`$ramPercent = [math]::Round((`$usedRam / `$totalRam) * 100, 1)

Write-Host "CPU: `$(`$cpu.CounterSamples[0].CookedValue)%" -ForegroundColor Green
Write-Host "RAM: `$ramPercent%" -ForegroundColor Green

Write-Host "========================" -ForegroundColor Cyan
"@
$statusServerScript | Out-File -FilePath "$serverPath\status_server.ps1" -Encoding UTF8

# server_control.ps1
$serverControlScript = @"
# Web control panel
cd $serverPath
if (Test-Path "venv\Scripts\python.exe") {
    .\venv\Scripts\python.exe server_control.py
} else {
    python server_control.py
}
"@
$serverControlScript | Out-File -FilePath "$serverPath\server_control.ps1" -Encoding UTF8

# Create bat files
$startServerBat = @"
@echo off
echo Starting home server...
powershell -ExecutionPolicy Bypass -File "$serverPath\start_server.ps1"
pause
"@
$startServerBat | Out-File -FilePath "$serverPath\start_server.bat" -Encoding ASCII

$stopServerBat = @"
@echo off
echo Stopping home server...
powershell -ExecutionPolicy Bypass -File "$serverPath\stop_server.ps1"
pause
"@
$stopServerBat | Out-File -FilePath "$serverPath\stop_server.bat" -Encoding ASCII

$statusServerBat = @"
@echo off
echo Server status...
powershell -ExecutionPolicy Bypass -File "$serverPath\status_server.ps1"
pause
"@
$statusServerBat | Out-File -FilePath "$serverPath\status_server.bat" -Encoding ASCII

# Configure firewall
Write-Host "Configuring firewall..." -ForegroundColor Yellow
New-NetFirewallRule -DisplayName "Home Server Web" -Direction Inbound -Protocol TCP -LocalPort 80,443,5000,8080 -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "Home Server SSH" -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow -ErrorAction SilentlyContinue

# Setup autostart
Write-Host "Setting up autostart..." -ForegroundColor Yellow
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = "$startupPath\HomeServer.lnk"

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "$serverPath\start_server.bat"
$Shortcut.WorkingDirectory = $serverPath
$Shortcut.Description = "Home Server"
$Shortcut.Save()

Write-Host "Autostart configured!" -ForegroundColor Green

# Create WSL2 setup instructions
Write-Host "Creating WSL2 setup instructions..." -ForegroundColor Yellow

$wslInstructions = @"
# WSL2 Setup Instructions

After restart, run these commands in PowerShell:

1. Install Linux:
   wsl --install -d Ubuntu

2. Set WSL2 as default:
   wsl --set-default-version 2

3. Restart WSL2:
   wsl --shutdown
   wsl

4. In Linux terminal run:
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y python3 python3-pip python3-venv nginx supervisor git curl wget

5. Create project directory:
   sudo mkdir -p /var/www/project
   sudo chown `$USER:`$USER /var/www/project

6. Copy files:
   cp -r /mnt/c/server/* /var/www/project/

7. Setup Python environment:
   cd /var/www/project
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt

8. Configure Nginx:
   sudo cp nginx.conf /etc/nginx/sites-available/project
   sudo ln -sf /etc/nginx/sites-available/project /etc/nginx/sites-enabled/
   sudo rm -f /etc/nginx/sites-enabled/default
   sudo nginx -t && sudo systemctl restart nginx

9. Configure Supervisor:
   sudo cp supervisor_webapp.conf /etc/supervisor/conf.d/
   sudo cp supervisor_bot.conf /etc/supervisor/conf.d/
   sudo supervisorctl reread
   sudo supervisorctl update
   sudo supervisorctl start webapp telegram_bot

10. Start server from Windows:
    C:\server\start_server.bat

Access to services:
- Web control panel: http://localhost:8080
- Main website: http://localhost:5000
- Admin panel: http://localhost:5000/admin

Management:
- Start: C:\server\start_server.bat
- Stop: C:\server\stop_server.bat
- Status: C:\server\status_server.bat
"@

$wslInstructions | Out-File -FilePath "$serverPath\WSL2_SETUP.md" -Encoding UTF8

# Create config files
Write-Host "Creating config files..." -ForegroundColor Yellow

# nginx.conf
$nginxConfig = @"
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
    }

    location /static {
        alias /var/www/project/static;
    }
}
"@
$nginxConfig | Out-File -FilePath "$serverPath\nginx.conf" -Encoding UTF8

# supervisor_webapp.conf
$supervisorWebapp = @"
[program:webapp]
command=/var/www/project/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:5000 admin:app
directory=/var/www/project
user=root
autostart=true
autorestart=true
stderr_logfile=/var/log/webapp.err.log
stdout_logfile=/var/log/webapp.out.log
environment=TELEGRAM_BOT_TOKEN="7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w"
"@
$supervisorWebapp | Out-File -FilePath "$serverPath\supervisor_webapp.conf" -Encoding UTF8

# supervisor_bot.conf
$supervisorBot = @"
[program:telegram_bot]
command=/var/www/project/venv/bin/python bot.py
directory=/var/www/project
user=root
autostart=true
autorestart=true
stderr_logfile=/var/log/telegram_bot.err.log
stdout_logfile=/var/log/telegram_bot.out.log
environment=TELEGRAM_BOT_TOKEN="7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w"
"@
$supervisorBot | Out-File -FilePath "$serverPath\supervisor_bot.conf" -Encoding UTF8

Write-Host "Installation completed!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Yellow
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Restart computer" -ForegroundColor White
Write-Host "2. Read file: C:\server\WSL2_SETUP.md" -ForegroundColor White
Write-Host "3. Follow instructions" -ForegroundColor White
Write-Host "4. Start server: C:\server\start_server.bat" -ForegroundColor White
Write-Host "================================================" -ForegroundColor Yellow

pause 