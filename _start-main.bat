@echo off
REM ============================================================
REM  Maildir Archive Server - startup logic
REM  Called by start.bat. Do not run this directly; start.bat is
REM  the wrapper that keeps the window open on failure.
REM  Pure ASCII on purpose.
REM ============================================================

setlocal EnableExtensions

set "ENGINE_OUT=%TEMP%\mas_engine.txt"
set "PS_OK="
where powershell.exe >nul 2>&1 && set "PS_OK=1"

echo ==========================================
echo   Maildir Archive Server - Startup
echo ==========================================
echo.

REM ---- 1. Are we in the project folder? ----
if not exist "docker-compose.yml" goto :no_project

REM ---- 2. Is the Docker CLI reachable? ----
set "DOCKER_OK="
where docker.exe >nul 2>&1 && set "DOCKER_OK=1"
if defined DOCKER_OK goto :cli_ok
if exist "%ProgramFiles%\Docker\Docker\resources\bin\docker.exe" set "DOCKER_OK=1"
if not defined DOCKER_OK goto :no_docker_cli
:cli_ok

REM ---- 3. Is the Docker ENGINE actually usable? ----
echo [INFO] Checking the Docker engine (max ~20 seconds)...
call :chk_engine
if not defined ENGINE_OK goto :no_docker_engine
echo [INFO] Engine is running.

REM ---- 4. Detect Compose v2, then fall back to v1 ----
set "COMPOSE="
docker compose version >nul 2>&1
if not errorlevel 1 set "COMPOSE=docker compose"
if defined COMPOSE goto :have_compose

docker-compose version >nul 2>&1
if not errorlevel 1 set "COMPOSE=docker-compose"
if defined COMPOSE goto :have_compose
goto :no_compose

:have_compose
echo [INFO] Using: %COMPOSE%

REM ---- 5. Create .env on first run ----
if not exist ".env" (
    echo [INFO] Creating .env from .env.example
    copy /Y ".env.example" ".env" >nul
)

REM ---- 6. Make sure the users file exists ----
if not exist "docker\dovecot\users" (
    >"docker\dovecot\users" echo # Maildir Archive Server - users file
)

REM ---- 7. Build and start ----
echo [INFO] Building and starting containers...
echo        The first run downloads images and may take a few minutes.
echo.
%COMPOSE% up -d --build
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
echo   Webmail (optional):
echo     %COMPOSE% --profile webmail up -d
echo     then open http://localhost:8000
echo.
echo   Next steps - run these in PowerShell (they print Persian):
echo     powershell -ExecutionPolicy Bypass -File scripts\Add-Domain.ps1 -Domain komajsaba.com
echo     powershell -ExecutionPolicy Bypass -File scripts\Import-DirectAdminBackup.ps1 -Source "D:\backup\user.tar.gz" -CreateAccounts
echo     powershell -ExecutionPolicy Bypass -File scripts\Get-Mailboxes.ps1
echo.
echo   Useful:
echo     logs.bat            show container logs
echo     check-docker.bat    diagnose Docker problems
echo.
endlocal
exit /b 0

:no_project
echo [ERROR] docker-compose.yml was not found in:
echo         %CD%
echo         Keep start.bat inside the project folder and run it there.
endlocal
exit /b 1

:no_docker_cli
echo [ERROR] The 'docker' command was not found.
echo         Install Docker Desktop, or if it is installed, sign out of
echo         Windows and back in so PATH is refreshed.
endlocal
exit /b 1

:no_docker_engine
echo.
echo [ERROR] The Docker engine is not usable yet.
echo.
echo --------- what Docker reported ---------
if exist "%ENGINE_OUT%" type "%ENGINE_OUT%"
if exist "%ENGINE_OUT%.err" type "%ENGINE_OUT%.err"
echo ----------------------------------------
call :engine_help
endlocal
exit /b 1

