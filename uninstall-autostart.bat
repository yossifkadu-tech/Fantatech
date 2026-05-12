@echo off
title Fantatech Hub - הסרת הפעלה אוטומטית
color 0C
chcp 65001 >nul 2>&1

echo.
echo  ================================================
echo   Fantatech Hub - הסרת Auto-Start
echo  ================================================
echo.

set STARTUP_FILE=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\FantatechHub.vbs
set LAUNCHER=%~dp0hub-launcher.vbs

:: Stop running hub
echo  [1] עוצר Hub אם פועל...
for /f "tokens=5" %%p in ('netstat -aon 2^>nul ^| findstr ":8080 "') do (
    taskkill /f /pid %%p >nul 2>&1
)
echo      [OK]

:: Remove from Startup folder
if exist "%STARTUP_FILE%" (
    del /f "%STARTUP_FILE%"
    echo  [2] הוסר מתיקיית Startup
) else (
    echo  [2] לא היה בתיקיית Startup
)

:: Remove launcher
if exist "%LAUNCHER%" (
    del /f "%LAUNCHER%"
    echo  [3] Launcher הוסר
)

echo.
echo  ================================================
echo   OK  הסרה הושלמה. Hub לא יעלה עוד אוטומטית.
echo  ================================================
echo.
pause
