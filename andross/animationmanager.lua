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

function AnimationManager:getBlendWeight(name)
    return self.animationStates[name].blendWeight
end

function AnimationManager:play(name, weight, startTime)
    self.animationStates[name].time = startTime or 0
    self.animationStates[name].blendWeight = weight or 1
    self.animationStates[name].playing = true
end

function AnimationManager:isPlaying(name)
    return self.animationStates[name].playing
end

function AnimationManager:isFinished(name)
    return not self.animationStates[name].playing and self.animationStates[name].time >= self.animationStates[name].animation.duration
end

-- makes sure the weight of the animation <name> is increased to 1.0 in duration seconds
-- also decreases all other weights on the same layer to zero in the same amount of time
-- it's easy to show that the relative weight of all the decreasing weight animations
-- stays the same for the whole fade
-- obviously this is not the case for the animation faded in
function AnimationManager:fadeInEx(name, duration) -- Ex = "exclusive"
    local layer = self.layers[self.animationStates[name].layer]
    for otherName, anim in pairs(layer.animations) do
        self:fadeOut(otherName, duration)
    end
    self:fadeIn(name, duration)
    self:play(name, self.animationStates[name].blendWeight)
end

function AnimationManager:fade(name, duration, targetWeight)
    local anim = self.animationStates[name]
    anim.weightSpeed = (targetWeight - anim.blendWeight) / duration
    anim.targetWeight = targetWeight
end

function AnimationManager:fadeIn(name, duration)
    self:fade(name, duration, 1.0)
end

function AnimationManager:fadeOut(name, duration)
    self:fade(name, duration, 0.0)
end

-- These things only exist if you want to manage animations as a group
-- then you can just fade your group in and multiply it with your sub-weights
-- also you can fade in something else and the group get's faded out.
-- This is essentially just a mock animation that has a weight than can be animated and
-- will be animated by fadeInEx (if called for other animations)
-- see examples/highlevelapi.lua to see how it can be used
function AnimationManager:addAnimationGroup(name)
    self.animationStates[name] = {
        animation = nil,
        blendWeight = 0.0,
        layer = 1,
        weightSpeed = 0,
    }
    self.layers[1].animations[name] = self.animationStates[name]
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
            if animState.playing and anim then
                local oldTime = animState.time
                local time = oldTime + dt * animState.speed

                -- callbacks
                for _, cb in ipairs(animState.callbacks) do
                    if oldTime < cb.time and time >= cb.time then
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
            end

            -- animate weights
            -- NOTE: you can not set a nonzero weight speed for a weight > 1 or < 0
            if math.abs(animState.weightSpeed) > 0 then
                local preDiff = animState.blendWeight - animState.targetWeight
                animState.blendWeight = animState.blendWeight + animState.weightSpeed * dt
                animState.blendWeight = math.max(0, math.min(1, animState.blendWeight))

                local postDiff = animState.blendWeight - animState.targetWeight
                if preDiff * postDiff <= 0 then
                    animState.blendWeight = animState.targetWeight
                    animState.weightSpeed = 0
                end
            end

            if animState.blendWeight > 0 and anim then
                local pose = anim:getPose(animState.time)
                table.insert(mixParams, pose)
                table.insert(mixParams, animState.blendWeight)
                --print(anim.name, animState.blendWeight)
            end
        end

        layer._pose = Pose.static:mix(unpack(mixParams))
        if pose == nil then
            pose = layer._pose
        else
            assert("Multiple layers not yet implemented!")
            pose = Pose.static:overlay(pose, layer._pose, layer.alpha)
        end
    end

    self.skeleton:reset()
    pose:apply(self.skeleton)
    self.skeleton:update()
end

return AnimationManager