export UpdateElo

"""
    UpdateElo <: UpdateRule

 Update using standard Elo where K is constant, but distribution can be set (with constant parameters)
     Elo2 has logistic distribution, but allows varying K

## Parameters
* `r0::Float64`: default rating
* `K::Float64`: the value of the gain parameter (use Elo2 for variable K)
* `dist::ContinuousUnivariateDistribution`: the model to use for performance as a function of rating, e.g, Normal or Logistic
* the distribution can have its own parameters, e.g., `β::Float64`, the spread parameter for the Logistic

```
"""
struct UpdateElo <: UpdateRule
    r0::Float64
    K::Float64
    dist::ContinuousUnivariateDistribution
    function UpdateElo(r0, K, dist)
        @check_args(UpdateElo, K >= zero(K))
        @check_args(UpdateElo, r0 >= zero(r0))
        new(r0, K, dist)
    end
end
# defaults imply the distribution is  Logistic(μ=0.0, θ=100.0)
#   https://en.wikipedia.org/wiki/Logistic_distribution
#   https://juliastats.github.io/Distributions.jl/latest/univariate.html#Continuous-Distributions-1
#      mean=mu=0.0, sdev=π θ / √3
default_θ = 400 / log(10) # this results in the standard values used for Elo in Chess and many other cases
UpdateElo(;r0=1500.0, K=32.0, θ=default_θ) = UpdateElo( r0, K, Logistic(0.0, θ) )

function update_info( rule::UpdateElo )
    info = Dict(
                :name => "Elo",
                :mode => "recursive",
                :reference => "\"Whos's #1\", Langville and Meyer, p.?? and ??",
                :input => "outcome", 
                :output => "probabilistic",
                :model => "single",   
                :ties => true,        
                :factors => true,     
                :parameters => ["r0, default rating", "K, gain", "dist(), performance model"],
                :record => false
                )
    return info
end
update_info( ::Type{UpdateElo} ) =  update_info( UpdateElo() )

function update_ratings( rule::UpdateElo,
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
        (rA, rB) = update( rule, old_rA, old_rB, d[i,Outcome], d[i,FactorA], d[i,FactorB])
        new_r[ pA ] = rA
        new_r[ pB ] = rB
    end
                          
    # output ratings list
    output_ratings = RatingsList(m, input_ratings.players, new_r )   
    return output_ratings
end

function update( rule::UpdateElo, ratingA::Real, ratingB::Real, outcome::Real, factorA::Union{Missing,Real}, factorB::Union{Missing,Real})
    rating_diff = ratingA - ratingB
    factorA = coalesce(factorA, 0.0) # replace missing values with 0
    factorB = coalesce(factorB, 0.0) # replace missing values with 0
    factors = (factorA - factorB)*std(rule.dist) # this should also probably include a tunable parameter
    expectedA = cdf( rule.dist,  rating_diff + factors )  # do these separately in case asymmetric distribution is chosen
    expectedB = cdf( rule.dist, -rating_diff - factors )  # do these separately in case asymmetric distribution is chosen
    outcomeA = (sign( outcome) + 1)/2
    outcomeB = (sign(-outcome) + 1)/2
    rA = ratingA + rule.K*( outcomeA - expectedA )
    rB = ratingB + rule.K*( outcomeB - expectedB )
    return rA, rB
end

