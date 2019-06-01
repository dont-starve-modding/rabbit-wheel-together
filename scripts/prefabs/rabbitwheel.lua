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
            inst.components.fueled.rate = math.max(load, TUNING.WINONA_BATTERY_MIN_LOAD) * TUNING.WINONA_BATTERY_LOW_FUEL_RATE_MULT
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
            inst.AnimState:PlayAnimation("idle_empty")
        else
            inst.AnimState:PlayAnimation("idle_charge", true)
        end
    end
end

local function PlayHitAnim(inst)
    print("PlayHitAnim")
    inst:RemoveEventCallback("animover", OnHitAnimOver)
    inst:ListenForEvent("animover", OnHitAnimOver)
    inst.AnimState:PlayAnimation("hit")
end

local function OnWorked(inst)
    print("OnWorked")
    if inst.components.fueled.accepting then
        PlayHitAnim(inst)
    end
    inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream_short")
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
    print(level)
    return level ~= nil
        and (   (level <= 0 and "OFF") or
                (level <= 1 and "LOWPOWER")
            )
        or nil
end

local function OnFuelEmpty(inst)
    print("OnFuelEmpty")
    if inst.components.fueled.accepting then
        inst.components.fueled:StopConsuming()
        BroadcastCircuitChanged(inst)
        StopBattery(inst)
        StopSoundLoop(inst)

        -- TODO this is needed!!!
        -- inst.AnimState:OverrideSymbol("m2", "rabbitwheel", "m1")
        -- inst.AnimState:OverrideSymbol("plug", "rabbitwheel", "plug_off")

        if inst.AnimState:IsCurrentAnimation("idle_charge") then
            inst.AnimState:PlayAnimation("idle_empty")
        end
        if not POPULATING then
            inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream")
        end
    end
end

local function OnAddFuel(inst)
    print("OnAddFuel")
    if inst.components.fueled.accepting and not inst.components.fueled:IsEmpty() then
        if not inst.components.fueled.consuming then
            inst.components.fueled:StartConsuming()
            BroadcastCircuitChanged(inst)
            if inst.components.circuitnode:IsConnected() then
                StartBattery(inst)
            end
            if not inst:IsAsleep() then
                StartSoundLoop(inst)
            end
        end
        PlayHitAnim(inst)
        inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream_short")
    end
end

local function OnFuelSectionChange(new, old, inst)
    print("OnFuelSectionChange")
    if inst.components.fueled.accepting then
        -- TODO this is needed!
        -- inst.AnimState:OverrideSymbol("m2", "rabbitwheel", "m"..tostring(math.clamp(new + 1, 1, 7)))
        -- inst.AnimState:ClearOverrideSymbol("plug")
        UpdateSoundLoop(inst, new)
    end
end

local function OnSave(inst, data)
    print("OnSave")
    data.burnt = inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") or nil
end

local function OnLoad(inst, data, ents)
    print("OnLoad")
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    elseif inst.components.fueled:IsEmpty() then
        OnFuelEmpty(inst)
    else
        UpdateSoundLoop(inst, inst.components.fueled:GetCurrentSection())
        if inst.AnimState:IsCurrentAnimation("idle_charge") then
            inst.AnimState:SetTime(inst.AnimState:GetCurrentAnimationLength() * math.random())
        end
    end
end

local function OnInit(inst)
    print("OnInit")
    inst._inittask = nil
    inst.components.circuitnode:ConnectTo("engineering")
end

local function OnLoadPostPass(inst)
    print("OnLoadPostPass")
    if inst._inittask ~= nil then
        inst._inittask:Cancel()
        OnInit(inst)
    end
end

--------------------------------------------------------------------------

local function OnBuilt3(inst)
    print("OnBuilt3")
    inst:RemoveTag("NOCLICK")
    inst.components.fueled.accepting = true
    if inst.components.fueled:IsEmpty() then
        OnFuelEmpty(inst)
    else
        OnFuelSectionChange(inst.components.fueled:GetCurrentSection(), nil, inst)
        inst.AnimState:PlayAnimation("idle_charge", true)
        if not inst.components.fueled.consuming then
            inst.components.fueled:StartConsuming()
            BroadcastCircuitChanged(inst)
        end
        if inst.components.circuitnode:IsConnected() then
            StartBattery(inst)
        end
        if not inst:IsAsleep() then
            StartSoundLoop(inst)
        end
    end
