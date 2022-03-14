--spring level 8: The Bard's Tale

import(Module_System)
import(Module_Globals)
import(Module_Players)
import(Module_DataTypes)
import(Module_Table)
import(Module_Level)
import(Module_Defines)
import(Module_PopScript)
import(Module_Game)
import(Module_Objects)
import(Module_Map)
import(Module_Math)
import(Module_String)
import(Module_MapWho)
import(Module_ImGui)
import(Module_Draw)
import(Module_Person)
import(Module_Sound)
import(Module_Commands)
import(Module_Spells)
import(Module_Building)
local gs = gsi()
local gns = gnsi()
_gnsi = gnsi()
_gsi = gsi()
sti = spells_type_info()
tmi = thing_move_info()
include("assets.lua")
--------------------
local player = TRIBE_ORANGE
local tribe1 = TRIBE_YELLOW
computer_init_player(_gsi.Players[tribe1])
local AItribes = {TRIBE_YELLOW}
--
local balm = M_SPELL_INVISIBILITY --(healing balm): units in a 3x3 area get healed for 1/3 their max hp
local seed = M_SPELL_SWAMP --(seed of life): casts a seed that rises a tree and creates a wildman
local balmCDR = -1
local seedCDR = -1
local balmC3D = 0
local seedC3D = 0
local replace1 = -1
local replace2 = -1
local bard = 0

botSpells = {M_SPELL_CONVERT_WILD,
             M_SPELL_BLAST,
             M_SPELL_LAND_BRIDGE,
             M_SPELL_LIGHTNING_BOLT,
             M_SPELL_INSECT_PLAGUE,
             M_SPELL_INVISIBILITY,
             --M_SPELL_GHOST_ARMY,
             M_SPELL_SWAMP,
             M_SPELL_HYPNOTISM,
             M_SPELL_WHIRLWIND,
             M_SPELL_EROSION,
             M_SPELL_EARTHQUAKE,
             M_SPELL_FIRESTORM,
             M_SPELL_SHIELD,
             --M_SPELL_FLATTEN,
             M_SPELL_VOLCANO,
             M_SPELL_ANGEL_OF_DEATH
}
botBldgs = {M_BUILDING_TEPEE,
            M_BUILDING_DRUM_TOWER,
            M_BUILDING_WARRIOR_TRAIN,
            M_BUILDING_TEMPLE,
            M_BUILDING_SUPER_TRAIN,
            --M_BUILDING_SPY_TRAIN,
			--M_BUILDING_BOAT_HUT_1,
            M_BUILDING_AIRSHIP_HUT_1
}
for t,w in ipairs (AItribes) do
	for k,v in ipairs(botSpells) do
		set_player_can_cast(v, w)
	end
	for k,v in ipairs(botBldgs) do
		set_player_can_build(v, w)
	end
end
--sti[balm].Cost = 10000
sti[balm].OneOffMaximum = 3
sti[balm].WorldCoordRange = 4096
sti[balm].CursorSpriteNum = 162
sti[balm].ToolTipStrIdx = 687
sti[balm].ToolTipStrIdxLSME = 687
sti[balm].AvailableSpriteIdx = 1776
sti[balm].NotAvailableSpriteIdx = 1780
sti[balm].ClickedSpriteIdx = 1778
--
--sti[seed].Cost = 10000
sti[seed].OneOffMaximum = 2
sti[seed].WorldCoordRange = 2048+1024
sti[seed].CursorSpriteNum = 163
sti[seed].ToolTipStrIdx = 688
sti[seed].ToolTipStrIdxLSME = 688
sti[seed].AvailableSpriteIdx = 1777
sti[seed].NotAvailableSpriteIdx = 1781
sti[seed].ClickedSpriteIdx = 1779

function BalmSpell(pn,c3d)
	if balmC3D ~= nil then
		local a = 0
		SearchMapCells(SQUARE ,0, 0, 1, world_coord3d_to_map_idx(c3d), function(me)
			local cloud = createThing(T_EFFECT,M_EFFECT_SMOKE_CLOUD,8,c3d,false,false) centre_coord3d_on_block(cloud.Pos.D3)
			cloud.u.Effect.Duration = 12*1 ; --cloud.DrawInfo.Alpha = 3
			me.MapWhoList:processList( function (h)
				if (h.Owner == pn) and (h.Type == T_PERSON) and (h.Model < 8) and (h.u.Pers.Life < h.u.Pers.MaxLife) then
					local hp = h.u.Pers.Life
					local give = math.floor(h.u.Pers.MaxLife/3) LOG(hp) LOG(give)
					if hp + give > h.u.Pers.MaxLife then
						h.u.Pers.Life = h.u.Pers.MaxLife
						a = 1
					else
						h.u.Pers.Life = hp + give
						a = 1
					end
					LOG(h.u.Pers.Life)
					local sp = createThing(T_EFFECT,60,8,h.Pos.D3,false,false) centre_coord3d_on_block(sp.Pos.D3) sp.u.Effect.Duration = 12
				end
			return true end)
		return true end)
		if a == 1 then queue_sound_event(nil,SND_EVENT_CMD_MENU_POPUP, SEF_FIXED_VARS) end
	end
