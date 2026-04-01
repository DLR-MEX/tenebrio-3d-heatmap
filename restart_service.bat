@echo off
chcp 65001 >nul 2>&1
setlocal

:: ============================================================
::  TENEBRIO 3D HEATMAP - Reiniciar servicio
:: ============================================================

set "SERVICE_NAME=TenebrioHeatmap"
set "APP_URL=http://localhost:5000"
set "WAIT_SECONDS=8"

title Tenebrio Heatmap - Reiniciar servicio

:: Verificar permisos de administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Este script requiere permisos de administrador.
    echo         Haz clic derecho y selecciona "Ejecutar como administrador".
    pause
    exit /b 1
)

:: Verificar que NSSM existe
where nssm >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] NSSM no se encontro en el PATH.
    pause
    exit /b 1
)

:: Verificar que el servicio existe
nssm status %SERVICE_NAME% >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] El servicio "%SERVICE_NAME%" no esta instalado.
    echo         Ejecuta primero setup_service.bat
    pause
    exit /b 1
)

echo.
echo Reiniciando servicio "%SERVICE_NAME%"...
nssm restart %SERVICE_NAME%
if %errorlevel% neq 0 (
    echo [ERROR] No se pudo reiniciar el servicio.
    echo         Ejecuta: nssm status %SERVICE_NAME%
    pause
    exit /b 1
)

echo Servicio reiniciado. Esperando %WAIT_SECONDS% segundos...
timeout /t %WAIT_SECONDS% /nobreak >nul

echo Abriendo navegador...
start "" "%APP_URL%"

echo.
echo OK - Servicio reiniciado en %APP_URL%
pause
