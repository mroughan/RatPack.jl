export PlayerA, PlayerB, Outcome, FactorA, FactorB, ScoreA, ScoreB, Margin, No # various useful symbol abbreviations
export check_ratings, read_ratings, write_ratings
export check_results, read_results, write_results, summarize, summarizeF
export read_ratingstable, write_ratingstable 

# useful symbols for working with ratings data frames
PlayerA = Symbol("Player A")
PlayerB = Symbol("Player B")
Outcome = Symbol("Outcome")
FactorA = Symbol("Factor A")
FactorB = Symbol("Factor B")
ScoreA = Symbol("Score A")
ScoreB = Symbol("Score B")
Margin = Symbol("Margin")
Result = Symbol("Result")
No = Symbol("No. of matches")
# don't need to abbreviate
#  :Players, :Ratings


#####################################
#  ranked lists
#####################################


#####################################
#  I/O of ratings dataframes
#####################################

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
 
# convert an input DataFrame into a RatingsList object
function convert(::Type{RatingsList}, df::DataFrame )
    n = size(df,1)
    r = RatingsList(df[:Players],
                    Dict( [ df[r,:Players] => df[r,:Ratings] for r=findall( .!ismissing.(df[:,:Ratings])) ] )
                    )
    return r
end

# convert a RatingsList object into a DataFrame for output
function convert(::Type{DataFrame}, r::RatingsList )
    m = length(r.players)
    x = Array{Union{Missing, Float64}, 1}(undef, m)
    for i=1:m
        if haskey(r.ratings, r.players[i])
            x[i] = r.ratings[ r.players[i] ]
        end
    end
    df = DataFrame(Players=r.players, Ratings=x)
    return df
end

# read in a CSV file of ratings
function read_ratings( file::String )
    df = CSV.read(file; comment="#")
    check_ratings( df )
    r = convert( RatingsList, df )
    return df, r
end

# write a RatingsList to a file
function write_ratings( file::String, r::RatingsList )
    # write comments into file??? -- perhaps by appending to a file???
    df = convert(DataFrame, r)
    CSV.write(file, df)
end

#####################################
#  competition lists
#####################################
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

    if haskey(df, Outcome)
        if !( eltype(df[Outcome]) <: Union{Missing, Integer} )
            error("Input DataFrame 'Outcome' column must have type Union{Missing, Integer}")
        end
        if maximum(skipmissing(df[Outcome])) > 1 ||  minimum(skipmissing(df[Outcome])) < -1
            error("Input DataFrame 'Outcome' column should be -1,0,1 (or missing)")
        end
    end

    if haskey(df, Result)
        if !( eltype(df[Result]) <: Union{Missing, Real} )
            error("Input DataFrame 'Result' column must have type Union{Missing, Real}")
        end
        if minimum(skipmissing(df[Result])) < 0
            error("Input DataFrame 'Result' column should be >= 0 (or missing)")
            # should really check it is an integer or half integer
        end
        if !haskey(df, No)
            error("Input DataFrame 'Result' column also requires 'No. of matches' column")
        end
        if !( eltype(df[No]) <: Union{Missing, Integer} )
            error("Input DataFrame 'No. of matches' column must have type Union{Missing, Integer}")
        end
        if minimum(skipmissing(df[No])) < 1
            error("Input DataFrame 'No. of matches' column should be >= 1 (or missing)")
        end
    end

    if haskey(df, ScoreA) && haskey(df, ScoreB)
        if !( eltype(df[ScoreA]) <: Union{Missing, Integer} )
            error("Input DataFrame 'Score A' column must have type Union{Missing, Integer}")
        end
        if !( eltype(df[ScoreB]) <: Union{Missing, Integer} )
            error("Input DataFrame 'Score B' column must have type Union{Missing, Integer}")
        end
    elseif haskey(df, ScoreA)
            error("Input DataFrame only has 'Score A' column, not 'Score B'")
    elseif haskey(df, ScoreB)
            error("Input DataFrame only has 'Score B' column, not 'Score A'")
    end  

    if haskey(df, Margin) && !( eltype(df[Margin]) <: Union{Missing, Integer} )
        error("Input DataFrame 'Margin' column must have type Union{Missing, Integer}")
    end

    if haskey(df, FactorA) && haskey(df, FactorB)
        if !( eltype(df[FactorA]) <: Union{Missing, Integer} )
            error("Input DataFrame 'Factor A' column must have type Union{Missing, Integer}")
        end
        if !( eltype(df[FactorB]) <: Union{Missing, Integer} )
            error("Input DataFrame 'Factor B' column must have type Union{Missing, Integer}")
        end
    elseif haskey(df, FactorA)
            error("Input DataFrame only has 'Factor A' column, not 'Factor B'")
    elseif haskey(df, FactorB)
            error("Input DataFrame only has 'Factor B' column, not 'Factor A'")
    end  

    # add columns that we can add
    if haskey(df, ScoreA) && haskey(df, ScoreB) && !haskey(df, Margin)
        df[Margin] = df[ScoreA] - df[ScoreB]
    end

    if haskey(df, Margin) && !haskey(df, Outcome)
        df[Outcome] = sign.(df[Margin])
    end

    # check for consistency between different types of inputs 
    if !all(skipmissing( df[Margin] .== df[ScoreA] - df[ScoreB] ))
        error("Input DataFrame: Margins are inconsistent with Scores")
    end
    if !all(skipmissing( df[Outcome] .== sign.(df[Margin]) ))
        error("Input DataFrame: Outcomes are inconsistent with Margins")
    end
 
    # results format isn't compatible with outcomes (or scores and margins)
    # so don't try to translate from one to the other (at the moment)
    # but we could at least check that both aren't there
    # should also check that
    #   - Result <= No
  
