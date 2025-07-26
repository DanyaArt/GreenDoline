#!/usr/bin/env python3
"""
Render Hosting Setup for Telegram Bot
Настройка хостинга Telegram бота на Render
"""

import os
import json

def create_render_files():
    """Create files needed for Render deployment"""
    
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
      - key: WEBHOOK_URL
        value: https://your-app-name.onrender.com/webhook
    healthCheckPath: /
    autoDeploy: true
    plan: free
"""
    
    with open('render.yaml', 'w', encoding='utf-8') as f:
        f.write(render_yaml)
    
    # Requirements for Render
    requirements_content = """flask==2.3.3
python-telegram-bot==20.6
requests==2.31.0
python-dotenv==1.0.0
gunicorn==21.2.0
"""
    
    with open('requirements.txt', 'w') as f:
        f.write(requirements_content)
    
    # Bot for Render (with Flask)
    bot_render_content = """import telebot
from datetime import datetime
import time
from telebot import types
import sqlite3
import hashlib
import os
from flask import Flask, request, jsonify
import requests

# Flask app for Render
app = Flask(__name__)

def hash_password(password):
    return hashlib.sha256(password.encode('utf-8')).hexdigest()

# Настройка подключения к базе данных
def init_db():
    conn = sqlite3.connect('users.db', check_same_thread=False)
    cursor = conn.cursor()
    
    cursor.execute('''CREATE TABLE IF NOT EXISTS users
             (id INTEGER PRIMARY KEY AUTOINCREMENT,
             user_id INTEGER UNIQUE,
             first_name TEXT,
             last_name TEXT,
             middle_name TEXT,
             phone TEXT,
             school TEXT,
             class TEXT,
             register_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
             password_hash TEXT)''')
    
    # Create messages table if not exists
    cursor.execute('''CREATE TABLE IF NOT EXISTS messages
             (id INTEGER PRIMARY KEY AUTOINCREMENT,
             user_id INTEGER,
             sender TEXT,
             message TEXT,
             timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP)''')
    
    conn.commit()
    return conn, cursor

# Инициализация базы данных
conn, cursor = init_db()

# Получаем токен бота из переменной окружения
BOT_TOKEN = os.environ.get('BOT_TOKEN', '7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w')
bot = telebot.TeleBot(BOT_TOKEN)

def get_main_menu():
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    markup.add(types.KeyboardButton("Войти"), types.KeyboardButton("Зарегистрироваться"))
    return markup

# Команда /start
@bot.message_handler(commands=['start'])
def start(message):
    updated = False
    with sqlite3.connect('users.db', check_same_thread=False) as conn:
        cursor = conn.cursor()
        if message.from_user.username:
            username = message.from_user.username.lstrip('@')
            cursor.execute(
                "UPDATE users SET user_id=? WHERE tg=? AND (user_id IS NULL OR user_id='')",
                (message.from_user.id, username)
            )
            if cursor.rowcount > 0:
                updated = True
        if not updated and message.contact:
            cursor.execute(
                "UPDATE users SET user_id=? WHERE phone=? AND (user_id IS NULL OR user_id='')",
                (message.from_user.id, message.contact.phone_number)
            )
            if cursor.rowcount > 0:
                updated = True
        conn.commit()
    print(f"[DEBUG] user_id update on /start: username={message.from_user.username}, id={message.from_user.id}, updated={updated}")
    msg = bot.send_message(
        message.chat.id,
        "Выберите действие:",
        reply_markup=get_main_menu()
    )
    bot.register_next_step_handler(msg, process_start_choice)

def process_start_choice(message):
    choice = message.text.strip().lower()
    if "войти" in choice:
        msg = bot.send_message(message.chat.id, "Введите ваш номер телефона для входа:", reply_markup=types.ReplyKeyboardRemove())
        bot.register_next_step_handler(msg, process_login_phone)
    elif "зарегистр" in choice:
        start_registration(message)
    else:
        msg = bot.send_message(message.chat.id, "Пожалуйста, выберите 'Войти' или 'Зарегистрироваться'.")
        bot.register_next_step_handler(msg, process_start_choice)

