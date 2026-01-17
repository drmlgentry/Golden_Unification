# ============================================================
# RX: Add Section 09 (Null hypotheses & pre-registered tests)
# and rebuild MASTER / CORE_MASTER.
# ============================================================

$Root   = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$Papers = Join-Path $Root "papers"
$Secs   = Join-Path $Papers "sections"

function Ensure-Dir {
  param([Parameter(Mandatory=$true)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null }
}

function Write-UTF8 {
  param([Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Content)
  $Content | Set-Content -Path $Path -Encoding UTF8
  Write-Host "Wrote file: $Path" -ForegroundColor Green
}

function Insert-InputBeforeEndDoc {
  param([Parameter(Mandatory=$true)][string]$TexPath,
        [Parameter(Mandatory=$true)][string]$InputLine)

  if (-not (Test-Path -LiteralPath $TexPath)) { return }

  $txt = Get-Content -LiteralPath $TexPath -Raw -Encoding UTF8

  if ($txt -match [regex]::Escape($InputLine)) {
    Write-Host "Already present in: $TexPath" -ForegroundColor DarkGray
    return
  }

  if ($txt -notmatch "\\end\{document\}") {
    Write-Host "No \\end{document} found in: $TexPath (skipping insert)" -ForegroundColor Yellow
    return
  }

  $new = $txt -replace "\\end\{document\}", ($InputLine + "`r`n`r`n\end{document}")
  Set-Content -LiteralPath $TexPath -Value $new -Encoding UTF8
  Write-Host "Inserted into: $TexPath" -ForegroundColor Cyan
  Write-Host "  + $InputLine" -ForegroundColor Cyan
}

Ensure-Dir $Secs

# ------------------------------------------------------------
# 09_null_hypotheses.tex
# ------------------------------------------------------------
$sec09 = @'
\section{Null hypotheses, comparison ensembles, and preregistered tests}
\label{sec:null_hypotheses}

This section states the falsification protocol in a form suitable for referee evaluation. The purpose is to distinguish a genuine discrete organizing structure from artifacts of coordinate choice, anchoring, or scan flexibility.

\subsection{Objects under test}
We consider two audited outputs:
\begin{enumerate}
\item \textbf{Mass alignment:} the existence of small logarithmic residuals $\epsilon$ between experimental masses $m_{\mathrm{exp}}$ and the discrete set $m_{\mathrm{lat}}(a,b,c)$ defined by Eq.~\eqref{eq:mass_law}, under declared scan bounds and an anchored convention.
\item \textbf{Mixing/CP alignment:} the deterministic mapping from fixed inputs $(s_{12},s_{23},s_{13})$ and a predicted holonomy angle $\theta_{\star}$ to a best-fit phase $\delta$ and invariant $J$ (CKM and PMNS), as implemented in \texttt{code/verify\_mixing.py} and emitted to \texttt{shared/paperV\_mixing\_results.tex}.
\end{enumerate}

\subsection{Primary null hypotheses}
We formalize the following nulls.

\paragraph{H0(M): Mass-coincidence null.}
The observed small residuals are consistent with chance alignment between experimental log-masses and a discretized log-lattice induced by a chosen base and scan domain. Under H0(M), the distribution of best-fit residuals and multiplicities (deduplicated by $q$) is not significantly different from an appropriate comparison ensemble.

\paragraph{H0(A): Anchoring/coordinate artifact null.}
Apparent structure is induced primarily by the anchoring choice and the logarithm base. Under H0(A), reasonable changes of anchor, base (within a declared family), or bounded scan expansion materially alter which particles appear ``unique($q$)'' or well-aligned.

\paragraph{H0(CP): Phase-matching flexibility null.}
The CKM/PMNS phase match is not predictive: for a broad range of plausible $\theta_{\star}$ inputs or matching rules, one can obtain a near-zero score on a coarse scan grid. Under H0(CP), the match does not survive preregistered constraints on inputs, grid resolution, and scoring metric.

\subsection{Comparison ensembles (referee-facing)}
A claim of nontrivial structure requires a clearly specified ensemble. We adopt two complementary ensembles.

\paragraph{E1: Local jitter ensemble (conservative).}
For each audited particle mass $m_{\mathrm{exp}}$, define a perturbed mass
\begin{equation}
m' = m_{\mathrm{exp}}\exp(\eta),
\end{equation}
where $\eta$ is drawn from a zero-mean distribution with a scale matched to the appropriate experimental/definition uncertainty class (e.g.\ pole mass vs running mass vs quark mass definition). Run the identical lattice scan on $\{m'\}$ and compare the distribution of minimum $|\epsilon|$ and unique($q$) counts.

\paragraph{E2: Order-statistics ensemble (agnostic).}
Construct synthetic spectra with the same cardinality and rough scale range as the audited set but with randomized log-gaps (e.g.\ by sampling sorted i.i.d.\ log-masses within the same range). This tests whether the lattice is so dense that it will typically approximate \emph{any} spectrum.

Both ensembles must preserve the declared scan bounds, anchoring convention, and multiplicity deduplication by $q$; otherwise, the comparison is invalid.

\subsection{Pre-registration rules}
To prevent post hoc optimization, the following must be declared \emph{before} evaluating updates or extensions:
\begin{enumerate}
\item \textbf{Audit set:} the exact list of particles/scales included.
\item \textbf{Mass inputs:} scheme (pole/running), scale, and reference values.
\item \textbf{Anchor:} the anchor triple $(a_e,b_e,c_e)$ and how anchor changes are handled.
\item \textbf{Bounds:} the scan region for $(a,b,c)$, including any symmetry-based restrictions.
\item \textbf{Tolerance:} the acceptance threshold $\epsilon_{\max}$.
\item \textbf{Multiplicity rule:} reporting of raw multiplicity and deduplicated-by-$q$ multiplicity.
\item \textbf{Success metrics:} a scalar summary statistic (e.g.\ median $|\epsilon|$, number of unique($q$) matches, or a likelihood ratio) and the threshold for rejecting H0.
\end{enumerate}

\subsection{Decision criteria}
We recommend the following minimal ``make-or-break'' criteria:
\begin{enumerate}
\item \textbf{Mass lattice:} compared to E1 and E2, the real spectrum exhibits (i) significantly smaller typical $|\epsilon|$ and (ii) significantly higher unique($q$) counts under fixed bounds and $\epsilon_{\max}$.
\item \textbf{Stability:} unique($q$) assignments remain stable under moderate bound expansion and under declared alternative anchoring conventions.
\item \textbf{CP sector:} a preregistered leptonic holonomy prediction $\theta_{\star}^{\mathrm{PMNS}}$ yields a definite $\delta_{\mathrm{PMNS}}$ and $J_{\mathrm{PMNS}}$ that remains consistent as global-fit inputs update; failure modes must be reported symmetrically.
\end{enumerate}

\subsection{Immediate and longer-horizon predictions}
The program’s predictions are stratified:
\begin{itemize}
\item \textbf{Immediate (audit-level):} stability under updated PDG/global-fit inputs; reproducible regeneration of all tables/figures from scripts; preregistered ensemble tests rejecting H0 at a declared level.
\item \textbf{Intermediate (phenomenology):} constrained predictions for currently uncertain quantities (e.g.\ $\delta_{\mathrm{PMNS}}$) under fixed holonomy input rules; robustness under running-mass substitutions.
\item \textbf{Long-horizon (model-level):} any new state predictions must specify couplings/signatures and not only masses; otherwise they remain numerology.
\end{itemize}
'@

Write-UTF8 (Join-Path $Secs "09_null_hypotheses.tex") $sec09

# Insert into MASTER.tex and CORE_MASTER.tex
$line = "\input{sections/09_null_hypotheses.tex}"

Insert-InputBeforeEndDoc -TexPath (Join-Path $Papers "MASTER.tex")     -InputLine $line
Insert-InputBeforeEndDoc -TexPath (Join-Path $Papers "CORE_MASTER.tex") -InputLine $line

# Build
Push-Location $Papers

if (Test-Path -LiteralPath ".\MASTER.tex") {
  Write-Host "`nCompiling MASTER.tex..." -ForegroundColor Cyan
  pdflatex -interaction=nonstopmode MASTER.tex | Out-Null
  Write-Host "Build OK: papers\MASTER.pdf" -ForegroundColor Cyan
  Write-Host "Log:     papers\MASTER.log" -ForegroundColor DarkGray
}

if (Test-Path -LiteralPath ".\CORE_MASTER.tex") {
  Write-Host "`nCompiling CORE_MASTER.tex..." -ForegroundColor Cyan
  pdflatex -interaction=nonstopmode CORE_MASTER.tex | Out-Null
  Write-Host "Build OK: papers\CORE_MASTER.pdf" -ForegroundColor Cyan
  Write-Host "Log:     papers\CORE_MASTER.log" -ForegroundColor DarkGray
}

Pop-Location
Write-Host "`nDone." -ForegroundColor Green