end

local function OnBuilt2(inst)
    print("OnBuilt2")
    if inst.components.fueled:IsEmpty() then
        StopSoundLoop(inst)
    else
        if not inst.components.fueled.consuming then
            inst.components.fueled:StartConsuming()
            BroadcastCircuitChanged(inst)
        end
        if not inst:IsAsleep() then
            StartSoundLoop(inst)
        end
    end
    inst.components.circuitnode:ConnectTo("engineering")
end

local function OnBuilt1(inst)
    print("OnBuilt1")
    inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream_short")
    if not (inst.components.fueled:IsEmpty() or inst:IsAsleep()) then
        StartSoundLoop(inst)
    end
end

local function OnBuilt(inst)--, data)
    print("OnBuilt")
    if inst._inittask ~= nil then
        inst._inittask:Cancel()
        inst._inittask = nil
    end
    inst.components.circuitnode:Disconnect()
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:ClearAllOverrideSymbols()
    inst.SoundEmitter:PlaySound("dontstarve/rabbit/scream")
    inst:AddTag("NOCLICK")
    inst.components.fueled.accepting = false
    inst.components.fueled:StopConsuming()
    BroadcastCircuitChanged(inst)
    StopSoundLoop(inst)
    inst:DoTaskInTime(10 * FRAMES, OnBuilt1)
    inst:DoTaskInTime(30 * FRAMES, OnBuilt2)
    inst:DoTaskInTime(50 * FRAMES, OnBuilt3)
end

--------------------------------------------------------------------------

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

    inst.AnimState:SetBank("rabbitwheel")
    inst.AnimState:SetBuild("rabbitwheel")
    inst.AnimState:PlayAnimation("idle_charge", true)

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

    inst:AddComponent("fueled")
    inst.components.fueled:SetDepletedFn(OnFuelEmpty)
    inst.components.fueled:SetTakeFuelFn(OnAddFuel)
    inst.components.fueled:SetSections(NUM_LEVELS)
    inst.components.fueled:SetSectionCallback(OnFuelSectionChange)
    inst.components.fueled:InitializeFuelLevel(TUNING.WINONA_BATTERY_LOW_MAX_FUEL_TIME)
    inst.components.fueled.fueltype = FUELTYPE.CHEMICAL
    inst.components.fueled.accepting = true
    inst.components.fueled:StartConsuming()

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

    inst._batterytask = nil
    inst._inittask = inst:DoTaskInTime(0, OnInit)
    UpdateCircuitPower(inst)

    return inst
end

--------------------------------------------------------------------------

local function placer_postinit_fn(inst)
    print("placer_postinit_fn")
    --Show the battery placer on top of the battery range ground placer

    local placer2 = CreateEntity()

    --[[Non-networked entity]]
    placer2.entity:SetCanSleep(false)
    placer2.persists = false

    placer2.entity:AddTransform()
    placer2.entity:AddAnimState()

    placer2:AddTag("CLASSIFIED")
    placer2:AddTag("NOCLICK")
    placer2:AddTag("placer")

    placer2.AnimState:SetBank("rabbitwheel")
    placer2.AnimState:SetBuild("rabbitwheel")
    placer2.AnimState:PlayAnimation("idle_placer")
    placer2.AnimState:SetLightOverride(1)

    placer2.entity:SetParent(inst.entity)

    inst.components.placer:LinkEntity(placer2)

    inst.AnimState:SetScale(PLACER_SCALE, PLACER_SCALE)
end

--------------------------------------------------------------------------

return Prefab("rabbitwheel", fn, assets, prefabs),
    MakePlacer("rabbitwheel_placer", "winona_battery_placement", "winona_battery_placement", "idle", true, nil, nil, nil, nil, nil, placer_postinit_fn)
