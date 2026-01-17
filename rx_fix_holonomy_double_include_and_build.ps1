# ============================================================
# rx_fix_holonomy_double_include_and_build.ps1
# Removes duplicate \input{../shared/paperV_mixing_results.tex}
# inside papers/sections/06_holonomy_mixing.tex (keeps first).
# Then rebuilds CORE_MASTER + MASTER.
# ============================================================

$ErrorActionPreference = "Stop"

$root   = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$papers = Join-Path $root "papers"
$sec    = Join-Path $papers "sections"
$f      = Join-Path $sec "06_holonomy_mixing.tex"

if (-not (Test-Path -LiteralPath $f)) { throw "Missing: $f" }

$lines = Get-Content -LiteralPath $f

$pattern = '^[ \t]*\\input\{\.\./shared/paperV_mixing_results\.tex\}[ \t]*$'
$hits = @()
for ($i=0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -match $pattern) { $hits += $i }
}

Write-Host ("Found {0} active mixing includes in 06_holonomy_mixing.tex" -f $hits.Count) -ForegroundColor Cyan
if ($hits.Count -le 1) {
  Write-Host "No duplicate to remove. Proceeding to build." -ForegroundColor Yellow
} else {
  # Keep the first occurrence, comment out all later ones
  for ($k=1; $k -lt $hits.Count; $k++) {
    $idx = $hits[$k]
    $lines[$idx] = "% DUPLICATE REMOVED (kept first include): " + $lines[$idx]
  }
  Set-Content -LiteralPath $f -Value $lines -Encoding UTF8
  Write-Host "Updated: papers/sections/06_holonomy_mixing.tex (removed extra include(s))" -ForegroundColor Green
}

function Build-Tex([string]$texName) {
  Push-Location $papers
  try {
    Write-Host ("Compiling {0}..." -f $texName) -ForegroundColor Cyan
    & pdflatex -interaction=nonstopmode $texName | Out-Null
    & pdflatex -interaction=nonstopmode $texName | Out-Null
    $pdf = [IO.Path]::ChangeExtension((Join-Path $papers $texName), ".pdf")
    if (-not (Test-Path -LiteralPath $pdf)) { throw ("Build failed; PDF not found: " + $pdf) }
    Write-Host ("Build OK: " + $pdf) -ForegroundColor Green
  } finally {
    Pop-Location
  }
}

Build-Tex "CORE_MASTER.tex"
Build-Tex "MASTER.tex"

Write-Host "DONE." -ForegroundColor Cyan
