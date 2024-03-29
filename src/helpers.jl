## Display string vector on fixed with screen
function show_string_vector(sV :: Vector{T1},  width :: T2 = 80;
    io :: IO = stdout)  where {T1 <: AbstractString,  T2 <: Integer}

    n = length(sV);
    if n < 1
        return nothing
    end

    iCol = 0;
    for s in sV
        len1 = length(s);
        if len1 > 0
            if iCol + len1 > width
                println(io, " ")
                iCol = 0;
            end
            print(io, s);
            iCol = iCol + len1;
            print(io, "    ");
            iCol = iCol + 4;
        end
    end
    println(io, " ")
end


function formatted_value(v :: AbstractFloat)
    return string(round(v, digits = 3))
end


function formatted_value(v :: Vector{T1}) where T1 <: AbstractFloat
    vStr = "";
    for j = 1 : length(v)
        vStr = vStr * formatted_value(v[j]);
        if j < length(v)
            vStr = vStr * " | ";
        end
    end
    return vStr
end


function formatted_value(v :: Array{T1}) where T1 <: AbstractFloat
    vStr = formatted_value(v[1]) * " ... " * formatted_value(v[end])
end


function calibrated_string(isCal :: Bool; fixedValue = nothing,
    nValues = nothing) 
    if isCal
        if isnothing(nValues)
            x = "calibrated";
        else
            x = "calibrated ($nValues values)";
        end
    elseif isnothing(fixedValue)
        x = "fixed";
    else
        x = "fixed at " * formatted_value(fixedValue);
    end
    return x
end

function calibrated_string(p :: Param)
    v = default_value(p);
    return calibrated_string(is_calibrated(p); fixedValue = v, nValues = length(v));
end

function calibrated_string(pv :: ParamVector, vName :: Symbol)
    return calibrated_string(retrieve(pv, vName));
end


# ----------------------