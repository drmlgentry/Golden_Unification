# ============================================================
# RX: Deduplicate inclusion of shared/paperIII_results.tex
# Keeps the first include; comments out the rest; rebuilds core
# ============================================================

$root    = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$papers  = Join-Path $root "papers"
$sections= Join-Path $papers "sections"
$core    = Join-Path $papers "CORE_MASTER.tex"

$pattern1 = "\\input\{../shared/paperIII_results\.tex\}"
$pattern2 = "paperIII_results\.tex"

$files = Get-ChildItem -Path $sections -Filter "*.tex" | Sort-Object Name

$hits = @()
foreach ($f in $files) {
    $text = Get-Content $f.FullName -Raw
    if ($text -match $pattern2) {
        $hits += $f.FullName
    }
}

if ($hits.Count -eq 0) {
    Write-Host "No references to paperIII_results.tex found in papers/sections/*.tex" -ForegroundColor Yellow
    Write-Host "Nothing to dedup." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found references in:" -ForegroundColor Cyan
$hits | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

$kept = $false
foreach ($path in $hits) {
    $text = Get-Content $path -Raw

    # If the file uses the explicit input line, dedup that.
    if ($text -match $pattern1) {
        if (-not $kept) {
            $kept = $true
            Write-Host "Keeping first include in: $path" -ForegroundColor Green
        } else {
            $text = $text -replace $pattern1, "% DUPLICATE REMOVED: \\input{../shared/paperIII_results.tex}"
            Set-Content -Path $path -Value $text -Encoding UTF8
            Write-Host "Commented duplicate include in: $path" -ForegroundColor Green
        }
        continue
    }

    # Otherwise, if the file references paperIII_results.tex in some other way,
    # we just warn (do not edit blindly).
    if (-not ($text -match $pattern1)) {
        Write-Host "NOTE: $path references paperIII_results.tex but not via \input{../shared/paperIII_results.tex}." -ForegroundColor Yellow
        Write-Host "      Review that file manually if duplication persists." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Compiling CORE_MASTER.tex..." -ForegroundColor Cyan
pdflatex -interaction=nonstopmode -output-directory $papers $core | Out-Null

Write-Host "Build OK: papers\CORE_MASTER.pdf" -ForegroundColor Cyan
Write-Host "Log:     papers\CORE_MASTER.log" -ForegroundColor Cyan
