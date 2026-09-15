@echo off
REM ============================================================
REM  Maildir Archive Server
REM  Convert a DirectAdmin Maildir backup to mbox files.
REM
REM  NO Docker. NO WSL. NO virtualization. Just PowerShell.
REM  Use this when Docker cannot run on your machine.
REM
REM  Pure ASCII on purpose - see the note in start.bat
REM ============================================================

setlocal EnableExtensions
cd /d "%~dp0"
title Maildir Archive Server - Convert to mbox

echo ==========================================
echo   Maildir  to  mbox  converter
echo   (no Docker required)
echo ==========================================
echo.

if not exist "scripts\Convert-MaildirToMbox.ps1" goto :missing

set "SRC=%~1"
if not "%SRC%"=="" goto :have_src

echo Drag the backup onto this file, or type its path below.
echo.
echo It accepts either:
echo    - the .tar.gz backup file straight from DirectAdmin
echo         D:\mail\backup-Feb-09-2026-1.tar.gz
echo    - or an already extracted folder
echo         D:\backup\extracted
echo.
set /p "SRC=Backup file or folder: "
if "%SRC%"=="" goto :no_src

:have_src
REM strip surrounding quotes if the user pasted a quoted path
set "SRC=%SRC:"=%"

if not exist "%SRC%" goto :bad_src

echo.
echo [INFO] Source: %SRC%
echo [INFO] Output: %CD%\mbox-export
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\Convert-MaildirToMbox.ps1" -Source "%SRC%" -Destination "%CD%\mbox-export"
if errorlevel 1 goto :failed

echo.
echo [OK] Done. Open the mbox-export folder to see your files.
echo.
echo Import them into Thunderbird:
echo    1. Right-click "Local Folders"
echo    2. ImportExportTools NG  ^>  Import mbox file
echo    3. Choose "Import directly one or more mbox files"
echo    4. Select the .mbox files from mbox-export
echo.
goto :done

:missing
echo [ERROR] scripts\Convert-MaildirToMbox.ps1 was not found.
echo         Re-extract the ZIP completely.
goto :done

:no_src
echo [ERROR] No folder given.
goto :done

:bad_src
echo [ERROR] Not found:
echo         %SRC%
echo         Check the path and try again.
echo         Tip: drag the file or folder onto this .bat instead of
echo              typing the path by hand.
goto :done

:failed
echo.
echo [ERROR] Conversion failed. See the messages above.
echo         If PowerShell refused to run the script, try:
echo             powershell -ExecutionPolicy Bypass -File scripts\Convert-MaildirToMbox.ps1 -Source "%SRC%"
goto :done

:done
echo.
echo Press any key to close this window...
pause >nul
endlocal
