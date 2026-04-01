@echo off
chcp 65001 >nul 2>&1
setlocal

:: ============================================================
::  TENEBRIO 3D HEATMAP - Detener y desinstalar servicio
::  Deja el equipo limpio como antes de ejecutar setup_service.bat
:: ============================================================

set "SERVICE_NAME=TenebrioHeatmap"

title Tenebrio Heatmap - Detener y limpiar servicio

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

echo.
echo ============================================================
echo   DETENIENDO Y LIMPIANDO SERVICIO
echo ============================================================

:: ============================================================
:: 1. Detener servicio
:: ============================================================
echo.
echo [1/4] Deteniendo servicio "%SERVICE_NAME%"...

nssm status %SERVICE_NAME% >nul 2>&1
if %errorlevel% neq 0 (
    echo       El servicio no esta instalado. Nada que detener.
    goto KILL_PROCESSES
)

nssm stop %SERVICE_NAME% >nul 2>&1
timeout /t 3 /nobreak >nul

:: Forzar si no respondio
for /f "tokens=3" %%p in ('sc queryex %SERVICE_NAME% ^| findstr PID') do (
    if %%p neq 0 taskkill /PID %%p /T /F >nul 2>&1
)

echo       OK

:: ============================================================
:: 2. Desinstalar servicio de NSSM
:: ============================================================
echo.
echo [2/4] Desinstalando servicio de NSSM...

nssm remove %SERVICE_NAME% confirm >nul 2>&1
timeout /t 2 /nobreak >nul

echo       OK

:: ============================================================
:: 3. Matar procesos residuales y liberar puerto 5000
:: ============================================================
:KILL_PROCESSES
echo.
echo [3/4] Liberando puerto 5000 y cerrando procesos residuales...

:: Matar cualquier python ejecutando main.py
powershell -Command "Get-WmiObject Win32_Process -Filter \"Name='python.exe'\" | Where-Object { $_.CommandLine -match 'main\.py' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }" >nul 2>&1

:: Liberar puerto 5000
powershell -Command "Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }" >nul 2>&1

echo       OK

:: ============================================================
:: 4. Detener vigilante de Edge (edge_killer)
:: ============================================================
echo.
echo [4/7] Deteniendo vigilante de Edge...

:: Matar edge_killer.bat y cualquier cmd que lo ejecute
powershell -Command "Get-WmiObject Win32_Process -Filter \"Name='cmd.exe'\" | Where-Object { $_.CommandLine -match 'edge_killer' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }" >nul 2>&1

echo       OK

:: ============================================================
:: 5. Cerrar navegador en modo kiosko y restaurar barra de tareas
:: ============================================================
echo.
echo [5/7] Cerrando navegador en modo kiosko...

:: Matar Chrome kiosko con localhost:5000
powershell -Command "Get-WmiObject Win32_Process -Filter \"Name='chrome.exe'\" | Where-Object { $_.CommandLine -match 'kiosk|localhost:5000' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }" >nul 2>&1

:: Matar Edge residual
taskkill /F /IM msedge.exe >nul 2>&1

:: Restaurar barra de tareas (desactivar auto-ocultar)
echo       Restaurando barra de tareas...
powershell -Command "$p = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'; $v = (Get-ItemProperty -Path $p).Settings; $v[8] = 2; Set-ItemProperty -Path $p -Name Settings -Value $v" >nul 2>&1
powershell -Command "Stop-Process -Name explorer -Force" >nul 2>&1
timeout /t 3 /nobreak >nul

echo       OK

:: ============================================================
:: 6. Eliminar kiosko del inicio de sesion
:: ============================================================
echo.
echo [6/7] Eliminando kiosko del inicio de sesion...

:: Eliminar tarea programada si existe
schtasks /delete /tn "TenebrioKiosk" /f >nul 2>&1

:: Eliminar archivo de la carpeta Startup
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\TenebrioKiosk.bat" >nul 2>&1

echo       OK

:: ============================================================
:: 7. Limpiar inicio automatico del navegador con localhost
:: ============================================================
echo.
echo [7/7] Limpiando inicio automatico...

:: Eliminar entradas del registro que abran localhost al inicio
powershell -Command "
$paths = @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Run','HKLM:\Software\Microsoft\Windows\CurrentVersion\Run');
foreach ($p in $paths) {
    Get-ItemProperty -Path $p -ErrorAction SilentlyContinue | ForEach-Object {
        $_.PSObject.Properties | Where-Object { $_.Value -match 'localhost:5000|kiosk' } | ForEach-Object {
            Remove-ItemProperty -Path $p -Name $_.Name -Force -ErrorAction SilentlyContinue;
            Write-Host ('      Eliminado del registro: ' + $_.Name)
        }
    }
}
" 2>nul

:: Eliminar del Startup del usuario
powershell -Command "
$startup = [Environment]::GetFolderPath('Startup');
Get-ChildItem $startup -ErrorAction SilentlyContinue | Where-Object { (Get-Content $_.FullName -ErrorAction SilentlyContinue) -match 'localhost:5000|kiosk|TenebrioHeatmap' } | ForEach-Object {
    Remove-Item $_.FullName -Force;
    Write-Host ('      Eliminado de Startup: ' + $_.Name)
}
" 2>nul

echo       OK

:: ============================================================
:: Resumen
:: ============================================================
echo.
echo ============================================================
echo   LIMPIEZA COMPLETADA
echo ============================================================
echo.
echo   Servicio:           Desinstalado
echo   Puerto 5000:        Liberado
echo   Vigilante Edge:     Detenido
echo   Navegador kiosko:   Cerrado
echo   Inicio de sesion:   Limpiado
echo   Inicio automatico:  Limpiado
echo.
echo   El equipo esta limpio. Para volver a instalar:
echo   Ejecuta setup_service.bat como administrador.
echo.
echo ============================================================
pause
