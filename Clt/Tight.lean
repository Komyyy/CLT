/-
Copyright (c) 2025 Rémy Degenne. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Rémy Degenne
-/
import Clt.CharFun

/-!
# Tightness and characteristic functions

-/

open MeasureTheory ProbabilityTheory Filter
open scoped ENNReal NNReal Topology RealInnerProductSpace

lemma tendsto_iSup_of_tendsto_limsup {u : ℕ → ℝ → ℝ≥0∞}
    (h_all : ∀ n, Tendsto (u n) atTop (𝓝 0))
    (h_tendsto : Tendsto (fun r : ℝ ↦ limsup (fun n ↦ u n r) atTop) atTop (𝓝 0))
    (h_anti : ∀ n, Antitone (u n)) :
    Tendsto (fun r : ℝ ↦ ⨆ n, u n r) atTop (𝓝 0) := by
  simp_rw [ENNReal.tendsto_atTop_zero] at h_tendsto h_all ⊢
  intro ε hε
  by_cases hε_top : ε = ∞
  · refine ⟨0, fun _ _ ↦ by simp [hε_top]⟩
  simp only [gt_iff_lt, ge_iff_le] at h_tendsto h_all hε
  obtain ⟨r, h⟩ := h_tendsto (ε / 2) (ENNReal.half_pos hε.ne')
  have h' x (hx : r ≤ x) y (hy : ε / 2 < y) : ∀ᶠ n in atTop, u n x < y := by
    specialize h x hx
    rw [limsup_le_iff] at h
    exact h y hy
  replace h' : ∀ x, r ≤ x → ∀ᶠ n in atTop, u n x < ε :=
    fun x hx ↦ h' x hx ε (ENNReal.half_lt_self hε.ne' hε_top)
  simp only [eventually_atTop, ge_iff_le] at h'
  obtain ⟨N, h⟩ := h' r le_rfl
  replace h_all : ∀ ε > 0, ∀ n, ∃ N, ∀ n_1 ≥ N, u n n_1 ≤ ε := fun ε hε n ↦ h_all n ε hε
  choose rs hrs using h_all ε hε
  refine ⟨r ⊔ ⨆ n : Finset.range N, rs n, fun v hv ↦ ?_⟩
  simp only [Set.mem_setOf_eq, iSup_exists, iSup_le_iff, forall_apply_eq_imp_iff]
  intro n
  by_cases hn : n < N
  · refine hrs n v ?_
    calc rs n
    _ = rs (⟨n, by simp [hn]⟩ : Finset.range N) := rfl
    _ ≤ ⨆ n : Finset.range N, rs n := by
      refine le_ciSup (f := fun (x : Finset.range N) ↦ rs x) ?_ (⟨n, by simp [hn]⟩ : Finset.range N)
      exact Finite.bddAbove_range _
    _ ≤ r ⊔ ⨆ n : Finset.range N, rs n := le_max_right _ _
    _ ≤ v := hv
  · have hn_le : N ≤ n := not_lt.mp hn
    specialize h n hn_le
    refine (h_anti n ?_).trans h.le
    calc r
    _ ≤ r ⊔ ⨆ n : Finset.range N, rs n := le_max_left _ _
    _ ≤ v := hv

variable {E : Type*} {mE : MeasurableSpace E} [NormedAddCommGroup E]

section FiniteDimensional

lemma isTightMeasureSet_of_tendsto_limsup_measure_norm_gt [BorelSpace E]
    [NormedSpace ℝ E] [FiniteDimensional ℝ E] {μ : ℕ → Measure E} [∀ i, IsFiniteMeasure (μ i)]
    (h : Tendsto (fun r : ℝ ↦ limsup (fun n ↦ μ n {x | r < ‖x‖}) atTop) atTop (𝓝 0)) :
    IsTightMeasureSet {μ n | n} := by
  refine isTightMeasureSet_of_tendsto_measure_norm_gt ?_
  convert tendsto_iSup_of_tendsto_limsup (fun n ↦ ?_) h fun n u v huv ↦ ?_ with y
  · change ⨆ μ' ∈ Set.range μ, _ = _
    rw [iSup_range]
  · have h_tight : IsTightMeasureSet {μ n} :=
      isTightMeasureSet_singleton_of_innerRegularWRT
        (innerRegular_isCompact_isClosed_measurableSet_of_finite (μ n))
    rw [isTightMeasureSet_iff_tendsto_measure_norm_gt] at h_tight
    simpa using h_tight
  · refine measure_mono fun x hx ↦ ?_
    simp only [Set.mem_setOf_eq] at hx ⊢
    exact huv.trans_lt hx

