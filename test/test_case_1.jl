
using StatsBase
using Distributions
using CategoricalArrays
using DataFrames
using CSV
using RatPack

file = "../examples/test_ratings.csv"
(a,b) = read_ratings(file)

file = "../examples/test_competitions.csv"
(c,d) = read_results( file )

R = RatingsList( d )

file = "../data/test_competitions_1.csv"
(e,f) = read_results( file )
summarize(e, f)

input_ratings = RatingsList( f )
input_competitions = e

ratings = update_ratings(UpdateColley(),
                         input_ratings,
                         input_competitions)           


ratings = update_ratings(UpdateKeenerScores(; skew = false),
                         input_ratings,
                         input_competitions)           


ratings = update_ratings(UpdateElo(;r0 = 0.0),
                         input_ratings,
                         input_competitions)           


# try out the NFL data
file = "../data/nfl_2009_regular.csv"
(e,f) = read_results( file )
summarize(e, f)

input_ratings = RatingsList( f )
input_competitions = e

ratings = update_ratings(UpdateKeenerScores(; skew=true, norm=false),
                         input_ratings,
                         input_competitions)           

S = sort(collect(ratings.ratings), by = tuple -> last(tuple), rev=true)



# iterate Elo on the data, one by one
file = "../data/nfl_2009.csv"
(nfl_ext_competitions,  nfl_ext_player_list) = read_results( file )
nfl_ext_ratings = RatingsList( nfl_ext_player_list )

rule = UpdateElo(;r0 = 0.0, K = 32.0, θ=1000.0/log(10.0) )
r = nfl_ext_ratings
for i=1:size(nfl_ext_competitions,1)
    global r = update_ratings(rule, r, nfl_ext_competitions[ [i], :])           
end
S = sort(collect(r.ratings), by = tuple -> last(tuple), rev=true)

mean(last.(S)) # should be close to r0 = 0.0

