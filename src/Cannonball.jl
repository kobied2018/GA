using Distributions, ColorSchemes
using Plots
gr()

export fire

"""
cannonball_trajectory(v::Real,θ::Real,t)

this function return the cannonball [x,y] coords at time t for
for initial data v,θ
"""
function cannonball_trajectory(θ::Real, v::Real, width::Real, t)
    g = 9.81
    x,y = 0.5*width .+ v*cos(θ).*t, v*sin(θ).*t - 0.5*g*t.^2
    return (x,y)
end # function cannonball_trajectory


"""
    random_tries(gen_size::Real; max_speed::Real = 20)

this function create random population of size = 'size' for the cannonball
for the velocity 'v' and angle 'θ'
v ∈ [0, typemax(Int64)]
θ ∈ [0, π]
"""
function random_tries(gen_size::Real; max_speed::Real = 20)::Matrix
    generation = Matrix{Real}(undef,gen_size,2)
    for ii in 1:gen_size
        generation[ii,1] = π * rand()
        generation[ii,2] = max_speed * rand()
    end
    return generation
end # function random_tries


"""
hit_coordinate(θ::Real,v::Real,width::Real)

this function find the coordinates of the cannonballs at the bag edge
"""
function hit_coordinate(θ::Real,v::Real,width::Real)
    x = 0.5 * width
    x_hit = width
    if θ > π/2
        x = -x
        x_hit = 0
    end
    t = x/(v*cos(θ))
    y = v*t*sin(θ) - 0.5 * 9.81 * t^2
    y = y < 0 ? 0 : y
    return x_hit, y
 end # function hit_coordinate


"""
    escaped(θ::Real, v::Real, width::Real, height::Real)

this function check if the cannonball escaped the bag
"""
function escaped(θ::Real, v::Real, width::Real, height::Real)
    x_hit, y_hit = hit_coordinate(θ, v, width)
    return (x_hit == 0 || x_hit == width) && y_hit > height
end # function escaped


"""
    cumulative_probabilities(results)

this function build a vector of comulative fittnes results
"""
function cumulative_probabilities(results)
    cprob = Vector{Real}(undef,length(results))
    total = 0.0
    for (ii,res) in enumerate(results)
        total += res[2]
        cprob[ii] = total
    end
    return cprob
end # function cumulative_probabilities


"""
    selection(generation::Matrix,width::Real)

The function appends the y-coordinate where each ball hits the bag
edge to a list, The cumulative_probabilities function then stacks up the running
total of these, giving you your roulette wheel.
"""
function selection(generation::Matrix,width::Real)
    results = [hit_coordinate(θ,v,width) for (θ,v) in zip(generation[:,1],generation[:,2])]
    return cumulative_probabilities(results)
end # function selection


"""
    choose(choices)

The function spins the roulette wheel by picking a random number and
seeing which solution it corresponds to.
"""
function choose(choices)
    p = rand(Uniform(0,choices[end]))
    for (ind,val) in enumerate(choices)
        val >= p && return ind
    end
end # function choose


"""
crossover(generation::Matrix, Width::Real)

Armed with two parents, breed new solutions Not all genetic algorithms
use two parents; some just use one, and there are others that use more.
However, two is a conventional approach.
Notice this makes a new generation of the same size as the last generation.
"""
function crossover(generation::Matrix, width::Real)
    choices = selection(generation,width)
    next_generation = Matrix{Real}(undef,size(generation))
    for (ind,val) in enumerate(eachrow(generation))
        mum = generation[choose(choices),:]
        dad = generation[choose(choices),:] # TODO - why not taking out the pair choosen for mum?
        next_generation[ind,:] = collect(breed(mum,dad))
    end
    return next_generation
end # function crossover


"""
    breed(mum::Vector, dad::Vector)

In order to breed, the information is split—half from one parent and half from
another. Since there are two bits of information, each child will have a velocity
from one parent and an angle from the other. There is only one way to
split this.
In this example, the parents produce a single child.
"""
function breed(mum::Vector, dad::Vector)
    return mum[1],dad[2]
end # function breed


