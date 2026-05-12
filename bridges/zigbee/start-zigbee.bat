@echo off
title Zigbee Bridge
color 0B
echo.
echo  ============================================
echo   Zigbee Bridge
echo  ============================================
echo.

cd /d "%~dp0"

echo  מתקין dependencies...
pip install -r requirements.txt -q

echo.
echo  מפעיל Zigbee Bridge...
echo  ודא ש-Zigbee USB Dongle מחובר ל-USB
echo  ועדכן את ZIGBEE_PORT ב-.env
echo.

python zigbee_bridge.py
pause
