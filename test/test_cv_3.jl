# test cross-validation, when the simulation includes home-ground advantage
using RatPack
using Random
using Distributions
using PlotlyJS


# generate large simulated dataset
include("test_sim_3.jl")

# test prediction/scoring
Random.seed!(2)
n2 = 1000
sim2 = SimRoundRobinF(;n=n2, factor_scale=real_f)
(test_competitions, winner) = simulate( real_ratings, sim2, perf_model )
srule = ScoreBrier(;normalise=true)
s0 = score_ratings( srule, test_competitions, irule, initial_ratings )
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

f_s = 0.0 : 20.0 : 600.0
score_f = zeros(size(f_s))
for (i,f) in enumerate( f_s )
    tmp_rule = UpdateIterate( rule=UpdateEloF(;r0 = r0, K = 30.0, θ=θ, factor_scale=f), batch_size=batch_size )
    new_ratings = update_ratings(tmp_rule, initial_ratings, input_competitions)
    score_f[i] = score_ratings( srule, test_competitions, tmp_rule, new_ratings )
end

data1 = scatter(;x=f_s, y=score_f, mode="lines+markers", name="misfit scale factor")
# data2 = scatter(;x=[θ, θ], y=[s2, s2], mode="markers", name="optimal")
# data3 = scatter(;x=[0.0, 0.0], y=[s3, s3], mode="markers", name="deterministic")
# data = [data1, data2, data3]
data = [data1]
layout = Layout(;
                xaxis=attr(title="f_s" ),
                yaxis=attr(title="(normalised) Brier score" ),
                )
PlotlyJS.plot( data, layout )
