$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

if (Get-Command latexmk -ErrorAction SilentlyContinue) {
  latexmk -pdf -interaction=nonstopmode -halt-on-error MASTER.tex
} else {
  pdflatex -interaction=nonstopmode -halt-on-error MASTER.tex
  bibtex MASTER.aux 2>$null
  pdflatex -interaction=nonstopmode -halt-on-error MASTER.tex
  pdflatex -interaction=nonstopmode -halt-on-error MASTER.tex
}
Write-Host "Done. Output: papers\MASTER.pdf"
