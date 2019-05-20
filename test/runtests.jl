using RatPack
using Distributions
using DataFrames
using CSV
using Test

# test case from "Whos's #1", Langville and Meyer
file = "../data/test_competitions_1.csv"
(input_competitions,  player_list) = read_results( file )
summarize(input_competitions,  player_list)
input_ratings = RatingsList( player_list )
r = update_ratings(UpdateMassey(),
                   input_ratings,
                   input_competitions)

R1 = RatingsTable(input_ratings.players) # empty
R2 = RatingsTable(input_ratings)         # 1 row but now values
R3 = RatingsTable(r)                     # 1 initialised row
R4 = RatingsTable(r.players, 4)          # 4 uninitialised rows
setindex!(R4, r, 2)
R4[3] = r
@testset "RatingsTable structure" begin
    @test append!(R1,R3) == R3
    @test R1.ratings[1,:] == R1[1]
    @test R4[2:2] == RatingsTable(r).ratings
end

massey_ratings = update_ratings(UpdateMassey(),
                                input_ratings,
                                input_competitions)

# include home ground factor in the original case from  "Whos's #1", Langville and Meyer
file2 = "../data/test_competitions_2.csv"
(input_competitions2,  player_list2) = read_results( file2 )
summarize(input_competitions2,  player_list2)
input_ratings2 = RatingsList( player_list2 )

# test case from NFL season 2009 (see file for source, but also used in "Whos's #1", Langville and Meyer)
#   this is the regular season, excluding playoffs
file = "../data/nfl_2009_regular.csv"
(nfl_competitions,  nfl_player_list) = read_results( file )
nfl_ratings = RatingsList( nfl_player_list )

#   this is the whole season, including playoffs
file = "../data/nfl_2009.csv"
(nfl_ext_competitions,  nfl_ext_player_list) = read_results( file )
nfl_ext_ratings = RatingsList( nfl_ext_player_list )

# small netflix-like example from "Whos's #1", Langville and Meyer
file = "../data/small_netflix_eg.csv"
(netflix_competitions,  netflix_player_list) = read_results( file )
netflix_ratings = RatingsList( netflix_player_list )

@testset "Utilities" begin
    @testset "Line search" begin
        r = [0.0, 2.0]
        ε = 1.0e-6
        (x_star1, y_star1, error_estimate1, n_evaluations2) =
            linesearch( "Grid", x->sin(x); range=r, ε=ε)
        (x_star2, y_star2, error_estimate2, n_evaluations2) =
            linesearch( "Golden", x->sin(x); range=r, ε=ε)
        @test abs(x_star1 - x_star2) < ε
    end
end

