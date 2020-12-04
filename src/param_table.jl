# Holds symbol, name, description, value
# All as formatted text
mutable struct ParamTable
    m :: Matrix{String}
end

ParamTable() = ParamTable(Matrix{String}(undef, 0, 4));
ParamTable(n :: Integer) = ParamTable(fill("", n, 4));

Base.length(pt :: ParamTable) = size(pt.m, 1);

get_symbol(pt :: ParamTable, ir :: Integer) = pt.m[ir, 1];
get_description(pt :: ParamTable, ir :: Integer) = pt.m[ir, 2];
get_value(pt :: ParamTable, ir :: Integer) = pt.m[ir, 3];
get_name(pt :: ParamTable, ir :: Integer) = pt.m[ir, 4];

get_symbols(pt :: ParamTable) = pt.m[:, 1];
get_descriptions(pt :: ParamTable) = pt.m[:, 2];
get_values(pt :: ParamTable) = pt.m[:, 3];
get_names(pt :: ParamTable) = pt.m[:, 4];

function add_row!(pt :: ParamTable, name, lsymbol, descr, value)
    append!(pt.m, [lsymbol descr value name]);
end

function set_row!(pt :: ParamTable, ir :: Integer, name, lsymbol, descr, value)
    pt.m[ir,:] .= [lsymbol, descr, value, name];
end


# Return a vector of latex table rows with
#   symbol / description / value
# Contains only the "bodies" of the rows. Not newlines etc.
# First row is multicolumn description, if provided.
function latex_param_table(tbM :: ParamTable, descr)
    n = length(tbM);
    if isempty(descr)
        lOffset = 0;
    else
        lOffset = 1;
    end
    sV = fill("", n + lOffset);
    if !isempty(descr)
        sV[1] = "\\multicolumn{3}{l}{$descr} \\\\";
    end
    for j = 1 : n
        sV[j + lOffset] = "\$$(get_symbol(tbM, j))\$ & $(get_description(tbM, j)) & $(get_value(tbM, j))"
    end
    return sV
end




# ------------
