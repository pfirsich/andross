local class = require "andross.middleclass"

function normalizeAngle(a)
    while a >  math.pi do a = a - 2*math.pi end
    while a < -math.pi do a = a + 2*math.pi end
    return a
end

function blendAngles(a, b, mix)
    local delta = b - a
    while delta >  math.pi do delta = delta - 2*math.pi end
    while delta < -math.pi do delta = delta + 2*math.pi end
    return normalizeAngle(a + delta * mix)
end

local Pose = class("Pose")

function Pose:initialize()
    self.values = {}
end

function Pose:setPoseValue(type, name, key, value)
    if not self.values[type] then
        self.values[type] = {}
    end

    if not self.values[type][name] then
        self.values[type][name] = {}
    end

    self.values[type][name][key] = value
end

function Pose:getPoseValue(type, name, key)
    if not self.values[type] or not self.values[type][name] then
        return nil
    end
    return self.values[type][name][key]
end

function Pose:blend(otherPose, mix)
    local ret = Pose()
    for typeName, _type in pairs(self.values) do
        for objName, obj in pairs(_type) do
            for keyName, keyValue in pairs(obj) do
                local value = keyValue
                local otherValue = otherPose:getPoseValue(typeName, objName, keyName)
                if otherValue then
                    value = keyValue + (otherValue - keyValue) * mix
                end
                ret:setPoseValue(typeName, objName, keyName, value)
                -- TODO: otherPose-values that self does not have
            end
        end
    end
    return ret
end

function Pose:apply(skeleton)
    if self.values.bones then
        for boneName, bone in pairs(self.values.bones) do
            for keyName, keyValue in pairs(bone) do
                skeleton.bones[boneName][keyName] = keyValue
            end
        end
    end
end

local Animation = class("Animation")

function Animation:initialize(name, duration)
    self.name = name
    self.duration = duration
    self.keyframes = {}
end

-- You have to insert the keyframes in ascending time order! i.e. chronological!
function Animation:addKeyframe(time, keyframeType, name, keyName, value, curve)
    if not self.keyframes[keyframeType] then
        self.keyframes[keyframeType] = {}
    end

    if not self.keyframes[keyframeType][name] then
        self.keyframes[keyframeType][name] = {}
    end

    if not self.keyframes[keyframeType][name][keyName] then
        self.keyframes[keyframeType][name][keyName] = {}
    end

    table.insert(self.keyframes[keyframeType][name][keyName], {
        time = time,
        value = value,
        curve = curve,
    })
end

function Animation:getPose(time, keyframeType, name, keyName)
    local pose = Pose()
    for _keyframeTypeName, _keyframeType in pairs(self.keyframes) do
        if keyframeType == nil or _keyframeTypeName == keyframeType then
            for _name, keyframeField in pairs(_keyframeType) do
                if name == nil or _name == name then
                    for _keyName, key in pairs(keyframeField) do
                        if keyName == nil or _keyName == keyName then
                            if time <= key[1].time then -- before first keyframe
                                pose:setPoseValue(_keyframeTypeName, _name, _keyName, key[1].value)
                            elseif time >= key[#key].time then -- after last keyframe
                                pose:setPoseValue(_keyframeTypeName, _name, _keyName, key[#key].value)
                            else
                                -- TODO: binary search?
                                for keyframeIndex = 2, #key do
                                    -- the first keyframe is always at t = 0
                                    if time < key[keyframeIndex].time then
                                        local keyframe = key[keyframeIndex-1]
                                        local nextKeyframe = key[keyframeIndex]
                                        local alpha = (time - keyframe.time) / (nextKeyframe.time - keyframe.time)
                                        -- TODO: curves -> if keyframe.curve then alpha = keyframe.curve(alpha) end
                                        local value = keyframe.value + (nextKeyframe.value - keyframe.value) * alpha
                                        if _keyName == "angle" then
                                            value = blendAngles(keyframe.value, nextKeyframe.value, alpha)
                                        end
                                        pose:setPoseValue(_keyframeTypeName, _name, _keyName, value)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return pose
end

return Animation