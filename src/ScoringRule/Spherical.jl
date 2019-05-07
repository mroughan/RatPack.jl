export ScoreSpherical

"""
    ScoreSpherical <: ScoringRule

 Calculate Spherical Scores for a set of outcomes and predictions

## References
* https://en.wikipedia.org/wiki/Scoring_rule
* 

## Parameters
* `normalise::false`: if true, normalise scores so that for binary choice
     + S( [0.5,0.5], 1) = 0.0
     + S( [0.0,1.0], 1) = 1.0

```
"""
struct ScoreSpherical <: ScoringRule
    normalise::Bool
end
ScoreSpherical(; normalise::Bool=false) = ScoreSpherical(normalise)

function score_direction(srule::ScoreSpherical)
    return 1
end

function scoring_function(srule::ScoreSpherical, predicted_probabilities::Array{Float64,1}, outcome::Int)
    if abs( sum(predicted_probabilities) - 1.0 ) > 1.0e-2
        error("probabilities must sum to 1")
    end
    result = predicted_probabilities[outcome] / sqrt( sum( predicted_probabilities.^2 ) )
    if srule.normalise
        x = 2/(2 - sqrt(2))
        y = 1 - x
        return result*x + y
    else
        return result
    end
end
