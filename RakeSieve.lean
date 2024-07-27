-- RakeSieve uses a rake to implement a prime sieve.
import Rake
import PrimeSieve

structure RakeSieve where
  prop : Nat -> Prop
  rm: RakeMap prop
  p : NPrime               -- the current prime
  c : Nat                  -- the candidate for next prime
  hprop : ∀ n:Nat, prop n ↔ n ∈ R p
  hCinR : c ∈ R p
  hRmin : ∀ r ∈ R p, c ≤ r
  -- Q : Array RakeMap     -- queue of found primes

def RakeSieve.sort (r: RakeSieve) : {r': RakeSieve // r'.rm.rake.sorted } :=
  let ⟨rm', hs⟩ := r.rm.rake.sort
  ⟨{ prop := r.prop, rm := rm', p:=r.p, c:=r.c,
     hprop:=r.hprop, hCinR := r.hCinR, hRmin := r.hRmin  }, rfl⟩

def RakeSieve.init : RakeSieve :=
  let rm := rm_ge2 |>.rem 2
  let p := ⟨2, Nat.prime_two⟩
  { prop := rm.pred, rm := rm, p := p, c := 3,
    hprop := by
      have hrm : rm.pred = λn => n ≥ 2 ∧ ¬ 2∣n := by simp[RakeMap.pred]
      show ∀ n, rm.pred n ↔ n ∈ R p
      have hbij := rm.hbij
      unfold R; simp_all; intro n
      apply Iff.intro
      case mp =>
        intro hn
        apply And.intro
        · rw[← hbij] at hn; exact hn.left
        · intro q hq hq'
          simp[←hbij] at hn
          have := Nat.Prime.two_le hq'
          have : 2=q := by omega
          rw[this] at hn
          omega
      case mpr =>
        simp; intro hn hn2; rw[←hbij]; simp_all
        have hp2: p.val = 2 := by rfl
        have hn2' := hn2
        set p' := p.val
        specialize hn2' p';  simp[hp2] at hn2'
        exact hn2' Nat.prime_two
    hCinR := by
      -- clearly 3 isn't divisible by 2, so is in r
      unfold R; simp; intro q _ hq'
      have : q = 2 := by rw[Nat.prime_def_lt] at hq'; omega
      aesop
    hRmin := by
      -- to show that every number in R 2 is ≥ 3,
      -- show that an r∈R 2 where r<3 leads to a contradiction.
      dsimp[R]; intro r ⟨hr, hrr⟩; by_contra h; simp_all
      -- r ≥ 2 and r < 3, so r must be 2
      have r2 : r = 2 := by omega
      -- but R 2 means not divisible by primes ≤ 2
      -- now we can use hrr to prove ¬2∣2, which is absurd
      have := Nat.prime_two; aesop }

def RakeSieve.next (x : RakeSieve) (hC₀: Nat.Prime x.c) (hNS: nosk' x.p x.c): RakeSieve :=
  let h₀ := x.prop
  have hh₀ : ∀n, h₀ n ↔ n ∈ R x.p := x.hprop
  have hCR₀ := x.hCinR
  have hpgt:PrimeGt x.p x.c := by
    constructor
    · exact hC₀
    · exact r_gt_p (↑x.p) x.c hCR₀
  have hmin: ∀ q < x.c, ¬PrimeGt (↑x.p) q := by
    simp_all; intro q hq hq'; apply hNS at hq'; omega
  let m : MinPrimeGt x.p := { p:=x.c, hpgt:=hpgt, hmin:=hmin}
  let ⟨rm, hs⟩ := x.rm.rem m.p |>.sort
  let c₁ := rm.rake.term 0
  have hc₁: ∃ i, rm.rake.term i = c₁ := by
    exact exists_apply_eq_apply (fun a => rm.rake.term a) 0
  let h₁ := rm.pred
  have hh₁ : ∀n, h₁ n ↔ h₀ n ∧ ¬(m.p∣n) := by simp[h₁, RakeMap.pred]
  have hprop : ∀n, h₁ n ↔ n ∈ R m.p := by
    intro n; exact r_next_prop (hh₀ n) (hh₁ n)
  { prop := rm.pred, rm := rm, p := ⟨m.p, hC₀⟩, c := c₁,
    hprop := hprop
    hCinR := by
      show c₁ ∈ R m.p
      · have : h₁ c₁ := by rw[← rm.hbij] at hc₁; exact hc₁
        specialize hprop c₁
        exact hprop.mp this
    hRmin := by
      dsimp[c₁,p,h₁] at *
      intro r hr
      have : ∃k, rm.rake.term k = r := by
        have : x.c = m.p := by rfl
        conv at hr => rw[←(hprop r), hh₁]; dsimp[h₀]; rw[‹x.c=m.p›, rm.hbij r]
        exact hr
      obtain ⟨k, hk⟩ := this
      rw[←hk]
      exact Rake.sorted_min_term_zero rm.rake (rm.rake.hsort hs) k}

open RakeSieve

instance : PrimeSieveState RakeSieve where
  P x := x.p
  C x := x.c
  next := .next
  hNext := by
    intro s hC hNS s' hs'; simp_all; rw[←hs']
    unfold next at hs'; simp at hs'
    have hpc: s'.p = s.c := by simp_all
    apply And.intro
    · exact hpc
    · show s'.c > s.c
      have := s'.hCinR
      have := r_gt_p
      aesop

open PrimeSieveState

instance : PrimeSieveDriver RakeSieve where
  hCinR x := by dsimp[C]; dsimp[P]; exact x.hCinR
  hRmin x := by dsimp[C]; dsimp[P]; exact x.hRmin
