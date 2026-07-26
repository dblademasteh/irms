@echo off
title IRMS Web Server

cd /d "%~dp0build\web"

echo Getting IP address...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4" ^| findstr "192.168"') do set IP=%%a
set IP=%IP: =%

if "%IP%"=="" (
    echo Could not find local IP address!
    pause
    exit /b 1
)

echo Starting server on %IP%...
echo.
echo ====================================
echo   Open this URL on your phone:
echo   http://%IP%:9000
echo ====================================
echo.
echo Press Ctrl+C to stop the server
echo.

python -m http.server 9000