@echo off
title Fantatech Hub - התקנת הפעלה אוטומטית
color 0A
chcp 65001 >nul 2>&1

echo.
echo  ================================================
echo   Fantatech Hub - Auto-Start Setup
echo  ================================================
echo.

set HUB_DIR=%~dp0hub
set LAUNCHER=%~dp0hub-launcher.vbs
set STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
set STARTUP_FILE=%STARTUP_DIR%\FantatechHub.vbs

:: ── Find Python ───────────────────────────────────────────────────────────────
for /f "tokens=*" %%i in ('where python 2^>nul') do (
    set PYTHON_EXE=%%i
    goto :found_python
)
echo  [X] Python לא נמצא. ודא ש-Python מותקן.
pause
exit /b 1
:found_python
echo  [OK] Python: %PYTHON_EXE%

:: ── Create hidden launcher VBS ────────────────────────────────────────────────
echo Set oShell = CreateObject("WScript.Shell") > "%LAUNCHER%"
echo oShell.CurrentDirectory = "%HUB_DIR%" >> "%LAUNCHER%"
echo oShell.Run """%PYTHON_EXE%"" -m uvicorn main:app --host 0.0.0.0 --port 8080", 0, False >> "%LAUNCHER%"
echo  [OK] Launcher נוצר

:: ── Copy to Startup folder ────────────────────────────────────────────────────
copy /y "%LAUNCHER%" "%STARTUP_FILE%" >nul
if exist "%STARTUP_FILE%" (
    echo  [OK] נוסף לתיקיית Startup של Windows
) else (
    echo  [X] שגיאה - לא ניתן להעתיק לתיקיית Startup
    pause
    exit /b 1
)

:: ── Open Firewall (requires admin, skip gracefully if not admin) ──────────────
net session >nul 2>&1
if %errorlevel% == 0 (
    netsh advfirewall firewall delete rule name="Fantatech Hub 8080" >nul 2>&1
    netsh advfirewall firewall add rule name="Fantatech Hub 8080" dir=in action=allow protocol=TCP localport=8080 >nul 2>&1
    netsh advfirewall firewall delete rule name="Fantatech Hub Python" >nul 2>&1
    netsh advfirewall firewall add rule name="Fantatech Hub Python" dir=in action=allow program="%PYTHON_EXE%" >nul 2>&1
    echo  [OK] חומת אש נפתחה לפורט 8080
) else (
    echo  [i] חומת אש: הפעל פעם אחת כמנהל כדי לפתוח פורט 8080
)

echo.
echo  ================================================
echo   OK  התקנה הושלמה!
echo.
echo   ה-Hub יפעל ברקע בכל כניסה ל-Windows אוטומטית.
echo   להסרה: הפעל uninstall-autostart.bat
echo  ================================================
echo.
echo  האם להפעיל עכשיו? (Y/N)
set /p RUNNOW=
if /i "%RUNNOW%"=="Y" (
    wscript.exe "%LAUNCHER%"
    echo  Hub מופעל ברקע. המתן 5 שניות ובדוק http://localhost:8080/ping
    timeout /t 5 /nobreak >nul
    powershell -Command "try{$r=(Invoke-WebRequest http://localhost:8080/ping -TimeoutSec 4 -UseBasicParsing).Content; Write-Host '  PING: '$r} catch{Write-Host '  [!] Hub לא הגיב עדיין, המתן עוד כמה שניות'}"
)

pause
