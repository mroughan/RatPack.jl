export UpdateEloF

"""
    UpdateEloF <: UpdateRule

 Update using standard Elo where 
* K is constant, but 
* performance model distribution can be set (with constant parameters)
* extra factors are added to ratings, with a scale parameter

## Parameters
* `r0::Float64`: default rating
* `K::Float64`: the value of the gain parameter (use EloF2 for variable K)
* `dist::ContinuousUnivariateDistribution`: the model to use for performance as a function of rating, e.g, Normal or Logistic
* `factor_scale::Float64`
* the distribution can have its own parameters, e.g., `β::Float64`, the spread parameter for the Logistic

```
"""
struct UpdateEloF <: UpdateRule
    r0::Float64
    K::Float64
    dist::ContinuousUnivariateDistribution
    factor_scale::Float64
    function UpdateEloF(r0, K, dist, factor_scale)
        @check_args(UpdateEloF, K >= zero(K))
        @check_args(UpdateEloF, r0 >= zero(r0))
        @check_args(UpdateEloF, factor_scale >= zero(factor_scale))
        new(r0, K, dist, factor_scale)
    end
end
# defaults imply the distribution is  Logistic(μ=0.0, θ=100.0)
#   https://en.wikipedia.org/wiki/Logistic_distribution
#   https://juliastats.github.io/Distributions.jl/latest/univariate.html#Continuous-Distributions-1
#      mean=mu=0.0, sdev=π θ / √3
default_θ = 400 / log(10) # this results in the standard values used for Elo in Chess and many other cases
UpdateEloF(;r0=1500.0, K=32.0, θ=default_θ, factor_scale=default_θ) = UpdateEloF( r0, K, Logistic(0.0, θ), factor_scale )
# default factor_scale is one "standard deviation"

function update_info( rule::UpdateEloF )
    info = Dict(
                :name => "EloF",
                :mode => "recursive",
                :reference => "\"Whos's #1\", Langville and Meyer, p.?? and ??",
                :input => "outcome,factors", 
                :output => "probabilistic",
                :model => "single",   
                :ties => true,        
                :factors => true,     
                :parameters => ["r0, default rating", "K, gain", "dist(), performance model", "factor_scale"],
                :record => false
                )
    return info
end
update_info( ::Type{UpdateEloF} ) =  update_info( UpdateEloF() )

function update_ratings( rule::UpdateEloF,
                         input_ratings::RatingsList,
                         input_competitions::DataFrame)
    n = size(input_competitions,1)
    m = length( input_ratings.players )
    I = player_indexes( input_ratings.players )

    # set initial ratings if they aren't already
    old_r = copy( input_ratings.ratings )
    for p in input_ratings.players
        if !haskey( old_r, p )
            old_r[p] = rule.r0
        end
    end
    new_r = copy(old_r) # start with the old ratings, in case one isn't modified at all
    
    # perform update for each outcome
    d = input_competitions # just an abbreviation
    for i=1:n
        pA = d[i,PlayerA]
        pB = d[i,PlayerB]
        old_rA = old_r[ pA ]
        old_rB = old_r[ pB ]
        (rA, rB) = update( rule, old_rA, old_rB, d[i,Outcome], rule.factor_scale*d[i,FactorA], rule.factor_scale*d[i,FactorB])
        new_r[ pA ] = rA
        new_r[ pB ] = rB
    end
                          
    # output ratings list
    output_ratings = RatingsList(input_ratings.players, new_r )   
    return output_ratings
end

# see Elo.jl for definition of `update`
