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


