# 🪟 Домашний хостинг на Windows (Ryzen 7 5700U, 8GB RAM)

## 📋 Варианты настройки

### Вариант 1: Windows Server (рекомендую)
- **Преимущества**: Стабильность, встроенные сервисы
- **Недостатки**: Платная лицензия
- **Подходит для**: Продакшн среды

### Вариант 2: Windows 10/11 + WSL2
- **Преимущества**: Бесплатно, Linux внутри Windows
- **Недостатки**: Дополнительный слой абстракции
- **Подходит для**: Разработка и тестирование

### Вариант 3: Windows + Docker
- **Преимущества**: Изоляция, простота развертывания
- **Недостатки**: Требует Docker Desktop
- **Подходит для**: Контейнеризация

## 🚀 Вариант 1: Windows Server

### Установка Windows Server
1. Скачайте Windows Server 2022 (есть бесплатная пробная версия)
2. Установите на ноутбук
3. Настройте статический IP

### Установка необходимого ПО
```powershell
# Установка Chocolatey (менеджер пакетов)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Установка Python
choco install python -y

# Установка Git
choco install git -y

# Установка Node.js (для дополнительных инструментов)
choco install nodejs -y
```

### Настройка Python окружения
```powershell
# Создание виртуального окружения
python -m venv C:\server\venv
C:\server\venv\Scripts\Activate.ps1

# Установка зависимостей
pip install -r requirements.txt
```

### Настройка Windows Firewall
```powershell
# Открытие портов
New-NetFirewallRule -DisplayName "Web Server" -Direction Inbound -Protocol TCP -LocalPort 80,443,5000,8080 -Action Allow
New-NetFirewallRule -DisplayName "SSH" -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow
```

## 🐧 Вариант 2: Windows + WSL2 (рекомендую для вас)

### Установка WSL2
```powershell
# Включение WSL2
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Перезагрузка
Restart-Computer

# Установка Ubuntu
wsl --install -d Ubuntu

# Установка WSL2 как версии по умолчанию
wsl --set-default-version 2
```

### Настройка WSL2
```bash
# В WSL2 Ubuntu
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
sudo apt install -y python3 python3-pip python3-venv nginx supervisor git curl wget

# Создание директории для проекта
sudo mkdir -p /var/www/project
sudo chown $USER:$USER /var/www/project
```

### Настройка автозапуска WSL2
```powershell
# Создание bat-файла для автозапуска
@echo off
wsl -d Ubuntu -u root service nginx start
wsl -d Ubuntu -u root supervisorctl start all
```

## 🐳 Вариант 3: Windows + Docker

### Установка Docker Desktop
1. Скачайте Docker Desktop для Windows
2. Установите и запустите
3. Включите WSL2 backend

### Создание Docker Compose
```yaml
# docker-compose.yml
version: '3.8'

services:
  webapp:
    build: .
    ports:
      - "5000:5000"
    volumes:
      - ./:/app
    environment:
      - TELEGRAM_BOT_TOKEN=7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w
    restart: unless-stopped

  telegram_bot:
    build: .
    command: python bot.py
    volumes:
      - ./:/app
    environment:
      - TELEGRAM_BOT_TOKEN=7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./static:/var/www/static
    depends_on:
      - webapp
    restart: unless-stopped
```

## 🎛️ Управление сервером на Windows

### Создание PowerShell скриптов
```powershell
# start_server.ps1
Write-Host "🚀 Запуск сервера..." -ForegroundColor Green

# Для WSL2
wsl -d Ubuntu -u root service nginx start
wsl -d Ubuntu -u root supervisorctl start all

# Для Docker
docker-compose up -d

Write-Host "✅ Сервер запущен!" -ForegroundColor Green
```

```powershell
# stop_server.ps1
Write-Host "🛑 Остановка сервера..." -ForegroundColor Yellow

# Для WSL2
wsl -d Ubuntu -u root service nginx stop
wsl -d Ubuntu -u root supervisorctl stop all

# Для Docker
docker-compose down

Write-Host "✅ Сервер остановлен!" -ForegroundColor Green
```

```powershell
# status_server.ps1
Write-Host "📊 Статус сервера:" -ForegroundColor Cyan

# Для WSL2
wsl -d Ubuntu -u root service nginx status
wsl -d Ubuntu -u root supervisorctl status

# Для Docker
docker-compose ps

Write-Host "========================" -ForegroundColor Cyan
```

