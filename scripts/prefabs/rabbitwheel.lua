require("prefabutil")

local assets =
{
    Asset("ANIM", "anim/rabbitwheel.zip"),
    Asset("ANIM", "anim/winona_battery_placement.zip"),

    Asset("SOUND", "sound/rabbit.fsb"),
}

local prefabs =
{
    "collapse_small",
}

--------------------------------------------------------------------------

local PERIOD = .5

local function DoAddBatteryPower(inst, node)
    print("DoAddBatteryPower")
    node:AddBatteryPower(PERIOD + math.random(2, 6) * FRAMES)
end

local function OnBatteryTask(inst)
    print("OnBatteryTask")
    inst.components.circuitnode:ForEachNode(DoAddBatteryPower)
end

local function StartBattery(inst)
    print("StartBattery")
    if inst._batterytask == nil then
        inst._batterytask = inst:DoPeriodicTask(PERIOD, OnBatteryTask, 0)
    end
end

local function StopBattery(inst)
    print("StopBattery")
    if inst._batterytask ~= nil then
        inst._batterytask:Cancel()
        inst._batterytask = nil
    end
end

local function UpdateCircuitPower(inst)
    print("UpdateCircuitPower")
    inst._circuittask = nil
    if inst.components.fueled ~= nil then
        if inst.components.fueled.consuming then
            local load = 0
            inst.components.circuitnode:ForEachNode(function(inst, node)
                local batteries = 0
                node.components.circuitnode:ForEachNode(function(node, battery)
                    if battery.components.fueled ~= nil and battery.components.fueled.consuming then
                        batteries = batteries + 1
                    end
                end)
                load = load + 1 / batteries
            end)
            inst.components.fueled.rate = math.max(load, TUNING.WINONA_BATTERY_MIN_LOAD)
        else
            inst.components.fueled.rate = 0
        end
    end
end

local function OnCircuitChanged(inst)
    print("OnCircuitChanged")
    if inst._circuittask == nil then
        inst._circuittask = inst:DoTaskInTime(0, UpdateCircuitPower)
    end
end

local function NotifyCircuitChanged(inst, node)
    print("NotifyCircuitChanged")
    node:PushEvent("engineeringcircuitchanged")
end

local function BroadcastCircuitChanged(inst)
    print("BroadcastCircuitChanged")
    --Notify other connected nodes, so that they can notify their connected batteries
    inst.components.circuitnode:ForEachNode(NotifyCircuitChanged)
    if inst._circuittask ~= nil then
        inst._circuittask:Cancel()
    end
    UpdateCircuitPower(inst)
end

local function OnConnectCircuit(inst)--, node)
    print("OnConnectCircuit")
    if inst.components.fueled ~= nil and inst.components.fueled.consuming then
        StartBattery(inst)
    end
    OnCircuitChanged(inst)
end

local function OnDisconnectCircuit(inst)--, node)
    print("OnDisconnectCircuit")
    if not inst.components.circuitnode:IsConnected() then
        StopBattery(inst)
    end
    OnCircuitChanged(inst)
end

--------------------------------------------------------------------------

local NUM_LEVELS = 6

local function UpdateSoundLoop(inst, level)
    print("UpdateSoundLoop")
    if inst.SoundEmitter:PlayingSound("loop") then
        inst.SoundEmitter:SetParameter("loop", "intensity", 1 - level / NUM_LEVELS)
    end
end

local function StartSoundLoop(inst)
    print("StartSoundLoop")
    if not inst.SoundEmitter:PlayingSound("loop") then
        inst.SoundEmitter:PlaySound("dontstarve/common/together/battery/on_LP", "loop")
        UpdateSoundLoop(inst, inst.components.fueled:GetCurrentSection())
    end
end

local function StopSoundLoop(inst)
    print("StopSoundLoop")
    inst.SoundEmitter:KillSound("loop")
end

local function OnEntityWake(inst)
    print("OnEntityWake")
    if inst.components.fueled ~= nil and inst.components.fueled.consuming then
        StartSoundLoop(inst)
    end
end

--------------------------------------------------------------------------

