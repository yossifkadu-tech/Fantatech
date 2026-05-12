@echo off
title Smart Home App
color 0B
echo.
echo  ============================================
echo   Smart Home App - מפעיל...
echo  ============================================
echo.
cd /d "%~dp0app"
start http://localhost:3000
npm run dev
pause
