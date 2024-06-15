-- TODO:
-- 实现billboard
-- 移除Debug代码
-- prefab重命名（加前缀）

local assets =
{
    Asset("ANIM", "anim/interior_unique.zip"),
    Asset("ANIM", "anim/interior_sconce.zip"),
    Asset("ANIM", "anim/interior_defect.zip"),
    Asset("ANIM", "anim/interior_decor.zip"),
    Asset("ANIM", "anim/interior_pillar.zip"),
    Asset("ANIM", "anim/ceiling_lights.zip"),
    Asset("ANIM", "anim/containers.zip"),
    Asset("ANIM", "anim/interior_floor_decor.zip"),
    Asset("ANIM", "anim/interior_window.zip"),
    Asset("ANIM", "anim/interior_window_burlap.zip"),
    Asset("ANIM", "anim/interior_window_lightfx.zip"),
    Asset("ANIM", "anim/window_arcane_build.zip"),

    Asset("ANIM", "anim/interior_wall_decals.zip"),
    Asset("ANIM", "anim/interior_wall_decals_hoofspa.zip"),
    Asset("ANIM", "anim/interior_wall_mirror.zip"),
    Asset("ANIM", "anim/interior_chair.zip"),

    Asset("ANIM", "anim/interior_wall_decals_antcave.zip"),
    Asset("ANIM", "anim/interior_wall_decals_antiquities.zip"),
    Asset("ANIM", "anim/interior_wall_decals_arcane.zip"),
    Asset("ANIM", "anim/interior_wall_decals_batcave.zip"),
    Asset("ANIM", "anim/interior_wall_decals_deli.zip"),
    Asset("ANIM", "anim/interior_wall_decals_florist.zip"),
    Asset("ANIM", "anim/interior_wall_decals_mayorsoffice.zip"),
    Asset("ANIM", "anim/interior_wall_decals_palace.zip"),
    Asset("ANIM", "anim/interior_wall_decals_ruins.zip"),
    Asset("ANIM", "anim/interior_wall_decals_ruins_blue.zip"),
    Asset("ANIM", "anim/interior_wall_decals_accademia.zip"),
    Asset("ANIM", "anim/interior_wall_decals_millinery.zip"),
    Asset("ANIM", "anim/interior_wall_decals_weapons.zip"),

    Asset("ANIM", "anim/interior_wallornament.zip"),

    Asset("ANIM", "anim/window_mayorsoffice.zip"),
    Asset("ANIM", "anim/window_palace.zip"),
    Asset("ANIM", "anim/window_palace_stainglass.zip"),

    Asset("ANIM", "anim/interior_plant.zip"),
    Asset("ANIM", "anim/interior_table.zip"),
    Asset("ANIM", "anim/interior_floorlamp.zip"),

    Asset("ANIM", "anim/interior_window_small.zip"),
    Asset("ANIM", "anim/interior_window_large.zip"),
    Asset("ANIM", "anim/interior_window_tall.zip"),
    Asset("ANIM", "anim/interior_window_greenhouse.zip"),
    Asset("ANIM", "anim/interior_window_greenhouse_build.zip"),

    Asset("ANIM", "anim/window_weapons_build.zip"),

    Asset("ANIM", "anim/pig_ruins_well.zip"),
    Asset("ANIM", "anim/ceiling_decor.zip"),
    Asset("ANIM", "anim/light_dust_fx.zip"),
}

local prefabs =
{
    "swinglightobject",
    "deco_roomglow",
    "deco_wood_cornerbeam_placer",
}

local function smash(inst)
    if inst.components.lootdropper then
        local interior_spawner = TheWorld.components.interiorspawner
        if interior_spawner.current_interior then
            local originpt = interior_spawner:getSpawnOrigin()
            local x, y, z = inst.Transform:GetWorldPosition()
            local dropdir = Vector3(originpt.x - x, 0.0, originpt.z - z):GetNormalized()
            inst.components.lootdropper.dropdir = dropdir
            inst.components.lootdropper:DropLoot()
        end
    end
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    end

    inst:Remove()
end

local function SetPlayerUncraftable(inst)
    inst.entity:AddSoundEmitter()

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnWorkCallback(function(inst, worker, workleft)
        if workleft <= 0 then
            smash(inst)
        end
    end)
    inst:RemoveTag("NOCLICK")
