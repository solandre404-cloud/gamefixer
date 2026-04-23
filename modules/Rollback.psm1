# ============================================================================
#  modules/Rollback.psm1
#  Restauracion de backups del registro y creacion de puntos de restauracion
# ============================================================================

function Invoke-Rollback {
    do {
        Clear-Host
        Show-Section "SEGURIDAD Y RESPALDO"

        Write-UI "  Esta seccion protege tu sistema: crea puntos de restauracion," -Color Cyan
        Write-UI "  revierte cambios si algo sale mal, y gestiona claves de seguridad." -Color Cyan
        Write-Host ""
        Write-UI "  [1] Ver backups del registro creados por GameFixer" -Color Yellow
        Write-UI "  [2] Restaurar registro al estado previo (ultimo backup)" -Color Yellow
        Write-UI "  [3] Crear PUNTO DE RESTAURACION de Windows (recomendado antes de tweaks)" -Color Yellow
        Write-UI "  [4] Abrir menu clasico de Restauracion de Sistema (Windows)" -Color Yellow
        Write-UI "  [5] Resetear TPM (AVANZADO - leer advertencias)" -Color Red
        Write-UI "  [B] Volver al menu principal" -Color Yellow
        Write-Host ""
        Write-UI "  > " -Color Cyan -NoNewline
        $sub = (Read-Host).Trim().ToUpper()

        switch ($sub) {
            '1' { Show-Backups;              Pause-Submenu }
            '2' { Restore-LastBackup;        Pause-Submenu }
            '3' { New-SystemRestorePoint;    Pause-Submenu }
            '4' { Start-Process 'rstrui.exe';Pause-Submenu }
            '5' { Reset-TPMKeys;             Pause-Submenu }
            'B' { return }
            default { }
        }
    } while ($true)
}

function Show-Backups {
    Write-Host ""
    Write-UI "Backups en: $($Global:GF.BackupsDir)" -Color Cyan
    $backups = Get-ChildItem $Global:GF.BackupsDir -Directory -ErrorAction SilentlyContinue |
               Sort-Object LastWriteTime -Descending
    if (-not $backups) {
        Write-UI "  (sin backups)" -Color DarkGray
        return
    }
    foreach ($b in $backups) {
        $files = Get-ChildItem $b.FullName -Filter '*.reg' -ErrorAction SilentlyContinue
        Write-UI ("  $($b.Name) [$($files.Count) archivos] - $($b.LastWriteTime)") -Color Green
    }
}

function Restore-LastBackup {
    Write-Host ""
    $latest = Get-ChildItem $Global:GF.BackupsDir -Directory -ErrorAction SilentlyContinue |
              Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) {
        Write-UI "  No hay backups para restaurar." -Color Yellow
        return
    }
    Write-UI ("Ultimo backup: $($latest.Name)") -Color Cyan
    $regs = Get-ChildItem $latest.FullName -Filter '*.reg'
    foreach ($r in $regs) {
        Invoke-LoggedAction -Description "Restaurar $($r.Name)" -Action {
            & reg import $r.FullName 2>&1 | Out-Null
        }
    }
    Write-UI "  Restauracion aplicada." -Color Green
}

