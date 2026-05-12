@echo off
title Fantatech Home & Security Hub
color 0A
chcp 65001 >nul 2>&1
set PYTHONIOENCODING=utf-8
set PYTHONUTF8=1

echo.
echo  ================================================
echo   Fantatech Home ^& Security Hub
echo  ================================================
echo.

:: ── Step 0: Make sure we run as Admin ────────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!] לא הופעל כמנהל מערכת. מנסה להפעיל מחדש...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: ── Step 1: Auto-open Windows Firewall for Python on port 8080 ───────────────
echo [0/3] פותח חומת אש Windows לפורט 8080...
netsh advfirewall firewall delete rule name="Fantatech Hub 8080" >nul 2>&1
netsh advfirewall firewall add rule name="Fantatech Hub 8080" dir=in action=allow protocol=TCP localport=8080 >nul 2>&1
if %errorlevel% == 0 (
    echo       חומת אש נפתחה לפורט 8080 [OK]
) else (
    echo       [!] לא ניתן לפתוח חומת האש - הפעל כמנהל
)

:: Also allow Python itself
for /f "tokens=*" %%i in ('where python 2^>nul') do (
    netsh advfirewall firewall add rule name="Fantatech Hub Python" dir=in action=allow program="%%i" >nul 2>&1
)

:: ── Step 2: Start Mosquitto ───────────────────────────────────────────────────
echo.
echo [1/3] מפעיל MQTT Broker (Mosquitto)...

set MOSQUITTO_EXE=
where mosquitto >nul 2>&1 && set MOSQUITTO_EXE=mosquitto
if "%MOSQUITTO_EXE%"=="" (
    if exist "C:\Program Files\mosquitto\mosquitto.exe" set MOSQUITTO_EXE=C:\Program Files\mosquitto\mosquitto.exe
)
if "%MOSQUITTO_EXE%"=="" (
    if exist "C:\mosquitto\mosquitto.exe" set MOSQUITTO_EXE=C:\mosquitto\mosquitto.exe
)

if not "%MOSQUITTO_EXE%"=="" (
    start "MQTT Broker" /min "%MOSQUITTO_EXE%" -c "%~dp0mosquitto\mosquitto.conf" -v
    timeout /t 2 /nobreak >nul
    echo       MQTT פועל על port 1883 [OK]
) else (
    echo       [!] Mosquitto לא נמצא - Hub יפעיל MQTT פנימי אוטומטית
)

:: ── Step 3: Print local IP clearly ───────────────────────────────────────────
echo.
echo [2/3] כתובת IP של המחשב (הזן באפליקציה אם הגילוי לא עובד):
echo.
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /R "IPv4"') do (
    set IP=%%a
    setlocal enabledelayedexpansion
    set IP=!IP: =!
    echo        >>> !IP! <<<
    endlocal
)
echo.

:: ── Step 4: Start Hub ─────────────────────────────────────────────────────────
echo [3/3] מפעיל Fantatech Hub...
cd /d "%~dp0hub"
python -m uvicorn main:app --host 0.0.0.0 --port 8080

pause