lemma isTightMeasureSet_iff_tendsto_limsup_measure_norm_gt [BorelSpace E]
    [NormedSpace ℝ E] [FiniteDimensional ℝ E] {μ : ℕ → Measure E} [∀ i, IsFiniteMeasure (μ i)] :
    IsTightMeasureSet {μ n | n}
      ↔ Tendsto (fun r : ℝ ↦ limsup (fun n ↦ μ n {x | r < ‖x‖}) atTop) atTop (𝓝 0) := by
  refine ⟨fun h ↦ ?_, isTightMeasureSet_of_tendsto_limsup_measure_norm_gt⟩
  have h_sup := tendsto_measure_norm_gt_of_isTightMeasureSet h
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds h_sup (fun _ ↦ zero_le') ?_
  intro r
  have : {μ n | n} = Set.range μ := rfl
  simp_rw [this, iSup_range]
  exact limsup_le_iSup

variable {ι : Type*} [Fintype ι]

lemma isTightMeasureSet_of_tendsto_limsup_inner [BorelSpace E]
    [InnerProductSpace ℝ E] [FiniteDimensional ℝ E] {μ : ℕ → Measure E} [∀ i, IsFiniteMeasure (μ i)]
    (h : ∀ z, Tendsto (fun r : ℝ ↦ limsup (fun n ↦ μ n {x | r < |⟪z, x⟫|}) atTop) atTop (𝓝 0)) :
    IsTightMeasureSet {μ n | n} := by
  refine isTightMeasureSet_of_inner_tendsto (𝕜 := ℝ) fun z ↦ ?_
  convert tendsto_iSup_of_tendsto_limsup (fun n ↦ ?_) (h z) fun n u v huv ↦ ?_ with y
  · apply le_antisymm
    · simp only [Set.mem_setOf_eq, iSup_exists, iSup_le_iff, forall_apply_eq_imp_iff]
      exact fun n ↦ le_iSup (fun j ↦ μ j {x | y < |⟪z, x⟫|}) n
    · simp only [Set.mem_setOf_eq, iSup_exists, iSup_le_iff]
      intro n
      calc μ n {x | y < |⟪z, x⟫|}
      _ ≤ ⨆ j, ⨆ (_ : μ j = μ n), μ j {x | y < |⟪z, x⟫|} :=
          le_biSup (fun j ↦ μ j {x | y < |⟪z, x⟫|}) rfl
      _ = ⨆ j, ⨆ (_ : μ j = μ n), μ n {x | y < |⟪z, x⟫|} := by
        convert rfl using 4 with m hm
        rw [hm]
      _ ≤ ⨆ μ', ⨆ j, ⨆ (_ : μ j = μ'), μ' {x | y < |⟪z, x⟫|} :=
        le_iSup (fun μ' ↦ ⨆ j, ⨆ (_ : μ j = μ'), μ' {x | y < |⟪z, x⟫|}) (μ n)
  · have h_tight : IsTightMeasureSet {(μ n).map (fun x ↦ ⟪z, x⟫)} :=
      isTightMeasureSet_singleton
    rw [isTightMeasureSet_iff_tendsto_measure_norm_gt] at h_tight
    have h_map r : (μ n).map (fun x ↦ ⟪z, x⟫) {x | r < |x|}
        = μ n {x | r < |⟪z, x⟫|} := by
      rw [Measure.map_apply (by fun_prop)]
      · simp
      · exact MeasurableSet.preimage measurableSet_Ioi (by fun_prop)
    simpa [h_map] using h_tight
  · exact measure_mono fun x hx ↦ huv.trans_lt hx

