@echo off
REM ============================================================
REM  Docker diagnostics for Maildir Archive Server
REM  Run this when start.bat cannot reach the Docker engine.
REM  Pure ASCII on purpose - see the note in start.bat
REM
REM  Every Docker call here is time-limited, because a half-started
REM  engine can make "docker version" block for several minutes.
REM ============================================================

setlocal EnableExtensions
cd /d "%~dp0"
title Maildir Archive Server - Docker Check

set "OUT=%TEMP%\mas_diag.txt"
set "PS_OK="
where powershell.exe >nul 2>&1 && set "PS_OK=1"

echo ==========================================
echo   Docker Diagnostics
echo ==========================================
echo.

echo [1] Is the docker command reachable?
where docker.exe >nul 2>&1
if errorlevel 1 goto :cli_missing
for /f "delims=" %%P in ('where docker.exe 2^>nul') do echo     FOUND: %%P
goto :cli_done
:cli_missing
if exist "%ProgramFiles%\Docker\Docker\resources\bin\docker.exe" (
    echo     FOUND: %ProgramFiles%\Docker\Docker\resources\bin\docker.exe
    echo     WARNING: it is not in PATH. Sign out of Windows and back in.
) else (
    echo     NOT FOUND. Docker Desktop does not appear to be installed.
    goto :summary
)
:cli_done
echo.

echo [2] CLI build ^(works even when the engine is stopped^):
call :run_timed 10 "--version"
type "%OUT%" 2>nul
echo.

echo [3] Engine connection ^(this is the one that matters^):
echo     Please wait, up to 20 seconds...
call :run_timed 20 "info"
set "RC=%ERRORLEVEL%"
if "%RC%"=="2" goto :engine_timeout
REM  A broken Docker Desktop can exit 0 while printing "unable to start"
REM  and no Server section, so require "Server Version" in the output.
findstr /c:"Server Version" "%OUT%" >nul 2>&1
if errorlevel 1 goto :engine_error
echo     RESULT: OK - the engine is running.
findstr /i /c:"Server Version" "%OUT%" 2>nul
goto :step4

:engine_timeout
echo     RESULT: TIMED OUT after 20 seconds.
echo     The engine is not answering. It is usually still starting up,
echo     or Docker Desktop is stuck.
goto :step4

:engine_error
echo     RESULT: ENGINE NOT USABLE.
echo     ----- what Docker reported -----
type "%OUT%" 2>nul
if exist "%OUT%.err" type "%OUT%.err" 2>nul
echo     --------------------------------
findstr /c:"unable to start" "%OUT%" >nul 2>&1
if errorlevel 1 goto :step4
echo.
echo     "Docker Desktop is unable to start" means the engine backend
echo     crashed. See step 6 in the instructions at the end.

:step4
echo.
echo [4] Docker Compose:
call :run_timed 15 "compose version"
if errorlevel 1 goto :compose_v1
echo     OK - Compose v2 available:
for /f "usebackq delims=" %%L in ("%OUT%") do echo     %%L
goto :compose_done
:compose_v1
echo     "docker compose" ^(v2^) did not respond. Trying legacy v1...
docker-compose version 2>&1
:compose_done
echo.

echo [5] Docker Desktop service status:
sc query "com.docker.service" 2>nul | findstr /i "STATE"
if errorlevel 1 echo     Service not found or not accessible ^(needs admin^).
echo.

echo [6] WSL status ^(Docker Desktop uses WSL2 as its backend^):
wsl --status 2>&1
echo.

echo [7] WSL distributions:
wsl --list --verbose 2>&1
echo.

:summary
echo ==========================================
echo   What to do
echo ==========================================
echo.
echo If step [3] timed out or failed:
echo.
echo   1. Open Docker Desktop. Wait until the bottom-left status reads
echo      "Engine running" and the whale icon stops animating.
echo      After a reboot this can take 1-3 minutes.
echo.
echo   2. If it stays on "Docker Desktop starting...", reset WSL:
echo         wsl --update
echo         wsl --shutdown
echo      then start Docker Desktop again.
echo.
echo   3. If step [5] shows the service is STOPPED, start it:
echo      Win+R -^> services.msc -^> "Docker Desktop Service" -^> Start
echo.
echo   4. If step [6] or [7] reported errors, install/repair WSL:
echo         wsl --install --no-distribution
echo      then reboot Windows.
echo.
echo   5. Verify:  docker info
echo      It must print a "Server Version:" line. Then run start.bat.
echo.
echo   6. If Docker says "Docker Desktop is unable to start", the engine
echo      backend is broken. Fix it like this:
echo         a) Quit Docker Desktop from the tray.
echo         b) In PowerShell:  wsl --shutdown
echo         c) Start Docker Desktop again.
echo         d) Still broken? Rebuild Docker's WSL machine. This deletes
echo            local images/containers but NOT your mail\ folder:
echo               wsl --unregister docker-desktop
echo            then start Docker Desktop; it recreates it.
echo         e) Last resort: Docker Desktop -^> Troubleshoot (bug icon)
echo            -^> "Reset to factory defaults".
echo      Test with:  docker run --rm hello-world
echo.
echo Press any key to close this window...
pause >nul
endlocal
goto :eof

REM ------------------------------------------------------------
REM  run_timed <seconds> "<docker arguments>"
REM  Runs docker with a hard timeout. Output goes to %OUT%.
REM  Returns 0 on success, 2 on timeout, otherwise docker's code.
REM ------------------------------------------------------------
:run_timed
del "%OUT%" "%OUT%.err" >nul 2>&1
set "T_SEC=%~1"
set "D_ARGS=%~2"
if not defined PS_OK goto :run_plain
set /a T_MS=%T_SEC%*1000
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; $a=$env:D_ARGS -split ' '; $p=Start-Process -FilePath 'docker' -ArgumentList $a -NoNewWindow -PassThru -RedirectStandardOutput $env:OUT -RedirectStandardError \"$env:OUT.err\"; if(-not $p.WaitForExit([int]$env:T_MS)){ try{$p.Kill()}catch{}; exit 2 }; exit $p.ExitCode" >nul 2>&1
exit /b %ERRORLEVEL%
:run_plain
docker %D_ARGS% >"%OUT%" 2>&1
exit /b %ERRORLEVEL%
