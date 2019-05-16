export ScoreBrier

"""
    ScoreBrier <: ScoringRule

 Calculate Brier Scores for a set of outcomes and predictions

## References
* https://en.wikipedia.org/wiki/Scoring_rule
* https://en.wikipedia.org/wiki/Brier_score
* https://www2.cs.duke.edu/courses/spring17/compsci590.2/proper_scoring.pdf

## Parameters
* `normalise::false`: if true, normalise scores so that for binary choice
     + S( [0.5,0.5], 1) = 0.0
     + S( [0.0,1.0], 1) = 1.0

```
"""
struct ScoreBrier <: ScoringRule
    normalise::Bool
end
ScoreBrier(; normalise::Bool=false) = ScoreBrier(normalise)

function score_direction(srule::ScoreBrier)
    if srule.normalise
        return 1 # normalising puts it in the positive direction
    else
        return -1
    end
end

function scoring_function(srule::ScoreBrier, predicted_probabilities::Array{Float64,1}, outcome::Int)
    # general model allows C classes, so number classes 1,2,...,C
    #    predicted_probabilities is a C-element vector, which must sum to 1
    #    outcome is the index of the event that actually happens
    if abs( sum(predicted_probabilities) - 1.0 ) > 1.0e-2
        error("probabilities must sum to 1")
    end
    C = length(predicted_probabilities)
    e_i = zeros(Float64, C)
    e_i[outcome] = 1.0
    result = sum( (predicted_probabilities - e_i).^2 )
    if srule.normalise
        return 1-2*result
    else
        return result
    end
end
