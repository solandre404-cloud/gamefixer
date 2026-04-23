# ============================================================================
#  modules/Effects.psm1
#  Efectos visuales: matrix rain, typewriter, scanning, glitch, progress, sonidos
# ============================================================================

function Test-SoundEnabled {
    # Respeta la preferencia del usuario en config.json
    if ($Global:GF -and $Global:GF.Config) {
        return [bool]$Global:GF.Config.soundEnabled
    }
    return $false
}

function Play-Sound {
    <#
    .SYNOPSIS
    Reproduce un beep de tono y duracion configurables. No hace nada si sonido esta OFF.
    #>
    param(
        [int]$Frequency = 800,
        [int]$DurationMs = 150
    )
    if (-not (Test-SoundEnabled)) { return }
    try {
        [Console]::Beep($Frequency, $DurationMs)
    } catch {}
}

function Play-SuccessChime {
    # Acorde ascendente tipo "completado"
    if (-not (Test-SoundEnabled)) { return }
    try {
        [Console]::Beep(523, 100)  # Do
        [Console]::Beep(659, 100)  # Mi
        [Console]::Beep(784, 150)  # Sol
    } catch {}
}

function Play-ErrorSound {
    # Tono descendente tipo "error"
    if (-not (Test-SoundEnabled)) { return }
    try {
        [Console]::Beep(400, 150)
        [Console]::Beep(200, 250)
    } catch {}
}

function Play-BootSound {
    # Secuencia tipo arranque
    if (-not (Test-SoundEnabled)) { return }
    try {
        [Console]::Beep(440, 80)
        Start-Sleep -Milliseconds 50
        [Console]::Beep(660, 80)
        Start-Sleep -Milliseconds 50
        [Console]::Beep(880, 150)
    } catch {}
}

function Play-KeyClick {
    # Click corto para feedback de tecla
    if (-not (Test-SoundEnabled)) { return }
    try {
        [Console]::Beep(1200, 15)
    } catch {}
}

function Show-MatrixRain {
    <#
    .SYNOPSIS
    Efecto Matrix rain por N segundos antes de mostrar el banner.
    #>
    param(
        [int]$DurationMs = 1500,
        [int]$Density = 35,
        [ConsoleColor]$Color = 'Green'
    )

    [Console]::CursorVisible = $false
    try {
        $width = [Console]::WindowWidth
        $height = [Console]::WindowHeight - 1
        if ($width -lt 10 -or $height -lt 10) { return }

        Clear-Host
        $rng = New-Object Random
        $end = (Get-Date).AddMilliseconds($DurationMs)

        # Array de columnas con drops
        $drops = @()
        for ($i = 0; $i -lt $Density; $i++) {
            $drops += @{
                Col   = $rng.Next(0, $width)
                Row   = $rng.Next(-10, 0)
                Speed = $rng.Next(1, 3)
                Len   = $rng.Next(5, 15)
            }
        }

        $prev = [Console]::ForegroundColor
        while ((Get-Date) -lt $end) {
            foreach ($d in $drops) {
                # Borrar el caracter mas viejo de la estela
                $oldRow = $d.Row - $d.Len
                if ($oldRow -ge 0 -and $oldRow -lt $height) {
                    [Console]::SetCursorPosition($d.Col, $oldRow)
                    [Console]::Write(' ')
                }

                # Dibujar caracter nuevo
                if ($d.Row -ge 0 -and $d.Row -lt $height) {
                    [Console]::SetCursorPosition($d.Col, $d.Row)
                    [Console]::ForegroundColor = 'White'  # cabeza brillante
                    $char = [char]$rng.Next(33, 126)
                    [Console]::Write($char)

                    # Estela verde atras
                    for ($t = 1; $t -lt $d.Len; $t++) {
                        $r = $d.Row - $t
                        if ($r -ge 0 -and $r -lt $height) {
                            [Console]::SetCursorPosition($d.Col, $r)
                            [Console]::ForegroundColor = if ($t -lt 3) { 'Green' } else { 'DarkGreen' }
                            $trailChar = [char]$rng.Next(33, 126)
                            [Console]::Write($trailChar)
                        }
                    }
                }

                $d.Row += $d.Speed

                if ($d.Row - $d.Len -gt $height) {
                    $d.Row = $rng.Next(-10, 0)
                    $d.Col = $rng.Next(0, $width)
                }
            }
            Start-Sleep -Milliseconds 50
        }
        [Console]::ForegroundColor = $prev
    } finally {
        [Console]::CursorVisible = $true
    }

    Clear-Host
}

