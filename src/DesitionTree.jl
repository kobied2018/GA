#md # Needed packages
using DataFrames
using GraphRecipes
using Plots
using AbstractTrees
gr()

#md # this file holds the needed function to build a desition tree base on
#md # [Iterative Dichotomiser 3 method](http://hunch.net/~coms-4771/quinlan.pdf)
#md # this file documentation is base on [Weave.jl](https://github.com/JunoLab/Weave.jl) and [Literate](https://github.com/fredrikekre/Literate.jl)



#md # # ENTROPY

#md # this function calculate the entropy, at Base 2, of the input data for a given
#md # category.
#md #+
#md # base 2 entropy is good for binary class that has only two values.
#md # for more information see: [Entropy](https://en.wikipedia.org/wiki/Entropy)

#src """
#src    entropy2(data::DataFrame, categorycol::Symbol)
#src
#src this function calculate the category entropy using base 2.
#src this is good for binary class that can have only two values.
#src the function output the category entropy
#src """

function entropy2(data::DataFrame, categorycol::Symbol)
    #src # find the total number of samples
    totalnumofsamples = length(data[!,categorycol])
    #src # get the category sets (there should be only 2)
    categorysets = Set(data[!,categorycol])
    #src # define the Dictionary for the Probability of each dataset to have each categoryset
    Pcategory = Dict{String,Real}()
    for categoryset in categorysets
        #src # find the number of samples of the choosen dataset
        Pcategory[string(categoryset)] = count(i->i == categoryset, data[!,categorycol])/totalnumofsamples
    end
    return -sum([v == 0 ? 0 : v*log2(v) for v in values(Pcategory)])
end # function entropy2


#md # # Best feature to split
#md # this function run on all the features in the DataFrame and find the best
#md # feature to split about, base on 'entropy2' function

#src """
#src    best_feature_to_split(data::DataFrame, features::Tuple{Symbol}, categorycol::Symbol)
#src
#src this function run on all the features in the DataFrame and find the best
#src feature to split about, base on 'entropy2' function
#src """
function best_feature_to_split(data::DataFrame, features::Tuple, categorycol::Symbol)
    baseline = entropy2(data,categorycol) # the base line is the entropy of the total data
    feature_entropy =  Dict{String,Real}()
    #src # this for loop run on each feature column in the data and calculate his entropy
    for feature in features
        feature_entropy[string(feature)] = 0.0
        # categorysets = Set(data[!,categorycol])
        featuresets = Set(data[!,feature])
        # for categoryset in categorysets
        # partitioned_data = filter(row -> row[categorycol] == categoryset,data)
        # porportion = length(partitioned_data[!,feature])/length(data[!,feature])
        # feature_entropy[string(feature)] += porportion * entropy2(partitioned_data, feature)
        for featureset in featuresets
            partitioned_data = filter(row -> row[feature] == featureset,data)
            porportion = length(partitioned_data[!,feature])/length(data[!,feature])
            feature_entropy[string(feature)] += porportion * entropy2(partitioned_data, categorycol)
        end
    end
    information_gain = Dict{String,Real}()
    for feature in features
        information_gain[string(feature)] = baseline - feature_entropy[string(feature)]
    end
    @info "information_gain: $information_gain"
    return findmax(information_gain)
end # function best_feature_to_split


#md # Potential leaf node
#md # this function find the most common category

#src """
#src    potential_leaf_node(data::DataFrame, categorycol::Symbol)
#src
#src this function find the most common category
#src """
function potential_leaf_node(data::DataFrame, categorycol::Symbol)
    counter = Dict{String,Real}()
    categorysets = Set(data[!,categorycol])
    for categoryset in categorysets
        counter[string(categoryset)] = count(i->i == categoryset, data[!,categorycol])
    end

    return findmax(counter)
end # function potential_leaf_node

#md # # Create Tree
#md # the most common is define as the category which has larger percentage then the 'persent_threshold'
#md # the default value is set to 100%


#src """
#src    create_tree(data::DataFrame, features::Tuple, categirycol::Symbol, persent_threshold::Int = 100)
#src
#src the most common is define as the category which has larger percentage then the 'persent_threshold'
#src the default value is set to 100%
#src """
function create_tree(data::DataFrame, features::Tuple, categorycol::Symbol, persent_threshold::Int = 100)
    counter , category = potential_leaf_node(data, categorycol)
    counter == length(data[!,categorycol]) && return category
    node = Dict{String,Dict}()
    feature_gain, feature_lable = best_feature_to_split(data, features, categorycol)
    node[feature_lable] = Dict()
    classes = Set(data[!,Symbol(feature_lable)])
    for c in classes
        partitioned_data = data[data[!,Symbol(feature_lable)] .== c,:]
        node[feature_lable][string(c)] = create_tree(partitioned_data, features, categorycol)
    end
    return node
end # function create_tree


# AbstractTrees.children(d::Dict) = [p for p in d]
# AbstractTrees.children(p::Pair) = AbstractTrees.children(p[2])
# function AbstractTrees.printnode(io::IO, p::Pair)
#     str = isempty(AbstractTrees.children(p[2])) ? string(p[1], ": ", p[2]) : string(p[1], ": ")
#     print(io, str)
# end
"""
    plottree(tree)

this function plot the tree
"""
function plottree(tree)
    default(size=(1000, 1000))
    plot(TreePlot(tree), method=:tree, fontsize=10, nodeshape=:rectangle, nodesize = 0.05)
end # function plottree


"""
    classify(tree::Dict, data)

this function classify data using the a tree
"""
function classify(tree::Dict,data::DataFrame)
    root = collect(keys(tree))[1]
    node = tree[root]
    res = nothing
    for k in keys(node)
        if string(data[!,Symbol(root)][1]) == k
            if node[k] isa Dict
                res = classify(node[k],data)
            else
                return node[k]
            end
        end
    end
    return res
end # function classify

#====== exmaples for building desition tree and calssify new data =============#
# desition_tree_data_weather = DataFrame( outlook = ["sunny","sunny","overcast","rain","rain","rain","overcast","sunny","sunny","rain","sunny","overcast","overcast","rain"],
#                                         temperature = ["hot","hot","hot","mild","cool","cool","cool","mild","cool","mild","mild","mild","hot","mild"],
#                                         humidity = ["high","high","high","high","normal","normal","normal","high","normal","normal","normal","high","normal","high"],
#                                         windy = [0,1,0,0,0,1,1,0,0,0,1,1,0,1],
#                                         class = [0,0,1,1,1,0,1,0,1,1,1,1,1,0])
# desition_tree_data_weather_features = (:outlook,:temperature,:humidity,:windy)
# desition_tree_data_weather_categorycol = :class
#
# tree = create_tree(desition_tree_data_weather,desition_tree_data_weather_features,desition_tree_data_weather_categorycol)
#
# plottree(tree)
#
# data = DataFrame( outlook = "rain", temperature = "hot", humidity = "normal", windy = 0)
#
# @show classify(tree,data)
#
# desition_tree_data_box2 = DataFrame(x = [0,-1,1,0,0], y = [0,0,0,-1,1], out = [0,1,1,1,1])
# desition_tree_data_box_features = (:x,:y)
# desition_tree_data_box_categorycol = :out
#
# tree = create_tree(desition_tree_data_box2,desition_tree_data_box_features,desition_tree_data_box_categorycol)
#
# plottree(tree)
#
# data = DataFrame( y = 1, x = 1)
#
# @show classify(tree,data)
