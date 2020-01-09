using Literate
using Weave
path = @__DIR__
cd(joinpath(path,".."))
filename = "DesitionTree"
inputfile = joinpath(path,filename*".jl")
outputdir = joinpath(path,"..","Doc")
Literate.markdown(inputfile, outputdir)
mdfile = joinpath(path,"..","Doc",filename*".md")
weave(mdfile, out_path=outputdir)