def process_login_phone(message):
    if message.text == 'Отмена':
        return start(message)
    with sqlite3.connect('users.db', check_same_thread=False) as conn:
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE phone = ?", (message.text.strip(),))
    user = cursor.fetchone()
    if user:
        markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
        markup.add(types.KeyboardButton('Отмена'))
        msg = bot.send_message(message.chat.id, "Введите ваш пароль:", reply_markup=markup)
        bot.register_next_step_handler(msg, lambda m: process_login_password_by_phone(m, user))
    else:
        bot.send_message(message.chat.id, "Пользователь с таким номером не найден. Зарегистрируйтесь через сайт или бота.")
        start(message)

def process_login_password_by_phone(message, user):
    if message.text == 'Отмена':
        return start(message)
    password = message.text
    password_hash = hash_password(password)
    if password_hash == user['password_hash']:
        # Обновляем user_id для этого пользователя
        with sqlite3.connect('users.db', check_same_thread=False) as conn:
            cursor = conn.cursor()
            cursor.execute("UPDATE users SET user_id=? WHERE phone=?", (message.from_user.id, user['phone']))
            conn.commit()
        bot.send_message(message.chat.id, "✅ Вход выполнен успешно!", reply_markup=types.ReplyKeyboardRemove())
        show_menu(message)
    else:
        markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
        markup.add(types.KeyboardButton('Отмена'))
        msg = bot.send_message(message.chat.id, "❌ Неверный пароль. Попробуйте ещё раз:", reply_markup=markup)
        bot.register_next_step_handler(msg, lambda m: process_login_password_by_phone(m, user))

# Процесс регистрации
def start_registration(message):
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    markup.add(types.KeyboardButton('Отмена'))
    msg = bot.send_message(message.chat.id, "Давайте зарегистрируемся. Введите вашу фамилию:", reply_markup=markup)
    bot.register_next_step_handler(msg, process_last_name)

def process_last_name(message):
    if message.text == 'Отмена':
        return start(message)
    last_name = message.text
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    markup.add(types.KeyboardButton('Отмена'))
    msg = bot.send_message(message.chat.id, "Теперь введите ваше имя:", reply_markup=markup)
    bot.register_next_step_handler(msg, lambda m: process_first_name(m, last_name))

def process_first_name(message, last_name):
    if message.text == 'Отмена':
        return start(message)
    first_name = message.text
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    markup.add(types.KeyboardButton('Отмена'))
    msg = bot.send_message(message.chat.id, "Введите ваше отчество:", reply_markup=markup)
    bot.register_next_step_handler(msg, lambda m: process_middle_name(m, last_name, first_name))

def process_middle_name(message, last_name, first_name):
    if message.text == 'Отмена':
        return start(message)
    middle_name = message.text
    
    keyboard = types.ReplyKeyboardMarkup(one_time_keyboard=True, resize_keyboard=True)
    reg_button = types.KeyboardButton(text="📱 Отправить номер телефона", request_contact=True)
    keyboard.add(reg_button)
    keyboard.add(types.KeyboardButton('Отмена'))
    
    msg = bot.send_message(message.chat.id, "Отправьте ваш номер телефона:", reply_markup=keyboard)
    bot.register_next_step_handler(msg, lambda m: process_phone(m, last_name, first_name, middle_name))

def process_phone(message, last_name, first_name, middle_name):
    if message.text == 'Отмена':
        return start(message)
    if message.contact:
        phone = message.contact.phone_number
    else:
        phone = message.text
    # Проверка уникальности телефона
    with sqlite3.connect('users.db', check_same_thread=False) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT 1 FROM users WHERE phone = ?", (phone,))
        exists = cursor.fetchone()
    if exists:
        markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
        markup.add(types.KeyboardButton('Отмена'))
        msg = bot.send_message(message.chat.id, "Пользователь с таким номером уже существует. Пожалуйста, используйте другой номер или войдите в свой аккаунт.", reply_markup=markup)
        return bot.register_next_step_handler(msg, lambda m: process_phone(m, last_name, first_name, middle_name))
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    markup.add(types.KeyboardButton('Отмена'))
    msg = bot.send_message(message.chat.id, "Введите номер вашей школы:", reply_markup=markup)
    bot.register_next_step_handler(msg, lambda m: process_school(m, last_name, first_name, middle_name, phone))

