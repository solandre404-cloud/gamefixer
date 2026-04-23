# GAMEFIXER — FamiliaCuba Edition

[![CI](https://github.com/FamiliaCuba/gamefixer/actions/workflows/ci.yml/badge.svg)](https://github.com/FamiliaCuba/gamefixer/actions/workflows/ci.yml)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://learn.microsoft.com/en-us/powershell/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/FamiliaCuba/gamefixer)](https://github.com/FamiliaCuba/gamefixer/releases)

Herramienta profesional de diagnóstico, optimización y reparación de Windows orientada a gaming. PowerShell puro, arquitectura modular, **50+ tests automatizados con CI/CD**, auto-update desde GitHub, y un **dashboard en vivo tipo htop**.

## ✨ Features principales

### Core
- **AUTO-FIX [A]** — pipeline completo en un click con restore point + benchmarks antes/después + reporte HTML
- **Benchmarks [B]** — CPU (single+multi), RAM, disco (multi-drive con SSD/HDD detection), red (adaptativo 10-500MB)
- **Dashboard Live [M]** — monitor en tiempo real con sparklines Unicode tipo htop 🆕
- **Detector de juegos [G]** — Steam, Epic, Riot, Battle.net, Ubisoft, EA, GOG, Xbox Game Pass
- **Tweaks por juego [T]** — CS2, Valorant, LoL, Fortnite, GTA V, RDR2, Minecraft, Apex, R6

### Configuración
- **Settings persistente [S]** — config.json con 10 preferencias editables 🆕
- **Perfiles exportables [E]** — archivos .gfprofile para compartir tu setup con amigos 🆕
- **Auto-update [U]** — check silencioso con banner amarillo si hay versión nueva
- **Arranque épico** — modo "matrix rain" o "typewriter" configurable 🆕

### Extensibilidad
- **Sistema de plugins [X]** — dropear un `.psm1` en `/plugins` y se carga solo
- **Auto-elevación** a administrador, **DRY-RUN** por defecto, **logging** a archivo

## 🧪 Tests y CI/CD

Este proyecto tiene **suite completa de tests con Pester 5**:

```powershell
# Correr todos los tests localmente
.\tests\Run-Tests.ps1

# Con cobertura de código
.\tests\Run-Tests.ps1 -CodeCoverage
```

Cada push al repo corre automáticamente:
- **Pester tests** en Windows Server 2022 + PowerShell 7 (50+ tests)
- **PSScriptAnalyzer** (linter oficial de Microsoft)
- **Parser check**: valida sintaxis de todos los `.ps1` y `.psm1`
- **BOM check**: verifica UTF-8 BOM en todos los archivos (evita bugs de encoding)

Ver estado en la pestaña [Actions](https://github.com/FamiliaCuba/gamefixer/actions).

## 🏗️ Arquitectura

```
GameFixer/
├── GameFixer.ps1              # Entry point
├── GameFixer.bat              # Launcher
├── version.txt                # Sincroniza con GitHub Releases
├── config.json                # Preferencias persistentes (auto-generado)
├── README.md | LICENSE | CHANGELOG.md
├── .gitignore | .github/workflows/ci.yml
│
├── modules/                   # 23 módulos
│   ├── UI.psm1                # Colores, banner, paneles
│   ├── Logger.psm1            # Logging con niveles
│   ├── Telemetry.psm1         # Stats en vivo (multi-disk, VRAM real)
│   ├── Updater.psm1           # Auto-update GitHub
│   ├── Config.psm1            # 🆕 Persistencia de settings
│   ├── Effects.psm1           # 🆕 Matrix rain + animaciones
│   ├── Dashboard.psm1         # 🆕 Monitor live tipo htop
│   ├── Benchmark.psm1         # CPU/RAM/Disk/Red tests
│   ├── HtmlReport.psm1        # Dashboards HTML
│   ├── GameDetector.psm1      # 8 launchers
│   ├── GameTweaks.psm1        # Tweaks por juego
│   ├── AutoFix.psm1           # Pipeline automático
│   ├── PluginLoader.psm1      # Carga dinámica
│   └── (módulos de features)
│
├── plugins/ejemplo.psm1
├── tests/                     # Suite Pester
│   ├── Run-Tests.ps1
│   └── *.Tests.ps1  (7 archivos, 50+ tests)
│
├── profiles/                  # 🆕 .gfprofile exportados
├── logs/                      # Sessions
├── backups/                   # Registry backups
├── benchmarks/                # Historial JSON
└── reports/                   # HTML generados
```

## 🚀 Uso

**Doble-click:** `GameFixer.bat`.

**Desde terminal:**

```powershell
.\GameFixer.ps1              # DRY-RUN (simula)
.\GameFixer.ps1 -Live        # Modo real
.\GameFixer.ps1 -NoBanner    # Sin animación
.\GameFixer.ps1 -NoUpdate    # Sin check updates
```

### Teclas del menú principal

| Tecla | Función |
|-------|---------|
| 1-9, P | Módulos principales (Diagnóstico, Optim, GPU, Red, etc.) |
| A | **Auto-Fix**: pipeline completo automático |
| B | **Benchmarks** |
| G | **Detectar Juegos** |
| T | **Tweaks por Juego** |
| M | **Monitor Live** (dashboard tipo htop) |
| S | **Settings** (edita config.json) |
| E | **Export/Import Perfiles** |
| X | **Plugins** |
| U | **Update** (descarga última versión de GitHub) |
| L | Logs de sesión |
| I | Info de configuración |
| H | Ayuda |
| D | Toggle DRY-RUN |
| Q | Salir |

## 📋 Requisitos

- Windows 10 / 11
- PowerShell 5.1+
- Admin (se auto-eleva)
- Opcional: `nvidia-smi`, Pester 5.x para tests

## 🔒 Seguridad

- **DRY-RUN por defecto**: nada se aplica hasta activar `-Live` o pulsar `[D]`
- **Backups automáticos** del registro antes de cada cambio
- **Puntos de restauración** del sistema integrados
- **Logs con timestamps** de cada acción

## 🧩 Plugins

```powershell
# plugins/miplugin.psm1
$Global:PluginInfo = @{
    Name        = 'Mi Plugin'
    Version     = '1.0'
    Author      = 'Tu nombre'
    Description = 'Qué hace'
    EntryPoint  = 'Invoke-MiFuncion'
}
function Invoke-MiFuncion { Write-UI "Hola" -Color Green }
Export-ModuleMember -Function Invoke-MiFuncion
```

## 📄 Licencia

MIT

## 👥 Créditos

Desarrollado por **FamiliaCuba**.
