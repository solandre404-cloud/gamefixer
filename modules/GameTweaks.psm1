# ============================================================================
#  modules/GameTweaks.psm1
#  Tweaks especificos por juego detectado
# ============================================================================

function Invoke-GameTweaksMenu {
    # Catalogo completo de juegos soportados
    $catalog = @(
        # FPS competitivos
        [pscustomobject]@{ Name='CS2';              Func='Apply-CS2Tweaks';         Category='FPS Competitivos' }
        [pscustomobject]@{ Name='CS:GO';            Func='Apply-CS2Tweaks';         Category='FPS Competitivos' }
        [pscustomobject]@{ Name='VALORANT';         Func='Apply-ValorantTweaks';    Category='FPS Competitivos' }
        [pscustomobject]@{ Name='Rainbow Six Siege';Func='Apply-R6Tweaks';          Category='FPS Competitivos' }
        [pscustomobject]@{ Name='Apex Legends';     Func='Apply-ApexTweaks';        Category='FPS Competitivos' }

        # Battle Royale / FPS modernos
        [pscustomobject]@{ Name='Fortnite';         Func='Apply-FortniteTweaks';    Category='Battle Royale / FPS' }
        [pscustomobject]@{ Name='Warzone / COD';    Func='Apply-WarzoneTweaks';     Category='Battle Royale / FPS' }
        [pscustomobject]@{ Name='Battlefield 2042'; Func='Apply-BattlefieldTweaks'; Category='Battle Royale / FPS' }
        [pscustomobject]@{ Name='Battlefield 6';    Func='Apply-BattlefieldTweaks'; Category='Battle Royale / FPS' }
        [pscustomobject]@{ Name='Delta Force';      Func='Apply-DeltaForceTweaks';  Category='Battle Royale / FPS' }
        [pscustomobject]@{ Name='The Finals';       Func='Apply-TheFinalsTweaks';   Category='Battle Royale / FPS' }
        [pscustomobject]@{ Name='Marvel Rivals';    Func='Apply-MarvelRivalsTweaks';Category='Battle Royale / FPS' }

        # MOBA
        [pscustomobject]@{ Name='League of Legends';Func='Apply-LolTweaks';         Category='MOBA' }
        [pscustomobject]@{ Name='Dota 2';           Func='Apply-Dota2Tweaks';       Category='MOBA' }

        # Supervivencia
        [pscustomobject]@{ Name='Rust';             Func='Apply-RustTweaks';        Category='Supervivencia' }
        [pscustomobject]@{ Name='DayZ';             Func='Apply-DayZTweaks';        Category='Supervivencia' }
        [pscustomobject]@{ Name='ARK';              Func='Apply-ArkTweaks';         Category='Supervivencia' }

        # AAA
        [pscustomobject]@{ Name='GTA V';            Func='Apply-GTAVTweaks';        Category='AAA Single-Player' }
        [pscustomobject]@{ Name='Red Dead 2';       Func='Apply-RDR2Tweaks';        Category='AAA Single-Player' }
        [pscustomobject]@{ Name='Cyberpunk 2077';   Func='Apply-CyberpunkTweaks';   Category='AAA Single-Player' }
        [pscustomobject]@{ Name='Elden Ring';       Func='Apply-EldenRingTweaks';   Category='AAA Single-Player' }

        # Otros
        [pscustomobject]@{ Name='Minecraft';        Func='Apply-MinecraftTweaks';   Category='Otros' }
        [pscustomobject]@{ Name='Escape from Tarkov';Func='Apply-TarkovTweaks';     Category='Otros' }
        [pscustomobject]@{ Name='PUBG';             Func='Apply-PUBGTweaks';        Category='Otros' }
    )

    do {
        Show-Section "AJUSTES POR JUEGO"

        Write-UI "  Aplica ajustes optimizados para cada juego." -Color Cyan
        Write-UI "  No importa si lo tenes instalado o no: los ajustes se aplican igual" -Color Cyan
        Write-UI "  (algunos son del registro de Windows, otros activan al abrir el juego)." -Color Cyan
        Write-Host ""

        # Agrupar y numerar
        $categories = $catalog | Group-Object Category
        $numberedList = @()
        $globalIdx = 1

        foreach ($cat in $categories) {
            Write-UI ("  --- " + $cat.Name + " " + ('-' * [math]::Max(0, 55 - $cat.Name.Length))) -Color Cyan

            $seen = @{}
            foreach ($item in $cat.Group) {
                if ($seen.ContainsKey($item.Func)) { continue }
                $seen[$item.Func] = $true

                Write-UI ("    [{0,2}] {1}" -f $globalIdx, $item.Name) -Color Yellow
                $numberedList += [pscustomobject]@{
                    Number = $globalIdx
                    Item = $item
                }
                $globalIdx++
            }
        }

        Write-Host ""
        Write-UI "  Opciones:" -Color Cyan
        Write-UI "    NUMERO (ej: 3)  -> Aplicar ajustes de ese juego" -Color Yellow
        Write-UI "    [A] Aplicar TODOS los ajustes del catalogo" -Color Yellow
        Write-UI "    [B] Volver al menu principal" -Color Yellow
        Write-Host ""
        Write-UI "  > " -Color Cyan -NoNewline
        $sub = (Read-Host).Trim().ToUpper()

        if ($sub -eq 'B') { return }

        if ($sub -eq 'A') {
            Write-Host ""
            Write-UI ("  [!] Vas a aplicar ajustes para los " + $numberedList.Count + " juegos del catalogo.") -Color Yellow
            Write-UI "  [?] Continuar? (s/N): " -Color Yellow -NoNewline
            $r = Read-Host
            if ($r.Trim().ToLower() -eq 's') {
                foreach ($entry in $numberedList) {
                    Write-Host ""
                    Write-UI ("=== " + $entry.Item.Name + " ===") -Color Cyan
                    $stub = [pscustomobject]@{ Name=$entry.Item.Name; Launcher='Manual'; InstallDir='' }
                    try {
                        & $entry.Item.Func -Game $stub
                    } catch {
                        Write-UI ("  [X] Fallo: " + $_.Exception.Message) -Color Red
                    }
                }
            }
            Pause-Submenu
            continue
        }

        # Numero individual
        $idx = 0
        if ([int]::TryParse($sub, [ref]$idx) -and $idx -ge 1 -and $idx -le $numberedList.Count) {
            $entry = $numberedList[$idx - 1]
            Write-Host ""
            Write-UI ("=== AJUSTES PARA: " + $entry.Item.Name + " ===") -Color Cyan
            Write-Host ""
            $stub = [pscustomobject]@{ Name=$entry.Item.Name; Launcher='Manual'; InstallDir='' }
            try {
                & $entry.Item.Func -Game $stub
            } catch {
                Write-UI ("  [X] Fallo: " + $_.Exception.Message) -Color Red
            }
            Pause-Submenu
        } else {
            Write-UI "  [!] Opcion invalida" -Color Red
            Start-Sleep -Seconds 1
        }
    } while ($true)
}

