export SimRoundRobinF
"""
    SimRoundRobinF

 Simulates multiple round-robin competition between a list of players under some performance model.
 Differs from SimRoundRobin because it adds in a "home ground" advantage term, which is randomly 
 distributed for each match up.

## Parameters
* `n::Int`: number of RR competitions to run
* `factor_scale::Float64`

## Limitations
* no ties
* just win/loss, so scores are trivial

```
"""
struct SimRoundRobinF <: SimulateRule
    n::Int
    factor_scale::Float64
    function SimRoundRobinF(n, factor_scale)
        @check_args(SimRoundRobin, n >= one(n))
        @check_args(SimRoundRobinF, factor_scale >= zero(factor_scale))
        new(n, factor_scale)
    end
end
default_θ = 400 / log(10) # this results in the standard values used for Elo in Chess and many other cases
SimRoundRobinF(; n::Int=1, factor_scale=default_θ) = SimRoundRobinF(n, factor_scale)    

function simulate( r::RatingsList, model::SimRoundRobinF, perf_model::ContinuousUnivariateDistribution )
    m = length( r.players )
    L = Int( m*(m-1)/2 )
    df = DataFrame([String, String, Int, Int, Int, Union{Missing,Int}, Union{Missing,Int}], [PlayerA, PlayerB, Outcome, ScoreA, ScoreB, FactorA, FactorB], model.n*L)
    wins = Dict{String, Int}()
    
    # simulate all players playing each other once per round
    c = 1
    for i=1:model.n
        for j=1:m-1
            for k=j+1:m
                pA = r.players[j]
                pB = r.players[k]
                df[c, PlayerA] = pA
                df[c, PlayerB] = pB
                y = rand()
                if y <= 0.5
                    df[c, FactorA] = 1
                    df[c, FactorB] = 0
                else
                    df[c, FactorA] = 0
                    df[c, FactorB] = 1
                end
                o = outcome( r.ratings[pA], r.ratings[pB],  model.factor_scale*(df[c, FactorA]-df[c, FactorB]), perf_model )
                df[c, Outcome] = o
                if o == 1
                    df[c, ScoreA] = 1
                    df[c, ScoreB] = 0
                    increment!(wins, pA, 1)
                elseif o == -1
                    df[c, ScoreA] = 0
                    df[c, ScoreB] = 1
                    increment!(wins, pB, 1)
                end
                c += 1
            end
        end
    end
    
    # winners are players who wins most games
    #   if there is a tie, one is picked (by Julia not me)
    winner = findmax(wins)[2]
    return df, winner
end

# random outcome of a single match
#   should be able to push this into a single instantiation, or corresponding update rule?
function outcome( rA::Float64, rB::Float64, f::Float64, perf_model::ContinuousUnivariateDistribution)
    p = cdf( perf_model, rA - rB + f )
    x = rand()
    if x <= p
        o = 1
    else
        o = -1
    end
    return o
end

