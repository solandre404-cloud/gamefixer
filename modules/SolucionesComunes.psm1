# ============================================================================
#  modules/SolucionesComunes.psm1
#  Soluciones comunes para problemas tipicos de gaming
# ============================================================================

function Invoke-SolucionesComunes {
    do {
        Clear-Host
        Show-Section "SOLUCIONES COMUNES DE GAMING"

        Write-UI "  [1] Stuttering / FPS drops (limpiar DirectX cache + shader)" -Color Yellow
        Write-UI "  [2] Desync de audio (reiniciar servicios de audio)" -Color Yellow
        Write-UI "  [3] Juego no abre / crash al iniciar (reparar VC++ runtimes)" -Color Yellow
        Write-UI "  [4] Input lag (reconfigurar HID + USB selective suspend)" -Color Yellow
        Write-UI "  [5] Xbox Game Bar no funciona" -Color Yellow
        Write-UI "  [6] Problemas con anti-cheat (EAC/BattlEye check)" -Color Yellow
        Write-UI "  [7] Mouse acceleration OFF (precision del raton)" -Color Yellow
        Write-UI "  [8] Hardware Accelerated GPU Scheduling (HAGS) ON" -Color Yellow
        Write-UI "  [B] Volver al menu principal" -Color Yellow
        Write-Host ""
        Write-UI "  > " -Color Cyan -NoNewline
        $sub = (Read-Host).Trim().ToUpper()

        switch ($sub) {
            '1' { Fix-Stuttering;     Pause-Submenu }
            '2' { Fix-Audio;          Pause-Submenu }
            '3' { Fix-VCRuntimes;     Pause-Submenu }
            '4' { Fix-InputLag;       Pause-Submenu }
            '5' { Fix-XboxGameBar;    Pause-Submenu }
            '6' { Test-AntiCheat;     Pause-Submenu }
            '7' { Disable-MouseAccel; Pause-Submenu }
            '8' { Enable-HAGS;        Pause-Submenu }
            'B' { return }
            default { }
        }
    } while ($true)
}

function Fix-Stuttering {
    Write-Host ""
    Write-UI "Fix de stuttering / FPS drops:" -Color Cyan
    Clear-ShaderCache
    Invoke-LoggedAction -Description "Desactivar Fullscreen Optimizations globalmente" -Action {
        $key = 'HKCU:\System\GameConfigStore'
        if (Test-Path $key) {
            Set-ItemProperty -Path $key -Name 'GameDVR_FSEBehaviorMode'         -Value 2 -Type DWord -Force
            Set-ItemProperty -Path $key -Name 'GameDVR_HonorUserFSEBehaviorMode' -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $key -Name 'GameDVR_DXGIHonorFSEWindowsCompatible' -Value 1 -Type DWord -Force
        }
    }
}

function Fix-Audio {
    Write-Host ""
    Write-UI "Reiniciando servicios de audio:" -Color Cyan
    $services = @('Audiosrv','AudioEndpointBuilder')
    foreach ($s in $services) {
        Invoke-LoggedAction -Description "Reiniciar servicio $s" -Action {
            Restart-Service -Name $s -Force -ErrorAction SilentlyContinue
        }
    }
    Write-UI "  Audio reiniciado. Si persiste, reinstala driver de audio." -Color Green
}

function Fix-VCRuntimes {
    Write-Host ""
    Write-UI "=== REPARACION DE VISUAL C++ RUNTIMES ===" -Color Cyan
    Write-Host ""

    # Listar instalados actualmente
    Write-UI "Runtimes Visual C++ instalados actualmente:" -Color Cyan
    $installed = @()
    try {
        # Metodo rapido: registro (Win32_Product es lentisimo)
        $keys = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        )
        foreach ($k in $keys) {
            Get-ChildItem $k -ErrorAction SilentlyContinue | ForEach-Object {
                $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
                if ($p.DisplayName -and $p.DisplayName -match 'Visual C\+\+') {
                    $installed += [pscustomobject]@{
                        Name = $p.DisplayName
                        Version = $p.DisplayVersion
                    }
                }
            }
        }
    } catch {}

    if ($installed.Count -eq 0) {
        Write-UI "  [!] No se encontraron runtimes VC++ instalados!" -Color Yellow
    } else {
        foreach ($p in $installed) {
            Write-UI ("    " + $p.Name + "  [" + $p.Version + "]") -Color Green
        }
    }

    Write-Host ""
    Write-UI "Opciones:" -Color Cyan
    Write-UI "  [1] Descargar e instalar VC++ Redistributable 2015-2022 x64 (recomendado)" -Color Yellow
    Write-UI "  [2] Descargar e instalar VC++ Redistributable 2015-2022 x86" -Color Yellow
    Write-UI "  [3] Instalar AMBOS (x64 + x86)" -Color Yellow
    Write-UI "  [4] Solo mostrar URLs de descarga" -Color Yellow
    Write-UI "  [B] Volver" -Color Yellow
    Write-Host ""
    Write-UI "  > " -Color Cyan -NoNewline
    $sub = (Read-Host).Trim().ToUpper()

    switch ($sub) {
        '1' { Install-VCRedist -Arch 'x64' }
        '2' { Install-VCRedist -Arch 'x86' }
        '3' { Install-VCRedist -Arch 'x64'; Install-VCRedist -Arch 'x86' }
        '4' {
            Write-UI "  x64: https://aka.ms/vs/17/release/vc_redist.x64.exe" -Color Green
            Write-UI "  x86: https://aka.ms/vs/17/release/vc_redist.x86.exe" -Color Green
        }
        default { return }
    }
}

