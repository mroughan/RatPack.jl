export SimElimination
"""
    SimElimination

 Simulates multiple elimination competitions between a list of players under some performance model.

## Parameters
* `n::Int`: number of n of RR competition to run

## Limitations
* no ties
* no additional factors in competitions
* just win/loss, so scores are trivial
* random ordering of players (no match making)

```
"""
struct SimElimination <: SimulateRule
    n::Int
end
SimElimination(; n::Int=1) = SimElimination(n)    

function simulate( r::RatingsList, model::SimElimination, perf_model::ContinuousUnivariateDistribution )
    m = length( r.players )
    L = m-1 # number of matches to play per tournament
    df = DataFrame([String, String, Int, Int, Int], [PlayerA, PlayerB, Outcome, ScoreA, ScoreB], model.n*L)
    
    # simulate all players playing each other once per round
    c = 1
    winner = ""
    for i=1:model.n
        # random ordering of players
        current_player_list = shuffle( r.players )
        println(" $current_player_list")
        not_end = true
        level = 1
        while not_end
            k = 1
            new_player_list = Array{String,1}(undef, Int(ceil(length(current_player_list)/2)) )
            while k<length(current_player_list)
                # println("  level=$level, k=$k, c=$c, l=$(length(current_player_list))")
                pA = current_player_list[k]
                pB = current_player_list[k+1]
                df[c, PlayerA] = pA
                df[c, PlayerB] = pB
                o = outcome( r.ratings[pA], r.ratings[pB],  perf_model )
                df[c, Outcome] = o
                if o == 1
                    df[c, ScoreA] = 1
                    df[c, ScoreB] = 0
                    new_player_list[ Int(ceil(k/2)) ] = pA
                elseif o == -1
                    df[c, ScoreA] = 0
                    df[c, ScoreB] = 1
                    new_player_list[ Int(ceil(k/2)) ] = pB
                end
                c += 1
                k += 2
            end
            if k==length(current_player_list)
                new_player_list[end] = current_player_list[end]
            end
            # current_player_list = shuffle(new_player_list)
            current_player_list = new_player_list
            if length(current_player_list) == 1
                not_end = false
            end
            level += 1
        end
        winner = current_player_list[1] # winner is last person standing
    end
    return df, winner
end

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

