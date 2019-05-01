export UpdateKeenerScores

"""
    UpdateKeenerScores

 Keener update rule, e.g., see \"Whos's #1\", Langville and Meyer, p.29
 Note Keener's method can use general inputs, this variant uses scores

## Parameters
* `skew::Bool`: skew input statistics to give more weight to small values
* `norm::Bool`: normalise input statistics by number of games played

```
"""
struct UpdateKeenerScores <: UpdateRule
    skew::Bool # skew input statistics to give more weight to small values
    norm::Bool # normalise input statistics by number of games played
end
UpdateKeenerScores(; skew=false, norm=true) = UpdateKeenerScores(skew, norm) # default no skew, but yes to normalisation

function update_info( rule::UpdateKeenerScores )
    info = Dict(
                :name => "KeenerScores",
                :reference => "\"Whos's #1\", Langville and Meyer, p.29",
                :mode => "batch",
                :input => "outcome",
                :output => "deterministic",
                :model => "single",
                :ties => true,
                :factors => false,
                :parameters => ["skew", "norm"],
                :record => true
                )
    return info
end
update_info( ::Type{UpdateKeenerScores} ) =  update_info( UpdateKeenerScores() )

# skew function
h( x::Float64 ) = 0.5*(1 + sign(x - 0.5)*sqrt(abs(2*x - 1.0)) )

function update_ratings( rule::UpdateKeenerScores,
                         input_ratings::RatingsList,
                         input_competitions::DataFrame)
    n = size(input_competitions,1)
    m = length( input_ratings.players )
    I = player_indexes( input_ratings.players )
    
    # construct KeenerScores matrices and vectors
    #   note Keener's method can use general inputs, here we use scores
    S = zeros(Int,m,m)
    n_games = zeros(Int,m)
    d = input_competitions
    for i=1:n
        n_games[ I[d[i,PlayerA]] ] += 1
        n_games[ I[d[i,PlayerB]] ] += 1
        S[ I[d[i,PlayerA]], I[d[i,PlayerB]]] += d[i,ScoreA]
        S[ I[d[i,PlayerB]], I[d[i,PlayerA]]] += d[i,ScoreB]
    end
   
    A = (S .+ 1) ./ (S .+ S' .+ 2)
    # skew if needed
    if rule.skew
        A = h.(A)
    end
    # normalise
    if rule.norm
        for i=1:m
            A[i,:] = A[i,:] ./ n_games[i]
        end
    end
    
    # solve Keener's equation
    #   assuming matrix is irreducible (all teams are linked by games)
    r = solve_keener( A )
    ratings = Dict{String, Float64}()
    for player in input_ratings.players
        ratings[player] = r[ I[player] ]
    end
        
    # output ratings list
    output_ratings = RatingsList(m, input_ratings.players, ratings )   
    return output_ratings
end

function solve_keener( A::Array{Float64, 2} )
    # make irreducible
    m = size(A,1)
    epsilon = 1.0e-8
    𝐞 = ones(Float64,m)
    A = A .+ epsilon * 𝐞 * 𝐞'

    # solve by power method (see, p.41) 
    r = ones(Float64, m)/m
    not_converged = true
    i = 0
    max_i = 100
    while not_converged && i < max_i
        σ = epsilon * sum(r)
        new_r = A*r + σ*𝐞
        ν = sum( new_r )
        new_r = new_r / ν
        if sum( abs.(new_r - r) ) < 1.0e-6
            not_converged = false
        end
        r = new_r 
        i += 1
    end
    if max_i == i
        println("WARN:   i = $i = max_i")
    end
    
    return r
end
