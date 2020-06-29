## -----------  General functions

name(d :: AbstractDeviation) = d.name;
short_description(d :: AbstractDeviation) = d.shortStr;
long_description(d :: AbstractDeviation) = d.longStr;

"""
    $(SIGNATURES)

Retrieve data values
"""
get_data_values(d :: AbstractDeviation{F1}) where F1 = deepcopy(d.dataV);


"""
    $(SIGNATURES)

Retrieve model values
"""
get_model_values(d :: AbstractDeviation{F1}) where F1 = deepcopy(d.modelV);


"""
	$(SIGNATURES)

Retrieve std errors of data values. Not valid for all types of deviations.
Returns `nothing` if std errors are not set (are all 0).
"""
function get_std_errors(d :: AbstractDeviation{F1}) where F1
    if all(d.stdV .== zero(F1))
        return nothing
    else
        return deepcopy(d.stdV);
    end
end


"""
    $(SIGNATURES)

Set model values in an existing deviation.
"""
function set_model_values(d :: AbstractDeviation{F1}, modelV) where F1
    dataV = get_data_values(d);
    if typeof(modelV) != typeof(dataV)  
        println(modelV);
        println(dataV);
        error("Type mismatch in $(d.name): $(typeof(modelV)) vs $(typeof(dataV))");
    end
    @assert size(modelV) == size(dataV)  "Size mismatch: $(size(modelV)) vs $(size(dataV))"
    d.modelV = deepcopy(modelV);
    return nothing
end


"""
	$(SIGNATURES)

Retrieve weights. Returns scalar 1 for scalar deviations.
"""
function get_weights(d :: AbstractDeviation{F1}) where F1
    return d.wtV
end

"""
    set_weights
    
Does nothing for Deviation types that do not have weights.
"""
function set_weights!(d :: AbstractDeviation{F1}, wtV) where F1
    if isa(d, Deviation)
        @assert typeof(wtV) == typeof(get_data_values(d))
        @assert size(wtV) == size(get_data_values(d))
        @assert all(wtV .> 0.0)
        d.wtV = deepcopy(wtV);
    end
    return nothing
end


"""
	$(SIGNATURES)

Validate a `Deviation`.
"""
validate_deviation(d :: AbstractDeviation) = true


## ---------------  Display

# This is never called for concrete types (why?)
Base.show(io :: IO, d :: AbstractDeviation{F1}) where F1 = 
    Base.print(io, "$(name(d)):  ", short_description(d));

## Formatted short deviation for display
function short_display(d :: AbstractDeviation{F1}; inclScalarWt :: Bool = true) where F1
    _, scalarStr = scalar_dev(d, inclScalarWt = inclScalarWt);
    return d.shortStr * ": " * scalarStr;
 end
 
 
 """
    $(SIGNATURES)

Show a deviation using the show function contained in its definition.

Optionally, a file path can be provided. If none is provided, the path inside the deviation is used.
"""
function show_deviation(d :: AbstractDeviation{F1}; showModel :: Bool = true, fPath :: String = "") where F1
    return d.showFct(d,  showModel = showModel, fPath = fPath)
end


function open_show_path(d :: AbstractDeviation{F1}; 
    fPath :: String = "", writeMode :: String = "w") where F1

    if isempty(fPath)
        showPath = d.showPath;
    else
        showPath = fPath;
    end
    if isempty(showPath)
        io = stdout;
    else
        io = open(showPath, "w");
    end
    return io
end

function close_show_path(d :: AbstractDeviation{F1}, io) where F1
    if io != stdout
        close(io);
    end
end


# -------------