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

TUNING.RABBITWHEEL_COST_ROCKS = 1
TUNING.RABBITWHEEL_COST_POOP = 0
TUNING.RABBITWHEEL_COST_LOG = 0

if (GetModConfigData("poop_amount") == "low") then
    TUNING.RABBITWHEEL_COST_ROCKS = 2
    TUNING.RABBITWHEEL_COST_POOP = 1
    TUNING.RABBITWHEEL_COST_LOG = 2
end
if (GetModConfigData("poop_amount") == "high") then
    TUNING.RABBITWHEEL_COST_ROCKS = 10
    TUNING.RABBITWHEEL_COST_POOP = 5
    TUNING.RABBITWHEEL_COST_LOG = 8
end

local recipe = AddRecipe("rabbitwheel",
    -- {
    --     Ingredient("sewing_tape", 1), 
    --     Ingredient("log", 2), 
    --     Ingredient("nitre", 2)
    -- }, 
    {
        GLOBAL.Ingredient("rocks", TUNING.RABBITWHEEL_COST_ROCKS),
    }, 
    GLOBAL.CUSTOM_RECIPETABS.ENGINEERING, 
    GLOBAL.TECH.NONE, 
    "rabbitwheel_placer", 
    TUNING.WINONA_ENGINEERING_SPACING, 
    nil, nil, 
    "handyperson")


recipe.atlas = "images/inventoryimages/rabbitwheel.xml"

-- carrot fuel

GLOBAL.FUELTYPE.CARROT = "CARROT"

local oldstrfn = GLOBAL.ACTIONS.GIVE.strfn

GLOBAL.ACTIONS.GIVE.strfn = function(act)
    return oldstrfn(act) 
    or (act.target ~= nil
        and (
            act.target:HasTag("rabbitwheel") 
            and not act.target.components.rabbitcage:HasRabbit() 
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
