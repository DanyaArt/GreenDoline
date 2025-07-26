# Профориентационный тест - Веб-сайт и Telegram-бот

## Описание
Система профориентационного тестирования для школьников с веб-интерфейсом и Telegram-ботом.

## Функции
- Регистрация и авторизация пользователей
- Прохождение профориентационного теста
- Админ-панель для управления пользователями
- Telegram-бот для взаимодействия с пользователями
- Экспорт результатов в Excel
- Отправка результатов на email

## Деплой на Render

### 1. Подготовка
1. Создайте аккаунт на [render.com](https://render.com)
2. Подключите ваш GitHub репозиторий

### 2. Создание веб-сервиса
1. Нажмите "New +" → "Web Service"
2. Выберите ваш репозиторий
3. Настройки:
   - **Name**: your-app-name
   - **Environment**: Python 3
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn admin:app`

### 3. Создание Worker для бота
1. Нажмите "New +" → "Background Worker"
2. Выберите тот же репозиторий
3. Настройки:
   - **Name**: your-bot-name
   - **Environment**: Python 3
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `python bot.py`

### 4. Переменные окружения
Добавьте в настройках каждого сервиса:
- `TELEGRAM_BOT_TOKEN` - токен вашего Telegram-бота

## Локальный запуск

### Установка зависимостей
```bash
pip install -r requirements.txt
```

### Запуск веб-приложения
```bash
python admin.py
```

### Запуск бота
```bash
python bot.py
```

## Структура проекта
- `admin.py` - Flask веб-приложение
- `bot.py` - Telegram-бот
- `templates/` - HTML шаблоны
- `users.db` - SQLite база данных
- `requirements.txt` - зависимости Python
- `Procfile` - конфигурация для деплоя 