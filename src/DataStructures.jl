# Two main data structures used here
#   (1) RatingsList  -- stores an array of players, and a dictionary of their ratings
#   (2) RatingsTable -- for storing an array of ratings (with players as column headings)

#####################################
#  RatingsList
#####################################

"""
    RatingsList

 Self-contained set of players and their ratings

## Parameters
* `players::Array{String,1}`: ordered list of player names
* `ratings::Dict{String, Float64}`: the ratings of the players (where these have been set)
```
"""
struct RatingsList
    players::Array{String,1} # names of players
    ratings::Dict{String, Float64}
#    K::Dict{String, Float64}
#    β::Dict{String, Float64}
end
copy(r::RatingsList) = RatingsList( r.players, r.ratings )
length(r::RatingsList) = length(r.players)
==(r1::RatingsList, r2::RatingsList) = (r1.players == r2.players) && (r1.ratings == r2.ratings)

# get inverse mapping from an array of players to their indexes
function player_indexes( players::Array{String,1} )
    d = Dict{String, Int64}()
    for i in 1:length(players)
        d[players[i]] = i
    end
    return d
end
player_indexes( R::RatingsList ) = player_indexes( R.players )

# create a blank ratings list from a list of players
function RatingsList( player_list::Dict{String,Int64} )
    tmp = sort( collect( keys(player_list) ) )
    return RatingsList( tmp, Dict{String, Int64}() )
end

#####################################
#  RatingsTable
#####################################
"""
    RatingsTable

 Table of ratings (with players as column headings)

## Parameters
* `players::Array{String,1}`: ordered list of player names
* `ratings::DataFrame`: containing a series of ratings for each player as a column
```
"""
struct RatingsTable
    players::Array{String,1}    
    ratings::DataFrame 
end 
copy(R::RatingsTable) = RatingsTable( R.players, R.ratings )
size(R::RatingsTable) = size(R.ratings)
size(R::RatingsTable, d) = size(R.ratings, d)
lastindex(R::RatingsTable) = size(R.ratings, 1)

# create empty RatingsTable with players as names of columns
function RatingsTable(players::Array{String,1})
    R = DataFrame( Matrix{Union{Missing,Float64}}(undef, 0, length(players)) )
    names!(R, Symbol.(players))
    return RatingsTable(players, R)
end

# create empty RatingsTable with players as names of columns, and n empty rows
function RatingsTable(players::Array{String,1}, n::Int)
    R = DataFrame( Matrix{Union{Missing,Float64}}(undef, n, length(players)) )
    names!(R, Symbol.(players))
    return RatingsTable(players, R)
end

# create a RatingsTable from a RatingsList (with same players, and one row giving the set ratings)
function RatingsTable(r::RatingsList)
    A = DataFrame( Matrix{Union{Missing,Float64}}(undef, 1, length(r)) )
    names!(A, Symbol.(r.players))
    for k in keys(r.ratings)
        A[ Symbol(k) ] = r.ratings[k]
    end
    return RatingsTable(r.players, A)
end

# append one RatingsTable onto another
function append!(R1::RatingsTable, R2::RatingsTable)
    append!(R1.ratings, R2.ratings)
    return R1
end

# add a row to a RatingsTable from a RatingsList (they must have matching players lists)
function push!(R::RatingsTable, r::RatingsList)
    if R.players != r.players
        error("must have matching player lists")
    end
    x = RatingsTable(r)
    append!(R, x)
    return R
end

# insert a row into a RatingsTable from a ratings list -- not sure if this is needed?
# function insert!(R::RatingsTable, i::Int, r::RatingsList) # insert a row into a existing RatingsTable
#    
# end

# address rows of a RatingsTable
getindex(R::RatingsTable, i::Int) = R.ratings[i,:]
getindex(R::RatingsTable, range::UnitRange{Int}) = R.ratings[range,:]
function setindex!(R::RatingsTable, r::RatingsList, i::Int)
    R.ratings[i,:] = RatingsTable(r).ratings
end

# compare RatingsTables
==(R1::RatingsTable, R2::RatingsTable) = (R1.players == R2.players) && (R1.ratings == R2.ratings)

