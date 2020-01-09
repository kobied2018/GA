export LSystem,render,evaluate

# based on: https://github.com/cormullion/Lindenmayer.jl
mutable struct LSystem
    rules::Dict{String, String}
    state::Array{Int64, 1}
    initial_state::Array{Int64, 1}
    function LSystem(rules, state_as_string)
        newlsystem = new(rules, string_to_array(state_as_string), string_to_array(state_as_string))
        return newlsystem
    end
end

function string_to_array(str::String)
    temp = Array{Int64, 1}()
    for c in str
        push!(temp, Int(c))
    end
    return temp
end

function array_to_string(arr::Array)
    temp = ""
    for c in arr
        temp = string(temp, Char(abs(c)))
    end
    return temp
end

"""
    evaluate(ls::LSystem, iterations=1)
Apply the rules in the LSystem to the initial state repeatedly. The ls.state array holds
the result.
This must be inefficient, creating a new copy of the state each time......? :(
"""
function evaluate(ls::LSystem, iterations=1; debug=false)
    for i in 1:iterations
        debug && println("iteration $i")
        the_state = Array{Int64, 1}()
        for j in 1:length(ls.state) # each character in state
            s = string(Char(ls.state[j]))
            if haskey(ls.rules, s)
                #  replace it using the rule
                value = ls.rules[s]
                varr = string_to_array(value)
                if ! isempty(value)
                    push!(the_state, varr...)
                end
            else # keep it in
                push!(the_state, ls.state[j])
            end
        end
        ls.state = the_state
        debug == true ? println(array_to_string(ls.state)) : print("")
    end
end

"""
    render(ls::LSystem)
Once the LSystem has been evaluated, the LSystem.state can be drawn.
"""
function render(ls::LSystem, t::Turtles, stepdistance, rotangle, do_till_escaped; debug=false)
    counter = 1
    escaped = false
    for a in ls.state
        command = string(Char(a))
        if command =="F"
            escaped = draw_line(t, 0, stepdistance)
        elseif command =="G"
            escaped = draw_line(t, 0, stepdistance)
        elseif command =="B"
            cw(t, π)
            escaped = draw_line(t, 0, stepdistance)
            cw(t, π)
        elseif command =="V"
            cw(t, π)
            escaped = draw_line(t, 0, stepdistance)
            cw(t, π)
        elseif command =="f"
            escaped = draw_line(t, 0, stepdistance/2)
        elseif command =="b"
            cw(t, π)
            escaped = draw_line(t, 0, stepdistance/2)
        elseif command =="U"
            penup(t)
        elseif command =="D"
            pendown(t)
        elseif command =="+"
            cw(t, rotangle)
        elseif command =="-"
            ccw(t, rotangle)
        elseif command =="r"
            rotangle = deg2rad.([10, 15, 30, 45, 60])[rand(1:end)]
        # elseif command =="T"
        #     randomhue()
        # elseif command =="t"
        #     HueShift(t, 5) # shift hue round the Hue scale (0-360)
        # elseif command =="c"
        #     Randomize_saturation(t) # shift saturation
        # elseif command =="O"
        #     Pen_opacity_random(t)
        elseif command =="l"
            stepdistance = stepdistance + 1 # larger
        elseif command =="s"
            stepdistance = stepdistance - 1 # smaller
        elseif command =="5"
            t.pen.size = 5
        elseif command =="4"
            t.pen.size = 4
        elseif command =="3"
            t.pen.size = 3
        elseif command =="2"
            t.pen.size = 2
        elseif command =="1"
            t.pen.size = 1
        elseif command =="n"
            t.pen.size = 0.5
        # elseif command =="o"
            # Circle(t, stepdistance/4)
        # elseif command =="q"
            # Rectangle(t, stepdistance/4, stepdistance/4)
        elseif command =="["
            push!(t) # push //TODO - need to implimant
        elseif command =="]"
            pop!(t)   # pop //TODO - need to implimant
        end
        counter += 1
        if do_till_escaped && escaped
            break
        end
    end
    return (counter,escaped)
end
