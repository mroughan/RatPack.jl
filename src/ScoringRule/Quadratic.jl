export ScoreQuadratic

"""
    ScoreQuadratic <: ScoringRule

 Calculate Quadratic Scores for a set of outcomes and predictions

## References
* https://en.wikipedia.org/wiki/Scoring_rule
* 

## Parameters
* `normalise::false`: if true, normalise scores so that for binary choice
     + S( [0.5,0.5], 1) = 0.0
     + S( [0.0,1.0], 1) = 1.0

```
"""
struct ScoreQuadratic <: ScoringRule
    normalise::Bool
end
ScoreQuadratic(; normalise::Bool=false) = ScoreQuadratic(normalise)

function score_direction(srule::ScoreQuadratic)
    return 1
end

function scoring_function(srule::ScoreQuadratic, predicted_probabilities::Array{Float64,1}, outcome::Int)
    if abs( sum(predicted_probabilities) - 1.0 ) > 1.0e-2
        error("probabilities must sum to 1")
    end
    result = 2*predicted_probabilities[outcome] - sum( predicted_probabilities.^2 )
    if srule.normalise
        return 2*result - 1
    else
        return result
    end
end
