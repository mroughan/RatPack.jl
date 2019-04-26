# RatPack

[![Build Status](https://travis-ci.com/mroughan/RatPack.jl.svg?branch=master)](https://travis-ci.com/mroughan/RatPack.jl)
[![Codecov](https://codecov.io/gh/mroughan/RatPack.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/mroughan/RatPack.jl)
[![Coveralls](https://coveralls.io/repos/github/mroughan/RatPack.jl/badge.svg?branch=master)](https://coveralls.io/github/mroughan/RatPack.jl?branch=master)


## Competitive ratings

Competetive ratings are ratings of players or teams in competitive
sports created by analysis of their performance. That is, if you win
more, your rating should be higher.

There are many schemes for generating such, but essential ideas
underlying the ratings schemes here is that they be

1. Transparent (easily computable by anyone, and thus objective);

2. Based on performance relative to the field played against. That is,
   a player should get more credit for defeating stronger opponients,
   where stronger here is with respect to the ratings themselves.

3. Non-gameable. That is, you should not be able to arbitrarily
   improve your rating without an improvement in skill. For instance,
   the number of games you play should not be a major input, so much
   as the results of those games. 

The goals of such ratings are related but somewhat varied and include:

1. Matchmaking (pitting similar players against each other)

2. Predicting outcomes (e.g., for gambling or other reasons)

3. 

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
are currently simple versions of 

+ Massey
+ Colley
+ Elo
+ Keener

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
