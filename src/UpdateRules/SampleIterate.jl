export UpdateSampleIterate

"""
    UpdateSampleIterate <: UpdateRule

 Update using by iterating over another recursive rule, while sampling from the input

## Parameters
* `rule::UpdateRule`: rule to use at each iteration (default is Elo() )
* `batch_size::Int`: the size of batches to use (default is 1)
* `n_samples::Int`: the number of random samples to take
* ``

## Not implemented yet
* `batching_rule::` ??? how to select batches ???

```
"""
struct UpdateSampleIterate <: UpdateRule
    rule::UpdateRule
    batch_size::Int
    n_samples::Int
    function UpdateSampleIterate(rule::UpdateRule, batch_size::Int, n_samples::Int)
        @check_args(UpdateSampleIterate, batch_size >= one(batch_size))
        @check_args(UpdateSampleIterate, n_samples >= one(n_samples))
        @check_args(UpdateSampleIterate, update_info(rule)[:state_model] == "recursive")
        new(rule, batch_size, n_samples)
    end
end
UpdateSampleIterate(;rule::UpdateRule=UpdateElo(), batch_size::Int=1, n_samples::Int=1) = UpdateSampleIterate( rule, batch_size, n_samples)

function update_info( rule::UpdateSampleIterate )
    info = Dict(
                :name => "SampleIterate",
                :reference => "none",
                :computation => "sequential",
                :state_model => "recursive",
                :input => update_info( rule.rule )[:input], 
                :output => update_info( rule.rule )[:output],
                :model => update_info( rule.rule )[:model], 
                :ties => update_info( rule.rule )[:ties], 
                :factors => update_info( rule.rule )[:factors], 
                :parameters => append!( ["rule(default=Elo)", "batch_size(default=1)"], update_info( rule.rule )[:parameters] ),
                :record => true
                )
    return info
end
update_info( ::Type{UpdateSampleIterate} ) =  error("Need to specify the sub-rule")

function update_ratings( rule::UpdateSampleIterate,
                         input_ratings::RatingsList,
                         input_competitions::DataFrame;
                         record::Union{Missing,RatingsTable}=missing)
    n = size(input_competitions,1)
    m = length( input_ratings.players )
    I = player_indexes( input_ratings.players )
    r = deepcopy(input_ratings)

    # select a batch, and then update using the appropriate rule
    d = input_competitions # just an abbreviation
    for (j,i) = enumerate( 1 : rule.batch_size : rule.n_samples )
        rows = d[ rand(1:n, rule.batch_size), :]
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

function predict_outcome(rule::UpdateSampleIterate,
                         ratingA::Real, ratingB::Real, 
                         factorA::Union{Missing,Real}, factorB::Union{Missing,Real})
    return predict_outcome(rule.rule, ratingA, ratingB, factorA, factorB)
end
