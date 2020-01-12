using Plots
gr()


struct Particles
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


"""
    init(width::Real = 600, height::Real = 600)

this function create a plot canvas and place the particle and the
center of the canvas
"""
function init(width::Real = 600, height::Real = 600)
    particle = particles(width/2,height/2)
    canvas = plot(size = (width,height))
end # function init


"""
    update(particle::Particles)

this function update the particle location using the 'move' funciton
"""
function update(particle::Particles)
    move(particle)

    if !draw(particle)
        init()
    end
end # function update


"""
    move(particle::Particles)

this function add a random shift in the particle position
"""
function move(particle::Particles)
    particle.x += 50 * (rand() - 0.5)
    particle.y += 50 * (rand() - 0.5)
end # function move


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
    draw(particle::Particles; width::Real = 600, height::Real = 600)

this function draw the bag and particle
"""
function draw(particle::Particles; width::Real = 600, height::Real = 600)::Bool
    bag_size= Bags_size(width/3,height/3,-width/6,-height/6)
    bag = rectangle(bag_size.w,bag_size.h,bag_size.x,bag_size.y)
    p = plot(bag, opacity = 0.2, legend = false)
    xlims!(p,(-width/2,width/2))
    ylims!(p,(-height/2,height/2))
    scatter!(p,[particle.x],[particle.y],marker = :rect)
    return in_bag(particle, bag_sides)
end # function draw


"""
    in_bag(particle::Particles, bag_sides::NamedTuple)::Bool

this function chekc if the particle is in the bag
"""
function in_bag(particle::Particles, bag_sides::NamedTuple)::Bool
    (bag_sides.left < particle.x < bag_sides.rigth) && (bag_sides.bottom < particle.y < bag_sides.top) && return true
end # function in_bag
