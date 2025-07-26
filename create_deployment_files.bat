@echo off
echo Creating deployment files for 24/7 hosting...
echo.
echo This will create files for:
echo - Railway (Free hosting)
echo - Render (Free hosting)  
echo - Heroku (Paid hosting)
echo.
pause

python deploy_to_railway.py

echo.
echo Deployment files created successfully!
echo.
echo Next steps:
echo 1. Railway: Run deploy_railway.bat
echo 2. Render: Upload to GitHub and connect
echo 3. Heroku: Use app.json for deployment
echo.
pause 