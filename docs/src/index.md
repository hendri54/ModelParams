# ModelParams

The purpose of `ModelParams` is to offer an automated workflow for handling model objects and their potentially calibrated or estimated parameters.

```@meta
CurrentModule = ModelParams
```

## Background

The target audience consists mainly of economists who calibrate or estimate structural models.

One may think of a model as a collection of model objects, such as utility functions, production functions, etc. Model objects may contain nested model objects. For example, a `household` model object may contain a utility function.

Typically, a researcher will calibrate many model versions that differ in:

* functional forms (e.g., log utility versus CARA)
* which parameters are fixed versus calibrated
* switches (e.g., does the model have preference shocks? How many types of households are there?)

The challenge is then to keep track of:

* which fixed parameters need to be set?
* which parameters need to be calibrated?
* where to put the calibrated parameter values in the model?

In addition, one needs to keep track of which data moments are used in the calibration and what the associated model moments are.

All of this is automated in `ModelParams`.

To see in action how this works, see the `SampleModel` repo in my `github` account.


## Parameters: [`Param`](@ref)

Model parameters that are either calibrated or fixed are defined in [`Param`](@ref) objects. These encode default values (used when not calibrated), bounds, Latex symbols, and descriptions.

Vectors that are increasing are encoded in an [`IncreasingVector`](@ref).

```@docs
IncreasingVector
values
```

[`BoundedVector`](@ref) encodes a vector that is monotone and bounded.

```@docs
BoundedVector
set_pvector!
set_default_value!
fix_values!
```

## Parameter Vectors: `ParamVector`

The second key concept is a [`ParamVector`](@ref). It collects all potentially calibrated model parameters, represented as [`Param`](@ref) objects.

For convenience and performance, a `ModelObject` has a field for each `Param`. The field values should never be written to "by hand." Functions are provided that sync fixed and calibrated parameters from the `ParamVector`.

To enable unambiguous matching of `ParamVector`s to child objects, each `ParamVector` contains the object's `ObjectId`.

```@docs
ParamVector
Param
```

Useful access routines for `ParamVectors` include:

```@docs
retrieve
append!
remove!
replace!
change_calibration_status!
change_value!
```

## Vectors of `ParamVector`

These are used when all the `ParamVector`s from a `ModelObject` are collected.

```@docs
find_pvector
```

## Calibrating a model

The workflow is implemented and tested in the `SampleModel` repo.

1. Initialize a model object, including its child objects. E.g., `SampleModel.Model`.
2. Write the code and solves the model and computes any desired statistics. This part is not affected by anything related to `ModelParams` because the potentially calibrated parameters are stored inside each object and synced with the `ParamVector`s.
3. Write a deviation function that accepts a vector of calibrated parameters as an input. Call [`set_params_from_guess!`](@ref) to copy the parameter values from the vector into the various model objects.
4. In the calibration function, call [`make_guess`](@ref) to make a vector of parameter values from the parameter values in all of the model objects.
5. Report the calibrated and fixed parameters using [`report_params`](@ref)

```@docs
set_params_from_guess!
make_guess
report_params
param_tables
```


-----------