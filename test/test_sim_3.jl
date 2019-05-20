using RatPack
using StatsBase
using Distributions
using CategoricalArrays
using DataFrames
using CSV
using Random
using PlotlyJS

Random.seed!(1)
    
# generate large simulated dataset
n = 25
real_f = 200.0
sim = SimRoundRobinF(;n=n, factor_scale=real_f)
r = Dict( "P_A"=>1000.0, "P_B"=>800.0, "P_C"=>600.0, "P_D"=>400.0, "P_E"=>200.0 )
# r = Dict( "P_A"=>1000.0, "P_B"=>1000.0, "P_C"=>1000.0 )
m = length(keys(r))
ell = m*(m-1)/2
real_ratings = RatingsList( sort(collect(keys(r))), r )

r0 = sum( values(r) ) / m
r2 = copy(r)
reset!(r2; z0=r0)
initial_ratings = RatingsList( sort(collect(keys(r2))), r2 )
θ=400.0/log(10.0)
perf_model = Logistic(0.0, θ)
Random.seed!(1)
(input_competitions, winner) = simulate( real_ratings, sim, perf_model )
player_list = merge(+, countmap( input_competitions[PlayerA] ), countmap( input_competitions[PlayerB] )  ) 
show(summarize( input_competitions, player_list ))
println()
show(summarizeF(input_competitions, player_list ))
println()

# just do standard ratings, and see if they converge
batch_size = 10
irule = UpdateIterate( rule=UpdateEloF(;r0 = r0, K = 10.0, θ=θ, factor_scale=real_f ), batch_size=batch_size )
R = RatingsTable( initial_ratings.players, Int(ceil(n*ell/batch_size)) )
simple_ratings = update_ratings(irule, initial_ratings, input_competitions; record=R)

println("sum real = $(sum( values(real_ratings.ratings) )), sum initial = $(sum( values(initial_ratings.ratings) )), sum final = $(sum( values(simple_ratings.ratings) ))")
 
# PlotlyJS.plot( coalesce.(R.ratings[:P_A], r0) )
# PlotlyJS.plot( coalesce.(R.ratings[:P_B], r0) )

