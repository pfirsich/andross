local class = require "andross.middleclass"
local androssMath = require "andross.math"

local Pose = class("Pose")

function Pose:initialize()
    self.values = {}
end

function Pose:setPoseValue(type, name, channel, value)
    if not self.values[type] then
        self.values[type] = {}
    end

    if not self.values[type][name] then
        self.values[type][name] = {}
    end

    self.values[type][name][channel] = value
end

function Pose:getPoseValue(type, name, channel)
    if not self.values[type] or not self.values[type][name] then
        return nil
    end
    return self.values[type][name][channel]
end

-- TODO: implement this fully
function Pose:blend(otherPose, mix)
    local ret = Pose()
    for typeName, _type in pairs(self.values) do
        for objName, obj in pairs(_type) do
            for channelName, channelValue in pairs(obj) do
                local value = channelValue
                local otherValue = otherPose:getPoseValue(typeName, objName, channelName)
                if otherValue then
                    value = channelValue + (otherValue - channelValue) * mix
                end
                ret:setPoseValue(typeName, objName, channelName, value)
                -- TODO: otherPose-values that self does not have
                -- TODO: blend angles properly
            end
        end
    end
    return ret
end

function Pose:apply(skeleton)
    if self.values.bones then
        for boneName, bone in pairs(self.values.bones) do
            for channelName, channelValue in pairs(bone) do
                skeleton.bones[boneName][channelName] = channelValue
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
function Animation:addKeyframe(time, keyframeType, name, channel, value, curve)
    if not self.keyframes[keyframeType] then
        self.keyframes[keyframeType] = {}
    end

    if not self.keyframes[keyframeType][name] then
        self.keyframes[keyframeType][name] = {}
    end

    if not self.keyframes[keyframeType][name][channel] then
        self.keyframes[keyframeType][name][channel] = {}
    end

    table.insert(self.keyframes[keyframeType][name][channel], {
        time = time,
        value = value,
        curve = curve,
    })
end

function Animation:getPose(time, keyframeType, name, channel)
    time = time % self.duration

    local pose = Pose()
    for _keyframeTypeName, _keyframeType in pairs(self.keyframes) do
        if keyframeType == nil or _keyframeTypeName == keyframeType then
            for _name, _keyframeField in pairs(_keyframeType) do
                if name == nil or _name == name then
                    for _channelName, _channel in pairs(_keyframeField) do
                        if channelName == nil or _channelName == channel then
                            if time <= _channel[1].time then -- before first keyframe
                                pose:setPoseValue(_keyframeTypeName, _name, _channelName, _channel[1].value)
                            elseif time >= _channel[#_channel].time then -- after last keyframe
                                pose:setPoseValue(_keyframeTypeName, _name, _channelName, _channel[#_channel].value)
                            else
                                -- TODO: binary search?
                                -- the first keyframe is always at t = 0, see notes
                                for keyframeIndex = 2, #_channel do
                                    if time < _channel[keyframeIndex].time then
                                        local keyframe = _channel[keyframeIndex-1]
                                        local nextKeyframe = _channel[keyframeIndex]
                                        local alpha = (time - keyframe.time) / (nextKeyframe.time - keyframe.time)
                                        -- TODO: curves -> if keyframe.curve then alpha = keyframe.curve(alpha) end
                                        local value = keyframe.value + (nextKeyframe.value - keyframe.value) * alpha
                                        if _channelName == "angle" then -- I really don't like this if
                                            value = andross.math.lerpAngles(keyframe.value, nextKeyframe.value, alpha)
                                        end
                                        pose:setPoseValue(_keyframeTypeName, _name, _channelName, value)
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