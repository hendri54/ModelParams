## ---------  Scalar map

pvalue(p :: MParam{T1, ScalarMap}) where T1 = only(p.value);
pvalue(p :: MParam{T1, ScalarMap}, j :: Integer) where T1 = only(p.value);
# Not user facing (though the same here).
default_value(p :: MParam{T1, ScalarMap}) where T1 = only(p.defaultValue);

# pvalue(::ScalarMap, p :: MParam) = only(p.value);
# pvalue(::ScalarMap, p :: MParam, j :: Integer) = only(p.value);
# default_value(::ScalarMap, p :: MParam) = only(p.defaultValue);
type_description(::ScalarMap) = "Scalar value";

## ----------  Identity map

pvalue(p :: MParam{T1, IdentityMap}) where T1 = p.value;
pvalue(p :: MParam{T1, IdentityMap}, j) where T1 = p.value[j];
# Not user facing (though the same here).
default_value(p :: MParam{T1, IdentityMap}) where T1 = p.defaultValue;
# pvalue(::IdentityMap, p :: MParam) = p.value;
# pvalue(::IdentityMap, p :: MParam, j) = p.value[j];
# default_value(::IdentityMap, p :: MParam) = p.defaultValue;
type_description(::IdentityMap) = "Array value";


## ----------  Base value and deviations
# one deviation normalized to 1
# When constructing: first element is the base. Others are deviations.

pvalue(p :: MParam{T1, BaseAndDeviationsMap}) where T1 =
    [pvalue(p, j)  for j = 1 : length(p.value)];

pvalue(p :: MParam{T1, BaseAndDeviationsMap}, j) where T1 = 
    base_and_dev_value(p.value, j);

# Not user facing
default_value(p :: MParam{T1, BaseAndDeviationsMap}) where T1 = p.defaultValue;
    # [base_and_dev_value(p.defaultValue, j)  for j = 1 : length(p.defaultValue)];

# pvalue(m :: BaseAndDeviationsMap, p :: MParam) =
#     [pvalue(m, p, j)  for j = 1 : length(p.value)];

# pvalue(m :: BaseAndDeviationsMap, p :: MParam, j) = 
#     base_and_dev_value(p.value, j);

# default_value(m :: BaseAndDeviationsMap, p :: MParam) = 
#     [base_and_dev_value(p.defaultValue, j)  for j = 1 : length(p.defaultValue)];

function base_and_dev_value(valueV, j)
    v = first(valueV);
    (j > 1)  &&  (v += valueV[j]);
    return v
end

type_description(::BaseAndDeviationsMap) = "Base and deviations";


## -----------  Increasing

# Scalar bounds (user facing)
scalar_lb(iMap :: IncreasingMap) = iMap.lb;
scalar_ub(iMap :: IncreasingMap) = iMap.ub;

function pvalue(p :: MParam{T1, IncreasingMap{T2}}) where {T1, T2}
    iMap = pmeta(p); 
    return dx_to_values_increasing(p.value, scalar_lb(iMap), scalar_ub(iMap));
end

pvalue(p :: MParam{T1, IncreasingMap{T2}}, j) where {T1, T2} = 
    pvalue(p)[j];

# Not user facing
function default_value(p :: MParam{T1, IncreasingMap{T2}}) where {T1, T2}
    return p.defaultValue
    # iMap = pmeta(p); 
    # return dx_to_values_increasing(p.defaultValue, scalar_lb(iMap), scalar_ub(iMap));
end

type_description(::IncreasingMap) = "Increasing vector";


## -----------  Decreasing

# Scalar bounds (user facing)
scalar_lb(iMap :: DecreasingMap) = iMap.lb;
scalar_ub(iMap :: DecreasingMap) = iMap.ub;

function pvalue(p :: MParam{T1, DecreasingMap{T2}}) where {T1, T2}
    iMap = pmeta(p);
    return dx_to_values_decreasing(p.value, scalar_lb(iMap), scalar_ub(iMap));
end

pvalue(p :: MParam{T1, DecreasingMap{T2}}, j) where {T1, T2} = 
    pvalue(p)[j];

# Not user facing
function default_value(p :: MParam{T1, DecreasingMap{T2}}) where {T1, T2}
    return p.defaultValue;
    # iMap = pmeta(p);
    # return dx_to_values_decreasing(p.defaultValue, scalar_lb(iMap), scalar_ub(iMap));
end

# pvalue(iMap :: DecreasingMap, p :: MParam) = 
#     dx_to_values_decreasing(p.value, scalar_lb(iMap), scalar_ub(iMap));
# default_value(iMap :: DecreasingMap, p :: MParam) = 
#     dx_to_values_decreasing(p.defaultValue, scalar_lb(iMap), scalar_ub(iMap));
type_description(::DecreasingMap) = "Decreasing vector";


## ----------  Grouped map

function make_test_grouped_map()
    groupV = [2, 1, 2, 1, 3];
    fixedValueV = [missing, 9.5, missing];
    return GroupedMap(groupV, fixedValueV)
end

type_description(m :: GroupedMap) = "Grouped vector";

# Value for each index. User visible
pvalue(p :: MParam{T1, GroupedMap{T2}}) where {T1, T2} = 
    [pvalue(p, j)  for j = 1 : n_values(pmeta(p))];

# Value for one category (index).
function pvalue(p :: MParam{T1, GroupedMap{T2}}, j :: Integer) where {T1, T2}
    m = pmeta(p);
    g = get_group(m, j);
    if group_fixed(m, g)
        v = fixed_value(m, g);
    else
        v = group_calibrated_value(p, g);
    end
    return v
end

# Not user facing.
default_value(p :: MParam{T1, GroupedMap{T1}}) where T1 = p.defaultValue;

# Default value for one group. Nothing if that group is fixed.
function group_default_value(p :: MParam{T1, GroupedMap{T1}}, g) where T1
    m = pmeta(p);
    if group_fixed(m, g)
        return missing
    else
        idx = group_idx(m, g);
        return p.defaultValue[idx];
    end
end


# No of categories (index values). User visible.
n_values(m :: GroupedMap) = length(m.groupV);
get_group(m :: GroupedMap, j) = m.groupV[j];
group_fixed(m :: GroupedMap, g) = !ismissing(fixed_value(m, g));

# Fixed value. Missing if calibrated.
fixed_value(m :: GroupedMap, g) = m.fixedValueV[g];

# Calibrated value for one group. Missing if that group is fixed.
function group_calibrated_value(p :: MParam{T1, GroupedMap{T2}}, g) where {T1, T2}
    m = pmeta(p);
    if group_fixed(m, g)
        return missing
    else
        idx = group_idx(m, g);
        return p.value[idx];
    end
end

# Index into vector of calibrated params (p.value). Nothing if group not calibrated.
function group_idx(m :: GroupedMap, g)
    if group_fixed(m, g)
        return missing;
    else
        return findfirst(x -> x == g, calibrated_groups(m));
    end
end

function calibrated_groups(m :: GroupedMap)
    return findall(ismissing, m.fixedValueV);
end

# ----------------------------