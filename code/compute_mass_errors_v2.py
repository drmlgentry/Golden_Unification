import math
from dataclasses import dataclass
from typing import Dict, List, Tuple, Optional

PHI = (1.0 + math.sqrt(5.0)) / 2.0

@dataclass(frozen=True)
class Particle:
    name: str
    m_exp_gev: float

def q(a: int, b: int, c: int) -> int:
    return 8*a + 15*b + 24*c

def m_pred_relative(m_e_gev: float,
                    a: int, b: int, c: int,
                    a_e: int, b_e: int, c_e: int) -> float:
    """Anchored model: m = m_e * PHI^((q - q_e)/4)."""
    dq = q(a,b,c) - q(a_e,b_e,c_e)
    return m_e_gev * (PHI ** (dq / 4.0))

def frac_err(m_pred_gev: float, m_exp_gev: float) -> float:
    return (m_pred_gev - m_exp_gev) / m_exp_gev

def l1_norm(a: int, b: int, c: int) -> int:
    return abs(a) + abs(b) + abs(c)

def canonical_rep_for_q(target_q: int,
                        search_box: Tuple[range, range, range]) -> Optional[Tuple[int,int,int]]:
    """
    Choose one canonical representative for a given q value
    by minimizing L1 norm, then lexicographic tie-break.
    """
    ar, br, cr = search_box
    best = None
    best_key = None
    for a in ar:
        for b in br:
            for c in cr:
                if q(a,b,c) == target_q:
                    key = (l1_norm(a,b,c), a, b, c)
                    if best is None or key < best_key:
                        best = (a,b,c)
                        best_key = key
    return best

# Reference set (replace masses if you have a canonical dataset file later)
PARTICLES: List[Particle] = [
    Particle("electron", 0.00051099895),
    Particle("muon",     0.1056583755),
    Particle("tau",      1.77686),
    Particle("W",        80.379),
    Particle("Z",        91.1876),
    Particle("top",      172.76),
]

# Scan bounds
A_MIN, A_MAX = -80, 20
B_MIN, B_MAX = -40, 40
C_MIN, C_MAX = -40, 60

# Tolerance for “solutions”
TAU_FRAC = 0.05  # 0.1%
# For diagnostic runs, you can temporarily try 0.02 or 0.05.

def scan_best_and_solutions(p: Particle,
                            m_e_gev: float,
                            anchor: Tuple[int,int,int]) -> Tuple[Tuple[int,int,int,float,float], List[Tuple[int,int,int,float]]]:
    a_e,b_e,c_e = anchor
    best = None
    sols: List[Tuple[int,int,int,float]] = []

    for a in range(A_MIN, A_MAX+1):
        for b in range(B_MIN, B_MAX+1):
            for c in range(C_MIN, C_MAX+1):
                mp = m_pred_relative(m_e_gev, a,b,c, a_e,b_e,c_e)
                e = frac_err(mp, p.m_exp_gev)
                ae = abs(e)
                if best is None or ae < best[3]:
                    best = (a,b,c,ae,mp)
                if ae <= TAU_FRAC:
                    sols.append((a,b,c,e))

    assert best is not None
    return best, sols

def main():
    # Electron mass defines the base scale
    m_e = next(pp.m_exp_gev for pp in PARTICLES if pp.name == "electron")

    # Anchor choice:
    # Option 1 (recommended immediately): use the best-fit electron found previously
    #            (-60, -16, 30) from your output.
    # Option 2: replace with YOUR canonical electron triple once you decide it.
    anchor = (-60, -16, 30)

    q_e = q(*anchor)

    print("% --- AUTO TABLE: errors (anchored model; best fit per particle) ---")
    print(f"% Anchor (a_e,b_e,c_e) = {anchor} ; q_e = {q_e}")
    for p in PARTICLES:
        best, sols = scan_best_and_solutions(p, m_e, anchor)
        a,b,c,abs_e,mp = best
        e = frac_err(mp, p.m_exp_gev)
        print(f"{p.name} & {p.m_exp_gev:.9g} & {mp:.9g} & {a} & {b} & {c} & {e:+.3e} \\\\")

    # Multiplicity, but de-duplicated by q (equivalence classes)
    print("\n% --- AUTO MULTIPLICITY: counts within tolerance (dedup by q) ---")
    print(f"% Bounds: a[{A_MIN},{A_MAX}], b[{B_MIN},{B_MAX}], c[{C_MIN},{C_MAX}] ; tolerance |epsilon| <= {TAU_FRAC}")
    for p in PARTICLES:
        best, sols = scan_best_and_solutions(p, m_e, anchor)

        # Deduplicate solutions by q-value (equivalence under kernel of q)
        q_map: Dict[int, Tuple[int,int,int,float]] = {}
        for a,b,c,e in sols:
            qq = q(a,b,c)
            # keep one representative per q, prefer smallest |e|
            if qq not in q_map or abs(e) < abs(q_map[qq][3]):
                q_map[qq] = (a,b,c,e)

        # Canonicalize each q-class (optional but better)
        search_box = (range(A_MIN, A_MAX+1), range(B_MIN, B_MAX+1), range(C_MIN, C_MAX+1))
        canonical_classes = []
        for qq, (a,b,c,e) in q_map.items():
            rep = canonical_rep_for_q(qq, search_box)
            if rep is None:
                rep = (a,b,c)
            canonical_classes.append((qq, rep[0], rep[1], rep[2], e))

        canonical_classes.sort(key=lambda x: abs(x[4]))
        n_classes = len(canonical_classes)

        notes = "unique(q)" if n_classes == 1 else "multiple(q)"
        # best abs error from the scan (even if no solutions)
        a_best,b_best,c_best,abs_e_best,mp_best = best
        print(f"{p.name} & {n_classes} & {abs_e_best:.3e} & {notes} \\\\")

if __name__ == "__main__":
    main()
