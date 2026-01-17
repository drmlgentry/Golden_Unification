# ============================================================
# Rx: Add Paper 7 + Paper 8 sections (LaTeX) and build MASTER
# Writes:
#   papers\sections\07_predictions.tex
#   papers\sections\08_falsifiability.tex
# Inserts:
#   \input{sections/07_predictions.tex}
#   \input{sections/08_falsifiability.tex}
# Compiles:
#   papers\MASTER.tex
# ============================================================

$ErrorActionPreference = "Stop"

# --- Paths ---
$RepoRoot   = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$PapersDir  = Join-Path $RepoRoot "papers"
$SectionsDir= Join-Path $PapersDir "sections"
$MasterTex  = Join-Path $PapersDir "MASTER.tex"

function Ensure-Dir {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
        Write-Host "Created directory: $Path" -ForegroundColor Green
    } else {
        Write-Host "Directory exists:  $Path" -ForegroundColor DarkGray
    }
}

function Write-UTF8 {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Content
    )
    $Content | Set-Content -LiteralPath $Path -Encoding UTF8
    Write-Host "Wrote file:         $Path" -ForegroundColor Green
}

function Insert-InputLine {
    param(
        [Parameter(Mandatory=$true)][string]$MasterPath,
        [Parameter(Mandatory=$true)][string]$LineToInsert
    )

    $txt = Get-Content -LiteralPath $MasterPath -Raw

    if ($txt -match [regex]::Escape($LineToInsert)) {
        Write-Host "Already present in:  $MasterPath" -ForegroundColor DarkGray
        Write-Host "  = $LineToInsert" -ForegroundColor DarkGray
        return
    }

    if ($txt -notmatch "\\end\{document\}") {
        throw "MASTER.tex does not contain \end{document}. Cannot insert safely."
    }

    # Insert right before \end{document}
    $updated = $txt -replace "\\end\{document\}", ($LineToInsert + "`r`n`r`n\end{document}")

    $updated | Set-Content -LiteralPath $MasterPath -Encoding UTF8
    Write-Host "Inserted into:      $MasterPath" -ForegroundColor Green
    Write-Host "  + $LineToInsert" -ForegroundColor Green
}

# --- Preconditions ---
if (-not (Test-Path -LiteralPath $PapersDir))  { throw "Missing papers directory: $PapersDir" }
if (-not (Test-Path -LiteralPath $MasterTex))  { throw "Missing MASTER.tex: $MasterTex" }

Ensure-Dir $SectionsDir

# ============================================================
# Section 07: Predictions and tests
# ============================================================
$sec07 = @'
\section{Paper VII: Predictions and test program}
\label{sec:predictions}

This section isolates those outputs of the Golden Unification program that qualify as \emph{predictions} in the strict sense: numerical statements that can be evaluated against data without post-hoc adjustment of the rule. We separate (i) immediate near-term tests using existing global fits and collider measurements, (ii) medium-term tests requiring improved experimental precision or reanalyses, and (iii) long-term tests that require new facilities or astrophysical surveys.

\subsection{Immediate tests (existing data; days-to-weeks)}
\begin{enumerate}
\item \textbf{CKM phase audit (already implemented).}
Given measured $(s_{12},s_{23},s_{13})$ and a fixed predicted holonomy angle $\theta_\star$, the scan protocol returns a definite $\delta_{\mathrm{CKM}}$ and $J_{\mathrm{CKM}}$. The acceptance criterion is that the returned $\delta_{\mathrm{CKM}}$ matches the current global-fit value within the scan resolution and that the implied $J_{\mathrm{CKM}}$ matches within propagated uncertainties.

\item \textbf{PMNS phase audit (already implemented).}
With leptonic $(s_{12},s_{23},s_{13})$ specified and a leptonic $\theta_\star$ fixed by the model, the same protocol yields $\delta_{\mathrm{PMNS}}$ and $J_{\mathrm{PMNS}}$. The acceptance criterion is agreement with the preferred global-fit region for $\delta_{\mathrm{PMNS}}$ under a declared matching rule (e.g.\ match $\sin\delta$ to $\sin\theta_\star$).

\item \textbf{Sensitivity to input drift.}
Re-run the audit under reasonable perturbations of the mixing-angle inputs (global-fit 1$\sigma$ ranges). A viable model should yield (a) bounded variation of the inferred phases, and (b) no requirement of re-tuning the matching rule.
\end{enumerate}

\subsection{Medium-term tests (months-to-years)}
\begin{enumerate}
\item \textbf{Pre-registered lattice scan outcomes.}
For the anchored logarithmic lattice model of Paper~III, define a fixed search box in $(a,b,c)$ and a fixed tolerance $\epsilon_{\max}$, then publish the complete set of admissible solutions for a declared set of particles. A prediction is the \emph{multiplicity structure} (counts after deduplication by $q$) and the stability of the best-fit $q$ values under updated inputs.

\item \textbf{Scheme and scale dependence.}
Repeat the mass alignment using running masses at declared renormalization scales and schemes (e.g.\ $\overline{\mathrm{MS}}$ at $\mu=m_Z$ where appropriate). A viable structural hypothesis should not collapse under reasonable, standard transformations.

\item \textbf{Cross-sector constraints.}
If a single geometric rule is asserted across sectors (quarks and leptons), then the holonomy parameter(s) used to generate CKM and PMNS phases must be related by an explicit mapping. The mapping must be specified in advance and subjected to global-fit updates.
\end{enumerate}

\subsection{Long-term tests (new measurements)}
\begin{enumerate}
\item \textbf{Improved $\delta_{\mathrm{PMNS}}$ resolution.}
Next-generation long-baseline experiments will tighten the allowed region of $\delta_{\mathrm{PMNS}}$. The model is falsified if the predicted phase mapping is excluded at high confidence once experimental systematics and degeneracies are controlled.