lemma isTightMeasureSet_iff_tendsto_limsup_inner [BorelSpace E]
    [InnerProductSpace ℝ E] [FiniteDimensional ℝ E]
    {μ : ℕ → Measure E} [∀ i, IsFiniteMeasure (μ i)] :
    IsTightMeasureSet {μ n | n}
      ↔ ∀ z, Tendsto (fun r : ℝ ↦ limsup (fun n ↦ μ n {x | r < |⟪z, x⟫|}) atTop) atTop (𝓝 0) := by
  refine ⟨fun h z ↦ ?_, isTightMeasureSet_of_tendsto_limsup_inner⟩
  rw [isTightMeasureSet_iff_inner_tendsto ℝ] at h
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds (h z)
    (fun _ ↦ zero_le') fun r ↦ ?_
  have : {μ n | n} = Set.range μ := rfl
  simp_rw [this, iSup_range]
  exact limsup_le_iSup

lemma isTightMeasureSet_of_tendsto_limsup_inner_of_norm_eq_one [BorelSpace E]
    [InnerProductSpace ℝ E] [FiniteDimensional ℝ E] {μ : ℕ → Measure E} [∀ i, IsFiniteMeasure (μ i)]
    (h : ∀ z, ‖z‖ = 1
      → Tendsto (fun r : ℝ ↦ limsup (fun n ↦ μ n {x | r < |⟪z, x⟫|}) atTop) atTop (𝓝 0)) :
    IsTightMeasureSet {μ n | n} := by
  have : ProperSpace E := FiniteDimensional.proper ℝ E
  refine isTightMeasureSet_of_tendsto_limsup_inner fun y ↦ ?_
  by_cases hy : y = 0
  · simp only [hy, inner_zero_left, abs_zero]
    refine (tendsto_congr' ?_).mpr tendsto_const_nhds
    filter_upwards [eventually_ge_atTop 0] with r hr
    simp [not_lt.mpr hr]
  have h' : Tendsto (fun r : ℝ ↦ limsup (fun n ↦ μ n {x | ‖y‖⁻¹ * r < |⟪‖y‖⁻¹ • y, x⟫|}) atTop)
      atTop (𝓝 0) := by
    specialize h (‖y‖⁻¹ • y) ?_
    · simp only [norm_smul, norm_inv, norm_norm]
      rw [inv_mul_cancel₀ (by positivity)]
    exact h.comp <| (tendsto_const_mul_atTop_of_pos (by positivity)).mpr tendsto_id
  convert h' using 7 with r n x
  rw [inner_smul_left]
  simp only [map_inv₀, conj_trivial, abs_mul, abs_inv, abs_norm]
  rw [mul_lt_mul_left]
  positivity

/-- Let $(\mu_n)_{n \in \mathbb{N}}$ be measures on $\mathbb{R}^d$ with characteristic functions
$(\hat{\mu}_n)$. If $\hat{\mu}_n$ converges pointwise to a function $f$ which is continuous at 0,
then $(\mu_n)$ is tight. -/
lemma isTightMeasureSet_of_tendsto_charFun [InnerProductSpace ℝ E] [FiniteDimensional ℝ E]
    [BorelSpace E]
    {μ : ℕ → Measure E} [∀ i, IsProbabilityMeasure (μ i)]
    {f : E → ℂ} (hf : ContinuousAt f 0) (hf_meas : Measurable f)
    (h : ∀ t, Tendsto (fun n ↦ charFun (μ n) t) atTop (𝓝 (f t))) :
    IsTightMeasureSet {μ i | i} := by
  refine isTightMeasureSet_of_tendsto_limsup_inner_of_norm_eq_one fun z hz ↦ ?_
  have h_le n r := measure_abs_inner_ge_le_charFun (μ := μ n) (a := z) (r := r)
  suffices Tendsto (fun (r : ℝ) ↦
        limsup (fun n ↦ (μ n {x | r < |⟪z, x⟫|}).toReal) atTop)
      atTop (𝓝 0) by
    have h_ofReal r : limsup (fun n ↦ μ n {x | r < |⟪z, x⟫|}) atTop
        = ENNReal.ofReal
          (limsup (fun n ↦ (μ n {x | r < |⟪z, x⟫|}).toReal) atTop) := by
      rw [ENNReal.limsup_toReal_eq (b := 1)]
      · rw [ENNReal.ofReal_toReal]
        refine ne_of_lt ?_
        calc limsup (fun n ↦ (μ n) {x | r < |⟪z, x⟫|}) atTop
        _ ≤ 1 := by
          refine limsup_le_of_le ?_ ?_
          · exact IsCoboundedUnder.of_frequently_ge <| .of_forall fun _ ↦ zero_le'
          · exact .of_forall fun _ ↦ prob_le_one
        _ < ⊤ := by simp
      · simp
      · exact .of_forall fun _ ↦ prob_le_one
    simp_rw [h_ofReal]
    rw [← ENNReal.ofReal_zero]
    exact ENNReal.tendsto_ofReal this
  have h_le_4 n r (hr : 0 < r) :
      2⁻¹ * r * ‖∫ t in -2 * r⁻¹..2 * r⁻¹,
        1 - charFun (μ n) (t • z)‖ ≤ 4 := by
    have hr' : -(2 * r⁻¹) ≤ 2 * r⁻¹ := by rw [neg_le_self_iff]; positivity
    calc 2⁻¹ * r * ‖∫ t in -2 * r⁻¹..2 * r⁻¹, 1 - charFun (μ n) (t • z)‖
    _ ≤ 2⁻¹ * r
        * ∫ t in -(2 * r⁻¹)..2 * r⁻¹, ‖1 - charFun (μ n) (t • z)‖ := by
      simp only [neg_mul, intervalIntegrable_const]
      gcongr
      rw [intervalIntegral.integral_of_le hr', intervalIntegral.integral_of_le hr']
      exact norm_integral_le_integral_norm _
    _ ≤ 2⁻¹ * r * ∫ t in -(2 * r⁻¹)..2 * r⁻¹, 2 := by
      gcongr
      rw [intervalIntegral.integral_of_le hr', intervalIntegral.integral_of_le hr']
      refine integral_mono_of_nonneg ?_ (by fun_prop) ?_
      · exact ae_of_all _ fun _ ↦ by positivity
      · refine ae_of_all _ fun x ↦ norm_one_sub_charFun_le_two
    _ ≤ 4 := by
      simp only [neg_mul, intervalIntegral.integral_const, sub_neg_eq_add, smul_eq_mul]
      ring_nf
      rw [mul_inv_cancel₀ hr.ne', one_mul]
  -- We introduce an upper bound for the limsup.
  -- This is where we use the fact that `charFun (μ n)` converges to `f`.
  have h_limsup_le r (hr : 0 < r) :
      limsup (fun n ↦ (μ n {x | r < |⟪z, x⟫|}).toReal) atTop
        ≤ 2⁻¹ * r * ‖∫ t in -2 * r⁻¹..2 * r⁻¹, 1 - f (t • z)‖ := by
    calc limsup (fun n ↦ (μ n {x | r < |⟪z, x⟫|}).toReal) atTop
    _ ≤ limsup (fun n ↦ 2⁻¹ * r
        * ‖∫ t in -2 * r⁻¹..2 * r⁻¹, 1 - charFun (μ n) (t • z)‖) atTop := by
      refine limsup_le_limsup (.of_forall fun n ↦ h_le n r hr) ?_ ?_
      · exact IsCoboundedUnder.of_frequently_ge <| .of_forall fun _ ↦ ENNReal.toReal_nonneg
      · refine ⟨4, ?_⟩
        simp only [eventually_map, eventually_atTop, ge_iff_le]
        exact ⟨0, fun n _ ↦ h_le_4 n r hr⟩
    _ = 2⁻¹ * r * ‖∫ t in -2 * r⁻¹..2 * r⁻¹, 1 - f (t • z)‖ := by
      refine ((Tendsto.norm ?_).const_mul _).limsup_eq
      simp only [neg_mul, intervalIntegrable_const]
      have hr' : -(2 * r⁻¹) ≤ 2 * r⁻¹ := by rw [neg_le_self_iff]; positivity
      simp_rw [intervalIntegral.integral_of_le hr']
      refine tendsto_integral_of_dominated_convergence (fun _ ↦ 2) ?_ (by fun_prop) ?_ ?_
      · exact fun _ ↦ Measurable.aestronglyMeasurable <| by fun_prop
      · exact fun _ ↦ ae_of_all _ fun _ ↦ norm_one_sub_charFun_le_two
      · exact ae_of_all _ fun x ↦ tendsto_const_nhds.sub (h _)
  -- It suffices to show that the upper bound tends to 0.
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds
    (h := fun r ↦ 2⁻¹ * r * ‖∫ t in -2 * r⁻¹..2 * r⁻¹, 1 - f (t • z)‖)
    ?_ ?_ ?_
  rotate_left
  · filter_upwards [eventually_gt_atTop 0] with r hr
    refine le_limsup_of_le ?_ fun u hu ↦ ?_
    · refine ⟨4, ?_⟩
      simp only [eventually_map, eventually_atTop, ge_iff_le]
      exact ⟨0, fun n _ ↦ (h_le n r hr).trans (h_le_4 n r hr)⟩
    · exact ENNReal.toReal_nonneg.trans hu.exists.choose_spec
  · filter_upwards [eventually_gt_atTop 0] with r hr using h_limsup_le r hr
  -- We now show that the upper bound tends to 0.
  -- This will follow from the fact that `f` is continuous at `0`.
  -- `⊢ Tendsto (fun r ↦ 2⁻¹ * r * ‖∫ t in -2 * r⁻¹..2 * r⁻¹,`
  --    `1 - f (t • z)‖) atTop (𝓝 0)`
  have hf_tendsto := hf.tendsto
  rw [Metric.tendsto_nhds_nhds] at hf_tendsto
  rw [Metric.tendsto_atTop]
  intro ε hε
  have hf0 : f 0 = 1 := by symm; simpa using h 0
  simp only [gt_iff_lt, dist_eq_norm_sub', zero_sub, norm_neg, hf0] at hf_tendsto
  simp only [ge_iff_le, neg_mul, intervalIntegrable_const, dist_zero_right, norm_mul, norm_inv,
    Real.norm_ofNat, Real.norm_eq_abs, norm_norm]
  simp_rw [abs_of_nonneg (norm_nonneg _)]
  obtain ⟨δ, hδ, hδ_lt⟩ : ∃ δ, 0 < δ ∧ ∀ ⦃x : E⦄, ‖x‖ < δ → ‖1 - f x‖ < ε / 4 :=
    hf_tendsto (ε / 4) (by positivity)
  refine ⟨4 * δ⁻¹, fun r hrδ ↦ ?_⟩
  have hr : 0 < r := lt_of_lt_of_le (by positivity) hrδ
  have hr' : -(2 * r⁻¹) ≤ 2 * r⁻¹ := by rw [neg_le_self_iff]; positivity
  have h_le_Ioc x (hx : x ∈ Set.Ioc (-(2 * r⁻¹)) (2 * r⁻¹)) :
      ‖1 - f (x • z)‖ ≤ ε / 4 := by
    refine (hδ_lt ?_).le
    simp only [norm_smul, Real.norm_eq_abs, OrthonormalBasis.norm_eq_one, mul_one, hz]
    calc |x|
    _ ≤ 2 * r⁻¹ := by
      rw [abs_le]
      rw [Set.mem_Ioc] at hx
      exact ⟨hx.1.le, hx.2⟩
    _ < δ := by
      rw [← lt_div_iff₀' (by positivity), inv_lt_comm₀ hr (by positivity)]
      refine lt_of_lt_of_le ?_ hrδ
      ring_nf
      gcongr
      norm_num
  rw [abs_of_nonneg hr.le]
  calc 2⁻¹ * r * ‖∫ t in -(2 * r⁻¹)..2 * r⁻¹, 1 - f (t • z)‖
  _ ≤ 2⁻¹ * r * ∫ t in -(2 * r⁻¹)..2 * r⁻¹, ‖1 - f (t • z)‖ := by
    gcongr
    rw [intervalIntegral.integral_of_le hr', intervalIntegral.integral_of_le hr']
    exact norm_integral_le_integral_norm _
  _ ≤ 2⁻¹ * r * ∫ t in -(2 * r⁻¹)..2 * r⁻¹, ε / 4 := by
    gcongr
    rw [intervalIntegral.integral_of_le hr', intervalIntegral.integral_of_le hr']
    refine integral_mono_ae ?_ (by fun_prop) ?_
    · refine Integrable.mono' (integrable_const (ε / 4)) ?_ ?_
      · exact Measurable.aestronglyMeasurable <| by fun_prop
      · simp_rw [norm_norm]
        exact ae_restrict_of_forall_mem measurableSet_Ioc h_le_Ioc
    · exact ae_restrict_of_forall_mem measurableSet_Ioc h_le_Ioc
  _ = ε / 2 := by
    simp only [intervalIntegral.integral_div, intervalIntegral.integral_const, sub_neg_eq_add,
      smul_eq_mul]
    ring_nf
    rw [mul_inv_cancel₀ hr.ne', one_mul]
  _ < ε := by simp [hε]

end FiniteDimensional

variable {ι : Type*} [InnerProductSpace ℝ E] {μ : ι → Measure E} [∀ i, IsProbabilityMeasure (μ i)]

section EquicontinuousAt

lemma equicontinuousAt_charFun_zero_of_isTightMeasureSet (hμ : IsTightMeasureSet {μ i | i}) :
    EquicontinuousAt (fun i ↦ charFun (μ i)) 0 := by
  sorry

lemma isTightMeasureSet_of_equicontinuousAt_charFun
    (hμ : EquicontinuousAt (fun i ↦ charFun (μ i)) 0) :
    IsTightMeasureSet {μ i | i} := by
  sorry

lemma isTightMeasureSet_iff_equicontinuousAt_charFun :
    IsTightMeasureSet {μ i | i} ↔ EquicontinuousAt (fun i ↦ charFun (μ i)) 0 :=
  ⟨equicontinuousAt_charFun_zero_of_isTightMeasureSet,
    isTightMeasureSet_of_equicontinuousAt_charFun⟩

end EquicontinuousAt
