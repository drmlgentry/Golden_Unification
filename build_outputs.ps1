# ============================================================
# build_outputs.ps1  (SAFE VERSION — no here-strings)
# ============================================================

$ErrorActionPreference = "Stop"

$root = Resolve-Path .
$data = Join-Path $root "data"
$derived = Join-Path $data "derived"
$figures = Join-Path $root "figures"

foreach ($p in @($data, $derived, $figures)) {
    if (-not (Test-Path $p)) {
        New-Item -ItemType Directory -Path $p | Out-Null
        Write-Host "Created $p" -ForegroundColor Green
    }
}

# ---- placeholder outputs (proof of life) ----
$best = Join-Path $derived "paperIII_bestfits.csv"
$mult = Join-Path $derived "paperIII_multiplicity.csv"

"particle,mass_exp,mass_pred,q,epsilon" | Set-Content $best
"electron,0.000511,0.000511,0,0.0"      | Add-Content $best

"particle,multiplicity" | Set-Content $mult
"electron,1"            | Add-Content $mult

$fig1 = Join-Path $figures "mass_fit_log.pdf"
$fig2 = Join-Path $figures "mass_residuals.pdf"

"PDF PLACEHOLDER" | Set-Content $fig1
"PDF PLACEHOLDER" | Set-Content $fig2

Write-Host ""
Write-Host "Build complete (safe mode)." -ForegroundColor Cyan
Write-Host "Derived data: $derived"
Write-Host "Figures:      $figures"
