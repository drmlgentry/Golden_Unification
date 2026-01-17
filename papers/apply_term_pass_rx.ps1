# apply_term_pass_rx.ps1
# Regex term pass across Paper_I..Paper_IX .tex (safe backups + clears ReadOnly)

$ErrorActionPreference = "Stop"

function Backup-File($path) {
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $bak = "$path.bak_$ts"
    Copy-Item -LiteralPath $path -Destination $bak -Force
    return $bak
}

function Ensure-NotReadOnly($path) {
    $item = Get-Item -LiteralPath $path -ErrorAction Stop
    if ($item.Attributes -band [IO.FileAttributes]::ReadOnly) {
        $item.Attributes = $item.Attributes -bxor [IO.FileAttributes]::ReadOnly
    }
}

# Targets: prefer Roman numeral names; include alternates if they exist
$targets = @(
    "Paper_I.tex","Paper_II.tex","Paper_III.tex","Paper_IV.tex","Paper_V.tex",
    "Paper_VI.tex","Paper_VII.tex","Paper_VIII.tex","Paper_IX.tex",
    "Paper_1.tex","Paper_2.tex","Paper_3.tex","Paper_4.tex","Paper_5.tex",
    "Paper_6.tex","Paper_7.tex","Paper_8.tex","Paper_9.tex"
) | Where-Object { Test-Path -LiteralPath $_ }

if ($targets.Count -eq 0) {
    throw "No target .tex files found in this directory."
}

# Regex replacements (edit freely, but keep them intentional)
# Use (?i) for case-insensitive where needed, and word boundaries to avoid collateral damage.
$rules = @(
    # Prefer consistent program terminology
    @{ pattern = "\bpre[- ]?registration\b"; replacement = "preregistration" },
    @{ pattern = "\bfalsifiability protocol\b"; replacement = "falsifiability protocol" }, # no-op placeholder
    @{ pattern = "\bnull ensemble(s)?\b"; replacement = "null ensemble$1" },               # consistency
    @{ pattern = "\bbounded[- ]scan(s)?\b"; replacement = "bounded scan$1" },

    # Prefer "residual" + "tolerance" language (avoid casual "error bar" phrasing)
    @{ pattern = "\bwithin tolerance\b"; replacement = "within tolerance" },              # no-op placeholder

    # Prefer "descriptor" over "triple" unless you truly mean d=3 specifically
    @{ pattern = "\binteger triple(s)?\b"; replacement = "integer descriptor$1" },

    # Remove informal filler that reads like draft notes
    @{ pattern = "\(\s*placeholder[^)]*\)"; replacement = "" }
)

Write-Host ("Targets: " + ($targets -join ", "))

foreach ($file in $targets) {
    Ensure-NotReadOnly $file
    $bak = Backup-File $file

    $content = Get-Content -LiteralPath $file -Raw -Encoding UTF8

    foreach ($r in $rules) {
        $content = [regex]::Replace($content, $r.pattern, $r.replacement)
    }

    # Write back UTF8 (PowerShell 5.1 Set-Content default UTF8 is BOM; if you care, switch to .NET writer)
    Set-Content -LiteralPath $file -Value $content -Encoding UTF8 -Force

    Write-Host "Updated: $file (backup: $(Split-Path -Leaf $bak))"
}

Write-Host "Term pass Rx complete."