def process_school(message, last_name, first_name, middle_name, phone):
    if message.text == 'Отмена':
        return start(message)
    school = message.text.strip()
    # Проверка: школа должна быть числом от 1 до 9999
    if not school.isdigit() or not (1 <= int(school) <= 9999):
        markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
        markup.add(types.KeyboardButton('Отмена'))
        msg = bot.send_message(message.chat.id, "Пожалуйста, введите номер школы цифрами (от 1 до 9999):", reply_markup=markup)
        return bot.register_next_step_handler(msg, lambda m: process_school(m, last_name, first_name, middle_name, phone))
    # Proceed to class selection
    markup = types.ReplyKeyboardMarkup(row_width=3, resize_keyboard=True)
    buttons = [types.KeyboardButton(str(i)) for i in range(1, 12)]
    markup.add(*buttons)
    markup.add(types.KeyboardButton('Отмена'))
    msg = bot.send_message(message.chat.id, "Выберите ваш класс:", reply_markup=markup)
    bot.register_next_step_handler(msg, lambda m: process_class(m, last_name, first_name, middle_name, phone, school))

def process_class(message, last_name, first_name, middle_name, phone, school):
    if message.text == 'Отмена':
        return start(message)
    class_num = message.text.strip()
    # Проверка: класс только от 1 до 11
    if not class_num.isdigit() or not (1 <= int(class_num) <= 11):
        markup = types.ReplyKeyboardMarkup(row_width=3, resize_keyboard=True)
        buttons = [types.KeyboardButton(str(i)) for i in range(1, 12)]
        markup.add(*buttons)
        markup.add(types.KeyboardButton('Отмена'))
        msg = bot.send_message(message.chat.id, "Пожалуйста, выберите класс от 1 до 11:", reply_markup=markup)
        return bot.register_next_step_handler(msg, lambda m: process_class(m, last_name, first_name, middle_name, phone, school))
    # После класса — запросить пароль
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    markup.add(types.KeyboardButton('Отмена'))
    msg = bot.send_message(message.chat.id, "Придумайте пароль для входа:", reply_markup=markup)
    bot.register_next_step_handler(msg, lambda m: process_password1(m, last_name, first_name, middle_name, phone, school, class_num))

def process_password1(message, last_name, first_name, middle_name, phone, school, class_num):
    if message.text == 'Отмена':
        return start(message)
    password1 = message.text
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    markup.add(types.KeyboardButton('Отмена'))
    msg = bot.send_message(message.chat.id, "Повторите пароль:", reply_markup=markup)
    bot.register_next_step_handler(msg, lambda m: process_password2(m, last_name, first_name, middle_name, phone, school, class_num, password1))

def process_password2(message, last_name, first_name, middle_name, phone, school, class_num, password1):
    if message.text == 'Отмена':
        return start(message)
    password2 = message.text
    if password1 != password2:
        markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
        markup.add(types.KeyboardButton('Отмена'))
        msg = bot.send_message(message.chat.id, "Пароли не совпадают! Попробуйте снова. Придумайте пароль:", reply_markup=markup)
        return bot.register_next_step_handler(msg, lambda m: process_password1(m, last_name, first_name, middle_name, phone, school, class_num))
    password_hash = hash_password(password1)
    try:
        print('Попытка вставки пользователя в БД...')
        with sqlite3.connect('users.db', check_same_thread=False) as conn:
            cursor = conn.cursor()
            
            # Проверяем, существует ли пользователь с таким user_id
            cursor.execute("SELECT 1 FROM users WHERE user_id = ?", (message.from_user.id,))
            existing_user = cursor.fetchone()
            
            if existing_user:
                # Пользователь уже существует, обновляем данные
                cursor.execute(
                    "UPDATE users SET first_name=?, last_name=?, middle_name=?, phone=?, school=?, class=?, password_hash=? WHERE user_id=?",
                    (first_name, last_name, middle_name, phone, school, class_num, password_hash, message.from_user.id)
                )
                print('Данные пользователя обновлены!')
                bot.send_message(message.chat.id, "✅ Данные обновлены!", reply_markup=types.ReplyKeyboardRemove())
            else:
                # Новый пользователь, вставляем
                cursor.execute(
                    "INSERT INTO users (user_id, first_name, last_name, middle_name, phone, school, class, register_date, password_hash) VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'), ?)",
                    (message.from_user.id, first_name, last_name, middle_name, phone, school, class_num, password_hash)
                )
                print('Пользователь успешно добавлен!')
                bot.send_message(message.chat.id, "✅ Регистрация завершена!", reply_markup=types.ReplyKeyboardRemove())
            
            conn.commit()
            show_menu(message)
    except Exception as e:
        import traceback
        print('Ошибка при регистрации:', traceback.format_exc())
        bot.send_message(message.chat.id, f"Ошибка при регистрации: {e}")

