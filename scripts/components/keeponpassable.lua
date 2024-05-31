local function OnUpdate(inst)
    if inst:IsInLimbo() or inst.components.inventoryitem or inst.components.drownable or (not inst.components.health or inst.components.health:IsDead()) then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()

    if TheWorld.Map:ReverseIsVisualWaterAtPoint(x, y, z) and not inst:CanOnWater() then
        inst.components.health:Kill()
        return
    end

    if not inst:CanOnLand() and TheWorld.Map:ReverseIsVisualGroundAtPoint(x, y, z) then
        inst.components.health:Kill()
        return
    end

    if not inst:CanOnImpassable() and not TheWorld.Map:IsPassableAtPoint(x, y, z) then
        inst.components.health:Kill()
        return
    end
end

local KeepOnPassable = Class(function(self, inst)
    self.inst = inst
    self.period = 0.5

    self:Schedule()
end)

function KeepOnPassable:Schedule(new_period)
    if new_period ~= nil then
        self.period = new_period
    end

    self:Stop()
    self.task = self.inst:DoPeriodicTask(self.period, OnUpdate, math.random() * self.period)
end

function KeepOnPassable:Stop()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end

function KeepOnPassable:ForceUpdate()
    OnUpdate(self.inst)
end

function KeepOnPassable:OnEntitySleep()
    self:Stop()
    self:ForceUpdate()
end

function KeepOnPassable:OnEntityWake()
    self:ForceUpdate()
    self:Schedule()
end

KeepOnPassable.OnRemoveEntity = KeepOnPassable.Stop
KeepOnPassable.OnRemoveFromEntity = KeepOnPassable.Stop

return KeepOnPassable
