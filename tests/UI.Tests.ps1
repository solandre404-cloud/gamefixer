#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    $Global:GF = @{
        Version  = 'v2.04'
        Build    = '2604'
        Profile  = 'Test'
        DryRun   = $true
        IsAdmin  = $true
        Hostname = 'TEST-PC'
        User     = 'tester'
        BlockFull  = [char]0x2588
        BlockLight = [char]0x2591
        StartTime  = Get-Date
        LogFile    = 'test.log'
    }

    $modulePath = Join-Path $PSScriptRoot '..\modules\UI.psm1'
    Import-Module $modulePath -Force
}

Describe 'Write-UI' {

    It 'no falla con texto basico' {
        { Write-UI "Hola" -Color Green } | Should -Not -Throw
    }

    It 'acepta string vacio' {
        { Write-UI "" -Color Green } | Should -Not -Throw
    }

    It 'funciona con switch NoNewline' {
        { Write-UI "test" -Color Green -NoNewline } | Should -Not -Throw
    }
}

Describe 'Write-Badge' {

    It 'renderiza sin crashear' {
        { Write-Badge -Text ' TEST ' -Bg DarkYellow -Fg Black } | Should -Not -Throw
    }
}

Describe 'Show-Section' {

    It 'no falla con titulo normal' {
        { Show-Section "TEST SECTION" } | Should -Not -Throw
    }

    It 'no falla con titulo largo' {
        { Show-Section "ESTA ES UNA SECCION CON TITULO LARGO DE VERDAD" } | Should -Not -Throw
    }
}
