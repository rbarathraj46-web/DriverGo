\
@echo off
REM Setup script (Windows) - calls PowerShell interactive script
SET SCRIPT_DIR=%~dp0
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%setup_env.ps1"
pause