local function OnHitAnimOver(inst)
    print("OnHitAnimOver")
    inst:RemoveEventCallback("animover", OnHitAnimOver)
    if inst.AnimState:IsCurrentAnimation("hit") then
        if inst.components.fueled:IsEmpty() then
            inst.AnimState:PlayAnimation("idle_empty", true)
        else
            inst.AnimState:PlayAnimation("idle_charge", true)
        end
    end
end

local function PlayHitAnim(inst)
    print("PlayHitAnim")
    -- inst:RemoveEventCallback("animover", OnHitAnimOver)
    -- inst:ListenForEvent("animover", OnHitAnimOver)
    -- inst.AnimState:PlayAnimation("hit")
end

local function OnWorked(inst)
    print("OnWorked")
    -- if inst.components.fueled.accepting then
    --     PlayHitAnim(inst)
    -- end
    if inst.components.rabbitcage:HasRabbit() then
        inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream_short")
    end
end

local function OnWorkFinished(inst)
    print("OnWorkFinished")
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function OnBurnt(inst)
    print("OnBurnt")
    DefaultBurntStructureFn(inst)
    StopSoundLoop(inst)
    if inst.components.fueled ~= nil then
        inst:RemoveComponent("fueled")
    end
    inst.components.workable:SetOnWorkCallback(nil)
    inst:RemoveTag("NOCLICK")
    if inst._inittask ~= nil then
        inst._inittask:Cancel()
        inst._inittask = nil
    end
    inst.components.circuitnode:Disconnect()
end

--------------------------------------------------------------------------

local function GetStatus(inst)
    print("GetStatus")
    if inst:HasTag("burnt") then
        return "BURNT"
    elseif inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        return "BURNING"
    end
    local level = inst.components.fueled ~= nil and inst.components.fueled:GetCurrentSection() or nil
    local hasrabbit = inst.components.rabbitcage ~= nil and inst.components.rabbitcage:HasRabbit() or nil
    local isStarving = inst.components.hunger:IsStarving()

    if(hasrabbit == nil or hasrabbit == false) then
        return "DESERTED"
    end

    if(level == 0) then
        return "OFF"
    end

    if(level == 1) then
        return "LOWPOWER"
    end

    if(isStarving) then
        return "IDLE"
    end

    return "CHARGING"
end

-- local function OnAddFuel(inst)
--     print("OnAddFuel")
--     if inst.components.fueled.accepting and not inst.components.fueled:IsEmpty() then
--         if not inst.components.fueled.consuming then
--             inst.components.fueled:StartConsuming()
--             BroadcastCircuitChanged(inst)
--             if inst.components.circuitnode:IsConnected() then
--                 StartBattery(inst)
--             end
--             if not inst:IsAsleep() then
--                 StartSoundLoop(inst)
--             end
--         end
--         PlayHitAnim(inst)
--         inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream_short")
--     end
-- end


local function OnInit(inst)
    print("OnInit")
    inst._inittask = nil
    inst.components.circuitnode:ConnectTo("engineering")
end

local PLACER_SCALE = 1.5

local function OnUpdatePlacerHelper(helperinst)
    print("OnUpdatePlacerHelper")
    if not helperinst.placerinst:IsValid() then
        helperinst.components.updatelooper:RemoveOnUpdateFn(OnUpdatePlacerHelper)
        helperinst.AnimState:SetAddColour(0, 0, 0, 0)
    elseif helperinst:IsNear(helperinst.placerinst, TUNING.WINONA_BATTERY_RANGE) then
        helperinst.AnimState:SetAddColour(helperinst.placerinst.AnimState:GetAddColour())
    else
        helperinst.AnimState:SetAddColour(0, 0, 0, 0)
    end
end

