#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    function global:Write-Log { param($Level, $Message) }
    function global:Write-UI  { param($Text, $Color, [switch]$NoNewline) }
    function global:Show-Section { param($Title) }

    $modulePath = Join-Path $PSScriptRoot '..\modules\GameDetector.psm1'
    Import-Module $modulePath -Force
}

Describe 'Get-AllDrives' {

    It 'devuelve al menos un drive' {
        $drives = Get-AllDrives
        $drives | Should -Not -BeNullOrEmpty
    }

    It 'cada entrada termina con ":"' {
        $drives = Get-AllDrives
        foreach ($d in $drives) {
            $d | Should -Match '^[A-Z]:$'
        }
    }

    It 'incluye C: siempre en un sistema Windows' {
        $drives = Get-AllDrives
        $drives | Should -Contain 'C:'
    }
}

Describe 'Get-InstalledLaunchers' {

    It 'devuelve una coleccion (puede ser vacia)' {
        $launchers = @(Get-InstalledLaunchers)
        # -NOT null: es array
        $launchers.GetType().Name | Should -BeIn @('Object[]','ArrayList','Hashtable')
    }

    It 'cada launcher tiene Name y Path' {
        $launchers = Get-InstalledLaunchers
        foreach ($l in $launchers) {
            $l.PSObject.Properties.Name | Should -Contain 'Name'
            $l.PSObject.Properties.Name | Should -Contain 'Path'
            $l.Name | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Get-XboxGamePassGames' {

    It 'devuelve una coleccion sin crashear' {
        { Get-XboxGamePassGames } | Should -Not -Throw
    }

    It 'cada juego detectado tiene las propiedades correctas' {
        $games = @(Get-XboxGamePassGames)
        foreach ($g in $games) {
            $g.Launcher | Should -Be 'Xbox/GP'
            $g.Name | Should -Not -BeNullOrEmpty
            $g.InstallDir | Should -Not -BeNullOrEmpty
        }
    }
}
