using Makie, Distributions, Random
import GeometryBasics


mutable struct Bags
    sides
    color
    linewidth
    function Bags(; width, hight, color::Symbol = :green, linewidth = 10)
        sides = [
            Point2f0(0,hight) => Point2f0(0,0);
            Point2f0(0,0) => Point2f0(width,0);
            Point2f0(width,0) => Point2f0(width,hight);
        ]
        new(sides, color, linewidth)
    end
end


mutable struct Hives
    location::Point2f0
    Hives(x,y) = new(Point2f0(x,y))
end

abstract type AbsrtactBee end
struct Workers <: AbsrtactBee end
struct Scouts <: AbsrtactBee end
struct Inactives <: AbsrtactBee end

const worker = Workers()
const scout = Scouts()
const inactive = Inactives()

mutable struct Bees{P}
    node_x::Node
    node_y::Node
    marker::Symbol
    color::Symbol
    Bees(x::T, y::G, marker::Symbol, color::Symbol, type::Type) where {T <: Real, G <: Real} =
        new{type}(Node([x]), Node([y]), marker, color)
end

Bees(data::T) where {T <: Tuple} = Bees(data[1], data[2], data[3])
Bees(x, y, type::T) where {T <: AbsrtactBee} = Bees(T, x, y)
Bees(type::Type{Workers}, x, y) = Bees(x, y, :diamond, :red, type)
Bees(type::Type{Scouts}, x, y) = Bees(x, y, :star4, :purple, type)
Bees(type::Type{Inactives}, x, y) = Bees(x, y, :star4, :black, type)


mutable struct Foods{T <: GeometryBasics.AbstractPoint}
    location::Vector{T}
    # amount
end


mutable struct SimScene
    bag::Bags
    hive::Hives
    bees::Vector{Bees}
    food::Foods
    scene::Scene
    function SimScene(bag, hive, nbees::Tuple, food)
        bees = []
        bee_type = (worker, scout, inactive)
        for ind in 1:length(nbees)
            bees_x_location = fill(Float64(hive.location[1]), nbees[ind])
            bees_y_location = fill(Float64(hive.location[2]), nbees[ind])
            bees_type = fill(bee_type[ind] ,nbees[ind])
            append!(bees, Bees.(zip(bees_x_location, bees_y_location, bees_type)))
        end
        new(bag, hive, bees, food)
    end
end # mutable struct SimScene


"""
    plot_scene(sim_scene::SimScene)

this function plot the simulation scene

inputs:
    sim_scene - the main sim obj

output::
    nothing
"""
function plot_scene!(sim_scene::SimScene)
    bag = sim_scene.bag
    hive = sim_scene.hive
    bees = sim_scene.bees
    food = sim_scene.food
    sim_scene.scene = linesegments(bag.sides , color = bag.color, linewidth = bag.linewidth)
    scatter!(sim_scene.scene, hive.location; color = :orange, markersize = 8 ,marker = :pentagon)
    scatter!(sim_scene.scene, food.location; color = :blue, markersize = 8, marker = :star5)
    for bee in sim_scene.bees
        scatter!(sim_scene.scene, bee.node_x, bee.node_y ; marker = bee.marker, color = bee.color, markersize = 4)
    end
    sim_scene.scene |> display
    return nothing
end # function plot_scene

import AbstractPlotting.linesegments
linesegments(bag::Bags) = linesegments(bag.sides, color = bag.color, linewidth = bag.linewidth)


import Base: convert
convert(t::T, d::Bees{G}) where {T <: AbsrtactBee,G} = Bees(d.node_x.val[1], d.node_y.val[1], t)

"""
    update_plot_bees_location(newsim_scene::SimScene, newx::Vector, new_y::Vect
this function update the bees location in the main scene

inputs:
    sim_scene - the main sim obj
    new_x - a vector that holds all the bees X location
    new_y - a vector that holds all the bees Y location

output:
    nothing
"""
function update_plot_bees_location!(sim_scene::SimScene, new_x::Vector, new_y::Vector)
    sim_scene.bees.node_x[] = new_x
    sim_scene.bees.node_y[] = new_y
    return nothing
end # function update_plot_bees_location


"""
    convert_bee_type!(type::T, sim_scene::SimScene, bee_num::Int) where {T <: AbsrtactBee,G}

this function convert the bee to one of the following {worker, scout, inactive}

inputs:
    bee - the Bees object to convert
    type - the type to convert to
    bee_num - the index in the 'sim_scene.bees' array

output:
    bee - the converted bee object
"""
convert_bee_type!(sim_scene::SimScene, type::T, bee_num::Int) where {T <: AbsrtactBee,G} =
    sim_scene.bees[bee_num] = Bees( sim_scene.bees[bee_num].node_x.val[1],
                                    sim_scene.bees[bee_num].node_y.val[1],
                                    type)

"""
    bees_main_sim(sim_scene::SimScene)

this is the main simulation function

inputs:
    sim_scene - the simulation main obj

output:
    nothing
"""
function bees_main_sim(sim_scene::SimScene)
    body
end # function


#-------------------------- Test Simulation -----------------------------------
width = 100
hight = 100
bag = Bags(width = width, hight = hight)
hive = Hives(width/2,10)
food = Foods(vec(Point2f0[(80,40)]))
sim_scene = SimScene(bag, hive, (3,3,3), food)

plot_scene!(sim_scene)