local function OnEnableHelper(inst, enabled, recipename, placerinst)
    print("OnEnableHelper")
    if enabled then
        if inst.helper == nil and inst:HasTag("HAMMER_workable") and not inst:HasTag("burnt") then
            inst.helper = CreateEntity()

            --[[Non-networked entity]]
            inst.helper.entity:SetCanSleep(false)
            inst.helper.persists = false

            inst.helper.entity:AddTransform()
            inst.helper.entity:AddAnimState()

            inst.helper:AddTag("CLASSIFIED")
            inst.helper:AddTag("NOCLICK")
            inst.helper:AddTag("placer")

            inst.helper.AnimState:SetBank("winona_battery_placement")
            inst.helper.AnimState:SetBuild("winona_battery_placement")
            inst.helper.AnimState:PlayAnimation("idle")
            inst.helper.AnimState:SetLightOverride(1)
            inst.helper.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
            inst.helper.AnimState:SetLayer(LAYER_BACKGROUND)
            inst.helper.AnimState:SetSortOrder(1)
            inst.helper.AnimState:SetScale(PLACER_SCALE, PLACER_SCALE)

            inst.helper.entity:SetParent(inst.entity)

            if placerinst ~= nil 
                    and recipename ~= "rabbitwheel" 
                    and recipename ~= "winona_battery_low" 
                    and recipename ~= "winona_battery_high" then
                inst.helper:AddComponent("updatelooper")
                inst.helper.components.updatelooper:AddOnUpdateFn(OnUpdatePlacerHelper)
                inst.helper.placerinst = placerinst
                OnUpdatePlacerHelper(inst.helper)
            end
        end
    elseif inst.helper ~= nil then
        inst.helper:Remove()
        inst.helper = nil
    end
end

local function UpdateAnimation(inst, section)
    local val = "m"..tostring(section)
    print("val ".. tostring(val))

    -- inst.AnimState:OverrideSymbol("status", "rabbitwheel", val)
    inst.AnimState:OverrideSymbol("m1", "rabbitwheel", val)
    -- inst.AnimState:OverrideSymbol("m2", "rabbitwheel", val)
    -- inst.AnimState:OverrideSymbol("a", "rabbitwheel", val)
end

local function OnFuelEmpty(inst)
    print("OnFuelEmpty")

    inst.components.fueled:StopConsuming()
    BroadcastCircuitChanged(inst)
    StopBattery(inst)
    StopSoundLoop(inst)

    UpdateAnimation(inst, 1)

    -- inst.AnimState:OverrideSymbol("plug", "rabbitwheel", "plug_off")

    if not POPULATING and inst.components.rabbitcage and inst.components.rabbitcage:HasRabbit() then
        inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream")
    end
end


-- specific rabbitwheel stuff -------------

-- 1. empty rabbitwheel is a rabbitcage
-- 2. if a rabbit is put, it becomes a healthy/hunger instance
-- 3. the rabbit accepts carrots to satisfy the hunger
-- 4. the rabbit in the rabbitcage dies over time
-- 5. the rabbit may starve
-- 6. the rabbit produces energy based on hunger

local function OnRabbitHealthDelta(inst, oldpercent, newpercent)
    print("OnRabbitHealthDelta", newpercent)
    if newpercent <= 0.05 then
        OnRemoveRabbit(inst)
    end
end

local function ShouldAcceptCarrot(inst, item)
    print("ShouldAcceptCarrot")
    return item.prefab == "carrot"
end

local function ShouldAcceptRabbit(inst, item)
    print("ShouldAcceptRabbit")
    return item.prefab == "rabbit"
end


local function OnRabbitHunger(inst, data)
    print("OnRabbitHunger " .. tostring(data.delta) .. ": " .. tostring(data.newpercent) .. "%")
    -- data = { oldpercent, newpercent, overtime, delta }
    if data.delta == 0 then
        return
    end 

    -- TODO tweak based on current hunger
    local factor = TUNING.RABBIT_JOULE_CONVERSION_RATE
    if data.delta ~= nil and data.delta < 0 
            and math.abs(data.delta) < 10 then -- there are strange high numbers coming in
        local fueldelta = -1 * factor * data.delta
        inst.components.fueled:DoDelta(fueldelta) -- transform burned food into energy
        
        print("DELTA ".. tostring(data.delta) .. " * -" .. tostring(factor) .. " = " .. tostring(fueldelta))
        print("SECTION " .. tostring(inst.components.fueled:GetCurrentSection()))
        print("PERCENT " .. tostring(inst.components.fueled:GetPercent()))
        if not inst.AnimState:IsCurrentAnimation("idle_charge") then
            inst.AnimState:PlayAnimation("idle_charge", true)
        end
    
        if not inst.components.fueled.consuming then
            inst.components.fueled:StartConsuming()
            BroadcastCircuitChanged(inst)
            if inst.components.circuitnode:IsConnected() then
                StartBattery(inst)
            end
    
            -- if not inst:IsAsleep() then
            --     StartSoundLoop(inst)
            -- end
        end
    end

    if data.newpercent == 0 then
        if not inst.AnimState:IsCurrentAnimation("idle_empty") then
            print("switching to idle_empty")
            inst.AnimState:PlayAnimation("idle_empty", true)
            if inst.components.rabbitcage 
                    and inst.components.rabbitcage:HasRabbit() then
                inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream_short")
            end
        end
    end
