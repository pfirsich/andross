local class = require "andross.middleclass"
local androssMath = require "andross.math"
local Pose = require "andross.Pose"

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
    -- I do this so that the last keyframe is chosen if time = duration, so that
    -- non-looping animations that reached the end don't wrap around
    if math.abs(self.duration - time) < 1e-5 then
        time = self.duration
    else
        time = time % self.duration
    end

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
                                            value = androssMath.lerpAngles(keyframe.value, nextKeyframe.value, alpha)
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