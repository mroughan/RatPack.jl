module RatPack
__precompile__(false)

using StatsBase
using Distributions
using CategoricalArrays
using DataFrames
using CSV
using LinearAlgebra

export check_ratings, convert_ratings, read_ratings, check_results, read_results
export update_ratings, update_info, summarize, increment!, reset!, player_indexes
export UpdateRule, UpdateElo
export RatingsList, Parameters
export PlayerA, PlayerB, Outcome, FactorA, FactorB, ScoreA, ScoreB

## macro for argument checking
##   from Distributions.jl
macro check_args(D, cond)
    quote
        if !($(esc(cond)))
            throw(ArgumentError(string(
                $(string(D)), ": the condition ", $(string(cond)), " is not satisfied.")))
        end
    end 
end

### ratings structures and associated functions
struct RatingsList
    n::Int64 # number of rated players
    players::Array{String,1}
    ratings::Dict{String, Float64}
#    K::Dict{String, Float64}
#    β::Dict{String, Float64}
end

function player_indexes( players::Array{String,1} )
    d = Dict{String, Int64}()
    for i in 1:length(players)
        d[players[i]] = i
    end
    return d
end
player_indexes( R::RatingsList ) = player_indexes( R.players )
               
# check you have a valid data frame
function check_ratings( df::DataFrame )
    # check it has the required columns with correct datatype
    if !haskey(df, :Players)
       error("Input DataFrame must have a 'Players' column'")
    end
    if !haskey(df, :Ratings)
        error("Input DataFrame must have a 'Ratings' column")
    end
    if !( eltype(df[:Players]) <: Union{Missing, AbstractString} )
       error("Input DataFrame 'Players' column must have type String")

    end
    if !( eltype(df[:Ratings]) <: Union{Missing, AbstractFloat} )
        error("Input DataFrame must have a 'Ratings' column must have type Float64")
    end
    # do I care if there is other stuff???
end
 
# convert the data frame into a RatingsList object
function convert(::Type{RatingsList}, df::DataFrame )
    n = size(df,1)
    R = RatingsList(n,
                    df[:Players],
                    Dict( [ df[r,:Players] => df[r,:Ratings] for r=findall( .!ismissing.(df[:,:Ratings])) ] )
                    )
    return R
end

function convert(::Type{DataFrame}, R::RatingsList )
    return 1
end

# read in a CSV file of ratings
function read_ratings( file::String )
    df = CSV.read(file; comment="#")
    check_ratings( df )
    R = convert( RatingsList, df )
    return df, R
end

### same again but for offence/defence ratings

struct ODRatingsList
    n::Int64 # number of rated players
    players::Array{String,1}
    offense_ratings::Dict{String, Float64}
    defence_ratings::Dict{String, Float64}
#    K::Dict{String, Float64}
#    β::Dict{String, Float64}
end



### competition lists and associated functions

# check you have a valid data frame
PlayerA = Symbol("Player A")
PlayerB = Symbol("Player B")
Outcome = Symbol("Outcome")
FactorA = Symbol("Factor A")
FactorB = Symbol("Factor B")
ScoreA = Symbol("Score A")
ScoreB = Symbol("Score B")
function check_results( df::DataFrame )
    # check it has the required columns with correct datatype
    if !haskey(df, PlayerA)
       error("Input DataFrame must have a 'Player A' column'")
    end
    if !( eltype(df[PlayerA]) <: Union{Missing, AbstractString} )
       error("Input DataFrame 'Player A' column must have type String")
    end
    if !haskey(df, PlayerB)
       error("Input DataFrame must have a 'Player B' column'")
    end
    if !( eltype(df[PlayerB]) <: Union{Missing, AbstractString} )
       error("Input DataFrame 'Player B' column must have type String")
    end
    if !haskey(df, Outcome)
        error("Input DataFrame must have a 'Outcome' column")
    end
    if !( eltype(df[Outcome]) <: Union{Missing, Integer} )
        error("Input DataFrame must have a 'Outcome' column must have type Float64")
    end
    if maximum(skipmissing(df[Outcome])) > 1 ||  minimum(skipmissing(df[Outcome])) < -1
        error("Outcome should be -1,0,1")
    end
    # Factor A and Factor B
    # Score A and Score B
end
 
# read in a CSV file of ratings
function read_results( file::String )
    df = CSV.read(file; comment="#")
    check_results( df )
    df[PlayerA] = coalesce.( df[PlayerA], "" )
    df[PlayerB] = coalesce.( df[PlayerB], "" )
    player_list = merge(+, countmap( df[PlayerA] ), countmap( df[PlayerB] )  ) 
    return df, player_list
end

# create a blank ratings list from a list of players
function RatingsList( player_list::Dict{String,Int64} )
    tmp = sort( collect( keys(player_list) ) )
    return RatingsList( length(tmp), tmp, Dict{String, Int64}() )
end

function reset!( d::Dict{String, Int} )
    for k in keys(d)
        d[k] = 0
    end
end

function increment!( d::Dict{String, Int}, k::String, i::Int)
    if haskey(d, k)
        d[k] += i
    else
        d[k] = i
    end
end

# summarize a list of competitions
function summarize( df::DataFrame,  player_list::Dict{String,Int64})
    wins = copy(player_list)
    reset!(wins)
    score_diff = Dict{String,Int64}()
    for i=1:size(df,1)
        # ignores ties
        if df[i,Outcome] == 1
            increment!(wins, df[i,PlayerA], 1)
        elseif df[i,Outcome] == -1
            increment!(wins, df[i,PlayerB], 1)
        end
        diff = df[i,ScoreA] - df[i,ScoreB]
        increment!(score_diff, df[i,PlayerA], diff)
        increment!(score_diff, df[i,PlayerB], -diff)
    end

    new_df = DataFrame( Player=Array{String,1}(), Record=Array{String,1}(), ScoreDiff = Array{Int64,1}() )
    for p in keys(player_list)
        push!( new_df, [p, "$(wins[p])/$(player_list[p])", score_diff[p] ])
    end
    return new_df
end

### Update calculations

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
include("UpdateRules/Colley.jl")
include("UpdateRules/Massey.jl")
include("UpdateRules/KeenerScores.jl")

# include("UpdateRules/MasseyAdv.jl")
# include("UpdateRules/MasseyColley.jl")
# include("UpdateRules/KeenerOutcomes.jl")

include("UpdateRules/Elo.jl")


# recursive versions of batch rules (or others), using exponential smoothing
#    construct these by building a "recursion" on existing rules


# Revise.includet("UpdateRules/???.jl")


### wrapper functions 


 

end # module
