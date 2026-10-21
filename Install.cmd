@echo off
setlocal DisableDelayedExpansion
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1"
set "result=%errorlevel%"
if not defined SIGNAPK_NO_PAUSE pause
exit /b %result%
