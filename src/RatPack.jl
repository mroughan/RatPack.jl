module RatPack
__precompile__(false)

import Base: copy, push!, append!, insert!, getindex, setindex!, length, size, lastindex, ==

using Random
using StatsBase
using Distributions
using CategoricalArrays
using DataFrames
using CSV
using LinearAlgebra

export check_ratings, read_ratings, write_ratings, check_results, read_results, write_results, read_ratingstable, write_ratingstable # I/O functions
export update_ratings, predict_outcome, update_info, summarize, increment!, reset!, player_indexes, linesearch
export update_rule_list, update_rule_names, simulate_rule_list, simulate_rule_names, scoring_rule_list, scoring_rule_names
export UpdateRule, SimulateRule, GenerateRule, ScoringRule # parent abstract types -- instantiations are exported in their own files
export RatingsList, RatingsTable # main datastructures
export simulate, generate # simulation tools
export score_ratings, scoring_function, score_direction
export PlayerA, PlayerB, Outcome, FactorA, FactorB, ScoreA, ScoreB # various useful symbol abbreviations
export copy, push!, append!, insert!, getindex, setindex!, length, size, lastindex, ==
export cross_validate, optimise # higher-level wrapper functions

### Main data structures used here
include("DataStructures.jl")

### General purpose utilities
include("Utilities.jl")

### I/O routines
include("IO.jl")

### Models for update calculation rules and predictions
abstract type UpdateRule end


"""
    update_ratings()

 Compute one round of updates to ratings

## Input arguments
* `rule::UpdateRule`: the type of update rule to use
* `input_ratings::RatingsList`: a list of current ratings to be used in recursive updates
* `input_competitions::DataFrame`: a DataFrame containing the outcomes of a series of competitions

```
"""
function update_ratings( rule::UpdateRule,
                         input_ratings::RatingsList,
                         input_competitions::DataFrame )
    error("undefined update rule") # this is the default that is called with an update rule that isn't properly defined
end

"""
    predict_outcome()

 Predict outcome of a single match

## Input arguments
* `rule::UpdateRule`: the type of update rule to use
* `ratingA::Real`: rating of player A
* `ratingB::Real`: rating of player B
* `factorA::Union{Missing,Real}`: factors affecting player A where relevant (small int usually)
* `factorB::Union{Missing,Real}`: factors affecting player B where relevant (small int usually)

```
"""
function predict_outcome(rule::UpdateRule,
                         ratingA::Real, ratingB::Real, 
                         factorA::Union{Missing,Real}, factorB::Union{Missing,Real} )
    if update_info(rule)[:input] != "outcome"
        error("the $rule update doesn't predict outcomes")
    else
        error("the $rule update doesn't have a prediction function")
    end
end

# actual instantiations of updates 
update_rule_list = ["Colley", "Massey", "MasseyColley", "KeenerScores", "Revert", "EloF", "Elo", "Iterate", "SampleIterate"]
update_rule_names = Array{String,1}(undef,length(update_rule_list))
for (i,u) in enumerate(update_rule_list)
    u_file = "UpdateRules/$(u).jl"
    include(u_file)
    update_rule_names[i] = "Update$(u)"
end


### Simulation tools
abstract type SimulateRule end
abstract type GenerateRule end

"""
    simulate()

 Simulate a set of competition for rated players

## Input arguments
* `r::RatingsList`: the list of players and their ratings
* `model::SimulateRule`: the type of competition to simulate, and it's parameters
* `perf_model::ContinuousUnivariateDistribution`: the performance model (strength mapped to outcomes)

```
"""
function simulate(r::RatingsList, model::SimulateRule, perf_model::ContinuousUnivariateDistribution )
    error("undefined simulation rule") # this is the default that is called with rules that aren't properly defined
end

# actual instantiations of simulation rules 
simulate_rule_list = ["RoundRobin", "Elimination"]
simulate_rule_names = Array{String,1}(undef,length(simulate_rule_list))
for (i,u) in enumerate(simulate_rule_list)
    u_file = "Simulation/$(u).jl"
    include(u_file)
    simulate_rule_names[i] = "Sim$(u)"
end


"""
    generate()

 generate a set of rated players

## Input arguments
* `m::Int`: the number of players to simulate
* `model::???`: the model to use in generation

```
"""
function generate()
    error("undefined generation rule") # this is the default that is called with an update rule that isn't properly defined
end

### Scoring Rules
abstract type ScoringRule end

"""
    score()

 Compure "Scores" for a set of ratings and a model by comparing predictions from the ratings/model to contest data
    
## Input arguments
* `srule::ScoringRule`: the scoring rule to use
* `outcomes::DataFrame`: the outcomes of the contests (see I/O)
* `rule::UpdateRule`: the update/prediction rule
* `r::RatingsList`: a list of ratings (should be complete) of all players involved (typically derived using same rule)

```
"""
function score_ratings(srule::ScoringRule, outcomes::DataFrame, rule::UpdateRule, r::RatingsList)
    total_score = 0.0
    for i=1:size(outcomes,1)
        # form the predictions from the update rule's prediction function
        out_prob = predict_outcome(rule,
                                   r.ratings[outcomes[i,PlayerA]], r.ratings[outcomes[i,PlayerB]],
                                   outcomes[i,FactorA], outcomes[i,FactorB])
        
        # add scores over all contests
        o = outcomes[i,Outcome]
        if o==-1
            o = 2
        elseif o==0
            o = 3
        end
        total_score += scoring_function(srule, out_prob, o)
    end
    av_score = total_score/size(outcomes,1)
    
    return av_score
end

"""
    score_direction()

 Indicate whether score is positive (1) or negative (-1), i.e.,
* positive: means larger scores are better
* negative: means scores closer to zero are better
    
## Input arguments
* `srule::ScoringRule`: the scoring rule to use

```
"""
function score_direction(srule::ScoringRule)
    error("undefined generation rule") # this is the default that is called with scoring function that isn't properly defined
end

"""
    scoring_function()

 Compute "Scores" for predicted probabilities of outcome
    
## Input arguments
* `srule::ScoringRule`: the scoring rule to use
* `predicted_probabilities::Array{Float64,1}`: vector length C for C classes of outcome (must add to 1)
* `outcome::Int`: the outcome as an Integer from 1,...,C

```
"""
function scoring_function(srule::ScoringRule, predicted_probabilities::Array{Float64,1}, outcome::Int)
    error("undefined generation rule") # this is the default that is called with scoring function that isn't properly defined
end

function scoring_function(srule::ScoringRule, predicted_probabilities::Tuple, outcome::Int)
    return scoring_function(srule, [x for x in predicted_probabilities], outcome)
end

# actual instantiations of simulation rules 
scoring_rule_list = ["Brier", "Logarithmic", "Quadratic", "Spherical"]
scoring_rule_names = Array{String,1}(undef,length(scoring_rule_list))
for (i,u) in enumerate(scoring_rule_list)
    u_file = "ScoringRules/$(u).jl"
    include(u_file)
    scoring_rule_names[i] = "Score$(u)"
end

### Wrapper functions
include("Wrappers.jl")


end # module
