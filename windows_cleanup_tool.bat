@echo off
chcp 65001 >nul
title PC Clean & Optimize Tool
echo ============================================
echo    PC Clean and Optimize Tool (Chinese)
echo ============================================
echo.
echo This tool cleans C-drive cache safely and
echo optionally disables unnecessary startup items.
echo It will NOT delete your personal files.
echo.
echo Requesting administrator rights...
echo If a UAC prompt appears, please click YES.
echo.
pause
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0cleanup_optimize.ps1"
