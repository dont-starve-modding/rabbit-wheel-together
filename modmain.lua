PrefabFiles = {
    "rabbitwheel",
}

Assets = {
	Asset("IMAGE", "images/inventoryimages/rabbitwheel.tex"),
	Asset("ATLAS", "images/inventoryimages/rabbitwheel.xml"),
}

STRINGS = GLOBAL.STRINGS

function TableMerge(t1, t2)
    for k,v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k] or false) == "table" then
                TableMerge(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
    return t1
end

NEWSTRINGS = GLOBAL.require("rabbitwheelstrings")
GLOBAL.STRINGS = TableMerge(GLOBAL.STRINGS, NEWSTRINGS)

-- rabbitwheel Recipe

TUNING.RABBITWHEEL_COST_SEWING_TAPE = 2
TUNING.RABBITWHEEL_COST_BOARDS = 3
TUNING.RABBITWHEEL_COST_TRANSISTOR = 1

TUNING.RABBIT_MAX_HEALTH = TUNING.RABBIT_HEALTH
TUNING.RABBIT_STARVE_KILL_TIME = TUNING.TOTAL_DAY_TIME * 2
TUNING.RABBIT_MAX_HUNGER = 20 -- how many joule can a rabbit store?
TUNING.RABBIT_JOULE_PER_DAY = 50 -- how many joule are burned in a single day?
TUNING.RABBIT_CARROT_JOULE = 10 -- how many joule gives a carrot?
TUNING.RABBIT_CARROT_HEAL_PERCENT = 100
TUNING.RABBIT_CARROT_POISON_PERCENT = 4 -- how much max health does a rabbit lose on carrot feeding?
TUNING.RABBIT_SEGMENTS_PER_JOULE = 0.8 -- how many segments lasts a battery with 1 Joule burned by the rabbit?
TUNING.RABBITWHEEL_CAPACITY_IN_SEGMENTS = 6 -- how many segments lasts a full battery?

-- configuration

if (GetModConfigData("rabbit_lifetime") == "low") then
    TUNING.RABBIT_CARROT_POISON_PERCENT = 2
end
if (GetModConfigData("rabbit_lifetime") == "high") then
    TUNING.RABBIT_CARROT_POISON_PERCENT = 6
end

if (GetModConfigData("rabbit_perseverance") == "low") then
    TUNING.RABBIT_MAX_HUNGER = 15
    TUNING.RABBIT_CARROT_JOULE = 5
end
if (GetModConfigData("rabbit_perseverance") == "high") then
    TUNING.RABBIT_MAX_HUNGER = 40
    TUNING.RABBIT_CARROT_JOULE = 20
end

if (GetModConfigData("rabbit_power") == "low") then
    TUNING.RABBIT_JOULE_PER_DAY = 25
end
if (GetModConfigData("rabbit_power") == "high") then
    TUNING.RABBIT_JOULE_PER_DAY = 100
end

if (GetModConfigData("rabbit_wheel_costs") == "low") then
    TUNING.RABBITWHEEL_COST_SEWING_TAPE = 1
    TUNING.RABBITWHEEL_COST_BOARDS = 2
    TUNING.RABBITWHEEL_COST_TRANSISTOR = 1
end
if (GetModConfigData("rabbit_wheel_costs") == "high") then
    TUNING.RABBITWHEEL_COST_SEWING_TAPE = 3
    TUNING.RABBITWHEEL_COST_BOARDS = 6
    TUNING.RABBITWHEEL_COST_TRANSISTOR = 2
end

-- derived parameters

TUNING.RABBITWHEEL_FULL_BATTERY_DURATION = TUNING.SEG_TIME * TUNING.RABBITWHEEL_CAPACITY_IN_SEGMENTS
-- how much time is added to a battery when 1 Joule is burned by the rabbit?
TUNING.RABBIT_JOULE_CONVERSION_RATE = 
    TUNING.SEG_TIME * TUNING.RABBIT_SEGMENTS_PER_JOULE

local recipe = AddRecipe("rabbitwheel",
    {
        Ingredient("sewing_tape", TUNING.RABBITWHEEL_COST_SEWING_TAPE),
        Ingredient("boards", TUNING.RABBITWHEEL_COST_BOARDS),
        Ingredient("transistor", TUNING.RABBITWHEEL_COST_TRANSISTOR)
    }, 
    -- {
    --     GLOBAL.Ingredient("rocks", TUNING.RABBITWHEEL_COST_ROCKS),
    -- }, 
    GLOBAL.CUSTOM_RECIPETABS.ENGINEERING, 
    GLOBAL.TECH.NONE, 
    "rabbitwheel_placer", 
    TUNING.WINONA_ENGINEERING_SPACING, 
    nil, nil, 
    "handyperson"
)


recipe.atlas = "images/inventoryimages/rabbitwheel.xml"

-- carrot fuel

GLOBAL.FUELTYPE.CARROT = "CARROT"

local oldstrfn = GLOBAL.ACTIONS.GIVE.strfn

GLOBAL.ACTIONS.GIVE.strfn = function(act)
    return oldstrfn(act) 
    or (act.target ~= nil
        and ( -- if there is no rabbit, print "Place"
            act.target:HasTag("rabbitwheel") 
            and not act.target:HasTag("hasrabbit")
            and "NOTREADY")
    )
    or nil -- nil for "Give"
end


-- GLOBAL.FUELTYPE.RABBIT = "RABBIT"

-- GLOBAL.ACTIONS.IMPRISON = GLOBAL.Action({ priority=1, mount_valid=true })

-- GLOBAL.ACTIONS.IMPRISON.fn  = function(act)
--     if act.target.components.rabbitcage and act.doer.components.inventory then
--         local rabbit = act.doer.components.inventory:RemoveItem(act.invobject)
--         if rabbit and not act.target.components.rabbitcage:HasRabbit() then
--             if act.target.components.rabbitcage:TakeRabbit(rabbit, act.doer) then
--                 return true
--             else 
--                 act.doer.components.inventory:GiveItem(rabbit)
--                 return false
--             end
--         else
--             -- return false, "INUSE"
--             return false
--         end
--     end
-- end

-- AddComponentAction("SCENE", "rabbitcage", function(inst, doer, actions, right)
--     if not inst:HasTag("burnt") and
--         print("rabbitcage: " .. tostring(inst.components.rabbitcage ~= nil))
--         not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding()) then
--         if inst.components.rabbitcage and not inst.components.rabbitcage:HasRabbit() then
--             table.insert(actions, GLOBAL.ACTIONS.IMPRISON)
--         end
--     end
-- end)

