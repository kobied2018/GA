using Plots
# using IndexedTables
gr()

mutable struct XY
    x::Real
    y::Real
    XY(x::T where {T <: Real}, y::T where {T <: Real}) = new(x,y)
end

mutable struct Particles
    x::Real
    y::Real
    index::Int
    step::Real
    best::XY
    velocity::XY

    function Particles(x::T1, y::T2, index::T3, step::T4 = 10) where {T1 <: Real, T2 <: Real, T3 <: Int, T4 <: Real}
        best = XY(x,y)
        velocity = XY(getRandomInt(-step, step), getRandomInt(0, step))
        new(x, y, index, step, best, velocity)
    end
end # struct Particles



function Particles(index::T2, step::T1 = 10) where {T1 <: Real, T2 <: Int}
    x = step * (rand() - 0.5)
    y = step * (rand() - 0.5)
    Particles(x, y, index, step)
end


struct Bags_size
    w::Real
    h::Real
    x::Real
    y::Real
    sides::NamedTuple

    function Bags_size(w::T1, h::T2, x::T3, y::T4) where {T1 <: Real, T2 <: Real, T3 <: Real, T4 <: Real}
        temp1 = Set(x .+ [0,w,w,0])
        temp2 = Set(y .+ [0,0,h,h])
        sides = (left = minimum(temp1), rigth = maximum(temp1), bottom = minimum(temp2), top = maximum(temp2))
        new(w,h,x,y,sides)
    end
end


"""
    getRandomInt(min,max)

generate a random number between min and max
"""
function getRandomInt(min,max)
    return floor(rand() * (max - min + 1)) + min
end # function

rectangle(w, h, x, y) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])

"""
    init(width::Real, height::Real)

this function create a plot canvas and place the particles and the
center of the canvas
"""
function init(width::T1, height::T2) where {T1 <: Real, T2 <: Real}
    particles = [Particles(1)]
    bag_size= Bags_size(width/3,height/3,-width/6,-height/6)
    canvas = plot(size = (width,height), legend = false)
    xlims!(canvas,(-width/2,width/2))
    ylims!(canvas,(-height/2,height/2))
    bag = rectangle(bag_size.w,bag_size.h,bag_size.x,bag_size.y)
    plot!(canvas, bag, opacity = 0.2)
    draw(particles[1], canvas)
    return (particles, bag_size, canvas)
end # function init

function init(width::T1, height::T2, number::Int) where {T1 <: Real, T2 <: Real}
    particles = []
    for ind in 1:number
        push!(particles,Particles(ind, 50)])
    end
    bag_size= Bags_size(width/3,height/3,-width/6,-height/6)
    canvas = plot(size = (width,height), legend = false)
    xlims!(canvas,(-width/2,width/2))
    ylims!(canvas,(-height/2,height/2))
    bag = rectangle(bag_size.w,bag_size.h,bag_size.x,bag_size.y)
    plot!(canvas, bag, opacity = 0.2)
    for ind in 1:number
        draw(particles[ind], canvas)
    end
    return (particles, bag_size, canvas)
end # function init

"""
    update_all!(particles::Array{Particles}, canvas::Plots.Plot, width::Real, height::Real, bag_size::Bags_size)

this function update all the particles location using the 'move!' funciton
"""
function update_all!(particles::Array{Particles}, canvas::Plots.Plot, width::T1, height::T2, bag_size::Bags_size) where {T1 <: Real, T2 <: Real}
    for ind in 1:length(particles)
        move!(particles,ind)
        canvas.series_list[ind + 1][:x] = particles[ind].x
        canvas.series_list[ind + 1][:y] = particles[ind].y
    end
    # if !in_bag(particles, bag_size.sides)
    #     init()
    # end
end # function update_all!


"""
    update_single!(particles::Array{Particles}, index::Int, canvas::Plots.Plot, width::Real, height::Real, bag_size::Bags_size)

this function update a single particle location using the 'move!' funciton
"""
function update_single!(particles::Array{Particles}, index::T1, canvas::Plots.Plot, width::T2, height::T3, bag_size::Bags_size) where {T1 <: Int, T2 <: Real, T3 <: Real}
    move!(particles,index)
    canvas.series_list[index + 1][:x] = particles[index].x
    canvas.series_list[index + 1][:y] = particles[index].y
    if !in_bag(particles, index, bag_size.sides)
        particles[index].step = 0
    end
end # function update_single!


"""
    move!(particles::Array{Particles}, index::Int)

this function add a random shift in the particles position
"""
function move!(particles::Array{Particles}, index::T) where {T <: Int}
    particles[index].x += particles[index].step * (rand() - 0.5)
    particles[index].y += particles[index].step * (rand() - 0.5)

    k = minimum([5,length(particles)]) - 1
    items = knn(particles, index, k)
    x_step, y_step = iszero(length(items)) ? (0,0) : nudge(particles[items])
    # @info "particles x_step = $x_step, y_step = $y_step"
    particles[index].x += (x_step - particles[index].x)*(rand() - 0.5)
    particles[index].y += (y_step - particles[index].y)*(rand() - 0.5)

    return particles
end # function move!


"""
    nudge(particles::Array{Particles})

documentation
"""
function nudge(particles::Array{Particles})
    N = length(particles)
    iszero(N) && return 0
    sum = [0.0,0.0]
    for particle in particles
        sum[1] += particle.x
        sum[2] += particle.y
    end
    return (sum[1]/N,sum[2]/N)
