# ============================================================
#  TENEBRIO 3D HEATMAP - Configurar equipo 24/7 sin suspension
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "  CONFIGURACION DE ENERGIA 24/7"
Write-Host "============================================================"
Write-Host ""

# --- 1. Crear o encontrar plan de energia "Tenebrio 24/7" ---
Write-Host "[1/5] Creando plan de energia 'Tenebrio 24/7'..."

$guidRegex = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
$planGuid = $null

# Buscar si ya existe
$lines = & powercfg /list 2>&1 | Out-String
foreach ($line in $lines -split "`n") {
    if ($line -match "Tenebrio" -and $line -match "($guidRegex)") {
        $planGuid = $matches[1]
        Write-Host "      Plan ya existe ($planGuid). Actualizando configuracion..."
        break
    }
}

# Si no existe, duplicar el plan activo
if (-not $planGuid) {
    $activeOut = & powercfg /getactivescheme 2>&1 | Out-String
    if ($activeOut -match "($guidRegex)") {
        $activeGuid = $matches[1]
    } else {
        Write-Host "[ERROR] No se pudo obtener el plan activo."
        exit 1
    }

    $dupOut = & powercfg /duplicatescheme $activeGuid 2>&1 | Out-String
    if ($dupOut -match "($guidRegex)") {
        $planGuid = $matches[1]
    } else {
        Write-Host "[ERROR] No se pudo duplicar el plan de energia."
        Write-Host "        Salida: $dupOut"
        exit 1
    }
}

# Renombrar el plan
& powercfg /changename $planGuid "Tenebrio 24/7" "Equipo siempre encendido para monitoreo de temperatura"
Write-Host "      OK"

# --- 2. Desactivar suspension e hibernacion ---
Write-Host ""
Write-Host "[2/5] Desactivando suspension e hibernacion..."

& powercfg /change standby-timeout-ac 0
& powercfg /change standby-timeout-dc 0
& powercfg /change hibernate-timeout-ac 0
& powercfg /change hibernate-timeout-dc 0
& powercfg /hibernate off 2>$null

Write-Host "      OK - Suspension e hibernacion desactivadas."

# --- 3. Configurar pantalla ---
Write-Host ""
Write-Host "[3/5] Configurando pantalla..."

& powercfg /change monitor-timeout-ac 5
& powercfg /change monitor-timeout-dc 5

Write-Host "      OK - Monitor se apagara a los 5 min (el equipo sigue activo)."

# --- 4. Activar el plan ---
Write-Host ""
Write-Host "[4/5] Activando plan 'Tenebrio 24/7'..."

& powercfg /setactive $planGuid

Write-Host "      OK - Plan activado."

# --- 5. Desactivar inicio rapido ---
Write-Host ""
Write-Host "[5/5] Desactivando inicio rapido de Windows..."

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue

Write-Host "      OK"

# --- Resumen ---
Write-Host ""
Write-Host "============================================================"
Write-Host "  CONFIGURACION COMPLETADA"
Write-Host "============================================================"
Write-Host ""
Write-Host "  Plan activo:      Tenebrio 24/7"
Write-Host "  Suspension:       DESACTIVADA"
Write-Host "  Hibernacion:      DESACTIVADA"
Write-Host "  Inicio rapido:    DESACTIVADO"
Write-Host "  Monitor:          Se apaga a los 5 min (equipo sigue activo)"
Write-Host ""
Write-Host "  El equipo permanecera encendido 24/7."
Write-Host "  Para revertir, selecciona otro plan en:"
Write-Host "  Panel de control > Opciones de energia"
Write-Host ""
Write-Host "============================================================"
Write-Host ""
Write-Host "Plan de energia activo:"
& powercfg /getactivescheme
