# ============================================================================
#  tests/Run-Tests.ps1
#  Ejecuta toda la suite de tests de Pester localmente
# ============================================================================

[CmdletBinding()]
param(
    [string]$TestName,       # Filtrar por nombre especifico (ej -TestName 'Compare-SemVer')
    [switch]$Verbose,        # Output detallado
    [switch]$CodeCoverage    # Generar reporte de cobertura
)

# Verificar Pester
$pesterMin = [version]'5.0.0'
$pester = Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1

if (-not $pester -or $pester.Version -lt $pesterMin) {
    Write-Host "Pester 5.x no encontrado. Instalando..." -ForegroundColor Yellow
    try {
        Install-Module -Name Pester -MinimumVersion $pesterMin -Force -SkipPublisherCheck -Scope CurrentUser
    } catch {
        Write-Host "Fallo la instalacion. Ejecuta en admin: Install-Module Pester -Force" -ForegroundColor Red
        exit 1
    }
}

Import-Module Pester -MinimumVersion $pesterMin -Force

# Configuracion de Pester 5.x
$config = New-PesterConfiguration
$config.Run.Path = $PSScriptRoot
$config.Output.Verbosity = if ($Verbose) { 'Detailed' } else { 'Normal' }
$config.Run.PassThru = $true

if ($TestName) {
    $config.Filter.FullName = $TestName
}

if ($CodeCoverage) {
    $modulesPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'modules\*.psm1'
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = $modulesPath
    $config.CodeCoverage.OutputPath = Join-Path $PSScriptRoot 'coverage.xml'
    $config.CodeCoverage.OutputFormat = 'JaCoCo'
}

Write-Host ""
Write-Host "=== GAMEFIXER TEST SUITE ===" -ForegroundColor Cyan
Write-Host "Ejecutando tests desde: $PSScriptRoot"
Write-Host ""

$result = Invoke-Pester -Configuration $config

Write-Host ""
Write-Host "=== RESUMEN ===" -ForegroundColor Cyan
Write-Host "  Total  : $($result.TotalCount)"
Write-Host "  Passed : $($result.PassedCount)" -ForegroundColor Green
Write-Host "  Failed : $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "  Skipped: $($result.SkippedCount)" -ForegroundColor Yellow
Write-Host "  Duracion: $([math]::Round($result.Duration.TotalSeconds, 2))s"

if ($CodeCoverage -and $result.CodeCoverage) {
    $cov = $result.CodeCoverage
    $pct = if ($cov.CommandsAnalyzedCount -gt 0) {
        [math]::Round(($cov.CommandsExecutedCount / $cov.CommandsAnalyzedCount) * 100, 1)
    } else { 0 }
    Write-Host ""
    Write-Host "=== COBERTURA DE CODIGO ===" -ForegroundColor Cyan
    Write-Host "  Cobertura: $pct% ($($cov.CommandsExecutedCount) / $($cov.CommandsAnalyzedCount) comandos)"
    Write-Host "  Reporte:   $(Join-Path $PSScriptRoot 'coverage.xml')"
}

if ($result.FailedCount -gt 0) {
    exit 1
}
exit 0