end

local function OnBuilt(inst)
    SetPlayerUncraftable(inst)
    inst.onbuilt = true

    if inst:HasTag("cornerpost") then
        local pt = inst:GetPosition()
        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 1, {"cornerpost"})
        for i,ent in ipairs(ents) do
            if ent ~= inst then
                smash(ent)
            end
        end
    end

    if inst:HasTag("centerlight") then
        local pt = inst:GetPosition()
        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 1, {"centerlight"})
        for i,ent in ipairs(ents) do
            if ent ~= inst then
               smash(ent)
            end
        end
    end

    if inst:HasTag("wallsection") then
        local pt = inst:GetPosition()
        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 1, {"wallsection"})
        for i,ent in ipairs(ents) do
            if ent ~= inst and not (ent:HasTag("interior_door") and not ent.doorcanberemoved) then
               smash(ent)
            end
        end
    end
end

local function UpdateArtWorkable(inst, instant)
    local workleft = inst.components.workable.workleft
    local animlevel = workleft/TUNING.DECO_RUINS_BEAM_WORK
    if animlevel <= 0 then
        if not instant then
            inst.AnimState:PlayAnimation("pillar_front_crumble")
            inst.AnimState:PushAnimation("pillar_front_crumble_idle")
        else
            inst.AnimState:PlayAnimation("pillar_front_crumble_idle")
        end
    elseif animlevel < 1/3 then
        inst.AnimState:PlayAnimation("pillar_front_break_2")
    elseif animlevel < 2/3 then
        inst.AnimState:PlayAnimation("pillar_front_break_1")
    end
    if workleft <= 0 then
        inst.components.workable:SetWorkable(false)
    end
end

local function OnSave(inst, data)
    local references = {}
    data.rotation = inst.Transform:GetRotation()
    local pt = Vector3(inst.Transform:GetScale())
    data.scalex = pt.x
    data.scaley = pt.y
    data.scalez = pt.z

    if inst.sunraysspawned then
        data.sunraysspawned = inst.sunraysspawned
    end

    if inst.childrenspawned then
        data.childrenspawned = inst.childrenspawned
    end

    --if inst.flipped then
        --data.flipped = inst.flipped
    --end    
    if inst.setbackground then
        data.setbackground = inst.setbackground
    end
    if inst:HasTag("dartthrower") then
        data.dartthrower = true
    end
    if inst:HasTag("dartthrower_right") then
        data.dartthrower_right = true
    end
    if inst:HasTag("dartthrower_left") then
        data.dartthrower_left = true
    end
    if inst:HasTag("playercrafted") then
        data.playercrafted = true
    end

    data.children = {}
    if inst.decochildrenToRemove then
        for i, child in ipairs(inst.decochildrenToRemove) do
            table.insert(data.children, child.GUID)
            table.insert(references, child.GUID)
        end
    end

    if inst.dust then
        data.dust = inst.dust.GUID
        table.insert(references, data.dust)
    end

    if inst.swinglight then
        data.swinglight = inst.swinglight.GUID
        table.insert(references, data.swinglight)
    end

    if inst.animdata then
        data.animdata = inst.animdata
    end

    if inst.onbuilt then
        data.onbuilt = inst.onbuilt
    end
    if inst.recipeproxy then
        data.recipeproxy = inst.recipeproxy
    end

    if inst:HasTag("roc_cave_delete_me")then
        data.roc_cave_delete_me = true
    end

    return references
end

