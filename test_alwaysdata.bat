@echo off
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
