# Автоматическая установка домашнего сервера для Windows 11 Home
# Ryzen 7 5700U, 8GB RAM

Write-Host "Установка домашнего сервера на Windows 11 Home..." -ForegroundColor Green
Write-Host "Система: Ryzen 7 5700U, 8GB RAM" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Yellow

# Проверка прав администратора
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Требуются права администратора!" -ForegroundColor Red
    Write-Host "Запустите PowerShell от имени администратора" -ForegroundColor Yellow
    pause
    exit
}

# Создание директории для сервера
$serverPath = "C:\server"
if (!(Test-Path $serverPath)) {
    Write-Host "Создание директории сервера..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $serverPath -Force
}

# Копирование файлов проекта
Write-Host "Копирование файлов проекта..." -ForegroundColor Yellow
$currentDir = Get-Location
Copy-Item -Path "$currentDir\*" -Destination $serverPath -Recurse -Force

# Включение WSL2
Write-Host "Включение WSL2..." -ForegroundColor Yellow
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

Write-Host "WSL2 включен!" -ForegroundColor Green
Write-Host "Требуется перезагрузка для завершения установки WSL2" -ForegroundColor Red
$restart = Read-Host "Перезагрузить компьютер сейчас? (y/n)"
if ($restart -eq 'y' -or $restart -eq 'Y') {
    Restart-Computer -Force
}

# Создание скриптов управления
Write-Host "Создание скриптов управления..." -ForegroundColor Yellow

# start_server.ps1
$startServerScript = @"
# Запуск домашнего сервера
Write-Host "Запуск сервера..." -ForegroundColor Green

# Запуск WSL2 сервисов
wsl -u root service nginx start
wsl -u root supervisorctl start all

# Запуск веб-панели управления
Start-Process -FilePath "powershell" -ArgumentList "-ExecutionPolicy Bypass -File `"$serverPath\server_control.ps1`"" -WindowStyle Minimized

Write-Host "Сервер запущен!" -ForegroundColor Green
Write-Host "Веб-панель: http://localhost:8080" -ForegroundColor Cyan
Write-Host "Сайт: http://localhost:5000" -ForegroundColor Cyan
"@
$startServerScript | Out-File -FilePath "$serverPath\start_server.ps1" -Encoding UTF8

# stop_server.ps1
$stopServerScript = @"
# Остановка домашнего сервера
Write-Host "Остановка сервера..." -ForegroundColor Yellow

# Остановка WSL2 сервисов
wsl -u root service nginx stop
wsl -u root supervisorctl stop all

# Остановка веб-панели
Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object {`$_.ProcessName -eq "python"} | Stop-Process -Force

Write-Host "Сервер остановлен!" -ForegroundColor Green
"@
$stopServerScript | Out-File -FilePath "$serverPath\stop_server.ps1" -Encoding UTF8

# status_server.ps1
$statusServerScript = @"
# Статус домашнего сервера
Write-Host "Статус сервера:" -ForegroundColor Cyan

# Статус WSL2 сервисов
Write-Host "WSL2 сервисы:" -ForegroundColor Yellow
wsl -u root service nginx status
wsl -u root supervisorctl status

# Системная информация
Write-Host "Система:" -ForegroundColor Yellow
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

# server_control.ps1 (запуск веб-панели)
$serverControlScript = @"
# Веб-панель управления сервером
cd $serverPath
if (Test-Path "venv\Scripts\python.exe") {
    .\venv\Scripts\python.exe server_control.py
} else {
    python server_control.py
}
"@
$serverControlScript | Out-File -FilePath "$serverPath\server_control.ps1" -Encoding UTF8

# Создание bat-файлов для удобства
$startServerBat = @"
@echo off
echo Запуск домашнего сервера...
powershell -ExecutionPolicy Bypass -File "$serverPath\start_server.ps1"
pause
"@
$startServerBat | Out-File -FilePath "$serverPath\start_server.bat" -Encoding ASCII