local function OnLoad(inst, data)
    if data.rotation then
        if inst.components.rotatingbillboard == nil or true --[[skip this 2024/6/13]] then
            -- this component handle rotation save/load itself
            inst.Transform:SetRotation(data.rotation)
        end
    end
    if data.scalex  then
        inst.Transform:SetScale( data.scalex, data.scaley, data.scalez)
    end
    if data.sunraysspawned then
        inst.sunraysspawned = data.sunraysspawned
    end
    if data.childrenspawned then
        inst.childrenspawned = data.childrenspawned
    end
    --if data.flipped then
    --    inst.flipped = data.flipped        
    --end       
    if data.dartthrower then
       inst:AddTag("dartthrower")
    end
    if data.dartthrower_right then
        inst:AddTag("dartthrower_right")
    end
    if  data.dartthrower_left then
        inst:AddTag("dartthrower_left")
    end
    if data.playercrafted then
        inst:AddTag("playercrafted")
    end
    if data.setbackground then
        inst.AnimState:SetLayer( LAYER_WORLD_BACKGROUND )
        inst.AnimState:SetSortOrder(data.setbackground)
        inst.setbackground = data.setbackground
    end
    if data.animdata then
        inst.animdata = data.animdata
        if inst.animdata.build then
            inst.AnimState:SetBuild(inst.animdata.build)
        end
        if inst.animdata.bank then
            inst.AnimState:SetBank(inst.animdata.bank)
        end
        if inst.animdata.anim then
            inst.AnimState:PlayAnimation(inst.animdata.anim,inst.animdata.animloop)
        end
    end

    if data.onbuilt then
        SetPlayerUncraftable(inst)
        inst.onbuilt = data.onbuilt
    end

    if data.recipeproxy then
        inst.recipeproxy = data.recipeproxy
    end

    if data.roc_cave_delete_me then
        inst:AddTag("roc_cave_delete_me")
    end

end

local function OnLoadPostPass(inst,ents, data)
    if data then
        if data.swinglight then
            local swinglight = ents[data.swinglight]
            if swinglight then
                inst.swinglight = swinglight.entity
            end
        end
        if data.dust then
            local dust = ents[data.dust]
            if dust then
                inst.dust = dust.entity
            end
        end

        inst.decochildrenToRemove = {}
        if data.children then
            for i,child in ipairs(data.children) do
                local childent = ents[child]
                if childent then
                    table.insert(inst.decochildrenToRemove, childent.entity)
                end
            end
        end
    end
    if inst.updateworkableart then
        UpdateArtWorkable(inst,true)
    end
end

local function OnRemove(inst)
    if inst.decochildrenToRemove then
        for _,child in ipairs(inst.decochildrenToRemove) do
            child:Remove()
        end
    end

    if inst.swinglight then
        inst.swinglight:Remove()
    end
    if inst.dust then
        inst.dust:Remove()
    end
end

local function turnoff(inst, light)
    if light then
        light:Enable(false)
    end
end

local function timechange(inst)
    if TheWorld.state.isday then
        inst.AnimState:PlayAnimation("to_day")
        inst.AnimState:PushAnimation("day_loop", true)
    elseif TheWorld.state.isnight then
       inst.AnimState:PlayAnimation("to_night")
        inst.AnimState:PushAnimation("night_loop", true)
    elseif TheWorld.state.isdusk then
        inst.AnimState:PlayAnimation("to_dusk")
        inst.AnimState:PushAnimation("dusk_loop", true)
    end
end

local function mirror_blink_idle(inst)
    if inst.isneer then
        inst.AnimState:PlayAnimation("shadow_blink")
        inst.AnimState:PushAnimation("shadow_idle", true)
    end
    inst.blink_task = inst:DoTaskInTime(10 + math.random() * 50, mirror_blink_idle)
end

local function mirror_OnNear(inst)
    inst.AnimState:PlayAnimation("shadow_in")
    inst.AnimState:PushAnimation("shadow_idle", true)

    inst.blink_task = inst:DoTaskInTime(10 + math.random() * 50, mirror_OnNear)
    inst.isneer = true
end

local function mirror_OnFar(inst)
    if inst.isneer then
        inst.AnimState:PlayAnimation("shadow_out")
        inst.AnimState:PushAnimation("idle", true)
        inst.isneer = nil
        inst.blink_task:Cancel()
        inst.blink_task = nil
    end
end

local function swapColor(inst, light)
    if inst.iswhite then
        inst.iswhite = false
        inst.isred = true
        inst.components.lighttweener:StartTween(light, Lerp(0, 3, 1), nil, nil, {240/255, 100/255, 100/255}, 0.2, swapColor)
    elseif inst.isred then
        inst.isred = false
        inst.isgreen = true
        inst.components.lighttweener:StartTween(light, Lerp(0, 3, 1), nil, nil, {240/255, 230/255, 100/255}, 0.2, swapColor)
    else
        inst.isgreen = false
        inst.iswhite =true
        inst.components.lighttweener:StartTween(light, Lerp(0, 3, 1), nil, nil, {100/255, 240/255, 100/255}, 0.2, swapColor)
    end
