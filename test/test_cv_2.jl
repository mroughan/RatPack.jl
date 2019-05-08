# test cross-validation
using RatPack
using Random
using Distributions
using PlotlyJS


# generate large simulated dataset
include("test_sim_2.jl")

# test prediction/scoring
Random.seed!(2)
n2 = 1000
sim2 = SimRoundRobin(n2)
(test_competitions, winner) = simulate( real_ratings, sim2, perf_model )
srule = ScoreBrier(;normalise=true)
s1 = score_ratings( srule, test_competitions, irule, simple_ratings )
s2 = score_ratings( srule, test_competitions, irule, real_ratings )

println("score with real ratings = $s2, score with simulated ratings = $s1")

# test cross-validation
k = 10
Random.seed!(1)
S1 = cross_validate(irule, input_competitions;
                   k = k,
                   n_samples = 1000,
                   batch_size = 1,
                   srule = ScoreBrier(;normalise=true) )

println(" S1bar = $(sum(S1)/k)")

# see what happens when prediction rule mismatch with rule used to create the ratings
s3 = score_ratings( srule, test_competitions, UpdateColley(), real_ratings )

θ_test = 10.0 : 10.0 : 500.0
score_s = zeros(size(θ_test))
for (i,t) in enumerate( θ_test )
    tmp_rule = UpdateIterate( rule=UpdateElo(;r0 = r0, K = 10.0, θ=t ), batch_size=batch_size )
    score_s[i] = score_ratings( srule, test_competitions, tmp_rule, real_ratings )
end

data1 = scatter(;x=θ_test, y=score_s, mode="lines+markers", name="misfit θ")
data2 = scatter(;x=[θ, θ], y=[s2, s2], mode="markers", name="optimal")
data3 = scatter(;x=[0.0, 0.0], y=[s3, s3], mode="markers", name="deterministic")
data = [data1, data2, data3]
layout = Layout(;width=600, height=400,
                xaxis=attr(title="θ" ),
                yaxis=attr(title="(normalised) Brier score" ),
                )
PlotlyJS.plot( data, layout )

# consider optimising the value of K
Ks = 0.0 : 2.0 : 40.0
score_k = zeros(size(Ks))
for (i,k) in enumerate( Ks )
    tmp_rule = UpdateIterate( rule=UpdateElo(;r0 = r0, K = k, θ=θ ), batch_size=batch_size )
    simple_ratings = update_ratings(tmp_rule, initial_ratings, input_competitions)
    score_k[i] = score_ratings( srule, test_competitions, tmp_rule, simple_ratings )
end

data1 = scatter(;x=Ks, y=score_k, mode="lines+markers", name="score as a function of K")
data2 = scatter(;x=[0, maximum(Ks)], y=[s2, s2], mode="lines", name="upper bound")
    
data = [data1, data2]
layout = Layout(;
                xaxis=attr(title="K" ),
                yaxis=attr(title="(normalised) Brier score" ),
                )
PlotlyJS.plot( data, layout )
