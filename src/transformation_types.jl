## ----------  Parameter Transformations

"""
	ParamTransformation

Abstract type for transforming parameters into bounded values (guesses) and reverse.

Define a concrete type with its own parameters and method
```julia
    transform_param(tr :: ParamTransformation, p :: Param)
```
"""
abstract type ParamTransformation{F1 <: AbstractFloat} end


"""
	LinearTransformation

Default linear transformation into default interval [1, 2].

Keyword constructor is provided.
"""
@with_kw struct LinearTransformation{F1 <: AbstractFloat} <: ParamTransformation{F1}
    lb :: F1 = one(F1)
    ub :: F1 = F1(2.0)
end

# ----------------