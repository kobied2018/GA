"""
cannonball_trajectory(v::Real,θ::Real)

this function return the cannonball [x,y] coords at time t for
for initial data v,θ
"""
function cannonball_trajectory(v::Real,θ::Real)
    g = 9.81
    x,y = v*t*cos(θ), v*t*sin(θ) - 0.5*g*t^2
end # function cannonball_trajectory
