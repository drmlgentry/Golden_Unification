# ============================================================
# rx_run_null_tests_and_confirm.ps1  (LOUD VERSION)
# ============================================================

$ErrorActionPreference = "Stop"

Write-Output "=== RX START: rx_run_null_tests_and_confirm.ps1 ==="
Write-Output ("PWD: " + (Get-Location).Path)

$root   = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$code   = Join-Path $root "code"
$shared = Join-Path $root "shared"

Write-Output ("ROOT:   " + $root)
Write-Output ("CODE:   " + $code)
Write-Output ("SHARED: " + $shared)

if (-not (Test-Path -LiteralPath $code)) {
  Write-Output "ERROR: code/ folder not found."
  exit 10
}
if (-not (Test-Path -LiteralPath $shared)) {
  Write-Output "ERROR: shared/ folder not found."
  exit 11
}

$candidates = @(
  (Join-Path $code "null_tests_v3.py"),
  (Join-Path $code "null_tests_v2.py"),
  (Join-Path $code "null_tests.py")
)

Write-Output "Looking for candidate Python scripts:"
$candidates | ForEach-Object { Write-Output ("  - " + $_) }

$py = $null
foreach ($c in $candidates) {
  if (Test-Path -LiteralPath $c) { $py = $c; break }
}

if (-not $py) {
  Write-Output "ERROR: No null tests script found in code/."
  Write-Output "Files present in code/:"
  Get-ChildItem -LiteralPath $code -File | Select-Object Name, Length | Format-Table -AutoSize | Out-String | Write-Output
  exit 12
}

Write-Output ("Using: " + $py)
Write-Output "Running: python <script> ..."
python $py
Write-Output ("python exit code: " + $LASTEXITCODE)

if ($LASTEXITCODE -ne 0) {
  Write-Output "ERROR: python failed."
  exit $LASTEXITCODE
}

$out1 = Join-Path $shared "paperIX_null_pvalues.tex"
$out2 = Join-Path $shared "paperIX_null_v3.tex"

Write-Output "Checking for TeX outputs:"
Write-Output ("  - " + $out1)
Write-Output ("  - " + $out2)

$found = @()
if (Test-Path -LiteralPath $out1) { $found += $out1 }
if (Test-Path -LiteralPath $out2) { $found += $out2 }

if ($found.Count -eq 0) {
  Write-Output "ERROR: No TeX output found in shared/."
  Write-Output "shared/ currently contains:"
  Get-ChildItem -LiteralPath $shared -File | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize | Out-String | Write-Output
  exit 13
}

Write-Output "OK: Found TeX output file(s):"
$found | ForEach-Object { Write-Output ("  + " + $_) }

Write-Output "=== RX END: OK ==="
