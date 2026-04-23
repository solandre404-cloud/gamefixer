#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\modules\Updater.psm1'
    # Mock global para que Write-Log no falle en tests
    function global:Write-Log { param($Level, $Message) }
    function global:Write-UI  { param($Text, $Color, [switch]$NoNewline) }
    function global:Write-Badge { param($Text, $Bg, $Fg) }
    function global:Show-Section { param($Title) }
    Import-Module $modulePath -Force
}

Describe 'Compare-SemVer' {

    Context 'detecta correctamente cuando hay update' {
        It 'v2.0 vs v2.1 devuelve -1 (hay update)' {
            Compare-SemVer -Current '2.0' -Remote '2.1' | Should -Be -1
        }

        It 'v2.04 vs v2.10 devuelve -1 (update disponible)' {
            Compare-SemVer -Current '2.04' -Remote '2.10' | Should -Be -1
        }

        It 'v1.9.9 vs v2.0.0 devuelve -1' {
            Compare-SemVer -Current '1.9.9' -Remote '2.0.0' | Should -Be -1
        }
    }

    Context 'detecta cuando estas actualizado' {
        It 'v2.04 vs v2.04 devuelve 0 (misma version)' {
            Compare-SemVer -Current '2.04' -Remote '2.04' | Should -Be 0
        }

        It 'v3.0 vs v3.0.0 devuelve 0 (formatos equivalentes)' {
            Compare-SemVer -Current '3.0' -Remote '3.0.0' | Should -Be 0
        }
    }

    Context 'detecta cuando estas por delante' {
        It 'v2.5 vs v2.1 devuelve 1 (local es mas nuevo)' {
            Compare-SemVer -Current '2.5' -Remote '2.1' | Should -Be 1
        }

        It 'v3.0 vs v2.9.9 devuelve 1' {
            Compare-SemVer -Current '3.0' -Remote '2.9.9' | Should -Be 1
        }
    }

    Context 'tolera prefijo v' {
        It 'acepta "v2.1" como input' {
            Compare-SemVer -Current 'v2.0' -Remote 'v2.1' | Should -Be -1
        }

        It 'mezcla con y sin v' {
            Compare-SemVer -Current 'v2.0' -Remote '2.1' | Should -Be -1
        }
    }
}
