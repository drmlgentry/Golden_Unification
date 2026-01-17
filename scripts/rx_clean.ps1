# Remove common LaTeX build artifacts and local transient outputs.
# Safe to run repeatedly.

$ErrorActionPreference = 'Stop'

$roots = @('.', 'papers', 'papers/sections')
$patterns = @(
  '*.aux','*.bbl','*.bcf','*.blg','*.fdb_latexmk','*.fls','*.lof','*.lot','*.log','*.out','*.run.xml','*.synctex.gz','*.toc','texput.log','*.nav','*.snm'
)

foreach ($r in $roots) {
  if (Test-Path $r) {
    foreach ($p in $patterns) {
      Get-ChildItem -LiteralPath $r -Recurse -Force -File -Filter $p -ErrorAction SilentlyContinue |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
    }
  }
}

# Do not delete PDFs by default; uncomment if you want a totally clean tree.
# Get-ChildItem -LiteralPath 'papers' -Recurse -Force -File -Filter '*.pdf' | Remove-Item -Force

Write-Host 'Clean complete.'
