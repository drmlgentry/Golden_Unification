$ErrorActionPreference = 'Stop'

Push-Location (Join-Path $PSScriptRoot '..\papers')
try {
  latexmk -pdf -interaction=nonstopmode -file-line-error MASTER.tex
}
finally {
  Pop-Location
}
