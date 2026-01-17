param(
  [string]$GppRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$guRoot = Resolve-Path (Join-Path $here "..")

if ([string]::IsNullOrWhiteSpace($GppRoot)) {
  $desktop = Split-Path -Parent $guRoot
  $GppRoot = Join-Path $desktop "Geometric_Particle_Physics"
}

if (-not (Test-Path $GppRoot)) { throw "GPP root not found: $GppRoot" }

Write-Host "GU root : $guRoot" -ForegroundColor Cyan
Write-Host "GPP root: $GppRoot" -ForegroundColor Cyan

$copyPairs = @(
  # PDG mass/width products
  @{ src = "data\pdg\mass_width_latest.json"; dst = "data\pdg\mass_width_latest.json" },
  @{ src = "data\pdg\mass_width_meta.json";   dst = "data\pdg\mass_width_meta.json" },

  # SM subset products
  @{ src = "data\pdg\sm_masses_latest.json";  dst = "data\pdg\sm_masses_latest.json" },
  @{ src = "data\pdg\sm_masses_latest.csv";   dst = "data\pdg\sm_masses_latest.csv" },
  @{ src = "data\pdg\sm_masses_meta.json";    dst = "data\pdg\sm_masses_meta.json" }
)

function Ensure-Dir([string]$p) {
  if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function Copy-One([string]$srcAbs, [string]$dstAbs) {
  Ensure-Dir (Split-Path -Parent $dstAbs)
  Copy-Item -Force -Path $srcAbs -Destination $dstAbs
}

$copied = 0
$missed = 0

Write-Host "`n=== Copying artifacts GPP -> GU ===" -ForegroundColor Yellow
foreach ($p in $copyPairs) {
  $srcAbs = Join-Path $GppRoot $p.src
  $dstAbs = Join-Path $guRoot  $p.dst

  if (Test-Path $srcAbs) {
    Copy-One $srcAbs $dstAbs
    Write-Host "[COPY] $($p.src) -> $($p.dst)" -ForegroundColor Green
    $copied++
  } else {
    Write-Host "[MISS] $($p.src)" -ForegroundColor DarkYellow
    $missed++
  }
}

Write-Host "`nDone. Copied=$copied Missing=$missed" -ForegroundColor Cyan
if ($missed -gt 0) {
  Write-Host "Tip: run update_pdg_and_pull.ps1 first to regenerate missing outputs in GPP." -ForegroundColor DarkYellow
}