end # function nudge


"""
    draw(particles::Particles, canvas::Plots.Plot)

this function draw the bag and particles
"""
function draw(particles::Particles, canvas::Plots.Plot)
    scatter!(canvas,[particles.x],[particles.y],marker = :rect)
end # function draw


"""
    in_bag(particles::Array{Particles}, bag_sides::NamedTuple)::Bool

this function has two methods
    1. check if all the particles are in the bag
    2. check if a specific particle is in the bag
"""
function in_bag(particles::Array{Particles}, bag_sides::NamedTuple)::Bool
    res = fill(false,(length(particles),1))
    for (ind,particle) in enumerate(particles)
        if (bag_sides.left < particle.x < bag_sides.rigth) && (bag_sides.bottom < particle.y < bag_sides.top)
            res[ind] = true
        end
    end
    return all(res)
end # function in_bag

function in_bag(particles::Array{Particles}, index::T, bag_sides::NamedTuple)::Bool  where {T <: Int}
    res = false
    if (bag_sides.left < particles[index].x < bag_sides.rigth) && (bag_sides.bottom < particles[index].y < bag_sides.top)
        res = true
    end
    return res
end # function in_bag


"""
    addparticle(particles::Array{Particles},canvas::Plots.Plot)

this function add a new particles at the center of the canvas
"""
function addparticle(particles::Array{Particles}, canvas::Plots.Plot)
    index = length(particles) + 1
    push!(particles,Particles(index))
    draw(particles[end], canvas)
end # function addparticle


"""
    euclidean_distance(p1,p2)

this function calculate the euclidean distance between two particles
"""
function euclidean_distance(p1::Particles, p2::Particles)
    return sqrt((p1.x - p2.x)^2 + (p1.y - p2.y)^2)
end # function euclidean_distance


"""
    knn(particles::Array{Particles}, index::Int)

this function finds the 'k' nearest neighbors
"""
function knn(particles::Array{Particles}, index::T, k::T) where {T <: Int}
    tested_particle = particles[index]
    dist = []
    ind = []
    for particle in particles
        if particle.index != index
            push!(dist,euclidean_distance(tested_particle,particle))
            push!(ind,particle.index)
        end
    end
    m = [dist ind]
    return iszero(length(m)) ? [] : m[sortperm(m[:,1]),:][1:k,2]
end # function knn


"""
    main_all(width::Real = 600, height::Real = 600)

this function run the main loop and move all the particles at the same time
"""
function main_all(width::T1 = 600, height::T2 = 600) where {T1 <: Real, T2 <: Real}
    println("To add a new particles press 'n'")
    println("To add a quit press 'q'")
    (particles, bag_size, canvas) = init(width, height)
    @async begin
        cb(timer) = (update_all!(particles, canvas, width, height, bag_size);display(canvas))
        global t = Timer(cb,0, interval = 1)
    end
    while true
        kb_input = readline()
        if lowercase(kb_input) == "n"
            addparticle(particles,canvas)
            kb_input = ""
        end
        if lowercase(kb_input) == "q"
            close(t)
            break
        end
    end
end # function main_all


"""
    main_single(width::Real = 600, height::Real = 600)

this function run the main loop and move a single particle at a time
"""
function main_single(width::T1 = 600, height::T2 = 600) where {T1 <: Real, T2 <: Real}
    println("To add a new particles press 'n'")
    println("To add a quit press 'q'")
    (particles, bag_size, canvas) = init(width, height)
    current_p = 0
    @async begin
        cb(timer) = (current_p = (current_p  % length(particles)) + 1;
                     if particles[current_p].step > 0
                         update_single!(particles, current_p, canvas, width, height, bag_size)
                     end;
                     display(canvas))
        global t = Timer(cb,0, interval = 1)
    end
    while true
        kb_input = readline()
        if lowercase(kb_input) == "n"
            addparticle(particles,canvas)
            kb_input = ""
        end
        if lowercase(kb_input) == "q"
            close(t)
            break
        end
    end
end # function main_single


"""
    main_follow_the_best(width::Real = 600, height::Real = 600)

this function run the main loop and move a single particle at a time
"""
function main_follow_the_best(width::T1 = 600, height::T2 = 600; number::Int = 20) where {T1 <: Real, T2 <: Real}
    println("To add a new particles press 'n'")
    println("To add a quit press 'q'")
    (particles, bag_size, canvas) = init(width, height, number)
    current_p = 0
    @async begin
        cb(timer) = (current_p = (current_p  % length(particles)) + 1;
                     if particles[current_p].step > 0
                         update_single!(particles, current_p, canvas, width, height, bag_size)
                     end;
                     display(canvas))
        global t = Timer(cb,0, interval = 1)
    end
    while true
        kb_input = readline()
        if lowercase(kb_input) == "n"
            addparticle(particles,canvas)
            kb_input = ""
        end
        if lowercase(kb_input) == "q"
            close(t)
            break
        end
    end
end # function main_follow_the_best


"""
    create_animate()

documentation
"""
function create_animate(args)
    anim = @animate for ii in 1:15
        Timer(update_all!(particles, canvas, width, height, bag_size),0, interval = 1)
        display(canvas)
    end
    gif(anim, joinpath(@__DIR__,"..","animations\\anim_fps15.gif"), fps = 15)
end # function
