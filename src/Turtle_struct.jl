using Plots

export DefaultVals,Bags,Pens,Turtles

mutable struct DefaultVals
    turn_rad::Real
    step::Real
    do_till_escaped::Bool
    N::Int
    increase_step::Real
    ang::Real
    lsys_data::Tuple
    iterations::Int

    function DefaultVals()
        turn_rad = 0
        step = 100
        do_till_escaped = false
        N = 10
        increase_step = 50
        ang = deg2rad(120)
        lsys_data = (Dict("L" => "L+RF+",
                    "R" => "-FL-R"),
                    "L")
        iterations = 3
        new(turn_rad,step,do_till_escaped,N,increase_step,ang,lsys_data,iterations)
    end
end


mutable struct Bags
    vertexes::Union{Matrix{T} where T<:Real,Tuple}

    function Bags(x::Union{Array{T} where T<:Real,Tuple} = vec([-350. -350. 350. 350.]), y::Union{Array{T} where T<:Real,Tuple} = vec([350. -350. -350. 350.]))
        if x isa Tuple
            x = collect(x)
        end

        if !(x isa Vector)
            # @warn "x is converted from $(typeof(x)) to Array{$(eltype(x)),1} by columns"
            x = vec(x)
        end

        if y isa Tuple
            y = collect(y)
        end

        if !(y isa Vector)
            # @warn "y is converted from $(typeof(y)) to Array{$(eltype(y)),1} by columns"
            y = vec(y)
        end

        if size(x) != size(y)
            DimensionMismatch("vector x,y dimensions mismatch")
        end

        new([x y])
    end
end


mutable struct Pens
    color::Symbol
    size::Int
    up::Bool

    function Pens(;color::Union{String,Symbol,AbstractFloat} = :blue, size = 5, up::Bool = false)
        new(color,size,up)
    end
end

mutable struct Turtles
    bag::Bags
    pen::Pens
    icon_shape::Symbol
    icon_size::Int
    pos::Vector
    heading::AbstractFloat
    plt::Plots.Plot
    history::Array{Any,2}
    junctions::Vector

    function Turtles(;  bag::Bags = Bags(),
                        pen::Pens = Pens(),
                        icon_shape::Symbol = :rect,
                        icon_size::Int = 5,
                        pos::Union{Tuple,Array{T} where T<:Real} = vec([0.0,0.0]),
                        heading::Real = 0.0,
                        world_size::Union{Tuple,Vector{T} where T<:Real} = vec([600., 600.]))

        if pos isa Tuple
            pos = collect(pos)
        end

        if !(pos isa Vector)
            pos = vec(pos)
        end

        if length(pos) != 2
            DimensionMismatch("The new point to goto must have 2 elements [x,y]")
        end

        if world_size isa Tuple
            world_size = vec(world_size)
        end

        if length(world_size) != 2
            DimensionMismatch("The worldSize must have 2 elements [width,hight]")
        end
        plt = plot();
        plot!(plt,  bag.vertexes[:,1],bag.vertexes[:,2],
                    xlims = (-world_size[1],world_size[1]),
                    ylims = (-world_size[2],world_size[2]),
                    leg = false, xgrid = false, ygrid = false,
                    linewidth = pen.size, linecolor = pen.color);
        scatter!(plt,[pos[1]],[pos[2]],marker = (icon_shape,icon_size));
        plot!(plt,[pos[1]],[pos[2]]);
        history = [pos;false]'
        junctions = []
        new(bag,pen,icon_shape,icon_size,pos,heading,plt,history,junctions);
    end
end
