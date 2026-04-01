@echo off
:: ============================================================
::  TENEBRIO 3D HEATMAP - Configurar equipo 24/7 sin suspension
::  Ejecuta el script de PowerShell que configura la energia
:: ============================================================

:: Verificar permisos de administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Este script requiere permisos de administrador.
    echo         Haz clic derecho y selecciona "Ejecutar como administrador".
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0power_always_on.ps1"
pause