@testset "I/O" begin
    @test_throws ArgumentError o = read_results( "test" )
    # @test_throws ErrorException SurrealFinite("1", [x1], [x0])
    # @test_throws DomainError convert(SurrealFinite, NaN )

    @test (sort(summarize(input_competitions,  player_list), :Player) ==
           DataFrame(Player=["Duke","Miami","UNC","UVA","VT"], Record=["0/4","4/4","2/4","1/4","3/4"], ScoreDiff=[-124,91,-40,-17,90])
           )

    test_out = "test_ratings.csv"
    write_ratings( test_out,  massey_ratings)
    df,r = read_ratings( test_out )
    @test r == massey_ratings

    # test for a wide range of input errors in competitions
    error_list = ["Input DataFrame must have a 'Player A' column'",
                  "Input DataFrame 'Player A' column must have type String",
                  "Input DataFrame must have a 'Player B' column'",
                  "Input DataFrame 'Player B' column must have type String",
                  "Input DataFrame 'Outcome' column must have type Union{Missing, Integer}",
                  "Input DataFrame 'Outcome' column should be -1,0,1 (or missing)",
                  "Input DataFrame 'Result' column must have type Union{Missing, Real}",
                  "Input DataFrame 'Result' column should be >= 0 (or missing)",
                  "Input DataFrame 'No. of matches' column must have type Union{Missing, Integer}",
                  "Input DataFrame 'No. of matches' column should be >= 1 (or missing)",
                  "Input DataFrame 'Score A' column must have type Union{Missing, Integer}",
                  "Input DataFrame 'Score B' column must have type Union{Missing, Integer}",
                  "Input DataFrame only has 'Score A' column, not 'Score B'",
                  "Input DataFrame only has 'Score B' column, not 'Score A'",
                  "Input DataFrame 'Margin' column must have type Union{Missing, Integer}",
                  "Input DataFrame 'Factor A' column must have type Union{Missing, Integer}",
                  "Input DataFrame 'Factor B' column must have type Union{Missing, Integer}",
                  "Input DataFrame only has 'Factor A' column, not 'Factor B'",
                  "Input DataFrame only has 'Factor B' column, not 'Factor A'",
                  "Input DataFrame: Margins are inconsistent with Scores",
                  "Input DataFrame: Outcomes are inconsistent with Margins",
                  "",
                  "",
                  ] 
    
    errored_file_dir = "../data/errored_files"
    files = readdir(errored_file_dir)
    i = 1
    for f in files
        # global file, df, i
        if match(r".csv$", f) !== nothing
            file = "$errored_file_dir/$f"
            # println("testing $file ($i of $(length(files)))")
            df = CSV.read(file; comment="#")
            @test_throws ErrorException(error_list[i]) check_results( df )
            
            i += 1
        end
    end
    
end

@testset "Info" begin
    for (i,u) in enumerate(update_rule_list)
        if u != "Iterate" && u != "SampleIterate"
            nm = Meta.parse("Update$u()")
            info_update_rule = :(update_info( $nm ) )
            D = eval( info_update_rule )
            # println("$u, $(D[:name])")
            @test D[:name] == u
        end
    end
end

@testset "Massey" begin
    # see \"Whos's #1\", Langville and Meyer, p.11
    required_output = Dict{String,Float64}(
        "Duke"  => -24.8,
        "Miami" =>  18.2,
        "UNC"   =>  -8.0,
        "UVA"   =>  -3.4,
        "VT"    =>  18.0)
    for k in keys(required_output)
        @test abs(required_output[k] - massey_ratings.ratings[k]) < 1.0e-1
    end

    massey_ratings2 = update_ratings(UpdateMassey(),
                                     netflix_ratings,
                                     netflix_competitions)           
    # see \"Whos's #1\", Langville and Meyer, Table 3.3, p.26
    required_output = Dict{String,Float64}(
        "M1" =>  0.65,
        "M2" =>  1.01,
        "M3" => -0.55,
        "M4" => -1.11
        )
    for k in keys(required_output)
        @test abs(required_output[k] - massey_ratings2.ratings[k]) < 1.0e-2
    end
   
end

@testset "Colley" begin
    colley_ratings = update_ratings(UpdateColley(),
                                    input_ratings,
                                    input_competitions)           
    # see \"Whos's #1\", Langville and Meyer, Tabl 3.1, p.23
    required_output = Dict{String,Float64}(
        "Duke"  => 0.21,
        "Miami" => 0.79,
        "UNC"   => 0.50,
        "UVA"   => 0.36,
        "VT"    => 0.64)
    for k in keys(required_output)
        @test abs(required_output[k] - colley_ratings.ratings[k]) < 1.0e-2
    end
    
    colley_ratings2 = update_ratings(UpdateColley(), netflix_ratings,
                                     netflix_competitions)
    # see \"Whos's #1\", Langville and Meyer, Table 3.3, p.26
    required_output = Dict{String,Float64}(
        "M1" =>  0.67,
        "M2" =>  0.63,
        "M3" =>  0.34,
        "M4" =>  0.35
        )
    for k in keys(required_output)
        @test abs(required_output[k] - colley_ratings2.ratings[k]) < 1.0e-2
    end