end

function SeedSpell(pn,c3d)
	local function RegiveSeed()
		local shots = GET_NUM_ONE_OFF_SPELLS(player,seed)
		_gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[seed] = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[seed] & 240
		_gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[seed] = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[seed] | shots+1
	end
	if seedC3D ~= nil then
		SearchMapCells(SQUARE, 0, 0 , 0, world_coord3d_to_map_idx(c3d), function(me)
			if (is_map_elem_sea_or_coast(me) == 0) then
				if is_map_cell_obstacle_free(world_coord3d_to_map_idx(c3d)) == 1 and is_cell_too_steep_for_building(world_coord3d_to_map_idx(c3d),4) == 0 then
					if is_building_on_map_cell(world_coord3d_to_map_idx(c3d)) == 0 then
						if is_map_cell_a_building_belonging_to_player(world_coord3d_to_map_idx(c3d),7) == 0 and is_map_cell_a_building_belonging_to_player(world_coord3d_to_map_idx(c3d),3) == 0 then
							queue_sound_event(nil,SND_EVENT_WOOD_STRESS, SEF_FIXED_VARS)
							local se = createThing(T_EFFECT,10,8,c3d,false,false) centre_coord3d_on_block(se.Pos.D3)
							se.u.Effect.Duration = 56 ; se.DrawInfo.DrawNum = 475 se.DrawInfo.Alpha = -16
							CREATE_THING_WITH_PARAMS4(T_SCENERY, M_SCENERY_DORMANT_TREE, TRIBE_HOSTBOT, c3d, T_SCENERY, math.random(1,6), 0, 0);
						else
							RegiveSeed()
						end
					else
						RegiveSeed()
					end
				else
					RegiveSeed()
				end
			else
				createThing(T_EFFECT,M_EFFECT_SPLASH,8,c3d,false,false)
				queue_sound_event(nil,SND_EVENT_W_SPLASH, SEF_FIXED_VARS)
				RegiveSeed()
			end
		return true end)
	end
end



function OnTurn() 														--LOG(_gsi.Players[player].SpellsCast[1])
	--balm spell
	if balmCDR > 0 then 
		balmCDR = balmCDR - 1
	elseif balmCDR == 0 then
		balmCDR = -1
		BalmSpell(player,balmC3D)
	end
	--seed spell
	if seedCDR > 0 then 
		seedCDR = seedCDR - 1
	elseif seedCDR == 0 then
		seedCDR = -1
		SeedSpell(player,seedC3D)
	end
	--trees grow
	ProcessGlobalTypeList(T_EFFECT, function(t)
		if t.Type == T_EFFECT and t.Model == 10 and t.DrawInfo.DrawNum == 475 then
			SearchMapCells(CIRCULAR, 0, 0, 8, world_coord3d_to_map_idx(t.Pos.D3), function(me)
				me.MapWhoList:processList( function (h)
					if h.Type == T_SCENERY and h.Model < 7 then
						local s = h.u.ObjectInfo.Scale
						if s+4 < 160 then h.u.ObjectInfo.Scale = s+1 else h.u.ObjectInfo.Scale = 160 end
						local s = h.u.ObjectInfo.Scale
						if s <= 40 then h.u.Scenery.ResourceRemaining = 100 elseif s <= 80 then h.u.Scenery.ResourceRemaining = 200 elseif h.u.Scenery.ResourceRemaining <= 120 then h.u.Scenery.ResourceRemaining = 300 else h.u.Scenery.ResourceRemaining = 400 end
						if s > 155 and s < 160 then
							queue_sound_event(nil,SND_EVENT_BIRTH, SEF_FIXED_VARS)
							local g = createThing(T_EFFECT,59,8,h.Pos.D3,false,false) g.DrawInfo.Alpha = 1
							createThing(T_PERSON,M_PERSON_WILD,8,h.Pos.D3,false,false)
						end
					end
				return true end)
			return true end)
		end
	return true end)
	if every2Pow(4) then
		if bard >= 3 and bard < 9 then
			bard = bard + 1
			if bard == 9 then
				queue_sound_event(nil,SND_EVENT_DISCOVERY_START, SEF_FIXED_VARS)
				set_player_can_cast(seed, player) set_player_can_cast(balm, player)
				_gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[balm] = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[balm] & 240
				_gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[balm] = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[balm] | 2
				_gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[seed] = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[seed] & 240
				_gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[seed] = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[seed] | 2
				_gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[M_SPELL_CONVERT_WILD] = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[M_SPELL_CONVERT_WILD] & 240
				_gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[M_SPELL_CONVERT_WILD] = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[M_SPELL_CONVERT_WILD] | 2
				FLASH_BUTTON(27,1) --FLASH_BUTTON(22,1)
			end
		end
	end
	if turn() == 1 then
		local fireplace = createThing(T_EFFECT,M_EFFECT_FIRESTORM_SMOKE,8,marker_to_coord3d(2),false,false) fireplace.DrawInfo.Alpha = 1 centre_coord3d_on_block(fireplace.Pos.D3)
		local bf = createThing(T_EFFECT,M_EFFECT_BIG_FIRE,8,marker_to_coord3d(2),false,false) bf.u.Effect.Duration = 12*50 centre_coord3d_on_block(bf.Pos.D3)
	end
