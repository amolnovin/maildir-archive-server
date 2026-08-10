@echo off
REM Pure ASCII on purpose - see the note in start.bat
setlocal
cd /d "%~dp0"

title Maildir Archive Server - Stop

set "COMPOSE=docker compose"
docker compose version >nul 2>&1
if errorlevel 1 set "COMPOSE=docker-compose"

echo [INFO] Stopping services...
%COMPOSE% --profile webmail down
if errorlevel 1 (
    echo [WARN] Stop command reported an error. Is Docker running?
) else (
    echo [OK] Stopped. Your mail in the mail\ folder is untouched.
)
echo.
pause
endlocal
