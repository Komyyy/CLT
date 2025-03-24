/-
Copyright (c) 2025 Rémy Degenne. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Rémy Degenne
-/
import Clt.CharFun
import Clt.Prokhorov

/-!
# Tightness and characteristic functions

-/

open MeasureTheory ProbabilityTheory Filter
open scoped ENNReal Topology RealInnerProductSpace

variable {E ι : Type*} {mE : MeasurableSpace E} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
  {μ : ι → Measure E} [∀ i, IsProbabilityMeasure (μ i)]

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

lemma isTightMeasureSet_of_tendsto_measure_norm_gt [BorelSpace E] [SecondCountableTopology E]
    [FiniteDimensional ℝ E]
    {S : Set (Measure E)} (h : Tendsto (fun (r : ℝ) ↦ ⨆ μ ∈ S, μ {x | r < ‖x‖}) atTop (𝓝 0)) :
    IsTightMeasureSet S := by
  rw [IsTightMeasureSet_iff_exists_isCompact_measure_compl_le]
  intro ε hε
  rw [ENNReal.tendsto_atTop_zero] at h
  obtain ⟨r, h⟩ := h ε hε
  specialize h r le_rfl
  refine ⟨Metric.closedBall 0 r, isCompact_closedBall 0 r, ?_⟩
  simp only [iSup_le_iff] at h
  convert h using 4 with μ hμ
  ext
  simp

lemma isTightMeasureSet_of_forall_basis_tendsto [BorelSpace E] [SecondCountableTopology E]
    [FiniteDimensional ℝ E]
    {S : Set (Measure E)} (h_prob : ∀ μ ∈ S, IsProbabilityMeasure μ)
    (h : ∀ i, Tendsto (fun (r : ℝ) ↦ ⨆ μ ∈ S, μ {x | r < |⟪Module.finBasis ℝ E i, x⟫|})
      atTop (𝓝 0)) :
    IsTightMeasureSet S := by
  refine isTightMeasureSet_of_tendsto_measure_norm_gt ?_
  sorry

lemma isTightMeasureSet_of_tendsto_limsup_measure_norm_gt [BorelSpace E] [SecondCountableTopology E]
    [FiniteDimensional ℝ E]
    {μ : ℕ → Measure E}
    (h : Tendsto (fun (r : ℝ) ↦ limsup (fun n ↦ μ n {x | r < ‖x‖}) atTop) atTop (𝓝 0)) :
    IsTightMeasureSet {μ n | n} := by
  sorry

lemma isTightMeasureSet_of_forall_basis_tendsto_limsup [BorelSpace E] [SecondCountableTopology E]
    [FiniteDimensional ℝ E]
    {μ : ℕ → Measure E} [∀ n, IsProbabilityMeasure (μ n)]
    (h : ∀ i, Tendsto (fun (r : ℝ) ↦ limsup (fun n ↦ μ n {x | r < |⟪Module.finBasis ℝ E i, x⟫|})
      atTop) atTop (𝓝 0)) :
    IsTightMeasureSet {μ n | n} := by
  sorry

