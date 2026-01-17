# rx_fix_06a_missing_math.ps1
# Fixes "of $ and the predicted ..." -> "of $s_{12}, s_{23}, s_{13}$ and the predicted ..."
# Then rebuilds CORE_MASTER

$ErrorActionPreference = "Stop"

$f = "C:\Users\Your Name Here\Desktop\Golden_Unification\papers\sections\06a_formal_verification.tex"
if (-not (Test-Path -LiteralPath $f)) { throw "File not found: $f" }

$txt0 = Get-Content -LiteralPath $f -Raw
$txt  = $txt0

# Fix the empty math opener: "of $ and the predicted"
$txt = $txt -replace 'of\s*\$\s*and\s+the\s+predicted', 'of $s_{12}, s_{23}, s_{13}$ and the predicted'

# Also normalize any accidental spacing in theta-star
$txt = $txt -replace '\$\\theta\s*_\s*\{\\star\}\$', '$\theta_{\star}$'
$txt = $txt -replace '\$\\theta\s*_\s*\\star\$', '$\theta_{\star}$'

if ($txt -ne $txt0) {
  Set-Content -LiteralPath $f -Value $txt -Encoding UTF8
  Write-Host "Patched: $f" -ForegroundColor Green
} else {
  Write-Host "No changes made (pattern not found). Printing lines 55..70 for manual fix:" -ForegroundColor Yellow
  (Get-Content -LiteralPath $f) | Select-Object -Index 55..70 | ForEach-Object { Write-Host $_ }
}

Push-Location "C:\Users\Your Name Here\Desktop\Golden_Unification\papers"
pdflatex -interaction=nonstopmode -halt-on-error "CORE_MASTER.tex" | Out-Null
Pop-Location

Write-Host "Build OK: papers\CORE_MASTER.pdf" -ForegroundColor Cyan
