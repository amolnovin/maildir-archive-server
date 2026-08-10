@echo off
REM  Stop the server when Docker runs inside WSL2 (no Docker Desktop)
REM  Pure ASCII on purpose.

setlocal EnableExtensions
cd /d "%~dp0"
title Maildir Archive Server - Stop (WSL mode)

set "WPATH="
for /f "usebackq delims=" %%P in (`wsl.exe wslpath -a "'%CD%'" 2^>nul`) do set "WPATH=%%P"
if not defined WPATH (
    echo [ERROR] Could not reach WSL.
    goto :done
)

echo [INFO] Stopping services...
wsl.exe -e sh -c "cd '%WPATH%' && docker compose --profile webmail down"
if errorlevel 1 (
    echo [WARN] The stop command reported an error. Is the daemon running?
) else (
    echo [OK] Stopped. Your mail in the mail\ folder is untouched.
)

:done
echo.
echo Press any key to close this window...
pause >nul
endlocal
