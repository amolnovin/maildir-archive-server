@echo off
REM ============================================================
REM  Maildir Archive Server - Start (debug / logging mode)
REM
REM  Use this when start.bat closes too fast to read.
REM  Everything, including errors, is written to start-log.txt.
REM  Pure ASCII on purpose.
REM ============================================================

cd /d "%~dp0"
title Maildir Archive Server - Start (debug)

set "LOG=%~dp0start-log.txt"

echo Writing a full log to:
echo   %LOG%
echo.
echo Please wait, this can take up to a minute...
echo.

REM Header first, then the run, then the environment snapshot.
> "%LOG%" echo === Maildir Archive Server start log ===
>>"%LOG%" echo Date: %DATE% %TIME%
>>"%LOG%" echo Folder: %CD%
>>"%LOG%" echo.
>>"%LOG%" echo --- docker --version ---
docker --version >>"%LOG%" 2>&1
>>"%LOG%" echo.
>>"%LOG%" echo --- Docker Desktop service ---
sc query "com.docker.service" >>"%LOG%" 2>&1
>>"%LOG%" echo.
>>"%LOG%" echo --- wsl --status ---
wsl --status >>"%LOG%" 2>&1
>>"%LOG%" echo.
>>"%LOG%" echo --- startup run ---

if not exist "_start-main.bat" goto :missing

REM Run the real script; show it on screen and append to the log.
call "_start-main.bat" >>"%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
>>"%LOG%" echo.
>>"%LOG%" echo --- exit code: %RC% ---

REM Now show the log on screen too.
type "%LOG%"
goto :hold

:missing
echo [ERROR] _start-main.bat was not found next to this file.
>>"%LOG%" echo [ERROR] _start-main.bat not found.

:hold
echo.
echo ==========================================
echo   Log saved to: %LOG%
echo   If you need help, send that file.
echo ==========================================
echo.
echo Press any key to close this window...
pause >nul
