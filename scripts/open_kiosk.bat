@echo off
:: ============================================================
::  TENEBRIO 3D HEATMAP - Abrir Chrome en modo kiosko
::  Se ejecuta al iniciar sesion via tarea programada
:: ============================================================

set "APP_URL=http://localhost:5000"
set "WAIT_SECONDS=15"

:: Esperar a que el servicio Flask arranque
timeout /t %WAIT_SECONDS% /nobreak >nul

:: Matar Edge e iniciar vigilante en segundo plano
taskkill /F /IM msedge.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start /min "" cmd /c "%~dp0edge_killer.bat"

:: Detectar Chrome
set "BROWSER="
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" set "BROWSER=C:\Program Files\Google\Chrome\Application\chrome.exe"
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" set "BROWSER=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"

if not defined BROWSER exit /b 1

:: Ocultar barra de tareas automaticamente
powershell -Command "$p = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'; $v = (Get-ItemProperty -Path $p).Settings; $v[8] = 3; Set-ItemProperty -Path $p -Name Settings -Value $v" >nul 2>&1
:: Reiniciar explorer para aplicar (no cierra ventanas del usuario)
powershell -Command "Stop-Process -Name explorer -Force" >nul 2>&1
timeout /t 3 /nobreak >nul

:: Abrir Chrome en modo kiosko
start "" "%BROWSER%" --kiosk --new-window --no-first-run --no-default-browser-check --no-restore --disable-translate --disable-extensions "%APP_URL%"
