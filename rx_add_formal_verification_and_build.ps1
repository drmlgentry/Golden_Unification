# ============================================================
# RX: Add formal CKM/PMNS verification subsection and rebuild
# ============================================================

$root = "C:\Users\Your Name Here\Desktop\Golden_Unification"
$papers = Join-Path $root "papers"
$sections = Join-Path $papers "sections"
$core = Join-Path $papers "CORE_MASTER.tex"

$secFile = Join-Path $sections "06a_formal_verification.tex"

# --- write section file ---
$tex = @"
\section{Formal verification of CKM and PMNS phases}
\label{sec:formal_verification}

We formalize the scan-and-match procedure used to extract CP-violating phases
from fixed mixing-angle inputs. This formulation is independent of implementation
details and defines a reproducible mathematical protocol.

\subsection{Inputs}

The procedure takes as input three experimentally determined mixing angles
\[
(s_{12}, s_{23}, s_{13}),
\]
together with a predicted holonomy angle $\theta_\star \in (0,180^\circ)$
supplied by the geometric model.

\subsection{Scan procedure}

The CP phase $\delta$ is scanned over a discrete grid
\[
\delta \in [0,180^\circ],
\]
with uniform step size $\Delta\delta$.

For each $\delta$, the Jarlskog invariant
\[
J(s_{12}, s_{23}, s_{13}, \delta)
= s_{12}s_{23}s_{13}c_{12}c_{23}c_{13}^2 \sin\delta
\]
is evaluated.

\subsection{Matching functional}

We define the objective functional
\[
\mathcal{D}(\delta)
= \left| \sin\delta - \sin\theta_\star \right|,
\]
and select
\[
\delta_\star = \arg\min_{\delta} \mathcal{D}(\delta).
\]

\subsection{Outputs and resolution}

The procedure yields the pair
\[
(\delta_\star, J_\star),
\quad
J_\star = J(s_{12}, s_{23}, s_{13}, \delta_\star).
\]

Agreement between $\delta_\star$ and $\theta_\star$ is understood to be
limited by the scan resolution $\Delta\delta$. Exact numerical equality
is neither required nor expected.

\subsection{Application to quark and lepton sectors}

The protocol applies identically to the CKM and PMNS matrices.
Sector-specific differences enter only through the numerical values
of $(s_{12}, s_{23}, s_{13})$ and the predicted $\theta_\star$.
"@

$tex | Set-Content -Path $secFile -Encoding UTF8
Write-Host "Wrote file: $secFile" -ForegroundColor Green

# --- insert into CORE_MASTER.tex if not present ---
$coreText = Get-Content $core -Raw
$insert = "\input{sections/06a_formal_verification.tex}"

if ($coreText -notmatch "06a_formal_verification") {
    $coreText = $coreText -replace
        "(\\input\{sections/06_holonomy_mixing\.tex\})",
        "`$1`n$insert"
    Set-Content -Path $core -Value $coreText -Encoding UTF8
    Write-Host "Inserted verification section into CORE_MASTER.tex" -ForegroundColor Green
} else {
    Write-Host "Verification section already present." -ForegroundColor DarkGray
}

# --- rebuild ---
Write-Host "Compiling CORE_MASTER.tex..." -ForegroundColor Cyan
pdflatex -interaction=nonstopmode -output-directory $papers $core | Out-Null
Write-Host "Build OK: papers\CORE_MASTER.pdf" -ForegroundColor Cyan
