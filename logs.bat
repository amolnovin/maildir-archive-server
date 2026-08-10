@echo off
REM Pure ASCII on purpose - see the note in start.bat
setlocal
cd /d "%~dp0"

title Maildir Archive Server - Logs

set "COMPOSE=docker compose"
docker compose version >nul 2>&1
if errorlevel 1 set "COMPOSE=docker-compose"

echo [INFO] Showing live logs. Press Ctrl+C to exit.
echo.
%COMPOSE% logs -f --tail=100
endlocal
