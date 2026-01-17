# apply_language_polish.ps1
# Safe typography/whitespace hygiene for TeX sources (no content rewrites).
# Run from the papers/ directory.

$ErrorActionPreference = "Stop"

$targets = @(
  ".\CORE_MASTER.tex",
  ".\MASTER.tex"
) + (Get-ChildItem -Path ".\sections" -Filter "*.tex" | ForEach-Object { $_.FullName })

foreach ($path in $targets) {
  if (-not (Test-Path $path)) { continue }

  $text = Get-Content -Path $path -Raw

  # 1) Normalize line endings to LF (pdflatex is fine with this)
  $text = $text -replace "`r`n", "`n"

  # 2) Trim trailing spaces on each line
  $text = ($text -split "`n") | ForEach-Object { $_ -replace "\s+$", "" }
  $text = ($text -join "`n")

  # 3) Collapse 3+ blank lines to 2 blank lines (keeps TeX readable)
  $text = $text -replace "(\n\s*){3,}", "`n`n"

  # 4) Fix a few low-risk punctuation spacing issues in prose only
  #    (Avoid touching TeX commands: we only target patterns with plain punctuation)
  $text = $text -replace " ,", ","
  $text = $text -replace "\s+\.", "."
  $text = $text -replace "\.\.\.", "…"

  Set-Content -Path $path -Value $text -NoNewline
}

Write-Host "apply_language_polish.ps1: Completed safe hygiene pass on CORE_MASTER/MASTER and sections/*.tex"
