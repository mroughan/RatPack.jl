####### general utilities

## macro for argument checking from Distributions.jl
macro check_args(D, cond)
    quote
        if !($(esc(cond)))
            throw(ArgumentError(string(
                $(string(D)), ": the condition ", $(string(cond)), " is not satisfied.")))
        end
    end 
end

# set all keys of a dictionary to zero
function reset!( d::Dict; z0=missing )
    for k in keys(d)
        if ismissing(z0)
            d[k] = zero(typeof(d[k]))
        else
            d[k] = z0
        end
    end
end

# increment counters kept in a dictionary
function increment!( d::Dict{String, Int}, k::String, i::Int)
    if haskey(d, k)
        d[k] += i
    else
        d[k] = i
    end
end