end

function OnCreateThing(t)
	--2 new spells
	if bard > 0 and bard < 3 then
		if (t.Type == T_SPELL) then
			--replace1 = t.Model
			local g = createThing(T_EFFECT,M_EFFECT_ORBITER,8,t.Pos.D3,false,false)
			if getShaman(player) ~= nil then
				createThing(T_EFFECT,58,8,getShaman(player).Pos.D3,false,false)
			end
			set_player_cannot_cast(t.Model, player)
			bard = bard+1
			queue_sound_event(nil,SND_EVENT_DISCOVERY_END, SEF_FIXED_VARS)
			if bard == 3 then
				createThing(T_EFFECT,M_EFFECT_EARTHQUAKE,8,marker_to_coord3d(1),false,false)
			end
		end
	end
	--healing balm (invisibility)
	if (t.Type == T_SPELL) and (t.Model == balm) then
		t.Model = M_SPELL_NONE
		queue_sound_event(nil,SND_EVENT_SELECT_CMD, SEF_FIXED_VARS)
		balmCDR = 8
		balmC3D = CopyC3d(t.Pos.D3)
		local shots = GET_NUM_ONE_OFF_SPELLS(t.Owner,balm)
		_gsi.ThisLevelInfo.PlayerThings[t.Owner].SpellsAvailableOnce[balm] = _gsi.ThisLevelInfo.PlayerThings[t.Owner].SpellsAvailableOnce[balm] & 240
		_gsi.ThisLevelInfo.PlayerThings[t.Owner].SpellsAvailableOnce[balm] = _gsi.ThisLevelInfo.PlayerThings[t.Owner].SpellsAvailableOnce[balm] | shots-1
	end
	--seed of life (swamp)
	if (t.Type == T_SPELL) and (t.Model == seed) then
		t.Model = M_SPELL_NONE
		queue_sound_event(nil,SND_EVENT_ACCEPT_CMD, SEF_FIXED_VARS)
		seedCDR = 8
		seedC3D = CopyC3d(t.Pos.D3)
		local shots = GET_NUM_ONE_OFF_SPELLS(t.Owner,seed)
		_gsi.ThisLevelInfo.PlayerThings[t.Owner].SpellsAvailableOnce[seed] = _gsi.ThisLevelInfo.PlayerThings[t.Owner].SpellsAvailableOnce[seed] & 240
		_gsi.ThisLevelInfo.PlayerThings[t.Owner].SpellsAvailableOnce[seed] = _gsi.ThisLevelInfo.PlayerThings[t.Owner].SpellsAvailableOnce[seed] | shots-1
	end
end


function OnSoundEvent(t_thing, event, flags) 
  if (event == SND_EVENT_SHAM_INVIS) or (event == SND_EVENT_SHAM_SWAMP) then
    --log_msg(8, string.format("Event: %i, Flags: %i", event, flags))
    return 1
  end
end


function OnSave(save_data)
	save_data:push_int(bard)
	save_data:push_int(balmCDR)
	save_data:push_int(seedCDR)
	save_data:push_int(replace1)
	save_data:push_int(replace2)
	Engine:saveData(save_data)
end

function OnLoad(load_data)
	game_loaded = true
	Engine:loadData(load_data)
	replace2 = load_data:pop_int()
	replace1 = load_data:pop_int()
	seedCDR = load_data:pop_int()
	balmCDR = load_data:pop_int()
	bard = load_data:pop_int()
end

import(Module_Helpers)
function OnKeyDown(k)
    if (k == LB_KEY_1) then
		bard = 1
		local fullspells = {2,3,4,5,6,8,10,11,12,14,15,19}
		for k,v in ipairs(fullspells) do
			set_player_can_cast(v, player)
		end
		set_player_cannot_cast(6, player) set_player_cannot_cast(11, player) set_player_cannot_cast(9, player) set_player_cannot_cast(12, player) set_player_cannot_cast(15, player)
	end
end