end

@testset "MasseyColley" begin
    massey_colley_ratings = update_ratings(UpdateMasseyColley(),
                                           input_ratings,
                                           input_competitions)           
    # see \"Whos's #1\", Langville and Meyer, Tabl 3.2, p.25
    required_output = Dict{String,Float64}(
        "Duke"  => -17.7,
        "Miami" =>  13.0,
        "UNC"   =>  -5.7,
        "UVA"   =>  -2.4,
        "VT"    =>  12.9)
    for k in keys(required_output)
        @test abs(required_output[k] - massey_colley_ratings.ratings[k]) < 1.0e-1
    end
    
end

@testset "KeenerScores" begin
    keener_score_ratings = update_ratings(UpdateKeenerScores(; skew=true, norm=false),
                                          nfl_ratings,
                                          nfl_competitions)
    # see \"Whos's #1\", Langville and Meyer, p.44
    required_output = Dict{String,Float64}(
   "New Orleans Saints" => 0.0361385,
    "Green Bay Packers" => 0.0357225,
 "New England Patriots" => 0.0350508,
   "San Diego Chargers" => 0.0350264,
   "Indianapolis Colts" => 0.0348175,
    "Minnesota Vikings" => 0.0347833,
       "Dallas Cowboys" => 0.0347101,
        "New York Jets" => 0.0346833,
  "Philadelphia Eagles" => 0.0338832,
     "Baltimore Ravens" => 0.0338213,
  "Pittsburgh Steelers" => 0.0335293,
       "Houston Texans" => 0.0334149,
      "Atlanta Falcons" => 0.0326898,
    "Arizona Cardinals" => 0.0323456,
  "San Francisco 49ers" => 0.0318757,
       "Denver Broncos" => 0.0317885,
   "Cincinnati Bengals" => 0.0314828,
    "Carolina Panthers" => 0.0307855,
     "Tennessee Titans" => 0.0305376,
      "New York Giants" => 0.0304804,
       "Miami Dolphins" => 0.0298047,
        "Chicago Bears" => 0.0294099,
  "Washington Redskins" => 0.0291071,
        "Buffalo Bills" => 0.0290657,
 "Jacksonville Jaguars" => 0.0289624,
   "Kansas City Chiefs" => 0.0280055,
     "Cleveland Browns" => 0.0279232,
     "Seattle Seahawks" => 0.0272619,
      "Oakland Raiders" => 0.0262216,
 "Tampa Bay Buccaneers" => 0.0261939,
        "Detroit Lions" => 0.0255954,
       "St. Louis Rams" => 0.0248815
    )
    for k in keys(required_output)
        @test abs(required_output[k] - keener_score_ratings.ratings[k]) < 1.0e-5
    end
end

@testset "Revert" begin
    colley_ratings = update_ratings(UpdateColley(),
                                    input_ratings,
                                    input_competitions)
    r0 = 1.0
    a = 0.25
    revert_ratings = update_ratings(UpdateRevert(; r_base=r0, α=a),
                                    colley_ratings)           
    required_output = Dict{String,Float64}(
        "Duke"  => 0.21*a + r0*(1-a),
        "Miami" => 0.79*a + r0*(1-a),
        "UNC"   => 0.50*a + r0*(1-a),
        "UVA"   => 0.36*a + r0*(1-a),
        "VT"    => 0.64*a + r0*(1-a))
    for k in keys(required_output)
        @test abs(required_output[k] - revert_ratings.ratings[k]) < 1.0e-2
    end 

    # check it complains when you give invalid arguments
    @test_throws ArgumentError rule = UpdateRevert(α = -0.1)
    @test_throws ArgumentError rule = UpdateRevert(α =  1.1)
end

