# RatPack

[![Build Status](https://travis-ci.com/mroughan/RatPack.jl.svg?branch=master)](https://travis-ci.com/mroughan/RatPack.jl)
[![Codecov](https://codecov.io/gh/mroughan/RatPack.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/mroughan/RatPack.jl)
[![Coveralls](https://coveralls.io/repos/github/mroughan/RatPack.jl/badge.svg?branch=master)](https://coveralls.io/github/mroughan/RatPack.jl?branch=master)


## Competitive ratings

Competetive ratings are ratings of players or teams in competitive sports created by analysis of their performance.

There are many schemes for generating such, but essential ideas underlying the ratings schemes here is that they be

1. Transparent (easily computable by anyone, and thus objective);

2. Based on performance relative to the field played against. That is,
   a player should get more credit for defeating stronger opponients,
   where stronger here is with respect to the ratings themselves.

3. 


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

The package also provides some additional tools for working with ratings. 

