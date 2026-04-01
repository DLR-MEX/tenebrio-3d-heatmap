@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

:: ============================================================
::  DIAGNOSTICO Y DESACTIVACION DE EDGE
::  Evita que Edge se abra automaticamente o interfiera
:: ============================================================

title Diagnostico y desactivacion de Edge

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
echo   DIAGNOSTICO DE EDGE
echo ============================================================

set "FIXES=0"

:: ============================================================
:: 1. Matar todos los procesos de Edge
:: ============================================================
echo.
echo [1/9] Matando procesos de Edge...

tasklist /FI "IMAGENAME eq msedge.exe" 2>nul | findstr /I "msedge.exe" >nul 2>&1
if %errorlevel% equ 0 (
    taskkill /F /IM msedge.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    echo       Procesos de Edge terminados.
    set /a FIXES+=1
) else (
    echo       OK - Edge no esta corriendo.
)

:: ============================================================
:: 2. Desactivar Startup Boost (Edge se precarga al iniciar)
:: ============================================================
echo.
echo [2/9] Verificando Startup Boost...

reg query "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v StartupBoostEnabled 2>nul | findstr "0x0" >nul 2>&1
if %errorlevel% neq 0 (
    echo       [PROBLEMA] Startup Boost activo o no configurado.
    echo       [SOLUCION] Desactivando...
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v StartupBoostEnabled /t REG_DWORD /d 0 /f >nul 2>&1
    set /a FIXES+=1
) else (
    echo       OK - Startup Boost desactivado.
)

:: ============================================================
:: 3. Desactivar modo en segundo plano de Edge
:: ============================================================
echo.
echo [3/9] Verificando modo en segundo plano...

reg query "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v BackgroundModeEnabled 2>nul | findstr "0x0" >nul 2>&1
if %errorlevel% neq 0 (
    echo       [PROBLEMA] Modo en segundo plano activo.
    echo       [SOLUCION] Desactivando...
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v BackgroundModeEnabled /t REG_DWORD /d 0 /f >nul 2>&1
    set /a FIXES+=1
) else (
    echo       OK - Modo en segundo plano desactivado.
)

:: ============================================================
:: 4. Desactivar prelanzamiento de Edge
:: ============================================================
echo.
echo [4/9] Verificando prelanzamiento de Edge...

reg query "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v AllowPrelaunch 2>nul | findstr "0x0" >nul 2>&1
if %errorlevel% neq 0 (
    echo       [PROBLEMA] Prelanzamiento activo.
    echo       [SOLUCION] Desactivando...
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v AllowPrelaunch /t REG_DWORD /d 0 /f >nul 2>&1
    set /a FIXES+=1
) else (
    echo       OK - Prelanzamiento desactivado.
)

:: ============================================================
:: 5. Desactivar restauracion de pestanas al inicio
:: ============================================================
echo.
echo [5/9] Verificando restauracion de pestanas...

reg query "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v RestoreOnStartup 2>nul | findstr "0x5" >nul 2>&1
if %errorlevel% neq 0 (
    echo       [PROBLEMA] Edge restaura pestanas anteriores.
    echo       [SOLUCION] Configurando para abrir pagina nueva...
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v RestoreOnStartup /t REG_DWORD /d 5 /f >nul 2>&1
    set /a FIXES+=1
) else (
    echo       OK - Restauracion de pestanas desactivada.
)

:: ============================================================
:: 6. Eliminar Edge del inicio automatico del registro
:: ============================================================
echo.
echo [6/9] Verificando registro de inicio automatico...

for %%k in (
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    "HKLM\Software\Microsoft\Windows\CurrentVersion\Run"
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
) do (
    reg query %%k 2>nul | findstr /I "edge" >nul 2>&1
    if !errorlevel! equ 0 (
        echo       [PROBLEMA] Edge encontrado en %%k
        for /f "tokens=1" %%v in ('reg query %%k 2^>nul ^| findstr /I "edge"') do (
            reg delete %%k /v "%%v" /f >nul 2>&1
            echo       [SOLUCION] Eliminado: %%v
        )
        set /a FIXES+=1
    )
)
echo       OK

:: ============================================================
:: 7. Eliminar Edge de la carpeta Startup
:: ============================================================
echo.
echo [7/9] Verificando carpeta Startup...

powershell -Command "
$paths = @(
    [Environment]::GetFolderPath('Startup'),
    [Environment]::GetFolderPath('CommonStartup')
);
foreach ($p in $paths) {
    Get-ChildItem $p -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match 'edge' -or
        (Get-Content $_.FullName -ErrorAction SilentlyContinue) -match 'msedge|edge'
    } | ForEach-Object {
        Remove-Item $_.FullName -Force;
        Write-Host ('      [SOLUCION] Eliminado de Startup: ' + $_.Name)
    }
}
" 2>nul

echo       OK

:: ============================================================
:: 8. Eliminar tareas programadas de Edge
:: ============================================================
echo.
echo [8/9] Verificando tareas programadas de Edge...

for /f "tokens=1" %%t in ('schtasks /query /fo list 2^>nul ^| findstr /I "MicrosoftEdge"') do (
    echo       [PROBLEMA] Tarea encontrada: %%t
)

schtasks /query /fo list 2>nul | findstr /I "MicrosoftEdge" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2 delims=:" %%t in ('schtasks /query /fo list 2^>nul ^| findstr /I "MicrosoftEdge"') do (
        set "TASKNAME=%%t"
        set "TASKNAME=!TASKNAME:~1!"
        schtasks /change /tn "!TASKNAME!" /disable >nul 2>&1
        echo       [SOLUCION] Desactivada: !TASKNAME!
    )
    set /a FIXES+=1
) else (
    echo       OK - No hay tareas programadas de Edge.
)

:: ============================================================
:: 9. Quitar Edge como navegador predeterminado para localhost
:: ============================================================
echo.
echo [9/9] Verificando asociaciones de protocolo...

powershell -Command "
$assoc = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice' -ErrorAction SilentlyContinue;
if ($assoc.ProgId -match 'Edge') {
    Write-Host '      [PROBLEMA] Edge es el navegador predeterminado para HTTP.';
    Write-Host '      [SOLUCION] Cambia el navegador predeterminado a Chrome:';
    Write-Host '      Configuracion > Aplicaciones > Aplicaciones predeterminadas > Navegador web > Chrome';
} else {
    Write-Host '      OK - Edge no es el navegador predeterminado.';
}
" 2>nul

:: ============================================================
:: Resumen
:: ============================================================
echo.
echo ============================================================
if %FIXES% equ 0 (
    echo   No se encontraron problemas con Edge.
) else (
    echo   Se aplicaron %FIXES% correcciones.
)
echo.
echo   Edge esta configurado para:
echo     - No iniciarse automaticamente
echo     - No precargarse en segundo plano
echo     - No restaurar pestanas anteriores
echo     - No ejecutarse al inicio de Windows
echo.
echo   Si Edge sigue abriendose, ve a:
echo   Configuracion ^> Aplicaciones ^> Aplicaciones predeterminadas
echo   y selecciona Chrome como navegador predeterminado.
echo.
echo ============================================================
pause
