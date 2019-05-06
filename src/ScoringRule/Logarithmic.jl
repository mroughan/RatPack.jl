export ScoreLogarithmic

"""
    ScoreLogarithmic <: ScoringRule

 Calculate Logarithmic Scores for a set of outcomes and predictions

## References
* https://en.wikipedia.org/wiki/Scoring_rule
* 

## Parameters
* `normalise::false`: if true, normalise scores so that for binary choice
     + S( [0.5,0.5], 1) = 0.0
     + S( [0.0,1.0], 1) = 1.0

```
"""
struct ScoreLogarithmic <: ScoringRule
    normalise::Bool
end
ScoreLogarithmic(; normalise::Bool=false) = ScoreLogarithmic(normalise)

function score_direction(srule::ScoreLogarithmic)
    return 1
end

function scoring_function(srule::ScoreLogarithmic, predicted_probabilities::Array{Float64,1}, outcome::Int)
    if abs( sum(predicted_probabilities) - 1.0 ) > 1.0e-2
        error("probabilities must sum to 1")
    end
    if srule.normalise
        return 1.0 + log( predicted_probabilities[outcome] )/log(2)
    else
        return log( predicted_probabilities[outcome] )
    end
end
