# ============================================================
# populate_repo.ps1  (ASCII-only, paste-safe)
# Writes Paper_I..VIII.tex into the explicit repo path.
# ============================================================

$ErrorActionPreference = "Stop"

$Root = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$PapersDir = Join-Path $Root "papers"

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
        Write-Host "Created directory: $Path"
    }
}

function Write-UTF8NoBOM([string]$Path, [string]$Content) {
    $dir = Split-Path -Parent $Path
    Ensure-Dir $dir
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $enc)
    Write-Host "Wrote: $Path"
}

Ensure-Dir $PapersDir

function PaperStub([string]$Title, [string]$Label) {
    return (
        "% " + $Title + "`r`n" +
        "% ===============================================`r`n" +
        "`r`n" +
        "\section{" + $Title + "}`r`n" +
        "\label{" + $Label + "}`r`n" +
        "`r`n" +
        "\subsection{Status}`r`n" +
        "Draft placeholder. Replace this with the full LaTeX content.`r`n"
    )
}

$paperI   = PaperStub "Paper I: Modular A5 origin of the mass lattice" "paper:I"
$paperII  = PaperStub "Paper II: Lattice definition and integer structure" "paper:II"
$paperIII = PaperStub "Paper III: Empirical fits, numerical errors, uniqueness" "paper:III"
$paperIV  = PaperStub "Paper IV: Hyperbolic geometry and embeddings" "paper:IV"
$paperV   = PaperStub "Paper V: CP/T violation as holonomy; CKM matching" "paper:V"
$paperVI  = PaperStub "Paper VI: Dodecahedral topology and cosmological implications" "paper:VI"
$paperVII = PaperStub "Paper VII: Extensions, predictions, and model selection" "paper:VII"

$paperVIII =
"% Paper_VIII.tex - Synthesis, predictions, falsifiability`r`n" +
"% =======================================================`r`n" +
"`r`n" +
"\section{Paper VIII: Synthesis and falsifiability roadmap}`r`n" +
"\label{paper:VIII}`r`n" +
"`r`n" +
"\subsection{Abstract (Paper VIII)}`r`n" +
"We synthesize the Golden Unification program into a falsifiable roadmap. The core thesis is that Standard Model masses and mixing phases may admit a discrete geometric/arithmetic description of low description length. We specify which outputs count as genuine predictions, define pre-registration rules to avoid overfitting, and give a minimal list of make-or-break tests.`r`n" +
"`r`n" +
"\subsection{Key falsifiability criteria}`r`n" +
"\begin{enumerate}`r`n" +
"\item \textbf{Uniqueness reporting:} integer/phase solutions must be reported as sets, not single best fits.`r`n" +
"\item \textbf{Stability:} results should be stable under reasonable updates (running masses, scheme choices, updated CKM fits).`r`n" +
"\item \textbf{Prediction:} at least one quantitative prediction must be stated before discovery/measurement.`r`n" +
"\end{enumerate}`r`n" +
"`r`n" +
"\subsection{Deliverable checklist}`r`n" +
"Before arXiv submission, the program should include: (i) a reproducible dataset file, (ii) a deterministic script that regenerates all tables and figures, (iii) a bibliography pass, and (iv) an arXiv packaging script.`r`n"

Write-UTF8NoBOM (Join-Path $PapersDir "Paper_I.tex")   $paperI
Write-UTF8NoBOM (Join-Path $PapersDir "Paper_II.tex")  $paperII
Write-UTF8NoBOM (Join-Path $PapersDir "Paper_III.tex") $paperIII
Write-UTF8NoBOM (Join-Path $PapersDir "Paper_IV.tex")  $paperIV
Write-UTF8NoBOM (Join-Path $PapersDir "Paper_V.tex")   $paperV
Write-UTF8NoBOM (Join-Path $PapersDir "Paper_VI.tex")  $paperVI
Write-UTF8NoBOM (Join-Path $PapersDir "Paper_VII.tex") $paperVII
Write-UTF8NoBOM (Join-Path $PapersDir "Paper_VIII.tex") $paperVIII

Write-Host ""
Write-Host "Repo population complete."
Write-Host ("Wrote files under: " + $PapersDir)