@testset "Elo" begin
    r0 = 0.0
    rule = UpdateElo(;r0 = r0, K = 32.0, θ=1000.0/log(10.0) )
    r = nfl_ext_ratings
    for i=1:size(nfl_ext_competitions,1)
        # apply Elo 1-by-1 to each result
         r = update_ratings(rule, r, nfl_ext_competitions[ i:i, :])           
    end
    S = sort(collect(r.ratings), by = tuple -> last(tuple), rev=true)
    r_mean = mean(last.(S)) # should be close to r0 = 0.0
    @test abs(r0 - r_mean) < 1.0e-6
    elo_ratings = r
    # see \"Whos's #1\", Langville and Meyer, p.58
    required_output = Dict{String,Float64}(
   "New Orleans Saints" => 173.661, 
   "Indianapolis Colts" => 170.331,
   "San Diego Chargers" => 127.582,
    "Minnesota Vikings" => 103.504, 
       "Dallas Cowboys" => 89.1285,
  "Philadelphia Eagles" => 69.5331,
    "Green Bay Packers" => 67.8292, 
    "Arizona Cardinals" => 53.227 , 
        "New York Jets" => 50.1431, 
 "New England Patriots" => 39.6328, 
       "Houston Texans" => 33.9024, 
   "Cincinnati Bengals" => 33.0116, 
     "Baltimore Ravens" => 32.0826, 
      "Atlanta Falcons" => 28.1178, 
  "Pittsburgh Steelers" => 27.1246, 
     "Tennessee Titans" => 13.2216, 
    "Carolina Panthers" => 11.4745, 
  "San Francisco 49ers" => -1.28445,
      "New York Giants" => -5.3217, 
       "Denver Broncos" => -11.1262,
       "Miami Dolphins" => -26.7173,
        "Chicago Bears" => -28.1416,
 "Jacksonville Jaguars" => -36.2142,
        "Buffalo Bills" => -53.3495,
     "Cleveland Browns" => -74.6639,
      "Oakland Raiders" => -83.3188,
     "Seattle Seahawks" => -88.8452,
   "Kansas City Chiefs" => -109.281,
  "Washington Redskins" => -110.212,
 "Tampa Bay Buccaneers" => -130.102,
        "Detroit Lions" => -170.809,
       "St. Louis Rams" => -194.119
                                           )
    for k in keys(required_output)
        @test abs(required_output[k] - elo_ratings.ratings[k]) < 1.0e-2
    end

    # do a test for: K=32 weeks 1-15; K=16 weeks 16-17; K=64 for playoffs
    #  p.60-61
    

    # check it complains when you give invalid arguments
    @test_throws ArgumentError rule = UpdateElo(K = -1)
    @test_throws ArgumentError rule = UpdateElo(θ = -1)
end