# Главное меню
def show_menu(message):
    markup = types.ReplyKeyboardMarkup(row_width=2, resize_keyboard=True)
    btn_profile = types.KeyboardButton("👤 Мой профиль")
    btn_edit = types.KeyboardButton("✏️ Изменить данные")
    btn_delete = types.KeyboardButton("🗑️ Удалить профиль")
    markup.add(btn_profile, btn_edit, btn_delete)
    
    bot.send_message(message.chat.id, "Главное меню:", reply_markup=markup)

# Просмотр профиля
@bot.message_handler(func=lambda message: message.text == "👤 Мой профиль")
def show_profile(message):
    cursor.execute("SELECT * FROM users WHERE user_id = ?", (message.from_user.id,))
    user = cursor.fetchone()
    if user:
        # Форматирование даты регистрации
        register_date = user[7]
        if register_date and str(register_date).lower() != 'none':
            try:
                if isinstance(register_date, str):
                    dt = datetime.strptime(register_date, "%Y-%m-%d %H:%M:%S")
                else:
                    dt = datetime.fromtimestamp(time.mktime(register_date))
                register_date = dt.strftime("%d.%m.%Y %H:%M")
            except:
                register_date = "неизвестно"
        else:
            register_date = "не указана"
        # Обработка школы
        school = user[5]
        if not school or str(school).lower() == 'none':
            school = "не указана"
        # ФИО: фамилия, имя, отчество
        profile_text = f"""
📌 <b>Ваш профиль</b>:

👤 <b>ФИО:</b> {user[3]} {user[2]} {user[8]}
📞 <b>Телефон:</b> {user[4]}
🏫 <b>Школа:</b> {school}
🎒 <b>Класс:</b> {user[6]}
📅 <b>Дата регистрации:</b> {register_date}
        """
        bot.send_message(message.chat.id, profile_text, parse_mode='HTML')
    else:
        bot.send_message(message.chat.id, "Профиль не найден. Нажмите /start для регистрации")

# Редактирование профиля
@bot.message_handler(func=lambda message: message.text == "✏️ Изменить данные")
def edit_profile(message):
    markup = types.ReplyKeyboardMarkup(row_width=2)
    btn1 = types.KeyboardButton("Изменить имя")
    btn2 = types.KeyboardButton("Изменить телефон")
    btn3 = types.KeyboardButton("Изменить школу")
    btn4 = types.KeyboardButton("Изменить класс")
    btn_back = types.KeyboardButton("↩️ Назад")
    markup.add(btn1, btn2, btn3, btn4, btn_back)
    
    bot.send_message(message.chat.id, "Что вы хотите изменить?", reply_markup=markup)

@bot.message_handler(func=lambda message: message.text.startswith("Изменить"))
def select_field_to_edit(message):
    field = message.text.replace("Изменить ", "").lower()
    
    if field == "телефон":
        keyboard = types.ReplyKeyboardMarkup(one_time_keyboard=True)
        reg_button = types.KeyboardButton(text="📱 Отправить номер", request_contact=True)
        keyboard.add(reg_button)
        msg = bot.send_message(message.chat.id, "Отправьте новый номер телефона:", reply_markup=keyboard)
    else:
        msg = bot.send_message(message.chat.id, f"Введите новое значение для {field}:",
                             reply_markup=types.ReplyKeyboardRemove())
    
    bot.register_next_step_handler(msg, lambda m: update_profile(m, field))

