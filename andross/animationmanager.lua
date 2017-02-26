local class = require "andross.middleclass"
local Pose = require "andross.Pose"

local AnimationManager = class("AnimationManager")

-- later take a skin as an additional parameter for slot animations?
function AnimationManager:initialize(skeleton, animations)
    self.skeleton = skeleton
    self.skin = skin
    self.animationStates = {}
    self.layers = {{alpha = 1.0, animations = {}}}
    for _, anim in pairs(animations) do
        self.animationStates[anim.name] = {
            animation = anim,
            time = 0.0,
            speed = 1.0,
            playing = false,
            looping = true,
            callbacks = {},
            blendWeight = 0.0,
            layer = 1,
            weightSpeed = 0,
        }
        self.layers[1].animations[anim.name] = self.animationStates[anim.name]
    end
    -- self.layers might be sparse, so that iterating via ipairs or #self.layers
    -- might terminate early. So we have another list, which just stores a list of
    -- layer indices (sorted)
    self.layerList = {1}
end

-- This functionality should be improved. I have never used something like this before, so I
-- don't really know it's use cases and caveats, but I know there should probably be a way to
-- disable/remove callbacks afterwards
function AnimationManager:setCallback(name, time, callback)
    table.insert(self.animationStates[name].callbacks, {time = time, callback = callback})
end

function AnimationManager:setSpeed(name, speed)
    self.animationStates[name].speed = speed
end

function AnimationManager:setTime(name, time)
    self.animationStates[name].time = time
end

function AnimationManager:setLooping(name, looping)
    self.animationStates[name].looping = looping
end

function AnimationManager:setBlendWeight(name, blendWeight)
    self.animationStates[name].blendWeight = math.min(math.max(blendWeight, 0.0), 1.0)
end

function AnimationManager:play(name, startTime)
    self.animationStates[name].time = startTime or 0
    self.animationStates[name].playing = true
end

-- makes sure the weight of the animation <name> is increased to 1.0 in duration seconds
-- also decreases all other weights on the same layer to zero in the same amount of time
-- it's easy to show that the relative weight of all the decreasing weight animations
-- stays the same for the whole fade
-- obviously this is not the case for the animation faded in
function AnimationManager:fadeIn(name, duration)
    local layer = self.layers[self.animationStates[name].layer]
    for name, anim in pairs(layer.animations) do
        anim.weightSpeed = (0.0 - anim.blendWeight) / duration
    end
    local anim = self.animationStates[name]
    anim.weightSpeed = (1.0 - anim.blendWeight) / duration
    self:play(name)
end

function AnimationManager:getState(name)
    return self.animationStates[name]
end

function AnimationManager:rebuildLayerList()
    local layers = {}
    for name, animState in pairs(self.animationStates) do
        layers[animState.layer] = true
    end

    self.layerList = {}
    for layerId, layer in pairs(layers) do
        table.insert(self.layerList, layerId)
    end
    table.sort(self.layerList)
end

function AnimationManager:setLayer(name, layer)
    if self.layers[layer] == nil then
        self.layers[layer] = {alpha = 1.0, animations = {}}
    end

    local animState = self.animationStates[name]
    self.layers[animState.layer].animations[name] = nil
    animState.layer = layer
    self.layers[layer].animations[name] = animState
    self:rebuildLayerList()
end

function AnimationManager:setLayerAlpha(layer, alpha)
    if self.layers[layer] == nil then
        self.layers[layer] = {alpha = alpha, animations = {}}
    else
        self.layers[layer].alpha = alpha
    end
end


function AnimationManager:update(dt)
    local pose = nil

    local layerMixParams = {}
    for _, layerId in ipairs(self.layerList) do
        local layer = self.layers[layerId]

        local mixParams = {}
        for name, animState in pairs(layer.animations) do
            local anim = animState.animation
            if animState.playing then
                local oldTime = animState.time
                local time = oldTime + dt * animState.speed

                -- callbacks
                for _, cb in ipairs(animState.callbacks) do
                    if oldTime < cb.time and time > cb.time then
                        cb.callback(self, anim.name)
                    end
                end

                -- looping
                if time > anim.duration then
                    if animState.looping then
                        time = time % anim.duration
                    else
                        time = anim.duration
                        animState.playing = false
                    end
                end
                animState.time = time

                -- animate weights
                -- NOTE: you can not set a nonzero weight speed for a weight > 1 or < 0
                animState.blendWeight = animState.blendWeight + animState.weightSpeed * dt
                if animState.blendWeight > 1.0 or animState.blendWeight < 0.0 then
                    animState.blendWeight = math.max(0, math.min(1, animState.blendWeight))
                    animState.weightSpeed = 0.0
                end
            end

            local pose = anim:getPose(animState.time)
            table.insert(mixParams, pose)
            table.insert(mixParams, animState.blendWeight)
        end

        layer._pose = Pose.static:mix(unpack(mixParams))
        if pose == nil then
            pose = layer._pose
        else
            assert("Multiple layers not yet implemented!")
            pose = Pose.static:overlay(pose, layer._pose, layer.alpha)
        end
    end

    pose:apply(self.skeleton)
    self.skeleton:update()
end

return AnimationManager