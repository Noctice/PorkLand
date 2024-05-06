local modimport = modimport
GLOBAL.setfenv(1, GLOBAL)

-- Update this list when adding files
local behaviour_posts = {
    "wander",
}

local component_posts = {
    "actionqueuer",
    "ambientlighting",
    "blinkstaff",
    "clock",
    "colourcube",
    "combat",
    "drownable",
    "edible",
    "equippable_replica",
    "equippable",
    "floater",
    "grogginess",
    "health",
    "inventory",
    "inventoryitem_replica",
    "inventoryitem",
    "locomotor",
    "lootdropper",
    "moisture",
    "playeractionpicker",
    "playercontroller",
    "pollinator",
    "regrowthmanager",
    "repairable",
    "rider_replica",
    "seasons",
    "shard_clock",
    "shard_seasons",
    "sleeper",
    "waterproofer",
    "wavemanager",
    "worldstate",
}

local prefab_posts = {
    "buff_workeffectiveness",
    "orangestaff",
    "player",
    "player_classified",
    "torch",
    "woodie",
    "world_network",
    "shard_network",
    "wormwood",
}

local multipleprefab_posts = {
    "poisonable",
}

local scenario_posts = {
    "playerhud",
}

local stategraph_posts = {
    "wilson",
    "wilson_client",
}

local brain_posts = {
}

local widget_posts = {
    "containerwidget",
    "inventorybar",
    "seasonclock",
    "uianim",
    "uiclock",
    "widget",
}

local module_posts = {
    ["components/map"] = "map",
}

local _require = require
---@param module_name string
function require(module_name, ...)
    local no_loaded = package.loaded[module_name] == nil
    local ret = { _require(module_name, ...) }
    if module_posts[module_name] and no_loaded then -- only load when first
        modimport("postinit/modules/" .. module_posts[module_name])
    end
    return unpack(ret)
end

modimport("postinit/equipslotutil")
modimport("postinit/stategraph")
modimport("postinit/entityscript")
modimport("postinit/animstate")
modimport("postinit/stategraphs/commonstates")

for _, file_name in ipairs(behaviour_posts) do
    modimport("postinit/behaviours/" .. file_name)
end

for _, file_name in ipairs(component_posts) do
    modimport("postinit/components/" .. file_name)
end

for _, file_name in ipairs(prefab_posts) do
    modimport("postinit/prefabs/" .. file_name)
end

for _, file_name in ipairs(multipleprefab_posts) do
    modimport("postinit/multipleprefabs/" .. file_name)
end

for _, file_name in ipairs(scenario_posts) do
    modimport("postinit/scenarios/" .. file_name)
end

for _, file_name in ipairs(stategraph_posts) do
    modimport("postinit/stategraphs/SG" .. file_name)
end

for _, file_name in ipairs(brain_posts) do
    modimport("postinit/brains/" .. file_name)
end

for _, file_name in ipairs(widget_posts) do
    modimport("postinit/widgets/" .. file_name)
end
