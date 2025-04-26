/-
Copyright (c) 2024 Thomas Zhu. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Thomas Zhu, Rémy Degenne
-/
import Mathlib.Probability.Distributions.Gaussian
import Mathlib.Analysis.SpecialFunctions.Gaussian.FourierTransform
import Clt.CharFunCLM
import Clt.Covariance
import Clt.GaussianReal
import Clt.MomentGenerating

/-!
Properties of Gaussian distributions and its characteristic function.
-/

open MeasureTheory ProbabilityTheory Complex NormedSpace
open scoped ENNReal NNReal Real Topology

section Aux

lemma rpow_toReal_eLpNorm {E F : Type*} {mE : MeasurableSpace E} {μ : Measure E}
    [NormedAddCommGroup F] {f : E → F} {p : ℝ}
    (hf : MemLp f (ENNReal.ofReal p) μ) (hp : 0 < p) :
    (eLpNorm f (ENNReal.ofReal p) μ).toReal ^ p = ∫ x, ‖f x‖ ^ p ∂μ := by
  rw [eLpNorm_eq_lintegral_rpow_enorm (by simp [hp]) (by simp)]
  simp only [one_div]
  have : (ENNReal.ofReal p).toReal = p := ENNReal.toReal_ofReal (by positivity)
  simp_rw [this]
  rw [ENNReal.toReal_rpow, ← ENNReal.rpow_mul, inv_mul_cancel₀ hp.ne', ENNReal.rpow_one]
  simp_rw [← ofReal_norm, ENNReal.ofReal_rpow_of_nonneg (norm_nonneg _) hp.le]
  rw [← ofReal_integral_eq_lintegral_ofReal, ENNReal.toReal_ofReal (by positivity)]
  · convert MemLp.integrable_norm_rpow hf (by simp [hp]) (by simp)
    exact this.symm
  · exact ae_of_all _ fun x ↦ by positivity

lemma pow_toReal_eLpNorm {E F : Type*} {mE : MeasurableSpace E} {μ : Measure E}
    [NormedAddCommGroup F] {f : E → F} {n : ℕ}
    (hf : MemLp f n μ) (hn : n ≠ 0) :
    (eLpNorm f n μ).toReal ^ n = ∫ x, ‖f x‖ ^ n ∂μ := by
  have h_Lp : MemLp f (ENNReal.ofReal n) μ := by convert hf; simp
  have h := rpow_toReal_eLpNorm h_Lp (by positivity)
  simpa using h

end Aux

namespace ProbabilityTheory

/-- A measure is Gaussian if its map by every continuous linear form is a real Gaussian measure. -/
class IsGaussian {E : Type*} [TopologicalSpace E] [AddCommMonoid E] [Module ℝ E]
  {mE : MeasurableSpace E} (μ : Measure E) : Prop where
  map_eq_gaussianReal (L : E →L[ℝ] ℝ) : μ.map L = gaussianReal (μ[L]) (Var[L ; μ]).toNNReal

instance isGaussian_gaussianReal (m : ℝ) (v : ℝ≥0) : IsGaussian (gaussianReal m v) where
  map_eq_gaussianReal L := by
    rw [gaussianReal_map_continuousLinearMap]
    simp only [integral_continuousLinearMap_gaussianReal, variance_continuousLinearMap_gaussianReal,
      Real.coe_toNNReal']
    congr
    rw [Real.toNNReal_mul (by positivity), Real.toNNReal_coe]
    congr
    simp only [left_eq_sup]
    positivity

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
  {mE : MeasurableSpace E} [BorelSpace E]

instance {x : E} : IsGaussian (Measure.dirac x) where
  map_eq_gaussianReal L := by rw [Measure.map_dirac (by fun_prop)]; simp

/-- A Gaussian measure is a probability measure. -/
instance {μ : Measure E} [IsGaussian μ] : IsProbabilityMeasure μ where
  measure_univ := by
    let L : E →L[ℝ] ℝ := Nonempty.some inferInstance
    have : μ.map L Set.univ = 1 := by simp [IsGaussian.map_eq_gaussianReal L]
    simpa [Measure.map_apply (by fun_prop : Measurable L) .univ] using this

lemma IsGaussian.memLp_continuousLinearMap (μ : Measure E) [IsGaussian μ] (L : E →L[ℝ] ℝ)
    (p : ℝ≥0∞) (hp : p ≠ ∞) :
    MemLp L p μ := by
  suffices MemLp (id ∘ L) p μ from this
  rw [← memLp_map_measure_iff, IsGaussian.map_eq_gaussianReal L]
  · convert memLp_id_gaussianReal _ _ p.toNNReal
    simp [hp]
  · exact Measurable.aestronglyMeasurable <| by fun_prop
  · fun_prop

@[fun_prop]
lemma IsGaussian.integrable_continuousLinearMap (μ : Measure E) [IsGaussian μ] (L : E →L[ℝ] ℝ) :
    Integrable L μ := by
  rw [← memLp_one_iff_integrable]
  exact IsGaussian.memLp_continuousLinearMap μ L 1 (by simp)

lemma isGaussian_map_prod_add [SecondCountableTopology E]
    {μ ν : Measure E} [IsGaussian μ] [IsGaussian ν] :
    IsGaussian ((μ.prod ν).map (fun p ↦ p.1 + p.2)) where
  map_eq_gaussianReal := by
    intro L
    have h1 : ((μ.prod ν).map (fun p ↦ p.1 + p.2)).map L
        = ((μ.map L).prod (ν.map L)).map (fun p ↦ p.1 + p.2) := by
      rw [Measure.map_map (by fun_prop) (by fun_prop)]
      have : (L ∘ fun (p : E × E) ↦ p.1 + p.2)
          = (fun p : ℝ × ℝ ↦ p.1 + p.2) ∘ (Prod.map L L) := by ext; simp
      rw [this, ← Measure.map_map (by fun_prop) (by fun_prop),
        ← Measure.map_prod_map]
      · fun_prop
      · fun_prop
    have : ∫ x, L x ∂((μ.prod ν).map (fun p ↦ p.1 + p.2))
          = ∫ x, x ∂(((μ.map L).prod (ν.map L)).map (fun p ↦ p.1 + p.2)) := by
        rw [← h1, integral_map (φ := L)]
        · fun_prop
        · exact measurable_id.aestronglyMeasurable
    rw [h1, this, ← variance_id_map (by fun_prop), h1, IsGaussian.map_eq_gaussianReal L,
      IsGaussian.map_eq_gaussianReal L, gaussianReal_map_prod_add]
    congr
    · simp
    · simp [variance_nonneg]

instance isGaussian_conv [SecondCountableTopology E]
    {μ ν : Measure E} [IsGaussian μ] [IsGaussian ν] :
    IsGaussian (μ ∗ ν) := isGaussian_map_prod_add

section Centered

def IsCentered (μ : Measure E) : Prop := ∀ L : E →L[ℝ] ℝ, μ[L] = 0

lemma isCentered_dirac_zero : IsCentered (Measure.dirac (0 : E)) := by intro L; simp

end Centered

section IsDegenerate

def IsDegenerate (μ : Measure E) : Prop :=
  ∃ L : E →L[ℝ] ℝ, L ≠ 0 ∧ Var[L ; μ] = 0

lemma isDegenerate_dirac (x : E) : IsDegenerate (Measure.dirac x) := by
  obtain ⟨L, hL⟩ : ∃ L : E →L[ℝ] ℝ, L ≠ 0 := by
    sorry
  exact ⟨L, hL, by simp⟩

end IsDegenerate

section CharFunCLM

lemma IsGaussian.charFunCLM_eq {μ : Measure E} [IsGaussian μ] (L : E →L[ℝ] ℝ) :
    charFunCLM μ L = cexp (μ[L] * I - Var[L ; μ] / 2) := by
  calc charFunCLM μ L
  _ = charFun (μ.map L) 1 := by rw [charFunCLM_eq_charFun_map_one]
  _ = charFun (gaussianReal (μ[L]) (Var[L ; μ]).toNNReal) 1 := by
    rw [IsGaussian.map_eq_gaussianReal L]
  _ = cexp (μ[L] * I - Var[L ; μ] / 2) := by
    rw [charFun_gaussianReal]
    simp only [ofReal_one, one_mul, Real.coe_toNNReal', one_pow, mul_one]
    congr
    · rw [integral_complex_ofReal]
    · simp only [sup_eq_left]
      exact variance_nonneg _ _

lemma IsGaussian.charFunCLM_eq_of_isCentered {μ : Measure E} [IsGaussian μ]
    (hμ : IsCentered μ) (L : E →L[ℝ] ℝ) :
    charFunCLM μ L = cexp (- Var[L ; μ] / 2) := by
  rw [IsGaussian.charFunCLM_eq L, integral_complex_ofReal, hμ L]
  simp [neg_div]

theorem isGaussian_iff_charFunCLM_eq {μ : Measure E} [IsFiniteMeasure μ] :
    IsGaussian μ ↔ ∀ L : E →L[ℝ] ℝ, charFunCLM μ L = cexp (μ[L] * I - Var[L ; μ] / 2) := by
  refine ⟨fun h ↦ h.charFunCLM_eq, fun h ↦ ⟨fun L ↦ ?_⟩⟩
  refine Measure.ext_of_charFun ?_
  ext u
  rw [charFun_map_eq_charFunCLM_smul L u, h (u • L), charFun_gaussianReal]
  simp only [ContinuousLinearMap.coe_smul', Pi.smul_apply, smul_eq_mul, ofReal_mul,
    Real.coe_toNNReal']
  congr
  · rw [integral_mul_left, integral_complex_ofReal]
  · rw [max_eq_left (variance_nonneg _ _), mul_comm, ← ofReal_pow, ← ofReal_mul, ← variance_mul]
    congr

alias ⟨_, isGaussian_of_charFunCLM_eq⟩ := isGaussian_iff_charFunCLM_eq

end CharFunCLM

section Rotation

variable {F : Type*} [NormedAddCommGroup F] [NormedSpace ℝ F]
  {mF : MeasurableSpace F} [BorelSpace F]
  {μ : Measure E} [IsGaussian μ] {ν : Measure F} [IsGaussian ν]

instance isGaussian_map (L : E →L[ℝ] F) : IsGaussian (μ.map L) where
  map_eq_gaussianReal L' := by
    rw [Measure.map_map (by fun_prop) (by fun_prop)]
    change Measure.map (L'.comp L) μ = _
    rw [IsGaussian.map_eq_gaussianReal (L'.comp L)]
    congr
    · rw [integral_map (by fun_prop)]
      · simp
      · exact Measurable.aestronglyMeasurable <| by fun_prop
    · rw [← variance_id_map (by fun_prop)]
      conv_rhs => rw [← variance_id_map (by fun_prop)]
      rw [Measure.map_map (by fun_prop) (by fun_prop)]
      simp

instance isGaussian_map_equiv (L : E ≃L[ℝ] F) : IsGaussian (μ.map L) := by
  convert isGaussian_map (L : E →L[ℝ] F)
  infer_instance

lemma isCentered_conv_map_neg [SecondCountableTopology E] :
    IsCentered (μ ∗ (μ.map (ContinuousLinearEquiv.neg ℝ))) := by
  intro L
  rw [integral_conv (by fun_prop)]
  simp only [map_add]
  calc ∫ x, ∫ y, L x + L y ∂μ.map (ContinuousLinearEquiv.neg ℝ) ∂μ
  _ = ∫ x, L x + ∫ y, L y ∂μ.map (ContinuousLinearEquiv.neg ℝ) ∂μ := by
    congr with x
    rw [integral_add (by fun_prop) (by fun_prop)]
    simp [- ContinuousLinearEquiv.coe_neg, integral_const, smul_eq_mul, add_left_inj]
  _ = ∫ x, L x ∂μ + ∫ y, L y ∂μ.map (ContinuousLinearEquiv.neg ℝ) := by
    rw [integral_add (by fun_prop) (by fun_prop)]
    simp
  _ = 0 := by
    rw [integral_map (by fun_prop)]
    · simp [integral_neg]
    · exact Measurable.aestronglyMeasurable <| by fun_prop

lemma todol' (L : E × F →L[ℝ] ℝ) {p : ℝ≥0∞} (hp : p ≠ ∞) :
    MemLp (fun x ↦ (L.comp (.inl ℝ E F) x.1)) p (μ.prod ν) := by
  change MemLp ((L.comp (.inl ℝ E F) ∘ Prod.fst)) p (μ.prod ν)
  rw [← memLp_map_measure_iff]
  · simp only [Measure.map_fst_prod, measure_univ, one_smul]
    exact IsGaussian.memLp_continuousLinearMap μ (L.comp (.inl ℝ E F)) p hp
  · simp only [Measure.map_fst_prod, measure_univ, one_smul]
    exact (IsGaussian.integrable_continuousLinearMap μ (L.comp (.inl ℝ E F))).1
  · fun_prop

lemma todor' (L : E × F →L[ℝ] ℝ) {p : ℝ≥0∞} (hp : p ≠ ∞) :
    MemLp (fun x ↦ (L.comp (.inr ℝ E F) x.2)) p (μ.prod ν) := by
  change MemLp ((L.comp (.inr ℝ E F) ∘ Prod.snd)) p (μ.prod ν)
  rw [← memLp_map_measure_iff]
  · simp only [Measure.map_snd_prod, measure_univ, one_smul]
    exact IsGaussian.memLp_continuousLinearMap _ (L.comp (.inr ℝ E F)) p hp
  · simp only [Measure.map_snd_prod, measure_univ, one_smul]
    exact (IsGaussian.integrable_continuousLinearMap _ (L.comp (.inr ℝ E F))).1
  · fun_prop

lemma todo' (L : E × F →L[ℝ] ℝ) {p : ℝ≥0∞} (hp : p ≠ ∞) :
    MemLp L p (μ.prod ν) := by
  suffices MemLp (fun v ↦ L.comp (.inl ℝ E F) v.1 + L.comp (.inr ℝ E F) v.2) p (μ.prod ν) by
    simp_rw [L.comp_inl_add_comp_inr] at this
    exact this
  exact MemLp.add (todol' L hp) (todor' L hp)

lemma todol (L : E × F →L[ℝ] ℝ) :
    Integrable (fun x ↦ (L.comp (.inl ℝ E F) x.1)) (μ.prod ν) := by
  rw [← memLp_one_iff_integrable]
  exact todol' L (by simp)

lemma todor (L : E × F →L[ℝ] ℝ) :
    Integrable (fun x ↦ (L.comp (.inr ℝ E F) x.2)) (μ.prod ν) := by
  rw [← memLp_one_iff_integrable]
  exact todor' L (by simp)

lemma integral_continuousLinearMap_prod (L : E × F →L[ℝ] ℝ) :
    (μ.prod ν)[L] = μ[L.comp (.inl ℝ E F)] + ν[L.comp (.inr ℝ E F)] := by
  simp_rw [← L.comp_inl_add_comp_inr]
  rw [integral_add (todol L) (todor L)]
  · congr
    · rw [integral_prod _ (todol L)]
      simp
    · rw [integral_prod _ (todor L)]
      simp

lemma variance_continuousLinearMap_prod [SecondCountableTopologyEither E F] (L : E × F →L[ℝ] ℝ) :
    Var[L ; μ.prod ν] = Var[L.comp (.inl ℝ E F) ; μ] + Var[L.comp (.inr ℝ E F) ; ν] := by
  rw [variance_def' (todo' L (by simp)), integral_continuousLinearMap_prod L,
    variance_def', variance_def']
  rotate_left
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  let L₁ := L.comp (.inl ℝ E F)
  let L₂ := L.comp (.inr ℝ E F)
  simp only [Pi.pow_apply, Function.comp_apply,
    ContinuousLinearMap.inl_apply, ContinuousLinearMap.inr_apply]
  suffices h_sq : ∫ v, L v ^ 2 ∂(μ.prod ν)
      = ∫ x, L₁ x ^ 2 ∂μ + ∫ x, L₂ x ^ 2 ∂ν + 2 * μ[L₁] * ν[L₂] by rw [h_sq]; ring
  calc ∫ v, L v ^ 2 ∂μ.prod ν
  _ = ∫ v, (L₁ v.1 + L₂ v.2) ^ 2 ∂μ.prod ν := by simp_rw [← L.comp_inl_add_comp_inr]; simp [L₁, L₂]
  _ = ∫ v, L₁ v.1 ^ 2 + L₂ v.2 ^ 2 + 2 * L₁ v.1 * L₂ v.2 ∂μ.prod ν := by
    congr with v; ring
  _ = ∫ v, L₁ v.1 ^ 2 ∂μ.prod ν + ∫ v, L₂ v.2 ^ 2 ∂μ.prod ν
      + 2 * ∫ v, L₁ v.1 * L₂ v.2 ∂μ.prod ν := by
    have h_int1 : Integrable (fun a ↦ L₁ a.1 ^ 2) (μ.prod ν) := by
      rw [← integrable_norm_iff]
      swap; · exact Measurable.aestronglyMeasurable <| by fun_prop
      simp only [norm_pow]
      refine MemLp.integrable_norm_pow ?_ (by simp)
      exact todol' L (by simp)
    have h_int2 : Integrable (fun a ↦ L₂ a.2 ^ 2) (μ.prod ν) := by
      rw [← integrable_norm_iff]
      swap; · exact Measurable.aestronglyMeasurable <| by fun_prop
      simp only [norm_pow]
      refine MemLp.integrable_norm_pow ?_ (by simp)
      exact todor' L (by simp)
    rw [integral_add, integral_add]
    · simp_rw [mul_assoc]
      rw [integral_mul_left]
    · exact h_int1
    · exact h_int2
    · exact Integrable.add h_int1 h_int2
    · simp_rw [mul_assoc]
      refine Integrable.const_mul ?_ _
      refine MemLp.integrable_mul (p := 2) (q := 2) ?_ ?_
      · exact todol' L (by simp)
      · exact todor' L (by simp)
  _ = ∫ x, L₁ x ^ 2 ∂μ + ∫ x, L₂ x ^ 2 ∂ν + 2 * μ[L₁] * ν[L₂] := by
    simp_rw [mul_assoc]
    congr
    · have : μ = (μ.prod ν).map (fun p ↦ p.1) := by simp
      conv_rhs => rw [this]
      rw [integral_map]
      · fun_prop
      · exact Measurable.aestronglyMeasurable <| by fun_prop
    · have : ν = (μ.prod ν).map (fun p ↦ p.2) := by simp
      conv_rhs => rw [this]
      rw [integral_map]
      · fun_prop
      · exact Measurable.aestronglyMeasurable <| by fun_prop
    · rw [integral_prod_mul]

/-- A product of Gaussian distributions is Gaussian. -/
instance [SecondCountableTopologyEither E F] : IsGaussian (μ.prod ν) := by
  refine isGaussian_of_charFunCLM_eq fun L ↦ ?_
  rw [charFunCLM_prod, IsGaussian.charFunCLM_eq, IsGaussian.charFunCLM_eq, ← Complex.exp_add]
  congr
  let L₁ := L.comp (.inl ℝ E F)
  let L₂ := L.comp (.inr ℝ E F)
  suffices μ[L₁] * I - Var[L₁ ; μ] / 2 +(ν[L₂] * I - Var[L₂ ; ν] / 2)
      = (μ.prod ν)[L] * I - Var[L ; μ.prod ν] / 2 by convert this
  rw [sub_add_sub_comm, ← add_mul]
  congr
  · simp_rw [integral_complex_ofReal]
    rw [integral_continuousLinearMap_prod L]
    norm_cast
  · field_simp
    rw [variance_continuousLinearMap_prod]
    norm_cast

noncomputable
def _root_.ContinuousLinearMap.rotation (θ : ℝ) :
    E × E →L[ℝ] E × E where
  toFun := fun x ↦ (Real.cos θ • x.1 + Real.sin θ • x.2, - Real.sin θ • x.1 + Real.cos θ • x.2)
  map_add' x y := by
    simp only [Prod.fst_add, smul_add, Prod.snd_add, neg_smul, Prod.mk_add_mk]
    ext
    · simp_rw [add_assoc]
      congr 1
      rw [add_comm, add_assoc]
      congr 1
      rw [add_comm]
    · simp only
      simp_rw [add_assoc]
      congr 1
      rw [add_comm, add_assoc]
      congr 1
      rw [add_comm]
  map_smul' c x := by
    simp only [Prod.smul_fst, Prod.smul_snd, neg_smul, RingHom.id_apply, Prod.smul_mk, smul_add,
      smul_neg]
    simp_rw [smul_comm c]
  cont := by fun_prop

lemma _root_.ContinuousLinearMap.rotation_apply (θ : ℝ) (x : E × E) :
    ContinuousLinearMap.rotation θ x = (Real.cos θ • x.1 + Real.sin θ • x.2,
      - Real.sin θ • x.1 + Real.cos θ • x.2) := rfl

lemma IsGaussian.map_rotation_eq_self [SecondCountableTopology E] [CompleteSpace E]
    (θ : ℝ) (hμ : IsCentered μ) :
    (μ.prod μ).map (ContinuousLinearMap.rotation θ) = μ.prod μ := by
  refine ext_of_charFunCLM ?_
  ext L
  rw [charFunCLM_map, charFunCLM_prod, IsGaussian.charFunCLM_eq_of_isCentered hμ,
    IsGaussian.charFunCLM_eq_of_isCentered hμ, ← Complex.exp_add, charFunCLM_prod,
    IsGaussian.charFunCLM_eq_of_isCentered hμ, IsGaussian.charFunCLM_eq_of_isCentered hμ,
    ← Complex.exp_add]
  rw [← add_div, ← add_div, ← neg_add, ← neg_add]
  congr 3
  norm_cast
  show Var[(L.comp (.rotation θ)).comp (.inl ℝ E E) ; μ]
        + Var[(L.comp (.rotation θ)).comp (.inr ℝ E E) ; μ]
      = Var[L.comp (.inl ℝ E E) ; μ] + Var[L.comp (.inr ℝ E E) ; μ]
  have h1 : (L.comp (.rotation θ)).comp (.inl ℝ E E)
      = Real.cos θ • L.comp (.inl ℝ E E) - Real.sin θ • L.comp (.inr ℝ E E) := by
    ext x
    simp only [ContinuousLinearMap.coe_comp', Function.comp_apply, ContinuousLinearMap.inl_apply,
      ContinuousLinearMap.rotation_apply, smul_zero, add_zero,
      ContinuousLinearMap.add_apply, ContinuousLinearMap.coe_smul', Pi.smul_apply, smul_eq_mul,
      ContinuousLinearMap.inr_apply]
    rw [← L.comp_inl_add_comp_inr]
    simp [- neg_smul, sub_eq_add_neg]
  have h2 : (L.comp (.rotation θ)).comp (.inr ℝ E E)
      = Real.sin θ • L.comp (.inl ℝ E E) + Real.cos θ • L.comp (.inr ℝ E E) := by
    ext x
    simp only [ContinuousLinearMap.coe_comp', Function.comp_apply, ContinuousLinearMap.inr_apply,
      ContinuousLinearMap.rotation_apply, smul_zero, zero_add, ContinuousLinearMap.add_apply,
      ContinuousLinearMap.coe_smul', Pi.smul_apply, ContinuousLinearMap.inl_apply, smul_eq_mul]
    rw [← L.comp_inl_add_comp_inr]
    simp
  rw [h1, h2, ← covariance_self (by fun_prop), ← covariance_self (by fun_prop),
    ← covariance_self (by fun_prop), ← covariance_self (by fun_prop)]
  simp only [ContinuousLinearMap.coe_sub',
    ContinuousLinearMap.coe_add']
  rw [covariance_sub_left, covariance_sub_right, covariance_sub_right,
    covariance_add_left, covariance_add_right, covariance_add_right]
  rotate_left
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · refine MemLp.add ?_ ?_
    · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
    · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  · refine MemLp.sub ?_ ?_
    · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
    · exact IsGaussian.memLp_continuousLinearMap _ _ _ (by simp)
  simp only [ContinuousLinearMap.coe_smul', ContinuousLinearMap.coe_comp', covariance_smul_right,
    covariance_smul_left]
  ring_nf
  rw [add_assoc, add_add_add_comm, mul_comm _ (Real.sin θ ^ 2), ← add_mul, ← add_mul,
    Real.cos_sq_add_sin_sq, one_mul, one_mul]

end Rotation

section ToLpₗ

variable {p : ℝ≥0∞}

/-- `MemLp.toLp` as a `LinearMap` from the continuous linear maps. -/
def ContinuousLinearMap.toLpₗ (μ : Measure E) [IsGaussian μ] (p : ℝ≥0∞) (hp : p ≠ ∞) :
    (E →L[ℝ] ℝ) →ₗ[ℝ] Lp ℝ p μ where
  toFun := fun L ↦ MemLp.toLp L (IsGaussian.memLp_continuousLinearMap μ L p hp)
  map_add' u v := by push_cast; rw [MemLp.toLp_add]
  map_smul' c L := by push_cast; rw [MemLp.toLp_const_smul]; rfl

@[simp]
lemma ContinuousLinearMap.toLpₗ_apply {μ : Measure E} [IsGaussian μ] (L : E →L[ℝ] ℝ)
    (hp : p ≠ ∞) :
    L.toLpₗ μ p hp = MemLp.toLp L (IsGaussian.memLp_continuousLinearMap μ L p hp) := rfl

end ToLpₗ

section Fernique

variable [SecondCountableTopology E] [CompleteSpace E] {μ : Measure E} [IsGaussian μ]

lemma norm_add_sub_norm_le_div_two_le_min (x y : E) :
    (‖x + y‖ - ‖x - y‖) / 2 ≤ min ‖x‖ ‖y‖ := by
  sorry

lemma IsGaussian.measure_le_mul_measure_gt_le (hμ : IsCentered μ) (a b : ℝ) :
    μ {x | ‖x‖ ≤ a} * μ {x | b < ‖x‖} ≤ μ {x | (b - a) / √2 < ‖x‖} ^ 2 := by
  calc μ {x | ‖x‖ ≤ a} * μ {x | b < ‖x‖}
  _ = (μ.prod μ) ({x | ‖x‖ ≤ a} ×ˢ {y | b < ‖y‖}) := by rw [Measure.prod_prod]
    -- this is the measure of two bands in the plane (draw a picture!)
  _ = (μ.prod μ) {p | ‖p.1‖ ≤ a ∧ b < ‖p.2‖} := rfl
  _ = ((μ.prod μ).map (ContinuousLinearMap.rotation (- (π/4)))) {p | ‖p.1‖ ≤ a ∧ b < ‖p.2‖} := by
    -- we can rotate the bands since `μ.prod μ` is invariant under rotation
    rw [map_rotation_eq_self _ hμ]
  _ = (μ.prod μ) {p | ‖p.1 - p.2‖ / √2 ≤ a ∧ b < ‖p.1 + p.2‖ / √2} := by
    rw [Measure.map_apply]
    rotate_left
    · fun_prop
    · refine MeasurableSet.inter ?_ ?_
      · change MeasurableSet {p : E × E | ‖p.1‖ ≤ a}
        exact measurableSet_le (by fun_prop) (by fun_prop)
      · change MeasurableSet {p : E × E | b < ‖p.2‖}
        exact measurableSet_lt (by fun_prop) (by fun_prop)
    congr 1
    simp only [Set.preimage_setOf_eq, ContinuousLinearMap.rotation_apply, Real.cos_neg,
      Real.cos_pi_div_four, Real.sin_neg, Real.sin_pi_div_four, neg_smul, neg_neg]
    have h_twos : ‖2⁻¹ * √2‖ = (√2)⁻¹ := by
      simp only [norm_mul, norm_inv, Real.norm_ofNat, Real.norm_eq_abs]
      rw [abs_of_nonneg (by positivity)]
      nth_rw 1 [← Real.sq_sqrt (by simp : (0 : ℝ) ≤ 2)]
      rw [pow_two, mul_inv, mul_assoc, inv_mul_cancel₀ (by positivity), mul_one]
    congr! with p
    · rw [← sub_eq_add_neg, ← smul_sub, norm_smul, div_eq_inv_mul, div_eq_inv_mul]
      congr
    · rw [← smul_add, norm_smul, div_eq_inv_mul, div_eq_inv_mul]
      congr
  _ ≤ (μ.prod μ) {p | (b - a) / √2 < ‖p.1‖ ∧ (b - a) / √2 < ‖p.2‖} := by
    -- the rotated bands are contained in quadrants.
    refine measure_mono fun p ↦ ?_
    simp only [Set.mem_setOf_eq, and_imp]
    intro hp1 hp2
    suffices (b - a) / √2 < min ‖p.1‖ ‖p.2‖ from lt_min_iff.mp this
    calc (b - a) / √2
    _ < (‖p.1 + p.2‖ - ‖p.1 - p.2‖) / 2 := by
      suffices b - a < ‖p.1 + p.2‖ / √2 - ‖p.1 - p.2‖ / √2 by
        calc (b - a) / √2
        _ < (‖p.1 + p.2‖ / √2 - ‖p.1 - p.2‖ / √2) / √2 := by gcongr
        _ = (‖p.1 + p.2‖ - ‖p.1 - p.2‖) / 2 := by
          rw [sub_div, div_div, div_div, ← pow_two, Real.sq_sqrt, sub_div]
          simp
      calc b - a
      _ < ‖p.1 + p.2‖ / √2 - a := by gcongr
      _ ≤ ‖p.1 + p.2‖ / √2 - ‖p.1 - p.2‖ / √2 := by gcongr
    _ ≤ min ‖p.1‖ ‖p.2‖ := norm_add_sub_norm_le_div_two_le_min _ _
  _ = (μ.prod μ) ({x | (b - a) / √2 < ‖x‖} ×ˢ {y | (b - a) / √2 < ‖y‖}) := rfl
  _ ≤ μ {x | (b - a) / √2 < ‖x‖} ^ 2 := by rw [Measure.prod_prod, pow_two]

open Metric in
/-- Special case of Fernique's theorem for centered Gaussian distributions. -/
lemma IsGaussian.exists_integrable_exp_sq_of_isCentered (hμ : IsCentered μ) :
    ∃ C, 0 < C ∧ Integrable (fun x ↦ rexp (C * ‖x‖ ^ 2)) μ := by
  by_cases hμ' : μ = Measure.dirac 0
  · refine ⟨1, by positivity, ?_⟩
    rw [hμ']
    exact integrable_dirac' <| Measurable.stronglyMeasurable <| by fun_prop
  obtain ⟨a, hc_gt, hc_lt⟩ : ∃ a, 2⁻¹ < μ {x | ‖x‖ ≤ a} ∧ μ {x | ‖x‖ ≤ a} < 1 := by
    sorry
  have ha_pos : 0 < a := by
    by_contra! ha
    have : {x : E | ‖x‖ ≤ a} ⊆ {0} := by
      intro x hx
      simp only [Set.mem_setOf_eq] at hx
      suffices ‖x‖ = 0 from norm_eq_zero.mp this
      exact le_antisymm (hx.trans ha) (norm_nonneg x)
    have h_not_lt : ¬ (2 : ℝ≥0∞)⁻¹ < 0 := by simp
    refine h_not_lt (hc_gt.trans_le ?_)
    simp only [nonpos_iff_eq_zero]
    refine measure_mono_null this ?_
    sorry
  let c := μ {x | ‖x‖ ≤ a}
  replace hc_gt : 2⁻¹ < c := hc_gt
  have hc_pos : 0 < c := lt_of_lt_of_le (by simp) hc_gt.le
  replace hc_lt : c < 1 := hc_lt
  have hc_lt_top : c < ∞ := lt_top_of_lt hc_lt
  let C : ℝ := a⁻¹ ^ 2 * Real.log (c / (1 - c)).toReal / 24
  have hC_pos : 0 < C := by
    simp only [inv_pow, ENNReal.toReal_div, Nat.ofNat_pos, div_pos_iff_of_pos_right, C]
    refine mul_pos (by positivity) ?_
    rw [Real.log_pos_iff]
    · rw [one_lt_div_iff]
      left
      constructor
      · simp only [ENNReal.toReal_pos_iff, tsub_pos_iff_lt, hc_lt, true_and, C]
        exact lt_top_of_lt (b := 2) (tsub_le_self.trans_lt (by simp))
      · gcongr
        · exact hc_lt_top.ne
        · refine ENNReal.sub_lt_of_lt_add hc_lt.le ?_
          sorry
    · positivity
  refine ⟨C, hC_pos, ?_⟩
  -- main part of the proof: prove integrability by bounding the measure of a sequence of annuli
  refine ⟨Measurable.aestronglyMeasurable <| by fun_prop, ?_⟩
  simp only [HasFiniteIntegral, ← ofReal_norm_eq_enorm, Real.norm_eq_abs, Real.abs_exp]
  -- `⊢ ∫⁻ (a : E), ENNReal.ofReal (rexp (C * ‖a‖ ^ 2)) ∂μ < ⊤`
  let t : ℕ → ℝ := Nat.rec a fun n tn ↦ a + √2 * tn -- t 0 = a ; t (n + 1) = a + √2 * t n
  have ht_succ n : t (n + 1) = a * (1 + √2) * (√2 ^ (n + 2) - 1) := by
    induction n with
    | zero =>
      simp only [zero_add, Nat.rec_one, Nat.ofNat_nonneg, Real.sq_sqrt, t, C]
      ring
    | succ n hn =>
      have : t (n + 1 + 1) = a + √2 * t (n + 1) := rfl
      rw [this, hn]
      simp_rw [← mul_assoc, mul_comm _ a, mul_assoc]
      nth_rw 1 [← mul_one a]
      rw [← mul_add]
      congr
      ring_nf
      congr 2
      rw [add_sub, ← sub_eq_add_neg, Real.sq_sqrt (by positivity)]
      ring
  have ht_succ_le n : t (n + 1) ^ 2 ≤ a ^ 2 * (1 + √2) ^ 2 * 2 ^ (n + 2) := by
    simp_rw [ht_succ, mul_pow, mul_assoc]
    gcongr
    sorry
  have ht_meas_le n : μ {x | t n < ‖x‖} ≤ c * ((1 - c) / c) ^ (2 ^ n) := by
    induction n with
    | zero =>
      simp only [pow_zero, pow_one, C]
      rw [ENNReal.mul_div_cancel hc_pos.ne' hc_lt_top.ne]
      refine le_of_eq ?_
      rw [← prob_compl_eq_one_sub]
      · congr with x
        simp [t]
      · exact measurableSet_le (by fun_prop) (by fun_prop)
    | succ n _ =>
      sorry
  have h_iUnion : (Set.univ : Set E)
      = closedBall 0 (t 0) ∪ ⋃ n, closedBall 0 (t (n + 1)) \ closedBall 0 (t n) := by
    ext x
    simp only [Set.mem_univ, Set.mem_union, Metric.mem_closedBall, dist_zero_right, Set.mem_iUnion,
      Set.mem_diff, not_le, true_iff]
    sorry
  have ht_int_zero : ∫⁻ x in closedBall 0 (t 0), ENNReal.ofReal (rexp (C * ‖x‖ ^ 2)) ∂μ
      ≤ ENNReal.ofReal (rexp (C * t 0 ^ 2)) := by
    calc ∫⁻ x in closedBall 0 (t 0), ENNReal.ofReal (rexp (C * ‖x‖ ^ 2)) ∂μ
    _ ≤ ∫⁻ x in closedBall 0 (t 0), ENNReal.ofReal (rexp (C * t 0 ^ 2)) ∂μ := by
      refine setLIntegral_mono (by fun_prop) fun x hx ↦ ?_
      gcongr
      simpa using hx
    _ ≤ ∫⁻ x, ENNReal.ofReal (rexp (C * t 0 ^ 2)) ∂μ := setLIntegral_le_lintegral _ _
    _ = ENNReal.ofReal (rexp (C * t 0 ^ 2)) := by simp
  have ht_int_le n : ∫⁻ x in (closedBall 0 (t (n + 1)) \ closedBall 0 (t n)),
        .ofReal (rexp (C * ‖x‖ ^ 2)) ∂μ
      ≤ .ofReal (rexp (C * t (n + 1) ^ 2)) * μ {x | t n < ‖x‖} := by
    calc ∫⁻ x in (closedBall 0 (t (n + 1)) \ closedBall 0 (t n)), .ofReal (rexp (C * ‖x‖ ^ 2)) ∂μ
    _ ≤ ∫⁻ x in (closedBall 0 (t (n + 1)) \ closedBall 0 (t n)),
        .ofReal (rexp (C * t (n + 1) ^ 2)) ∂μ := by
      refine setLIntegral_mono (by fun_prop) fun x hx ↦ ?_
      gcongr
      simp only [Set.mem_diff, mem_closedBall, dist_zero_right, not_le] at hx
      exact hx.1
    _ = .ofReal (rexp (C * t (n + 1) ^ 2)) * μ (closedBall 0 (t (n + 1)) \ closedBall 0 (t n)) := by
      simp only [lintegral_const, MeasurableSet.univ, Measure.restrict_apply, Set.univ_inter, C, t]
    _ ≤ .ofReal (rexp (C * t (n + 1) ^ 2)) * μ {x | t n < ‖x‖} := by
      gcongr
      intro x
      simp
  rw [← setLIntegral_univ, h_iUnion, lintegral_union, lintegral_iUnion]
  rotate_left
  · exact fun _ ↦ measurableSet_closedBall.diff measurableSet_closedBall
  · sorry
  · exact MeasurableSet.iUnion fun _ ↦ measurableSet_closedBall.diff measurableSet_closedBall
  · sorry
  refine ENNReal.add_lt_top.mpr ⟨ht_int_zero.trans_lt ENNReal.ofReal_lt_top, ?_⟩
  calc ∑' i, ∫⁻ x in closedBall 0 (t (i + 1)) \ closedBall 0 (t i),
      .ofReal (rexp (C * ‖x‖ ^ 2)) ∂μ
  _ ≤ ∑' i, .ofReal (rexp (C * t (i + 1) ^ 2)) * μ {x | t i < ‖x‖} := by
    gcongr with i
    exact ht_int_le i
  _ ≤ ∑' i, .ofReal (rexp (C * (a ^ 2 * (1 + √2) ^ 2 * 2 ^ (i + 2))))
      * (c * ((1 - c) / c) ^ (2 ^ i)) := by
    gcongr with i
    · exact ht_succ_le i
    · exact ht_meas_le i
  _ = c * ∑' i, .ofReal (rexp (C * (a ^ 2 * (1 + √2) ^ 2 * 2 ^ (i + 2))))
      * ((1 - c) / c) ^ (2 ^ i) := by rw [← ENNReal.tsum_mul_left]; congr with i; ring
  _ = c * ∑' i, .ofReal (rexp ((C * a ^ 2 * (1 + √2) ^ 2 * 4 * 2 ^ i)
      + (- Real.log (c / (1 - c)).toReal * 2 ^ i))) := by
    congr with i
    rw [Real.exp_add, ENNReal.ofReal_mul (by positivity)]
    congr 3
    · ring
    · rw [← Real.log_inv, mul_comm _ (2 ^ i), ← Real.log_rpow, Real.exp_log]
      · sorry
      · simp only [ENNReal.toReal_div, inv_div]
        sorry
      · simp only [ENNReal.toReal_div, inv_div]
        sorry
  _ < ⊤ := by
    refine ENNReal.mul_lt_top hc_lt_top ?_
    sorry

lemma todo_ineq {a b ε : ℝ} (hε : 0 < ε) : 2 * a * b ≤ ε * a ^ 2 + (1 / ε) * b ^ 2 := by
  have h : 2 * (ε * a) * b ≤ (ε * a) ^ 2 + b ^ 2 := two_mul_le_add_sq (ε * a) b
  calc 2 * a * b
  _ = (2 * (ε * a) * b) / ε := by field_simp; ring
  _ ≤ ((ε * a) ^ 2 + b ^ 2) / ε := by gcongr
  _ = ε * a ^ 2 + (1 / ε) * b ^ 2  := by field_simp; ring

/-- **Fernique's theorem** -/
theorem IsGaussian.exists_integrable_exp_sq (μ : Measure E) [IsGaussian μ] :
    ∃ C, 0 < C ∧ Integrable (fun x ↦ rexp (C * ‖x‖ ^ 2)) μ := by
  obtain ⟨C, hC_pos, hC⟩ := exists_integrable_exp_sq_of_isCentered
    (isCentered_conv_map_neg (μ := μ))
  have h_int : ∀ᵐ y ∂μ, Integrable (fun x ↦ rexp (C * ‖x - y‖^2)) μ := by
    -- todo: extract lemma about integrability wrt conv
    unfold Measure.conv at hC
    rw [integrable_map_measure] at hC
    rotate_left
    · exact Measurable.aestronglyMeasurable <| by fun_prop
    · fun_prop
    rw [integrable_prod_iff] at hC
    swap; · exact Measurable.aestronglyMeasurable <| by fun_prop
    replace hC := hC.1
    simp only [Function.comp_apply, ContinuousLinearEquiv.coe_neg] at hC
    filter_upwards [hC] with y hy
    rw [integrable_map_measure] at hy
    rotate_left
    · exact Measurable.aestronglyMeasurable <| by fun_prop
    · exact measurable_id.neg.aemeasurable
    convert hy with x
    simp only [Function.comp_apply, Pi.neg_apply, id_eq, Real.exp_eq_exp, mul_eq_mul_left_iff,
      norm_nonneg, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, pow_left_inj₀]
    left
    simp_rw [← sub_eq_add_neg, norm_sub_rev]
  obtain ⟨y, hy⟩ := h_int.exists
  obtain ⟨C', hC'_pos, hC'_lt⟩ : ∃ C', 0 < C' ∧ C' < C := ⟨C / 2, by positivity, by simp [hC_pos]⟩
  refine ⟨C', hC'_pos, ?_⟩
  let ε := (C - C') / C'
  have hε : 0 < ε := div_pos (by rwa [sub_pos]) (by positivity)
  suffices ∀ x, rexp (C' * ‖x‖ ^ 2) ≤ rexp (C/ε * ‖y‖ ^ 2) * rexp (C * ‖x - y‖ ^ 2) by
    refine integrable_of_le_of_le (g₁ := 0)
      (g₂ := fun x ↦ rexp (C/ε * ‖y‖ ^ 2) * rexp (C * ‖x - y‖ ^ 2)) ?_ ?_ ?_
      (integrable_const _) (hy.const_mul _)
    · exact Measurable.aestronglyMeasurable <| by fun_prop
    · exact ae_of_all _ fun _ ↦ by positivity
    · exact ae_of_all _ this
  intro x
  rw [← Real.exp_add]
  gcongr
  have h_le ε' (hε' : 0 < ε') : ‖x‖ ^ 2 ≤ (1 + ε') * ‖x - y‖ ^ 2 + (1 + 1 / ε') * ‖y‖ ^ 2 := by
    calc ‖x‖ ^ 2
    _ = ‖x - y + y‖ ^ 2 := by simp
    _ ≤ (‖x - y‖  + ‖y‖) ^ 2 := by gcongr; exact norm_add_le (x - y) y
    _ = ‖x - y‖ ^ 2 + ‖y‖ ^ 2 + 2 * ‖x - y‖ * ‖y‖ := by ring
    _ ≤ ‖x - y‖ ^ 2 + ‖y‖ ^ 2 + ε' * ‖x - y‖ ^ 2 + (1 / ε') * ‖y‖ ^ 2 := by
      simp_rw [add_assoc]
      gcongr
      exact todo_ineq (by positivity)
    _ = (1 + ε') * ‖x - y‖ ^ 2 + (1 + 1 / ε') * ‖y‖ ^ 2 := by ring
  specialize h_le ε hε
  calc C' * ‖x‖ ^ 2
  _ ≤ C' * ((1 + ε) * ‖x - y‖ ^ 2 + (1 + 1 / ε) * ‖y‖ ^ 2) := by gcongr
  _ = (C' * (1 + 1 / ε)) * ‖y‖ ^ 2 + (C' * (1 + ε)) * ‖x - y‖ ^ 2 := by ring
  _ = C / ε * ‖y‖ ^ 2 + C * ‖x - y‖ ^ 2 := by
    unfold ε
    congr 2
    · simp only [one_div, inv_div]
      rw [one_add_div (by rw [sub_ne_zero]; exact hC'_lt.ne'), div_div_eq_mul_div]
      simp only [sub_add_cancel]
      ring
    · rw [one_add_div (by positivity)]
      simp only [add_sub_cancel]
      rw [mul_div_cancel₀ _ (by positivity)]

lemma IsGaussian.memLp_id (μ : Measure E) [IsGaussian μ] (p : ℝ≥0∞) (hp : p ≠ ∞) :
    MemLp id p μ := by
  suffices MemLp (fun x ↦ ‖x‖ ^ 2) (p / 2) μ by
    rw [← memLp_norm_rpow_iff (q := 2) _ (by simp) (by simp)]
    · simpa using this
    · exact Measurable.aestronglyMeasurable <| by fun_prop
  lift p to ℝ≥0 using hp
  convert memLp_of_mem_interior_integrableExpSet ?_ (p / 2)
  · simp
  obtain ⟨C, hC_pos, hC⟩ := exists_integrable_exp_sq μ
  have hC_neg : Integrable (fun x ↦ rexp (-C * ‖x‖ ^ 2)) μ := by -- `-C` could be any negative
    refine integrable_of_le_of_le (g₁ := 0) (g₂ := 1) ?_ ?_ ?_
      (integrable_const _) (integrable_const _)
    · exact Measurable.aestronglyMeasurable <| by fun_prop
    · exact ae_of_all _ fun _ ↦ by positivity
    · refine ae_of_all _ fun x ↦ ?_
      simp only [neg_mul, Pi.one_apply, Real.exp_le_one_iff, Left.neg_nonpos_iff]
      positivity
  have h_subset : Set.Ioo (-C) C ⊆ interior (integrableExpSet (fun x ↦ ‖x‖ ^ 2) μ) := by
    rw [IsOpen.subset_interior_iff isOpen_Ioo]
    exact fun x hx ↦ integrable_exp_mul_of_le_of_le hC_neg hC hx.1.le hx.2.le
  exact h_subset ⟨by simp [hC_pos], hC_pos⟩

end Fernique

section ToLp

variable {p : ℝ≥0∞} [SecondCountableTopology E] [CompleteSpace E]

lemma norm_toLpₗ_le (μ : Measure E) [IsGaussian μ] (L : E →L[ℝ] ℝ) (hp : p ≠ 0) (hp_top : p ≠ ∞) :
    ‖L.toLpₗ μ p hp_top‖ ≤ ‖L‖ * (eLpNorm id p μ).toReal := by
  have h0 : 0 < p.toReal := by simp [ENNReal.toReal_pos_iff, pos_iff_ne_zero, hp, hp_top.lt_top]
  suffices ‖L.toLpₗ μ p hp_top‖
      ≤ (‖L‖ₑ ^ p.toReal * ∫⁻ x, ‖x‖ₑ ^ p.toReal ∂μ).toReal ^ p.toReal⁻¹ by
    refine this.trans_eq ?_
    simp only [ENNReal.toReal_mul]
    rw [← ENNReal.toReal_rpow, Real.mul_rpow (by positivity) (by positivity),
      ← Real.rpow_mul (by positivity), mul_inv_cancel₀ h0.ne', Real.rpow_one, toReal_enorm]
    rw [eLpNorm_eq_lintegral_rpow_enorm (by simp [hp]) hp_top, ENNReal.toReal_rpow]
    simp
  rw [ContinuousLinearMap.toLpₗ_apply, Lp.norm_toLp,
    eLpNorm_eq_lintegral_rpow_enorm (by simp [hp]) hp_top]
  simp only [ENNReal.toReal_ofNat, ENNReal.rpow_ofNat, one_div]
  refine ENNReal.toReal_le_of_le_ofReal (by positivity) ?_
  suffices ∫⁻ x, ‖L x‖ₑ ^ p.toReal ∂μ ≤ ‖L‖ₑ ^ p.toReal * ∫⁻ x, ‖x‖ₑ ^ p.toReal ∂μ by
    rw [← ENNReal.ofReal_rpow_of_nonneg (by positivity) (by positivity)]
    gcongr
    rwa [ENNReal.ofReal_toReal]
    refine ENNReal.mul_ne_top (by simp) ?_
    have h := (IsGaussian.memLp_id μ p hp_top).eLpNorm_ne_top
    rw [eLpNorm_eq_lintegral_rpow_enorm (by simp [hp]) hp_top] at h
    simpa [h0] using h
  calc ∫⁻ x, ‖L x‖ₑ ^ p.toReal ∂μ
  _ ≤ ∫⁻ x, ‖L‖ₑ ^ p.toReal * ‖x‖ₑ ^ p.toReal ∂μ := by
    refine lintegral_mono fun x ↦ ?_
    rw [← ENNReal.mul_rpow_of_nonneg]
    swap; · positivity
    gcongr
    simp_rw [← ofReal_norm]
    rw [← ENNReal.ofReal_mul (by positivity)]
    gcongr
    exact L.le_opNorm x
  _ = ‖L‖ₑ ^ p.toReal * ∫⁻ x, ‖x‖ₑ ^ p.toReal ∂μ := by rw [lintegral_const_mul]; fun_prop

/-- `MemLp.toLp` as a `ContinuousLinearMap` from the continuous linear maps. -/
def ContinuousLinearMap.toLp (μ : Measure E) [IsGaussian μ] (p : ℝ≥0∞) [Fact (1 ≤ p)]
    (hp : p ≠ ∞) :
    (E →L[ℝ] ℝ) →L[ℝ] Lp ℝ p μ where
  toLinearMap := ContinuousLinearMap.toLpₗ μ p hp
  cont := by
    refine LinearMap.continuous_of_locally_bounded _ fun s hs ↦ ?_
    rw [image_isVonNBounded_iff]
    simp_rw [isVonNBounded_iff'] at hs
    obtain ⟨r, hxr⟩ := hs
    refine ⟨r * (eLpNorm id p μ).toReal, fun L hLs ↦ ?_⟩
    specialize hxr L hLs
    have hp_ne : p ≠ 0 := by
      have : 1 ≤ p := Fact.out
      positivity
    refine (norm_toLpₗ_le μ L hp_ne hp).trans ?_
    gcongr

@[simp]
lemma ContinuousLinearMap.toLp_apply {μ : Measure E} [IsGaussian μ] (L : E →L[ℝ] ℝ)
    [Fact (1 ≤ p)] (hp : p ≠ ∞) :
    L.toLp μ p hp = MemLp.toLp L (IsGaussian.memLp_continuousLinearMap μ L p hp) := rfl

end ToLp

section Mean

lemma IsGaussian.integral_continuousLinearMap [SecondCountableTopology E] [CompleteSpace E]
    {μ : Measure E} [IsGaussian μ] (L : E →L[ℝ] ℝ) :
    μ[L] = L (∫ x, x ∂μ) := by
  have h_Lp := IsGaussian.memLp_id μ 1 (by simp)
  have h := L.integral_comp_L1_comm (h_Lp.toLp id)
  refine (trans ?_ h).trans ?_
  · refine integral_congr_ae ?_
    filter_upwards [MemLp.coeFn_toLp h_Lp] with x hx
    rw [hx, id_eq]
  · congr 1
    refine integral_congr_ae ?_
    filter_upwards [MemLp.coeFn_toLp h_Lp] with x hx
    rw [hx, id_eq]

end Mean

section Covariance

variable [SecondCountableTopology E] [CompleteSpace E]

-- todo: this is the right def only for centered gaussian measures
/-- Covariance operator of a Gaussian measure. -/
noncomputable
def covarianceOperator (μ : Measure E) [IsGaussian μ] : (E →L[ℝ] ℝ) →L[ℝ] (E →L[ℝ] ℝ) →L[ℝ] ℝ :=
  ContinuousLinearMap.bilinearComp (continuousBilinFormOfInner (E := Lp ℝ 2 μ))
    (ContinuousLinearMap.toLp μ 2 (by simp)) (ContinuousLinearMap.toLp μ 2 (by simp))

lemma covarianceOperator_apply {μ : Measure E} [IsGaussian μ] (L₁ L₂ : E →L[ℝ] ℝ) :
    covarianceOperator μ L₁ L₂ = ∫ x, L₁ x * L₂ x ∂μ := by
  have : Fact (1 ≤ 2) := ⟨by simp⟩
  simp only [covarianceOperator, ContinuousLinearMap.bilinearComp_apply,
    ContinuousLinearMap.toLp_apply,
    continuousBilinFormOfInner_apply, L2.inner_def,
    RCLike.inner_apply, conj_trivial]
  refine integral_congr_ae ?_
  filter_upwards [MemLp.coeFn_toLp (IsGaussian.memLp_continuousLinearMap μ L₁ 2 (by simp)),
    MemLp.coeFn_toLp (IsGaussian.memLp_continuousLinearMap μ L₂ 2 (by simp))] with x hxL₁ hxL₂
  rw [hxL₁, hxL₂, mul_comm]

lemma norm_covarianceOperator_le {μ : Measure E} [IsGaussian μ] (L₁ L₂ : E →L[ℝ] ℝ) :
    ‖covarianceOperator μ L₁ L₂‖ ≤ ‖L₁‖ * ‖L₂‖ * ∫ x, ‖x‖ ^ 2 ∂μ := by
  calc ‖covarianceOperator μ L₁ L₂‖
  _ = ‖∫ x, L₁ x * L₂ x ∂μ‖ := by rw [covarianceOperator_apply]
  _ ≤ ∫ x, ‖L₁ x‖ * ‖L₂ x‖ ∂μ := (norm_integral_le_integral_norm _).trans (by simp)
  _ ≤ ∫ x, ‖L₁‖ * ‖x‖ * ‖L₂‖ * ‖x‖ ∂μ := by
    refine integral_mono_ae ?_ ?_ (ae_of_all _ fun x ↦ ?_)
    · simp_rw [← norm_mul]
      exact (MemLp.integrable_mul (IsGaussian.memLp_continuousLinearMap μ L₁ 2 (by simp))
        (IsGaussian.memLp_continuousLinearMap μ L₂ 2 (by simp))).norm
    · simp_rw [mul_assoc]
      refine Integrable.const_mul ?_ _
      simp_rw [← mul_assoc, mul_comm _ (‖L₂‖), mul_assoc, ← pow_two]
      refine Integrable.const_mul ?_ _
      exact (IsGaussian.memLp_id μ 2 (by simp)).integrable_norm_pow (by simp)
    · simp only
      rw [mul_assoc]
      gcongr
      · exact ContinuousLinearMap.le_opNorm L₁ x
      · exact ContinuousLinearMap.le_opNorm L₂ x
  _ = ‖L₁‖ * ‖L₂‖ * ∫ x, ‖x‖ ^ 2 ∂μ := by
    rw [← integral_mul_left]
    congr with x
    ring

lemma norm_covarianceOperator_le' {μ : Measure E} [IsGaussian μ] (L₁ L₂ : E →L[ℝ] ℝ) :
    ‖covarianceOperator μ L₁ L₂‖ ≤ ‖L₁‖ * ‖L₂‖ * (eLpNorm id 2 μ).toReal ^ 2 := by
  calc ‖covarianceOperator μ L₁ L₂‖
  _ ≤ ‖L₁‖ * ‖L₂‖ * ∫ x, ‖x‖ ^ 2 ∂μ := norm_covarianceOperator_le _ _
  _ = ‖L₁‖ * ‖L₂‖ * (eLpNorm id 2 μ).toReal ^ 2 := by
    congr
    have h := pow_toReal_eLpNorm (IsGaussian.memLp_id μ 2 (by simp)) (by simp)
    simpa only [ENNReal.ofReal_ofNat, Real.rpow_two, id_eq] using h.symm

end Covariance

end ProbabilityTheory
