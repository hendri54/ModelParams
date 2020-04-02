## -----------------  Deviation vector

"""
    DevVector

Deviation vector
"""
mutable struct DevVector
    dv :: Vector{AbstractDeviation}
end



"""
    DevVector()

Constructs an empty deviation vector
"""
function DevVector()
    DevVector(Vector{AbstractDeviation}())
end

Base.isempty(d :: DevVector) = Base.isempty(d.dv);
Base.length(d :: DevVector) = Base.length(d.dv);
Base.getindex(d :: DevVector, j) = d.dv[j];

# Iteration
function Base.iterate(d :: DevVector, j) 
    if isempty(d)
        return nothing
    elseif j > length(d)
        return nothing
    else
        return d.dv[j], j+1
    end
end

Base.iterate(d :: DevVector) = Base.iterate(d, 1);


"""
    append!(d :: DevVector, dev :: Deviation)

Append a deviation.
"""
function append!(d :: DevVector, dev :: AbstractDeviation)
    @assert !dev_exists(d, dev.name)  "Deviation $(dev.name) already exists"
    Base.push!(d.dv, dev)
end


"""
    $(SIGNATURES)
    
Set model values for one deviation in a `DevVector` specified by `name`
"""
function set_model_values(d :: DevVector, name :: Symbol, modelV)
    dev = retrieve(d, name);
    @assert !isempty(dev)
    set_model_values(dev, modelV);
    return nothing
end


"""
	set_weights!
"""
function set_weights!(d :: DevVector, name :: Symbol, wtV)
    dev = retrieve(d, name);
    @assert !isempty(dev)
    @assert size(wtV) == size(dev.dataV)  "Size mismatch: $(size(wtV)) vs $(size(dev.dataV))"
    set_weights!(dev, wtV);
    return nothing
end


"""
    retrieve

If not found: return empty Deviation
"""
function retrieve(d :: DevVector, dName :: Symbol)
    outDev = empty_deviation();

    n = length(d);
    if n > 0
        dIdx = 0;
        for i1 in 1 : n
            #println("$i1: $(d.dv[i1].name)")
            if d.dv[i1].name == dName
                dIdx = i1;
                break;
            end
            #println("  not found")
        end
        if dIdx > 0
            outDev = d.dv[dIdx];
        end
    end
    return outDev :: AbstractDeviation
end


function dev_exists(d :: DevVector, dName :: Symbol)
    return !isempty(retrieve(d, dName))
end

Base.show(io :: IO, d :: DevVector) = show_deviations(io, d);

"""
    $(SIGNATURES)

Show all deviations. Each gets a short display with name and scalar deviation.
"""
function show_deviations(io :: IO,  d :: DevVector; sorted :: Bool = false)
    if length(d) < 1
        println(io, "No deviations");
    else
        lineV = Vector{String}();
        for i1 in 1 : length(d)
            dStr = short_display(d.dv[i1]);
            push!(lineV, dStr);
        end
    end
    if sorted
        lineV = sort(lineV);
    end
    show_string_vector(lineV, 80, io = io);
end

show_deviations(d :: DevVector; kwargs...) = show_deviations(stdout, d; kwargs...);


"""
	$(SIGNATURES)

Return vector of scalar deviations.

Returns empty vector if `DevVector` is empty.
"""
function scalar_devs(d :: DevVector; inclScalarWt :: Bool = true)
    sds = scalar_dev_dict(d; inclScalarWt = inclScalarWt);
    return collect(values(sds));
end


"""
	$(SIGNATURES)

Make a `Dict{Symbol, DevType}` that maps deviation names into scalar deviations.
Useful for saving to disk.
"""
function scalar_dev_dict(d :: DevVector; inclScalarWt :: Bool = true)
    sds = Dict{Symbol, DevType}();
    n = length(d);
    if n > 0
        for i1 in 1 : n
            dev,_ = scalar_dev(d.dv[i1],  inclScalarWt = inclScalarWt);
            sds[name(d.dv[i1])] = dev;
        end
    end
    return sds
end

"""
	$(SIGNATURES)

Overall scalar deviation. Weighted sum of the scalar deviations returned by all `Deviation` objects
"""
function scalar_deviation(d :: DevVector)
    scalarDev = 0.0;
    for dev in d.dv
        sDev, _ = scalar_dev(dev,  inclScalarWt = true);
        @assert sDev >= 0.0
        scalarDev += sDev;
    end
    return scalarDev
end




# ---------------