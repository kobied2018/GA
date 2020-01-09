using MyGA
using Test
using Combinatorics
using DataFrames

correct_bag_data_type = ([1 2 3],[1,2,3],[1;2;3],(1,2,3),
                         [1. 2. 3.],[1.,2.,3.],[1.;2.;3.],(1.,2.,3.))
correct_bag_test = combinations(correct_bag_data_type,2)
correct_bag_test_output = [[1.;2.;3.] [1.;2.;3.]]

non_correct_bag_data_type = ([1 2 3],[1 2 3 4],(1,2,3,4,5))
non_correct_bag_test = combinations(non_correct_bag_data_type,2)

@testset "Turtle.jl" begin
    @testset "create a correct bag" begin
        for datain in correct_bag_test
            @test begin
                mybag = Bags(datain[1],datain[2])
                mybag.vertexes == correct_bag_test_output
            end
        end
    end

    @testset "create a non correct bag" begin
        for datain in non_correct_bag_test
            @test_throws DimensionMismatch Bags(datain[1],datain[2])
        end
    end

end


# desition_tree_data_letters = DataFrame(letter = ["a","b", "a"], number = [0,-1,101], class = ["good","bad","good"])
# desition_tree_data_letters_features = (:letter,:number)
# desition_tree_data_letters_categorycol = :class
#
# desition_tree_data_box1 = DataFrame(x = [0,1,0,1], y = [0,0,1,1], out = [0,0,1,1])
# desition_tree_data_box2 = DataFrame(x = [0,-1,1,0,0], y = [0,0,0,-1,1], out = [0,1,1,1,1])
# desition_tree_data_box_features = (:x,:y)
# desition_tree_data_box_categorycol = :out
#
# desition_tree_data_weather = DataFrame( outlook = ["sunny","sunny","overcast","rain","rain","rain","overcast","sunny","sunny","rain","sunny","overcast","overcast","rain"],
#                                         temperature = ["hot","hot","hot","mild","cool","cool","cool","mild","cool","mild","mild","mild","hot","mild"],
#                                         humidity = ["high","high","high","high","normal","normal","normal","high","normal","normal","normal","high","normal","high"],
#                                         windy = [0,1,0,0,0,1,1,0,0,0,1,1,0,1],
#                                         class = [0,0,1,1,1,0,1,0,1,1,1,1,1,0])
# desition_tree_data_weather_features = (:outlook,:temperature,:humidity,:windy)
# desition_tree_data_weather_categorycol = :class
#
# desition_tree_data_in = (   (desition_tree_data_letters,desition_tree_data_letters_features,desition_tree_data_letters_categorycol),
#                             (desition_tree_data_box1,desition_tree_data_box_features,desition_tree_data_box_categorycol),
#                             (desition_tree_data_box2,desition_tree_data_box_features,desition_tree_data_box_categorycol),
#                             (desition_tree_data_weather,desition_tree_data_weather_features,desition_tree_data_weather_categorycol))
#
# desition_tree_data_res =(   Dict("letter" => Dict("b" => "bad","a" => "good")),
#                             Dict("y" => Dict("1" => "1","0" => "0")),
#                             Dict("y" => Dict("1" => "1","0" => "0")),
#                             Dict("outlook" => Dict(
#                                                     "sunny" => Dict("humidity" => Dict(
#                                                                                         "normal" => 1,
#                                                                                         "high" => 0)),
#                                                     "rain" => Dict("windy" => Dict(
#                                                                                     "1" => 0,
#                                                                                     "0" => 1)))
#                                                     "overcast" => 1)) # TODO - need to define the last 2 database result
# @testset "DesitionTree.jl" begin
#     @testset "create desition tree" begin
#         for (data,res) in zip(desition_tree_data_in,desition_tree_data_res)
#             @test create_tree(data[1], data[2], data[3]) = res
#     end
# end