function Invoke-GameTweaksDetector {
    # Ya no se necesita, pero lo dejamos para retrocompatibilidad
    Write-UI "  Funcion deprecada." -Color DarkGray
}


function Apply-CS2Tweaks {
    param($Game)
    Write-Host ""
    Write-UI "Aplicando tweaks de CS2..." -Color Cyan
    Invoke-LoggedAction -Description "CS2: fps_max 0 via launch options (manual)" -AlwaysRun -Action {
        Write-UI "       Recomendacion: en Steam, CS2 > Propiedades > Opciones de lanzamiento agrega:" -Color Green
        Write-UI "         -high -threads 8 -novid -nojoy +fps_max 0" -Color Yellow
    }
    Invoke-LoggedAction -Description "CS2: prioridad alta en exe si esta abierto" -Action {
        $p = Get-Process -Name 'cs2' -ErrorAction SilentlyContinue
        if ($p) { $p.PriorityClass = 'High' }
    }
}

function Apply-ValorantTweaks {
    param($Game)
    Write-Host ""
    Write-UI "Aplicando tweaks de VALORANT..." -Color Cyan
    Invoke-LoggedAction -Description "Valorant: desactivar fullscreen optimization en exe" -Action {
        $exe = Get-ChildItem -Path $Game.InstallDir -Filter 'VALORANT-Win64-Shipping.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($exe) {
            $key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
            if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
            Set-ItemProperty -Path $key -Name $exe.FullName -Value '~ DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE' -Force
            Write-UI "       FSO desactivado en: $($exe.FullName)" -Color Green
        } else {
            Write-UI "       Exe no encontrado; se omite" -Color Yellow
        }
    }
    Invoke-LoggedAction -Description "Valorant: cerrar Vanguard no elimina problema - tip informativo" -AlwaysRun -Action {
        Write-UI "       Tip: si tienes stuttering, verifica vgc y vgk en [7] Soluciones Comunes." -Color Green
    }
}