/-- Let $(\mu_n)_{n \in \mathbb{N}}$ be measures on $\mathbb{R}^d$ with characteristic functions
$(\hat{\mu}_n)$. If $\hat{\mu}_n$ converges pointwise to a function $f$ which is continuous at 0,
then $(\mu_n)$ is tight. -/
lemma isTightMeasureSet_of_tendsto_charFun [BorelSpace E] [SecondCountableTopology E]
    [FiniteDimensional ℝ E]
    {μ : ℕ → Measure E} [∀ i, IsProbabilityMeasure (μ i)]
    {f : E → ℂ} (hf : ContinuousAt f 0) (hf_meas : Measurable f)
    (h : ∀ t, Tendsto (fun n ↦ charFun (μ n) t) atTop (𝓝 (f t))) :
    IsTightMeasureSet {μ i | i} := by
  refine isTightMeasureSet_of_forall_basis_tendsto_limsup fun i ↦ ?_
  have h_le n r := measure_abs_inner_ge_le_charFun (μ := μ n) (a := Module.finBasis ℝ E i) (r := r)
  suffices Tendsto (fun (r : ℝ) ↦
        limsup (fun n ↦ (μ n {x | r < |⟪Module.finBasis ℝ E i, x⟫|}).toReal) atTop)
      atTop (𝓝 0) by
    have h_ofReal r : limsup (fun n ↦ μ n {x | r < |⟪Module.finBasis ℝ E i, x⟫|}) atTop
        = ENNReal.ofReal
          (limsup (fun n ↦ (μ n {x | r < |⟪Module.finBasis ℝ E i, x⟫|}).toReal) atTop) := by
      sorry
    simp_rw [h_ofReal]
    rw [← ENNReal.ofReal_zero]
    exact ENNReal.tendsto_ofReal this
  have h_limsup_le r (hr : 0 < r) :
      limsup (fun n ↦ (μ n {x | r < |⟪Module.finBasis ℝ E i, x⟫|}).toReal) atTop
      ≤ 2⁻¹ * r * ‖∫ t in -2 * r⁻¹..2 * r⁻¹, 1 - f (t • Module.finBasis ℝ E i)‖ := by
    -- This is where we use the fact that `charFun (μ n)` converges to `f`
    sorry
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds
    (h := fun r ↦ 2⁻¹ * r * ‖∫ t in -2 * r⁻¹..2 * r⁻¹, 1 - f (t • Module.finBasis ℝ E i)‖)
    ?_ ?_ ?_
  rotate_left
  · filter_upwards [eventually_gt_atTop 0] with r hr
    refine le_limsup_of_le ?_ fun u hu ↦ ?_
    · refine ⟨4, ?_⟩
      simp only [eventually_map, eventually_atTop, ge_iff_le]
      refine ⟨0, fun n _ ↦ ?_⟩
      refine (h_le n r hr).trans ?_
      calc 2⁻¹ * r * ‖∫ t in -2 * r⁻¹..2 * r⁻¹, 1 - charFun (μ n) (t • Module.finBasis ℝ E i)‖
      _ ≤ 2⁻¹ * r
          * ∫ t in -(2 * r⁻¹)..2 * r⁻¹, ‖1 - charFun (μ n) (t • Module.finBasis ℝ E i)‖ := by
        simp only [neg_mul, intervalIntegrable_const]
        gcongr
        rw [intervalIntegral.integral_of_le, intervalIntegral.integral_of_le]
        · exact norm_integral_le_integral_norm _
        · rw [neg_le_self_iff]; positivity
        · rw [neg_le_self_iff]; positivity
      _ ≤ 2⁻¹ * r * ∫ t in -(2 * r⁻¹)..2 * r⁻¹, 2 := by
        gcongr
        rw [intervalIntegral.integral_of_le, intervalIntegral.integral_of_le]
        rotate_left
        · rw [neg_le_self_iff]; positivity
        · rw [neg_le_self_iff]; positivity
        refine integral_mono_of_nonneg ?_ (by fun_prop) ?_
        · exact ae_of_all _ fun _ ↦ by positivity
        · refine ae_of_all _ fun x ↦ ?_
          calc ‖1 - charFun (μ n) (x • Module.finBasis ℝ E i)‖
          _ ≤ ‖(1 : ℂ)‖ + ‖charFun (μ n) (x • Module.finBasis ℝ E i)‖ := norm_sub_le _ _
          _ ≤ 1 + 1 := by simp [norm_charFun_le_one]
          _ = 2 := by norm_num
      _ ≤ 4 := by
        simp only [neg_mul, intervalIntegral.integral_const, sub_neg_eq_add, smul_eq_mul]
        ring_nf
        rw [mul_inv_cancel₀ hr.ne', one_mul]
    · exact ENNReal.toReal_nonneg.trans hu.exists.choose_spec
  · filter_upwards [eventually_gt_atTop 0] with r hr using h_limsup_le r hr
  -- `⊢ Tendsto (fun r ↦ 2⁻¹ * r * ‖∫ t in -2 * r⁻¹..2 * r⁻¹, 1 - f (t • Module.finBasis ℝ E i)‖)`
  --    `atTop (𝓝 0)`
  -- This will follow from the fact that `f` is continuous at `0`.
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
  have h_norm_basis_pos : 0 < ‖Module.finBasis ℝ E i‖ := by
    simp only [norm_pos_iff, ne_eq]
    exact Basis.ne_zero (Module.finBasis ℝ E) i
  refine ⟨4 * δ⁻¹ * ‖Module.finBasis ℝ E i‖, fun r hrδ ↦ ?_⟩
  have hr : 0 < r := lt_of_lt_of_le (by positivity) hrδ
  have h_le_Ioc x (hx : x ∈ Set.Ioc (-(2 * r⁻¹)) (2 * r⁻¹)) :
      ‖1 - f (x • Module.finBasis ℝ E i)‖ ≤ ε / 4 := by
    refine (hδ_lt ?_).le
    rw [norm_smul]
    calc ‖x‖ * ‖Module.finBasis ℝ E i‖
    _ ≤ 2 * r⁻¹ * ‖Module.finBasis ℝ E i‖ := by
      gcongr
      simp only [Real.norm_eq_abs, abs_le]
      simp only [Set.mem_Ioc] at hx
      exact ⟨hx.1.le, hx.2⟩
    _ < δ * ‖Module.finBasis ℝ E i‖⁻¹ * ‖Module.finBasis ℝ E i‖ := by
      rw [mul_lt_mul_right h_norm_basis_pos, ← lt_div_iff₀' (by positivity),
        inv_lt_comm₀ hr (by positivity)]
      refine lt_of_lt_of_le ?_ hrδ
      ring_nf
      rw [mul_comm δ⁻¹, inv_inv]
      gcongr
      norm_num
    _ ≤ δ := by
      rw [mul_assoc, inv_mul_cancel₀, mul_one]
      simp only [ne_eq, norm_eq_zero]
      exact Basis.ne_zero (Module.finBasis ℝ E) i
  rw [abs_of_nonneg hr.le]
  calc 2⁻¹ * r * ‖∫ t in -(2 * r⁻¹)..2 * r⁻¹, 1 - f (t • Module.finBasis ℝ E i)‖
  _ ≤ 2⁻¹ * r * ∫ t in -(2 * r⁻¹)..2 * r⁻¹, ‖1 - f (t • Module.finBasis ℝ E i)‖ := by
    gcongr
    rw [intervalIntegral.integral_of_le, intervalIntegral.integral_of_le]
    · exact norm_integral_le_integral_norm _
    · rw [neg_le_self_iff]; positivity
    · rw [neg_le_self_iff]; positivity
  _ ≤ 2⁻¹ * r * ∫ t in -(2 * r⁻¹)..2 * r⁻¹, ε / 4 := by
    gcongr
    rw [intervalIntegral.integral_of_le, intervalIntegral.integral_of_le]
    rotate_left
    · rw [neg_le_self_iff]; positivity
    · rw [neg_le_self_iff]; positivity
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
