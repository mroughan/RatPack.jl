# generate test plots of scores
#    matching https://en.wikipedia.org/wiki/Scoring_rule
#
#
using RatPack
using PyPlot

x = collect( 0 : 0.01 : 1.0 )
norm = false
norm = true

rule_log = ScoreLogarithmic(; normalise=norm )
y_log = zeros(size(x))
for i=1:length(x)
    y_log[i] = scoring_function( rule_log, [x[i], 1-x[i]], 1 ) 
end

rule_brier = ScoreBrier(; normalise=norm )
y_brier = zeros(size(x))
for i=1:length(x)
    y_brier[i] = scoring_function( rule_brier, [x[i], 1-x[i]], 1 ) 
end

rule_quad = ScoreQuadratic(; normalise=norm )
y_quad = zeros(size(x))
for i=1:length(x)
    y_quad[i] = scoring_function( rule_quad, [x[i], 1-x[i]], 1 ) 
end

rule_sphere = ScoreSpherical(; normalise=norm )
y_sphere = zeros(size(x))
for i=1:length(x)
    y_sphere[i] = scoring_function( rule_sphere, [x[i], 1-x[i]], 1 ) 
end


figure(1)
clf()
plot(x, y_log) 
plot(x, y_brier) 
plot(x, y_quad) 
plot(x, y_sphere) 
ylim([-3, 1])





# test scoring on cases

