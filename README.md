# ModelParams.jl

## Change Log 2023

Feb-6: (v3.0)
- renamed `set_pvalue!` to `set_calibrated_value!`
- renamed `set_value!` to `set_calibrated_value!`
Feb-4:
- removed `CalArray`, which is rarely used and can be replicated with `MParam`
Feb-3:
- removed `lb` and `ub` functions (v2.3)
- removed `calibrated_lb` (not needed).
Feb-2:
- removed `value`; now always use `pvalue`


----------