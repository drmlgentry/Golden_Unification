# ============================================================
# rx_global_dedup_shared_inputs.ps1
# Enforce single-source inclusion of shared result blocks:
#   - paperIII_results.tex only in sections/03_results.tex
#   - paperV_mixing_results.tex only in sections/06_holonomy_mixing.tex
# Then rebuild CORE_MASTER and MASTER.
# ============================================================

$ErrorActionPreference = "Stop"

$root   = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$papers = Join-Path $root "papers"
$secDir = Join-Path $papers "sections"

$keeperPaperIII = Join-Path $secDir "03_results.tex"
$keeperMixing   = Join-Path $secDir "06_holonomy_mixing.tex"

if (-not (Test-Path -LiteralPath $keeperPaperIII)) { throw "Missing keeper: $keeperPaperIII" }
if (-not (Test-Path -LiteralPath $keeperMixing))   { throw "Missing keeper: $keeperMixing" }

# Files to scan (exclude unreadable ones automatically)
$targets = @()
$targets += Get-ChildItem -LiteralPath $papers -File -Filter "*.tex" -ErrorAction SilentlyContinue
$targets += Get-ChildItem -LiteralPath $secDir -File -Filter "*.tex" -ErrorAction SilentlyContinue

# Patterns (only uncommented lines)
$patIII = '^\s*\\input\{../shared/paperIII_results\.tex\}\s*$'
$patMix = '^\s*\\input\{../shared/paperV_mixing_results\.tex\}\s*$'

function Dedup-One([string]$pattern, [string]$keeperFullPath, [string]$tag) {
  Write-Host ""
  Write-Host ("--- Dedup: " + $tag + " ---") -ForegroundColor Cyan
  Write-Host ("Keeper: " + $keeperFullPath) -ForegroundColor Gray

  foreach ($f in $targets) {
    # Some files may be locked/denied; skip safely.
    try {
      $raw = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
    } catch {
      Write-Host ("SKIP (unreadable): " + $f.FullName) -ForegroundColor Yellow
      continue
    }

    $lines = $raw -split "`r?`n"
    $changed = $false

    for ($i=0; $i -lt $lines.Count; $i++) {
      if ($lines[$i] -match $pattern) {
        if ($f.FullName -ieq $keeperFullPath) {
          # keeper: leave as-is
          continue
        } else {
          $lines[$i] = "% DUPLICATE REMOVED: " + $lines[$i]
          $changed = $true
        }
      }
    }

    if ($changed) {
      Set-Content -LiteralPath $f.FullName -Value ($lines -join "`r`n") -Encoding UTF8
      Write-Host ("Updated: " + $f.FullName) -ForegroundColor Green
    }
  }
}

Dedup-One $patIII $keeperPaperIII "paperIII_results.tex include"
Dedup-One $patMix $keeperMixing   "paperV_mixing_results.tex include"

# Confirm counts
Write-Host ""
Write-Host "=== Confirm remaining uncommented includes ===" -ForegroundColor Cyan

$allScan = @()
$allScan += Get-ChildItem -LiteralPath $papers -File -Filter "*.tex" -ErrorAction SilentlyContinue
$allScan += Get-ChildItem -LiteralPath $secDir -File -Filter "*.tex" -ErrorAction SilentlyContinue

function Count-Matches([string]$pattern, [string]$label) {
  $hits = @()
  foreach ($f in $allScan) {
    try { $c = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8 } catch { continue }
    $lns = $c -split "`r?`n"
    for ($i=0; $i -lt $lns.Count; $i++) {
      if ($lns[$i] -match $pattern) {
        $hits += ("{0}:{1}: {2}" -f $f.FullName, ($i+1), $lns[$i].Trim())
      }
    }
  }
  Write-Host ""
  Write-Host ($label + " (uncommented) = " + $hits.Count) -ForegroundColor Gray
  $hits | ForEach-Object { Write-Host ("  " + $_) }
}

Count-Matches $patIII "paperIII_results.tex includes"
Count-Matches $patMix "paperV_mixing_results.tex includes"

# Rebuild
Push-Location $papers
Write-Host ""
Write-Host "Compiling CORE_MASTER.tex..." -ForegroundColor Cyan
pdflatex -interaction=nonstopmode .\CORE_MASTER.tex | Out-Null
Write-Host "Compiling MASTER.tex..." -ForegroundColor Cyan
pdflatex -interaction=nonstopmode .\MASTER.tex | Out-Null
Pop-Location

Write-Host ""
Write-Host "DONE. Check:" -ForegroundColor Cyan
Write-Host ("  " + (Join-Path $papers "CORE_MASTER.pdf")) -ForegroundColor Gray
Write-Host ("  " + (Join-Path $papers "MASTER.pdf")) -ForegroundColor Gray
