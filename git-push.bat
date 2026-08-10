@echo off
REM ============================================================
REM  Maildir Archive Server - commit and push to GitHub
REM
REM  Usage:
REM     git-push.bat "your commit message"
REM     git-push.bat                 (asks for the message)
REM
REM  The first push asks for your GitHub username and a Personal
REM  Access Token as the password. Tick "remember" in the Windows
REM  credential dialog and it will not ask again.
REM
REM  SECURITY: never put the token inside this file or in the
REM  remote URL - it would end up in the repo history.
REM
REM  Pure ASCII on purpose.
REM ============================================================

setlocal EnableExtensions
cd /d "%~dp0"
title Maildir Archive Server - Push to GitHub

echo ==========================================
echo   Commit and push to GitHub
echo ==========================================
echo.

where git.exe >nul 2>&1
if errorlevel 1 goto :no_git
if not exist ".git" goto :no_repo

echo [INFO] Changes to be committed:
echo.
git status --short
echo.

REM  "git status --porcelain" prints one line per change and nothing
REM  at all when the tree is clean. That is the simplest reliable test.
set "DIRTY="
for /f "delims=" %%L in ('git status --porcelain 2^>nul') do set "DIRTY=1"
if not defined DIRTY goto :nothing

set "MSG=%~1"
if not "%MSG%"=="" goto :have_msg
set /p "MSG=Commit message: "
if "%MSG%"=="" set "MSG=Update"

:have_msg
echo.
echo [INFO] Staging all changes...
git add -A
if errorlevel 1 goto :failed

echo [INFO] Committing...
git commit -m "%MSG%"
if errorlevel 1 goto :failed

echo [INFO] Pushing to GitHub...
git push origin main
if errorlevel 1 goto :push_failed

echo.
echo [OK] Pushed successfully.
echo      https://github.com/amolnovin/maildir-archive-server
goto :done

:nothing
echo [INFO] Nothing to commit - the working tree is clean.
goto :done

:no_git
echo [ERROR] git was not found.
echo         Install Git for Windows: https://git-scm.com/download/win
goto :done

:no_repo
echo [ERROR] This folder is not a git repository.
echo         Clone it instead:
echo             git clone https://github.com/amolnovin/maildir-archive-server.git
goto :done

:push_failed
echo.
echo [ERROR] Push failed. Common causes:
echo.
echo   1. Wrong credentials. Use your GitHub username and a
echo      Personal Access Token as the password (not your
echo      account password).
echo.
echo   2. The remote has newer commits. Pull first:
echo          git pull --rebase origin main
echo      then run this file again.
echo.
echo   3. Token expired or missing "repo" / "Contents: write"
echo      permission. Create a new one at:
echo          https://github.com/settings/tokens
echo.
echo   To clear a saved bad credential:
echo      Control Panel  ^>  Credential Manager  ^>  Windows Credentials
echo      then remove the git:https://github.com entry.
goto :done

:failed
echo.
echo [ERROR] The git command failed. See the messages above.

:done
echo.
echo Press any key to close this window...
pause >nul
endlocal
