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
nssm stop %SERVICE_NAME% >nul 2>&1
timeout /t 3 /nobreak >nul

:: Verificar si el servicio realmente se detuvo
nssm status %SERVICE_NAME% 2>nul | findstr /I "SERVICE_STOPPED" >nul 2>&1
if %errorlevel% neq 0 (
    echo [AVISO] El servicio no respondio al stop. Forzando detencion...
    :: Obtener PID del proceso del servicio y matarlo
    for /f "tokens=3" %%p in ('sc queryex %SERVICE_NAME% ^| findstr PID') do (
        if %%p neq 0 (
            taskkill /PID %%p /T /F >nul 2>&1
        )
    )
    :: Matar cualquier proceso python ejecutando main.py
    powershell -Command "Get-WmiObject Win32_Process -Filter \"Name='python.exe'\" | Where-Object { $_.CommandLine -match 'main\.py' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }" >nul 2>&1
    timeout /t 2 /nobreak >nul
)

:: Verificar que el puerto 5000 ya no esta en uso
powershell -Command "$c = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue; if ($c) { $c | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue } }" >nul 2>&1

:: Confirmacion final
nssm status %SERVICE_NAME% 2>nul | findstr /I "SERVICE_STOPPED" >nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo OK - Servicio detenido completamente.
) else (
    echo.
    echo OK - Procesos terminados. El servicio puede tardar unos segundos en reflejar el estado.
)

echo     Para reiniciar: ejecuta restart_service.bat
echo     Para desinstalar: nssm remove %SERVICE_NAME%
pause
