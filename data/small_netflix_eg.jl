# example from "Whos's #1", Langville and Meyer
#   p. 25
# example given as a matrix that must be converted to "scores"
using DataFrames
using CSV

file = "small_netflix_eg.txt"
df = CSV.read(file; comment="#")

competitions = DataFrame( A=[], B=[], Fa=[], Fb=[], O=[], Sa=[], Sb=[] )
for i=1:size(df,1)
    ranks = df[i,2:end]
    for j=1:length(ranks)-1
        for k=j+1:length(ranks)
            if ranks[j]>0 && ranks[k]>0
                push!( competitions, ["M$j", "M$k", 0, 0, sign(ranks[j]-ranks[k]), ranks[j], ranks[k] ] )
            end
        end
    end
end

names!( competitions,  Symbol.(["Player A","Player B","Factor A","Factor B","Outcome","Score A","Score B"]) )
outfile = "small_netflix_eg.csv"
CSV.write(outfile, competitions)
