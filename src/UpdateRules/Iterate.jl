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
        @check_args(UpdateIterate, update_info(rule)[:mode] == "recursive")
        new(rule, batch_size)
    end
end
UpdateIterate(;rule::UpdateRule=UpdateElo(), batch_size::Int=1 ) = UpdateIterate( rule, batch_size )

function update_info( rule::UpdateIterate )
    info = Dict(
                :name => "Iterate",
                :mode => "recursive", 
                :reference => "none",
                :input => update_info( rule.rule )[:input], 
                :output => update_info( rule.rule )[:output],
                :model => update_info( rule.rule )[:model], 
                :ties => update_info( rule.rule )[:ties], 
                :factors => update_info( rule.rule )[:factors], 
                :parameters => append!( ["rule(=Elo)", "batch_size(=1)"], update_info( rule.rule )[6] )
                )
    return info
end
update_info( ::Type{UpdateIterate} ) =  error("Need to specify the sub-rule")

function update_ratings( rule::UpdateIterate,
                         input_ratings::RatingsList,
                         input_competitions::DataFrame;
                         record::Union{Missing,RatingsTable}=missing)
    n = size(input_competitions,1)
    m = length( input_ratings.players )
    I = player_indexes( input_ratings.players )
    r = copy(input_ratings)

    # select a batch, and then update using the appropriate rule
    d = input_competitions # just an abbreviation
    for (j,i) = enumerate( 1 : rule.batch_size : n )
        start = i
        fin = min(n, i+rule.batch_size-1)
        rows = d[ start:fin, :]
        r = update_ratings(rule.rule, r, rows) 
        if !ismissing(record) && size(record,1)>=j
            record[j] = r # record results if required, and space allocated
        elseif !ismissing(record)
            println("Warn: out of space to record ratings: j=$j of $(size(record,1))")
        end
    end
                          
    # output ratings list
    return r
end

