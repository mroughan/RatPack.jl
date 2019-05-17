export UpdateColley

"""
    UpdateColley

 Colley update rule, e.g., see "Whos's #1", Langville and Meyer, p.21

## Parameters (none)
```
"""
struct UpdateColley <: UpdateRule
# this is a batch calculation that takes no account of past ratings, and
# has no parameters
end

function update_info( rule::UpdateColley )
    info = Dict(
                :name => "Colley",
                :reference => "\"Whos's #1\", Langville and Meyer, p.21",
                :computation => "simultaneous",
                :state_model => "none",
                :input => "outcome",
                :output => "deterministic",
                :model => "single",
                :ties => false,
                :factors => false,
                :parameters => [],
                :record => false
                )
    return info
end
update_info( ::Type{UpdateColley} ) =  update_info( UpdateColley() )

function update_ratings( rule::UpdateColley,
                         input_ratings::RatingsList,
                         input_competitions::DataFrame)
    n = size(input_competitions,1)
    m = length( input_ratings.players )
    I = player_indexes( input_ratings.players )
    
    # construct Colley matrices and vectors
    C = diagm(0 => 2*ones(Int,m))
    wins = zeros(Int, m)
    losses = zeros(Int, m)
    d = input_competitions
    for i=1:n
        if d[i,Outcome] == 1
            wins[I[d[i,PlayerA]]] += 1
            losses[I[d[i,PlayerB]]] += 1
        elseif d[i,Outcome] == -1
            wins[I[d[i,PlayerB]]] += 1
            losses[I[d[i,PlayerA]]] += 1
        end
        C[ I[d[i,PlayerA]], I[d[i,PlayerB]] ] -= 1
        C[ I[d[i,PlayerB]], I[d[i,PlayerA]] ] -= 1
        C[ I[d[i,PlayerA]], I[d[i,PlayerA]] ] += 1
        C[ I[d[i,PlayerB]], I[d[i,PlayerB]] ] += 1
    end

    # solve Colley's equation
    b = 1 .+ 0.5*(wins .- losses)
    r = C \ b
    ratings = Dict{String, Float64}()
    for player in input_ratings.players
        ratings[player] = r[ I[player] ]
    end
        
    # output ratings list
    output_ratings = RatingsList(input_ratings.players, ratings )   
    return output_ratings
end

# Colley's predictions are deterministic, unless you apply some model after the fact
function predict_outcome(rule::UpdateColley,
                         ratingA::Real, ratingB::Real, 
                         factorA::Union{Missing,Real}, factorB::Union{Missing,Real})
    rating_diff = ratingA - ratingB
    s = sign(rating_diff)
    if s==1
        return (1.0, 0.0, 0.0)
    elseif s==-1
        return (0.0, 1.0, 0.0)
    else
        return (0.0, 0.0, 1.0)
    end
end
