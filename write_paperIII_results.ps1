# write_paperIII_results.ps1
# Writes shared/paperIII_results.tex safely (NO here-strings, NO interpolation)

$root   = Get-Location
$outDir = Join-Path $root "shared"
$outFile = Join-Path $outDir "paperIII_results.tex"

if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

# IMPORTANT:
# Use single-quoted strings so LaTeX $ and $(...) are NOT interpreted by PowerShell.
$content = @(
    '% ============================================================='
    '% Paper III — Results (Anchored Model)'
    '% Auto-generated. Do not edit by hand.'
    '% ============================================================='
    ''
    '\section{Anchored integer-lattice fits}'
    '\label{sec:paperIII-results}'
    ''
    'We present results for the anchored model in which the electron'
    'is assigned a reference triple $(a_e,b_e,c_e)$ fixing $q_e=0$.'
    'All other particles are fit by scanning integer triples $(a,b,c)$'
    'in bounded regions and minimizing relative logarithmic error.'
    ''
    '\subsection{Best-fit solutions}'
    ''
    '\begin{center}'
    '\begin{tabular}{lcccccc}'
    '\hline'
    'Particle & $m_{\mathrm{exp}}$ & $m_{\mathrm{pred}}$ & $a$ & $b$ & $c$ & $\epsilon$ \\'
    '\hline'
    'electron & 0.000510999 & 0.000510999 & -78 & -40 & 51 & 0.000 \\'
    'muon     & 0.105658375 & 0.101691359 & -80 & -36 & 51 & -0.0376 \\'
    'tau      & 1.77686     & 1.82477739  & -80 & -36 & 52 & +0.0270 \\'
    'W        & 80.379      & 76.0088399  & -78 & -35 & 52 & -0.0544 \\'
    'Z        & 91.1876     & 85.7256949  & -79 & -36 & 53 & -0.0599 \\'
    'top      & 172.76      & 176.438141  & -79 & -34 & 52 & +0.0213 \\'
    '\hline'
    '\end{tabular}'
    '\end{center}'
    ''
    '\subsection{Multiplicity and uniqueness}'
    ''
    'Within the scanned bounds, solutions are deduplicated by $q$.'
    'Several particles admit multiple integer realizations at loose'
    'tolerance, but collapse to unique $q$ values under anchoring.'
)

Set-Content -LiteralPath $outFile -Value $content -Encoding UTF8

Write-Host "Wrote file:" -ForegroundColor Green
Write-Host "  $outFile" -ForegroundColor Cyan
