@echo off
:: bump-version.bat [major|minor|patch]
:: דוגמה: bump-version.bat minor

set TYPE=%1
if "%TYPE%"=="" set TYPE=patch

for /f %%v in (VERSION) do set VERSION=%%v
for /f "tokens=1,2,3 delims=." %%a in ("%VERSION%") do (
    set MAJOR=%%a
    set MINOR=%%b
    set PATCH=%%c
)

if "%TYPE%"=="major" (
    set /a MAJOR=MAJOR+1 & set MINOR=0 & set PATCH=0
) else if "%TYPE%"=="minor" (
    set /a MINOR=MINOR+1 & set PATCH=0
) else (
    set /a PATCH=PATCH+1
)

set NEW=%MAJOR%.%MINOR%.%PATCH%
echo %NEW% > VERSION

echo גרסה עודכנה: %VERSION% ^→ %NEW%
echo.
echo אל תשכח לעדכן CHANGELOG.md!
