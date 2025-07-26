# 🚀 Быстрый старт на AlwaysData
# Quick Start on AlwaysData

## 📋 Что нужно сделать (пошагово):

### 1. **Подготовка файлов** ✅
Файлы уже созданы! У вас есть:
- `bot_alwaysdata.py` - модифицированный бот
- `passenger_wsgi.py` - точка входа для AlwaysData
- `requirements.txt` - зависимости Python
- `alwaysdata.conf` - конфигурация

### 2. **Загрузка на AlwaysData**

#### Шаг 1: Войдите в панель управления
- Откройте: https://admin.alwaysdata.com
- Войдите в аккаунт: `artdan1122@yandex.ru`

#### Шаг 2: Создайте сайт
1. Перейдите в **"Паутина"** → **"Сайты"**
2. Нажмите **"Добавить сайт"**
3. Выберите **Python** как тип
4. Укажите домен (например: `your-bot.alwaysdata.net`)

#### Шаг 3: Загрузите файлы
1. В разделе **"Файлы"** откройте папку вашего сайта
2. Загрузите эти файлы:
   - `bot_alwaysdata.py` → переименуйте в `bot.py`
   - `passenger_wsgi.py`
   - `requirements.txt`
   - `users.db` (если есть)

#### Шаг 4: Настройте Python
1. Перейдите в **"Окружающая среда"** → **"Python"**
2. Выберите версию **Python 3.11**
3. Укажите файл запуска: `passenger_wsgi.py`

#### Шаг 5: Настройте переменные окружения
1. Перейдите в **"Окружающая среда"** → **"Переменные"**
2. Добавьте переменные:
   ```
   BOT_TOKEN = 7709800436:AAG9zdInNqWmU-TW7IuzioHhy_McWnqLw0w
   PORT = 5000
   DATABASE_URL = sqlite:///users.db
   WEBHOOK_URL = https://your-domain.alwaysdata.net/webhook
   ```

#### Шаг 6: Включите SSL
1. Перейдите в **"Паутина"** → **"SSL"**
2. Включите **автоматический SSL сертификат**
3. Настройте редирект с HTTP на HTTPS

### 3. **Настройка вебхука**

После загрузки файлов настройте вебхук:

1. Откройте в браузере: `https://your-domain.alwaysdata.net/set_webhook?url=https://your-domain.alwaysdata.net/webhook`
2. Должен появиться ответ: `{"ok":true,"result":true,"description":"Webhook was set"}`

### 4. **Тестирование**

1. **Проверьте сайт**: `https://your-domain.alwaysdata.net`
   - Должна появиться страница статуса

2. **Проверьте бота в Telegram**:
   - Напишите `/start`
   - Бот должен ответить

## 🎯 **Готово!**

После этих шагов ваш бот будет работать **24/7** на AlwaysData!

## 🆘 **Если что-то не работает:**

### Бот не отвечает:
- Проверьте токен в переменных окружения
- Проверьте вебхук: `https://your-domain.alwaysdata.net/set_webhook`
- Посмотрите логи в AlwaysData

### Ошибка 500:
- Проверьте `passenger_wsgi.py`
- Убедитесь, что Python 3.11 выбран
- Проверьте `requirements.txt`

### SSL ошибки:
- Включите SSL в панели управления
- Обновите вебхук на HTTPS

## 📞 **Поддержка:**

- **AlwaysData**: https://admin.alwaysdata.com/support
- **Логи**: Панель управления → Логи
- **Документация**: https://help.alwaysdata.com

---

**🌍 Ваш бот теперь работает круглосуточно!** 