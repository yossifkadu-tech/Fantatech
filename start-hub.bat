@echo off
title Fantatech Home ^& Security Hub
color 0A
chcp 65001 >nul 2>&1
set PYTHONIOENCODING=utf-8
set PYTHONUTF8=1

echo.
echo  ================================================
echo   Fantatech Home ^& Security Hub
echo  ================================================
echo.

:: -- Step 0: Admin is optional -- only the firewall-rule step below needs
:: it, and that step already degrades gracefully on its own (prints a
:: warning and continues) when it can't open the rule. No need to force a
:: UAC relaunch just to start the Hub itself.
::
:: Status text below is plain ASCII on purpose, not Hebrew -- this console
:: window's font/codepage can't reliably render Hebrew glyphs even with a
:: UTF-8 BOM and chcp 65001 set (confirmed: still garbled after both), so
:: English is used here for the parts only this terminal window sees. The
:: app itself (Flutter UI) is unaffected -- this is purely this script's
:: own diagnostic output.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  [i] Not running as Administrator - automatic firewall setup will be skipped
    echo      ^(optional: run as Administrator to enable it^)
    echo.
)

:: -- Step 1: Auto-open Windows Firewall for Python on port 8080 ----------
echo [1/3] Opening Windows Firewall for port 8080...
netsh advfirewall firewall delete rule name="Fantatech Hub 8080" >nul 2>&1
netsh advfirewall firewall add rule name="Fantatech Hub 8080" dir=in action=allow protocol=TCP localport=8080 >nul 2>&1
if %errorlevel% == 0 (
    echo       Firewall rule added for port 8080 [OK]
) else (
    echo       [!] Could not open firewall - run as Administrator to enable this
)

:: Also allow Python itself
for /f "tokens=*" %%i in ('where python 2^>nul') do (
    netsh advfirewall firewall add rule name="Fantatech Hub Python" dir=in action=allow program="%%i" >nul 2>&1
)

:: -- Step 2: Start Mosquitto -----------------------------------------------
echo.
echo [2/3] Starting MQTT Broker (Mosquitto)...

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
    echo       MQTT running on port 1883 [OK]
) else (
    echo       [!] Mosquitto not found - Hub will start its own internal MQTT broker automatically
)

:: -- Step 3: Print local IP clearly -----------------------------------------
echo.
echo [3/3] This computer's IP address (enter it in the app if auto-discovery fails):
echo.
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /R "IPv4"') do (
    set IP=%%a
    setlocal enabledelayedexpansion
    set IP=!IP: =!
    echo        ^>^>^> !IP! ^<^<^<
    endlocal
)
echo.

:: -- Step 4: Start Hub -------------------------------------------------------
echo Starting Fantatech Hub...
cd /d "%~dp0hub"
python -m uvicorn main:app --host 0.0.0.0 --port 8080

pause
