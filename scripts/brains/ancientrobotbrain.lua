require("behaviours/wander")
require("behaviours/faceentity")
require("behaviours/chaseandattack")
require("behaviours/doaction")

local START_FACE_DIST = 4
local KEEP_FACE_DIST = 6
local MAX_CHASE_TIME = 15
local MAX_BEAM_ATTACK_RANGE = 9
local MAX_JUMP_ATTACK_RANGE = 9
local MERGE_SCAN = 10
local ASSEMBLE_DIST = 15

local function Deactivate(inst)
    if not inst:HasTag("dormant") then
        inst.components.combat.target = nil
        inst:PushEvent("deactivate")
    end
end

local function GetFaceTargetFn(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local target = FindClosestPlayerInRange(x, y, z, START_FACE_DIST, true)
    if target and not target:HasTag("notarget") then
        return target
    end
end

local function KeepFaceTargetFn(inst, target)
    return inst:GetDistanceSqToInst(target) <= KEEP_FACE_DIST * KEEP_FACE_DIST and not target:HasTag("notarget")
end

local function ShouldBeamAttack(inst)
    if inst.components.combat.target and not inst.components.timer:TimerExists("laserbeam_cd") and inst:HasTag("beam_attack") then
        local target = inst.components.combat.target
        local distsq = inst:GetDistanceSqToInst(target)
        return distsq < MAX_BEAM_ATTACK_RANGE * MAX_BEAM_ATTACK_RANGE
    end
    return false
end

local function DoBeamAttack(inst)
    if inst.components.combat.target then
        inst:PushEvent("dobeamattack", {target = inst.components.combat.target})
    end
end

local function ShouldJumpAttack(inst)
    if not inst:HasTag("jump_attack") then
        return false
    end

    if inst.sg:HasStateTag("leapattack") then
        return true
    end

    local target = inst.components.combat.target
    if target and target:IsValid() then
        return inst:GetDistanceSqToInst(target) < MAX_JUMP_ATTACK_RANGE * MAX_JUMP_ATTACK_RANGE
    else
        inst.components.combat.target = nil
    end

    return false
end

local function DoJumpAttack(inst)
    if inst.components.combat.target and not inst.sg:HasStateTag("leapattack") then
        local target = inst.components.combat.target
        local x, y, z = target.Transform:GetWorldPosition()

        if TheWorld.Map:IsVisualGroundAtPoint(x, y, z) then
            inst:PushEvent("doleapattack", {target = target})
            inst:FacePoint(x, y, z)
        end
    end
end

local function ShouldAssemble(inst)
    -- if inst.sg:HasStateTag("busy") then
    --     return false
    -- end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, ASSEMBLE_DIST, {'ancient_robot'})
    local mergetarget = nil
    local dist = 9999
    local hulk = nil
    for _, ent in ipairs(ents)do
        -- a valid merge target is when there is only one active bot. And a hulk should have priority
        if ent ~= inst then
            if ent:HasTag("ancient_robots_assembly") or (ent:HasTag("dormant") and not hulk) then
                if ent:HasTag("ancient_robots_assembly") then
                    if not hulk then
                        mergetarget = nil
                        dist = 9999
                    end
                    hulk = true
                end
                local testdist = inst:GetDistanceSqToInst(ent)
                if ent:HasTag("ancient_robots_assembly") or testdist < MERGE_SCAN*MERGE_SCAN then
                    if testdist < dist then
                        mergetarget = ent
                        dist = testdist
                    end
                end
            end
            if not ent:HasTag("ancient_robots_assembly") and not ent:HasTag("dormant") then
                -- abort the merge
                inst.mergetarget = nil
                return false
            end
        end
    end

    inst.mergetarget = mergetarget
    if inst.mergetarget then
        return true
    end
end

local function DoAssemble(inst)
    --local range = inst:GetPhysicsRadius() + inst.mergetarget:GetPhysicsRadius() + 0.1
    return BufferedAction(inst, inst.mergetarget, ACTIONS.ASSEMBLE_ROBOT)--, nil, nil, nil, range)
end

local AncientRobotBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function AncientRobotBrain:OnStart()
    local root = PriorityNode(
    {
        IfNode(function() return self.inst.wantstodeactivate or self.inst:HasTag("dormant") end, "Should deactivate",
            DoAction(self.inst, function() return Deactivate(self.inst) end, "Deactivate", true)),

        WhileNode(function() return not self.inst:HasTag("dormant") end, "Is activated",
            PriorityNode(
            {
                --DoAction(self.inst, function() return DoAssemble(self.inst) end, "Assemble", true),
                WhileNode(function() return ShouldAssemble(self.inst) end, "Should assemble",
                    DoAction(self.inst, function() return DoAssemble(self.inst) end, "Assemble", true)),

                WhileNode(function() return self.inst.mergetarget == nil end, "Not assemble",
                    PriorityNode({
                        WhileNode(function() return ShouldBeamAttack(self.inst) end, "Should beak attack",
                            DoAction(self.inst, function() return DoBeamAttack(self.inst) end, "Beam attack", true)),

                        WhileNode(function() return ShouldJumpAttack(self.inst) end, "Should jump attack",
                            DoAction(self.inst, function() return DoJumpAttack(self.inst) end, "Jump attack", true)),

                        ChaseAndAttack(self.inst, MAX_CHASE_TIME),

                        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),

                        Wander(self.inst)
                    })
                ),
            }, 0.25)
        )
    }, 0.25)

    self.bt = BT(self.inst, root)