@testset "EloF" begin
    r0 = 0.0
    rule = UpdateEloF(;r0 = r0, K = 32.0, θ=1000.0/log(10.0), factor_scale = 0.0 )
    r = nfl_ext_ratings
    for i=1:size(nfl_ext_competitions,1)
        # apply Elo 1-by-1 to each result
        r = update_ratings(rule, r, nfl_ext_competitions[ i:i, :])           
    end
    S = sort(collect(r.ratings), by = tuple -> last(tuple), rev=true)
    r_mean = mean(last.(S)) # should be close to r0 = 0.0
    @test abs(r0 - r_mean) < 1.0e-6
    elo_ratings = r
    # see \"Whos's #1\", Langville and Meyer, p.58
    required_output = Dict{String,Float64}(
   "New Orleans Saints" => 173.661, 
   "Indianapolis Colts" => 170.331,
   "San Diego Chargers" => 127.582,
    "Minnesota Vikings" => 103.504, 
       "Dallas Cowboys" => 89.1285,
  "Philadelphia Eagles" => 69.5331,
    "Green Bay Packers" => 67.8292, 
    "Arizona Cardinals" => 53.227 , 
        "New York Jets" => 50.1431, 
 "New England Patriots" => 39.6328, 
       "Houston Texans" => 33.9024, 
   "Cincinnati Bengals" => 33.0116, 
     "Baltimore Ravens" => 32.0826, 
      "Atlanta Falcons" => 28.1178, 
  "Pittsburgh Steelers" => 27.1246, 
     "Tennessee Titans" => 13.2216, 
    "Carolina Panthers" => 11.4745, 
  "San Francisco 49ers" => -1.28445,
      "New York Giants" => -5.3217, 
       "Denver Broncos" => -11.1262,
       "Miami Dolphins" => -26.7173,
        "Chicago Bears" => -28.1416,
 "Jacksonville Jaguars" => -36.2142,
        "Buffalo Bills" => -53.3495,
     "Cleveland Browns" => -74.6639,
      "Oakland Raiders" => -83.3188,
     "Seattle Seahawks" => -88.8452,
   "Kansas City Chiefs" => -109.281,
  "Washington Redskins" => -110.212,
 "Tampa Bay Buccaneers" => -130.102,
        "Detroit Lions" => -170.809,
       "St. Louis Rams" => -194.119
                                           )
    for k in keys(required_output)
        @test abs(required_output[k] - elo_ratings.ratings[k]) < 1.0e-2
    end

    # do a test where factors, e.g., home ground are important
    rule = UpdateEloF(;r0 = r0, K = 32.0, θ=1000.0/log(10.0), factor_scale=10.0 )
    r = input_ratings2
    for i=1:10
        r = update_ratings(rule,
                           r,
                           input_competitions2)
    end
    # check the output against something??? 
    
    # check it complains when you give invalid arguments
    @test_throws ArgumentError rule = UpdateEloF(K = -1)
    @test_throws ArgumentError rule = UpdateEloF(θ = -1)
    @test_throws ArgumentError rule = UpdateEloF(factor_scale = -1.0)
end

@testset "Iterate" begin
    r0 = 0.0
    # nice way to say, do Elo line-by-line on the inputs
    rule = UpdateIterate( UpdateElo(;r0 = r0, K = 32.0, θ=1000.0/log(10.0) ), 1)
    iterate_ratings = update_ratings(rule, nfl_ext_ratings, nfl_ext_competitions)
    # see \"Whos's #1\", Langville and Meyer, p.58
    required_output = Dict{String,Float64}(
   "New Orleans Saints" => 173.661, 
   "Indianapolis Colts" => 170.331,
   "San Diego Chargers" => 127.582,
    "Minnesota Vikings" => 103.504, 
       "Dallas Cowboys" => 89.1285,
  "Philadelphia Eagles" => 69.5331,
    "Green Bay Packers" => 67.8292, 
    "Arizona Cardinals" => 53.227 , 
        "New York Jets" => 50.1431, 
 "New England Patriots" => 39.6328, 
       "Houston Texans" => 33.9024, 
   "Cincinnati Bengals" => 33.0116, 
     "Baltimore Ravens" => 32.0826, 
      "Atlanta Falcons" => 28.1178, 
  "Pittsburgh Steelers" => 27.1246, 
     "Tennessee Titans" => 13.2216, 
    "Carolina Panthers" => 11.4745, 
  "San Francisco 49ers" => -1.28445,
      "New York Giants" => -5.3217, 
       "Denver Broncos" => -11.1262,
       "Miami Dolphins" => -26.7173,
        "Chicago Bears" => -28.1416,
 "Jacksonville Jaguars" => -36.2142,
        "Buffalo Bills" => -53.3495,
     "Cleveland Browns" => -74.6639,
      "Oakland Raiders" => -83.3188,
     "Seattle Seahawks" => -88.8452,
   "Kansas City Chiefs" => -109.281,
  "Washington Redskins" => -110.212,
 "Tampa Bay Buccaneers" => -130.102,
        "Detroit Lions" => -170.809,
       "St. Louis Rams" => -194.119
                                           )
    for k in keys(required_output)
        @test abs(required_output[k] - iterate_ratings.ratings[k]) < 1.0e-2
    end

    # check recording doesn't break anything
    R5 = RatingsTable( nfl_ext_ratings.players, size(nfl_ext_competitions,1) )
    iterate_ratings2 = update_ratings(rule, nfl_ext_ratings, nfl_ext_competitions; record=R5)
    @test iterate_ratings2 == iterate_ratings
    @test R5[end:end] == RatingsTable(iterate_ratings2).ratings

    # extra I/O question
    test_out2 = "test_ratings_table_out.csv"
    write_ratingstable( test_out2, R5 )
    R7 = read_ratingstable( test_out2 )
    @test R5 == R7

    # check it complains when you give invalid arguments
    @test_throws ArgumentError rule = UpdateIterate( UpdateColley(), 1)
    @test_throws ArgumentError rule = UpdateIterate( UpdateElo(), 0)