def update_profile(message, field):
    try:
        new_value = message.contact.phone_number if field == "телефон" and message.contact else message.text
        user_id = message.from_user.id
        db_field = {
            "имя": "first_name",
            "отчество": "middle_name",
            "телефон": "phone",
            "школу": "school",
            "класс": "class"
        }.get(field)
        # Проверки для школы и класса
        if db_field == "school":
            if not new_value.isdigit() or not (1 <= int(new_value) <= 9999):
                msg = bot.send_message(message.chat.id, "Пожалуйста, введите номер школы цифрами (от 1 до 9999):")
                return bot.register_next_step_handler(msg, lambda m: update_profile(m, field))
        if db_field == "class":
            if not new_value.isdigit() or not (1 <= int(new_value) <= 11):
                msg = bot.send_message(message.chat.id, "Пожалуйста, выберите класс от 1 до 11:")
                return bot.register_next_step_handler(msg, lambda m: update_profile(m, field))
        if db_field:
            cursor.execute(f"UPDATE users SET {db_field} = ? WHERE user_id = ?", (new_value, user_id))
            conn.commit()
            bot.send_message(message.chat.id, f"✅ {field.capitalize()} успешно изменен!")
            show_menu(message)
    except Exception as e:
        bot.send_message(message.chat.id, f"Ошибка при обновлении: {str(e)}")

# Удаление профиля
@bot.message_handler(func=lambda message: message.text == "🗑️ Удалить профиль")
def confirm_delete(message):
    markup = types.ReplyKeyboardMarkup(row_width=2)
    btn_yes = types.KeyboardButton("✅ Да, удалить")
    btn_no = types.KeyboardButton("❌ Нет, отменить")
    markup.add(btn_yes, btn_no)
    
    bot.send_message(message.chat.id, "Вы уверены, что хотите удалить свой профиль? Все данные будут безвозвратно удалены.", 
                    reply_markup=markup)

@bot.message_handler(func=lambda message: message.text == "✅ Да, удалить")
def delete_profile(message):
    try:
        cursor.execute("DELETE FROM users WHERE user_id = ?", (message.from_user.id,))
        conn.commit()
        bot.send_message(message.chat.id, "Ваш профиль удален. Для новой регистрации нажмите /start", 
                        reply_markup=types.ReplyKeyboardRemove())
    except Exception as e:
        bot.send_message(message.chat.id, f"Ошибка при удалении: {str(e)}")

# Навигация назад
@bot.message_handler(func=lambda message: message.text in ["↩️ Назад", "❌ Нет, отменить"])
def back_to_menu(message):
    show_menu(message)

# Сохранение сообщений пользователя
@bot.message_handler(func=lambda m: m.text and not m.text.startswith('/') and m.text not in [
    "👤 Мой профиль", "✏️ Изменить данные", "🗑️ Удалить профиль",
    "Изменить имя", "Изменить телефон", "Изменить школу", "Изменить класс",
    "↩️ Назад", "❌ Нет, отменить", "✅ Да, удалить", "Отмена"
])
def save_user_message(message):
    try:
        with sqlite3.connect('users.db', check_same_thread=False) as conn:
            cursor = conn.cursor()
            cursor.execute('INSERT INTO messages (user_id, sender, message) VALUES (?, ?, ?)', (message.from_user.id, 'user', message.text))
            conn.commit()
    except Exception as e:
        print(f'Ошибка при сохранении сообщения пользователя: {e}')

# Flask routes for Render
@app.route('/')
def home():
    return jsonify({
        'status': 'online',
        'service': 'Telegram Bot on Render',
        'uptime': '24/7',
        'message': 'Bot is running on Render!'
    })

@app.route('/webhook', methods=['POST'])
def webhook():
    if request.method == 'POST':
        bot.process_new_updates([telebot.types.Update.de_json(request.stream.read().decode("utf-8"))])
        return 'ok', 200

@app.route('/status')
def status():
    return jsonify({
        'bot_status': 'running',
        'database': 'connected',
        'users_count': len(cursor.execute("SELECT * FROM users").fetchall())
    })

@app.route('/set_webhook')
def set_webhook():
    try:
        webhook_url = request.args.get('url', 'https://your-app-name.onrender.com/webhook')
        url = f"https://api.telegram.org/bot{BOT_TOKEN}/setWebhook"
        data = {"url": webhook_url}
        response = requests.post(url, json=data)
        return jsonify(response.json())
    except Exception as e:
        return jsonify({'error': str(e)})

# Render specific configuration
if __name__ == '__main__':
    print("Bot starting on Render...")
    # Set webhook for Render
    try:
        webhook_url = os.environ.get('WEBHOOK_URL', 'https://your-app-name.onrender.com/webhook')
        url = f"https://api.telegram.org/bot{BOT_TOKEN}/setWebhook"
        data = {"url": webhook_url}
        response = requests.post(url, json=data)
        print(f"Webhook set: {response.json()}")
    except Exception as e:
        print(f"Error setting webhook: {e}")
    
    # Start Flask app
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
"""
    
    with open('bot_render.py', 'w', encoding='utf-8') as f:
        f.write(bot_render_content)
    
    # Render deployment guide
    deployment_guide = """# Render Deployment Guide
