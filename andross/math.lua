local androssMath = {}

local class = require "andross.middleclass"

-- a matrix is {a, b, c, d, t_x, t_y}
-- short for a homogeneous transform in 2D:
-- a   b   t_x
-- c   d   t_y
-- 0   0   1

-- normalize angle into [-math.pi, math.pi]
function androssMath.normalizeAngle(a)
    while a >  math.pi do a = a - 2*math.pi end
    while a < -math.pi do a = a + 2*math.pi end
    return a
end

function androssMath.lerpAngles(a, b, t)
    local delta = androssMath.normalizeAngle(b - a)
    return androssMath.normalizeAngle(a + delta * t)
end

function androssMath.sign(x)
    if x < 0 then
        return -1
    elseif x > 0 then
        return 1
    else
        return 0
    end
end

function androssMath.matrixMultiply(a, b)
    return {
        a[1]*b[1] + a[2]*b[3], -- a*a'+b*c'
        a[1]*b[2] + a[2]*b[4], -- a*b'+b*d'
        a[3]*b[1] + a[4]*b[3], -- c*a'+d*c'
        a[3]*b[2] + a[4]*b[4], -- c*b'+d*d'
        a[1]*b[5] + a[2]*b[6] + a[5], -- a*t_x'+b*t_y'+t_x
        a[3]*b[5] + a[4]*b[6] + a[6], -- c*t_x'+d*t_y'+t_y
    }
end

-- Calculated using Minors/Adjugate
function androssMath.matrixInverse(m)
    local a = 1 / (m[1]*m[4] - m[2]*m[3]) -- 1/det
    return {
        -- d, -b, -c, a
        a*m[4], -a*m[2], -a*m[3], a*m[1],
        -- b*t_y - d*t_x
        a*(m[2]*m[6] - m[4]*m[5]),
        -- c*t_x - a*t_y
        a*(m[3]*m[5] - m[1]*m[6]),
    }
end

-- http://math.stackexchange.com/questions/13150/extracting-rotation-scale-values-from-2d-transformation-matrix
-- I'm not sure if I calculcate the signs correctly (i.e. if my consideration of the sign of the cosine is necessary)
-- but I don't understand how it's not (and it works!)
function androssMath.extractPosRotScale(m)
    local x, y = m[5], m[6]
    local angle = math.atan2(m[3], m[4])
    local cosSign = androssMath.sign(math.cos(angle))
    local sX = androssMath.sign(m[1]) / cosSign * math.sqrt(m[1]*m[1] + m[2]*m[2])
    local sY = androssMath.sign(m[4]) / cosSign * math.sqrt(m[3]*m[3] + m[4]*m[4])
    return x, y, angle, sX, sY
end

function androssMath.transformMatrix(x, y, angle, scaleX, scaleY)
    local c, s = math.cos(angle), math.sin(angle)
    return {
        scaleX * c, scaleY * -s,
        scaleX * s, scaleY * c,
        x, y
    }
end

return androssMath