function Show-EpicBoot {
    <#
    .SYNOPSIS
    Secuencia de boot epica: matrix rain + typewriter + boot messages realistas.
    #>
    param([switch]$FastMode)

    $delay = if ($FastMode) { 0 } else { 1 }

    # Fase 1: Matrix rain
    if (-not $FastMode) {
        Show-MatrixRain -DurationMs 1200
    }

    Clear-Host
    Write-Host ""

    # Fase 2: Boot messages tipo BIOS/hackeo
    $messages = @(
        @{ Delay=30; Text='[BOOT] GAMEFIXER firmware initialized...'; Color='Green' }
        @{ Delay=40; Text='[BOOT] Memory test......................... OK'; Color='Green' }
        @{ Delay=35; Text='[BOOT] CPU topology detected: ' + [Environment]::ProcessorCount + ' logical cores'; Color='Green' }
        @{ Delay=40; Text='[BOOT] Scanning storage devices......... OK'; Color='Green' }
        @{ Delay=45; Text='[BOOT] GPU probe: attempting nvidia-smi...'; Color='Green' }
        @{ Delay=30; Text='[BOOT] Network link established'; Color='Green' }
        @{ Delay=35; Text='[BOOT] Loading modular subsystems...'; Color='Green' }
        @{ Delay=25; Text='       -> UI.........................OK'; Color='DarkGreen' }
        @{ Delay=25; Text='       -> Logger.....................OK'; Color='DarkGreen' }
        @{ Delay=25; Text='       -> Telemetry..................OK'; Color='DarkGreen' }
        @{ Delay=25; Text='       -> Updater....................OK'; Color='DarkGreen' }
        @{ Delay=25; Text='       -> Benchmark..................OK'; Color='DarkGreen' }
        @{ Delay=25; Text='       -> AutoFix....................OK'; Color='DarkGreen' }
        @{ Delay=25; Text='       -> Plugins....................OK'; Color='DarkGreen' }
        @{ Delay=30; Text='[BOOT] Verifying administrator privileges'; Color='Green' }
        @{ Delay=20; Text='[BOOT] Access granted.'; Color='Green' }
        @{ Delay=40; Text='[BOOT] Establishing secure session...'; Color='Yellow' }
        @{ Delay=30; Text='[BOOT] Welcome, ' + $env:USERNAME + '@' + $env:COMPUTERNAME; Color='Cyan' }
        @{ Delay=50; Text='[BOOT] System ready. Initializing GUI...'; Color='Green' }
    )

    foreach ($m in $messages) {
        Write-UI ("  " + $m.Text) -Color $m.Color
        if (-not $FastMode) { Start-Sleep -Milliseconds $m.Delay }
    }

    if (-not $FastMode) { Start-Sleep -Milliseconds 300 }
}

function Show-ScanLine {
    <#
    .SYNOPSIS
    Animacion de linea de scanner pasando por una serie de elementos.
    #>
    param(
        [string[]]$Items,
        [string]$Action = 'Scanning'
    )
    foreach ($item in $Items) {
        $prefix = "  [{0}] " -f $Action
        Write-Host -NoNewline $prefix -ForegroundColor Cyan
        # Typewriter del nombre del item
        foreach ($ch in $item.ToCharArray()) {
            Write-Host -NoNewline $ch -ForegroundColor Green
            Start-Sleep -Milliseconds 5
        }
        # Puntos animados
        for ($i = 0; $i -lt 3; $i++) {
            Write-Host -NoNewline '.' -ForegroundColor DarkGreen
            Start-Sleep -Milliseconds 80
        }
        Write-Host " OK" -ForegroundColor Green
    }
}