"""
    mutate(generation::Matrix; v_max::Real = 30, v_min::Real = 10)

the function change everything in a population, to keep it general.
the function uses probabilistic mutation, that is you want something to happen
on average, one time out of ten, One approac, is to get a random number between
0 and 1 and do that “something” if you get less than 0.1.
How do you mutate the value? It’s traditional to add or subtract a small
amount or scale (multiply) a little for real numbers. in our case
add a random number to the angle, but only use this if it stays between
0 and 180 degrees. and for the velocity, scale by something random between 0.9
and 1.1, cunningly avoiding the problem of potentially getting zero
"""
function mutate(generation::Matrix; v_max::Real = 30, v_min::Real = 10)
    for (ind,val) in enumerate(eachrow(generation))
        θ = val[1]
        v = val[2]
        if rand() < 0.1
            θ_new = θ + (rand(Uniform(-10,10)) |> deg2rad)
            if 0 < θ_new < π
                θ = θ_new
            end
        end
        if rand() < 0.1
            v *= rand(Uniform(0.9,1.1))
            if v > v_max
                v = v_max
            elseif v < v_min
                v = v_min
            end
        end
        generation[ind,:] = [θ,v]
    end
end # function mutate


"""
    display_epoch!(p::Plots.Plot, generation::Matrix, width::Real, height::Real)

this function plot the current epoch
"""
function display_epoch!(p::Plots.Plot, generation::Matrix, width::Real, height::Real)
    pcolor = rand(ColorSchemes.Accent_5.colors)
    markertype = rand(Plots.supported_markers())
    for (θ,v) in eachrow(generation)
        tend = (2*v*sin(θ))/9.81
        x,y = cannonball_trajectory(θ,v,width,range(0,tend[1],length=200))
        if escaped(θ, v, width, height)
            plot!(p, x, y, color = pcolor)
        else
            plot!(p, x, y, color = :red)
        end
        scatter!(p, x[1:Int(0.1*length(y)):end], y[1:Int(0.1*length(y)):end], marker = markertype, color = pcolor)
    end
end # function display_epoch


"""
    display_epoch(p::Plots.Plot, generation::Matrix, width::Real, height::Real)

this function plot the current epoch
"""
function display_epoch(pin::Plots.Plot, generation::Matrix, width::Real, height::Real)
    p = deepcopy(pin)
    for (θ,v) in eachrow(generation)
        tend = (2*v*sin(θ))/9.81
        x,y = cannonball_trajectory(θ,v,width,range(0,tend[1],length=200))
        if escaped(θ, v, width, height)
            plot!(p, x, y, color = :blue)
            scatter!(p, x[1:Int(0.1*length(y)):end], y[1:Int(0.1*length(y)):end], marker = :circle, color = :blue)
        else
            plot!(p, x, y, color = :red)
            scatter!(p, x[1:Int(0.1*length(y)):end], y[1:Int(0.1*length(y)):end], marker = :circle, color = :red)
        end
    end
    return p
end # function display_epoch


"""
    fire()

the main cannonball function
"""
function fire()
    epochs = 100
    items = 100
    height = 10
    width = 10
    max_cennonball_speed = 20
    box =( x = vec([0 0 width width]), y = vec([height 0 0 height]))
    generation = random_tries(items, max_speed = max_cennonball_speed)
    generation0 = deepcopy(generation) # save to contrast with last epoch
    # p = plot(box.x, box.y, legend = false, lw = 3, aspect_ratio=:equal)
    pbox = plot(box.x, box.y, legend = false, lw = 3)
    titles = ["First generation","Last generation"]
    for ii in 1:epochs
        results = []
        generation = crossover(generation, width)
        mutate(generation)
    end
    genPlot = (generation0,generation)
    pout = Vector{Any}(undef,length(genPlot))
    for (ind,gen) in enumerate(genPlot)
        pout[ind] = display_epoch(pbox, gen, width, height)
        title!(pout[ind],titles[ind])
        xlabel!(pout[ind],"X")
        ylabel!(pout[ind],"Y")
    end
    p = plot(pout[1],pout[2],layout = (2,1))
    display(p)
end # function fire
