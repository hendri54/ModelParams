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

The challenge is then to keep track of 

* which fixed parameters need to be set?
* which parameters need to be calibrated?
* where to put the calibrated parameter values in the model?

In addition, one needs to keep track of which data moments are used in the calibration and what the associated model moments are.

All of this is automated in `ModelParams`.

To see in action how this works, see the `SampleModel` repo in my `github` account.

## ModelObject

The abstract type [`ModelObject`](@ref) determines which objects the methods of `ModelParams` work on. Objects that are not subtypes of [`ModelObject`](@ref) are ignored.

Each `ModelObject` has a unique [`ObjectId`](@ref). It identifies where each object is located in the model hierarchy. The `ObjectId` keeps track of the parent object and of an index. The index is used when a vector of objects is created. For example, if we have several household types, their `ObjectId`s might be `:hh1`, `:hh2`, etc. 

## ParamVector

The second key concept is a [`ParamVector`](@ref). It collects all potentially calibrated model parameters, represented as [`Param`](@ref) objects.

## Calibrating a model

The workflow is implemented and tested in the `SampleModel` repo.

1. Initialize a model object, including its child objects. E.g., `SampleModel.Model`.
2. Write the code and solves the model and computes any desired statistics. This part is not affected by anything related to `ModelParams` because the potentially calibrated parameters are stored inside each object and synced with the `ParamVector`s.
3. Write a deviation function that accepts a vector of calibrated parameters as an input. Call [`set_params_from_guess!`](@ref) to copy the parameter values from the vector into the various model objects.
4. In the calibration function, call [`make_guess`](@ref) to make a vector of parameter values from the parameter values in all of the model objects.


## Data moments and deviations

The [`AbstractDevation`](@ref) object is designed to keep track of target moments for the calibration. It also stores the corresponding model moments and can therefore compute and display measures of model fit.

There are several types of `AbstractDeviation`s:

1. [`Deviation`](@ref) is the default type. It holds `Array`s of `Float64`s of any dimension.
2. [`ScalarDeviation`](@ref) holds scalar moments.
3. [`RegressionDeviation`](@ref) handles the case where the target moments are represented by regression coefficients and their standard errors.


# Function Reference

```@autodocs
Modules = [ModelParams]
```