end

return AncientRobotBrain

--[[
require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/follow"
require "behaviours/attackwall"
--require "behaviours/runaway"
--require "behaviours/doaction"



local START_FACE_DIST = 4
local KEEP_FACE_DIST = 6
local MAX_CHASE_TIME = 15
local MAX_BEAM_ATTACK_RANGE = 9
local MAX_JUMP_ATTACK_RANGE = 9


local function GetFaceTargetFn(inst)
    local target = GetClosestInstWithTag("player", inst, START_FACE_DIST)
    if target and not target:HasTag("notarget") then
        return target
    end
end

local function KeepFaceTargetFn(inst, target)
    return inst:GetDistanceSqToInst(target) <= KEEP_FACE_DIST*KEEP_FACE_DIST and not target:HasTag("notarget")
end


local function shouldbeamattack(inst)

    if inst.components.combat.target and not inst.components.timer:TimerExists("laserbeam_cd") and inst:HasTag("beam_attack") then
        local target = inst.components.combat.target
        local distsq = inst:GetDistanceSqToInst(target)
        if distsq < MAX_BEAM_ATTACK_RANGE * MAX_BEAM_ATTACK_RANGE then
            return true
        end
    end
    return false
end

local function dobeamattack(inst)
    if inst.components.combat.target then
        local target = inst.components.combat.target
        inst:PushEvent("dobeamattack",{target=inst.components.combat.target})
    end
end

local function deactivate(inst)
    if not inst:HasTag("dormant") then
        inst.components.combat.target = nil
        inst:PushEvent("deactivate")
    end
end

local MERGE_SCAN = 10
local MERGE_HULK = 15

local function shouldmerge(inst)

    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, MERGE_HULK, {'ancient_robot'})
    local mergetarget = nil
    local dist = 9999
    local hulk = nil
    for i, ent in ipairs(ents)do
        -- a valid merge target is when there is only one active bot. And a hulk should have priority
        if ent ~= inst then
            if ent:HasTag("ancient_robots_assembly") or (ent:HasTag("dormant") and not hulk) then
                if ent:HasTag("ancient_robots_assembly") then
                    if not hulk then
                        mergetarget = nil
                        dist = 9999
                    end
                    hulk = true
                end
                local testdist = inst:GetDistanceSqToInst(ent)
                if ent:HasTag("ancient_robots_assembly") or testdist < MERGE_SCAN*MERGE_SCAN then
                    if testdist < dist then
                        mergetarget = ent
                        dist = testdist
                    end
                end
            end
            if not ent:HasTag("ancient_robots_assembly") and not ent:HasTag("dormant") then
                -- abort the merge
                inst.mergetarget = nil
                return false
            end
        end
    end

    inst.mergetarget = mergetarget
    if inst.mergetarget then
        return true
    end
end

local function domerge(inst)
    local range = inst.collisionradius + inst.mergetarget.collisionradius + 0.1
    return BufferedAction(inst, inst.mergetarget, ACTIONS.SPECIAL_ACTION, nil,nil, nil, range)
end

local AncientRobotBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function shouldjumpattack(inst)
    if not inst:HasTag("jump_attack") then
        return false
    end
    if  inst.sg:HasStateTag("leapattack") then
        return true
    end

    if inst.components.combat.target then
        local target = inst.components.combat.target
        if target then
            if target:IsValid() then
                local combatrange = inst.components.combat:CalcAttackRangeSq(target)
                local distsq = inst:GetDistanceSqToInst(target)
                if distsq < MAX_JUMP_ATTACK_RANGE * MAX_JUMP_ATTACK_RANGE then
                    return true
                end
            else
                inst.components.combat.target = nil
            end
        end
    end
    return false
end

local function dojumpAttack(inst)
    if inst.components.combat.target and not inst.sg:HasStateTag("leapattack") then
        local target = inst.components.combat.target
        local pos = target:GetPosition()

        if not target:GetIsOnWater(pos:Get()) then
            inst:PushEvent("doleapattack", {target=target})

            inst:FacePoint(pos:Get())
        end
    end
end

function AncientRobotBrain:OnStart()
    local root = PriorityNode(
    {
        IfNode( function() return self.inst.wantstodeactivate or self.inst:HasTag("dormant") end, "deactivate test",
            DoAction(self.inst, function() return deactivate(self.inst) end, "deactivate", true)),
        WhileNode(function() return not self.inst:HasTag("dormant") end, "activate",
            PriorityNode({
                WhileNode( function() return shouldmerge(self.inst) end, "merge",
                    DoAction(self.inst, function() return domerge(self.inst) end, "merge", true)),

                WhileNode( function() return shouldbeamattack(self.inst) end, "beamattack",
                    DoAction(self.inst, function() return dobeamattack(self.inst) end, "beam", true)
                    ),
                WhileNode( function() return shouldjumpattack(self.inst) end, "jumpattack",
                    DoAction(self.inst, function() return dojumpAttack(self.inst) end, "jump", true)
                    ),
                ChaseAndAttack(self.inst, MAX_CHASE_TIME),
                FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
                Wander(self.inst)
            }, 0.25)
        )

    }, 0.25)

    self.bt = BT(self.inst, root)

end

return AncientRobotBrain
]]