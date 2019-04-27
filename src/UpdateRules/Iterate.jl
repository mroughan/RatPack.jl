export UpdateIterate

"""
    UpdateIterate <: UpdateRule

 Update using by iterating over another recursive rule.

## Parameters
* `rule::UpdateRule`: rule to use at each iteration (default is Elo() )
* `batch_size::Int`: the size of batches to use (default is 1)

## Not implemented yet
* `batching_rule::` ??? how to select batches ???

```
"""
struct UpdateIterate <: UpdateRule
    rule::UpdateRule
    batch_size::Int
    function UpdateIterate(rule::UpdateRule, batch_size::Int)
        @check_args(UpdateIterate, batch_size >= one(batch_size))
        @check_args(UpdateIterate, update_info(rule)[1] == "recursive")
        new(rule, batch_size)
    end
end
UpdateIterate(;rule::UpdateRule=UpdateElo(), batch_size::Int=1 ) = UpdateIterate( rule, batch_size )

function update_info( rule::UpdateIterate )
    mode = "recursive" # alternatives: "batch", "recursive" 
    input = update_info( rule.rule )[2] # inhereted from its update rule
    model = update_info( rule.rule )[3] # inhereted from its update rule
    ties = update_info( rule.rule )[4] # inhereted from its update rule
    factors = update_info( rule.rule )[5] # inhereted from its update rule
    parameters = append!( ["rule(=Elo)", "batch_size(=1)"], update_info( rule.rule )[6] )
    return mode, input, model, ties, facfors, parameters
end

function update_ratings( rule::UpdateIterate,
                         input_ratings::RatingsList,
                         input_competitions::DataFrame)
    n = size(input_competitions,1)
    m = length( input_ratings.players )
    I = player_indexes( input_ratings.players )
    r = copy(input_ratings)
    
    # select a batch, and then update using the appropriate rule
    d = input_competitions # just an abbreviation
    for i=1: rule.batch_size : n
        start = i
        fin = min(n, i+rule.batch_size-1)
        rows = d[ start:fin, :]
        r = update_ratings(rule.rule, r, rows) 
    end
                          
    # output ratings list
    return r
end

