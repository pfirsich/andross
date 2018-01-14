local andross = require "andross"
local json = require "andross.json"

local dragonBones = {}

function dragonBones.import(str, attachmentManager)
    local transforms = {
        "x", "y", "skX", "scX", "scY"
    }
    local transformNameMap = {
        x = "positionX",
        y = "positionY",
        skX = "angle",
        scX = "scaleX",
        scY = "scaleY",
    }

    local jsonTable = json.decode(str)
    local frameRate = jsonTable.frameRate
    local jsonArmature = jsonTable.armature[1]

    -- Skeleton
    local skel = andross.Skeleton()
    for boneIndex, bone in ipairs(jsonArmature.bone) do
        local angle = bone.transform.skX
        if angle then angle = angle * math.pi / 180.0 end
        skel:addBone(bone.name, bone.parent, bone.length,
                     bone.transform.x, bone.transform.y, angle,
                     bone.transform.scX, bone.transform.scY)
    end
    skel:update()

    -- Animation
    local anims = {}
    for animationIndex, animation in ipairs(jsonArmature.animation) do
        local anim = andross.Animation(animation.name, animation.duration / frameRate)
        for boneIndex, bone in ipairs(animation.bone) do
            local t = 0
            for frameIndex, frame in ipairs(bone.frame) do
                for _, name in ipairs(transforms) do
                    if frame.transform[name] then
                        local value = frame.transform[name]
                        if name == "skX" then value = value * math.pi / 180.0 end
                        anim:addKeyframe(t / frameRate, "bones", bone.name, transformNameMap[name], value)
                    end
                end
                t = t + frame.duration
            end
        end
        anims[animation.name] = anim
    end

    -- Skin
    local skin
    if attachmentManager then
        skin = andross.Skin(jsonArmature.skin[1].name)
        for attachmentIndex, attachment in ipairs(jsonArmature.skin[1].slot) do
            local data = attachment.display[1]
            if data.type == "mesh" then
                local indices = {}

                local vertices = {}
                assert(#data.vertices == #data.uvs)
                for i = 1, #data.vertices, 2 do
                    table.insert(vertices, {data.vertices[i], data.vertices[i+1], data.uvs[i], data.uvs[i+1]})
                end

                -- TODO: DragonBones sometimes does not export weights - this case should be handled
                local weights = {}
                if data.weights == nil then
                    weights = nil
                else
                    local i = 1
                    while i <= #data.weights do
                        local count = data.weights[i]
                        i = i + 1
                        local vertexWeights = {}
                        for c = 1, count do
                            -- +1 because of 1-indexing
                            table.insert(vertexWeights, data.weights[i+0] + 1) -- boneIndex
                            table.insert(vertexWeights, data.weights[i+1]) -- weight
                            i = i + 2
                        end
                        table.insert(weights, vertexWeights)
                    end
                end

                local indices = data.triangles
                -- COA, why do you do this?
                if #indices == 4 and indices[1] == 0 and indices[2] == 1 and
                                     indices[3] == 2 and indices[4] == 3 then
                    indices = {0, 1, 2, 0, 2, 3}
                end
                -- 1-indexing
                for i = 1, #indices do
                    indices[i] = indices[i] + 1
                end

                local attachment = attachmentManager:getMeshAttachment(attachment.name, vertices, weights, indices)
                local parentBone = jsonArmature.slot[attachmentIndex].parent
                if attachment.static then
                    parentBone = attachment.realParent
                end
                skin:addAttachment(parentBone, attachment)

                -- data.transform stores world position bind pose transforms
                -- COA parents every slot to the Armature itself, not to the bone it's attached to.
                -- So the attachment's transformation are in world space and we have to convert to the bone's space
                local angle = (data.transform.skX or 0) * math.pi/180.0
                local localTransform = andross.math.Transform(data.transform.x, data.transform.y,
                                                              angle, data.transform.scX, data.transform.scY)
                -- first transform to world space by applying the transform of the parent set in the file
                local worldTransform = skel.bones[jsonArmature.slot[attachmentIndex].parent].worldTransform:compose(localTransform)
                -- then transform into the space of the parent that we decided on
                attachment.bindTransform = skel.bones[parentBone].worldTransform:inverse():compose(worldTransform)
                --attachment.positionX, attachment.positionY, attachment.angle, attachment.scaleX, attachment.scaleY = finalTransform:decomposeTRS()
            end

            if data.type == "image" then
                local attachment = attachmentManager:getImageAttachment(attachment.name)
                skin:addAttachment(jsonArmature.slot[attachmentIndex].parent, attachment)
                for _, name in ipairs(transforms) do
                    if data.transform[name] then
                        local value = data.transform[name]
                        if name == "skX" then value = value * math.pi / 180.0 end
                        attachment[transformNameMap[name]] = data.transform[name]
                    end
                end
            end
        end
    end

    return skel, anims, skin
end

function dragonBones.importAtlasData(str)
    return json.decode(str).SubTexture
end

return dragonBones