end

local function MakeDeco(build, bank, animframe, data, name)
    if not data then
        data = {}
    end

    local loopanim = data.loopanim
    local decal = data.decal
    local background = data.background
    local light = data.light
    local followlight = data.followlight
    local scale = data.scale
    local mirror = data.mirror
    local physics = data.physics
    local windowlight = data.windowlight
    local workable = data.workable
    local prefabname = data.prefabname
    local minimapicon = data.minimapicon
    local tags = data.tags or {}
    local name_override = data.recipeproxy or data.name_override

    local function fn(Sim)
        local inst = CreateEntity()
        local trans = inst.entity:AddTransform()
        local anim = inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        anim:SetBuild(build)
        anim:SetBank(bank)
        anim:PlayAnimation(animframe, loopanim)

        inst.Transform:SetRotation(-90)

        for i, tag in ipairs(tags) do
            inst:AddTag(tag)
        end

        if data.children then
            inst:DoTaskInTime(0,function()
                -- don't spawn child in client
                if TheWorld.ismastersim and not inst.childrenspawned then
                    for i, child in ipairs(data.children) do
                        local childprop = SpawnPrefab(child)
                        local pt = Vector3(inst.Transform:GetWorldPosition())
                        print(childprop.prefab,pt.x,pt.y,pt.z)
                        childprop.Transform:SetPosition(pt.x ,pt.y, pt.z)
                        childprop.Transform:SetRotation(inst.Transform:GetRotation())
                        if not inst.decochildrenToRemove then
                            inst.decochildrenToRemove = {}
                        end
                        table.insert(inst.decochildrenToRemove,childprop)
                    end
                    inst.childrenspawned = true
                end
           end)
        end

        if minimapicon then
            local minimap = inst.entity:AddMiniMapEntity()
            minimap:SetIcon(minimapicon)
        end

        if background then
            inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
            inst.AnimState:SetSortOrder(background)
            inst.setbackground = background
        end

        if name == "deco_palace_beam_room_tall_corner" then
            -- fix layer
            inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
        end

        if TheWorld.ismastersim then
            if STRINGS.NAMES[string.upper(name)] then
                inst:AddComponent("inspectable")
            end

            if name_override then
                if not inst.components.inspectable then
                    inst:AddComponent("inspectable")
                end
                -- this way the backwall windows will show the right prefab name (with controller)
                inst.name = STRINGS.NAMES[name_override:upper()]
                inst.components.inspectable.nameoverride = name_override
            end
        end

        if physics then
            if physics == "sofa_physics" then
                MakeInteriorPhysics(inst, 1.3, 1, 0.2)
            elseif physics == "sofa_physics_vert" then
                MakeInteriorPhysics(inst, 0.2, 1, 1.3)
            elseif physics == "chair_physics_small" then
                MakeObstaclePhysics(inst, .5)
            elseif physics == "chair_physics" then
                MakeInteriorPhysics(inst, 1, 1, 1)
            elseif physics == "desk_physics" then
                MakeInteriorPhysics(inst, 2, 1, 1)
            elseif physics == "tree_physics" then
                inst:AddTag("blocker")
                inst.entity:AddPhysics()
                inst.Physics:SetMass(0)
                inst.Physics:SetCylinder(4.7, 4.0)
                inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
                inst.Physics:ClearCollisionMask()
                inst.Physics:CollidesWith(COLLISION.ITEMS)
                inst.Physics:CollidesWith(COLLISION.CHARACTERS)
                -- inst.Physics:CollidesWith(COLLISION.INTWALL)
            elseif physics == "pond_physics" then
                inst:AddTag("blocker")
                inst.entity:AddPhysics()
                inst.Physics:SetMass(0)
                inst.Physics:SetCylinder(1.6, 4.0)
                inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
                inst.Physics:ClearCollisionMask()
                inst.Physics:CollidesWith(COLLISION.ITEMS)
                inst.Physics:CollidesWith(COLLISION.CHARACTERS)
                -- inst.Physics:CollidesWith(COLLISION.INTWALL)
            elseif physics == "big_post_physics" then
                MakeObstaclePhysics(inst, 0.75)
            elseif physics == "post_physics" then
                MakeObstaclePhysics(inst, .25)
            end
        end

        if scale then
            anim:SetScale(scale.x, scale.y, scale.z)
        end

        if decal then
            -- NOTE: only apply billborad render behavior on beam/pillar 
            if name:find("_cornerbeam")
                or name:find("_beam")
                or name:find("_pillar")
                or data.rotatingbillboard then
                -- skip this 2024/6/13
                -- inst:AddComponent("pl_rotatingbillboard")

                -- inst.components.pl_rotatingbillboard.animdata = {
                --     bank = bank,
                --     build = build,
                --     animation = animframe,
                -- }
            else
                inst.Transform:SetTwoFaced()
            end
        else
            inst.Transform:SetTwoFaced()
        end

        if loopanim then
            anim:SetTime(math.random() * anim:GetCurrentAnimationLength())
        end

        if not data.curtains then
            anim:Hide("curtain")
        end

        if data.bloom then
            inst.AnimState:SetBloomEffectHandle( "shaders/anim.ksh" )
        end

        if light then
            if followlight then
                inst:DoTaskInTime(0, function()
                    if not TheWorld.ismastersim then
                        return
                    end
                    -- if inst.sunraysspawned then
                    --     return
                    -- end
                    -- inst.sunraysspawned = true

                    inst.swinglight = SpawnPrefab("swinglightobject")
                    inst.swinglight.setLightType(inst.swinglight, followlight)
                    inst.swinglight.persists = false
                    if windowlight then
                        inst.swinglight.setListenEvents(inst.swinglight)
                    end
                    -- NOTE: set arbitrary light position here
                    if inst.components.pl_rotatingbillboard ~= nil then
                        local offset = TUNING.PL_MANUAL_LIGHT_OFFSET[name:upper()] or TUNING.PL_MANUAL_LIGHT_OFFSET.DEFAULT
                        inst.swinglight.entity:SetParent(inst.entity)
                        inst.swinglight.offset = Vector3(0.01, offset[1], offset[2])
                        inst.components.pl_rotatingbillboard:UpdateLightPosition()
                    else
                        inst.swinglight.entity:SetParent(inst.entity)
                        local follower = inst.swinglight.Follower
                        follower:FollowSymbol( inst.GUID, "light_circle", 0, 0, 0 )
                        inst.swinglight.followobject = {GUID=inst.GUID, symbol="light_circle", x=0, y=0, z=0}
                    end
                end)
            else
                inst.entity:AddLight()
                inst.Light:SetIntensity(light.intensity)
                inst.Light:SetColour(light.color[1], light.color[2], light.color[3])
                inst.Light:SetFalloff(light.falloff)
                inst.Light:SetRadius(light.radius)
                inst.Light:Enable(true)
                inst:AddComponent("fader")
            end

            if data.blink then
                inst:AddComponent("lighttweener")
                swapColor(inst, inst.Light)
            end
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.LoadPostPass = OnLoadPostPass

        if data.dayevents then
            inst:WatchWorldState("isday", timechange)
            inst:WatchWorldState("isdusk", timechange)
            inst:WatchWorldState("isnight", timechange)
            timechange(inst)
        end

        if mirror then
            inst:AddComponent("playerprox")
            inst.components.playerprox:SetOnPlayerNear(mirror_OnNear)
            inst.components.playerprox:SetOnPlayerFar(mirror_OnFar)
            inst.components.playerprox:SetDist(2, 2.1)
        end

        if workable then

            if not inst.components.inspectable then
                inst:AddComponent("inspectable")
            end

            inst.entity:AddSoundEmitter()

            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.MINE)
            inst.components.workable:SetWorkLeft(TUNING.DECO_RUINS_BEAM_WORK)
            inst.components.workable:SetMaxWork(TUNING.DECO_RUINS_BEAM_WORK)
            inst.components.workable.savestate = true
            inst.components.workable:SetOnWorkCallback(
                function(inst, worker, workleft)
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")

                    UpdateArtWorkable(inst)

                    if GetWorld().components.quaker_interior then
                        if workleft <= 0 then
                            GetWorld().components.quaker_interior:ForceQuake("cavein")
                            print("QUAKE: CAVE IN!!!")
                        else
                           GetWorld().components.quaker_interior:ForceQuake("pillarshake")
                           print("QUAKE: pillar!!!")
                        end
                    end
                end)
            inst.updateworkableart = true
        end

        if prefabname then
            if not inst.components.inspectable then
                inst:AddComponent("inspectable")
            end

            inst:SetPrefabName(prefabname)
        end

        if prefabname == "pig_latin_1" then
            inst:AddTag("pig_writing_1")
            GetWorld():ListenForEvent("doorused", function(world, data)
                    if not inst:HasTag("INTERIOR_LIMBO") then
                        inst:DoTaskInTime(1,
                            function()
                                local pt = Vector3(inst.Transform:GetWorldPosition())
                                local torches = TheSim:FindEntities(pt.x, pt.y, pt.z, 50, {"wall_torch"}, {"INTERIOR_LIMBO"})
                                local closedoors = false
                                for i,torch in ipairs(torches)do
                                    if not torch.components.cooker then
                                        closedoors = true
                                    end
                                end

                                if closedoors then
                                    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 50, {"lockable_door"}, {"INTERIOR_LIMBO"})
                                    for i, ent in ipairs(ents)do
                                        if ent ~= data.door then
                                            ent:PushEvent("close")
                                        end
                                    end
                                end
                            end)
                    end
                end, GetWorld())


            inst:ListenForEvent("fire_lit", function()
                    local opendoors = true
                    local pt = Vector3(inst.Transform:GetWorldPosition())
                    local torches = TheSim:FindEntities(pt.x, pt.y, pt.z, 50, {"wall_torch"}, {"INTERIOR_LIMBO"})

                    for i,torch in ipairs(torches)do
                        if not torch.components.cooker then
                            opendoors = false
                        end
                    end

                    if opendoors then
                        local pt = Vector3(inst.Transform:GetWorldPosition())
                        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 50, nil, {"INTERIOR_LIMBO"})
                        for i, ent in ipairs(ents)do
                            if ent:HasTag("lockable_door") then
                                ent:PushEvent("open")
                            end
                        end
                    end
                end)
        end


        inst:ListenForEvent("onremove", function()
                OnRemove(inst)
            end)

        inst:DoTaskInTime(0,function()
                if inst:HasTag("playercrafted") then
                    SetPlayerUncraftable(inst)
                end
            end)

        if data.onbuilt then
            inst:ListenForEvent( "onbuilt", function()
                OnBuilt(inst)
            end)
        end

        if data.adjustanim then
            if false then
                anim:PlayAnimation(animframe .. "_front")
            else
                anim:PlayAnimation(animframe .. "_side")
            end
        end

        if data.recipeproxy then
            inst.recipeproxy = data.recipeproxy
        end

        return inst
    end
    return fn
