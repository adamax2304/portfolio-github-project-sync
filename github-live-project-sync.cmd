@echo off
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Users\adama\Documents\github-project-sync\watch-and-sync.ps1" -DebounceSeconds 20 -PeriodicSyncHours 12
