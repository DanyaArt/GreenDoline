@echo off
echo Installing missing Python packages...
echo.

cd /d C:\server

echo Activating virtual environment...
call venv\Scripts\activate.bat

echo Installing required packages...
pip install pyTelegramBotAPI==4.14.0
pip install Flask==2.3.3
pip install flask-sqlalchemy
pip install werkzeug
pip install gunicorn==21.2.0
pip install psutil==5.9.5

echo.
echo Packages installed successfully!
echo You can now run: start_server.bat
echo.
pause 