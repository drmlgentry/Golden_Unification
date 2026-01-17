param(
  [string]$GppRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$guRoot = Resolve-Path (Join-Path $here "..")

# default: sibling folder on Desktop
if ([string]::IsNullOrWhiteSpace($GppRoot)) {
  $desktop = Split-Path -Parent $guRoot
  $GppRoot = Join-Path $desktop "Geometric_Particle_Physics"
}

if (-not (Test-Path $GppRoot)) { throw "GPP root not found: $GppRoot" }

Write-Host "GU root : $guRoot" -ForegroundColor Cyan
Write-Host "GPP root: $GppRoot" -ForegroundColor Cyan

$pdgUpdate = Join-Path $GppRoot "scripts\pdg_update_mass_width.py"
$pdgSM     = Join-Path $GppRoot "scripts\pdg_extract_sm_masses.py"

if (-not (Test-Path $pdgUpdate)) { throw "Missing: $pdgUpdate" }
if (-not (Test-Path $pdgSM))     { throw "Missing: $pdgSM" }

# Run the two authoritative scripts inside GPP
Push-Location $GppRoot
try {
  Write-Host "`n[RUN] python scripts\pdg_update_mass_width.py" -ForegroundColor Yellow
  python $pdgUpdate
  if ($LASTEXITCODE -ne 0) { throw "pdg_update_mass_width.py failed with exit code $LASTEXITCODE" }

  Write-Host "`n[RUN] python scripts\pdg_extract_sm_masses.py" -ForegroundColor Yellow
  python $pdgSM
  if ($LASTEXITCODE -ne 0) { throw "pdg_extract_sm_masses.py failed with exit code $LASTEXITCODE" }
}
finally {
  Pop-Location
}

# Pull artifacts from GPP -> GU
$pull = Join-Path $guRoot "code\pull_from_gpp.ps1"
if (-not (Test-Path $pull)) { throw "Missing: $pull" }

Write-Host "`n[RUN] pull_from_gpp.ps1" -ForegroundColor Yellow
powershell -ExecutionPolicy Bypass -File $pull -GppRoot $GppRoot

Write-Host "`nOK: PDG updated in GPP, SM extracted, and artifacts copied into GU." -ForegroundColor Green
