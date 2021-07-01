## ----------  Parameter Transformations

"""
	ParamTransformation

Abstract type for transforming parameters into bounded values (guesses) and reverse.

Define a concrete type with its own parameters and method
```julia
    transform_param(tr :: ParamTransformation, p :: Param)
```
"""
abstract type ParamTransformation{F1 <: Real} end

lb(::ParamTransformation{F1}) where F1 = F1(TransformationLb);
ub(::ParamTransformation{F1}) where F1 = F1(TransformationUb);


"""
	LinearTransformation

Default linear transformation into default interval [1, 2].
`F1` encodes the element type. The bounds are always scalar.
"""
struct LinearTransformation{F1} <: ParamTransformation{F1}
    # lb :: F1 = one(F1)
    # ub :: F1 = F1(2.0)
end


# ----------------