$stopServerBat = @"
@echo off
echo Остановка домашнего сервера...
powershell -ExecutionPolicy Bypass -File "$serverPath\stop_server.ps1"
pause
"@
$stopServerBat | Out-File -FilePath "$serverPath\stop_server.bat" -Encoding ASCII

$statusServerBat = @"
@echo off
echo Статус домашнего сервера...
powershell -ExecutionPolicy Bypass -File "$serverPath\status_server.ps1"
pause
"@
$statusServerBat | Out-File -FilePath "$serverPath\status_server.bat" -Encoding ASCII

# Настройка брандмауэра
Write-Host "Настройка брандмауэра..." -ForegroundColor Yellow
New-NetFirewallRule -DisplayName "Home Server Web" -Direction Inbound -Protocol TCP -LocalPort 80,443,5000,8080 -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "Home Server SSH" -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow -ErrorAction SilentlyContinue

# Настройка автозапуска
Write-Host "Настройка автозапуска..." -ForegroundColor Yellow
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = "$startupPath\HomeServer.lnk"

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "$serverPath\start_server.bat"
$Shortcut.WorkingDirectory = $serverPath
$Shortcut.Description = "Домашний сервер"
$Shortcut.Save()

Write-Host "Автозапуск настроен!" -ForegroundColor Green

# Создание инструкции для WSL2
Write-Host "Создание инструкции для WSL2..." -ForegroundColor Yellow

$wslInstructions = @"
# Инструкция по настройке WSL2

После перезагрузки выполните следующие команды в PowerShell:

1. Установка Linux:
   wsl --install -d Ubuntu

2. Настройка WSL2 как версии по умолчанию:
   wsl --set-default-version 2

3. Перезапуск WSL2:
   wsl --shutdown
   wsl

4. В Linux терминале выполните:
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y python3 python3-pip python3-venv nginx supervisor git curl wget

5. Создание директории проекта:
   sudo mkdir -p /var/www/project
   sudo chown `$USER:`$USER /var/www/project

6. Копирование файлов:
   cp -r /mnt/c/server/* /var/www/project/

7. Настройка Python окружения:
   cd /var/www/project
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt

8. Настройка Nginx:
   sudo cp nginx.conf /etc/nginx/sites-available/project
   sudo ln -sf /etc/nginx/sites-available/project /etc/nginx/sites-enabled/
   sudo rm -f /etc/nginx/sites-enabled/default
   sudo nginx -t && sudo systemctl restart nginx

9. Настройка Supervisor:
   sudo cp supervisor_webapp.conf /etc/supervisor/conf.d/
   sudo cp supervisor_bot.conf /etc/supervisor/conf.d/
   sudo supervisorctl reread
   sudo supervisorctl update
   sudo supervisorctl start webapp telegram_bot

10. Запуск сервера из Windows:
    C:\server\start_server.bat

Доступ к сервисам:
- Веб-панель управления: http://localhost:8080
- Основной сайт: http://localhost:5000
- Админ панель: http://localhost:5000/admin

Управление:
- Запуск: C:\server\start_server.bat
- Остановка: C:\server\stop_server.bat
- Статус: C:\server\status_server.bat
"@

$wslInstructions | Out-File -FilePath "$serverPath\WSL2_SETUP.md" -Encoding UTF8

# Создание конфигурационных файлов для WSL2
Write-Host "Создание конфигурационных файлов..." -ForegroundColor Yellow

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

Write-Host "Установка завершена!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Yellow
Write-Host "Следующие шаги:" -ForegroundColor Cyan
Write-Host "1. Перезагрузите компьютер" -ForegroundColor White
Write-Host "2. Прочитайте файл: C:\server\WSL2_SETUP.md" -ForegroundColor White
Write-Host "3. Выполните команды из инструкции" -ForegroundColor White
Write-Host "4. Запустите сервер: C:\server\start_server.bat" -ForegroundColor White
Write-Host "================================================" -ForegroundColor Yellow

pause 