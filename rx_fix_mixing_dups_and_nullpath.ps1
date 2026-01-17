# ============================================================
# rx_fix_mixing_dups_and_nullpath.ps1
# Fix duplicate mixing results includes + fix null include path
# Then rebuild CORE_MASTER and MASTER.
# ============================================================

$ErrorActionPreference = "Stop"

$root   = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$papers = Join-Path $root "papers"
$secs   = Join-Path $papers "sections"

function Say($msg) { Write-Host $msg -ForegroundColor Cyan }

function Replace-InFile {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][scriptblock]$Transform
  )
  if (-not (Test-Path -LiteralPath $Path)) { throw "Missing file: $Path" }
  $txt = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  $new = & $Transform $txt
  if ($new -ne $txt) {
    Set-Content -LiteralPath $Path -Value $new -Encoding UTF8
    Write-Host "Updated: $Path" -ForegroundColor Green
  } else {
    Write-Host "No change: $Path" -ForegroundColor DarkGray
  }
}

function Remove-InputLineFromMaster {
  param([string]$MasterPath, [string]$InputLine)
  if (-not (Test-Path -LiteralPath $MasterPath)) { return }
  $lines = Get-Content -LiteralPath $MasterPath -Encoding UTF8
  $before = $lines.Count
  $lines2 = $lines | Where-Object { $_.Trim() -ne $InputLine.Trim() }
  if ($lines2.Count -ne $before) {
    Set-Content -LiteralPath $MasterPath -Value $lines2 -Encoding UTF8
    Write-Host "Removed from $(Split-Path $MasterPath -Leaf): $InputLine" -ForegroundColor Green
  } else {
    Write-Host "Not present in $(Split-Path $MasterPath -Leaf): $InputLine" -ForegroundColor DarkGray
  }
}

function Build-Tex {
  param([string]$TexName)
  $texPath = Join-Path $papers $TexName
  if (-not (Test-Path -LiteralPath $texPath)) { throw "Missing: $texPath" }
  Push-Location $papers
  try {
    Say "Compiling $TexName ..."
    pdflatex -interaction=nonstopmode $TexName
    pdflatex -interaction=nonstopmode $TexName
    $pdf = [System.IO.Path]::ChangeExtension($texPath, ".pdf")
    if (Test-Path -LiteralPath $pdf) {
      Write-Host "Build OK: $pdf" -ForegroundColor Green
    } else {
      throw "Build failed; PDF missing: $pdf"
    }
  } finally {
    Pop-Location
  }
}

Say "=== RX START: fix mixing duplicates + null include path ==="

# 1) Fix duplicated inclusion of paperV_mixing_results.tex inside 06_holonomy_mixing.tex
$hol = Join-Path $secs "06_holonomy_mixing.tex"
Replace-InFile -Path $hol -Transform {
  param($txt)

  # Count occurrences
  $pattern = [regex]::Escape('\input{../shared/paperV_mixing_results.tex}')
  $matches = [regex]::Matches($txt, $pattern)

  if ($matches.Count -le 1) { return $txt }

  # Keep the FIRST occurrence only, comment out the rest
  $out = $txt
  $seen = 0
  $out = [regex]::Replace($out, $pattern, {
      param($m)
      $script:seen++
      if ($script:seen -eq 1) { return $m.Value }
      return "% DUPLICATE REMOVED: " + $m.Value
    })

  return $out
}

# 2) Remove optional "06b_mixing_results.tex" inclusion from MASTER / CORE_MASTER (if present)
$master = Join-Path $papers "MASTER.tex"
$core   = Join-Path $papers "CORE_MASTER.tex"
Remove-InputLineFromMaster -MasterPath $master -InputLine '\input{sections/06b_mixing_results.tex}'
Remove-InputLineFromMaster -MasterPath $core   -InputLine '\input{sections/06b_mixing_results.tex}'

# 3) Fix bad null include path in 09_null_hypotheses.tex: ../../shared -> ../shared
$nullsec = Join-Path $secs "09_null_hypotheses.tex"
Replace-InFile -Path $nullsec -Transform {
  param($txt)
  $txt -replace '\\input\{../../shared/', '\input{../shared/'
}

# 4) Confirm file exists where LaTeX expects it
$nullShared = Join-Path $root "shared\paperIX_null_v3.tex"
if (Test-Path -LiteralPath $nullShared) {
  Write-Host "Found: $nullShared" -ForegroundColor Green
} else {
  Write-Host "WARNING: missing expected shared file: $nullShared" -ForegroundColor Yellow
}

# 5) Rebuild
Build-Tex "CORE_MASTER.tex"
Build-Tex "MASTER.tex"

Say "=== RX END: OK ==="
