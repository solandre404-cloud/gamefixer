#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    function global:Write-Log { param($Level, $Message) }
    function global:Write-UI  { param($Text, $Color, [switch]$NoNewline) }
    function global:Show-Section { param($Title) }

    $script:testRoot = Join-Path $env:TEMP ("gf-cfg-test-" + [Guid]::NewGuid())
    New-Item -ItemType Directory -Path $script:testRoot -Force | Out-Null

    $Global:GF = @{
        Root    = $script:testRoot
        LogFile = Join-Path $script:testRoot 'test.log'
        User    = 'tester'
        Hostname = 'TEST-PC'
        Version = 'v2.06'
        DryRun  = $true
    }

    $modulePath = Join-Path $PSScriptRoot '..\modules\Config.psm1'
    Import-Module $modulePath -Force
}

AfterAll {
    if (Test-Path $script:testRoot) {
        Remove-Item $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Initialize-Config' {

    It 'crea config.json si no existe' {
        Initialize-Config | Out-Null
        $path = Join-Path $script:testRoot 'config.json'
        Test-Path $path | Should -BeTrue
    }

    It 'devuelve un objeto con las propiedades del schema' {
        $cfg = Initialize-Config
        $cfg.theme | Should -Not -BeNullOrEmpty
        $cfg.PSObject.Properties.Name | Should -Contain 'autoUpdate'
        $cfg.PSObject.Properties.Name | Should -Contain 'language'
        $cfg.PSObject.Properties.Name | Should -Contain 'dryRunDefault'
    }

    It 'mergea config vieja con nuevas keys' {
        # Simulamos config vieja sin 'bootAnimation'
        $old = @{ theme = 'dracula'; language = 'en' }
        $old | ConvertTo-Json | Set-Content -Path (Join-Path $script:testRoot 'config.json') -Encoding UTF8

        $cfg = Initialize-Config
        $cfg.theme | Should -Be 'dracula'
        $cfg.language | Should -Be 'en'
        # bootAnimation deberia tener el default del schema
        $cfg.bootAnimation | Should -Not -BeNullOrEmpty
    }
}

Describe 'Save-Config y Set-ConfigValue' {

    It 'persiste cambios en el archivo' {
        Initialize-Config | Out-Null
        Set-ConfigValue -Key 'theme' -Value 'cyberpunk'

        # Recargar
        $cfg2 = Initialize-Config
        $cfg2.theme | Should -Be 'cyberpunk'
    }
}
