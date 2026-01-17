# ============================================================
# RX v2: Fix duplicate inclusion of ../shared/paperIII_results.tex
# - Skips unreadable files (no ACL drama)
# - Treats commented lines as NOT occurrences
# - Keeps exactly ONE uncommented include (prefers sections/03_results.tex)
# - Builds CORE_MASTER + MASTER
# ============================================================

$root   = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$papers = Join-Path $root "papers"

$needle = "\input{../shared/paperIII_results.tex}"
$keeperPreferred = Join-Path $papers "sections\03_results.tex"

function Try-ReadLines($path) {
    try {
        return Get-Content -LiteralPath $path -ErrorAction Stop
    } catch {
        Write-Host "SKIP (unreadable): $path" -ForegroundColor Yellow
        return $null
    }
}

function Is-UncommentedNeedleLine($line) {
    # ignore leading whitespace; if first nonspace is %, treat as commented
    $trim = $line.TrimStart()
    if ($trim.StartsWith("%")) { return $false }
    return ($line -match [regex]::Escape($needle))
}

# Collect all .tex files under papers/
$texFiles = Get-ChildItem -Path $papers -Recurse -Filter "*.tex" | Sort-Object FullName

# Find occurrences (uncommented only)
$occ = @()
foreach ($f in $texFiles) {
    $lines = Try-ReadLines $f.FullName
    if ($null -eq $lines) { continue }

    for ($i=0; $i -lt $lines.Count; $i++) {
        if (Is-UncommentedNeedleLine $lines[$i]) {
            $occ += [pscustomobject]@{ File=$f.FullName; Line=$i; Text=$lines[$i] }
        }
    }
}

Write-Host ""
Write-Host ("Found {0} UNCOMMENTED occurrences of: {1}" -f $occ.Count, $needle) -ForegroundColor Cyan
$occ | ForEach-Object { Write-Host ("  {0}:{1}" -f $_.File, ($_.Line+1)) -ForegroundColor Gray }

if ($occ.Count -le 1) {
    Write-Host "No duplication detected (0 or 1 uncommented occurrence). Proceeding to build." -ForegroundColor Green
} else {

    # Decide keeper
    $keeper = $null
    if (Test-Path -LiteralPath $keeperPreferred) {
        $keeper = $keeperPreferred
        Write-Host "Keeper set to preferred: $keeper" -ForegroundColor Green
    } else {
        $keeper = ($occ | Select-Object -First 1).File
        Write-Host "Keeper set to first occurrence file: $keeper" -ForegroundColor Yellow
    }

    # For each file: comment out every uncommented occurrence except one in keeper file
    foreach ($g in ($occ | Group-Object File)) {
        $path = $g.Name
        $lines = Try-ReadLines $path
        if ($null -eq $lines) { continue }

        $isKeeperFile = ($path -ieq $keeper)
        $changed = $false
        $keptInThisFile = $false

        for ($i=0; $i -lt $lines.Count; $i++) {
            if (Is-UncommentedNeedleLine $lines[$i]) {
                if ($isKeeperFile -and (-not $keptInThisFile)) {
                    # keep exactly one in keeper file
                    $keptInThisFile = $true
                } else {
                    $lines[$i] = "% DUPLICATE REMOVED: " + $lines[$i]
                    $changed = $true
                }
            }
        }

        if ($changed) {
            Set-Content -LiteralPath $path -Value $lines -Encoding UTF8
            Write-Host "Updated: $path" -ForegroundColor Green
        }
    }

    Write-Host ""
    Write-Host "Dedup complete. Re-scan to confirm..." -ForegroundColor Cyan

    # Confirm re-scan (uncommented only)
    $occ2 = @()
    foreach ($f in $texFiles) {
        $lines = Try-ReadLines $f.FullName
        if ($null -eq $lines) { continue }

        for ($i=0; $i -lt $lines.Count; $i++) {
            if (Is-UncommentedNeedleLine $lines[$i]) {
                $occ2 += [pscustomobject]@{ File=$f.FullName; Line=$i }
            }
        }
    }

    Write-Host ("Remaining UNCOMMENTED occurrences: {0}" -f $occ2.Count) -ForegroundColor Cyan
    $occ2 | ForEach-Object { Write-Host ("  {0}:{1}" -f $_.File, ($_.Line+1)) -ForegroundColor Gray }
}

function Build-Tex($texName) {
    $texPath = Join-Path $papers $texName
    if (-not (Test-Path -LiteralPath $texPath)) {
        Write-Host "Missing: $texPath" -ForegroundColor Yellow
        return
    }
    Write-Host ""
    Write-Host ("Compiling {0}..." -f $texName) -ForegroundColor Cyan
    Push-Location $papers
    pdflatex -interaction=nonstopmode $texName | Out-Null
    Pop-Location
    Write-Host ("Build OK: papers\{0}" -f ($texName -replace "\.tex$",".pdf")) -ForegroundColor Cyan
}

Build-Tex "CORE_MASTER.tex"
Build-Tex "MASTER.tex"