end
 
# read in a CSV file of competitions
function read_results( file::String )
    df = CSV.read(file; comment="#")
    check_results( df )
    df[PlayerA] = coalesce.( df[PlayerA], "" ) # replace missing player names with blanks (for the moment)
    df[PlayerB] = coalesce.( df[PlayerB], "" ) # replace missing player names with blanks (for the moment)
    player_list = merge(+, countmap( df[PlayerA] ), countmap( df[PlayerB] )  ) 
    return df, player_list
end

function write_results( file::String, df::DataFrame)
    CSV.write(file, df)
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

# summarize a list of competitions with home/away factors
#   presumes that exactly one of FactorA and FactorB is 0, and one is 1 indicating home-ground
function summarizeF( df::DataFrame,  player_list::Dict{String,Int64})
    home_wins = copy(player_list)
    away_wins = copy(player_list)
    home_games = copy(player_list)
    away_games = copy(player_list)
    reset!(home_wins)
    reset!(away_wins)
    reset!(home_games)
    reset!(away_games)
    score_diff = Dict{String,Int64}()
    for i=1:size(df,1)
        # ignores ties
        if df[i,Outcome] == 1 && df[i,FactorA] == 1
            increment!(home_wins, df[i,PlayerA], 1)
            increment!(home_games, df[i,PlayerA], 1)
            increment!(away_games, df[i,PlayerB], 1)
        elseif df[i,Outcome] == 1 && df[i,FactorA] == 0
            increment!(away_wins, df[i,PlayerA], 1)
            increment!(away_games, df[i,PlayerA], 1)
            increment!(home_games, df[i,PlayerB], 1)
        elseif df[i,Outcome] == -1 && df[i,FactorB] == 1
            increment!(home_wins, df[i,PlayerB], 1)
            increment!(home_games, df[i,PlayerB], 1)
            increment!(away_games, df[i,PlayerA], 1)
        elseif df[i,Outcome] == -1 && df[i,FactorB] == 0
            increment!(away_wins, df[i,PlayerB], 1)
            increment!(away_games, df[i,PlayerB], 1)
            increment!(home_games, df[i,PlayerA], 1)
        end
        diff = df[i,ScoreA] - df[i,ScoreB]
        increment!(score_diff, df[i,PlayerA], diff)
        increment!(score_diff, df[i,PlayerB], -diff)
    end

    new_df = DataFrame( Player=Array{String,1}(), HomeRecord=Array{String,1}(), AwayRecord=Array{String,1}() )
    for p in keys(player_list)
        push!( new_df, [p, "$(home_wins[p])/$(home_games[p])", "$(away_wins[p])/$(away_games[p])" ])
    end
    return new_df
end

# is there any need to write out a list of competition results????


#####################################
#  RatingsTable
#####################################

# read in a CSV file of ratings
function read_ratingstable( file::String )
    df = CSV.read(file; comment="#")
    # haven't written routines to check the input ratings table yet
    players = String.(names(df))
    return RatingsTable(players, df)
end

# write a RatingsList to a file
function write_ratingstable( file::String, R::RatingsTable )
    # write comments into file??? -- perhaps by appending to a file???
    CSV.write(file, R.ratings)
end