\item \textbf{New-state searches.}
If the mass lattice is promoted from an empirical organization to a claim of new states, then the program must specify a finite list of candidate masses (or narrow windows) along with production and decay hypotheses. Such claims are deferred unless and until uniqueness and stability criteria are met.
\end{enumerate}

\subsection{Reporting standard for predictions}
We adopt the following publication standard:
\begin{enumerate}
\item State the rule first (matching functional, scan grid, tolerance).
\item Publish the full solution set (not only the best point).
\item Declare the comparison dataset (PDG version / global-fit paper / scale scheme).
\item Report failure cases explicitly.
\end{enumerate}
'@

Write-UTF8 (Join-Path $SectionsDir "07_predictions.tex") $sec07

# ============================================================
# Section 08: Falsifiability, null hypotheses, and preregistration
# ============================================================
$sec08 = @'
\section{Paper VIII: Falsifiability, null hypotheses, and preregistration}
\label{sec:falsifiability}

This section formalizes what would count as evidence \emph{against} the Golden Unification hypothesis and provides explicit null models for comparison. The goal is to prevent overfitting and to ensure that any claimed structure is distinguishable from numerical coincidence.

\subsection{Core claim (minimal form)}
The minimal, defensible claim supported by Papers~III--VI is:
\begin{quote}
In logarithmic mass and mixing-phase coordinates, Standard Model flavor data may admit a compact discrete description (a ``low description length'' encoding) that is nontrivially more structured than generic random ensembles under declared comparison rules.
\end{quote}
No new dynamics are assumed at this stage. The claim is structural and phenomenological.

\subsection{Null hypotheses}
We define three nested null hypotheses:
\begin{enumerate}
\item $\mathcal{H}_0$ (unstructured): masses/phases are effectively uncorrelated in the chosen log coordinates, aside from known broad hierarchical trends.
\item $\mathcal{H}_1$ (smooth hierarchy only): masses are generated by smooth distributions in log space; any apparent lattice alignment is attributable to binning artifacts or tolerance choice.
\item $\mathcal{H}_2$ (overcomplete lattice): the integer lattice is so dense that any target value will be approximated to the stated tolerance within the declared search box; apparent matches have no evidential weight.
\end{enumerate}

\subsection{Pre-registration rules}
To avoid post-hoc tuning, any claimed ``match'' must specify in advance:
\begin{enumerate}
\item the anchor choice (e.g.\ electron $q_e=0$) and permitted transformations;
\item the scan region bounds in $(a,b,c)$ or other integer parameters;
\item the objective function (e.g.\ $|\log_\varphi(m_{\mathrm{fit}}/m_{\mathrm{exp}})|$);
\item the tolerance $\epsilon_{\max}$;
\item the deduplication criterion (e.g.\ by $q$);
\item the dataset version (PDG year; global-fit reference; scale and scheme).
\end{enumerate}
A result is not considered confirmatory unless it survives these locked conditions.

\subsection{Multiplicity and evidence}
A key discriminator between ``structure'' and ``mere approximation'' is \emph{solution multiplicity}.
If a large number of distinct lattice points satisfy the tolerance in a modest search box, then the match provides limited evidence. Conversely, if solutions are sparse (especially after deduplication by $q$) and stable under modest input drift, then the match is nontrivial.

We therefore require that each reported target quantity be accompanied by:
\begin{enumerate}
\item total number of solutions in the declared box;
\item number of distinct $q$ values (dedup by $q$);
\item best-fit error and rank of the best point among all solutions;
\item stability of the solution set under input perturbations.
\end{enumerate}

\subsection{Make-or-break criteria}
The program is falsified (in its minimal form) if any of the following occur under the pre-registered protocol:
\begin{enumerate}
\item CKM/PMNS phase mapping fails under updated global fits at high confidence while the matching rule remains fixed.
\item The mass-lattice alignment is shown to be typical under $\mathcal{H}_2$ (overcomplete lattice) for comparable scan regions and tolerances.
\item The apparent structure vanishes under standard scheme/scale choices for running masses.
\end{enumerate}

\subsection{Deliverables for an auditable submission}
A submission-ready package must include:
\begin{enumerate}
\item a single command that regenerates \emph{all} tables and figures from raw inputs;
\item frozen input files (PDG/global-fit snapshots) under version control;
\item a statement of null hypotheses and preregistered scan rules;
\item explicit reporting of both successes and failures.
\end{enumerate}
'@

Write-UTF8 (Join-Path $SectionsDir "08_falsifiability.tex") $sec08

# --- Insert into MASTER.tex ---
Insert-InputLine -MasterPath $MasterTex -LineToInsert "\input{sections/07_predictions.tex}"
Insert-InputLine -MasterPath $MasterTex -LineToInsert "\input{sections/08_falsifiability.tex}"

# --- Build ---
Write-Host ""
Write-Host "Compiling MASTER.tex..." -ForegroundColor Cyan

Push-Location $PapersDir
try {
    & pdflatex -interaction=nonstopmode "MASTER.tex" | Out-Null
    & pdflatex -interaction=nonstopmode "MASTER.tex" | Out-Null

    $pdf = Join-Path $PapersDir "MASTER.pdf"
    $log = Join-Path $PapersDir "MASTER.log"

    if (Test-Path -LiteralPath $pdf) {
        Write-Host ""
        Write-Host "Build OK:" -ForegroundColor Green
        Write-Host "  PDF: $pdf" -ForegroundColor Green
        Write-Host "  LOG: $log" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Build ran, but MASTER.pdf not found. Check MASTER.log." -ForegroundColor Yellow
        Write-Host "  LOG: $log" -ForegroundColor Yellow
    }
}
finally {
    Pop-Location
}
