# functions that wrap around other pieces to do higher level tasks, e.g.,
#     perform cross-validation of prediction scores on a datasets
#     optimisation of a parameter
#     

"""
    test_cv_1()

 Calculates k-fold cross-validated scores for predictions based on an update rule and ratings.

## Arguments
* `rule::UpdateRule`: the update rule to test
* `input_competitions::DataFrame`: a DataFrame in format specified in IO.jl
* `k::Int = 10`: doing k-fold cross-validation
* `n_samples::Int = 1000`: number of re-samples of the underlying dataset to use (see SampleIterate.jl)
* `batch_size::Int = 30`: size of batches in re-sampled iteration (see SampleIterate.jl)
* `srule::ScoringRule = ScoreBrier(;normalise=true)`: scoring schema to use (see ScoringRules/)

## Outputs
* S = length k vector of the cross-validation scores

```
"""
function cross_validate(rule::UpdateRule, input_competitions::DataFrame;
                        k::Int = 10,
                        n_samples::Int = 1000,
                        batch_size::Int = 30,
                        srule::ScoringRule = ScoreBrier(;normalise=true) )
    player_list = merge(+, countmap( input_competitions[PlayerA] ), countmap( input_competitions[PlayerB] )  )
    input_ratings = RatingsList( player_list ) # a blank set of starter ratings
    sampledrule = UpdateSampleIterate(; rule=rule, batch_size = batch_size, n_samples = n_samples)

    # k-fold cross-validation
    # separate data into training and test data, at random
    indexes = Random.shuffle( 1:size(input_competitions,1) )
    n = Int( k*floor(length(indexes)/k) )
    n_block = Int(n/k)
    indexes = indexes[1:n] # randomly drop a small amount of left-over data :( 

    S = zeros(Float64, k)
    for i=1:k
        test_indexes = indexes[ ((i-1)*n_block)+1 : i*n_block ]
        training_indexes = setdiff( indexes, test_indexes )

        # "train" by calculating ratings from training data
        training_data = input_competitions[ training_indexes, : ]
        out_ratings = update_ratings(rule, input_ratings, training_data)

        # score on the test data
        test_data = input_competitions[ test_indexes, : ]
        S[i] = score_ratings( srule, test_data, rule, out_ratings )
    end
    
    return S
end

function cross_validate(rule::UpdateRule, file::String;
                        k::Int = 10,
                        n_samples::Int = 1000,
                        batch_size::Int = 30,
                        srule::ScoringRule = ScoreBrier(;normalise=true) )
    (input_competitions,  player_list) = read_results( file )

    return cross_validate(rule, input_competitions; k=k, n_samples=n_samples, batch_size=batch_size, srule=srule)
end


function optimise() 
    # really should be a separate cross-validation process for choosing "hyperparameters"
    #   need data partitioned into training, test, and validation datasets



    
end
