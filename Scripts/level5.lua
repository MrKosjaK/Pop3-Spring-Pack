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
change_sprite_bank(0,0)
set_level_type(10) --A
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
local ground = 31
local jewels = 0 --/8
local placedJewels = 0 --/8
local j1,j2,j3,j4,j5,j6,j7,j8 = 0,0,0,0,0,0,0,0
local up = 1
--stuff at start only
if turn() == 0 then
	--white ground cemetery
	for i = 1,8 do
		SearchMapCells(CIRCULAR, 0, 0 , 1, world_coord3d_to_map_idx(marker_to_coord3d(i)), function(me)
			me.ShadeIncr = 31
		return true
		end)
	end
	--create jewels
	local possibleJewelMk = {21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36}
	local Jsprite = 1744
	for i = 1,8 do
		local idx = math.random(1,#possibleJewelMk)
		local mk = possibleJewelMk[idx]
		local jewel = createThing(T_EFFECT,10,8,marker_to_coord3d(mk),false,false) centre_coord3d_on_block(jewel.Pos.D3) ; set_thing_draw_info(jewel,TDI_SPRITE_F1_D1, Jsprite) 
		jewel.u.Effect.Duration = -1 ; jewel.DrawInfo.Alpha = -16 jewel.Flags2 = EnableFlag(jewel.Flags2, TF2_DONT_DRAW_IN_WORLD_VIEW)
		table.remove(possibleJewelMk,idx) log_msg(8,"placed jewel in marker: " .. mk)
		Jsprite = Jsprite + 1
	end
end
-------------------------------------------------------------------------------------------------------------------------------------------------
include("CSequence.lua");
local Engine = CSequence:createNew();
local dialog_msgs = {
  [0] = {"Here we are, Ikani. The place i told you about lies just ahead... <br> Behold one of the last known orbs of ascension - magical artifacts created by the old gods, and spread around the worlds, awaiting the arrival of worthy shamans. ", "Matak High-Preacher", 1743, 0, 225},
  [1] = {"Shall we get closer? ", "Matak High-Preacher", 1740, 0, 225},
  [2] = {"Certainly! As i told you before, it is the first time that a shaman from my bloodline has seen such a legendary artifact...","Ikani", 7594, 1, 219},
  [3] = {"*laughing* <br> That is not surprising, Ikani... Almost no one has ever laid eyes in one of these.","Matak High-Preacher", 1741, 0, 225},
  [4] = {"Thank you for your help, my friend. You shall be rewarded soon enough. For now, your services are no longer required.","Ikani", 6879, 1, 219},
  [5] = {"Farewell, shaman! Remember, the orb will test your wisdom... For every decision, there will be a reward - but in each reward lies a sacrifice... <br> I must go now, for i promised to show the location of this orb to a few other shamans i know. ","Matak High-Preacher", 1742, 0, 225},
  [6] = {"Sorry, but i think it's best if i keep the location of this orb to myself...","Ikani", 6897, 1, 219},
  [7] = {"The orb feels my presence... It tells me i shall be called three times during my visit to this world.","Ikani", 6879, 1, 219},
  [8] = {"Come forth, shaman...","Orb of Ascension", 471, 0, 248},
  [9] = {"I can feel the fire flowing through my veins... I must use this power to my advantage.","Ikani", 6879, 1, 219},
  [10] = {"My people shall live protected by the rivers... I must use this power to my advantage.","Ikani", 6879, 1, 219},
  [11] = {"Guide us, oh gods of the storm!","Ikani", 6879, 1, 219},
  [12] = {"Guide us, oh spirits of the land!","Ikani", 6879, 1, 219},
  [13] = {"Who needs honour when we can fight with the power of death and corruption? ","Ikani", 6879, 1, 219},
  [14] = {"The honourable way of living and fighting... the eagle shall guide us!","Ikani", 6879, 1, 219},
}
--for scaling purposes
local user_scr_height = ScreenHeight();
local user_scr_width = ScreenWidth();
if (user_scr_height > 600) then
  Engine.DialogObj:setFont(3);
end
-------------------------------------------------------------------------------------------------------------------------------------------------
	

function DevilMode()
	local sh = getShaman(0)
	if turn() % 2 == 0 then
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
		if sh ~= nil then
			--fire trail
			--local fire = createThing(T_EFFECT,M_EFFECT_BIG_FIRE ,8,sh.Pos.D3,false,false) fire.u.Effect.Duration = 8 ; fire.DrawInfo.Alpha = 0
			--dark trail
			SearchMapCells(CIRCULAR, 0, 0 , 1, world_coord3d_to_map_idx(sh.Pos.D3), function(me)
				me.Shade1 = -64
				me.ShadeIncr = -64
			return true
			end)
		end
	end
end

function GroundDarken()
	--cemetery ground changing once all stones are set
	if ground > -32 then
		for i = 1,8 do
			SearchMapCells(CIRCULAR, 0, 0 , 1, world_coord3d_to_map_idx(marker_to_coord3d(i)), function(me)
				me.ShadeIncr = ground	
			return true
			end)
		end
		ground = ground - 1
	end
end

function CatchJewels()
	local sh = getShaman(0)
	if sh ~= nil then
		ProcessGlobalTypeList(T_EFFECT,function(Jewel)
			if Jewel.Type == T_EFFECT and Jewel.Model == 10 and Jewel.DrawInfo.DrawNum > 1743 then
				if get_world_dist_xz(sh.Pos.D2,Jewel.Pos.D2) < 128+64 then
					jewels = jewels + 1
					local num = Jewel.DrawInfo.DrawNum
					if num == 1744 then j1 = 1 elseif num == 1745 then j2 = 1 elseif num == 1746 then j3 = 1 elseif num == 1747 then j4 = 1 elseif
					num == 1748 then j5 = 1 elseif num == 1749 then j6 = 1 elseif num == 1750 then j7 = 1 elseif num == 1751 then j8 = 1 end
					Jewel.DrawInfo.DrawNum = 683
					move_thing_within_mapwho(Jewel,marker_to_coord3d(37))
					queue_sound_event(nil, SND_EVENT_DISCOBLDG_START, SEF_FIXED_VARS)
				end
			end
		return true end)
	end
end

function MoveJewels()
	ProcessGlobalTypeList(T_EFFECT,function(Jewel)
		if Jewel.Type == T_EFFECT and Jewel.Model == 10 and Jewel.DrawInfo.DrawNum > 1743 then
			if rnd() > 70 then createThing(T_EFFECT,M_EFFECT_LIGHTNING_STRAND,8,Jewel.Pos.D3,false,false) end
			if up == 1 then Jewel.Pos.D3.Ypos = Jewel.Pos.D3.Ypos + 6 else Jewel.Pos.D3.Ypos = Jewel.Pos.D3.Ypos - 6 end
		end
	return true end)
	if turn() % 24 == 0 and turn() > 0 then
		if up == 0 then up = 1 else up = 0 end
	end
end


function OnTurn()

	MoveJewels()
	if every2Pow(3) then
		if devil == 0 then
			CatchJewels()
		end
	end

	if devil == 1 then
		DevilMode()
	end
	
end



local safeZones = {}
local m1 = MapPosXZ.new()
for x= 58,90 do ; for z= 194,234 do
    m1.XZ.X = x ; m1.XZ.Z = z ; table.insert(safeZones, m1.Pos)
end end
function OnCreateThing(t)
	--safe zones
	if (t.Type == T_SPELL) then
		local pos = world_coord3d_to_map_idx(t.Pos.D3)
		for k, v in pairs(safeZones) do
			if (v == pos) then
				t.Model = M_SPELL_NONE
			end
		end
	end
end



function OnFrame()
  --for cinematics
  if (gns.Flags3 & GNS3_INGAME_OPTIONS == 0) then
    local gui_width = GFGetGuiWidth();

    Engine.CinemaObj:renderView();

    Engine.DialogObj:setDimensions(ScreenWidth() >> 1, Engine.DialogObj.DialogHeight);
    --rescaling
    if (ScreenHeight() ~= user_scr_height) then
      user_scr_height = ScreenHeight();
      Engine.DialogObj:setFont(4);
      if (user_scr_height > 600) then
        Engine.DialogObj:setFont(3);
      end
      if (Engine.DialogObj.MsgCache ~= nil) then
        Engine.DialogObj:formatString(Engine.DialogObj.MsgCache);
      end
    end

    if (ScreenWidth() ~= user_scr_width) then
      user_scr_width = ScreenWidth();
      if (Engine.DialogObj.MsgCache ~= nil) then
        Engine.DialogObj:formatString(Engine.DialogObj.MsgCache);
      end
    end

    Engine.DialogObj:setPosition((math.floor(ScreenWidth() / 2) - math.floor(Engine.DialogObj.DialogWidth / 2)) + math.floor(gui_width / 2), ScreenHeight() - Engine.DialogObj.DialogHeight - (ScreenHeight() >> 4));

    Engine.DialogObj:renderDialog();
  end
------------------  
	local w = ScreenWidth()
	local h = ScreenHeight()
	local guiW = GFGetGuiWidth()
	local middle = math.floor ((w)/2)
	local middle2 = math.floor((w+guiW)/2)
	local box = math.floor(h/16)
	
	
end



function OnSave(save_data)

	save_data:push_int(j1)
	save_data:push_int(j2)
	save_data:push_int(j3)
	save_data:push_int(j4)
	save_data:push_int(j5)
	save_data:push_int(j6)
	save_data:push_int(j7)
	save_data:push_int(j8)
	save_data:push_int(up)
	save_data:push_int(placedJewels)
	save_data:push_int(jewels)
	save_data:push_int(devil)
	save_data:push_int(ground)
	--Engine:saveData(save_data)
end

function OnLoad(load_data)

	--Engine:loadData(load_data)
	ground = load_data:pop_int()
	devil = load_data:pop_int()
	jewels = load_data:pop_int()
	placedJewels = load_data:pop_int()
	up = load_data:pop_int()
	j8 = load_data:pop_int()
	j7 = load_data:pop_int()
	j6 = load_data:pop_int()
	j5 = load_data:pop_int()
	j4 = load_data:pop_int()
	j3 = load_data:pop_int()
	j2 = load_data:pop_int()
	j1 = load_data:pop_int()
	
	game_loaded = true
end

import(Module_Helpers)
function OnKeyDown(key)
	if key == LB_KEY_J then
		if getShaman(0) ~= nil then
			getShaman(0).u.Pers.MaxLife = 6666 
			getShaman(0).u.Pers.Life = 6666
			getShaman(0).Flags3 = EnableFlag(getShaman(0).Flags3, TF3_BLOODLUST_ACTIVE)
		end
		change_sprite_bank(0,1)
		devil = 1
		--set_level_type(29)
		draw_sky_clr_overlay(0,-1)
	end
end
