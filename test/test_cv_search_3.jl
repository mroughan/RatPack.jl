# test using cross-validation and a search algorithm to optimise the value of a hyper-parameter for scale of factors
using RatPack
using Random
using Distributions
using PlotlyJS


# generate large simulated dataset, and run base cross-validation on it, and optimise hyper-parameters
include("test_cv_3.jl")

#######################################
# optimise the scale factor, given home-ground advantages
r = [0.0, 400.0]
ε = 1.0e-0
score(f) = score_ratings( srule, test_competitions,
                         UpdateIterate( rule=UpdateEloF(;r0 = r0, K = 30.0, θ=θ, factor_scale=f ), batch_size=batch_size ),
                         update_ratings(UpdateIterate( rule=UpdateEloF(;r0 = r0, K = 30.0, θ=θ, factor_scale=f ), batch_size=batch_size ), initial_ratings, input_competitions)
                         )
(x_star2, y_star2, error_estimate2, n_evaluations2) = linesearch( "Golden", x->score(x); range=r, ε=ε)


data1 = scatter(;x=f_s, y=score_f, mode="lines+markers", name="score as a function of f_s")
data2 = scatter(;x=[0, maximum(score_f)], y=[s2, s2], mode="lines", name="upper bound")
data3 = scatter(;x=[x_star2, x_star2], y=[y_star2, y_star2], mode="markers", marker=attr(symbol="diamond-dot", size=12), name="maximum")
    
data = [data1, data2, data3]
layout = Layout(;
                xaxis=attr(title="f_s" ),
                yaxis=attr(title="(normalised) Brier score" ),
                )
p2 = PlotlyJS.plot( data, layout )
