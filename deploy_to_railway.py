#!/usr/bin/env python3
"""
Deploy to Railway - Free Hosting
Деплой на Railway - бесплатный хостинг
"""

import os
import json
import subprocess
import sys

def create_railway_files():
    """Create files needed for Railway deployment"""
    
    # Railway configuration
    railway_json = {
        "build": {
            "builder": "nixpacks"
        },
        "deploy": {
            "startCommand": "python bot.py",
            "healthcheckPath": "/",
            "healthcheckTimeout": 300,
            "restartPolicyType": "ON_FAILURE",
            "restartPolicyMaxRetries": 10
        }
    }
    
    with open('railway.json', 'w') as f:
        json.dump(railway_json, f, indent=2)
    
    # Procfile for Railway
    procfile_content = """web: python bot.py
bot: python bot.py"""
    
    with open('Procfile', 'w') as f:
        f.write(procfile_content)
    
    # Runtime.txt
    with open('runtime.txt', 'w') as f:
        f.write('python-3.11.8')
    
    # Requirements for Railway
    requirements_content = """flask==2.3.3
python-telegram-bot==20.6
sqlite3
requests==2.31.0
python-dotenv==1.0.0
gunicorn==21.2.0"""
    
    with open('requirements.txt', 'w') as f:
        f.write(requirements_content)
    
    # Environment variables template
    env_template = """# Railway Environment Variables
# Copy this to Railway dashboard

BOT_TOKEN=7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w
WEBHOOK_URL=https://your-app-name.railway.app
PORT=5000
DATABASE_URL=sqlite:///users.db
ADMIN_USERS=123456789,987654321
LOG_LEVEL=INFO"""
    
    with open('.env.example', 'w') as f:
        f.write(env_template)
    
    # Railway deployment script
    deploy_script = """#!/bin/bash
# Railway Deployment Script

echo "Deploying to Railway..."

# Install Railway CLI
npm install -g @railway/cli

# Login to Railway
railway login

# Initialize project
railway init

# Set environment variables
railway variables set BOT_TOKEN=7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w
railway variables set PORT=5000
railway variables set DATABASE_URL=sqlite:///users.db

# Deploy
railway up

echo "Deployment completed!"
echo "Your app is available at: https://your-app-name.railway.app"
"""
    
    with open('deploy_railway.sh', 'w') as f:
        f.write(deploy_script)
    
    # Windows batch file
    deploy_bat = """@echo off
echo Deploying to Railway...
echo.

echo Step 1: Install Railway CLI
npm install -g @railway/cli

echo.
echo Step 2: Login to Railway
railway login

echo.
echo Step 3: Initialize project
railway init

echo.
echo Step 4: Set environment variables
railway variables set BOT_TOKEN=7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w
railway variables set PORT=5000
railway variables set DATABASE_URL=sqlite:///users.db

echo.
echo Step 5: Deploy
railway up

echo.
echo Deployment completed!
echo Your app is available at: https://your-app-name.railway.app
pause
"""
    
    with open('deploy_railway.bat', 'w') as f:
        f.write(deploy_bat)

def create_render_files():
    """Create files for Render deployment"""
    
    # Render configuration
    render_yaml = """services:
  - type: web
    name: telegram-bot
    env: python
    buildCommand: pip install -r requirements.txt
    startCommand: python bot.py
    envVars:
      - key: BOT_TOKEN
        value: 7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w
      - key: PORT
        value: 5000
      - key: DATABASE_URL
        value: sqlite:///users.db
    healthCheckPath: /
    autoDeploy: true"""
    
    with open('render.yaml', 'w') as f:
        f.write(render_yaml)

def create_heroku_files():
    """Create files for Heroku deployment"""
    
    # Heroku Procfile
    heroku_procfile = """web: python bot.py
bot: python bot.py"""
    
    with open('Procfile.heroku', 'w') as f:
        f.write(heroku_procfile)
    
    # Heroku app.json
    app_json = {
        "name": "Telegram Bot",
        "description": "Telegram bot with web interface",
        "repository": "https://github.com/yourusername/your-repo",
        "logo": "",
        "keywords": ["python", "telegram", "bot", "flask"],
        "env": {
            "BOT_TOKEN": {
                "description": "Telegram Bot Token",
                "value": "7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w"
            },
            "PORT": {
                "description": "Port for web server",
                "value": "5000"
            }
        },
        "formation": {
            "web": {
                "quantity": 1,
                "size": "free"
            }
        },
        "buildpacks": [
            {
                "url": "heroku/python"
            }
        ]
    }
    
    with open('app.json', 'w') as f:
        json.dump(app_json, f, indent=2)

def main():
    print("🌐 Creating deployment files for external hosting...")
    print("=" * 50)
    
    # Create deployment files
    create_railway_files()
    create_render_files()
    create_heroku_files()
    
    print("✅ Deployment files created!")
    print()
    print("📁 Files created:")
    print("- railway.json, Procfile, runtime.txt (Railway)")
    print("- render.yaml (Render)")
    print("- app.json, Procfile.heroku (Heroku)")
    print("- deploy_railway.bat (Windows deployment)")
    print("- .env.example (Environment variables)")
    print()
    print("🚀 Quick Deploy Options:")
    print()
    print("1. Railway (Recommended - Free):")
    print("   - Run: deploy_railway.bat")
    print("   - Or: npm install -g @railway/cli && railway up")
    print()
    print("2. Render (Free):")
    print("   - Upload to GitHub")
    print("   - Connect to Render.com")
    print("   - Auto-deploy on push")
    print()
    print("3. Heroku (Free tier ended):")
    print("   - heroku create")
    print("   - git push heroku main")
    print()
    print("📋 Before deploying:")
    print("- Update BOT_TOKEN in .env.example")
    print("- Set up GitHub repository")
    print("- Configure webhook URL")
    print()
    print("🌍 Your bot will work 24/7 after deployment!")

if __name__ == "__main__":
    main() 