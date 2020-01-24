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

