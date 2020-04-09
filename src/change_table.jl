## ---------  Table that shows how each parameter affects each deviation


"""
	$(SIGNATURES)

Initialize a `ChangeTable` from a [`DevVector`](@ref).

# Arguments
- `d`: the `DevVector`
- `paramNameV`: the names of all parameters to be displayed
- `scalarDev`: the scalar deviation for the initial point
"""
function ChangeTable(d :: DevVector, paramNameV; scalarDev = nothing)
    nParams = length(paramNameV);
    devNameV = collect(keys(scalar_dev_dict(d)));
    nDev = length(devNameV);
    dev0V = zeros(nParams);
    devM = zeros(nDev, nParams);
    scalarDevV = zeros(nParams);
    scalarDev0 = 0.0;
    ct = ChangeTable(paramNameV, devNameV, dev0V, devM, scalarDevV, scalarDev0);
    ct.scalarDev0, ct.dev0V = changes_one_param(ct, d; scalarDev = nothing);
    return ct
end

dev_names(ct :: ChangeTable) = ct.devNameV;
param_names(ct :: ChangeTable) = ct.paramNameV;
n_params(ct :: ChangeTable) = length(param_names(ct));
n_devs(ct :: ChangeTable) = length(dev_names(ct));


function validate_change_table(ct :: ChangeTable)
    isValid = true;
    if !isequal(size(ct.devM),  (n_devs(ct), n_params(ct)))
        isValid = false;
        @warn "Invalid size of devation matrix: $(size(ct.devM))"
    end
    return isValid
end


# Compute changes for one parameter
function changes_one_param(ct :: ChangeTable, d :: DevVector;
    scalarDev = nothing)

    devDict = ModelParams.scalar_dev_dict(d);
    devV = zeros(n_devs(ct))
    for (j, key) in enumerate(dev_names(ct))
        devV[j] = devDict[key];
    end

    if isnothing(scalarDev)
        scalarDev = scalar_deviation(d);
        @assert isapprox(scalarDev, sum(devV), atol = 1e-3)
    end

    return scalarDev, devV
end


"""
	$(SIGNATURES)

Set values for one parameter. After the `ChangeTable` has been initialized, the model is solved with a different values for paramete `iParam`. This results in the deviations given by `d`.
"""
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
function make_table(ct :: ChangeTable)
    @assert validate_change_table(ct)
    # The `ChangeTable` stores levels. We want differences relative to initial point.
    devChangeM = ct.devM .- ct.dev0V;
    dScalarDevV = ct.scalarDevV .- ct.scalarDev0;
    # Col 1: initial point
    dev0V = [ct.scalarDev0; ct.dev0V];
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
function show_table(ct :: ChangeTable, io = stdout)
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


"""
	$(SIGNATURES)

Make table with largest individual deviation changes for each parameter.
Rows are parameters.
Can also show the transposed version: the `n` parameters with the largest effects on each devation.
"""
function make_largest_change_table(ct :: ChangeTable, n :: Integer; transposed :: Bool = false)
    @assert validate_change_table(ct)

    if transposed
        devChangeM = (ct.devM .- ct.dev0V);
        rowNameV = dev_names(ct);
        colNameV = string.(param_names(ct));
    else
        # Deviation changes by [parameter, deviation]
        devChangeM = (ct.devM .- ct.dev0V)';
        colNameV = dev_names(ct);
        rowNameV = string.(param_names(ct));
    end
    nRows = length(rowNameV);
    nCols = length(colNameV);
    @check n <= nCols
    @check isequal((nRows, nCols),  size(devChangeM))

    # Records `n` largest deviation changes for each column of `devChangeM`
    changeM = Matrix{String}(undef, nRows, n);
    for j = 1 : nRows
        # Largest deviation changes
        idxV = sortperm(abs.(devChangeM[j,:]), rev = true);
        for k = 1 : n
            idx = idxV[k];
            devChange = round(devChangeM[j, idx], digits = 3);
            changeM[j,k] = "$(colNameV[idx]): $devChange";
        end
    end

    hdRow = ["$j" for j = 0 : n];
    hdRow[1] = " ";

    return  hdRow,  rowNameV,  changeM
end


"""
	$(SIGNATURES)

Show a table with the largest deviation changes for each parameter.
"""
function show_largest_change_table(ct :: ChangeTable, n :: Integer; io = stdout,
    transposed :: Bool = false)
    hdRow, hdColumn, valueM = make_largest_change_table(ct, n; transposed = transposed);
    pretty_table(io, [hdColumn  valueM],  hdRow);
end    


# ---------------