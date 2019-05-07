using StatsBase
using Distributions
using CategoricalArrays
using DataFrames
using CSV
using Random
using RatPack
    
file = "../examples/test_ratings2.csv"
(df,r) = read_ratings(file)

Random.seed!(1)

competitions1, w1 = simulate( r, SimRoundRobin(2), Logistic(0.0, 1000.0/log(10.0)) )

competitions2, w2 = simulate( r, SimElimination(1), Logistic(0.0, 1000.0/log(10.0)) )


