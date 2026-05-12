@echo off
title Smart Home Hub - Start All
color 0A
echo.
echo  ============================================
echo   Smart Home Hub - מפעיל הכל
echo  ============================================
echo.

:: 1. MQTT Broker
echo [1/4] MQTT Broker...
set MOSQUITTO_EXE=C:\Program Files\mosquitto\mosquitto.exe
start "MQTT Broker" /min "%MOSQUITTO_EXE%" -c "%~dp0mosquitto\mosquitto.conf" -v
    timeout /t 2 /nobreak >nul
    echo      port 1883 OK
) else (
    echo      [!] Mosquitto לא מותקן
)

:: 2. Hub
echo [2/4] Smart Home Hub...
start "Hub" cmd /k "cd /d "%~dp0hub" && python -m uvicorn main:app --host 0.0.0.0 --port 8080"
timeout /t 3 /nobreak >nul
echo      port 8080 OK

:: 3. WiFi Bridge
echo [3/4] WiFi Bridge...
start "WiFi Bridge" cmd /k "cd /d "%~dp0bridges\wifi" && python wifi_bridge.py"
timeout /t 2 /nobreak >nul
echo      scanning 192.168.10.x...

:: 4. Zigbee Bridge (רק אם יש dongle)
echo [4/4] Zigbee Bridge...
echo      כדי להפעיל Zigbee: הרץ bridges\zigbee\start-zigbee.bat בנפרד

echo.
echo  ============================================
echo   הכל פועל!
echo   Hub API:  http://localhost:8080/docs
echo   MQTT:     localhost:1883
echo  ============================================
echo.
pause
