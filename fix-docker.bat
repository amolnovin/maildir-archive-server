@echo off
REM ============================================================
REM  Maildir Archive Server - Docker repair tool
REM
REM  For this exact symptom:
REM      com.docker.service   STATE: STOPPED
REM      WIN32_EXIT_CODE : 1077 (0x435)
REM  1077 = ERROR_SERVICE_NEVER_STARTED, meaning Windows never even
REM  tried to start the service since the last boot. Usually the
REM  service is set to Manual and Docker Desktop was not run with
REM  the rights needed to start it.
REM
REM  This script needs Administrator rights and will ask for them.
REM  Pure ASCII on purpose.
REM ============================================================

cd /d "%~dp0"
title Maildir Archive Server - Docker repair

REM ---- Elevate to Administrator if we are not already ----
net session >nul 2>&1
if not errorlevel 1 goto :elevated

echo Administrator rights are required to start the Docker service.
echo A UAC prompt will appear - please choose Yes.
echo.
powershell -NoProfile -Command "Start-Process -FilePath \"%~f0\" -Verb RunAs" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Could not elevate automatically.
    echo         Right-click this file and choose "Run as administrator".
    echo.
    pause
)
exit /b

:elevated
echo ==========================================
echo   Docker repair  (running as Administrator)
echo ==========================================
echo.

echo [1/6] Current service status:
sc query "com.docker.service" | findstr /i "STATE"
echo.

echo [2/6] Setting the service to start automatically...
sc config "com.docker.service" start= auto >nul 2>&1
if errorlevel 1 (
    echo       FAILED. Is Docker Desktop actually installed?
) else (
    echo       OK - startup type is now Automatic.
)
echo.

echo [3/6] Starting the service...
sc start "com.docker.service" >nul 2>&1
REM  Give the service a moment to come up. ping is used instead of
REM  "timeout" because timeout fails when input is redirected.
ping -n 7 127.0.0.1 >nul 2>&1
sc query "com.docker.service" | findstr /i "STATE"
sc query "com.docker.service" | findstr /i "RUNNING" >nul 2>&1
if errorlevel 1 (
    echo       Service is still not RUNNING. Docker Desktop itself may
    echo       start it - continuing with the remaining steps.
) else (
    echo       OK - the service is running.
)
echo.

echo [4/6] Adding you to the "docker-users" group...
echo       (members of this group may use Docker without admin rights)
net localgroup docker-users "%USERNAME%" /add >nul 2>&1
net localgroup docker-users "%USERDOMAIN%\%USERNAME%" /add >nul 2>&1
echo       Done. You must sign out and back in for this to take effect.
echo.

echo [5/6] Resetting the WSL backend...
wsl --shutdown >nul 2>&1
echo       Done.
echo.

echo [6/6] Launching Docker Desktop...
if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" (
    start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
    echo       Started. Wait until the bottom-left corner of the
    echo       Docker Desktop window says "Engine running".
    echo       This can take 1-3 minutes.
) else (
    echo       Docker Desktop.exe not found in the default location.
    echo       Please start Docker Desktop manually.
)
echo.

echo ==========================================
echo   What to do now
echo ==========================================
echo.
echo   1. Wait for Docker Desktop to show "Engine running".
echo.
echo   2. Verify in a NEW terminal:
echo         docker run --rm hello-world
echo.
echo   3. If that prints a greeting, run start.bat
echo.
echo   If the service still refuses to start:
echo     - Sign out of Windows and sign back in (needed for the
echo       docker-users group change), then try again.
echo     - Make sure virtualization is enabled. Open Task Manager,
echo       go to Performance, click CPU, and check that
echo       "Virtualization" says Enabled.
echo     - Repair the install: Settings, Apps, Docker Desktop,
echo       Modify, then Repair. Reboot afterwards.
echo.
echo Press any key to close this window...
pause >nul
