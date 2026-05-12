@echo off
chcp 65001 > nul
cd /d "%~dp0"
title Fantatech Hub v1.7.0

echo.
echo  ================================================
echo   Fantatech Home and Security - Hub v1.7.0
echo  ================================================
echo.

:: ── Check Admin rights ──────────────────────────────────────────────────────
net session > nul 2>&1
if errorlevel 1 (
    echo  [WARN] Not running as Administrator.
    echo  Firewall rules may not be added.
    echo  Right-click start-hub.bat and choose "Run as administrator"
    echo.
)

:: ── Check Python ─────────────────────────────────────────────────────────────
python --version > nul 2>&1
if errorlevel 1 (
    echo  [ERROR] Python not found!
    echo  Download: https://python.org
    echo  Check "Add Python to PATH" during install.
    pause
    exit /b 1
)
for /f "tokens=*" %%P in ('where python') do set PYTHON_EXE=%%P & goto :found_python
:found_python
echo  [OK] Python: %PYTHON_EXE%
echo.

:: ── Install packages ─────────────────────────────────────────────────────────
echo  Checking Python packages...
python -m pip install -r requirements.txt --quiet --no-warn-script-location 2>nul
echo  [OK] Packages ready
echo.

:: ── Firewall — open ALL profiles (Private + Public + Domain) ─────────────────
echo  Opening Windows Firewall...

:: Delete any old/partial rules
netsh advfirewall firewall delete rule name="Fantatech Hub API"       > nul 2>&1
netsh advfirewall firewall delete rule name="Fantatech Hub MQTT"      > nul 2>&1
netsh advfirewall firewall delete rule name="Fantatech Python"        > nul 2>&1

:: Allow Python.exe for ALL profiles (most important — bypasses per-port rules)
netsh advfirewall firewall add rule ^
    name="Fantatech Python" dir=in action=allow ^
    program="%PYTHON_EXE%" profile=any > nul 2>&1

:: Allow ports 8080 + 1883 for ALL profiles
netsh advfirewall firewall add rule ^
    name="Fantatech Hub API" protocol=TCP dir=in ^
    localport=8080 action=allow profile=any > nul 2>&1
netsh advfirewall firewall add rule ^
    name="Fantatech Hub MQTT" protocol=TCP dir=in ^
    localport=1883 action=allow profile=any > nul 2>&1

echo  [OK] Firewall rules added (all profiles)
echo.

:: ── Start MQTT Broker ────────────────────────────────────────────────────────
echo  Starting MQTT broker...
where mosquitto > nul 2>&1
if not errorlevel 1 (
    start /min "MQTT" mosquitto
    timeout /t 2 /nobreak > nul
    echo  [OK] Mosquitto on port 1883
) else (
    start /min "MQTT" python -m amqtt
    timeout /t 2 /nobreak > nul
    echo  [OK] Python MQTT on port 1883
)
echo.

:: ── Detect Hub IP ────────────────────────────────────────────────────────────
for /f "tokens=*" %%i in ('python -c "import socket;s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);s.connect(('8.8.8.8',80));print(s.getsockname()[0]);s.close()" 2^>nul') do set HUB_IP=%%i

:: ── Print connection info ────────────────────────────────────────────────────
echo  ================================================
if defined HUB_IP (
    echo.
    echo   Hub IP  :  %HUB_IP%
    echo   Hub URL :  http://%HUB_IP%:8080
    echo.
    echo   IN THE APP:
    echo   Settings ^> enter IP: %HUB_IP%
    echo.
    echo   OR open in phone browser to verify:
    echo   http://%HUB_IP%:8080/
    echo.
) else (
    echo   [WARN] Cannot detect IP - check network
)
echo  ================================================
echo.

:: ── Ping gateway to verify network ──────────────────────────────────────────
for /f "tokens=3" %%g in ('route print 0.0.0.0 ^| findstr "0.0.0.0" 2^>nul') do set GW=%%g & goto :gw_done
:gw_done
if defined GW (
    ping -n 1 -w 1000 %GW% > nul 2>&1
    if not errorlevel 1 (
        echo  [OK] Router reachable at %GW%
    ) else (
        echo  [WARN] Cannot reach router %GW% - check WiFi/LAN
    )
)
echo.
echo  Hub is running. Do NOT close this window.
echo  To stop: Ctrl+C or close window.
echo.

:: ── Start Hub ────────────────────────────────────────────────────────────────
python -m uvicorn main:app --host 0.0.0.0 --port 8080

echo.
echo  Hub stopped. Press any key to exit.
pause > nul
