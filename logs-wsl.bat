@echo off
REM  Show container logs when Docker runs inside WSL2
REM  Pure ASCII on purpose.

setlocal EnableExtensions
cd /d "%~dp0"
title Maildir Archive Server - Logs (WSL mode)

set "WPATH="
for /f "usebackq delims=" %%P in (`wsl.exe wslpath -a "'%CD%'" 2^>nul`) do set "WPATH=%%P"
if not defined WPATH (
    echo [ERROR] Could not reach WSL.
    echo.
    pause
    exit /b 1
)

echo [INFO] Showing live logs. Press Ctrl+C to exit.
echo.
wsl.exe -e sh -c "cd '%WPATH%' && docker compose logs -f --tail=100"
endlocal
