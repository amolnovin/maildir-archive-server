@echo off
REM ============================================================
REM  Maildir Archive Server - run a PowerShell script safely
REM
REM  Windows blocks .ps1 files by default (ExecutionPolicy), which
REM  gives the error:
REM      "... cannot be loaded because running scripts is disabled
REM       on this system."
REM
REM  This launcher always passes -ExecutionPolicy Bypass, which
REM  applies ONLY to this single run. It does not change any
REM  system setting.
REM
REM  Usage:
REM     run-script.bat Get-Mailboxes
REM     run-script.bat Add-Domain -Domain komajsaba.com
REM     run-script.bat Import-DirectAdminBackup -Source "D:\b.tar.gz" -CreateAccounts
REM
REM  The .ps1 extension is optional.
REM
REM  Pure ASCII on purpose - see the note in start.bat
REM ============================================================

setlocal EnableExtensions
cd /d "%~dp0"
title Maildir Archive Server - Run script

if "%~1"=="" goto :usage

set "NAME=%~1"
REM allow both "Get-Mailboxes" and "Get-Mailboxes.ps1"
if /i not "%NAME:~-4%"==".ps1" set "NAME=%NAME%.ps1"

set "TARGET=scripts\%NAME%"
if not exist "%TARGET%" goto :not_found

REM  Pass the remaining arguments through with their quoting intact.
REM  Using %* and stripping the first token keeps quoted paths that
REM  contain spaces in one piece - rebuilding them with shift/%1
REM  would split "D:\my mail\x.tar.gz" into two arguments.
set "ARGS=%*"
call :strip_first %*
goto :run

:strip_first
set "FIRST=%~1"
call set "ARGS=%%ARGS:*%1=%%"
exit /b 0

:run
echo [INFO] Running: %TARGET%%ARGS%
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%TARGET%"%ARGS%
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" echo [note] The script ended with exit code %RC%.
goto :done

:usage
echo ==========================================
echo   Run a project PowerShell script
echo ==========================================
echo.
echo This wrapper adds -ExecutionPolicy Bypass for you, so Windows
echo does not block the script.
echo.
echo Usage:
echo    run-script.bat ^<ScriptName^> [arguments]
echo.
echo Available scripts:
for %%F in (scripts\*.ps1) do echo    %%~nF
echo.
echo Examples:
echo    run-script.bat Get-Mailboxes
echo    run-script.bat Add-Domain -Domain komajsaba.com
echo    run-script.bat Convert-MaildirToMbox -Source "D:\mail\backup.tar.gz"
echo.
goto :done

:not_found
echo [ERROR] Script not found: %TARGET%
echo.
echo Available scripts:
for %%F in (scripts\*.ps1) do echo    %%~nF
echo.
echo Also check that you are running this from the project folder.
echo Current folder: %CD%
goto :done

:done
echo.
echo Press any key to close this window...
pause >nul
endlocal
