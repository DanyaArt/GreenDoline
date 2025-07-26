# 🪟 Домашний сервер на Windows 11 Home

## 🚀 Быстрая установка

### Шаг 1: Запуск установки
1. **Правый клик** на файле `quick_start.bat`
2. Выберите **"Запуск от имени администратора"**
3. Следуйте инструкциям на экране

### Шаг 2: Перезагрузка
- Компьютер перезагрузится автоматически
- Или перезагрузите вручную

### Шаг 3: Настройка WSL2
После перезагрузки откройте **PowerShell** и выполните:

```powershell
# Установка Linux
wsl --install -d Ubuntu

# Настройка WSL2
wsl --set-default-version 2

# Перезапуск WSL2
wsl --shutdown
wsl
```

### Шаг 4: Настройка в Linux
В открывшемся терминале Linux выполните:

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
sudo apt install -y python3 python3-pip python3-venv nginx supervisor git curl wget

# Создание директории проекта
sudo mkdir -p /var/www/project
sudo chown $USER:$USER /var/www/project

# Копирование файлов
cp -r /mnt/c/server/* /var/www/project/

# Настройка Python
cd /var/www/project
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Настройка Nginx
sudo cp nginx.conf /etc/nginx/sites-available/project
sudo ln -sf /etc/nginx/sites-available/project /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

# Настройка Supervisor
sudo cp supervisor_webapp.conf /etc/supervisor/conf.d/
sudo cp supervisor_bot.conf /etc/supervisor/conf.d/
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start webapp telegram_bot
```

### Шаг 5: Запуск сервера
В Windows выполните:
```cmd
C:\server\start_server.bat
```

## 🎛️ Управление сервером

### Быстрые команды
- **Запуск**: `C:\server\start_server.bat`
- **Остановка**: `C:\server\stop_server.bat`
- **Статус**: `C:\server\status_server.bat`

### Веб-интерфейс
- **Веб-панель управления**: http://localhost:8080
- **Основной сайт**: http://localhost:5000
- **Админ панель**: http://localhost:5000/admin

## 🔧 Автозапуск

Сервер будет автоматически запускаться при старте Windows.

## 📊 Мониторинг

Веб-панель управления показывает:
- Загрузка CPU и RAM
- Статус сервисов
- Температуру системы
- Сетевую информацию

## 🌐 Доступ из интернета

### Настройка роутера
1. Войдите в настройки роутера (обычно 192.168.1.1)
2. Найдите "Проброс портов" или "Port Forwarding"
3. Добавьте правила:
   - Порт 80 → ваш_IP:80
   - Порт 443 → ваш_IP:443
   - Порт 5000 → ваш_IP:5000

### Статический IP
1. Откройте "Сетевые подключения"
2. Правый клик на адаптере → Свойства
3. "Протокол Интернета версии 4" → Свойства
4. Укажите статический IP

## 🔒 Безопасность

- Брандмауэр Windows настроен автоматически
- Сервисы работают в изолированной среде WSL2
- Рекомендуется настроить SSL-сертификат для продакшена

## 💰 Экономия энергии

### Настройка плана электропитания
1. Откройте "Электропитание"
2. Создайте план "Сервер"
3. Настройте:
   - Отключение дисплея: 5 минут
   - Переход в спящий режим: Никогда
   - Отключение жестких дисков: Никогда

## 🆘 Устранение неполадок

### Проблема: WSL2 не запускается
```powershell
# Перезапуск WSL2
wsl --shutdown
wsl --update
```

### Проблема: Сервисы не работают
```bash
# В WSL2 Ubuntu
sudo systemctl status nginx
sudo supervisorctl status
```

### Проблема: Порты заняты
```powershell
# Проверка занятых портов
netstat -ano | findstr :5000
netstat -ano | findstr :8080
```

## 📞 Поддержка

Если возникли проблемы:
1. Проверьте файл `C:\server\WSL2_SETUP.md`
2. Посмотрите логи в веб-панели управления
3. Проверьте статус сервисов командой `C:\server\status_server.bat`

## ✅ Преимущества Windows 11 Home + WSL2

- ✅ Бесплатно
- ✅ Знакомая среда Windows
- ✅ Мощность Ryzen 7 5700U
- ✅ Полная совместимость с Linux-кодом
- ✅ Простота управления
- ✅ Автозапуск при старте системы
- ✅ Веб-интерфейс управления
- ✅ Экономия энергии 