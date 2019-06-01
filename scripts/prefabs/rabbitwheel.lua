require "prefabutil"
require "tuning"

local assets =
{ 
	Asset("ANIM", "anim/rabbitwheel.zip"),

	Asset("MINIMAP_IMAGE", "winona_catapult"),

	-- Asset("MINIMAP_IMAGE", "farm1"),
	-- Asset("MINIMAP_IMAGE", "farm2"),
	-- Asset("MINIMAP_IMAGE", "farm3"),
	
	-- for grass sounds opening (+others) the rabbitwheel 
	-- Asset("SOUND", "sound/common.fsb"),
	
    -- Asset("ATLAS", "images/inventoryimages/rabbitwheel.xml"),
    -- Asset("IMAGE", "images/inventoryimages/rabbitwheel.tex"),
}

local prefabs = 
{
}

local function onhammered(inst, worker)
	-- loot poop by destroying ur pile
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal")
	inst:Remove()
end


local function OnBurntDirty(inst)
    -- RefreshDecor(inst, inst._burnt:value())
end

local function OnBurnt(inst)
    inst._burnt:set(true)
    -- if not TheNet:IsDedicated() then
    --     -- RefreshDecor(inst, true)
    -- end
end

local function onbuilt(inst)
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal") 
	-- inst.AnimState:PlayAnimation("place")
	-- inst.AnimState:PushAnimation("idle_empty")

	-- is called only on built
	inst.Transform:SetRotation(45)
end

local function makeburnable(inst)   
	local burnt_highlight_override = {.5,.5,.5}
	local function OnBurnt(inst)
		local function changes()
			if inst.components.burnable then
				inst.components.burnable:Extinguish()
			end
			inst:RemoveComponent("burnable")
			inst:RemoveComponent("propagator")
		end
			
		inst:DoTaskInTime(0.5, changes)

		inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds") 
		inst.AnimState:PlayAnimation("idle")
		inst.highlight_override = burnt_highlight_override
	end

	local function pile_burnt(inst)
		OnBurnt(inst)
	end
	
	MakeLargeBurnable(inst)
	inst.components.burnable:SetFXLevel(5)
	inst.components.burnable:SetOnBurntFn(pile_burnt)
	
	MakeLargePropagator(inst)
end


local function OnHaunt(inst, haunter)
    return false
end

local function fn()
	
	local function onsave(inst, data)
		-- if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
		-- 	data.burnt = true
		-- end
	end
	
	local function onload(inst, data)
		-- if data ~= nil and data.burnt then
		-- 	inst.components.burnable.onburnt(inst)
		-- end
	end

	local function getstatus(inst)
		if inst:HasTag("burnt") then
			return "BURNT"
		end

		inst.AnimState:PlayAnimation("anim", true)
		
		return "EMPTY"
	end

	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, .5)

	inst.Transform:SetSixFaced()
    
    inst:AddTag("structure")
    
    inst.AnimState:SetBank("rabbitwheel")
    inst.AnimState:SetBuild("rabbitwheel")
	inst.AnimState:PlayAnimation("idle")
	
	inst.MiniMapEntity:SetIcon("winona_catapult.png")

	-- is called only on server load, not on built (see above!)
	inst.Transform:SetRotation(225)
	
	inst._burnt = net_bool(inst.GUID, "rabbitwheel._burnt", "burntdirty")

	inst.decor = {}

	MakeSnowCoveredPristine(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst.components.inspectable.nameoverride = "RABBITWHEEL"
	inst.components.inspectable.getstatus = getstatus

	MakeLargeBurnable(inst, nil, nil, true)
	MakeMediumPropagator(inst)

    -- inst:AddComponent("playerprox") -- TODO valid in DST?
    -- inst.components.playerprox:SetDist(3,5)
    -- inst.components.playerprox:SetOnPlayerFar(onfar)
	
    -- inst.components.inventoryitem:SetOnDroppedFn(function() inst.flies = inst:SpawnChild("flies") end)
    -- inst.components.inventoryitem:SetOnPickupFn(function() if inst.flies then inst.flies:Remove() inst.flies = nil end end)
    -- inst.components.inventoryitem:SetOnPutInInventoryFn(function() if inst.flies then inst.flies:Remove() inst.flies = nil end end)

	inst:ListenForEvent("burntup", OnBurnt)  
	inst:ListenForEvent("onbuilt", onbuilt)

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)

	inst:AddComponent("savedrotation")

	inst:AddComponent("hauntable")
	inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_SMALL
	inst.components.hauntable:SetOnHauntFn(OnHaunt)

    MakeSnowCovered(inst)

	inst.OnSave = onsave
	inst.OnLoad = onload

    return inst
end

return Prefab("common/rabbitwheel", fn, assets, prefabs),
    MakePlacer("common/rabbitwheel_placer", "rabbitwheel", "rabbitwheel", "idle")