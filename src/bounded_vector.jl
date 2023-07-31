## --------------  BoundedVector

# """
# 	$(SIGNATURES)

# Initialize the `ParamVector`. Requires `dxV` to be set.
# Note that bounds on `dxV` must be between 0 and 1.
# This is called after the `BoundedVector` has been constructed with an empty `ParamVector` but with the values of the field `dxV` set to reasonable defaults.

# # Example
# ```
# dxV = [0.3, 0.2, 0.8];
# b = BoundedVector(objId, ParamVector(objId), true, 1.0, 2.0, dxV);
# set_pvector!(b; description = "Gradient", symbol = "g(x)");
# ```
# """
# function set_pvector!(iv :: BoundedVector{T1};
#     description = "Increments", 
#     symbol = "dxV", 
#     isCalibrated :: Bool = true) where T1
    
#     defaultValueV = iv.dxV;
#     n = length(defaultValueV);
#     p = make_param(:dxV, description, symbol, defaultValueV, defaultValueV, 
#         zeros(T1, n), ones(T1, n), isCalibrated);
#     iv.pvec = ParamVector(iv.objId, [p]);
#     return nothing
# end

# is_increasing(iv :: BoundedVector{T1}) where T1 = (iv.increasing == :increasing);
# is_decreasing(iv :: BoundedVector{T1}) where T1 = (iv.increasing == :decreasing);
# is_nonmonotone(iv :: BoundedVector{T1}) where T1 = (iv.increasing == :nonmonotone);
# # Bounds for the user facing values.
# # value_lb(iv :: BoundedVector{T1}) where T1 = iv.lb;
# # value_ub(iv :: BoundedVector{T1}) where T1 = iv.ub;
# Base.length(iv :: BoundedVector{T1}) where T1 =  Base.length(iv.dxV);

# # Scalar bounds across all elements (user facing)
# scalar_lb(iv :: BoundedVector{T1}) where T1 = iv.lb;
# scalar_ub(iv :: BoundedVector{T1}) where T1 = iv.ub;


# function calibrate_values!(iv :: BoundedVector{T1}) where T1
#     calibrate!(iv, :dxV);
# end


# """
# 	$(SIGNATURES)

# Switches calibration toggle off. Sets values and default values everywhere. The end result is a `BoundedVector` with fixed (not calibrated) increments that result in values of `valueV`.

# `valueV` is not user facing.
# """
# function fix_values!(iv :: BoundedVector{T1}, 
#     valueV :: AbstractVector{T1}) where T1

#     p = retrieve(iv.pvec, :dxV);
#     set_calibrated_value!(p, valueV);
#     set_default_value!(p, valueV);
#     fix!(p);
#     dxV = values_to_dx(iv, valueV);
#     iv.dxV = dxV;
# end


# """
# 	$(SIGNATURES)

# Returns all values of a `BoundedVector`. User facing.
# """
# function values(iv :: BoundedVector{T1}) where T1
#     valueV = dx_to_values(iv, iv.dxV);
#     return valueV
# end

# """
# 	$(SIGNATURES)

# Returns a subset of the values of a `BoundedVector`.
# """
# values(iv :: BoundedVector{T1}, idx) where T1 =
#     values(iv)[idx];

# pvalue(iv :: BoundedVector{T1}) where T1 = values(iv);




# """
# 	$(SIGNATURES)

# Set the default values of a `BoundedVector`.
# """
# function set_default_value!(iv :: BoundedVector{T1}, 
#     valueV :: AbstractVector{T1}) where T1

#     dxV = values_to_dx(iv, valueV);
#     p = retrieve(iv.pvec, :dxV);
#     set_default_value!(p, valueV)
# end




# function param_table(iv :: BoundedVector{T1}, isCalibrated :: Bool) where T1
#     p = retrieve(iv.pvec, :dxV);
#     if isCalibrated == is_calibrated(p)
#         pt = ParamTable(1);
#         set_row!(pt, 1, string(p.name), p.symbol, p.description, 
#             formatted_value(values(iv)));
#     else
#         pt = nothing;
#     end
#     return pt
# end

# ----------------