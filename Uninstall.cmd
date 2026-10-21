@echo off
setlocal DisableDelayedExpansion
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Uninstall.ps1"
set "result=%errorlevel%"
if not defined SIGNAPK_NO_PAUSE pause
exit /b %result%
