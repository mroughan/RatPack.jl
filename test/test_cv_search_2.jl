# test using cross-validation and a search algorithm to optimise the value of a hyper-parameter
using RatPack
using Random
using Distributions
using PlotlyJS


# generate large simulated dataset, and run base cross-validation on it, and optimise hyper-parameters
include("test_cv_2.jl")

##############################################3
# optimise theta
r = [10.0, 500.0]
ε = 1.0e-1
score(t) = score_ratings( srule, test_competitions,
                         UpdateIterate( rule=UpdateElo(;r0 = r0, K = 10.0, θ=t ), batch_size=batch_size ),
                         real_ratings
                         )
(x_star1, y_star1, error_estimate1, n_evaluations1) = linesearch( "Golden", x->score(x); range=r, ε=ε)

data1 = scatter(;x=θ_test, y=score_s, mode="lines+markers", name="misfit θ")
data2 = scatter(;x=[θ, θ], y=[s2, s2], mode="markers", marker=attr(symbol="x", size=12), name="Input value")
data3 = scatter(;x=[0.0, 0.0], y=[s3, s3], mode="markers",  marker=attr(symbol="diamond-dot", size=12), name="Deterministic")
data4 = scatter(;x=[x_star1, x_star1], y=[y_star1, y_star1], mode="markers", marker=attr(symbol="diamond-dot", size=12), name="Maximum")
    
data = [data1, data2, data3, data4]
layout = Layout(;
                xaxis=attr(title="θ" ),
                yaxis=attr(title="(normalised) Brier score" ),
                )
p1 = PlotlyJS.plot( data, layout )
redraw!(p1)
# interestingly the optimal choice of theta is just slightly different from the real value
# but that is just probably the result of using a random simulation

#######################################
# optimise K
r = [0.0, 40.0]
ε = 1.0e-1
score(k) = score_ratings( srule, test_competitions,
                         UpdateIterate( rule=UpdateElo(;r0 = r0, K = k, θ=θ ), batch_size=batch_size ),
                         update_ratings(UpdateIterate( rule=UpdateElo(;r0 = r0, K = k, θ=θ ), batch_size=batch_size ), initial_ratings, input_competitions)
                         )
(x_star2, y_star2, error_estimate2, n_evaluations2) = linesearch( "Golden", x->score(x); range=r, ε=ε)


data1 = scatter(;x=Ks, y=score_k, mode="lines+markers", name="score as a function of K")
data2 = scatter(;x=[0, maximum(Ks)], y=[s2, s2], mode="lines", name="upper bound")
data3 = scatter(;x=[x_star2, x_star2], y=[y_star2, y_star2], mode="markers", marker=attr(symbol="diamond-dot", size=12), name="maximum")
    
data = [data1, data2, data3]
layout = Layout(;
                xaxis=attr(title="K" ),
                yaxis=attr(title="(normalised) Brier score" ),
                )
p2 = PlotlyJS.plot( data, layout )
redraw!(p2)
