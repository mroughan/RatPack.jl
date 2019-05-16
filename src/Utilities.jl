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

function increment!( d::Dict{S, T}, k::S, i::T) where {T<:Real, S<:AbstractString}
    if haskey(d, k)
        d[k] += i
    else
        d[k] = i
    end
end

function increment!( d::Dict{S, Dict{S, T}}, k1::S, k2::AbstractString, i::T) where {T<:Real, S<:AbstractString}
    if !haskey(d, k1)
        d[k1] = Dict{AbstractString, Real}()
    end
    if !haskey(d[k1], k2)
        d[k1][k2] = i
    else
        d[k1][k2] += i
    end
end

"""
    linesearch()

 Finds the minimum of a 1D function. Particular algorithms make assumptions about the form of the function.

## Input Arguments
* `algorithm::String`: algorithm to use. Current choices are `Grid`, `Golden` ...
* `func::Function`: function to optimize
* `x0::AbstractFloat`: [optional] starting point (only used for some algorithms)
* `range::Array{AbstractFloat,1}`: [optional] search range (only used for some algorithms)
* `ε::AbstractFloat`:  [default = 1.0e-3] error tolerance.

The input function should take one floating point parameter and map it
to a floating point output. At present there are not facilities to
pass additional parameters to the function, but this can be
accomplished by creating an anonymous function.

## Output arguments
* `x_star`: estimate of the location of the maximum
* `y_star`: estimate of the value at the maximum
* `error_estimate`: en estimate of the maximum possible error, which should be ≦ ε
* `n_evaluations`: number of function evaluations


## Examples
```jldoctest
julia> r = [0.0, 2.0]
julia> ε = 1.0e-6
julia> (x_star1, y_star1, error_estimate1, n_evaluations2) = linesearch( "Golden", x->sin(x); range=r, ε=ε)
(1.5707963972987837, 0.9999999999999976, 3.322605284239444e-7, 33)
```
"""
function linesearch( algorithm::String, func::Function; x0::AbstractFloat=0.0, range::Array{T,1}, ε::AbstractFloat=1.0e-3) where {T<:Real}
    if algorithm=="Grid"
        # dumb-arse grid search
        x = Float64(range[1]) : ε : Float64(range[2])
        y = func.(x) 
        (y_star, i) = findmax(y)
        x_star = x[i]
        error_estimate = ε
        n_evaluations = length(x)
    elseif algorithm=="Golden"
        # Golden section search
        γ = (sqrt(5)-1)/2
        a = Float64( range[1] )
        b = Float64( range[2] )
        ell = b - a
        no_of_iterations=ceil( log(ε/ell)/log(γ) )
        p = b - γ*(b-a)
        q = a + b - p
        fp = -func(p) # default search is a minimisation
        fq = -func(q)
        n_evaluations = 2
        for i = 1 : no_of_iterations
            ell = b - a
            if fp < fq
                a = a
                b = q
                if i < no_of_iterations
                    q = p
                    p = a + b - q
                    fq = fp
                    fp = -func(p)
                    n_evaluations = n_evaluations + 1
                end
            else
                a = p
                b = b
                if i < no_of_iterations
                    p = q
                    q = a + b - q
                    fp = fq
                    fq = -func(q)
                    n_evaluations = n_evaluations + 1
                end
            end
        end
        x_star = (a + b) / 2
        y_star = func(x_star)
        n_evaluations = n_evaluations + 1
        error_estimate = (b - a)/2.0
    else
        error("algorithm isn't implemented")
    end
    return (x_star, y_star, error_estimate, n_evaluations)
end
    
