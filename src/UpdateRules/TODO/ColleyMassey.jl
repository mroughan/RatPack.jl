export UpdateColleyMassey

"""
    UpdateColleyMassey

 Colley update rule applied to scores, e.g., see "Whos's #1", Langville and Meyer, p.25
   this is the "Masseyized Colley method", i.e., using Massey's matrix on outcomes

## Parameters (none)
```
"""
struct UpdateColleyMassey <: UpdateRule
# this is a batch calculation that takes no account of past ratings, and
# has no parameters
end

function update_info( rule::UpdateColleyMassey )
    name = "ColleyMassey"
    reference = "\"Whos's #1\", Langville and Meyer, p.25"
    mode = "batch"    # alternatives: "batch", "recursive" 
    input = "outome"  # alternatives: "outcome", "score"
    model = "single"  # alternatives: "single", "offence/defence"
    ties = false      # can it incorporate ties
    factors = false   # can it include extra factors
    parameters = []
    return name, reference, mode, input, model, ties, factors, parameters
end
update_info( ::Type{UpdateColleyMassey} ) =  update_info( UpdateColleyMassey() )

function update_ratings( rule::UpdateColleyMassey,
                         input_ratings::RatingsList,
                         input_competitions::DataFrame)
    n = size(input_competitions,1)
    m = length( input_ratings.players )
    I = player_indexes( input_ratings.players )
    
    # construct Colley matrices and vectors
    M = zeros(Int,m,m)
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
        M[ I[d[i,PlayerA]], I[d[i,PlayerB]] ] -= 1
        M[ I[d[i,PlayerB]], I[d[i,PlayerA]] ] -= 1
        M[ I[d[i,PlayerA]], I[d[i,PlayerA]] ] += 1
        M[ I[d[i,PlayerB]], I[d[i,PlayerB]] ] += 1
    end
    M̅  = copy(M) # "M\u0305" to get Mbar
    M̅[end,:] = ones(size(M[end,:]))
    b = 1 .+ 0.5*(wins .- losses)
    b_bar = copy(b)
    b_bar[end] = 0    
    
    # solve Massey's equation
    r = M̅  \  b_bar 
    ratings = Dict{String, Float64}()
    for player in input_ratings.players
        ratings[player] = r[ I[player] ]
    end
        
    # output ratings list
    output_ratings = RatingsList(m, input_ratings.players, ratings )   
    return output_ratings
end
