# pass2_polish_III_IV_V.ps1
# ------------------------------------------
# Safe language + terminology normalization across Paper_III, Paper_IV, Paper_V
# - Makes .bak backups
# - Never writes if path is null
# - Never prints "Updated" on failure
# - Normalizes key terms to match the 7–9 diagnostic/protocol language
# ------------------------------------------

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-FileSafe {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Content
    )
    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Refusing to write: Path is null/empty."
    }

    $bak = "$Path.bak"
    if (Test-Path $Path) {
        Copy-Item $Path $bak -Force
        Write-Host "Backup created: $([IO.Path]::GetFileName($bak))" -ForegroundColor DarkGray
    } else {
        Write-Host "WARNING: File not found, skipping: $Path" -ForegroundColor Yellow
        return
    }

    try {
        # temp-write then atomic move prevents partial files
        $tmp = "$Path.tmp"
        Set-Content -Path $tmp -Value $Content -Encoding UTF8 -NoNewline -ErrorAction Stop
        Move-Item -Path $tmp -Destination $Path -Force -ErrorAction Stop
        Write-Host "Updated: $([IO.Path]::GetFileName($Path))" -ForegroundColor Green
    } catch {
        Write-Host "FAILED to write: $Path -> $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Apply-Replacements {
    param(
        [Parameter(Mandatory=$true)][string]$Text
    )

    # Terminology normalization (journal-neutral)
    $repl = @(
        # hyphenation / consistency
        @{ pattern = "low description length";        replace = "low--description--length" },
        @{ pattern = "Low description length";        replace = "Low--description--length" },
        @{ pattern = "low-description-length";        replace = "low--description--length" },
        @{ pattern = "pre registered";                replace = "preregistered" },
        @{ pattern = "pre-registered";                replace = "preregistered" },
        @{ pattern = "Pre-registered";                replace = "Preregistered" },

        # null ensemble phrasing
        @{ pattern = "null ensembles";                replace = "null ensembles" }, # no-op guard
        @{ pattern = "Null ensembles";                replace = "Null ensembles" }, # no-op guard
        @{ pattern = "null distribution";             replace = "null-ensemble distribution" },

        # multiplicity wording
        @{ pattern = "uniqueness diagnostics";        replace = "multiplicity diagnostics" },
        @{ pattern = "Multiplicity matters";          replace = "Multiplicity matters" }, # no-op
        @{ pattern = "multiplicity reporting";        replace = "multiplicity reporting" }, # no-op

        # anchoring wording
        @{ pattern = "anchor discipline";             replace = "anchoring discipline" },
        @{ pattern = "Anchor discipline";             replace = "Anchoring discipline" },

        # avoid overclaim language that causes reviewer friction
        @{ pattern = "prove";                         replace = "demonstrate" },
        @{ pattern = "Proof";                         replace = "Demonstration" }
    )

    foreach ($r in $repl) {
        $Text = $Text -replace [regex]::Escape($r.pattern), $r.replace
    }

    return $Text
}

# --- Targets (explicit, no nulls) ---
$targets = @(
    "Paper_III.tex",
    "Paper_IV.tex",
    "Paper_V.tex"
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

# --- Run ---
foreach ($name in $targets) {
    $path = Join-Path (Get-Location) $name
    if (-not (Test-Path $path)) {
        Write-Host "Skipping (missing): $name" -ForegroundColor Yellow
        continue
    }

    $raw = Get-Content -Path $path -Raw -Encoding UTF8
    $new = Apply-Replacements -Text $raw

    # Optional: ensure final newline
    if (-not $new.EndsWith("`n")) { $new += "`n" }

    Write-FileSafe -Path $path -Content $new
}

Write-Host "Pass 2 complete." -ForegroundColor Cyan