function Show-GlitchText {
    <#
    .SYNOPSIS
    Glitch un texto por N frames.
    #>
    param([string]$Text, [int]$Frames = 10, [ConsoleColor]$Color = 'Green')

    $rng = New-Object Random
    $originalRow = [Console]::CursorTop
    [Console]::CursorVisible = $false

    try {
        $glitchChars = '!@#$%^&*()_+-=[]{}|;:<>?/'.ToCharArray()
        for ($f = 0; $f -lt $Frames; $f++) {
            [Console]::SetCursorPosition(0, $originalRow)
            $sb = New-Object System.Text.StringBuilder
            foreach ($ch in $Text.ToCharArray()) {
                if ($rng.NextDouble() -lt 0.15) {
                    [void]$sb.Append($glitchChars[$rng.Next(0, $glitchChars.Length)])
                } else {
                    [void]$sb.Append($ch)
                }
            }
            Write-UI $sb.ToString() -Color $Color
            Start-Sleep -Milliseconds 40
        }
        [Console]::SetCursorPosition(0, $originalRow)
        Write-UI $Text -Color $Color
    } finally {
        [Console]::CursorVisible = $true
    }
}

function Show-SpinnerAsync {
    <#
    .SYNOPSIS
    Devuelve un scriptblock que ejecuta un spinner hasta que se lo cancele.
    #>
    param([string]$Message = 'Trabajando')
    $spinner = @('|','/','-','\')
    $i = 0
    while ($true) {
        $ch = $spinner[$i % $spinner.Count]
        Write-Host -NoNewline ("`r  [{0}] {1}" -f $ch, $Message) -ForegroundColor Cyan
        Start-Sleep -Milliseconds 80
        $i++
    }
}

function Show-ProgressBar {
    <#
    .SYNOPSIS
    Barra de progreso animada en una linea.
    #>
    param(
        [int]$Current,
        [int]$Total,
        [string]$Label = '',
        [int]$Width = 30
    )
    $pct = if ($Total -gt 0) { [int](($Current / $Total) * 100) } else { 0 }
    $filled = [int](($pct / 100) * $Width)
    $empty = $Width - $filled

    $color = if ($pct -ge 80) { 'Green' } elseif ($pct -ge 40) { 'Yellow' } else { 'Cyan' }

    Write-Host -NoNewline "`r  $Label [" -ForegroundColor Cyan
    Write-Host -NoNewline ($Global:GF.BlockFull.ToString() * $filled) -ForegroundColor $color
    Write-Host -NoNewline ($Global:GF.BlockLight.ToString() * $empty) -ForegroundColor DarkGreen
    Write-Host -NoNewline ("] {0,3}%  ({1}/{2})" -f $pct, $Current, $Total) -ForegroundColor $color

    if ($Current -ge $Total) {
        Write-Host ""
    }
}

function Show-AsciiGPUCard {
    <#
    .SYNOPSIS
    ASCII art de una GPU con sus specs.
    #>
    param($GPUName, $VRAM, $Temp)

    $lines = @(
        '       ___________________________________'
        '      /                                   \'
        '     /   [=====]  [=====]  [=====]  [=]    \'
        '    |                                       |'
        "    |    $($GPUName.PadRight(35,' ').Substring(0,35))|"
        "    |    VRAM: $($VRAM.ToString().PadRight(8)) Temp: $($Temp)°C              |"
        '    |                                       |'
        '     \   [fan]  [fan]  [fan]  [fan]        /'
        '      \_____________________________________/'
        '             |  |  |  |  |  |  |  |'
        '             ================'
    )
    foreach ($l in $lines) {
        Write-UI $l -Color Green
    }
}

Export-ModuleMember -Function Show-MatrixRain, Show-EpicBoot, Show-ScanLine, `
    Show-GlitchText, Show-ProgressBar, Show-AsciiGPUCard, `
    Play-Sound, Play-SuccessChime, Play-ErrorSound, Play-BootSound, Play-KeyClick, `
    Test-SoundEnabled
