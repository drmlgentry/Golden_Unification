# ============================================================
# rx_fix_paper6_double_input.ps1
# Remove the SECOND mixing-results block inside 06_holonomy_mixing.tex
# ============================================================

$ErrorActionPreference = "Stop"

$root = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$f = Join-Path $root "papers\sections\06_holonomy_mixing.tex"

if (-not (Test-Path -LiteralPath $f)) { throw "Missing: $f" }

$text = Get-Content -LiteralPath $f -Raw -Encoding UTF8

# Remove the entire trailing duplicate subsection that re-inputs the same results.
# Matches from the duplicate subsection header through the \input line (inclusive).
$pattern = '(?s)\R\\subsection\{Numerical results: CKM and PMNS scans\}.*?\\input\{../shared/paperV_mixing_results\.tex\}\R'
$new = [regex]::Replace($text, $pattern, "`r`n% DUPLICATE REMOVED: Numerical results subsection re-inputed paperV_mixing_results.tex`r`n")

if ($new -eq $text) {
  Write-Host "No change made (pattern not found). Check the exact subsection title." -ForegroundColor Yellow
} else {
  Set-Content -LiteralPath $f -Value $new -Encoding UTF8
  Write-Host "Updated: $f" -ForegroundColor Green
}

# Rebuild
Push-Location (Join-Path $root "papers")
pdflatex -interaction=nonstopmode .\CORE_MASTER.tex | Out-Null
pdflatex -interaction=nonstopmode .\MASTER.tex | Out-Null
Pop-Location

Write-Host "Build complete. Check papers\CORE_MASTER.pdf and papers\MASTER.pdf" -ForegroundColor Cyan
