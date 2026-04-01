@echo off
:: ============================================================
::  EDGE KILLER - Mata Edge cada 10 segundos en segundo plano
::  No cierra explorer.exe ni taskmgr.exe
::  Para detenerlo: ejecuta stop_service.bat o mata edge_killer
:: ============================================================

:LOOP
tasklist /FI "IMAGENAME eq msedge.exe" 2>nul | findstr /I "msedge.exe" >nul 2>&1
if %errorlevel% equ 0 (
    taskkill /F /IM msedge.exe >nul 2>&1
)

timeout /t 10 /nobreak >nul
goto LOOP
