# ============================================================
# rx_build_all.ps1
# Build MASTER.tex and CORE_MASTER.tex reliably (2-pass build)
# Run from repo root: Golden_Unification\
# ============================================================

$ErrorActionPreference = "Stop"

$root   = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$papers = Join-Path $root "papers"

if (-not (Test-Path -LiteralPath $papers)) {
  throw ("Missing folder: " + $papers)
}

function Build-One {
  param([Parameter(Mandatory=$true)][string]$TexName)

  $texPath = Join-Path $papers $TexName
  if (-not (Test-Path -LiteralPath $texPath)) {
    throw ("Missing TeX file: " + $texPath)
  }

  Push-Location $papers
  try {
    Write-Host "" 
    Write-Host ("=== Building: " + $TexName + " (pass 1/2) ===") -ForegroundColor Cyan
    & pdflatex -interaction=nonstopmode -halt-on-error $TexName | Out-Host
    if ($LASTEXITCODE -ne 0) { throw ("pdflatex failed pass 1: " + $TexName) }

    Write-Host ("=== Building: " + $TexName + " (pass 2/2) ===") -ForegroundColor Cyan
    & pdflatex -interaction=nonstopmode -halt-on-error $TexName | Out-Host
    if ($LASTEXITCODE -ne 0) { throw ("pdflatex failed pass 2: " + $TexName) }

    $pdf = [System.IO.Path]::ChangeExtension($texPath, ".pdf")
    $log = [System.IO.Path]::ChangeExtension($texPath, ".log")

    if (-not (Test-Path -LiteralPath $pdf)) {
      throw ("Build failed: PDF not found: " + $pdf)
    }

    # Try to extract page count from the log, if present:
    $pages = $null
    if (Test-Path -LiteralPath $log) {
      $m = Select-String -Path $log -Pattern 'Output written on .* \((\d+)\s+pages' -AllMatches |
           Select-Object -First 1
      if ($m -and $m.Matches.Count -gt 0) {
        $pages = $m.Matches[0].Groups[1].Value
      }
    }

    Write-Host ("OK:  " + $pdf) -ForegroundColor Green
    if ($pages) {
      Write-Host ("     pages: " + $pages) -ForegroundColor Green
    }
    if (Test-Path -LiteralPath $log) {
      Write-Host ("LOG: " + $log) -ForegroundColor DarkGray
    }
  }
  finally {
    Pop-Location
  }
}

Write-Host "=== RX START: rx_build_all.ps1 ===" -ForegroundColor Cyan
Write-Host ("ROOT:   " + $root)
Write-Host ("PAPERS: " + $papers)

Build-One "CORE_MASTER.tex"
Build-One "MASTER.tex"

Write-Host ""
Write-Host "=== RX END: OK ===" -ForegroundColor Cyan