:no_compose
echo [ERROR] Docker Compose was not found.
echo         Update Docker Desktop to a recent version.
endlocal
exit /b 1

:compose_failed
echo.
echo [ERROR] Docker Compose failed. See the messages above.
echo.
REM  Work out WHY instead of guessing. If the engine broke down while
REM  Compose was running, this is a Docker Desktop problem, not a port
REM  conflict - so do not send the user chasing the wrong thing.
echo [INFO] Re-checking the Docker engine to identify the cause...
call :chk_engine
if not defined ENGINE_OK goto :cf_engine_dead

echo         The engine is alive, so this is most likely one of:
echo.
echo         1. A port is already in use (143, 993, 8080).
echo            Fix: open .env and change IMAP_PORT / IMAPS_PORT / PANEL_PORT,
echo                 for example IMAP_PORT=1143 and IMAPS_PORT=1993.
echo            Check with:  netstat -ano ^| findstr ":143"
echo.
echo         2. No internet access to download the base images.
echo            Test with:  docker pull alpine:3.22
echo.
echo         3. Not enough disk space for the images.
endlocal
exit /b 1

:cf_engine_dead
echo         CAUSE FOUND: the Docker engine stopped responding.
echo         This is NOT a port problem. Docker Desktop itself failed,
echo         which is why the image could not be downloaded.
call :engine_help
endlocal
exit /b 1

REM ------------------------------------------------------------
REM  :chk_engine
REM  Sets ENGINE_OK=1 only if the engine really answers.
REM  Exit code 0 alone is not enough: a broken Docker Desktop can
REM  return 0 while printing "unable to start" and no Server section.
REM  So we require the string "Server Version" in the output.
REM ------------------------------------------------------------
:chk_engine
set "ENGINE_OK="
del "%ENGINE_OUT%" "%ENGINE_OUT%.err" >nul 2>&1
if not defined PS_OK goto :chk_plain
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; $p=Start-Process -FilePath 'docker' -ArgumentList 'info' -NoNewWindow -PassThru -RedirectStandardOutput $env:ENGINE_OUT -RedirectStandardError \"$env:ENGINE_OUT.err\"; if(-not $p.WaitForExit(20000)){ try{$p.Kill()}catch{}; exit 2 }; exit $p.ExitCode" >nul 2>&1
goto :chk_verify
:chk_plain
docker info >"%ENGINE_OUT%" 2>&1
:chk_verify
if not exist "%ENGINE_OUT%" exit /b 0
findstr /c:"Server Version" "%ENGINE_OUT%" >nul 2>&1
if not errorlevel 1 set "ENGINE_OK=1"
exit /b 0

REM ------------------------------------------------------------
REM  :engine_help - shared recovery instructions
REM ------------------------------------------------------------
:engine_help
echo.
echo         HOW TO FIX - do these in order:
echo.
echo         1. Fully quit Docker Desktop:
echo            right-click the whale icon in the tray -^> Quit Docker Desktop.
echo.
echo         2. Reset the WSL backend, in PowerShell:
echo               wsl --shutdown
echo.
echo         3. Start Docker Desktop again and wait until the bottom-left
echo            corner says "Engine running".
echo.
echo         4. Confirm the settings:
echo            Settings -^> General -^> "Use the WSL 2 based engine" must be ON.
echo            Settings -^> Resources -^> WSL integration -^> enable your distro.
echo.
echo         5. Still failing? Rebuild Docker's own WSL machine.
echo            THIS DELETES ALL LOCAL IMAGES AND CONTAINERS, but your
echo            mail in the mail\ folder is NOT touched:
echo               wsl --unregister docker-desktop
echo            then start Docker Desktop (it recreates it automatically).
echo.
echo         6. Last resort: Docker Desktop -^> the bug icon (Troubleshoot)
echo            -^> "Reset to factory defaults".
echo.
echo         Verify with:  docker run --rm hello-world
echo         When that prints a greeting, run start.bat again.
exit /b 0
