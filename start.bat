@echo off
REM ============================================================
REM  Maildir Archive Server - Start
REM
REM  Pure ASCII on purpose: CMD parses .bat files with the OEM
REM  codepage, so non-ASCII text can be read as command separators
REM  (& | < >) and break the script. Persian lives in the
REM  PowerShell scripts and the docs.
REM
REM  Why this file is a wrapper:
REM  When you double-click a .bat, Windows runs it with "cmd /c",
REM  and ANY fatal error inside closes the window instantly - too
REM  fast to read. So we re-launch ourselves inside "cmd /k",
REM  which never auto-closes. The real logic is in _start-main.bat.
REM ============================================================

cd /d "%~dp0"

REM ---- Re-launch once inside a console that cannot auto-close ----
if not defined MAS_RELAUNCHED (
    set "MAS_RELAUNCHED=1"
    start "Maildir Archive Server" cmd /k "cd /d "%~dp0" && set MAS_RELAUNCHED=1 && call "%~f0""
    exit /b
)

title Maildir Archive Server - Start

if not exist "_start-main.bat" goto :missing

REM "call" returns control here even if the inner script fails.
call "_start-main.bat"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
    echo.
    echo [note] The startup script ended with exit code %RC%.
)
goto :hold

:missing
echo.
echo [ERROR] _start-main.bat was not found next to start.bat.
echo         Re-extract the ZIP so both files end up in the same
echo         folder, then run start.bat again.

:hold
echo.
echo If anything above is unclear, run start-debug.bat - it saves
echo a full log to start-log.txt that you can send for help.
echo.
echo This window will stay open. Close it when you are done,
echo or type EXIT and press Enter.
echo.
pause