# Руководство по деплою на Render

## 🚀 Quick Setup (Быстрая настройка)

### 1. Create GitHub Repository (Создайте GitHub репозиторий)
1. Go to GitHub.com
2. Create new repository
3. Upload these files:
   - bot_render.py (rename to bot.py)
   - requirements.txt
   - render.yaml
   - users.db (if exists)

### 2. Deploy on Render (Деплой на Render)
1. Go to https://render.com
2. Sign up with GitHub
3. Click "New +" → "Web Service"
4. Connect your GitHub repository
5. Configure:
   - Name: telegram-bot
   - Environment: Python
   - Build Command: pip install -r requirements.txt
   - Start Command: python bot.py

### 3. Set Environment Variables (Настройка переменных)
In Render dashboard, add:
- BOT_TOKEN = 7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w
- PORT = 5000
- DATABASE_URL = sqlite:///users.db
- WEBHOOK_URL = https://your-app-name.onrender.com/webhook

### 4. Deploy (Деплой)
1. Click "Create Web Service"
2. Wait for deployment
3. Copy your app URL

### 5. Set Webhook (Настройка вебхука)
After deployment, visit:
https://your-app-name.onrender.com/set_webhook

## 📁 File Structure (Структура файлов)

```
your-repo/
├── bot.py              # Main bot application
├── requirements.txt    # Python dependencies
├── render.yaml         # Render configuration
└── users.db           # SQLite database
```

## 🔧 Configuration (Конфигурация)

### Environment Variables (Переменные окружения)
- BOT_TOKEN: Your Telegram bot token
- WEBHOOK_URL: https://your-app-name.onrender.com/webhook
- PORT: 5000 (Render will set this)
- DATABASE_URL: sqlite:///users.db

### Webhook Setup (Настройка вебхука)
After deployment, set webhook:
```python
import requests

def set_webhook():
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/setWebhook"
    webhook_url = "https://your-app-name.onrender.com/webhook"
    data = {"url": webhook_url}
    response = requests.post(url, json=data)
    print(response.json())
```

## 🎯 Testing (Тестирование)

### Online Test (Онлайн тестирование)
1. Visit: https://your-app-name.onrender.com
2. Should see bot status page
3. Test bot in Telegram

## 🆘 Troubleshooting (Устранение проблем)

### Bot not responding:
- Check BOT_TOKEN in environment variables
- Verify webhook URL is correct
- Check Render logs

### 500 Error:
- Check bot.py syntax
- Verify requirements.txt
- Check Render build logs

### SSL Issues:
- Render provides SSL automatically
- Update webhook URL to HTTPS

## 📊 Render Features (Возможности Render)

✅ **Free SSL Certificate** - Автоматический SSL  
✅ **Custom Domain** - Свой домен  
✅ **Python Support** - Поддержка Python  
✅ **SQLite Database** - Встроенная база данных  
✅ **24/7 Uptime** - Работает круглосуточно  
✅ **Auto Deploy** - Автоматический деплой  
✅ **Logs & Monitoring** - Логи и мониторинг  

## 🎉 Success! (Успех!)

After setup, your bot will work 24/7 even when your PC is off!
После настройки ваш бот будет работать 24/7 даже когда ПК выключен!
"""
    
    with open('RENDER_GUIDE.md', 'w', encoding='utf-8') as f:
        f.write(deployment_guide)

def main():
    print("🌐 Creating Render hosting files...")
    print("=" * 50)
    
    # Create deployment files
    create_render_files()
    
    print("✅ Render files created!")
    print()
    print("📁 Files created:")
    print("- render.yaml (Render configuration)")
    print("- bot_render.py (Bot for Render)")
    print("- requirements.txt (Python dependencies)")
    print("- RENDER_GUIDE.md (Detailed guide)")
    print()
    print("🚀 Next Steps:")
    print("1. Read: RENDER_GUIDE.md")
    print("2. Upload to GitHub")
    print("3. Connect to Render")
    print("4. Set environment variables")
    print("5. Deploy")
    print()
    print("🌍 Your bot will work 24/7 on Render!")

if __name__ == "__main__":
    main() 