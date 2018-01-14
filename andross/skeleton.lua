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
        bindTransform = androssMath.Transform(positionX, positionY, angle, scaleX, scaleY),
        -- the following two are only updated, when updateBone is called
        localTransform = androssMath.Transform(),
        worldTransform = androssMath.Transform(),
        positionX = 0,
        positionY = 0,
        angle = 0,
        scaleX = 1,
        scaleY = 1,
    }

    self.bones[#self.bones+1] = self.bones[name]
    self.updateCounter = 0
end

function Skeleton:copy()
    local ret = Skeleton()
    for i, bone in ipairs(self.bones) do
        ret:addBone(bone.name, bone.parent and bone.parent.name, bone.length, 0, 0, 0, 0, 0)
        ret.bones[i].worldTransform = bone.worldTransform:copy()
        ret.bones[i].bindTransform = bone.bindTransform:copy()
        for _, prop in ipairs({"positionX", "positionY", "angle", "scaleX", "scaleY"}) do
            ret.bones[i][prop] = bone[prop]
        end
    end
    ret:update()
    return ret
end

function Skeleton:updateBone(bone)
    if bone.updateCounter < self.updateCounter then
        local wT = bone.worldTransform
        bone.localTransform:set(bone.positionX, bone.positionY, bone.angle, bone.scaleX, bone.scaleY)
        bone.worldTransform:setProduct(bone.bindTransform, bone.localTransform)
        -- This is so weird. Bone setup pose translations are in world space?! Is this COAs or the format's fault?
        bone.worldTransform.matrix[5] = bone.bindTransform.matrix[5] + bone.positionX
        bone.worldTransform.matrix[6] = bone.bindTransform.matrix[6] + bone.positionY

        if bone.parent then
            self:updateBone(bone.parent)
            bone.worldTransform:setProduct(bone.parent.worldTransform, bone.worldTransform)
        end
        bone.updateCounter = self.updateCounter
    end
end

function Skeleton:reset()
    for boneIndex, bone in ipairs(self.bones) do
        bone.positionX = 0
        bone.positionY = 0
        bone.angle = 0
        bone.scaleX = 1
        bone.scaleY = 1
    end
end

function Skeleton:update()
    self.updateCounter = self.updateCounter + 1
    for boneIndex, bone in ipairs(self.bones) do
        self:updateBone(bone)
    end
end

return Skeleton