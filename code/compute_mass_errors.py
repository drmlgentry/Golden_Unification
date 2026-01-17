import math
from dataclasses import dataclass
from typing import Dict, List, Tuple

PHI = (1.0 + math.sqrt(5.0)) / 2.0

@dataclass(frozen=True)
class Particle:
    name: str
    m_exp_gev: float

def q(a: int, b: int, c: int) -> int:
    return 8*a + 15*b + 24*c

def m_pred(m0_gev: float, a: int, b: int, c: int) -> float:
    return m0_gev * (PHI ** (q(a,b,c)/4.0))

def frac_err(m_pred_gev: float, m_exp_gev: float) -> float:
    return (m_pred_gev - m_exp_gev) / m_exp_gev

# Minimal reference set (expand as you like)
# NOTE: Replace these masses with your canonical dataset values if different.
PARTICLES: List[Particle] = [
    Particle("electron", 0.00051099895),
    Particle("muon",     0.1056583755),
    Particle("tau",      1.77686),
    Particle("W",        80.379),
    Particle("Z",        91.1876),
    Particle("top",      172.76),
]

# Search bounds (explicit, auditable)
A_MIN, A_MAX = -60, 0
B_MIN, B_MAX = -20, 20
C_MIN, C_MAX = -20, 40

# Tolerance for "acceptable fit"
TAU_FRAC = 1e-3  # 0.1% default; adjust and re-run

def best_and_solutions(p: Particle, m0_gev: float) -> Tuple[Tuple[int,int,int,float,float], List[Tuple[int,int,int,float]]]:
    best = None
    sols: List[Tuple[int,int,int,float]] = []
    for a in range(A_MIN, A_MAX+1):
        for b in range(B_MIN, B_MAX+1):
            for c in range(C_MIN, C_MAX+1):
                mp = m_pred(m0_gev, a,b,c)
                e = frac_err(mp, p.m_exp_gev)
                ae = abs(e)
                if best is None or ae < best[3]:
                    best = (a,b,c,ae,mp)
                if ae <= TAU_FRAC:
                    sols.append((a,b,c,e))
    assert best is not None
    return best, sols

def main():
    # Use electron as base scale m0
    m0 = next(pp.m_exp_gev for pp in PARTICLES if pp.name == "electron")

    # Produce LaTeX rows for the errors table (best fit per particle)
    print("% --- AUTO TABLE: errors (best fit per particle) ---")
    for p in PARTICLES:
        best, sols = best_and_solutions(p, m0)
        a,b,c,abs_e,mp = best
        e = frac_err(mp, p.m_exp_gev)
        print(f"{p.name} & {p.m_exp_gev:.9g} & {mp:.9g} & {a} & {b} & {c} & {e:+.3e} \\\\")

    print("\n% --- AUTO MULTIPLICITY: counts within tolerance ---")
    print(f"% Bounds: a[{A_MIN},{A_MAX}], b[{B_MIN},{B_MAX}], c[{C_MIN},{C_MAX}] ; tolerance |epsilon| <= {TAU_FRAC}")
    for p in PARTICLES:
        best, sols = best_and_solutions(p, m0)
        a,b,c,abs_e,mp = best
        notes = "unique" if len(sols) == 1 else "multiple"
        print(f"{p.name} & {len(sols)} & {abs_e:.3e} & {notes} \\\\")

if __name__ == "__main__":
    main()
