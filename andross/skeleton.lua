local class = require "andross.middleclass"
local androssMath = require "andross.math"

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
    setupTrafo.matrix = androssMath.transformMatrix(setupTrafo.positionX, setupTrafo.positionY,
                                        setupTrafo.angle, setupTrafo.scaleX, setupTrafo.scaleY)

    self.bones[#self.bones+1] = self.bones[name]
    self.updateCounter = 0
end

function Skeleton:updateBone(bone)
    if bone.updateCounter < self.updateCounter then
        local wT = bone.worldTransform
        wT.matrix = androssMath.matrixMultiply(bone.setupTransform.matrix,
                    androssMath.transformMatrix(bone.positionX, bone.positionY, bone.angle, bone.scaleX, bone.scaleY))
        wT.matrix[5] = bone.setupTransform.matrix[5] + bone.positionX
        wT.matrix[6] = bone.setupTransform.matrix[6] + bone.positionY

        if bone.parent then
            self:updateBone(bone.parent)
            wT.matrix = androssMath.matrixMultiply(bone.parent.worldTransform.matrix, wT.matrix)
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