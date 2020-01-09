import ReferenceFrameRotations
path = @__DIR__
include(joinpath(path,"Turtle_struct.jl"))
include(joinpath(path,"LSystem.jl"))
using Plots
using CSV, DataFrames
gr()

RF = ReferenceFrameRotations

#========================= Export =======================================#
export penup,pendown,goto,cw,ccw,forward,turtle_plot
export draw_line,draw_squares,draw_triangles,draw_lsystem
export main_proj

#========================= Function =======================================#

"""
    penup(turtle::Turtles)

this function create a new searies data with in the main plot (turtle.plt)
and set turtle.pen_up = true
"""
function penup(turtle::Turtles)
    turtle.pen.up = true
    turtle.history = [turtle.history;[NaN,NaN,NaN]']
    # plot!(turtle.plt,[turtle.pos[1]],[turtle.pos[2]]);
end # function penup


"""
    pendown(turtle::Turtles)

this function set turtle.pen_up = false
and store position data
"""
function pendown(turtle::Turtles)
    turtle.pen.up = false
    store_position_data(turtle)
end # function pendown


"""
     goto(turtle::Turtles,newpos::Array{T} where T<:Real)

this function update the turtle position.
the input is a new point in [x,y] coords that the turtle jump to.
"""
function goto(turtle::Turtles,newpos::Array{T}  where T<:Real)
    if length(newpos) != 2
        DimensionMismatch("The new point to goto must have 2 elements [x,y]")
    end

    if !(newpos isa Vector)
        newpos = vec(newpos)
    end

    turtle.pos = newpos
end #function goto



"""
    cw(turtle::Turtles,ang::Real)

this function update the turtle heading clock wise direction.
the input ang must be in [Rad], negative or positive angle
are treated as positive.
"""
function cw(turtle::Turtles,ang::Real)
    turtle.heading -= abs(ang)
end # function cw


"""
    ccw(turtle::Turtles,ang::Real)

this function update the turtle heading counter clock wise direction.
the input ang must be in [Rad], negative or positive angle
are treated as positive.
"""
function ccw(turtle::Turtles,ang::Real)
    turtle.heading += abs(ang)
end # function ccw


"""
    forward(turtle::Turtles,step::AbstractFloat)

this function will advance the turtle forward in the heading direction
for distance of 'step'
"""
function forward(turtle::Turtles,step::Real)
    R = RF.angle_to_dcm(turtle.heading,0,0)
    turtle.pos += vec(step * R[1,1:2])
    if !turtle.pen.up
        store_position_data(turtle)
    end
end # function forward


"""
    turtle_plot(data)

this function plot datain with in the turtle.main_scene
"""
function turtle_plot(turtle::Turtles)
    if !turtle.pen.up
        turtle.plt.series_list[end].plotattributes[:x] = turtle.history[:,1]
        turtle.plt.series_list[end].plotattributes[:y] = turtle.history[:,2]
        turtle.plt.series_list[2].plotattributes[:x] = turtle.pos[1]
        turtle.plt.series_list[2].plotattributes[:y] = turtle.pos[2]
    end
end # function turtle_plot


"""
    escaped(turtle::Turtles)

this function check if the turtle escape the bag
"""
function escaped(turtle::Turtles)
    res = false
    if  (turtle.pos[1] < minimum(turtle.bag.vertexes[:,1]) ||
        turtle.pos[1] > maximum(turtle.bag.vertexes[:,2])) ||
        (turtle.pos[2] < minimum(turtle.bag.vertexes[:,2]) ||
        turtle.pos[2] > maximum(turtle.bag.vertexes[:,2]))
        res = true
    end
    return res
end # function escaped


"""
    store_position_data(turtle::Turtles)

this function save to last step the turtle did within an array
"""
function store_position_data(turtle::Turtles)
    if !turtle.pen.up
        d = [turtle.pos;escaped(turtle)]'
        turtle.history = [turtle.history;d]
    end
end # function store_position_data



"""
    push!(turtle::Turtles)

this function push the current turtle position into vector 'turtle.junctions'
"""
function Base.push!(turtle::Turtles)
    push!(turtle.junctions,turtle.pos)
end # function push!


"""
    pop!(turtle::Turtles)

this function pop the last position data from 'turtle.junctions' vector
"""
function Base.pop!(turtle::Turtles)
    return pop!(turtle.junctions)
end # function pop!


"""
    draw_line(turtle::Turtles,turn_rad::Real, step::Real)

this function draw a line, by first rotating the turtle at 'turn_rad'
(ccw if 'turn_rad' > 0 and cw if 'turn_rad' < 0)
then move the turtle at the new direction distance of 'step'
the function check if the turtle escaped the bag and return true or false
"""
function draw_line( turtle::Turtles,
                    turn_rad::Real,
                    step::Real)
    if turn_rad < 0
        cw(turtle,turn_rad)
    elseif turn_rad > 0
        ccw(turtle,turn_rad)
    end
    forward(turtle,step)
    store_position_data(turtle)
    return escaped(turtle)
end # function draw_line


"""
    draw_square(turtle::Turtles, turn_rad::Real, step::Real, do_till_escaped::Bool)

this function draw a square rotated at 'turn_rad' and which rib size = 'step'
if 'do_till_escaped' == true, the function will stop when turtle escaped
"""
function draw_square(   turtle::Turtles,
                        turn_rad::Real,
                        step::Real,
                        do_till_escaped::Bool)
    res = false
    escaped = draw_line(turtle,turn_rad,step)
    if do_till_escaped && escaped
        res = true
    else
        for ii in 1:3
            escaped = draw_line(turtle,π/2,step)
            if do_till_escaped && escaped
                res = true
                break
            end
        end
    end
    return res
end # function draw_square


"""
    draw_squares(turtle::Turtles, N::Int, turn_rad::Real, step::Real, increase_step::Real, do_till_escaped::Bool)

this function draw 'N' squares,
the first square start at the curent turtle pos,
then it is rotated at initial 'turn_rad' radians,
with initial rib size = step.
the next square rib = 'step' + i*'increase_step'
if 'do_till_escaped' == true, the function will stop when turtle escaped
"""
function draw_squares(  turtle::Turtles,
                        N::Int,
                        turn_rad::Real,
                        step::Real,
                        increase_step::Real,
                        do_till_escaped::Bool)
    res = false
    escaped = draw_square(turtle, turn_rad, step, do_till_escaped)
    if do_till_escaped && escaped
        res = true
    else
        for ii in 1:N-1
            penup(turtle)
            forward(turtle,increase_step)
            cw(turtle,π/2)
            forward(turtle,increase_step)
            cw(turtle,π)
            pendown(turtle)
            escaped = draw_square(turtle, 0, step + ii*2*increase_step, do_till_escaped)
            if do_till_escaped && escaped
                res = true
                break
            end
        end
    end
    return res
end # function draw_squares


"""
    draw_triangles(turtle::Turtles, turn_rad::Real, N::Int, ang::Real, step::Real, increase_step::Real, do_till_escaped::Bool)

this function draw spriangles with angle = 'ang'
and initial rib size = 'step'
and rib = step + i * increase_step
if 'do_till_escaped' == true, the function will stop when turtle escaped
"""
function draw_triangles(turtle::Turtles,
                        turn_rad::Real,
                        N::Int,
                        ang::Real,
                        step::Real,
                        increase_step::Real,
                        do_till_escaped::Bool)
    res = false
    escaped = draw_line(turtle,turn_rad,step)
    if do_till_escaped && escaped
        res = true
    else
        for ii in 1:3*N-1
            escaped = draw_line(turtle,ang,step + ii*increase_step)
            if do_till_escaped && escaped
                res = true
                break
            end
        end
    end
    return res
end # function draw_triangles


"""
    draw_lsystem(turtle::Turtles, lsys_data::Dict, do_till_escaped::Bool, lsys_data::Tuple, step::Real, turn_rad::Real, iterations::Int)

this function will draw a Lsystem expration
"""
function draw_lsystem(  turtle::Turtles,
                        do_till_escaped::Bool,
                        lsys_data::Tuple,
                        step::Real,
                        turn_rad::Real,
                        iterations::Int)
    lsystem = LSystem(lsys_data[1],lsys_data[2])
    lsystem.state = lsystem.initial_state
    evaluate(lsystem,iterations,debug = false)
    render(lsystem, turtle, step, turn_rad, do_till_escaped, debug = false)
    return true
end # function draw_lsystem


"""
    save_to_file(turtle::Turtles)

this function save the turtle.history data to csv file
after filterring NaN values
"""
function save_to_file(turtle::Turtles,csvFilenameIn::String = "run_1.csv")
    if occursin(r".csv",csvFilenameIn)
        splitName = split(fullFileName,'.')
        endSplitName = splitName[1][end]
        if isnumeric(endSplitName)
            fullFileName = csvFilenameIn
        else
            fullFileName = splitName[1] * "_1.csv"
        end
    else
        if isnumeric(csvFilenameIn[end])
            fullFileName = csvFilenameIn * ".csv"
        else
            fullFileName = csvFilenameIn * "_1.csv"
        end
    end

    while isfile(fullFileName)
        splitName = split(fullFileName,'.')
        endSplitName = splitName[1][end]
        if isnumeric(endSplitName)
            numlength = sum(map(isnumeric,collect(splitName[1])))
            fileNameApendix = string(parse(Int64,splitName[1][end - numlength + 1 : end]) + 1)
        else
            fileNameApendix = "1"
        end

        fullFileName = splitName[1][1:end - length(fileNameApendix)] * fileNameApendix * ".csv"
    end

    datatofile = DataFrame(turtle.history)
    filter!(row->!isnan(row.x1),datatofile)
    CSV.write(fullFileName,  datatofile, writeheader=false)
end # function save_to_file


"""
    popup_my_input(prompt::String = "", df_val::DefaultVals)

this function ask the user to enter needed params for the called function
"""
function popup_my_input(df_val, prompt::String = "")
    if df_val isa Tuple
        println(prompt)
        d = Dict{String,String}()
        addData = true
        while addData
            println("\nEnter Var")
            varStr = chomp(readline())
            if isempty(varStr)
                println("default value was taken")
                d = df_val[1]
                addData = false
                break
            end
            println("Enter Expration")
            expStr = chomp(readline())
            println("recived $varStr => $expStr as Lsystm Expration")
            if haskey(d,varStr)
                println("Var exsist enter a new one")
            else
                d[varStr] = expStr
            end
        end
        println("\nEnter the starting point")
        startStr = chomp(readline())
        if isempty(startStr)
            startStr = df_val[2]
        else
            println("default value was taken")
            println("recived starting point = $startStr")
        end
        val = (d,startStr)
    else
        println(prompt)
        str = chomp(readline())
        if isempty(str)
            val = df_val
        else
            val = parse(typeof(df_val),str)
        end
    end
    return val
end # function popup_my_input


"""
    get_inputs_list(f::Function)

this function extract the given function, it's input argumant list
"""
function get_inputs_list(f::Function)
    list = []
    for m in methods(f)
        push!(list,string.(Base.method_argnames(m))...)
    end
    inputlist = Dict{String,Symbol}()
    for str in list
        splitlist = split(str,"\0")
        for s in splitlist
            if s == "#self#" || s == ""
                continue
            end
            if !haskey(inputlist,s)
                inputlist[s] = Symbol(s)
            end
        end
    end
    return inputlist
end # function get_inputs_list


"""
    get_my_input(dv::DefaultVals, ex)

this function call the function 'popup_my_input', to ask for the user to enter
the needed value for the needed var
"""
function get_my_input(dv::DefaultVals, ex)
    println("give value to $(string(ex)) or press ENTER for deafult")
    if ex == :turn_rad
        dv.turn_rad = popup_my_input(dv.turn_rad, "enter angle, in Deg, to rotate the turtle (positive -> ccw, negative -> cw), deafult = $(rad2deg(dv.turn_rad))")
        dv.turn_rad = deg2rad(dv.turn_rad)
        println("value entered = $(rad2deg(dv.turn_rad))")
    end
    if ex == :step
        dv.step = popup_my_input(dv.step, "enter step size, deafult = $(dv.step)")
        println("value entered = $(dv.step)")
    end
    if ex == :N
        dv.N = popup_my_input(dv.N, "enter number of reapets, deafult = $(dv.N)")
        println("value entered = $(dv.N)")
    end
    if ex == :ang
        dv.ang = popup_my_input(dv.ang, "enter triangle angle, in Rad, deafult = $(dv.ang)")
        println("value entered = $(dv.ang)")
    end
    if ex == :increase_step
        dv.increase_step = popup_my_input(dv.increase_step, "enter step increase size, deafult = $(dv.increase_step)")
        println("value entered = $(dv.increase_step)")
    end
    if ex == :do_till_escaped
        dv.do_till_escaped = popup_my_input(dv.do_till_escaped, "enter do_till_escaped, deafult = $(dv.do_till_escaped)")
        println("value entered = $(dv.do_till_escaped)")
    end
    if ex == :lsys_data
        dv.lsys_data = popup_my_input(dv.lsys_data, "enter lsys_data, deafult = $(dv.lsys_data)")
        println("value entered = $(dv.lsys_data)")
    end
    if ex == :iterations
        dv.iterations = popup_my_input(dv.iterations, "enter iterations, deafult = $(dv.iterations)")
        println("value entered = $(dv.iterations)")
    end
    println("===============================================================")
    println("")
end # function my_input


#================================= MACROS ===================================#
# see : https://discourse.julialang.org/t/undefvarerror-x-not-defined-when-calling-a-macro-outside-of-its-module/20201/3
# for explanation on the use of 'esc' in macro
macro run_type(type,func_type_dict,turtle,dv)
    quote
        local _type = $(esc(type))
        local _func_type_dict = $(esc(func_type_dict))
        local _turtle = $(esc(turtle))
        local _dv = $(esc(dv))
        inputs_needed = get_inputs_list(_func_type_dict[_type][1])
        for (k,v) in inputs_needed
            if v == :turtle
                continue
            end
            get_my_input(_dv,v)
        end
        if _dv.do_till_escaped
            _func_type_dict[_type][3](_turtle,_dv)
        else
            _func_type_dict[_type][2](_turtle,_dv)
        end
    end
end # macro run_type

# ------------------------  Tests -------------------------------------------
function main_line(turtle::Turtles, dv::DefaultVals)
    # turtle = Turtles()
    draw_line(turtle,dv.turn_rad,dv.step)
    turtle_plot(turtle)
    save_to_file(turtle,"main_line")
    return turtle.plt
end


function main_line_till_escaped(turtle::Turtles, dv::DefaultVals)
    # turtle = Turtles()
    escaped = false
    while !escaped
        escaped = draw_line(turtle,dv.turn_rad,dv.step)
        turtle_plot(turtle)
    end
    save_to_file(turtle,"main_line_till_escaped")
    return turtle.plt
end


function main_squares(turtle::Turtles, dv::DefaultVals)
    # turtle = Turtles()
    draw_squares(turtle,dv.N,dv.turn_rad,dv.step,dv.increase_step,dv.do_till_escaped)
    turtle_plot(turtle)
    save_to_file(turtle,"main_squares")
    return turtle.plt
end


function main_squares_till_escaped(turtle::Turtles, dv::DefaultVals)
    # turtle = Turtles()
    escaped = false
    while !escaped
        escaped = draw_squares(turtle,dv.N,dv.turn_rad,dv.step,dv.increase_step,dv.do_till_escaped)
        turtle_plot(turtle)
    end
    save_to_file(turtle,"main_squares_till_escaped")
    return turtle.plt
end


function main_triangles(turtle::Turtles, dv::DefaultVals)
    # turtle = Turtles()
    draw_triangles(turtle, dv.turn_rad, dv.N, dv.ang, dv.step, dv.increase_step, dv.do_till_escaped)
    turtle_plot(turtle)
    save_to_file(turtle,"main_triangles")
    return turtle.plt
end

function main_triangles_till_escaped(turtle::Turtles, dv::DefaultVals)
    # turtle = Turtles()
    escaped = false
    while !escaped
        escaped = draw_triangles(turtle, dv.turn_rad, dv.N, dv.ang, dv.step, dv.increase_step, dv.do_till_escaped)
        turtle_plot(turtle)
    end
    save_to_file(turtle,"main_triangles_till_escaped")
    return turtle.plt
end


function main_Lsystem(turtle::Turtles,dv::DefaultVals)
    draw_lsystem(turtle, dv.do_till_escaped, dv.lsys_data, dv.step, dv.turn_rad, dv.iterations)
    turtle_plot(turtle)
    save_to_file(turtle,"main_Lsystem")
    return turtle.plt
end

"""
    main_porj(moveType::String, stop_condition::String; N::Int, trun_rad::Real)

documentation
"""
function main_proj(move_type_in::String)
    turtle = Turtles()
    dv = DefaultVals()
    func_type_dict = Dict(  :line => [draw_line, main_line, main_line_till_escaped],
                            :squares => [draw_squares, main_squares, main_squares_till_escaped],
                            :triangles => [draw_triangles, main_triangles, main_triangles_till_escaped],
                            :lsystem => [draw_lsystem,main_Lsystem,main_Lsystem])
    move_type = Symbol(move_type_in)
    @run_type(move_type,func_type_dict,turtle,dv)
end # function main_proj
