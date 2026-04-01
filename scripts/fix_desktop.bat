@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

:: ============================================================
::  DIAGNOSTICO Y REPARACION DE ESCRITORIO WINDOWS 10
::  Problema: no se ve el escritorio, solo el cajon de apps
:: ============================================================

title Diagnostico de escritorio Windows 10

echo.
echo ============================================================
echo   DIAGNOSTICO DE ESCRITORIO WINDOWS 10
echo ============================================================
echo.

set "PROBLEMAS=0"

:: ============================================================
:: 1. Verificar si explorer.exe esta corriendo
:: ============================================================
echo [1/7] Verificando explorer.exe...

tasklist /FI "IMAGENAME eq explorer.exe" 2>nul | findstr /I "explorer.exe" >nul 2>&1
if %errorlevel% neq 0 (
    echo       [PROBLEMA] explorer.exe NO esta corriendo.
    echo       [SOLUCION] Iniciando explorer.exe...
    start explorer.exe
    timeout /t 3 /nobreak >nul
    set /a PROBLEMAS+=1
) else (
    echo       OK - explorer.exe esta corriendo.
)

:: ============================================================
:: 2. Verificar iconos del escritorio
:: ============================================================
echo.
echo [2/7] Verificando visibilidad de iconos del escritorio...

reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideIcons 2>nul | findstr "0x1" >nul 2>&1
if %errorlevel% equ 0 (
    echo       [PROBLEMA] Los iconos del escritorio estan OCULTOS.
    echo       [SOLUCION] Activando iconos del escritorio...
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideIcons /t REG_DWORD /d 0 /f >nul 2>&1
    set /a PROBLEMAS+=1
) else (
    echo       OK - Iconos del escritorio visibles.
)

:: ============================================================
:: 3. Verificar modo tableta
:: ============================================================
echo.
echo [3/7] Verificando modo tableta...

reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\ImmersiveShell" /v TabletMode 2>nul | findstr "0x1" >nul 2>&1
if %errorlevel% equ 0 (
    echo       [PROBLEMA] El modo tableta esta ACTIVADO.
    echo       [SOLUCION] Desactivando modo tableta...
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ImmersiveShell" /v TabletMode /t REG_DWORD /d 0 /f >nul 2>&1
    set /a PROBLEMAS+=1
) else (
    echo       OK - Modo tableta desactivado.
)

:: ============================================================
:: 4. Verificar shell de Windows
:: ============================================================
echo.
echo [4/7] Verificando shell de Windows...

for /f "tokens=3*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell 2^>nul ^| findstr Shell') do set "SHELL_VAL=%%a %%b"
set "SHELL_VAL=!SHELL_VAL: =!"

if /I not "!SHELL_VAL!"=="explorer.exe" (
    echo       [PROBLEMA] El shell NO es explorer.exe, es: !SHELL_VAL!
    echo       [SOLUCION] Restaurando explorer.exe como shell...
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "explorer.exe" /f >nul 2>&1
    set /a PROBLEMAS+=1
) else (
    echo       OK - Shell es explorer.exe.
)

:: ============================================================
:: 5. Verificar configuracion de inicio en pantalla completa
:: ============================================================
echo.
echo [5/7] Verificando inicio en pantalla completa...

reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo 2>nul | findstr "0x0" >nul 2>&1
if %errorlevel% equ 0 (
    echo       [PROBLEMA] El explorador esta configurado para abrir en pantalla completa.
    echo       [SOLUCION] Configurando para abrir en escritorio...
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d 1 /f >nul 2>&1
    set /a PROBLEMAS+=1
) else (
    echo       OK - Inicio normal del explorador.
)

:: ============================================================
:: 6. Verificar si hay apps en pantalla completa bloqueando
:: ============================================================
echo.
echo [6/7] Verificando procesos en pantalla completa...

powershell -Command "
$fullscreen = @();
Add-Type -TypeDefinition '
using System;
using System.Runtime.InteropServices;
public class ScreenCheck {
    [DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow();
    [DllImport(\"user32.dll\")] public static extern int GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport(\"user32.dll\")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
}';
$hw = [ScreenCheck]::GetForegroundWindow();
$rect = New-Object ScreenCheck+RECT;
[ScreenCheck]::GetWindowRect($hw, [ref]$rect) | Out-Null;
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds;
$pid = 0; [ScreenCheck]::GetWindowThreadProcessId($hw, [ref]$pid) | Out-Null;
$proc = Get-Process -Id $pid -ErrorAction SilentlyContinue;
if ($rect.Left -le 0 -and $rect.Top -le 0 -and $rect.Right -ge $screen.Width -and $rect.Bottom -ge $screen.Height -and $proc.Name -ne 'explorer') {
    Write-Host \"FULLSCREEN:$($proc.Name) (PID: $pid)\";
} else {
    Write-Host 'NONE';
}
" 2>nul | findstr "FULLSCREEN" >nul 2>&1
if %errorlevel% equ 0 (
    echo       [PROBLEMA] Hay una aplicacion en pantalla completa bloqueando el escritorio.
    echo       [SOLUCION] Presiona Alt+F4 o Win+D para minimizar.
    set /a PROBLEMAS+=1
) else (
    echo       OK - No hay apps bloqueando en pantalla completa.
)

:: ============================================================
:: 7. Verificar resolucion y escala de pantalla
:: ============================================================
echo.
echo [7/7] Verificando pantalla...

powershell -Command "
Add-Type -AssemblyName System.Windows.Forms;
$s = [System.Windows.Forms.Screen]::PrimaryScreen;
Write-Host \"      Resolucion: $($s.Bounds.Width)x$($s.Bounds.Height)\";
Write-Host \"      Area de trabajo: $($s.WorkingArea.Width)x$($s.WorkingArea.Height)\";
$scale = (Get-ItemProperty 'HKCU:\Control Panel\Desktop\WindowMetrics' -ErrorAction SilentlyContinue).AppliedDPI;
if ($scale) { $pct = [math]::Round($scale / 96 * 100); Write-Host \"      Escala: $pct%%\" }
" 2>nul

:: ============================================================
:: Resumen y acciones
:: ============================================================
echo.
echo ============================================================

if %PROBLEMAS% equ 0 (
    echo   No se encontraron problemas automaticos.
    echo.
    echo   Prueba estas soluciones manuales:
    echo.
    echo   1. Presiona Win+D para mostrar el escritorio
    echo   2. Clic derecho en escritorio ^> Ver ^> Mostrar iconos del escritorio
    echo   3. Reinicia explorer: Ctrl+Shift+Esc ^> Archivo ^> Nueva tarea ^> explorer.exe
    echo   4. Si nada funciona, reinicia el equipo
) else (
    echo   Se encontraron y corrigieron %PROBLEMAS% problema(s).
    echo.
    echo   Es necesario reiniciar explorer.exe para aplicar los cambios.
    echo.
    set /p RESTART="  Reiniciar explorer ahora? (S/N): "
    if /I "!RESTART!"=="S" (
        echo.
        echo   Reiniciando explorer.exe...
        taskkill /F /IM explorer.exe >nul 2>&1
        timeout /t 2 /nobreak >nul
        start explorer.exe
        echo   OK - Explorer reiniciado. El escritorio deberia aparecer.
    )
)

echo.
echo ============================================================
pause
