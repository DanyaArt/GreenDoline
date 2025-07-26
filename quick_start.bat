@echo off
echo Быстрый запуск установки домашнего сервера
echo Система: Windows 11 Home + WSL2
echo ================================================

REM Проверка прав администратора
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Права администратора получены
) else (
    echo Требуются права администратора!
    echo Запустите этот файл от имени администратора
    pause
    exit /b 1
)

echo.
echo Запуск установки WSL2 и настройки сервера...
echo.

REM Запуск PowerShell скрипта
powershell -ExecutionPolicy Bypass -File "windows_setup_safe.ps1"

echo.
echo Установка завершена!
echo.
echo Следующие шаги:
echo 1. Перезагрузите компьютер
echo 2. Прочитайте файл: C:\server\WSL2_SETUP.md
echo 3. Выполните команды из инструкции
echo 4. Запустите сервер: C:\server\start_server.bat
echo.
pause 