end


function OnPutRabbit(inst, rabbit)
    print("OnPutRabbit")
    if not POPULATING and inst.components.rabbitcage and inst.components.rabbitcage:HasRabbit() then
        inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream")
    end

    inst.AnimState:PlayAnimation("idle_empty", true)

    inst.components.rabbitcage:PutRabbit()
    
    inst.components.hunger:SetRate(TUNING.RABBIT_JOULE_PER_DAY/TUNING.TOTAL_DAY_TIME)
    inst:ListenForEvent("hungerdelta", OnRabbitHunger)

    inst.components.trader:SetAcceptTest(ShouldAcceptCarrot)
end

function OnRemoveRabbit(inst)
    print("OnRemoveRabbit")

    if not POPULATING and inst.components.rabbitcage and inst.components.rabbitcage:HasRabbit() then
        inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream")
    end
    
    inst.AnimState:PlayAnimation("idle_norabbit", true)

    inst.components.rabbitcage:RemoveRabbit()

    inst:RemoveEventCallback("hungerdelta", OnRabbitHunger)
    inst.components.hunger:SetPercent(0)
    inst.components.hunger:SetRate(0)

    inst.components.trader:SetAcceptTest(ShouldAcceptRabbit)
end

local function OnFeedCarrot(inst) 
    print("OnFeedCarrot")
    if inst.components.hunger ~= nil then
        inst.components.hunger:DoDelta(TUNING.RABBIT_CARROT_JOULE, false, true)
    end

    if inst.components.health ~= nil then
        -- rabbit loses some of his max health with every carrot ...
        inst.components.health:SetMaxHealth(inst.components.health.maxhealth * (1 - TUNING.RABBIT_CARROT_POISON_PERCENT/100))
        print(inst.components.health.maxhealth)
        -- ... but is healed to 100%
        inst.components.health:SetPercent(TUNING.RABBIT_CARROT_HEAL_PERCENT)
        -- aging sucks!
    end
end

local function OnGetItemFromPlayer(inst, giver, item)
    print("OnGetItemFromPlayer" .. tostring(item))

    if item.prefab == "carrot" then
        OnFeedCarrot(inst, item)
    elseif item.prefab == "rabbit" then
        OnPutRabbit(inst, item)

        -- calculate initial rabbit hunger and health based on perish value
        local factor = 1
        if item.components.perishable then
            if item.components.perishable:IsStale() then
                factor = 0.6
            elseif item.components.perishable:IsStale() then
                factor = 0.3
            end
        end
        inst.components.health:SetMaxHealth(TUNING.RABBIT_MAX_HEALTH)
        inst.components.hunger:SetPercent(factor * 100)
        inst.components.health:SetPercent(factor * 100)
    end
end

local function OnStartGenerating(inst)
    print("OnStartGenerating")

    inst:RemoveEventCallback("hungerdelta", OnRabbitHunger)
    inst:ListenForEvent("hungerdelta", OnRabbitHunger)

    if inst.components.rabbitcage and inst.components.rabbitcage:HasRabbit() then
        inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream_short")
    end

    inst.AnimState:PlayAnimation("idle_charge", true)
end

-- not used atm
local function OnStopGenerating(inst)
    print("OnStopGenerating")
    inst:RemoveEventCallback("hungerdelta", OnRabbitHunger)
    inst.AnimState:PlayAnimation("idle_empty", true)
end


local function OnFuelSectionChange(new, old, inst)
    print("OnFuelSectionChange " .. tostring(new))

    local newsection = math.clamp(new + 1, 1, 7)
    UpdateAnimation(inst, newsection)

    if inst.components.fueled ~= nil then
        if inst.components.fueled.consuming 
                and inst.components.rabbitcage:HasRabbit()
                and not inst.components.hunger:IsStarving()
                and newsection == 6 then
            OnStartGenerating(inst)
        end
    end
    StartSoundLoop(inst, newsection)
