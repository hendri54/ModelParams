## ---------  Scalar map

pvalue(::ScalarMap, p :: MParam) = only(p.value);
pvalue(::ScalarMap, p :: MParam, j :: Integer) = only(p.value);
default_value(::ScalarMap, p :: MParam) = only(p.defaultValue);


## ----------  Identity map

pvalue(::IdentityMap, p :: MParam) = p.value;
pvalue(::IdentityMap, p :: MParam, j) = p.value[j];
default_value(::IdentityMap, p :: MParam) = p.defaultValue;


## ----------  Grouped map

function make_test_grouped_map()
    groupV = [2, 1, 2, 1, 3];
    fixedValueV = [missing, 9.5, missing];
    return GroupedMap(groupV, fixedValueV)
end



# Value for each index. User visible
pvalue(m :: GroupedMap, p :: MParam) = 
    [pvalue(m, p, j)  for j = 1 : n_values(m)];

# Value for one category (index).
function pvalue(m :: GroupedMap, p :: MParam, j :: Integer)
    g = get_group(m, j);
    if group_fixed(m, g)
        v = fixed_value(m, g);
    else
        v = group_calibrated_value(m, p, g);
    end
    return v
end

# Not user facing.
default_value(::GroupedMap, p :: MParam) = p.defaultValue;

# Default value for one group. Nothing if that group is fixed.
function group_default_value(m :: GroupedMap, p :: MParam, g)
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
function group_calibrated_value(m :: GroupedMap, p :: MParam, g)
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