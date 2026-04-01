@echo off
chcp 65001 >nul 2>&1
setlocal

:: ============================================================
::  TENEBRIO 3D HEATMAP - Detener servicio
:: ============================================================

set "SERVICE_NAME=TenebrioHeatmap"

title Tenebrio Heatmap - Detener servicio

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
    pause
    exit /b 1
)

:: Verificar si ya esta detenido
for /f "tokens=*" %%s in ('nssm status %SERVICE_NAME% 2^>^&1') do set "STATUS=%%s"
if "%STATUS%"=="SERVICE_STOPPED" (
    echo El servicio "%SERVICE_NAME%" ya esta detenido.
    pause
    exit /b 0
)

echo.
echo Deteniendo servicio "%SERVICE_NAME%"...
nssm stop %SERVICE_NAME%
if %errorlevel% neq 0 (
    echo [ERROR] No se pudo detener el servicio.
    echo         Ejecuta: nssm status %SERVICE_NAME%
    pause
    exit /b 1
)

echo.
echo OK - Servicio detenido completamente.
echo     Para reiniciar: ejecuta restart_service.bat
echo     Para desinstalar: nssm remove %SERVICE_NAME%
pause
