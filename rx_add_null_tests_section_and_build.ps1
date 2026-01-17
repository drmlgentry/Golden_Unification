$root   = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$papers = Join-Path $root "papers"
$core   = Join-Path $papers "CORE_MASTER.tex"
$master = Join-Path $papers "MASTER.tex"

$line = '\input{sections/10_null_tests.tex}'

function Ensure-Line($path, $line) {
    $txt = Get-Content $path -Raw
    if ($txt -notmatch [regex]::Escape($line)) {
        $txt = $txt -replace "\\end\{document\}", "$line`r`n`r`n\end{document}"
        Set-Content -Path $path -Value $txt -Encoding UTF8
        Write-Host "Inserted into: $path" -ForegroundColor Green
        Write-Host "  + $line" -ForegroundColor Gray
    } else {
        Write-Host "Already present in: $path" -ForegroundColor DarkGray
    }
}

Ensure-Line $core   $line
Ensure-Line $master $line

Write-Host ""
Write-Host "Compiling CORE_MASTER.tex..." -ForegroundColor Cyan
Push-Location $papers
pdflatex -interaction=nonstopmode "CORE_MASTER.tex" | Out-Null
Pop-Location
Write-Host "Build OK: papers\CORE_MASTER.pdf" -ForegroundColor Cyan
