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
