#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

# Tests de integracion: validan estructura del proyecto sin ejecutar modificaciones

BeforeAll {
    $script:RootDir = Join-Path $PSScriptRoot '..'
}

Describe 'Estructura del proyecto' {

    It 'GameFixer.ps1 existe en la raiz' {
        Test-Path (Join-Path $script:RootDir 'GameFixer.ps1') | Should -BeTrue
    }

    It 'Carpeta modules existe' {
        Test-Path (Join-Path $script:RootDir 'modules') | Should -BeTrue
    }

    It 'version.txt existe y tiene formato valido' {
        $vf = Join-Path $script:RootDir 'version.txt'
        Test-Path $vf | Should -BeTrue
        $v = (Get-Content $vf -Raw).Trim()
        $v | Should -Match '^\d+(\.\d+)+$'
    }

    It 'README.md existe' {
        Test-Path (Join-Path $script:RootDir 'README.md') | Should -BeTrue
    }
}

Describe 'Sintaxis PowerShell valida' {

    It 'GameFixer.ps1 parsea sin errores' {
        $path = Join-Path $script:RootDir 'GameFixer.ps1'
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$errors)
        $errors.Count | Should -Be 0
    }

    It 'Todos los modulos .psm1 parsean sin errores' {
        $modules = Get-ChildItem (Join-Path $script:RootDir 'modules') -Filter '*.psm1'
        foreach ($m in $modules) {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($m.FullName, [ref]$null, [ref]$errors)
            if ($errors.Count -gt 0) {
                Write-Host "Errores en $($m.Name):" -ForegroundColor Red
                $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
            }
            $errors.Count | Should -Be 0 -Because "el modulo $($m.Name) debe parsear sin errores"
        }
    }
}

Describe 'Consistencia de version' {

    It 'version.txt y GameFixer.ps1 tienen la misma version' {
        $vFile = (Get-Content (Join-Path $script:RootDir 'version.txt') -Raw).Trim()

        $psContent = Get-Content (Join-Path $script:RootDir 'GameFixer.ps1') -Raw
        if ($psContent -match "Version\s+=\s+'v([\d\.]+)'") {
            $vInScript = $matches[1]
            $vInScript | Should -Be $vFile
        }
    }
}

Describe 'Archivos tienen BOM UTF-8' {
    # Critico: sin BOM, PowerShell 5.1 rompe los caracteres Unicode

    It 'GameFixer.ps1 tiene BOM' {
        $path = Join-Path $script:RootDir 'GameFixer.ps1'
        $bytes = [System.IO.File]::ReadAllBytes($path) | Select-Object -First 3
        $bytes[0] | Should -Be 0xEF
        $bytes[1] | Should -Be 0xBB
        $bytes[2] | Should -Be 0xBF
    }

    It 'Todos los .psm1 tienen BOM' {
        $modules = Get-ChildItem (Join-Path $script:RootDir 'modules') -Filter '*.psm1'
        foreach ($m in $modules) {
            $bytes = [System.IO.File]::ReadAllBytes($m.FullName) | Select-Object -First 3
            $bytes[0] | Should -Be 0xEF -Because "$($m.Name) debe empezar con BOM UTF-8"
            $bytes[1] | Should -Be 0xBB
            $bytes[2] | Should -Be 0xBF
        }
    }
}
