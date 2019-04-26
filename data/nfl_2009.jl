# read in data from NFL (cut and paste from table produced tab delim data)
#      data from https://www.pro-football-reference.com/years/2009/games.htm
# and output in my format
#
using DataFrames
using CSV
using RatPack

# read in raw TSV file
file = "nfl_2009.txt"
year = 2009 # to 2010
inp_df = CSV.read(file; comment="#", delim='\t', normalizenames=true, )
n = size(inp_df,1)
names(inp_df)
win_tie = sign.( inp_df[:PtsW] .- inp_df[:PtsL] )# Outcome is always 1 or 0, because they order the data Winner,Looser

# output results in my format
out_df = DataFrame(PlayerA=inp_df[:Winner_tie],
                   PlayerB=inp_df[:Loser_tie],
                   Outcome=win_tie,
                   FactorA=zeros(Int,n),
                   FactorB=zeros(Int,n),
                   ScoreA=inp_df[:PtsW],
                   ScoreB=inp_df[:PtsL])
colnames = Symbol.(["Player A", "Player B", "Outcome", "Factor A", "Factor B", "Score A", "Score B"])
names!(out_df, colnames)
out_file = replace(file, ".txt" => ".csv")
CSV.write(out_file, out_df)

# quick test to see if file can be read in OK
(df, player_list) = read_results( out_file )
input_ratings = RatingsList( player_list )
input_competitions = df
ratings = update_ratings(UpdateColley(),
                         input_ratings,
                         input_competitions)           
sort(collect(ratings.ratings), by = tuple -> last(tuple), rev=true)


# now do likewise for only the regular season
week = inp_df[:Week]
df = inp_df[ .!(tryparse.(Int, coalesce.(week,"")) .== nothing) , :]
n = size(df,1)
win_tie = sign.( df[:PtsW] .- df[:PtsL] )# Outcome is always 1 or 0, because they order the data Winner,Looser
out_df = DataFrame(PlayerA=df[:Winner_tie],
                   PlayerB=df[:Loser_tie],
                   Outcome=win_tie,
                   FactorA=zeros(Int,n),
                   FactorB=zeros(Int,n),
                   ScoreA=df[:PtsW],
                   ScoreB=df[:PtsL])
colnames = Symbol.(["Player A", "Player B", "Outcome", "Factor A", "Factor B", "Score A", "Score B"])
names!(out_df, colnames)
out_file = replace(file, ".txt" => "_regular.csv")
CSV.write(out_file, out_df)

# now output one file per week (17 weeks in regular season)
weeks = unique( coalesce.(week,"") ) 
for w in weeks
    if !(w == nothing)
        df = inp_df[ week .== w, :]
        n = size(df,1)
        win_tie = sign.( df[:PtsW] .- df[:PtsL] )# Outcome is always 1 or 0, because they order the data Winner,Looser
        out_df = DataFrame(PlayerA=df[:Winner_tie],
                           PlayerB=df[:Loser_tie],
                           Outcome=win_tie,
                           FactorA=zeros(Int,n),
                           FactorB=zeros(Int,n),
                           ScoreA=df[:PtsW],
                           ScoreB=df[:PtsL])
        colnames = Symbol.(["Player A", "Player B", "Outcome", "Factor A", "Factor B", "Score A", "Score B"])
        names!(out_df, colnames)
        out_file = replace(file, ".txt" => "_week_$(w).csv")
        CSV.write(out_file, out_df)
    end
end
