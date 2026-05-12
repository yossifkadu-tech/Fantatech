@echo off
title Smart Home Hub - Install
color 0A
echo.
echo  ============================================
echo   Smart Home Hub - התקנה ראשונית
echo  ============================================
echo.

:: Install Python dependencies
echo [1/3] מתקין Python dependencies...
cd /d "%~dp0hub"
pip install -r requirements.txt -q
echo      Done!

:: Download Mosquitto
echo.
echo [2/3] בודק Mosquitto MQTT Broker...
where mosquitto >nul 2>&1
if %errorlevel% == 0 (
    echo      Mosquitto כבר מותקן!
) else (
    echo      Mosquitto לא נמצא.
    echo      הורד והתקן מ: https://mosquitto.org/download/
    echo      בחר Windows installer ולחץ Next עד סוף.
    echo.
    pause
)

echo.
echo [3/3] יצירת קישורים...
echo Done!

echo.
echo  ============================================
echo   ההתקנה הושלמה!
echo   הרץ start-hub.bat להפעלה
echo  ============================================
pause