function Apply-LolTweaks {
    param($Game)
    Write-Host ""
    Write-UI "Aplicando tweaks de League of Legends..." -Color Cyan
    Invoke-LoggedAction -Description "LoL: limpieza de logs antiguos" -Action {
        $logsDir = Join-Path $Game.InstallDir 'Logs'
        if (Test-Path $logsDir) {
            Get-ChildItem $logsDir -Recurse -Include '*.log','*.txt' -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
}

function Apply-FortniteTweaks {
    param($Game)
    Write-Host ""
    Write-UI "Aplicando tweaks de Fortnite..." -Color Cyan
    Invoke-LoggedAction -Description "Fortnite: limpiar shader cache (DX11/DX12)" -Action {
        $caches = @(
            "$env:LOCALAPPDATA\FortniteGame\Saved\Logs",
            "$env:LOCALAPPDATA\FortniteGame\Saved\Config\WindowsClient",
            "$env:LOCALAPPDATA\FortniteGame\Saved\webcache"
        )
        foreach ($c in $caches) {
            if (Test-Path $c) {
                Get-ChildItem $c -Recurse -Force -ErrorAction SilentlyContinue |
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

function Apply-GTAVTweaks {
    param($Game)
    Write-Host ""
    Write-UI "Aplicando tweaks de GTA V..." -Color Cyan
    Invoke-LoggedAction -Description "GTA V: crear/editar commandline.txt con flags de rendimiento" -Action {
        $cmdFile = Join-Path $Game.InstallDir 'commandline.txt'
        $content = "-noSocialClub -borderless -availablevidmem 4096"
        if (-not $Global:GF.DryRun) {
            Set-Content -Path $cmdFile -Value $content -Encoding ASCII -Force
            Write-UI "       commandline.txt escrito en $cmdFile" -Color Green
        }
    }
}

function Apply-RDR2Tweaks {
    param($Game)
    Write-Host ""
    Write-UI "Aplicando tweaks de Red Dead Redemption 2..." -Color Cyan
    Invoke-LoggedAction -Description "RDR2: limpiar cache de shaders" -Action {
        $cache = "$env:USERPROFILE\Documents\Rockstar Games\Red Dead Redemption 2\Settings\shader_cache"
        if (Test-Path $cache) {
            Get-ChildItem $cache -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Apply-MinecraftTweaks {
    param($Game)
    Write-Host ""
    Write-UI "Aplicando tweaks de Minecraft..." -Color Cyan
    Invoke-LoggedAction -Description "Minecraft: recomendar args JVM optimizados" -AlwaysRun -Action {
        Write-UI "       JVM args recomendados (pega en Launcher > Installations > Edit > JVM args):" -Color Green
        Write-UI "         -Xmx8G -Xms4G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200" -Color Yellow
        Write-UI "         -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch" -Color Yellow
    }
}

function Apply-ApexTweaks {
    param($Game)
    Write-Host ""
    Write-UI "Aplicando tweaks de Apex Legends..." -Color Cyan
    Invoke-LoggedAction -Description "Apex: launch options recomendadas" -AlwaysRun -Action {
        Write-UI "       En Origin/EA App, Apex > Propiedades > Advanced launch options:" -Color Green
        Write-UI "         +fps_max 0 -high -novid" -Color Yellow
    }
}

function Apply-R6Tweaks {
    param($Game)
    Write-Host ""
    Write-UI "Aplicando tweaks de Rainbow Six Siege..." -Color Cyan
    Invoke-LoggedAction -Description "R6: tip de configuracion de Vulkan vs DX11" -AlwaysRun -Action {
        Write-UI "       Tip: Vulkan suele dar mejor frametime que DX11 en R6." -Color Green
        Write-UI "       Cambia el API desde el launcher (Uplay > R6 > Propiedades)." -Color Yellow
    }
}

function Apply-WarzoneTweaks {
    param($Game)
    Write-UI "  -- Warzone / Call of Duty tweaks --" -Color Cyan

    # Deshabilitar overlay del Xbox Game Bar (causa stutter)
    Invoke-LoggedAction -Description "Deshabilitar Xbox Game Bar overlay" -Action {
        $k = 'HKCU:\Software\Microsoft\GameBar'
        if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
        Set-ItemProperty -Path $k -Name 'UseNexusForGameBarEnabled' -Value 0 -Type DWord -Force
    }

    # Desactivar Fullscreen Optimization para cod.exe (reduce input lag)
    Invoke-LoggedAction -Description "Desactivar Fullscreen Optimization para cod.exe" -Action {
        $exePaths = @(
            (Join-Path $Game.InstallDir 'cod.exe'),
            (Join-Path $Game.InstallDir '_retail_\cod.exe'),
            (Join-Path $Game.InstallDir 'ModernWarfare.exe')
        )
        foreach ($exe in $exePaths) {
            if (Test-Path $exe) {
                $k = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
                if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
                Set-ItemProperty -Path $k -Name $exe -Value '~ DISABLEDXMAXIMIZEDWINDOWEDMODE HIGHDPIAWARE' -Type String -Force
            }
        }
    }

    # Configurar HAGS (Hardware-Accelerated GPU Scheduling) ON - mejora frame pacing en Warzone
    Invoke-LoggedAction -Description "Activar HAGS (Hardware GPU Scheduling)" -Action {
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' `
            -Name 'HwSchMode' -Value 2 -Type DWord -Force
    }

    Write-UI "  Tip manual:" -Color Yellow
    Write-UI "    - Activa 'On-demand Texture Streaming' OFF si tenes VRAM >=8GB" -Color DarkGray
    Write-UI "    - Pone 'Shader Preload' en FULL al primer arranque" -Color DarkGray
    Write-UI "    - Desactiva DLSS Frame Generation si tenes ping alto" -Color DarkGray
}

function Apply-BattlefieldTweaks {
    param($Game)
    Write-UI "  -- Battlefield (2042/6) tweaks --" -Color Cyan

    # DirectX 12 agent: BF2042 funciona mejor con DX12 en GPUs modernas
    Invoke-LoggedAction -Description "Recordatorio: forzar DX12 en settings del juego" -AlwaysRun -Action {
        Write-UI "         Verifica en el juego: Video > DirectX 12 = ON" -Color Yellow
    }

    # Aumentar prioridad del proceso en Task Manager
    Invoke-LoggedAction -Description "Configurar CPU affinity para bf2042.exe" -Action {
        # Crear entrada en IFEO para prioridad High al lanzarse
        $exeName = 'bf2042.exe'
        $k = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exeName\PerfOptions"
        if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
        Set-ItemProperty -Path $k -Name 'CpuPriorityClass' -Value 3 -Type DWord -Force  # High
    }

    # Desactivar fullscreen optimizations
    Invoke-LoggedAction -Description "Desactivar FSO en executables de BF" -Action {
        $exes = @('bf2042.exe','bf6.exe','bfv.exe')
        foreach ($exe in $exes) {
            $fullPath = Join-Path $Game.InstallDir $exe
            if (Test-Path $fullPath) {
                $k = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
                if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
                Set-ItemProperty -Path $k -Name $fullPath -Value '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' -Type String -Force
            }
        }
    }

    Write-UI "  Tip manual para BF2042/BF6:" -Color Yellow
    Write-UI "    - DLSS Quality + Frame Generation en GPUs RTX 40xx" -Color DarkGray
    Write-UI "    - Future Frame Rendering (FFR) = ON" -Color DarkGray
    Write-UI "    - Terrain Quality = Medium es el sweet spot" -Color DarkGray
}

function Apply-RustTweaks {
    param($Game)
    Write-UI "  -- Rust tweaks --" -Color Cyan

    # Rust sufre de stutter por garbage collection de Unity; asignar mas memoria al heap
    Invoke-LoggedAction -Description "Configurar launch options de Rust via registro Steam" -AlwaysRun -Action {
        Write-UI "         Launch options recomendadas (copiar en Steam > Rust > Propiedades):" -Color Yellow
        Write-UI "         -high -maxMem=16384 -malloc=system -cpuCount=8 -exThreads=8 -force-feature-level-11-0 -nolog" -Color Green
    }

    # Desactivar Windows Defender scan en carpeta de Rust (causa hitches)
    Invoke-LoggedAction -Description "Excluir carpeta de Rust de Windows Defender" -Action {
        if (Get-Command Add-MpPreference -ErrorAction SilentlyContinue) {
            Add-MpPreference -ExclusionPath $Game.InstallDir -ErrorAction SilentlyContinue
        }
    }

    # Limpiar shader cache antes de jugar (Rust re-compila los suyos)
    Invoke-LoggedAction -Description "Limpiar shader cache de DirectX" -Action {
        $paths = @("$env:LOCALAPPDATA\D3DSCache","$env:LOCALAPPDATA\NVIDIA\DXCache")
        foreach ($p in $paths) {
            if (Test-Path $p) {
                Get-ChildItem $p -Recurse -Force -ErrorAction SilentlyContinue |
                    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            }
        }
    }

    Write-UI "  Tip manual para Rust:" -Color Yellow
    Write-UI "    - grass.displacement = false ( ~15 FPS de ganancia)" -Color DarkGray
    Write-UI "    - shadow.quality = 0 o 1" -Color DarkGray
}

function Apply-DeltaForceTweaks {
    param($Game)
    Write-UI "  -- Delta Force tweaks --" -Color Cyan

    Invoke-LoggedAction -Description "Desactivar Nagle's algorithm para reducir latencia" -Action {
        $adapters = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue
        foreach ($a in $adapters) {
            Set-ItemProperty -Path $a.PSPath -Name 'TcpAckFrequency' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $a.PSPath -Name 'TCPNoDelay' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }
    }

    Invoke-LoggedAction -Description "Desactivar Fullscreen Optimization para Delta Force" -Action {
        $exes = @('DeltaForceClient.exe','df-game.exe','DFClient-Win64-Shipping.exe')
        foreach ($exe in $exes) {
            $fullPath = Join-Path $Game.InstallDir $exe
            if (Test-Path $fullPath) {
                $k = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
                if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
                Set-ItemProperty -Path $k -Name $fullPath -Value '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' -Type String -Force
            }
        }
    }

    Write-UI "  Tip manual para Delta Force:" -Color Yellow
    Write-UI "    - Activa DLSS/FSR Quality si usas AA" -Color DarkGray
    Write-UI "    - Ray Tracing OFF en competitivo" -Color DarkGray
}

function Apply-TheFinalsTweaks {
    param($Game)
    Write-UI "  -- The Finals tweaks --" -Color Cyan

    Invoke-LoggedAction -Description "Recordatorio: The Finals usa UE5 + Nanite, tweaks clave" -AlwaysRun -Action {
        Write-UI "         En Engine.ini del usuario:" -Color Yellow
        Write-UI "         [/Script/Engine.RendererSettings]" -Color DarkGray
        Write-UI "         r.Streaming.PoolSize=4096" -Color DarkGray
        Write-UI "         r.Streaming.HLODStrategy=2" -Color DarkGray
    }

    # Desactivar FSO
    Invoke-LoggedAction -Description "Desactivar FSO para Discovery.exe" -Action {
        $exe = Join-Path $Game.InstallDir 'Discovery\Binaries\Win64\Discovery.exe'
        if (Test-Path $exe) {
            $k = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
            if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
            Set-ItemProperty -Path $k -Name $exe -Value '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' -Type String -Force
        }
    }
}

function Apply-MarvelRivalsTweaks {
    param($Game)
    Write-UI "  -- Marvel Rivals tweaks --" -Color Cyan

    Invoke-LoggedAction -Description "Desactivar FSO para MarvelRivals-Win64-Shipping.exe" -Action {
        $exe = Join-Path $Game.InstallDir 'MarvelGame\Binaries\Win64\MarvelRivals-Win64-Shipping.exe'
        if (Test-Path $exe) {
            $k = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
            if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
            Set-ItemProperty -Path $k -Name $exe -Value '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' -Type String -Force
        }
    }

    Write-UI "  Tip manual para Marvel Rivals (UE5):" -Color Yellow
    Write-UI "    - Super Resolution: DLSS/FSR en Quality" -Color DarkGray
    Write-UI "    - Global Illumination: Low para mas FPS" -Color DarkGray
    Write-UI "    - Desactiva Lumen Hardware Ray Tracing" -Color DarkGray
}

function Apply-Dota2Tweaks {
    param($Game)
    Write-UI "  -- Dota 2 tweaks --" -Color Cyan

    Invoke-LoggedAction -Description "Sugerencia: usar Vulkan en lugar de DX11 (mas FPS)" -AlwaysRun -Action {
        Write-UI "         Launch option recomendada: -vulkan -high" -Color Yellow
    }

    Invoke-LoggedAction -Description "Desactivar FSO para dota2.exe" -Action {
        $exe = Join-Path $Game.InstallDir 'game\bin\win64\dota2.exe'
        if (Test-Path $exe) {
            $k = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
            if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
            Set-ItemProperty -Path $k -Name $exe -Value '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' -Type String -Force
        }
    }
}

function Apply-DayZTweaks {
    param($Game)
    Write-UI "  -- DayZ tweaks --" -Color Cyan

    Invoke-LoggedAction -Description "Launch options recomendadas para DayZ" -AlwaysRun -Action {
        Write-UI "         -winxp -noBenchmark -world=empty -maxMem=16384 -cpuCount=8 -exThreads=8" -Color Yellow
    }

    # Excluir de defender
    if (Get-Command Add-MpPreference -ErrorAction SilentlyContinue) {
        Add-MpPreference -ExclusionPath $Game.InstallDir -ErrorAction SilentlyContinue
    }
}

function Apply-ArkTweaks {
    param($Game)
    Write-UI "  -- ARK tweaks --" -Color Cyan

    Invoke-LoggedAction -Description "Launch options para ARK Survival Ascended" -AlwaysRun -Action {
        Write-UI "         -UseAllAvailableCores -USEALLAVAILABLECORES -sm4 -d3d10 -nomansky" -Color Yellow
    }

    # ARK es pesado, activar HAGS
    Invoke-LoggedAction -Description "Activar Hardware-Accelerated GPU Scheduling" -Action {
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' `
            -Name 'HwSchMode' -Value 2 -Type DWord -Force
    }
}

function Apply-CyberpunkTweaks {
    param($Game)
    Write-UI "  -- Cyberpunk 2077 tweaks --" -Color Cyan

    Invoke-LoggedAction -Description "Sugerencias config Cyberpunk 2.x (Phantom Liberty)" -AlwaysRun -Action {
        Write-UI "         - Path Tracing + DLSS Frame Gen en RTX 40xx: ON" -Color Yellow
        Write-UI "         - Ray Reconstruction: ON (reduce ruido)" -Color Yellow
        Write-UI "         - Crowd Density: Medium (CPU bound)" -Color Yellow
    }

    # Activar HAGS
    Invoke-LoggedAction -Description "Activar HAGS" -Action {
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' `
            -Name 'HwSchMode' -Value 2 -Type DWord -Force
    }

    # FSO off para Cyberpunk2077.exe
    $exe = Join-Path $Game.InstallDir 'bin\x64\Cyberpunk2077.exe'
    if (Test-Path $exe) {
        Invoke-LoggedAction -Description "Desactivar FSO Cyberpunk2077.exe" -Action {
            $k = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
            if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
            Set-ItemProperty -Path $k -Name $exe -Value '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' -Type String -Force
        }
    }
}

function Apply-EldenRingTweaks {
    param($Game)
    Write-UI "  -- Elden Ring tweaks --" -Color Cyan

    # Elden Ring está capped a 60 FPS, pero se puede aplicar seamless coop mod
    Invoke-LoggedAction -Description "Info - Elden Ring FPS cap" -AlwaysRun -Action {
        Write-UI "         Elden Ring esta bloqueado a 60 FPS por diseno." -Color Yellow
        Write-UI "         Para >60 FPS necesitas mod 'FPS Unlocker' (solo offline)" -Color DarkGray
    }

    # FSO off
    $exe = Join-Path $Game.InstallDir 'Game\eldenring.exe'
    if (Test-Path $exe) {
        Invoke-LoggedAction -Description "Desactivar FSO eldenring.exe" -Action {
            $k = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
            if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
            Set-ItemProperty -Path $k -Name $exe -Value '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' -Type String -Force
        }
    }
}

function Apply-TarkovTweaks {
    param($Game)
    Write-UI "  -- Escape from Tarkov tweaks --" -Color Cyan

    Invoke-LoggedAction -Description "Excluir Tarkov de Windows Defender" -Action {
        if (Get-Command Add-MpPreference -ErrorAction SilentlyContinue) {
            Add-MpPreference -ExclusionPath $Game.InstallDir -ErrorAction SilentlyContinue
        }
    }

    Invoke-LoggedAction -Description "Desactivar FSO para EscapeFromTarkov.exe" -Action {
        $exe = Join-Path $Game.InstallDir 'EscapeFromTarkov.exe'
        if (Test-Path $exe) {
            $k = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
            if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
            Set-ItemProperty -Path $k -Name $exe -Value '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' -Type String -Force
        }
    }

    Write-UI "  Tip manual para Tarkov:" -Color Yellow
    Write-UI "    - Texture Quality: Medium (el juego sufre de VRAM leaks)" -Color DarkGray
    Write-UI "    - Shadow Quality: Low, Object LOD: 2.5" -Color DarkGray
    Write-UI "    - DLSS/FSR: OFF en competitivo (introduce artefactos)" -Color DarkGray
}

function Apply-PUBGTweaks {
    param($Game)
    Write-UI "  -- PUBG tweaks --" -Color Cyan

    Invoke-LoggedAction -Description "Launch options para PUBG" -AlwaysRun -Action {
        Write-UI "         -USEALLAVAILABLECORES -malloc=system -sm4 -d3d11" -Color Yellow
    }

    # FSO off
    $exe = Join-Path $Game.InstallDir 'TslGame\Binaries\Win64\TslGame.exe'
    if (Test-Path $exe) {
        Invoke-LoggedAction -Description "Desactivar FSO TslGame.exe" -Action {
            $k = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
            if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
            Set-ItemProperty -Path $k -Name $exe -Value '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' -Type String -Force
        }
    }
}

Export-ModuleMember -Function Invoke-GameTweaksMenu
