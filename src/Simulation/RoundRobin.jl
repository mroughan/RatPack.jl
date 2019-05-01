export SimRoundRobin
"""
    SimRoundRobin

 Simulates multiple round-robin competition between a list of players under some performance model.

## Parameters
* `n::Int`: number of RR competitions to run

## Limitations
* no ties
* no additional factors in competitions
* just win/loss, so scores are trivial

```
"""
struct SimRoundRobin <: SimulateRule
    n::Int
end
SimRoundRobin(; n::Int=1) = SimRoundRobin(n)    

function simulate( r::RatingsList, model::SimRoundRobin, perf_model::ContinuousUnivariateDistribution )
    m = length( r.players )
    L = Int( m*(m-1)/2 )
    df = DataFrame([String, String, Int, Int, Int], [PlayerA, PlayerB, Outcome, ScoreA, ScoreB], model.n*L)
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
                o = outcome( r.ratings[pA], r.ratings[pB],  perf_model )
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
function outcome( rA::Float64, rB::Float64, perf_model::ContinuousUnivariateDistribution)
    p = cdf( perf_model, rA - rB )
    x = rand()
    if x <= p
        o = 1
    else
        o = -1
    end
    return o
end

