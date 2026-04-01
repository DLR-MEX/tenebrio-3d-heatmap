@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

:: ============================================================
::  TENEBRIO 3D HEATMAP - Instalador de servicio Windows (NSSM)
:: ============================================================

:: --- Configuración ---
set "SERVICE_NAME=TenebrioHeatmap"
set "PROJECT_DIR=%~dp0.."
set "BACKEND_DIR=%PROJECT_DIR%\backend"
set "VENV_DIR=%PROJECT_DIR%\venv"
set "PYTHON_VENV=%VENV_DIR%\Scripts\python.exe"
set "REQUIREMENTS=%PROJECT_DIR%\requirements.txt"
set "MAIN_SCRIPT=%BACKEND_DIR%\main.py"
set "LOGS_DIR=%PROJECT_DIR%\logs"
set "APP_URL=http://localhost:5000"
set "WAIT_SECONDS=8"

:: Quitar barra final de las rutas (NSSM puede fallar con ella)
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
if "%BACKEND_DIR:~-1%"=="\" set "BACKEND_DIR=%BACKEND_DIR:~0,-1%"
if "%VENV_DIR:~-1%"=="\" set "VENV_DIR=%VENV_DIR:~0,-1%"
if "%LOGS_DIR:~-1%"=="\" set "LOGS_DIR=%LOGS_DIR:~0,-1%"

title Tenebrio Heatmap - Instalador de servicio

:: ============================================================
:: 1. Verificar permisos de administrador
:: ============================================================
echo.
echo [1/8] Verificando permisos de administrador...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Este script requiere permisos de administrador.
    echo         Haz clic derecho y selecciona "Ejecutar como administrador".
    pause
    exit /b 1
)
echo       OK - Ejecutando como administrador.

:: ============================================================
:: 2. Verificar que NSSM existe en el PATH
:: ============================================================
echo.
echo [2/8] Verificando NSSM...
where nssm >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] NSSM no se encontro en el PATH.
    echo         Descarga NSSM desde https://nssm.cc/download
    echo         y coloca nssm.exe en una carpeta que este en el PATH del sistema.
    pause
    exit /b 1
)
echo       OK - NSSM encontrado.

:: ============================================================
:: 3. Verificar que Python existe
:: ============================================================
echo.
echo [3/8] Verificando Python...
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python no se encontro en el PATH.
    echo         Instala Python 3.10+ desde https://python.org
    pause
    exit /b 1
)

:: Verificar version minima (3.10)
for /f "tokens=2 delims= " %%v in ('python --version 2^>^&1') do set "PY_VERSION=%%v"
echo       OK - Python %PY_VERSION% encontrado.

:: ============================================================
:: 4. Crear entorno virtual e instalar dependencias
:: ============================================================
echo.
echo [4/8] Configurando entorno virtual...

if not exist "%PYTHON_VENV%" (
    echo       Creando entorno virtual en %VENV_DIR%...
    python -m venv "%VENV_DIR%"
    if %errorlevel% neq 0 (
        echo [ERROR] No se pudo crear el entorno virtual.
        pause
        exit /b 1
    )
    echo       Entorno virtual creado.
) else (
    echo       Entorno virtual ya existe.
)

echo       Instalando dependencias...
"%PYTHON_VENV%" -m pip install --upgrade pip >nul 2>&1
"%PYTHON_VENV%" -m pip install -r "%REQUIREMENTS%" >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] No se pudieron instalar las dependencias.
    echo         Revisa requirements.txt y la conexion a internet.
    pause
    exit /b 1
)
echo       OK - Dependencias instaladas.

:: ============================================================
:: 5. Crear carpeta de logs
:: ============================================================
echo.
echo [5/8] Preparando carpeta de logs...
if not exist "%LOGS_DIR%" (
    mkdir "%LOGS_DIR%"
    echo       Carpeta logs creada.
) else (
    echo       Carpeta logs ya existe.
)

:: ============================================================
:: 6. Instalar/actualizar servicio con NSSM
:: ============================================================
echo.
echo [6/8] Configurando servicio "%SERVICE_NAME%"...

:: Detener servicio si ya existe
nssm status %SERVICE_NAME% >nul 2>&1
if %errorlevel% equ 0 (
    echo       Deteniendo servicio existente...
    nssm stop %SERVICE_NAME% >nul 2>&1
    timeout /t 3 /nobreak >nul
    :: Forzar terminacion si no respondio
    for /f "tokens=3" %%p in ('sc queryex %SERVICE_NAME% ^| findstr PID') do (
        if %%p neq 0 taskkill /PID %%p /T /F >nul 2>&1
    )
    powershell -Command "Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }" >nul 2>&1
    timeout /t 2 /nobreak >nul
    echo       Removiendo servicio anterior...
    nssm remove %SERVICE_NAME% confirm >nul 2>&1
    timeout /t 2 /nobreak >nul
)

:: Instalar servicio
nssm install %SERVICE_NAME% "%PYTHON_VENV%" "%MAIN_SCRIPT%"
if %errorlevel% neq 0 (
    echo [ERROR] No se pudo instalar el servicio.
    pause
    exit /b 1
)

:: Configurar directorio de trabajo
nssm set %SERVICE_NAME% AppDirectory "%BACKEND_DIR%"

