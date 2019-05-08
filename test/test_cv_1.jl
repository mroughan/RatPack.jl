# test cross-validation
using RatPack
using Random

# first try my (largest current) dataset
file = "../data/nfl_2009.csv"
r0 = 0.0
irule = UpdateIterate( rule=UpdateElo(;r0 = r0, K = 32.0, θ=400.0/log(10.0) ), batch_size=1 )

# just do standard (sampled) ratings
r0 = 0.0
irule = UpdateIterate( rule=UpdateElo(;r0 = r0, K = 32.0, θ=400.0/log(10.0) ), batch_size=1 )
sample_ratings = update_ratings(irule, nfl_ratings, nfl_competitions)

# test prediction/scoring
srule = ScoreBrier(;normalise=true)
score( srule, nfl_competitions, irule, sample_ratings )

# try cross-validation
k = 10
Random.seed!(1)
S1 = cross_validate(irule, nfl_competitions;
                   k = k,
                   n_samples = 1000,
                   batch_size = 1,
                   srule = ScoreBrier(;normalise=true) )

Random.seed!(1)
S2 = cross_validate(irule, file;
                   k = k,
                   n_samples = 1000,
                   batch_size = 1,
                   srule = ScoreBrier(;normalise=true) )


println(" S1bar = $(sum(S1)/k), S2bar = $(sum(S2)/k)")
