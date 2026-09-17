@echo off
REM ============================================================
REM  Maildir Archive Server - import a DirectAdmin backup
REM  (Docker mode - the server must be running)
REM
REM  Windows blocks .ps1 files by default (ExecutionPolicy), which
REM  gives "running scripts is disabled on this system".
REM  This launcher passes -ExecutionPolicy Bypass for you, which
REM  applies ONLY to this run and changes no system setting.
REM
REM  Usage:
REM     import-backup.bat
REM     import-backup.bat "D:\backup\backup-Feb-09-2026-1.tar.gz"
REM     (or drag the backup onto this file)
REM
REM  Pure ASCII on purpose - see the note in start.bat
REM ============================================================

setlocal EnableExtensions
cd /d "%~dp0"
title Maildir Archive Server - Import backup

echo ==========================================
echo   Import a DirectAdmin backup  (Docker)
echo ==========================================
echo.

if not exist "scripts\Import-DirectAdminBackup.ps1" goto :missing

REM ---- Is the server running? ----
set "UP="
docker ps --filter "name=mas-dovecot" --filter "status=running" --format "{{.Names}}" 2>nul | find "mas-dovecot" >nul 2>&1
if not errorlevel 1 set "UP=1"
if not defined UP goto :not_running

REM ---- Which backup? ----
set "SRC=%~1"
if not "%SRC%"=="" goto :have_src

echo Drag the backup onto this window, or type its path below.
echo.
echo It accepts either:
echo    - the .tar.gz file straight from DirectAdmin
echo         D:\backup\backup-Feb-09-2026-1.tar.gz
echo    - or an already extracted folder
echo         D:\backup\extracted
echo.
set /p "SRC=Backup file or folder: "
if "%SRC%"=="" goto :no_src

:have_src
set "SRC=%SRC:"=%"
if not exist "%SRC%" goto :bad_src

echo.
echo [INFO] Source: %SRC%
echo.
set /p "PW=Password for the imported accounts [Archive2026!]: "
if "%PW%"=="" set "PW=Archive2026!"

echo.
echo [INFO] Importing. Large backups can take several minutes...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\Import-DirectAdminBackup.ps1" -Source "%SRC%" -CreateAccounts -DefaultPassword "%PW%"
if errorlevel 1 goto :failed

echo.
echo ==========================================
echo   Done
echo ==========================================
echo.
echo   Web panel : http://localhost:8080
echo.
echo   Connect Thunderbird:
echo      Server   : localhost
echo      Port     : 143   (STARTTLS)
echo      Username : the full email address
echo      Password : %PW%
echo      SMTP     : none - this is an archive only
echo.
echo   See what was imported:
echo      run-script.bat Get-Mailboxes
echo.
goto :done

:missing
echo [ERROR] scripts\Import-DirectAdminBackup.ps1 was not found.
echo         Run this file from inside the project folder, and make
echo         sure the ZIP was extracted completely.
echo         Current folder: %CD%
goto :done

:not_running
echo [ERROR] The mail server is not running.
echo.
echo         Start it first:
echo             start.bat
echo.
echo         Then run this file again.
echo.
echo         If Docker itself will not start, run:
echo             check-docker.bat
echo.
echo         No Docker at all? Use the converter instead - it needs
echo         nothing but Windows:
echo             convert-to-mbox.bat
goto :done

:no_src
echo [ERROR] No backup given.
goto :done

:bad_src
echo [ERROR] Not found:
echo         %SRC%
echo         Tip: drag the file onto this .bat instead of typing it.
goto :done

:failed
echo.
echo [ERROR] Import failed. See the messages above.
echo         For a dry run that only lists what is inside the backup:
echo             run-script.bat Import-DirectAdminBackup -Source "%SRC%" -WhatIfOnly
goto :done

:done
echo.
echo Press any key to close this window...
pause >nul
endlocal
