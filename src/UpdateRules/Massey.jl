export UpdateMassey

"""
    UpdateMassey

 Massey update rule, e.g., see "Whos's #1", Langville and Meyer, p.9

## Parameters (none)
```
"""
struct UpdateMassey <: UpdateRule
# this is a batch calculation that takes no account of past ratings, and
# has no parameters
end

function update_info( rule::UpdateMassey )
    name = "Massey"
    reference = "\"Whos's #1\", Langville and Meyer, p.9"
    mode = "batch"    # alternatives: "batch", "recursive" 
    input = "score"   # alternatives: "outcome", "score"
    model = "single"  # alternatives: "single", "offence/defence"
    ties = true       # scores based systems can incorporate ties
    factors = false   # can it include extra factors
    parameters = []
    return name, reference, mode, input, model, ties, factors, parameters
end
update_info( ::Type{UpdateMassey} ) =  update_info( UpdateMassey() )

function update_ratings( rule::UpdateMassey,
                         input_ratings::RatingsList,
                         input_competitions::DataFrame)
    n = size(input_competitions,1)
    m = length( input_ratings.players )
    I = player_indexes( input_ratings.players )
    
    # construct Massey matrices and vectors
    M = zeros(Int,m,m)
    p = zeros(Int, m)
    d = input_competitions # just an abbreviation
    point_diff = d[:,ScoreA] - d[:,ScoreB]
    for i=1:n
        p[ I[d[i,PlayerA]] ] +=  point_diff[i]
        p[ I[d[i,PlayerB]] ] -=  point_diff[i]
        M[ I[d[i,PlayerA]], I[d[i,PlayerB]] ] -= 1
        M[ I[d[i,PlayerB]], I[d[i,PlayerA]] ] -= 1
        M[ I[d[i,PlayerA]], I[d[i,PlayerA]] ] += 1
        M[ I[d[i,PlayerB]], I[d[i,PlayerB]] ] += 1
    end
    M̅  = copy(M) # "M\u0305" to get Mbar
    M̅[end,:] = ones(size(M[end,:]))
    p̅  = copy(p)
    p̅[end] = 0    
    
    # solve Massey's equation
    r = M̅  \  p̅  
    ratings = Dict{String, Float64}()
    for player in input_ratings.players
        ratings[player] = r[ I[player] ]
    end
        
    # output ratings list
    output_ratings = RatingsList(m, input_ratings.players, ratings )   
    return output_ratings
end