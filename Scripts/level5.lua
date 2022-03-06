--spring level 5: The Conjuring

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
--change_sprite_bank(0,0)
--set_level_type(20)
--------------------
local tribe1 = TRIBE_RED
local tribe2 = TRIBE_BLACK
computer_init_player(_gsi.Players[tribe1])
computer_init_player(_gsi.Players[tribe2])
local AItribes = {TRIBE_RED,TRIBE_BLACK}
for i = 1,7 do
	for j = 1,7 do
		set_players_allied(i,j) set_players_allied(j,i)
	end
end
--
--vars
local devil = 0
--------------------
	

function OnTurn()
	
	if every2Pow(2) then
		if devil == 1 then
			--kill aods
			ProcessGlobalSpecialList(TRIBE_BLUE, PEOPLELIST, function(t)
				if t.Model == M_PERSON_MEDICINE_MAN then
					SearchMapCells(CIRCULAR, 0, 0, 2, world_coord3d_to_map_idx(t.Pos.D3), function(me)
						me.MapWhoList:processList( function (h)
							if (h.Owner ~= t.Owner) and (h.Type == T_PERSON) and (h.Model == M_PERSON_ANGEL) then
								local a = createThing(T_EFFECT, M_EFFECT_LIGHTNING, 0, h.Pos.D3, false, false)
								local a = createThing(T_EFFECT, M_EFFECT_LIGHTNING_STRAND, 0, h.Pos.D3, false, false)
								local a = createThing(T_EFFECT, M_EFFECT_LAVA_GLOOP, 0, h.Pos.D3, false, false)
								damage_person (h,8,65000,1)
							end
						return true end)
					return true end)
				end
			return true end)
			--
			if getShaman(0) ~= nil then
				--lava trail
				--local l = createThing(T_EFFECT, M_EFFECT_LAVA_SQUARE, 0, getShaman(0).Pos.D3, false, false) centre_coord3d_on_block(l.Pos.D3)
				--dark trail
				SearchMapCells(CIRCULAR, 0, 0 , 1, world_coord3d_to_map_idx(getShaman(0).Pos.D3), function(me)
					me.Shade1 = -64
					me.ShadeIncr = -64
				return true
				end)
			end
		end
	end
	
end



import(Module_Helpers)
function OnKeyDown(key)
	if key == LB_KEY_J then
		if getShaman(0) ~= nil then
			getShaman(0).u.Pers.MaxLife = 22222 
			getShaman(0).u.Pers.Life = 22222
			getShaman(0).Flags3 = EnableFlag(getShaman(0).Flags3, TF3_BLOODLUST_ACTIVE)
		end
		change_sprite_bank(0,1)
		devil = 1
		--set_level_type(29)
		draw_sky_clr_overlay(12,-1)
	end
end