function Install-VCRedist {
    param([string]$Arch = 'x64')

    $url = "https://aka.ms/vs/17/release/vc_redist.$Arch.exe"
    $installer = Join-Path $env:TEMP ("vc_redist.$Arch.exe")

    Write-Host ""
    Write-UI ("Descargando VC++ Redistributable $Arch...") -Color Cyan
    Write-UI ("  URL: $url") -Color DarkGray

    if ($Global:GF.DryRun) {
        Write-UI "  [PRUEBA] No se descargara ni instalara. Activa LIVE para ejecutar." -Color DarkYellow
        return
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing -TimeoutSec 120 `
            -UserAgent 'Mozilla/5.0 GameFixer/2.06' -ErrorAction Stop
        $sizeMB = [math]::Round((Get-Item $installer).Length / 1MB, 1)
        Write-UI ("  Descargado: $sizeMB MB") -Color Green
    } catch {
        Write-UI ("  [X] Error descargando: " + $_.Exception.Message) -Color Red
        return
    }

    Write-UI "Instalando..." -Color Cyan
    Write-UI "  (puede aparecer una ventana de UAC; aceptar)" -Color DarkGray
    try {
        # /install /quiet /norestart = silencioso, sin reiniciar
        $process = Start-Process -FilePath $installer -ArgumentList '/install','/quiet','/norestart' -Wait -PassThru
        $exitCode = $process.ExitCode

        # Codigos de salida VC++ Redist:
        #   0    = success
        #   1638 = newer version already installed
        #   3010 = success, requires reboot
        switch ($exitCode) {
            0    { Write-UI "  [OK] Instalado correctamente" -Color Green }
            1638 { Write-UI "  [OK] Ya tenias una version igual o mas nueva" -Color Green }
            3010 { Write-UI "  [OK] Instalado. REINICIA Windows para completar" -Color Yellow }
            default { Write-UI "  [!] Codigo de salida: $exitCode (consulta docs MS)" -Color Yellow }
        }
        if (Test-SoundEnabled) { Play-SuccessChime }
    } catch {
        Write-UI ("  [X] Error instalando: " + $_.Exception.Message) -Color Red
    } finally {
        Remove-Item $installer -Force -ErrorAction SilentlyContinue
    }
}

function Fix-InputLag {
    Write-Host ""
    Write-UI "Ajustando configuracion de dispositivos USB:" -Color Cyan
    Invoke-LoggedAction -Description "Desactivar USB Selective Suspend (plan actual)" -Action {
        powercfg /setacvalueindex SCHEME_CURRENT SUB_USB USBSELECTIVESUSPEND 0
        powercfg /setdcvalueindex SCHEME_CURRENT SUB_USB USBSELECTIVESUSPEND 0
        powercfg /setactive SCHEME_CURRENT
    }
}

function Fix-XboxGameBar {
    Write-Host ""
    Write-UI "Reparando Xbox Game Bar:" -Color Cyan
    Invoke-LoggedAction -Description "Re-registrar Xbox Game Bar" -Action {
        Get-AppxPackage Microsoft.XboxGamingOverlay -AllUsers |
            ForEach-Object { Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue }
    }
}

function Test-AntiCheat {
    Write-Host ""
    Write-UI "Verificando anti-cheat:" -Color Cyan
    Invoke-LoggedAction -Description "Estado de servicios anti-cheat" -AlwaysRun -Action {
        $ac = @('EasyAntiCheat','BEService','FACEIT','vgc','vgk')
        foreach ($s in $ac) {
            $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
            if ($svc) {
                Write-UI ("       $s : $($svc.Status) ($($svc.StartType))") -Color Green
            }
        }
    }
    Invoke-LoggedAction -Description "Secure Boot status" -AlwaysRun -Action {
        try {
            $sb = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
            Write-UI ("       Secure Boot: $sb") -Color Green
        } catch {
            Write-UI "       Secure Boot: no se pudo verificar" -Color DarkGray
        }
    }
}

function Disable-MouseAccel {
    Write-Host ""
    Write-UI "Desactivando aceleracion del raton:" -Color Cyan
    Invoke-LoggedAction -Description "MouseSpeed=0, MouseThreshold1=0, MouseThreshold2=0" -Action {
        $key = 'HKCU:\Control Panel\Mouse'
        Set-ItemProperty -Path $key -Name 'MouseSpeed'      -Value '0' -Type String -Force
        Set-ItemProperty -Path $key -Name 'MouseThreshold1' -Value '0' -Type String -Force
        Set-ItemProperty -Path $key -Name 'MouseThreshold2' -Value '0' -Type String -Force
    }
    Write-UI "  Nota: los cambios aplican al re-iniciar sesion." -Color DarkYellow
}

function Enable-HAGS {
    Write-Host ""
    Write-UI "Activando Hardware Accelerated GPU Scheduling (requiere reinicio):" -Color Cyan
    Invoke-LoggedAction -Description "HwSchMode=2 (HAGS on)" -Action {
        $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
        Set-ItemProperty -Path $key -Name 'HwSchMode' -Value 2 -Type DWord -Force
    }
    Write-UI "  Reinicia para aplicar. Desactiva con HwSchMode=1 si causa problemas." -Color DarkYellow
}

Export-ModuleMember -Function Invoke-SolucionesComunes
