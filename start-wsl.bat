@echo off
REM ============================================================
REM  Maildir Archive Server - start using Docker inside WSL2
REM  (for setups WITHOUT Docker Desktop)
REM
REM  Important: docker compose is executed INSIDE WSL, not on
REM  Windows. The compose file uses relative bind mounts such as
REM  ./mail, and those only resolve correctly when compose runs
REM  in the same filesystem namespace as the daemon.
REM
REM  Pure ASCII on purpose.
REM ============================================================

setlocal EnableExtensions
cd /d "%~dp0"
title Maildir Archive Server - Start (WSL mode)

echo ==========================================
echo   Maildir Archive Server - Startup (WSL)
echo ==========================================
echo.

if not exist "docker-compose.yml" goto :no_project

REM ---- Is WSL available? ----
where wsl.exe >nul 2>&1
if errorlevel 1 goto :no_wsl

REM ---- Translate this Windows folder to a WSL path ----
set "WPATH="
for /f "usebackq delims=" %%P in (`wsl.exe wslpath -a "'%CD%'" 2^>nul`) do set "WPATH=%%P"
if not defined WPATH goto :no_path
echo [INFO] Project path inside WSL: %WPATH%

REM ---- Is the Docker daemon alive inside WSL? ----
echo [INFO] Checking the Docker daemon inside WSL...
wsl.exe -e sh -c "docker info >/dev/null 2>&1"
if errorlevel 1 goto :try_start
goto :daemon_ok

:try_start
echo [INFO] Daemon not responding, trying to start it...
wsl.exe -e sh -c "sudo service docker start >/dev/null 2>&1 || sudo systemctl start docker >/dev/null 2>&1" 2>nul
wsl.exe -e sh -c "docker info >/dev/null 2>&1"
if errorlevel 1 goto :no_daemon

:daemon_ok
echo [INFO] Docker daemon is running.

REM ---- First-run files ----
if not exist ".env" (
    echo [INFO] Creating .env from .env.example
    copy /Y ".env.example" ".env" >nul
)
if not exist "docker\dovecot\users" (
    >"docker\dovecot\users" echo # Maildir Archive Server - users file
)

REM ---- Build and start, from inside WSL ----
echo [INFO] Building and starting containers...
echo        The first run downloads images and may take a few minutes.
echo.
wsl.exe -e sh -c "cd '%WPATH%' && docker compose up -d --build"
if errorlevel 1 goto :compose_failed

echo.
echo [OK] Server is up.
echo.
echo   IMAP        : localhost:143  (STARTTLS)
echo   IMAPS       : localhost:993  (SSL/TLS)
echo   Web Panel   : http://localhost:8080
echo.
echo   Give the containers ~10 seconds, then open the panel.
echo.
echo   Manage it with:
echo     stop-wsl.bat        stop the server
echo     logs-wsl.bat        show container logs
echo.
echo   Note: with Docker in WSL, run the PowerShell scripts as usual,
echo   but any 'docker exec' they perform needs the WSL daemon, so
echo   prefer running them from inside WSL when possible.
echo.
goto :done

:no_project
echo [ERROR] docker-compose.yml was not found in:
echo         %CD%
echo         Keep this file inside the project folder.
goto :done

:no_wsl
echo [ERROR] wsl.exe was not found. Install WSL first:
echo             wsl --install
echo         then reboot Windows.
goto :done

:no_path
echo [ERROR] Could not translate the current folder to a WSL path.
echo         Make sure the project is on a local drive (C:, D:),
echo         not on a network share.
goto :done

:no_daemon
echo [ERROR] The Docker daemon inside WSL is not running.
echo.
echo         Install it by opening your WSL distro and running:
echo             bash install-docker-wsl.sh
echo.
echo         If it is already installed, start it with:
echo             wsl -e sudo service docker start
echo.
echo         To make it start automatically, enable systemd:
echo             put  [boot]  and  systemd=true  in /etc/wsl.conf
echo             then run  wsl --shutdown  from Windows.
goto :done

:compose_failed
echo.
echo [ERROR] docker compose failed. See the messages above.
echo         Common causes:
echo           - a port is in use: change IMAP_PORT / IMAPS_PORT in .env
echo           - no internet access to download images
echo           - permission denied: your WSL user is not in the docker
echo             group. Run:  sudo usermod -aG docker $USER
echo             then:        wsl --shutdown   (from Windows)
goto :done

:done
echo.
echo Press any key to close this window...
pause >nul
endlocal
