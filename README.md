# RatPack

[![Build Status](https://travis-ci.com/mroughan/RatPack.jl.svg?branch=master)](https://travis-ci.com/mroughan/RatPack.jl)
[![Codecov](https://codecov.io/gh/mroughan/RatPack.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/mroughan/RatPack.jl)
[![Coveralls](https://coveralls.io/repos/github/mroughan/RatPack.jl/badge.svg?branch=master)](https://coveralls.io/github/mroughan/RatPack.jl?branch=master)


## Competitive ratings

Competetive ratings (or contest ratings, or pairwise comparison
ratings) are ratings of players or teams in competitive sports created
by analysis of their performance. That is, if you win more, your
rating should be higher.

There are many schemes for generating such, but essential ideas
underlying the ratings schemes here is that they be

1. Transparent (easily computable by anyone, and thus objective);

2. Based on performance relative to the field played against. That is,
   a player should get more credit for defeating stronger opponients,
   where stronger here is with respect to the ratings themselves; 

3. Non-gameable. That is, you should not be able to arbitrarily
   improve your rating without an improvement in skill. For instance,
   the number of games you play should not be a major input, so much
   as the results of those games. 

The goals of such ratings are related but somewhat varied and include:

1. Matchmaking (pitting similar players against each other).

2. Predicting outcomes (e.g., for gambling or other reasons).

3. Providing rankings (for interests sake) of current players, historical players, or even between games.

4. Encouraging play (players need to play to improve their standing).

One side note: there is a subtle distinction between "ratings" and
"rankings". The latter is simply an ordering of players (or teams),
whereas the former provides a numerical value that also indicates some
idea of the players' *strengths* relative to each other. Thus a rating
provides more information, and a ranking can easily be derived from a
rating, but not visa versa. 

## Elo et al

Competitive ratings started (as far as I know) in Chess. Elo created
the most famous Chess ratings system as a result of perceived problems
in existing systems. However there are many other schemes that have
developed in parallel, or since. 

The main reference used in defining notation and results is "Whos's
\#1", by Langville and Meyer, Princeton, 2012. Other texts are referred
to in the relevant piece of source code. 

## The package

The package aims to provide means to perform all of the standard, and
some slightly non-standard ratings calculations. The supported systems
are currently:

+ Massey
+ Colley
+ Massey-Colley (the "Colleyized Massey method" of Langville and Meyer, p.25)
+ Elo
+ EloF (a version of Elo that allows factors such as home-ground advantage)
+ Keener

Along with the utility update methods

+ Iterate (to iterate another method over a dataset)
+ Revert (to smooth ratings towards some fixed value)

To add

+ Advanced and alternative versions of the above
+ Eigenvalue/Markovian ratings
+ Glicko (1 and 2)
+ [MS TrueSkill](https://www.microsoft.com/en-us/research/project/trueskill-ranking-system/)

The package also provides some additional tools for working with
ratings. For instance simulating competitions according to several
models, and I/O of data.

Indeed the package also includes several test sets of data:

+ Small example from Langville and Meyer
+ 2009-10 NFL (also used as an example in Langville and Meyer)
+ NBA data used by 538
+ 

## How to use it 

The package is still under development, and as such the interfaces are
still a moving target. Give me a few days. 

There are a few data structures used

+ `RatingsList` a composite structure
+ `player_list::Dict{String,Int64}`
+  `results::DataFrame`
+ `UpdateRule` is an abstract type; the actual update rules are subtypes.

There are three main functions you need

+ `update_ratings` reads in a `UpdateRule`, a `RatingsList` and a competition list and outputs 
+ `UpdateRule()` and its ilk are constructors for the update rules that let you set their particular parameters
+  `update_info` gives you information about an update rule

The way to add a new update rule is to create a copy of one of the
current updates (to use as a template) and fill in each of these bits.

File formats

+ Ratings
+ Competitions

  A competition is a pairwise match-up between two contestants called
  "Player A" and "Player B" along with the result. The result can be
  expressed as

   + an `Outcome`, which is {-1,0,+1} where 1 indicates victory to Player
     A, and -1 victory to Player, and 0 a tie.

   + a `Result`, which is {0, 1/2, 1} where 1 has the same meaning,
     1/2 means a tie and 0 means victory to Player B.

   + a `Margin` which gives the number of "points" by which Player A
     defeats Player B (negative values indicates a victory for Player B).

   + a pair of `Scores`, one for each player, i.e., "Score A" and Score B".

  Why have multiple formats? Different tools, packages and algorithms
  use different models and representations. So for portability it is
  useful to support all. Moreover, we want to make it blindingly clear
  which representation is used in each approach.

  Each match-up will be represented as one row of data in a CSV file. 

  Additionally, a


+ Rankings and other (e.g., matrix) inputs will also be added in the
  future. 

Plenty of other bits and pieces


## Additional tools

### Simulating competitions


### Generating players




## Related packages


Most implement one method or at most a class of similar approaches
(e.g., Elo and some variants) . For instance, Elo is common and
implementing variants is not hard, but is a very different approach to
the Colley system both in terms of inputs and sequential vs batch
processing. 

Most are not complete solutions: they implement the ratings component,
but not much else.

Many don't come with adequate testing or validation. 

### Open Source

+ **R** `PlayerRatings` (see []()). Implements variants of Elo
  (standard, FIDE) Glicko, Glicko2 and Stephenson and has a few routines for
  calculating parameters (the K factor). 

+ **R** `elo` (see [CRAN](https://cran.r-project.org/web/packages/elo/vignettes/elo.html) and [GitHub](https://github.com/eheinzen/elo) ). Implements Elo. 

+ **R** `elo` (see [elo](https://rdrr.io/cran/elo/)). Implements Elo.

+ **R** `EloRating` (see ["EloRating: Animal Dominance Hierarchies by
  Elo Rating"](https://rdrr.io/cran/EloRating/)). Implements Elo.

+ **R** `EloOptimized` (See
  [EloOptimized](https://cran.r-project.org/web/packages/EloOptimized/readme/README.html). Implements
  Elo with optimized Elo parameters.

+ **R** `prefmod` (see ["prefmod: An R Package for Modeling Preferences
  Based on Paired Comparisons, Rankings, or Ratings"]()). Implements
  Bradley-Terry style  *paired comparison* generalised-linear models.

+ **C#** `EloRate` (see [EloRate](https://github.com/richardadalton/EloRate)). Implements Elo.

+ **Javascript** `sortmatch` (see [sortmatch](https://sortmatch.ca/) and
  [sortmatch](https://github.com/bradbeattie/sortmatch)). Implements
  Glicko2 through browser interface.

+ **Java** `glicko2s` (see 
  [glick2s](https://github.com/forwardloop/glicko2s/tree/master/src/main)). Implements
  Glicko2.

+ **Ruby** `elo` (see
    [GitHub](https://github.com/iain/elo). Implements Elo variants
  (including FIDE variable K factors). 

+ **C++** `Elo Rater` (see [Elo Rater](http://www.garnergaggle.org/papa/chess/ELORater/)). Implements USCF or Harkness style ratings.



### Closed Source


+ `Bayeselo` [Bayesian Elo Rating](https://www.remi-coulom.fr/Bayesian-Elo/). Implements a Bayes
   version of Elo.
+ **Web based** [rankade](https://rankade.com/). Implements their own algorithm.
+ **Web based** [Chess Elo Rating Calculator](http://www.qa76.net/elo)
   Implements Elo.
+ **Web based** [Chess Elo Rating Difference Calculator](http://www.3dkingdoms.com/chess/elo.htm)
   Implements Elo.
+ **Excel** Chess Ranking Assistant](https://www.add-ins.com/free-products/chess-ranking-assistant.htm).
   Implements Glicko.


+ mirate (for Go)

+ ELOstat algorithm???

### Comparisons

+ https://rankade.com/ree#ranking-system-comparison
+ https://www.chessandfun.com/chess-rating-software-for-chess-clubs/