-- winona structure compatibility

-- add rabbitwheel as RecipeFilter to deployhelper (catapult)
AddPrefabPostInit("winona_catapult", function(inst)
    -- correct check would be not TheNet:IsDedicated() which is not available, I guess
    if inst.components.deployhelper ~= nil then
        inst.components.deployhelper:AddRecipeFilter("rabbitwheel")
    end

    -- local oldonenablehelper = inst.components.deployhelper.onenablehelper

    -- inst.components.deployhelper.onenablehelper = function(inst, enabled, recipename, placerinst)
    --     oldonenablehelper(inst, enabled, recipename, placerinst)

    --     if enabled then
    --         if inst.helper == nil and inst:HasTag("HAMMER_workable") and not inst:HasTag("burnt") then
    --             if recipename == "winona_catapult" then
    --                 -- do nothing - handled in old function
    --             else
    --                 inst.helper = CreatePlacerBatteryRing()
    --                 inst.helper.entity:SetParent(inst.entity)
    --                 if placerinst ~= nil and recipename == "rabbitwheel" then
    --                     inst.helper:AddComponent("updatelooper")
    --                     inst.helper.components.updatelooper:AddOnUpdateFn(OnUpdatePlacerHelper)
    --                     inst.helper.placerinst = placerinst
    --                     OnUpdatePlacerHelper(inst.helper)
    --                 end
    --             end
    --         end
    --     elseif inst.helper ~= nil then
    --         inst.helper:Remove()
    --         inst.helper = nil
    --     end
    -- end
end)

-- add rabbitwheel as RecipeFilter to deployhelper (spotlight)
AddPrefabPostInit("winona_spotlight", function(inst)
    -- correct check would be not TheNet:IsDedicated() which is not available, I guess
    if inst.components.deployhelper ~= nil then
        inst.components.deployhelper:AddRecipeFilter("rabbitwheel")
    end
end)
