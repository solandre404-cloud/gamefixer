#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    function global:Write-Log { param($Level, $Message) }
    function global:Write-UI  { param($Text, $Color, [switch]$NoNewline) }
    function global:Show-Section { param($Title) }

    $Global:GF = @{
        Root = $env:TEMP
        LogFile = Join-Path $env:TEMP 'test.log'
    }

    $modulePath = Join-Path $PSScriptRoot '..\modules\Benchmark.psm1'
    Import-Module $modulePath -Force
}

Describe 'Invoke-CPUBenchmark' {

    It 'devuelve un objeto con scores numericos' {
        $r = Invoke-CPUBenchmark
        $r | Should -Not -BeNullOrEmpty
        $r.Type | Should -Be 'CPU'
        $r.SingleScore | Should -BeGreaterThan 0
        $r.MultiScore | Should -BeGreaterThan 0
    }

    It 'incluye numero de cores' {
        $r = Invoke-CPUBenchmark
        $r.Cores | Should -BeGreaterThan 0
    }

    It 'tiene Summary no vacio' {
        $r = Invoke-CPUBenchmark
        $r.Summary | Should -Not -BeNullOrEmpty
    }
}

Describe 'Invoke-RAMBenchmark' {

    It 'devuelve velocidades de read y write' {
        $r = Invoke-RAMBenchmark
        $r.ReadMBs | Should -BeGreaterThan 0
        $r.WriteMBs | Should -BeGreaterThan 0
    }

    It 'Type es RAM' {
        $r = Invoke-RAMBenchmark
        $r.Type | Should -Be 'RAM'
    }
}

Describe 'Save-BenchResult y Show-BenchHistory' {

    BeforeAll {
        # Usar carpeta temporal aislada
        $script:testDir = Join-Path $env:TEMP ("gfbench-test-" + [Guid]::NewGuid())
        New-Item -ItemType Directory -Path $script:testDir -Force | Out-Null
        $Global:GF.Root = $script:testDir
    }

    AfterAll {
        if (Test-Path $script:testDir) {
            Remove-Item $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Save-BenchResult crea archivo history.json' {
        $fake = [pscustomobject]@{
            Type      = 'CPU'
            Timestamp = '2026-04-21 12:00:00'
            Summary   = 'test'
            Score     = 42
        }
        Save-BenchResult -Type 'CPU' -Result $fake

        $histFile = Join-Path $script:testDir 'benchmarks\history.json'
        Test-Path $histFile | Should -BeTrue
    }

    It 'mantiene entradas previas al agregar nueva' {
        $fake1 = [pscustomobject]@{ Type='CPU'; Timestamp='2026-04-21 12:00:00'; Summary='r1' }
        $fake2 = [pscustomobject]@{ Type='CPU'; Timestamp='2026-04-21 13:00:00'; Summary='r2' }
        Save-BenchResult -Type 'CPU' -Result $fake1
        Save-BenchResult -Type 'CPU' -Result $fake2

        $histFile = Join-Path $script:testDir 'benchmarks\history.json'
        $history = @(Get-Content $histFile -Raw | ConvertFrom-Json)
        $history.Count | Should -BeGreaterOrEqual 2
    }
}
