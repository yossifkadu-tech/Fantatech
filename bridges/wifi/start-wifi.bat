@echo off
title WiFi Bridge
color 0E
echo.
echo  ============================================
echo   WiFi Bridge (Tasmota / ESPHome)
echo  ============================================
echo.

cd /d "%~dp0"

echo  מתקין dependencies...
pip install -r requirements.txt -q

echo.
echo  מפעיל WiFi Bridge...
echo  סורק רשת %NETWORK_SUBNET%.x...
echo.

python wifi_bridge.py
pause
