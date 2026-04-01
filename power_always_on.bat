@echo off
chcp 65001 >nul 2>&1
setlocal

:: ============================================================
::  TENEBRIO 3D HEATMAP - Configurar equipo 24/7 sin suspensión
:: ============================================================

title Tenebrio Heatmap - Configurar energia 24/7

:: Verificar permisos de administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Este script requiere permisos de administrador.
    echo         Haz clic derecho y selecciona "Ejecutar como administrador".
    pause
    exit /b 1
)

echo.
echo ============================================================
echo   CONFIGURACION DE ENERGIA 24/7
echo ============================================================
echo.

:: ============================================================
:: 1. Crear plan de energia personalizado "Tenebrio 24/7"
:: ============================================================
echo [1/5] Creando plan de energia "Tenebrio 24/7"...

:: GUID fijo para poder identificar y actualizar el plan
set "PLAN_GUID=e9a42b02-d5df-448d-aa00-03f14749eb61"

:: Verificar si el plan ya existe
powercfg /list | findstr /I "%PLAN_GUID%" >nul 2>&1
if %errorlevel% equ 0 (
    echo       Plan ya existe. Actualizando configuracion...
) else (
    :: Duplicar el plan activo y renombrarlo
    powercfg /duplicatescheme 381b4222-f694-41f0-9685-ff5bb260df2e %PLAN_GUID% >nul 2>&1
    if %errorlevel% neq 0 (
        echo [ERROR] No se pudo crear el plan de energia.
        pause
        exit /b 1
    )
)

:: Renombrar el plan
powercfg /changename %PLAN_GUID% "Tenebrio 24/7" "Equipo siempre encendido para monitoreo de temperatura"

echo       OK

:: ============================================================
:: 2. Desactivar suspensión y hibernación
:: ============================================================
echo.
echo [2/5] Desactivando suspension e hibernacion...

:: Suspensión del sistema: Nunca (AC = corriente, DC = batería)
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0

:: Hibernación: Nunca
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0

:: Desactivar hibernación completamente
powercfg /hibernate off >nul 2>&1

echo       OK - Suspension e hibernacion desactivadas.

:: ============================================================
:: 3. Configurar pantalla (apagar después de 5 min para ahorro)
:: ============================================================
echo.
echo [3/5] Configurando pantalla...

:: Apagar monitor después de 5 minutos (ahorra energia sin suspender)
powercfg /change monitor-timeout-ac 5
powercfg /change monitor-timeout-dc 5

echo       OK - Monitor se apagara a los 5 min (el equipo sigue activo).

:: ============================================================
:: 4. Activar el plan de energía
:: ============================================================
echo.
echo [4/5] Activando plan "Tenebrio 24/7"...

powercfg /setactive %PLAN_GUID%

echo       OK - Plan activado.

:: ============================================================
:: 5. Desactivar inicio rápido (evita problemas con servicios)
:: ============================================================
echo.
echo [5/5] Desactivando inicio rapido de Windows...

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f >nul 2>&1

echo       OK

:: ============================================================
:: Resumen
:: ============================================================
echo.
echo ============================================================
echo   CONFIGURACION COMPLETADA
echo ============================================================
echo.
echo   Plan activo:      Tenebrio 24/7
echo   Suspension:       DESACTIVADA
echo   Hibernacion:      DESACTIVADA
echo   Inicio rapido:    DESACTIVADO
echo   Monitor:          Se apaga a los 5 min (equipo sigue activo)
echo.
echo   El equipo permanecera encendido 24/7.
echo   Para revertir, selecciona otro plan en:
echo   Panel de control ^> Opciones de energia
echo.
echo ============================================================

:: Mostrar plan activo para confirmar
echo.
echo Plan de energia activo:
powercfg /getactivescheme

pause
