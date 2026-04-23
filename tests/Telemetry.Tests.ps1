#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    function global:Write-Log { param($Level, $Message) }

    $modulePath = Join-Path $PSScriptRoot '..\modules\Telemetry.psm1'
    Import-Module $modulePath -Force

    # Setup global necesario
    $Global:GF = @{
        LogsDir = $env:TEMP
        LogFile = Join-Path $env:TEMP 'test.log'
    }
}

Describe 'Get-TelemetryStats' {

    It 'devuelve un PSCustomObject' {
        $stats = Get-TelemetryStats
        $stats | Should -Not -BeNullOrEmpty
        $stats.GetType().Name | Should -Be 'PSCustomObject'
    }

    It 'incluye todas las propiedades esperadas' {
        $stats = Get-TelemetryStats
        $expected = @('CPU','GPU','RAM','Disk','DiskUsedGB','DiskTotalGB','OS','NetStatus','Services','LastRun')
        foreach ($prop in $expected) {
            $stats.PSObject.Properties.Name | Should -Contain $prop
        }
    }

    It 'CPU es un numero entre 0 y 100' {
        $stats = Get-TelemetryStats
        $stats.CPU | Should -BeGreaterOrEqual 0
        $stats.CPU | Should -BeLessOrEqual 100
    }

    It 'RAM es un numero entre 0 y 100' {
        $stats = Get-TelemetryStats
        $stats.RAM | Should -BeGreaterOrEqual 0
        $stats.RAM | Should -BeLessOrEqual 100
    }

    It 'incluye lista Disks' {
        $stats = Get-TelemetryStats
        $stats.Disks | Should -Not -BeNullOrEmpty
    }

    It 'cada disco tiene Drive, TotalGB, UsedGB, Percent' {
        $stats = Get-TelemetryStats
        foreach ($d in $stats.Disks) {
            $d.PSObject.Properties.Name | Should -Contain 'Drive'
            $d.PSObject.Properties.Name | Should -Contain 'TotalGB'
            $d.PSObject.Properties.Name | Should -Contain 'UsedGB'
            $d.PSObject.Properties.Name | Should -Contain 'Percent'
        }
    }

    It 'OS no esta vacio' {
        $stats = Get-TelemetryStats
        $stats.OS | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-GPUVRam' {

    It 'devuelve un numero positivo con fallback' {
        # Simulamos AdapterRAM de 4GB que reporta uint32 (saturado)
        $result = Get-GPUVRam -GpuName 'Test GPU' -Fallback 4GB
        $result | Should -BeGreaterThan 0
    }

    It 'devuelve 0 o positivo sin fallback ni fuentes' {
        $result = Get-GPUVRam -GpuName 'NombreQueNoExisteJamas' -Fallback 0
        $result | Should -BeGreaterOrEqual 0
    }
}
