local class = require "andross.middleclass"

local Skeleton = class("Skeleton")

function Skeleton:initialize()
    self.bones = {}
end

-- parent can be name or index
function Skeleton:addBone(name, parent, length, positionX, positionY, angle, scaleX, scaleY)
    if parent then
        assert(self.bones[parent], "Parent bone index/name unknown!")
        parent = self.bones[parent]
    end

    assert(self.bones[name] == nil, "Bone " .. name .. " already present")
    self.bones[name] = {
        name = name,
        index = #self.bones+1,
        parent = parent,
        updateCounter = 0,
        worldTransform = {},

        length = length or 0,
        setupTransform = {
            positionX = positionX or 0,
            positionY = positionY or 0,
            angle = angle or 0,
            scaleX = scaleX or 1,
            scaleY = scaleY or 1,
        },
        positionX = 0,
        positionY = 0,
        angle = 0,
        scaleX = 1,
        scaleY = 1,
    }
    local setupTrafo = self.bones[name].setupTransform
    setupTrafo.matrix = transformMatrix(setupTrafo.positionX, setupTrafo.positionY,
                                        setupTrafo.angle, setupTrafo.scaleX, setupTrafo.scaleY)

    self.bones[#self.bones+1] = self.bones[name]
    self.updateCounter = 0
end


-- a matrix is {a, b, c, d, t_x, t_y}
-- short for a homogeneous transform in 2D:
-- a   b   t_x
-- c   d   t_y
-- 0   0   1

function matrixMultiply(a, b)
    return {
        a[1]*b[1] + a[2]*b[3], -- a*a'+b*c'
        a[1]*b[2] + a[2]*b[4], -- a*b'+b*d'
        a[3]*b[1] + a[4]*b[3], -- c*a'+d*c'
        a[3]*b[2] + a[4]*b[4], -- c*b'+d*d'
        a[1]*b[5] + a[2]*b[6] + a[5], -- a*t_x'+b*t_y'+t_x
        a[3]*b[5] + a[4]*b[6] + a[6], -- c*t_x'+d*t_y'+t_y
    }
end

-- vector can be homogeneous too, if #vector == 2 then vector[3] is assumed to be 0
-- so formally this should be matrixMultiplyPoint?
function matrixMultiplyVector(matrix, vector)
    local a = vector[3] or 1
    return {
        matrix[1]*vector[1] + matrix[2]*vector[2] + matrix[5]*a,
        matrix[3]*vector[2] + matrix[4]*vector[2] + matrix[6]*a,
    }
end

function transformMatrix(x, y, angle, scaleX, scaleY)
    local c, s = math.cos(angle), math.sin(angle)
    return {
        scaleX * c, scaleY * -s,
        scaleX * s, scaleY *  c,
        x, y
    }
end

function Skeleton:updateBone(bone)
    if bone.updateCounter < self.updateCounter then
        local wT = bone.worldTransform
        wT.matrix = matrixMultiply(bone.setupTransform.matrix,
                    transformMatrix(bone.positionX, bone.positionY, bone.angle, bone.scaleX, bone.scaleY))
        wT.matrix[5] = bone.setupTransform.matrix[5] + bone.positionX
        wT.matrix[6] = bone.setupTransform.matrix[6] + bone.positionY

        if bone.parent then
            self:updateBone(bone.parent)
            wT.matrix = matrixMultiply(bone.parent.worldTransform.matrix, wT.matrix)
        end
        bone.updateCounter = self.updateCounter
    end
end

function Skeleton:update()
    self.updateCounter = self.updateCounter + 1
    for boneIndex, bone in ipairs(self.bones) do
        self:updateBone(bone)
    end
end

return Skeleton