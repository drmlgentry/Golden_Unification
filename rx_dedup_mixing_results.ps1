# ============================================================
# rx_dedup_mixing_results.ps1
# Keep ONLY one uncommented include of paperV_mixing_results.tex
# Preferred keeper: papers/sections/06_holonomy_mixing.tex
# ============================================================

$ErrorActionPreference = "Stop"

$root = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$papers = Join-Path $root "papers"

$pattern = '\input{../shared/paperV_mixing_results.tex}'
$keeper  = Join-Path $papers "sections\06_holonomy_mixing.tex"

Write-Host "Keeper:" -ForegroundColor Cyan
Write-Host "  $keeper" -ForegroundColor Gray
Write-Host ""

# Collect targets; exclude unreadable/locked files like _V_EPJC.tex
$targets = Get-ChildItem -Path $papers -Recurse -File -Filter *.tex |
  Where-Object { $_.Name -ne "_V_EPJC.tex" }

# 1) Comment out every uncommented occurrence in ALL files except keeper
foreach ($f in $targets) {
  if ($f.FullName -eq $keeper) { continue }

  $lines = Get-Content -LiteralPath $f.FullName -ErrorAction Stop

  $changed = $false
  for ($i=0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $trim = $line.TrimStart()
    if ($trim.StartsWith("%")) { continue }

    if ($line -match [regex]::Escape($pattern)) {
      $lines[$i] = "% DUPLICATE REMOVED: " + $line
      $changed = $true
    }
  }

  if ($changed) {
    Set-Content -LiteralPath $f.FullName -Value $lines -Encoding UTF8
    Write-Host ("Updated: " + $f.FullName) -ForegroundColor Green
  }
}

# 2) In the keeper file: ensure ONLY ONE uncommented occurrence exists
$kLines = Get-Content -LiteralPath $keeper -ErrorAction Stop

$idxs = @()
for ($i=0; $i -lt $kLines.Count; $i++) {
  $line = $kLines[$i]
  $trim = $line.TrimStart()
  if ($trim.StartsWith("%")) { continue }
  if ($line -match [regex]::Escape($pattern)) { $idxs += $i }
}

if ($idxs.Count -gt 1) {
  # keep the first, comment out the rest
  for ($j=1; $j -lt $idxs.Count; $j++) {
    $kLines[$idxs[$j]] = "% DUPLICATE REMOVED (keeper extra): " + $kLines[$idxs[$j]]
  }
  Set-Content -LiteralPath $keeper -Value $kLines -Encoding UTF8
  Write-Host ("Keeper deduped: extra occurrences commented (" + ($idxs.Count-1) + ")") -ForegroundColor Yellow
} else {
  Write-Host ("Keeper OK: uncommented occurrences = " + $idxs.Count) -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Re-scan (uncommented occurrences)..." -ForegroundColor Cyan

$hits = Select-String -Path (Join-Path $papers "*.tex"), (Join-Path $papers "sections\*.tex") `
  -Pattern '^\s*\\input\{../shared/paperV_mixing_results\.tex\}' -ErrorAction SilentlyContinue

$hits | ForEach-Object { "{0}:{1}  {2}" -f $_.Path, $_.LineNumber, $_.Line.Trim() }

Write-Host ""
Write-Host ("Remaining uncommented hits: " + $hits.Count) -ForegroundColor Cyan

# 3) Build
Write-Host ""
Write-Host "Compiling CORE_MASTER.tex..." -ForegroundColor Cyan
Push-Location $papers
pdflatex -interaction=nonstopmode .\CORE_MASTER.tex | Out-Null
Write-Host "Compiling MASTER.tex..." -ForegroundColor Cyan
pdflatex -interaction=nonstopmode .\MASTER.tex | Out-Null
Pop-Location

Write-Host ""
Write-Host "DONE. Check papers\CORE_MASTER.pdf and papers\MASTER.pdf" -ForegroundColor Green
