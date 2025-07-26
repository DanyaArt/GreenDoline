@echo off
echo Setting up AlwaysData hosting for Telegram Bot...
echo.
echo This will create all files needed for AlwaysData deployment
echo.
pause

python alwaysdata_setup.py

echo.
echo AlwaysData setup completed!
echo.
echo Next steps:
echo 1. Read ALWAYSDATA_GUIDE.md for detailed instructions
echo 2. Upload files to your AlwaysData account
echo 3. Configure environment variables
echo 4. Set webhook URL
echo.
echo Your bot will work 24/7 on AlwaysData!
pause 