end


--------------------------------------------------------------------------

local function OnBuilt3(inst)
    print("OnBuilt3")
    inst:RemoveTag("NOCLICK")

    inst.components.circuitnode:ConnectTo("engineering")

    OnRemoveRabbit(inst)
    UpdateAnimation(inst, 7)
    -- OnFuelEmpty(inst)
end

local function OnBuilt2(inst)
    print("OnBuilt2")

end

local function OnBuilt1(inst)
    print("OnBuilt1")
    -- inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream_short")
end

local function OnBuilt(inst)--, data)
    print("OnBuilt")
    if inst._inittask ~= nil then
        inst._inittask:Cancel()
        inst._inittask = nil
    end
    
    inst.components.circuitnode:Disconnect()
    inst.AnimState:PlayAnimation("idle_placer", true)
    inst.AnimState:ClearAllOverrideSymbols()
    -- inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream")
    inst:AddTag("NOCLICK")

    BroadcastCircuitChanged(inst)
    StopSoundLoop(inst)
    inst:DoTaskInTime(30 * FRAMES, OnBuilt1)
    inst:DoTaskInTime(50 * FRAMES, OnBuilt2)
    inst:DoTaskInTime(75 * FRAMES, OnBuilt3)
end

--------------------------------------------------------------------------


local function OnSave(inst, data)
    print("OnSave")
    data.burnt = inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") or nil
    data.hasrabbit = inst.components.rabbitcage.hasrabbit
    data.currenthealth = inst.components.health.currenthealth
    data.maxhealth = inst.components.health.maxhealth
    print("health")
    print(data.currenthealth)
end

local function OnLoad(inst, data, ents)
    print("OnLoad")
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    else
        if inst.components.fueled then
            if inst.components.fueled:IsEmpty() then
                OnFuelEmpty(inst)
            else
                StartSoundLoop(inst, inst.components.fueled:GetCurrentSection())
                -- if inst.AnimState:IsCurrentAnimation("idle_charge") then
                --     inst.AnimState:SetTime(inst.AnimState:GetCurrentAnimationLength() * math.random())
                -- end
            end
        end

        if inst.components.rabbitcage then
            inst.components.rabbitcage.hasrabbit = data.hasrabbit or false
        end

        inst.components.health:SetMaxHealth(data.maxhealth or TUNING.RABBIT_MAX_HEALTH)
        inst.components.health.currenthealth = data.currenthealth or data.maxhealth
        print("health after")
        print(inst.components.health.currenthealth)
    end
end

local function OnLoadPostPass(inst)
    print("OnLoadPostPass")
    if inst._inittask ~= nil then
        inst._inittask:Cancel()
        OnInit(inst)
    end

    if inst.components.rabbitcage.hasrabbit then
        OnPutRabbit(inst)
    else
        OnRemoveRabbit(inst)
    end
end

--------------------------------------------------------------------------

