export UpdateRevert

"""
    UpdateRevert

 Revert a set of ratings to a baseline rating using weighted average
    -- repeated used could be used to do EWMA smoother

## Parameters
* `r_base::Float64`: baseline rating to revert towards
* `α::Float64`:      weight to give to new data
 
```
"""
struct UpdateRevert <: UpdateRule
    r_base::Float64
    α::Float64
    function UpdateRevert(r_base, α)
        @check_args(UpdateElo, α >= zero(α))
        @check_args(UpdateElo, α <= one(α))
        new(r_base, α)
    end
end
UpdateRevert(;r_base=1500.0, α=0.15) = UpdateRevert(r_base, α)

function update_info( rule::UpdateRevert )
    name = "Revert"
    reference = "??? 538 "
    mode = "recursive"# alternatives: "batch", "recursive" 
    input = "none"    # competition outcomes are ignored
    model = "single"  # alternatives: "single", "offence/defence" (could be "either")
    ties = true       # scores based systems can incorporate ties
    factors = false   # can it include extra factors
    parameters = ["r_base", "α"]
    return name, reference, mode, input, model, ties, factors, parameters
end
update_info( ::Type{UpdateRevert} ) =  update_info( UpdateRevert() )

function update_ratings( rule::UpdateRevert,
                         input_ratings::RatingsList,
                         input_competitions::DataFrame)
    m = length( input_ratings.players )
    I = player_indexes( input_ratings.players )
    
    r = copy( input_ratings.ratings )
    for p in input_ratings.players
        if !haskey( r, p )# set initial ratings if they aren't already
            r[p] = rule.r_base
        else
            r[p] = (1-rule.α) * rule.r_base  +   rule.α * r[p]
        end
    end
       
    # output ratings list
    output_ratings = RatingsList(m, input_ratings.players, r )   
    return output_ratings
end

function update_ratings( rule::UpdateRevert,
                         input_ratings::RatingsList )
    output_ratings = update_ratings( rule, input_ratings, DataFrame() )
end
