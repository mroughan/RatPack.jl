module RatPack
__precompile__(false)

import Base: copy, push!, append!, insert!, getindex, setindex!, length, size, lastindex, ==

using StatsBase
using Distributions
using CategoricalArrays
using DataFrames
using CSV
using LinearAlgebra

export check_ratings, convert_ratings, read_ratings, check_results, read_results # I/O functions
export update_ratings, update_info, summarize, increment!, reset!, player_indexes
export update_rule_list, update_rule_names
export UpdateRule # parent abstract type for updates -- instantiations are exported in their own files
export RatingsList, RatingsTable # main datastructures
export PlayerA, PlayerB, Outcome, FactorA, FactorB, ScoreA, ScoreB # various useful symbol abbreviations
export copy, push!, append!, insert!, getindex, setindex!, length, size, lastindex, ==

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
    m::Int64 # number of rated players
    players::Array{String,1}
    ratings::Dict{String, Float64}
#    K::Dict{String, Float64}
#    β::Dict{String, Float64}
end
copy(r::RatingsList) = RatingsList( r.m, r.players, r.ratings )
length(r::RatingsList) = r.m
==(r1::RatingsList, r2::RatingsList) = (r1.m == r2.m) && (r1.players == r2.players) && (r1.ratings == r2.ratings)

# construct a table to store a time-series of ratings in
struct RatingsTable
    players::Array{String,1}    
    ratings::DataFrame 
end
copy(R::RatingsTable) = RatingsTable( R.players, R.ratings )
size(R::RatingsTable) = size(R.ratings)
size(R::RatingsTable, d) = size(R.ratings, d)
lastindex(R::RatingsTable) = size(R.ratings, 1)
function RatingsTable(players::Array{String,1})
    # create empty RatingsTable with players as names of columns
    m = length(players)
    R = DataFrame( Union{Missing,Float64}, 0, m)
    names!(R, Symbol.(players))
    return RatingsTable(players, R)
end
function RatingsTable(players::Array{String,1}, n::Int)
    # create empty RatingsTable with players as names of columns, and n empty rows
    m = length(players)
    R = DataFrame( Union{Missing,Float64}, n, m)
    names!(R, Symbol.(players))
    return RatingsTable(players, R)
end
function RatingsTable(r::RatingsList)
    A = DataFrame( Union{Missing,Float64}, 1, r.m)
    names!(A, Symbol.(r.players))
    for k in keys(r.ratings)
        A[ Symbol(k) ] = r.ratings[k]
    end
    return RatingsTable(r.players, A)
end
function append!(R1::RatingsTable, R2::RatingsTable)
    append!(R1.ratings, R2.ratings)
    return R1
end
function push!(R::RatingsTable, r::RatingsList)
    x = RatingsTable(r)
    append!(R, x)
    return R
end
# function insert!(R::RatingsTable, i::Int, r::RatingsList) # insert a row into a existing RatingsTable    
# end
getindex(R::RatingsTable, i::Int) = R.ratings[i,:]
getindex(R::RatingsTable, range::UnitRange{Int}) = R.ratings[range,:]
function setindex!(R::RatingsTable, r::RatingsList, i::Int)
    R.ratings[i,:] = RatingsTable(r).ratings
end
==(R1::RatingsTable, R2::RatingsTable) = (R1.players == R2.players) && (R1.ratings == R2.ratings)

# get inverse mapping from an array of players to their indexes
function player_indexes( players::Array{String,1} )
    d = Dict{String, Int64}()
    for i in 1:length(players)
        d[players[i]] = i
    end
    return d
end
player_indexes( R::RatingsList ) = player_indexes( R.players )
               
# check you have a valid data frame for a set of ratings
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

# not finished
function convert(::Type{DataFrame}, r::RatingsList )
    m = length(R.players)
    x = Array{Union{Missing, Float64}, 1}(undef, m)
    for i=1:m
        if haskey(r.ratings, R.players[i])
            x[i] = r.ratings[ R.players[i] ]
        end
    end
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
update_rule_list = ["Colley", "Massey", "MasseyColley", "KeenerScores", "Revert", "Elo", "Iterate", "SampleIterate"]
update_rule_names = Array{String,1}(undef,length(update_rule_list))
for (i,u) in enumerate(update_rule_list)
    u_file = "UpdateRules/$(u).jl"
    include(u_file)
    update_rule_names[i] = "Update$(u)"
end


# Revise.includet("UpdateRules/???.jl")


### wrapper functions 


 

end # module
