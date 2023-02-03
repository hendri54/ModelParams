export GroupedVector, make_grouped_vector;

# replace with a generic object that maps `n` param values into `m` values
# see Obsidian notes
# Easiest implementation: store arbitrary meta info inside Param that is used to make the conversion.

param_loc(::GroupedVector{T1}) where T1 = ParamsInObject();
get_pvector(iv :: GroupedVector{T1}) where T1 = 
    ParamVector(iv.objId, [iv.v0, iv.vGroupV]);

Base.length(iv :: GroupedVector) = length(iv.groupCalV);

calibrated_groups(iv :: GroupedVector) = findall(iv.groupCalV);


"""
	$(SIGNATURES)

Constructor for a GroupedVector.

    add validation +++++
"""
function make_grouped_vector(objId, catGroupV, groupCalV, fixedValV;
        lb = 0.0, ub = 0.0,
        v0 = 0.0, v0Lb = 0.0, v0Ub = 0.0, calV0 = true)
    pV0 = init_v0(v0, v0Lb, v0Ub, calV0);
    pVGroupV = init_vgrouped(groupCalV, fixedValV, lb, ub);
    return GroupedVector(objId, catGroupV, groupCalV, fixedValV, pV0, pVGroupV)
end

function init_v0(v0 :: T1, v0Lb, v0Ub, calV0) where T1
    return Param{T1}(:v0, "v0", "v0", v0, v0, v0Lb, v0Ub, calV0)
end

function init_vgrouped(groupCalV, fixedValV :: AbstractVector{T1}, lb, ub) where T1
    nCal = sum(groupCalV);
    if nCal > 0
        idxV = findall(groupCalV);
        ng = length(idxV);
        p = Param{Vector{T1}}(:vGroupV, "vGroupV", "vGroupV", 
            fixedValV[idxV], fixedValV[idxV], fill(lb, ng), fill(ub, ng), true);
    else
        # Not used in this case. Construct a dummy.
        p = Param{Vector{T1}}(:vGroupV, "vGroupV", "vGroupV", lb, lb, lb, ub, false);
    end
    return p
end


"""
	$(SIGNATURES)

Retrieve values of an `GroupedVector`.
"""
function pvalue(iv :: GroupedVector{T1}, idx :: Int) where T1
	v = pvalue(iv.v0);
    for g ∈ groups(iv, idx)
        v += group_value(iv, g);
    end
    return v
end



function group_value(iv :: GroupedVector{T1}, ig) where T1
    if iv.groupCalV[ig]
        idx = cal_group_idx(iv, ig);
        pvalue(iv.vGroupV)[idx];
    else
        return iv.fixedValV[ig];
    end
end

# Index into the `vGroupV` parameter vector.
function cal_group_idx(iv :: GroupedVector, ig)
    if iv.groupCalV[ig]
        idxV = calibrated_groups(iv);
        idx = findfirst(g -> (g == ig), idxV);
        return idx
    else
        return nothing
    end
end


function groups(iv :: GroupedVector{T1}, idx :: Int) where T1
    return iv.catGroupV[idx];
end


# Displays parameters in levels, not as intercept and increments.
# function param_table(iv :: GroupedVector{T1}, 
#         isCalibrated :: Bool) where T1
#     if isCalibrated
#         # This is where we get the description and symbol from
#         p = iv.dxV;
#         pt = ParamTable(1);
#         set_row!(pt, 1, string(p.name), p.symbol, p.description, 
#             formatted_value(values(iv)));
#     else
#         pt = nothing;
#     end
#     return pt
# end

# -----------------