end


local LIGHTS =
{
    SUNBEAM =
    {
        day  = {radius = 3, intensity = 0.75, falloff = 0.5, color = {1, 1, 1}},
        dusk = {radius = 2, intensity = 0.75, falloff = 0.5, color = {1/1.8, 1/1.8, 1/1.8}},
        full = {radius = 2, intensity = 0.75, falloff = 0.5, color = {0.8/1.8, 0.8/1.8, 1/1.8}}
    },

    SUNBEAM =
    {
        intensity = 0.9,
        color     = {197/255, 197/255, 50/255},
        falloff   = 0.5,
        radius    = 2,
    },

    SMALL =
    {
        intensity = 0.75,
        color     = {97/255, 197/255, 50/255},
        falloff   = 0.7,
        radius    = 1,
    },

    MED =
    {
        intensity = 0.9,
        color     = {197/255, 197/255, 50/255},
        falloff   = 0.5,
        radius    = 3,
    },

    SMALL_YELLOW =
    {
        intensity = 0.75,
        color     = {197/255, 197/255, 50/255},
        falloff   = 0.7,
        radius    = 1,
    },
    FESTIVETREE =
    {
        intensity = 0.9,
        color     = {197/255, 197/255, 50/255},
        falloff   = 0.5,
        radius    = 3,
    },

}

local DecoCreator = Class(function(self)

end)

local prefab_names = {}

function DecoCreator:Create(name, build, bank, anim, data)
    assert(name, "Prefab name is nil")
    prefab_names[name] = true
    return Prefab("deco/"..name, MakeDeco(build, bank, anim, data, name), assets, prefabs)
end

function DecoCreator:GetLights()
    return LIGHTS
end

return DecoCreator
