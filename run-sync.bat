@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-projects-to-github.ps1"
endlocal
