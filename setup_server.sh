#!/bin/bash

# Скрипт настройки сервера для хостинга проекта
# Запускать с правами root: sudo bash setup_server.sh

echo "🚀 Настройка сервера для хостинга проекта..."

# Обновление системы
echo "📦 Обновление системы..."
apt update && apt upgrade -y

# Установка необходимых пакетов
echo "🔧 Установка пакетов..."
apt install -y python3 python3-pip python3-venv nginx supervisor git curl wget

# Создание пользователя для приложения
echo "👤 Создание пользователя..."
useradd -m -s /bin/bash appuser
usermod -aG sudo appuser

# Создание директории для проекта
echo "📁 Создание директорий..."
mkdir -p /var/www/project
chown appuser:appuser /var/www/project

# Настройка Python окружения
echo "🐍 Настройка Python..."
cd /var/www/project
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip

# Клонирование проекта (замените на ваш репозиторий)
echo "📥 Клонирование проекта..."
git clone https://github.com/your-username/your-project.git .
pip install -r requirements.txt

# Настройка Nginx
echo "🌐 Настройка Nginx..."
cat > /etc/nginx/sites-available/project << 'EOF'
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static {
        alias /var/www/project/static;
    }
}
EOF

ln -s /etc/nginx/sites-available/project /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# Настройка Supervisor для управления процессами
echo "⚙️ Настройка Supervisor..."

# Конфигурация для веб-приложения
cat > /etc/supervisor/conf.d/webapp.conf << 'EOF'
[program:webapp]
command=/var/www/project/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:5000 admin:app
directory=/var/www/project
user=appuser
autostart=true
autorestart=true
stderr_logfile=/var/log/webapp.err.log
stdout_logfile=/var/log/webapp.out.log
EOF

# Конфигурация для Telegram-бота
cat > /etc/supervisor/conf.d/telegram_bot.conf << 'EOF'
[program:telegram_bot]
command=/var/www/project/venv/bin/python bot.py
directory=/var/www/project
user=appuser
autostart=true
autorestart=true
stderr_logfile=/var/log/telegram_bot.err.log
stdout_logfile=/var/log/telegram_bot.out.log
EOF

# Перезапуск Supervisor
supervisorctl reread
supervisorctl update
supervisorctl start webapp
supervisorctl start telegram_bot

# Настройка файрвола
echo "🔥 Настройка файрвола..."
ufw allow 22
ufw allow 80
ufw allow 443
ufw --force enable

# Настройка SSL (Let's Encrypt)
echo "🔒 Установка SSL сертификата..."
apt install -y certbot python3-certbot-nginx

echo "✅ Настройка сервера завершена!"
echo "📝 Следующие шаги:"
echo "1. Настройте домен (если есть)"
echo "2. Получите SSL сертификат: certbot --nginx -d your-domain.com"
echo "3. Настройте переменные окружения в /var/www/project/.env"
echo "4. Проверьте логи: supervisorctl status" 