### Создание bat-файлов для удобства
```batch
@echo off
REM start_server.bat
echo 🚀 Запуск сервера...
powershell -ExecutionPolicy Bypass -File start_server.ps1
pause
```

```batch
@echo off
REM stop_server.bat
echo 🛑 Остановка сервера...
powershell -ExecutionPolicy Bypass -File stop_server.ps1
pause
```

## 🔧 Настройка автозапуска

### Windows Task Scheduler
1. Откройте "Планировщик задач"
2. Создайте новую задачу
3. Настройте запуск при старте системы
4. Укажите путь к `start_server.bat`

### Реестр Windows
```powershell
# Добавление в автозапуск через реестр
$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $path -Name "HomeServer" -Value "C:\server\start_server.bat"
```

## 📊 Мониторинг на Windows

### PowerShell скрипт мониторинга
```powershell
# monitor_server.ps1
Write-Host "=== Мониторинг системы ===" -ForegroundColor Cyan

# CPU
$cpu = Get-Counter "\Processor(_Total)\% Processor Time"
Write-Host "CPU: $($cpu.CounterSamples[0].CookedValue)%" -ForegroundColor Yellow

# RAM
$ram = Get-Counter "\Memory\Available MBytes"
$totalRam = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1MB
$usedRam = $totalRam - $ram.CounterSamples[0].CookedValue
$ramPercent = [math]::Round(($usedRam / $totalRam) * 100, 1)
Write-Host "RAM: ${ramPercent}%" -ForegroundColor Yellow

# Диск
$disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
$diskPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
Write-Host "Диск C: ${diskPercent}%" -ForegroundColor Yellow

Write-Host "========================" -ForegroundColor Cyan
```

## 🌐 Настройка сети

### Статический IP в Windows
1. Откройте "Сетевые подключения"
2. Правый клик на адаптере → Свойства
3. Выберите "Протокол Интернета версии 4" → Свойства
4. Укажите статический IP

### Настройка роутера
1. Войдите в настройки роутера
2. Настройте проброс портов:
   - Порт 80 → ваш_IP:80
   - Порт 443 → ваш_IP:443
   - Порт 5000 → ваш_IP:5000

## 🔒 Безопасность

### Windows Defender
```powershell
# Настройка исключений для проекта
Add-MpPreference -ExclusionPath "C:\server"
Add-MpPreference -ExclusionProcess "python.exe"
```

### Брандмауэр Windows
```powershell
# Создание правил для приложения
New-NetFirewallRule -DisplayName "Home Server App" -Direction Inbound -Program "C:\server\venv\Scripts\python.exe" -Action Allow
```

## 💰 Экономия энергии

### Настройка планов электропитания
1. Откройте "Электропитание"
2. Создайте новый план "Сервер"
3. Настройте:
   - Отключение дисплея: 5 минут
   - Переход в спящий режим: Никогда
   - Отключение жестких дисков: Никогда

### PowerShell скрипт экономии
```powershell
# power_save.ps1
Write-Host "🔋 Включение режима экономии энергии..." -ForegroundColor Green

# Установка плана электропитания
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e

# Ограничение CPU
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 50
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 80

Write-Host "✅ Режим экономии энергии включен!" -ForegroundColor Green
```

## 📱 Веб-интерфейс управления

### Запуск веб-панели
```powershell
# Запуск веб-интерфейса управления
cd C:\server
.\venv\Scripts\python.exe server_control.py
```

### Доступ к панели
- Откройте браузер
- Перейдите на `http://ваш_ip:8080`

## ✅ Преимущества Windows-решения

1. **Знакомая среда** - работаете в Windows
2. **Простота настройки** - графический интерфейс
3. **Интеграция** - с Windows-сервисами
4. **Мощность** - Ryzen 7 5700U справится с любой нагрузкой
5. **Экономия** - только стоимость электроэнергии

## 🎯 Рекомендация

**Для вашего случая рекомендую WSL2**, потому что:
- Бесплатно
- Полная совместимость с Linux-кодом
- Простота настройки
- Хорошая производительность
- Возможность использовать Linux-инструменты

Хотите, чтобы я создал автоматический скрипт установки для Windows + WSL2? 