local function fn()
    print("fn")
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

    inst:AddTag("structure")
    inst:AddTag("engineeringbattery")
    inst:AddTag("rabbitwheel")

    inst.AnimState:SetBank("rabbitwheel")
    inst.AnimState:SetBuild("rabbitwheel")
    inst.AnimState:PlayAnimation("idle_norabbit", true)

    inst.MiniMapEntity:SetIcon("winona_battery_low.png")

    --Dedicated server does not need deployhelper
    if not TheNet:IsDedicated() then
        inst:AddComponent("deployhelper")
        inst.components.deployhelper:AddRecipeFilter("winona_spotlight")
        inst.components.deployhelper:AddRecipeFilter("winona_catapult")
        inst.components.deployhelper:AddRecipeFilter("winona_battery_low")
        inst.components.deployhelper:AddRecipeFilter("winona_battery_high")
        inst.components.deployhelper:AddRecipeFilter("rabbitwheel")
        inst.components.deployhelper.onenablehelper = OnEnableHelper
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnWorkCallback(OnWorked)
    inst.components.workable:SetOnFinishCallback(OnWorkFinished)

    inst:AddComponent("circuitnode")
    inst.components.circuitnode:SetRange(TUNING.WINONA_BATTERY_RANGE)
    inst.components.circuitnode:SetOnConnectFn(OnConnectCircuit)
    inst.components.circuitnode:SetOnDisconnectFn(OnDisconnectCircuit)

    inst:AddComponent("trader")
    -- SetAcceptTest is changing depending on state
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.deleteitemonaccept = false

    inst:AddComponent("rabbitcage")
    inst.components.rabbitcage.hasrabbit = false

    inst:AddComponent("hunger")
    inst.components.hunger:SetMax(TUNING.RABBIT_MAX_HUNGER)
    inst.components.hunger:SetRate(0)
    inst.components.hunger:SetKillRate(TUNING.RABBIT_MAX_HEALTH / TUNING.RABBIT_STARVE_KILL_TIME) 

    inst:AddComponent("health") -- every inst with hunger has also health, I guess
    inst.components.health.ondelta = OnRabbitHealthDelta

    inst:AddComponent("fueled")
    inst.components.fueled:SetDepletedFn(OnFuelEmpty)
    -- inst.components.fueled:SetTakeFuelFn(OnAddFuel)
    inst.components.fueled:SetSections(NUM_LEVELS)
    inst.components.fueled:SetSectionCallback(OnFuelSectionChange)
    inst.components.fueled:InitializeFuelLevel(TUNING.RABBITWHEEL_FULL_BATTERY_DURATION)
    inst.components.fueled.fueltype = FUELTYPE.MAGIC -- no associated fuel
    inst.components.fueled.accepting = false
    inst.components.fueled:StartConsuming()

    inst:ListenForEvent("onbuilt", OnBuilt)
    inst:ListenForEvent("engineeringcircuitchanged", OnCircuitChanged)

    MakeHauntableWork(inst)
    MakeMediumBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)
    inst.components.burnable:SetOnBurntFn(OnBurnt)
    inst.components.burnable.ignorefuel = true --igniting/extinguishing should not start/stop fuel consumption

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass
    inst.OnEntitySleep = StopSoundLoop
    inst.OnEntityWake = OnEntityWake

    -- default fuel with nitre
    -- inst:AddComponent("fueled")
    -- inst.components.fueled:SetDepletedFn(OnFuelEmpty)
    -- inst.components.fueled:SetTakeFuelFn(OnAddFuel)
    -- inst.components.fueled:SetSections(NUM_LEVELS)
    -- inst.components.fueled:SetSectionCallback(OnFuelSectionChange)
    -- inst.components.fueled:InitializeFuelLevel(TUNING.WINONA_BATTERY_LOW_MAX_FUEL_TIME)
    -- inst.components.fueled.fueltype = FUELTYPE.CHEMICAL
    -- inst.components.fueled.accepting = true
    -- inst.components.fueled:StartConsuming()

    inst._batterytask = nil
    inst._inittask = inst:DoTaskInTime(0, OnInit)
    UpdateCircuitPower(inst)

    return inst
end

--------------------------------------------------------------------------

local function placer_postinit_fn(inst)
    print("placer_postinit_fn")
    --Show the battery placer on top of the battery range ground placer

    local placer = CreateEntity()

    --[[Non-networked entity]]
    placer.entity:SetCanSleep(false)
    placer.persists = false

    placer.entity:AddTransform()
    placer.entity:AddAnimState()

    placer:AddTag("CLASSIFIED")
    placer:AddTag("NOCLICK")
    placer:AddTag("placer")

    placer.AnimState:SetBank("rabbitwheel")
    placer.AnimState:SetBuild("rabbitwheel")
    placer.AnimState:PlayAnimation("idle_placer")
    placer.AnimState:SetLightOverride(1)

    placer.entity:SetParent(inst.entity)

    inst.components.placer:LinkEntity(placer)

    inst.AnimState:SetScale(PLACER_SCALE, PLACER_SCALE)
end

--------------------------------------------------------------------------

return Prefab("rabbitwheel", fn, assets, prefabs),
    MakePlacer("rabbitwheel_placer", "winona_battery_placement", "winona_battery_placement", "idle", true, nil, nil, nil, nil, nil, placer_postinit_fn)
