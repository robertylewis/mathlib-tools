/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Johannes Hölzl

Quotient construction on modules
-/

import linear_algebra.basic

universes u v w
variables {α : Type u} {β : Type v} {γ : Type w}
variables [ring α] [module α β] [module α γ] (s : set β) [is_submodule s]
include α

open function

namespace is_submodule

def quotient_rel : setoid β :=
⟨λb₁ b₂, b₁ - b₂ ∈ s,
  assume b, by simp [zero],
  assume b₁ b₂ hb,
  have - (b₁ - b₂) ∈ s, from is_submodule.neg hb,
  by simpa using this,
  assume b₁ b₂ b₃ hb₁₂ hb₂₃,
  have (b₁ - b₂) + (b₂ - b₃) ∈ s, from add hb₁₂ hb₂₃,
  by simpa using this⟩

end is_submodule

namespace quotient_module
open is_submodule

section
variable (β)
/-- Quotient module. `quotient β s` is the quotient of the module `β` by the submodule `s`. -/
def quotient (s : set β) [is_submodule s] : Type v := quotient (quotient_rel s)
end

local notation ` Q ` := quotient β s

def mk {s : set β} [is_submodule s] : β → quotient β s := quotient.mk'

instance {α} {β} {r : ring α} [module α β] (s : set β) [is_submodule s] : has_coe β (quotient β s) := ⟨mk⟩

protected def eq {s : set β} [is_submodule s] {a b : β} : (a : quotient β s) = b ↔ a - b ∈ s :=
quotient.eq'

instance quotient.has_zero : has_zero Q := ⟨mk 0⟩

instance quotient.has_add : has_add Q :=
⟨λa b, quotient.lift_on₂' a b (λa b, ((a + b : β ) : Q)) $
  assume a₁ a₂ b₁ b₂ (h₁ : a₁ - b₁ ∈ s) (h₂ : a₂ - b₂ ∈ s),
  quotient.sound' $
  have (a₁ - b₁) + (a₂ - b₂) ∈ s, from add h₁ h₂,
  show (a₁ + a₂) - (b₁ + b₂) ∈ s, by simpa⟩

instance quotient.has_neg : has_neg Q :=
⟨λa, quotient.lift_on' a (λa, mk (- a)) $ assume a b (h : a - b ∈ s),
  quotient.sound' $
  have - (a - b) ∈ s, from neg h,
  show (-a) - (-b) ∈ s, by simpa⟩

instance quotient.add_comm_group : add_comm_group Q :=
{ zero := 0,
  add  := (+),
  neg  := has_neg.neg,
  add_assoc    := assume a b c, quotient.induction_on₃' a b c $
    assume a b c, quotient_module.eq.2 $
    by simp [is_submodule.zero],
  add_comm     := assume a b, quotient.induction_on₂' a b $
    assume a b, quotient_module.eq.2 $ by simp [is_submodule.zero],
  add_zero     := assume a, quotient.induction_on' a $
    assume a, quotient_module.eq.2 $ by simp [is_submodule.zero],
  zero_add     := assume a, quotient.induction_on' a $
    assume a, quotient_module.eq.2 $ by simp [is_submodule.zero],
  add_left_neg := assume a, quotient.induction_on' a $
    assume a, quotient_module.eq.2 $ by simp [is_submodule.zero] }

instance quotient.has_scalar : has_scalar α Q :=
⟨λa b, quotient.lift_on' b (λb, ((a • b : β) : Q)) $ assume b₁ b₂ (h : b₁ - b₂ ∈ s),
  quotient.sound' $
  have a • (b₁ - b₂) ∈ s, from is_submodule.smul a h,
  show a • b₁ - a • b₂ ∈ s, by simpa [smul_add]⟩

instance quotient.module : module α Q :=
{ smul := (•),
  one_smul     := assume a, quotient.induction_on' a $
    assume a, quotient_module.eq.2 $ by simp [is_submodule.zero],
  mul_smul     := assume a b c, quotient.induction_on' c $
    assume c, quotient_module.eq.2 $ by simp [is_submodule.zero, mul_smul],
  smul_add     := assume a b c, quotient.induction_on₂' b c $
    assume b c, quotient_module.eq.2 $ by simp [is_submodule.zero, smul_add],
  add_smul     := assume a b c, quotient.induction_on' c $
    assume c, quotient_module.eq.2 $ by simp [is_submodule.zero, add_smul], }

@[simp] lemma coe_zero : ((0 : β) : Q) = 0 := rfl
@[simp] lemma coe_smul (a : α) (b : β) : ((a • b : β) : Q) = a • b := rfl
@[simp] lemma coe_add (a b : β) : ((a + b : β) : Q) = a + b := rfl

instance quotient.inhabited : inhabited Q := ⟨0⟩

lemma is_linear_map_quotient_mk : @is_linear_map _ _ Q _ _ _ (λb, mk b : β → Q) :=
by refine {..}; intros; refl

def quotient.lift {f : β → γ} (hf : is_linear_map f) (h : ∀x∈s, f x = 0) (b : Q) : γ :=
b.lift_on' f $ assume a b (hab : a - b ∈ s),
  have f a - f b = 0, by rw [←hf.sub]; exact h _ hab,
  show f a = f b, from eq_of_sub_eq_zero this

@[simp] lemma quotient.lift_mk {f : β → γ} (hf : is_linear_map f) (h : ∀x∈s, f x = 0) (b : β) :
  quotient.lift s hf h (b : Q) = f b :=
rfl

lemma is_linear_map_quotient_lift {f : β → γ} {h : ∀x y, x - y ∈ s → f x = f y}
  (hf : is_linear_map f) : is_linear_map (λq:Q, quotient.lift_on' q f h) :=
⟨assume b₁ b₂, quotient.induction_on₂' b₁ b₂ $ assume b₁ b₂, hf.add b₁ b₂,
  assume a b, quotient.induction_on' b $ assume b, hf.smul a b⟩

lemma quotient.injective_lift [is_submodule s] {f : β → γ} (hf : is_linear_map f)
  (hs : s = {x | f x = 0}) : injective (quotient.lift s hf $ le_of_eq hs) :=
assume a b, quotient.induction_on₂' a b $ assume a b (h : f a = f b), quotient.sound' $
  have f (a - b) = 0, by rw [hf.sub]; simp [h],
  show a - b ∈ s, from hs.symm ▸ this

lemma quotient.exists_rep {s : set β} [is_submodule s] : ∀ q : quotient β s, ∃ b : β, mk b = q :=
@_root_.quotient.exists_rep _ (quotient_rel s)

end quotient_module