:: Redirigir stdout/stderr de NSSM a un solo archivo (sin rotación)
:: Los logs principales los gestiona log_config.py en logs/YYYY-MM/YYYY-MM-DD.log
nssm set %SERVICE_NAME% AppStdout "%LOGS_DIR%\nssm_service.log"
nssm set %SERVICE_NAME% AppStderr "%LOGS_DIR%\nssm_service.log"
nssm set %SERVICE_NAME% AppStdoutCreationDisposition 2
nssm set %SERVICE_NAME% AppStderrCreationDisposition 2
nssm set %SERVICE_NAME% AppRotateFiles 0

:: Configurar reinicio automático ante fallos
nssm set %SERVICE_NAME% AppRestartDelay 5000
nssm set %SERVICE_NAME% AppExit Default Restart

:: Descripción del servicio
nssm set %SERVICE_NAME% DisplayName "Tenebrio 3D Heatmap"
nssm set %SERVICE_NAME% Description "Sistema de visualizacion 3D de temperatura para cuarto de cria de tenebrios"
nssm set %SERVICE_NAME% Start SERVICE_AUTO_START

echo       OK - Servicio instalado y configurado.

:: ============================================================
:: 7. Iniciar servicio
:: ============================================================
echo.
echo [7/8] Iniciando servicio...
nssm start %SERVICE_NAME%
if %errorlevel% neq 0 (
    echo [ERROR] No se pudo iniciar el servicio.
    echo         Revisa los logs en: %LOGS_DIR%
    echo         Comando: nssm status %SERVICE_NAME%
    pause
    exit /b 1
)

echo       Servicio iniciado correctamente.

:: ============================================================
:: 8. Crear tarea programada para abrir kiosko al iniciar sesion
:: ============================================================
echo.
echo [8/8] Configurando kiosko automatico al iniciar sesion...

set "KIOSK_SCRIPT=%~dp0open_kiosk.bat"
set "TASK_NAME=TenebrioKiosk"

:: Eliminar tarea anterior si existe
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

:: Crear tarea que se ejecuta al iniciar sesion de cualquier usuario
schtasks /create /tn "%TASK_NAME%" /tr "\"%KIOSK_SCRIPT%\"" /sc onlogon /rl highest /f >nul 2>&1
if %errorlevel% neq 0 (
    echo [AVISO] No se pudo crear la tarea programada.
    echo         El kiosko no se abrira automaticamente al encender.
) else (
    echo       OK - Kiosko se abrira automaticamente al iniciar sesion.
)

:: Abrir kiosko ahora
echo.
echo       Esperando %WAIT_SECONDS% segundos para que el servidor arranque...
timeout /t %WAIT_SECONDS% /nobreak >nul

echo       Desactivando Edge completamente...
taskkill /F /IM msedge.exe >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v StartupBoostEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v BackgroundModeEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v AllowPrelaunch /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v RestoreOnStartup /t REG_DWORD /d 5 /f >nul 2>&1
timeout /t 2 /nobreak >nul

:: Iniciar edge_killer en segundo plano
echo       Iniciando vigilante de Edge en segundo plano...
start /min "" cmd /c "%~dp0edge_killer.bat"

echo       Abriendo Chrome en modo kiosko...
call :OPEN_KIOSK

:: ============================================================
:: Resumen final
:: ============================================================
echo.
echo ============================================================
echo   INSTALACION COMPLETADA
echo ============================================================
echo.
echo   Servicio:      %SERVICE_NAME% (auto-inicia con Windows)
echo   Kiosko:        %TASK_NAME% (auto-abre al iniciar sesion)
echo   URL:           %APP_URL%
echo   Logs app:      %LOGS_DIR%\YYYY-MM\YYYY-MM-DD.log
echo   Logs NSSM:     %LOGS_DIR%\nssm_service.log
echo.
echo   Comandos utiles:
echo     nssm status %SERVICE_NAME%     - Ver estado
echo     nssm stop %SERVICE_NAME%       - Detener
echo     nssm start %SERVICE_NAME%      - Iniciar
echo     nssm restart %SERVICE_NAME%    - Reiniciar
echo.
echo   Para desinstalar todo: ejecuta stop_service.bat
echo.
echo ============================================================
pause
exit /b 0

:: ============================================================
:: Subrutina: abrir Chrome en modo kiosko (pantalla completa)
:: ============================================================
:OPEN_KIOSK
set "BROWSER="
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" set "BROWSER=C:\Program Files\Google\Chrome\Application\chrome.exe"
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" set "BROWSER=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"

if not defined BROWSER (
    echo [ERROR] Chrome no esta instalado. Instala Google Chrome para modo kiosko.
    goto :EOF
)

start "" "%BROWSER%" --kiosk --new-window --no-first-run --no-default-browser-check --no-restore "%APP_URL%"

:: Traer ventana al frente
timeout /t 3 /nobreak >nul
powershell -Command "Add-Type -Name W -Namespace N -MemberDefinition '[DllImport(\"user32.dll\")] public static extern bool SetForegroundWindow(IntPtr h);'; $p = Get-Process | Where-Object { $_.MainWindowTitle -ne '' -and ($_.Name -eq 'chrome') } | Select-Object -First 1; if ($p) { [N.W]::SetForegroundWindow($p.MainWindowHandle) }" >nul 2>&1

goto :EOF
