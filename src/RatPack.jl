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
export update_ratings, update_info, summarize, increment!, reset!, player_indexes
export update_rule_list, update_rule_names
export UpdateRule, SimulateRule, GenerateRule # parent abstract types -- instantiations are exported in their own files
export RatingsList, RatingsTable # main datastructures
export simulate, generate # simulation tools
export PlayerA, PlayerB, Outcome, FactorA, FactorB, ScoreA, ScoreB # various useful symbol abbreviations
export copy, push!, append!, insert!, getindex, setindex!, length, size, lastindex, ==

### Main data structures used here
include("DataStructures.jl")

### General purpose utilities
include("Utilities.jl")

### I/O routines
include("IO.jl")

### Update calculation rules
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

# actual instantiations of updates 
update_rule_list = ["Colley", "Massey", "MasseyColley", "KeenerScores", "Revert", "Elo", "Iterate", "SampleIterate"]
update_rule_names = Array{String,1}(undef,length(update_rule_list))
for (i,u) in enumerate(update_rule_list)
    u_file = "UpdateRules/$(u).jl"
    include(u_file)
    update_rule_names[i] = "Update$(u)"
end


# Simulation tools
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
    error("undefined simulation rule") # this is the default that is called with an update rule that isn't properly defined
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

end # module
