#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    function global:Write-Log { param($Level, $Message) }
    function global:Write-UI  { param($Text, $Color, [switch]$NoNewline) }
    function global:Get-TelemetryStats { return [pscustomobject]@{ CPU=50; GPU=30; RAM=40; Disks=@() } }

    $Global:GF = @{
        BlockFull  = [char]0x2588
        BlockLight = [char]0x2591
    }

    $modulePath = Join-Path $PSScriptRoot '..\modules\Dashboard.psm1'
    Import-Module $modulePath -Force -Global
}

Describe 'ConvertTo-Sparkline' {

    It 'devuelve string de la misma longitud que el array' {
        $result = ConvertTo-Sparkline -Values @(10, 20, 30, 40, 50)
        $result.Length | Should -Be 5
    }

    It 'usa caracteres del set de sparkline (U+2581 a U+2588)' {
        $result = ConvertTo-Sparkline -Values @(0, 25, 50, 75, 100)
        foreach ($ch in $result.ToCharArray()) {
            $code = [int]$ch
            # Aceptar tambien espacio (para valores null)
            ($code -eq 0x20 -or ($code -ge 0x2581 -and $code -le 0x2588)) | Should -BeTrue
        }
    }

    It 'valor 100 con Max=100 devuelve un caracter alto' {
        $result = ConvertTo-Sparkline -Values @(100) -Max 100
        # El mas alto del set
        [int]([char]$result[0]) | Should -BeGreaterOrEqual 0x2586
    }

    It 'valor 0 devuelve un caracter bajo o vacio' {
        $result = ConvertTo-Sparkline -Values @(0) -Max 100
        $result.Length | Should -BeGreaterOrEqual 1
        # El mas bajo del set o espacio
        $code = [int]([char]$result[0])
        ($code -eq 0x20 -or $code -le 0x2583) | Should -BeTrue
    }

    It 'array vacio devuelve string vacio' {
        $result = ConvertTo-Sparkline -Values @()
        $result | Should -Be ''
    }

    It 'Max=0 no explota (division por cero)' {
        { ConvertTo-Sparkline -Values @(10, 20) -Max 0 } | Should -Not -Throw
    }
}

Describe 'Get-BarColor' {

    It 'devuelve Red para percent >= 85' {
        Get-BarColor -Percent 85 | Should -Be 'Red'
        Get-BarColor -Percent 95 | Should -Be 'Red'
    }

    It 'devuelve Yellow para percent entre 70 y 84' {
        Get-BarColor -Percent 70 | Should -Be 'Yellow'
        Get-BarColor -Percent 84 | Should -Be 'Yellow'
    }

    It 'devuelve Green para percent < 70' {
        Get-BarColor -Percent 50 | Should -Be 'Green'
        Get-BarColor -Percent 0  | Should -Be 'Green'
    }
}
