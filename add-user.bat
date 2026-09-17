@echo off
REM ============================================================
REM  Maildir Archive Server - create or update one mail account
REM  (Docker mode - the server must be running)
REM
REM  Windows blocks .ps1 files by default (ExecutionPolicy), which
REM  gives "running scripts is disabled on this system".
REM  This launcher passes -ExecutionPolicy Bypass for you, which
REM  applies ONLY to this run and changes no system setting.
REM
REM  Usage:
REM     add-user.bat
REM     add-user.bat info@komajsaba.com
REM     add-user.bat info@komajsaba.com MyPassword
REM
REM  Pure ASCII on purpose - see the note in start.bat
REM ============================================================

setlocal EnableExtensions
cd /d "%~dp0"
title Maildir Archive Server - Add user

echo ==========================================
echo   Create a mail account
echo ==========================================
echo.

if not exist "scripts\Add-User.ps1" goto :missing

REM ---- Is the server running? ----
set "UP="
docker ps --filter "name=mas-dovecot" --filter "status=running" --format "{{.Names}}" 2>nul | find "mas-dovecot" >nul 2>&1
if not errorlevel 1 set "UP=1"
if not defined UP goto :not_running

REM ---- Email address ----
set "EMAIL=%~1"
if not "%EMAIL%"=="" goto :have_email
echo Enter the full email address, for example  info@komajsaba.com
echo.
set /p "EMAIL=Email: "
if "%EMAIL%"=="" goto :no_email

:have_email
set "EMAIL=%EMAIL:"=%"

REM ---- Password ----
set "PW=%~2"
if not "%PW%"=="" goto :have_pw
echo.
set /p "PW=Password [Archive2026!]: "
if "%PW%"=="" set "PW=Archive2026!"

:have_pw
set "PW=%PW:"=%"

echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\Add-User.ps1" -Email "%EMAIL%" -Password "%PW%" -Force
if errorlevel 1 goto :failed

echo.
echo ==========================================
echo   Done
echo ==========================================
echo.
echo   Connect Thunderbird:
echo      Server   : localhost
echo      Port     : 143   (STARTTLS)
echo      Username : %EMAIL%
echo      Password : %PW%
echo      SMTP     : none - this is an archive only
echo.
echo   Web panel : http://localhost:8080
echo.
goto :done

:missing
echo [ERROR] scripts\Add-User.ps1 was not found.
echo         Run this file from inside the project folder.
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
echo         No Docker at all? Accounts are only needed for the Docker
echo         mode. To just read the backup, use:
echo             convert-to-mbox.bat
goto :done

:no_email
echo [ERROR] No email address given.
goto :done

:failed
echo.
echo [ERROR] Could not create the account. See the messages above.
goto :done

:done
echo.
echo Press any key to close this window...
pause >nul
endlocal
