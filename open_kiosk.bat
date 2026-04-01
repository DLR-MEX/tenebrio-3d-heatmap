@echo off
:: ============================================================
::  TENEBRIO 3D HEATMAP - Abrir navegador en modo kiosko
::  Se ejecuta al iniciar sesion via tarea programada
:: ============================================================

set "APP_URL=http://localhost:5000"
set "WAIT_SECONDS=15"

:: Esperar a que el servicio Flask arranque
timeout /t %WAIT_SECONDS% /nobreak >nul

:: Cerrar cualquier Edge/Chrome con localhost:5000 anterior
taskkill /F /IM msedge.exe >nul 2>&1
timeout /t 2 /nobreak >nul

:: Detectar navegador
set "BROWSER="
if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" set "BROWSER=C:\Program Files\Microsoft\Edge\Application\msedge.exe"
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" set "BROWSER=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" set "BROWSER=C:\Program Files\Google\Chrome\Application\chrome.exe"
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" set "BROWSER=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"

if not defined BROWSER exit /b 1

:: Abrir en modo kiosko (Edge debe estar cerrado para que funcione)
start "" "%BROWSER%" --kiosk --new-window --no-first-run --no-default-browser-check --no-restore "%APP_URL%"
