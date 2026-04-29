# ModelParams.jl

## Change Log 2026

Apr 13
- dev EconometricsLH (to update CategoricalArrays) (v5.1)

## Change Log 2025

July 12

- `set_params_from_guess!` checks that guess has correct length.

July 2

- removed CalVector. Important reason: The set of potentially calibrated parameters must be fixed. Otherwise, setting default values, calibrated values, and copying params from one object to another is not possible.

June 30

- added CalVector (v5)

## Change Log 2024

July 9
- replaced Formatting.jl

## Change Log 2023

July-31
- removed BoundedVector
- ensured that `pvalue`  returns fixed value for all types when not calibrated.
July-18
- `default_value` not user facing for all param types. Documented distinction between user facing and internal values everywhere.
Jun-21:
- Changed `pvalue` functions to directly dispatch on `pMap` type. To make type stable.
Apr-11:
- DecreasingMap (v3.0.1)
Feb-10:
- IncreasingMap
- `short_description`
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

## Tasks

`GroupedMap`
need a convenient way of defining a map where one scalar is calibrated and applied to all group entries

`IncreasingMap`
Need a convenient way of constructing an `MParam` using it based on target values in levels.

----------