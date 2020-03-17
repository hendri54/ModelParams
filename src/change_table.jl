## ---------  Table that shows how each parameter affects each deviation


"""
	$(SIGNATURES)

Initialize a `ChangeTable` from a [`DevVector`](@ref).
"""
function ChangeTable(d :: DevVector, paramNameV; scalarDev = nothing)
    nParams = length(paramNameV);
    nameV = keys(scalar_dev_dict(d));
    nDev = length(nameV);
    dev0V = zeros(nParams);
    devM = zeros(nDev, nParams);
    scalarDevV = zeros(nParams);
    scalarDev0 = 0.0;
    ct = ChangeTable(paramNameV, nameV, dev0V, devM, scalarDevV, scalarDev0);
    ct.scalarDev0, ct.dev0V = changes_one_param(ct, d; scalarDev = nothing);
    return ct
end

dev_names(ct :: ChangeTable) = ct.devNameV;
param_names(ct :: ChangeTable) = ct.paramNameV;
n_params(ct :: ChangeTable) = length(param_names(ct));
n_devs(ct :: ChangeTable) = length(dev_names(ct));

# Compute changes for one parameter
function changes_one_param(ct :: ChangeTable, d :: DevVector;
    scalarDev = nothing)

    if isnothing(scalarDev)
        scalarDev = scalar_deviation(d);
    end

    devDict = ModelParams.scalar_dev_dict(d);
    devV = zeros(n_devs(ct))
    for (j, key) in enumerate(dev_names(ct))
        devV[j] = devDict[key];
    end
    return scalarDev, devV
end

# Set values for one parameter
function set_param_values!(ct :: ChangeTable, iParam :: Integer, d :: DevVector;
    scalarDev = nothing)

    ct.scalarDevV[iParam], devV = changes_one_param(ct, d; scalarDev = scalarDev);
    ct.devM[:, iParam] = devV;
    return nothing
end


"""
	$(SIGNATURES)

Make a formatted table that shows how each parameter changes each deviation.
Returns header row, header column, table with values (as strings).
"""
function make_table(ct)
    devChangeM = ct.devM .- ct.dev0V;
    dScalarDevV = ct.scalarDevV .- ct.scalarDev0;
    dev0V = [ct.scalarDev0; ct.dev0V];
    # Col 1: initial point
    # Row 1: scalar devs
    valueM = [dev0V  [dScalarDevV';  devChangeM]];
    @assert size(valueM) == (n_devs(ct) + 1,  n_params(ct) + 1)
    valueM = string.(round.(valueM, digits = 3));

    hdColumn = ["Scalar"; string.(dev_names(ct))];

    hdRow = [" ";  "Baseline";  string.(param_names(ct))];
    return  hdRow,  hdColumn,  valueM
end


"""
	$(SIGNATURES)

Show a `ChangeTable` as a `PrettyTable`.
"""
function show_table(ct, io = stdout)
    hdRow, hdColumn, valueM = make_table(ct);
    pretty_table(io, [hdColumn  valueM],  hdRow);
end    


"""
	$(SIGNATURES)

Find parameters where scalar deviation changes less than `rtol`.
"""
function find_unchanged_devs(ct :: ChangeTable; rtol = 0.01)
    relDevV = ct.scalarDevV ./ ct.scalarDev0 .- 1;
    return param_names(ct)[relDevV .< rtol]
end

# ---------------