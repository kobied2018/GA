using Plots
gr()


mutable struct Particles
    x::Real
    y::Real
    function Particles(x::Real,y::Real)
        new(x,y)
    end
end # struct Particles


"""
    particles(x::Real, y::Real)

this function create a new particle
"""
function particles(x::Real, y::Real)::Particles
    return Particles(x,y)
end # function Particle

struct Bags_size
    w::Real
    h::Real
    x::Real
    y::Real
    sides::NamedTuple

    function Bags_size(w::Real, h::Real, x::Real, y::Real)
        temp1 = Set(x .+ [0,w,w,0])
        temp2 = Set(y .+ [0,0,h,h])
        sides = (left = minimum(temp1), rigth = maximum(temp1), bottom = minimum(temp2), top = maximum(temp2))
        new(w,h,x,y,sides)
    end
end

rectangle(w, h, x, y) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])

"""
    init(width::Real, height::Real)

this function create a plot canvas and place the particle and the
center of the canvas
"""
function init(width::Real, height::Real)
    particle = [particles(0,0)]
    bag_size= Bags_size(width/3,height/3,-width/6,-height/6)
    canvas = plot(size = (width,height), legend = false)
    xlims!(canvas,(-width/2,width/2))
    ylims!(canvas,(-height/2,height/2))
    bag = rectangle(bag_size.w,bag_size.h,bag_size.x,bag_size.y)
    plot!(canvas, bag, opacity = 0.2)
    draw(particle[1], canvas)
    return (particle, bag_size, canvas)
end # function init


"""
    update(particle::Array{Particles})

this function update the particle location using the 'move' funciton
"""
function update(particle::Array{Particles}, canvas::Plots.Plot, width::Real, height::Real, bag_size::Bags_size)
    move(particle)
    for (ind,p) in enumerate(particle)
        canvas.series_list[ind + 1][:x] = p.x
        canvas.series_list[ind + 1][:y] = p.y
    end
    if !in_bag(particle, bag_size.sides)
        init()
    end
end # function update


"""
    move(particle::Array{Particles})

this function add a random shift in the particle position
"""
function move(particle::Array{Particles})
    for p in particle
        p.x += 50 * (rand() - 0.5)
        p.y += 50 * (rand() - 0.5)
    end
    return particle
end # function move


"""
    draw(particle::Particles, canvas::Plots.Plot)

this function draw the bag and particle
"""
function draw(particle::Particles, canvas::Plots.Plot)
    scatter!(canvas,[particle.x],[particle.y],marker = :rect)
end # function draw


"""
    in_bag(particle::Array{Particles}, bag_sides::NamedTuple)::Bool

this function chekc if the particle is in the bag
"""
function in_bag(particle::Array{Particles}, bag_sides::NamedTuple)::Bool
    res = fill(false,(length(particle),1))
    for (ind,p) in enumerate(particle)
        if (bag_sides.left < p.x < bag_sides.rigth) && (bag_sides.bottom < p.y < bag_sides.top)
            res[ind] = true
        end
    end
    return all(res)
end # function in_bag

"""
    addparticle(particle::Array{Particles},canvas::Plots.Plot)

this function add a new particle at the center of the canvas
"""
function addparticle(particle::Array{Particles},canvas::Plots.Plot)
    push!(particle,particles(0,0))
    draw(particle[end], canvas)
end # function addparticle


"""
    main(width::Real = 600, height::Real = 600)

documentation
"""
function main(width::Real = 600, height::Real = 600)
    println("To add a new particle press 'n'")
    println("To add a quit press 'q'")
    (particle, bag_size, canvas) = init(width, height)
    @async begin
        cb(timer) = (update(particle, canvas, width, height, bag_size);display(canvas))
        global t = Timer(cb,0, interval = 1)
    end
    # @async begin
        while true
            kb_input = readline()
            if lowercase(kb_input) == "n"
                addparticle(particle,canvas)
                kb_input = ""
            end
            if lowercase(kb_input) == "q"
                close(t)
                break
            end
        end
    # end
end # function main


"""
    create_animate()

documentation
"""
function create_animate(args)
    anim = @animate for ii in 1:15
        Timer(update(particle, canvas, width, height, bag_size),0, interval = 1)
        display(canvas)
    end
    gif(anim, joinpath(@__DIR__,"..","animations\\anim_fps15.gif"), fps = 15)
end # function