end

r0 = 0.0
n_samples = 1000
batch_size = 41
rule = UpdateSampleIterate( rule=UpdateElo(;r0 = r0, K = 32.0, θ=1000.0/log(10.0) ),
                            batch_size = batch_size,
                            n_samples = n_samples)
R6 = RatingsTable( nfl_ext_ratings.players, Int(ceil(n_samples/batch_size)) )
sample_ratings = update_ratings(rule, nfl_ext_ratings, nfl_ext_competitions; record=R6)
@testset "SampleIterate" begin
    @test R6[end:end] == RatingsTable(sample_ratings).ratings

    # check it complains when you give invalid arguments
    @test_throws ArgumentError rule = UpdateSampleIterate( UpdateColley(), 1, 0)
    @test_throws ArgumentError rule = UpdateSampleIterate( UpdateElo(), 0, 0)
    @test_throws ArgumentError rule = UpdateSampleIterate( UpdateElo(), 0, 1)
end

@testset "Scoring" begin
    # test normalised direction and score values
    for (i,s) in enumerate(scoring_rule_names)
        @testset "$s" begin
            nm = Meta.parse("$s(;normalise=true)")
            score_dir = :(score_direction( $nm ) )
            @test eval( score_dir ) == 1
            score_one = :(scoring_function( $nm, [0.0, 1.0], 2 ) )
            @test abs( eval( score_one  ) - 1.0) < 1.0e-6
            score_half = :(scoring_function( $nm, [0.5, 0.5], 2 ) )
            @test abs( eval( score_half ) - 0.0) < 1.0e-6
        end
    end
end

@testset "Predict" begin
    @testset "   outcomes" begin
        # cases that can predict outcome
        @test all( predict_outcome(UpdateElo(), 1.0, 1.0, missing, missing) .== (0.5, 0.5, 0.0) )
        @test all( predict_outcome(UpdateEloF(), 1.0, 1.0, missing, missing) .== (0.5, 0.5, 0.0) )
        @test all( predict_outcome(UpdateColley(), 1.0, 1.0, missing, missing) .== (0.0, 0.0, 1.0) )

        # case that use a sub-rule for prediction (default is Elo)
        @test all( predict_outcome(UpdateIterate(), 1.0, 1.0, missing, missing) .== (0.5, 0.5, 0.0) )
        @test all( predict_outcome(UpdateSampleIterate(), 1.0, 1.0, missing, missing) .== (0.5, 0.5, 0.0) )

        # cases based on score, not outcome
        @test_throws ErrorException predict_outcome(UpdateMassey(), 1.0, 1.0, missing, missing)
        @test_throws ErrorException predict_outcome(UpdateMasseyColley(), 1.0, 1.0, missing, missing)
        @test_throws ErrorException predict_outcome(UpdateKeenerScores(), 1.0, 1.0, missing, missing)
 
        # cases that don't have a predictive model 
        @test_throws ErrorException predict_outcome(UpdateRevert(), 1.0, 1.0, missing, missing)
    end

    @testset "   margin" begin
        # not implemented yet
    end
end
