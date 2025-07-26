#!/usr/bin/env python3
"""
AlwaysData Hosting Setup for Telegram Bot
Настройка хостинга Telegram бота на AlwaysData
"""

import os
import json

def create_alwaysdata_files():
    """Create files needed for AlwaysData deployment"""
    
    # WSGI file for AlwaysData
    wsgi_content = """#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os

# Add current directory to Python path
sys.path.insert(0, os.path.dirname(__file__))

# Import Flask app
from bot import app

# AlwaysData specific configuration
if __name__ == "__main__":
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))
"""
    
    with open('passenger_wsgi.py', 'w', encoding='utf-8') as f:
        f.write(wsgi_content)
    
    # Requirements for AlwaysData
    requirements_content = """flask==2.3.3
python-telegram-bot==20.6
requests==2.31.0
python-dotenv==1.0.0
gunicorn==21.2.0
"""
    
    with open('requirements.txt', 'w') as f:
        f.write(requirements_content)
    
    # AlwaysData configuration
    alwaysdata_config = """# AlwaysData Configuration
# Конфигурация для AlwaysData

[Web]
Framework = Python
Version = 3.11
StartupFile = passenger_wsgi.py

[Environment]
BOT_TOKEN = 7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w
WEBHOOK_URL = https://your-domain.alwaysdata.net
PORT = 5000
DATABASE_URL = sqlite:///users.db
ADMIN_USERS = 123456789,987654321
LOG_LEVEL = INFO

[Database]
Type = SQLite
File = users.db

[SSL]
Enabled = true
AutoRedirect = true
"""
    
    with open('alwaysdata.conf', 'w', encoding='utf-8') as f:
        f.write(alwaysdata_config)
    
    # Startup script
    startup_script = """#!/bin/bash
# AlwaysData Startup Script

echo "Starting Telegram Bot on AlwaysData..."

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export BOT_TOKEN="7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w"
export PORT=5000
export DATABASE_URL="sqlite:///users.db"

# Start the application
python passenger_wsgi.py
"""
    
    with open('startup.sh', 'w') as f:
        f.write(startup_script)
    
    # Windows batch file for local testing
    windows_startup = """@echo off
echo Testing AlwaysData configuration locally...
echo.

echo Installing dependencies...
pip install -r requirements.txt

echo.
echo Setting environment variables...
set BOT_TOKEN=7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w
set PORT=5000
set DATABASE_URL=sqlite:///users.db

echo.
echo Starting application...
python passenger_wsgi.py

pause
"""
    
    with open('test_alwaysdata.bat', 'w') as f:
        f.write(windows_startup)
    
    # AlwaysData deployment guide
    deployment_guide = """# AlwaysData Deployment Guide
# Руководство по деплою на AlwaysData

## 🚀 Quick Setup (Быстрая настройка)

### 1. Upload Files (Загрузка файлов)
1. Go to AlwaysData control panel
2. Navigate to "Web" → "Sites"
3. Create new site or use existing
4. Upload these files to your site directory:
   - bot.py
   - passenger_wsgi.py
   - requirements.txt
   - users.db (if exists)

### 2. Configure Environment (Настройка окружения)
1. Go to "Environment" → "Variables"
2. Add these variables:
   - BOT_TOKEN = 7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w
   - PORT = 5000
   - DATABASE_URL = sqlite:///users.db

### 3. Set Python Version (Установка версии Python)
1. Go to "Environment" → "Python"
2. Select Python 3.11
3. Set startup file: passenger_wsgi.py

### 4. Configure Domain (Настройка домена)
1. Go to "Domains"
2. Add your domain or use alwaysdata.net subdomain
3. Point it to your web site

### 5. Enable SSL (Включение SSL)
1. Go to "Web" → "SSL"
2. Enable automatic SSL certificate
3. Set redirect from HTTP to HTTPS

## 📁 File Structure (Структура файлов)

```
your-site/
├── bot.py              # Main bot application
├── passenger_wsgi.py   # WSGI entry point
├── requirements.txt    # Python dependencies
├── users.db           # SQLite database
├── alwaysdata.conf    # Configuration file
└── startup.sh         # Startup script
```

## 🔧 Configuration (Конфигурация)

### Environment Variables (Переменные окружения)
- BOT_TOKEN: Your Telegram bot token
- WEBHOOK_URL: https://your-domain.alwaysdata.net
- PORT: 5000 (AlwaysData will set this)
- DATABASE_URL: sqlite:///users.db

### Webhook Setup (Настройка вебхука)
After deployment, set webhook:
```python
import requests

def set_webhook():
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/setWebhook"
    webhook_url = "https://your-domain.alwaysdata.net/webhook"
    data = {"url": webhook_url}
    response = requests.post(url, json=data)
    print(response.json())
```

## 🎯 Testing (Тестирование)

### Local Test (Локальное тестирование)
Run: test_alwaysdata.bat

### Online Test (Онлайн тестирование)
1. Visit: https://your-domain.alwaysdata.net
2. Should see bot status page
3. Test bot in Telegram

## 🆘 Troubleshooting (Устранение проблем)

### Bot not responding:
- Check BOT_TOKEN in environment variables
- Verify webhook URL is correct
- Check AlwaysData logs

### 500 Error:
- Check passenger_wsgi.py syntax
- Verify Python version is 3.11
- Check requirements.txt

### SSL Issues:
- Enable SSL in AlwaysData control panel
- Update webhook URL to HTTPS

## 📊 AlwaysData Features (Возможности AlwaysData)

✅ **Free SSL Certificate** - Автоматический SSL  
✅ **Custom Domain** - Свой домен  
✅ **Python 3.11** - Поддержка Python  
✅ **SQLite Database** - Встроенная база данных  
✅ **24/7 Uptime** - Работает круглосуточно  
✅ **Logs & Monitoring** - Логи и мониторинг  

## 🎉 Success! (Успех!)

After setup, your bot will work 24/7 even when your PC is off!
После настройки ваш бот будет работать 24/7 даже когда ПК выключен!
"""
    
    with open('ALWAYSDATA_GUIDE.md', 'w', encoding='utf-8') as f:
        f.write(deployment_guide)

def main():
    print("🌐 Creating AlwaysData hosting files...")
    print("=" * 50)
    
    # Create deployment files
    create_alwaysdata_files()
    
    print("✅ AlwaysData files created!")
    print()
    print("📁 Files created:")
    print("- passenger_wsgi.py (WSGI entry point)")
    print("- requirements.txt (Python dependencies)")
    print("- alwaysdata.conf (Configuration)")
    print("- startup.sh (Startup script)")
    print("- test_alwaysdata.bat (Local testing)")
    print("- ALWAYSDATA_GUIDE.md (Detailed guide)")
    print()
    print("🚀 Next Steps:")
    print("1. Read: ALWAYSDATA_GUIDE.md")
    print("2. Upload files to AlwaysData")
    print("3. Configure environment variables")
    print("4. Set webhook URL")
    print()
    print("🌍 Your bot will work 24/7 on AlwaysData!")

if __name__ == "__main__":
    main() 