function New-SystemRestorePoint {
    Write-Host ""
    Write-UI "=== PUNTO DE RESTAURACION DEL SISTEMA ===" -Color Cyan
    Write-Host ""
    Write-UI "Un punto de restauracion permite volver a este estado si algo sale mal." -Color Green
    Write-UI "Se guarda en el registro del sistema, no ocupa mucho espacio." -Color DarkGray
    Write-Host ""

    $description = "GameFixer $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

    # En MODO PRUEBA: hacer el preview completo mostrando cada paso como si fuera a ejecutarse
    if ($Global:GF.DryRun) {
        Write-UI "  [PRUEBA] Mostrando lo que HARIA (ningun cambio aplicado):" -Color DarkYellow
        Write-Host ""

        Write-UI "  Paso 1/3: verificar estado de System Restore" -Color Cyan
        try {
            $enabled = $false
            try {
                Get-ComputerRestorePoint -ErrorAction Stop | Out-Null
                $enabled = $true
            } catch {}
            if ($enabled) {
                Write-UI "    -> YA activo en C:" -Color Green
            } else {
                Write-UI "    -> SE HABILITARIA con: Enable-ComputerRestore -Drive 'C:\\'" -Color DarkYellow
            }
        } catch {
            Write-UI "    -> Chequeo no concluyente" -Color DarkYellow
        }

        Write-UI "  Paso 2/3: permitir crear uno ahora" -Color Cyan
        Write-UI "    -> SE AJUSTARIA: HKLM\\...\\SystemRestore SystemRestorePointCreationFrequency = 0" -Color DarkYellow

        Write-UI "  Paso 3/3: crear punto" -Color Cyan
        Write-UI ("    -> SE CREARIA: Checkpoint-Computer -Description `"$description`" -RestorePointType MODIFY_SETTINGS") -Color DarkYellow

        Write-Host ""
        Write-UI "  Para aplicar estos cambios: pulsa [D] en el menu principal y vuelve a entrar." -Color Yellow
        return
    }

    # LIVE mode: ejecutar de verdad
    Write-UI "  Paso 1/3: verificando estado de System Restore..." -Color Cyan
    try {
        $enabled = $false
        try {
            Get-ComputerRestorePoint -ErrorAction Stop | Out-Null
            $enabled = $true
        } catch {}

        if (-not $enabled) {
            Write-UI "    System Restore no activo. Habilitando para C:..." -Color Yellow
            Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop
            Write-UI "    [OK] System Restore habilitado" -Color Green
        } else {
            Write-UI "    [OK] System Restore ya activo" -Color Green
        }
    } catch {
        Write-UI ("    [!] No se pudo habilitar: " + $_.Exception.Message) -Color Red
        Write-UI "    Tip: puede estar desactivado por politica de grupo" -Color DarkYellow
    }

    Write-UI "  Paso 2/3: ajustando frecuencia..." -Color Cyan
    try {
        $regKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
        if (-not (Test-Path $regKey)) { New-Item -Path $regKey -Force | Out-Null }
        Set-ItemProperty -Path $regKey -Name 'SystemRestorePointCreationFrequency' -Value 0 -Type DWord -Force
        Write-UI "    [OK]" -Color Green
    } catch {
        Write-UI "    [!] No se pudo ajustar frecuencia (sigue adelante)" -Color Yellow
    }

    Write-UI "  Paso 3/3: creando punto de restauracion..." -Color Cyan
    try {
        Checkpoint-Computer -Description $description -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
        Write-UI "    [OK] Punto creado: `"$description`"" -Color Green
        Write-UI "    Verlo con: systempropertiesprotection.exe" -Color DarkGray
        Write-Log -Level INFO -Message "Restore point creado: $description"
        if (Test-SoundEnabled) { Play-SuccessChime }
    } catch {
        Write-UI ("    [X] Error: " + $_.Exception.Message) -Color Red
        Write-UI "    Causas posibles:" -Color Yellow
        Write-UI "      - System Restore desactivado por politica" -Color DarkGray
        Write-UI "      - Ya se creo uno muy reciente (Windows limita a uno cada 24h)" -Color DarkGray
        Write-UI "      - Espacio insuficiente reservado" -Color DarkGray
    }
}

function Reset-TPMKeys {
    Write-Host ""
    Write-UI "===================================================================" -Color Red
    Write-UI "  ADVERTENCIA CRITICA - RESETEO DE TPM" -Color Red
    Write-UI "===================================================================" -Color Red
    Write-Host ""
    Write-UI "  Esta operacion BORRA TODAS las llaves del Trusted Platform Module." -Color Yellow
    Write-Host ""
    Write-UI "  Consecuencias directas:" -Color Yellow
    Write-UI "    - BitLocker se desbloqueara: necesitas la CLAVE DE RECUPERACION para bootear" -Color Red
    Write-UI "    - Windows Hello (PIN, huella, cara): hay que reconfigurarlo de cero" -Color Red
    Write-UI "    - Certificados de dominio/VPN/WiFi 802.1x pueden perderse" -Color Red
    Write-UI "    - Windows pedira configurar TPM desde BIOS/UEFI al reiniciar" -Color Red
    Write-UI "    - REINICIO OBLIGATORIO del equipo" -Color Red
    Write-Host ""
    Write-UI "  PRECONDICIONES (revisar antes de continuar):" -Color Yellow
    Write-UI "    1. Tenes guardada la clave de recuperacion de BitLocker? (si lo usas)" -Color Cyan
    Write-UI "       Verifica en: https://account.microsoft.com/devices/recoverykey" -Color DarkGray
    Write-UI "    2. Sabes como entrar a la BIOS/UEFI (F2/DEL al arrancar)?" -Color Cyan
    Write-UI "    3. Hiciste backup de archivos criticos?" -Color Cyan
    Write-Host ""

    if ($Global:GF.DryRun) {
        Write-UI "  [PRUEBA] Mostrando lo que HARIA:" -Color DarkYellow
        Write-UI "    1. Get-Tpm (consulta estado actual)" -Color DarkYellow
        Write-UI "    2. Pide confirmacion escribiendo 'RESETEAR TPM'" -Color DarkYellow
        Write-UI "    3. Clear-Tpm -ErrorAction Stop" -Color DarkYellow
        Write-UI "    4. Ofrece Restart-Computer -Force con countdown de 10s" -Color DarkYellow
        Write-Host ""
        Write-UI "  Para ejecutar: pulsa [D] en menu principal para salir del modo prueba." -Color Yellow
        return
    }

    # LIVE mode
    Write-UI "  Estado actual del TPM:" -Color Cyan
    try {
        $tpm = Get-Tpm -ErrorAction Stop
        Write-UI ("    Presente       : " + $tpm.TpmPresent) -Color Green
        Write-UI ("    Habilitado     : " + $tpm.TpmEnabled) -Color Green
        Write-UI ("    Preparado      : " + $tpm.TpmReady) -Color Green
        Write-UI ("    Con propietario: " + $tpm.TpmOwned) -Color Green
        Write-UI ("    Version spec   : " + $tpm.ManufacturerVersion) -Color Green
    } catch {
        Write-UI ("    [X] Get-Tpm fallo: " + $_.Exception.Message) -Color Red
        Write-UI "    No hay TPM disponible o no se puede acceder." -Color Red
        return
    }

    Write-Host ""
    Write-UI "  Para continuar, escribi exactamente: RESETEAR TPM" -Color Yellow
    Write-UI "  > " -Color Yellow -NoNewline
    $confirmation = Read-Host
    if ($confirmation -cne 'RESETEAR TPM') {
        Write-UI "  Cancelado (la frase no coincide exactamente)." -Color Green
        return
    }

    Write-UI "  Ejecutando Clear-Tpm..." -Color Cyan
    try {
        Clear-Tpm -ErrorAction Stop
        Write-UI "  [OK] TPM limpiado." -Color Green
        Write-Log -Level WARN -Message "TPM reset ejecutado por $($Global:GF.User)@$($Global:GF.Hostname)"
        if (Test-SoundEnabled) { Play-SuccessChime }

        Write-Host ""
        Write-UI "  IMPORTANTE - proximos pasos:" -Color Yellow
        Write-UI "    1. REINICIA el equipo" -Color Yellow
        Write-UI "    2. Si la BIOS pide confirmar reset del TPM, aceptar" -Color Yellow
        Write-UI "    3. Al volver, reconfigura Windows Hello (PIN/huella/cara)" -Color Yellow
        Write-UI "    4. Si usabas BitLocker: ingresa la clave de recuperacion" -Color Yellow
        Write-Host ""
        Write-UI "  [?] Reiniciar AHORA con countdown de 10s? (s/N): " -Color Yellow -NoNewline
        $r = Read-Host
        if ($r.Trim().ToLower() -eq 's') {
            for ($i = 10; $i -gt 0; $i--) {
                Write-Host -NoNewline ("`r  Reiniciando en $i segundos... (Ctrl+C para cancelar)  ") -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
            Write-Host ""
            Restart-Computer -Force
        } else {
            Write-UI "  Recuerda reiniciar manualmente pronto." -Color Yellow
        }
    } catch {
        Write-UI ("  [X] Error al resetear: " + $_.Exception.Message) -Color Red
        Write-UI "  Causas posibles:" -Color Yellow
        Write-UI "    - TPM con contrasena de propietario (necesita owner auth)" -Color DarkGray
        Write-UI "    - Politica de grupo bloquea Clear-Tpm" -Color DarkGray
        Write-UI "    - Hacerlo desde Windows Security -> Device Security -> Security processor" -Color DarkGray
    }
}

Export-ModuleMember -Function Invoke-Rollback
