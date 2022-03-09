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
local tribe1 = TRIBE_CYAN
local tribe2 = TRIBE_PINK
local tribe3 = TRIBE_BLACK
local tribe4 = TRIBE_ORANGE
computer_init_player(_gsi.Players[tribe1])
computer_init_player(_gsi.Players[tribe2])
computer_init_player(_gsi.Players[tribe3])
computer_init_player(_gsi.Players[tribe4])
local AItribes = {TRIBE_CYAN,TRIBE_PINK,TRIBE_BLACK,TRIBE_ORANGE}
gns.GameParams.Flags2 = gns.GameParams.Flags2 | GPF2_GAME_NO_WIN
gns.GameParams.Flags3 = gns.GameParams.Flags3 & ~GPF3_NO_GAME_OVER_PROCESS
for i = 1,7 do
	for j = 1,7 do
		set_players_allied(i,j) set_players_allied(j,i)
	end
end
for i = 2,17 do
	sti[i].AvailableSpriteIdx = 353+i
end
sti[19].AvailableSpriteIdx = 408
SearchMapCells(SQUARE, 0, 0 , 0, world_coord3d_to_map_idx(marker_to_coord3d(4)), function(me)
	me.Flags = EnableFlag(me.Flags, (1<<2))
	me.Flags = EnableFlag(me.Flags, (1<<19))
return true
end)
--
--vars
local game_loaded = false
local devil = 0
local ground = 31
local jewels = 0 --/8
local placedJewels = 0 --/8
local j1,j2,j3,j4,j5,j6,j7,j8 = 0,0,0,0,0,0,0,0
local up = 1
local devilProgress = 0
local lateSpeech = 0
local cinemaEnd = 0
local flashes = 0
local win = 0
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
	local staticJewelMk = {21,22,23,24,25,26,27}
	local possibleJewelMk = {28,29,30,31}
	local Jsprite = 1744
	for i = 1,7 do
		local idx = math.random(1,#staticJewelMk)
		local mk = staticJewelMk[idx]
		local jewel = createThing(T_EFFECT,10,8,marker_to_coord3d(mk),false,false) centre_coord3d_on_block(jewel.Pos.D3) ; set_thing_draw_info(jewel,TDI_SPRITE_F1_D1, Jsprite) 
		jewel.u.Effect.Duration = -1 ; jewel.DrawInfo.Alpha = -16 jewel.Flags2 = EnableFlag(jewel.Flags2, TF2_DONT_DRAW_IN_WORLD_VIEW)
		if mk ~= 21 or mk ~= 26 then createThing(T_EFFECT,M_EFFECT_REVEAL_FOG_AREA,8,marker_to_coord3d(mk),false,false) end
		table.remove(staticJewelMk,idx) ; Jsprite = Jsprite + 1
	end
	local jewel = createThing(T_EFFECT,10,8,marker_to_coord3d( possibleJewelMk[math.random(1,#possibleJewelMk)]),false,false) centre_coord3d_on_block(jewel.Pos.D3) ; set_thing_draw_info(jewel,TDI_SPRITE_F1_D1, Jsprite) 
	jewel.u.Effect.Duration = -1 ; jewel.DrawInfo.Alpha = -16 jewel.Flags2 = EnableFlag(jewel.Flags2, TF2_DONT_DRAW_IN_WORLD_VIEW)
	--braves
	Brave1 = createThing(T_PERSON,M_PERSON_BRAVE,0,marker_to_coord3d(39),false,false)
	Brave2 = createThing(T_PERSON,M_PERSON_BRAVE,0,marker_to_coord3d(40),false,false)
	Brave3 = createThing(T_PERSON,M_PERSON_BRAVE,0,marker_to_coord3d(41),false,false)
	Brave4 = createThing(T_PERSON,M_PERSON_BRAVE,0,marker_to_coord3d(42),false,false)
end
-------------------------------------------------------------------------------------------------------------------------------------------------
include("CSequence.lua");
local Engine = CSequence:createNew();
local dialog_msgs = {
  [0] = {"I can feel a dark mist flowing through my veins... I sense the ultimate power is close! <br> With the jewels reunited and the curse unleashed, all i have to do is neil before the gargoyle once i sacrifice my entire tribe. I must get rid of any love or compassion left in me, if i am to be worthy of this power.", "Ikani", 6881, 1, 219},
  [1] = {"To unleash the dark power upon Ikani, she must sacrifice her humanity - to do so, neil before the garoyle once all your tribe's followers are dead, and you have no completed huts. <br> (you can perform a tribal suicide ritual by sending followers to the cemetery)", "Info", 173, 0, 160},
  [2] = {"...! <br> ... Did you hear that?!... It sounded like...", "villager #1", 1769, 0, 138},
  [3] = {"The earthquakes were the first warnings... and now that scream... I fear it has happened: The curse has been unleashed, once again, after so many centuries... We failed to protect the jewels... The culprit was that intruder, the Ikani!", "villager #2", 1770, 0, 146},
  [4] = {"! <br> We are all doomed! But there is hope - the curse will be lifted and abandon the host if it senses sign of life on the planet. <br> As long as one of us is alive by the end of the hunt, Ikani will perish. ", "Preacher #1", 1771, 0, 212},
  [5] = {"Don't bother engaging, she's currently immortal and unstoppable - run... run and hide! We stand no chance at war, but time is against her.", "villager #3", 1772, 0, 175},
  [6] = {"What have you done, Ikani...", "Tiyao", 6883, 2, 146},
  [7] = {"Yesss... If i knew it felt this way, i would have killed my whole tribe long ago... Now, prepare to die.", "Dark-Ikani", 1773, 0, 216},
  [8] = {"...................... <br> ... I can still hear the sound of pulsating hearts in this world... I failed to kill every remaining living thing...", "Dark-Ikani", 1775, 0, 216},
  [9] = {"Beautiful... Not a remaining living thing in this planet... This world is mine!", "Dark-Ikani", 1773, 0, 216},
  [10] = {"About 2000 years ago, on this very planet, a tragedy took place. <br> All the community leaders gathered and planned a hunt on a villager, who was suspected of witchcraft.", "Ikani", 6881, 1, 219},
  [11] = {"They were supposed to enter her home and arrest her the following day. But the villagers, tempered in anger, disobeyed the orders and secretly went to her place, that same night, burning the house to the ground.", "Ikani", 6881, 1, 219},
  [12] = {"Little they knew at the time, for the witch was not home - but instead, all her 8 daughters, who were fated to burn on their sleep.", "Ikani", 6881, 1, 219},
  [13] = {"Once the witch arrived home and came across the ashes of her daughters, sorrow, pain and revenge took over, and she conjured a curse so powerful that all her enemies wish they were never born.", "Ikani", 6881, 1, 219},
  [14] = {"First, she forged 8 jewels from the ashes of each daughter, and scattered them around the planet, granting them eternal rest.", "Ikani", 6881, 1, 219},
  [15] = {"Then, she pacted with a god of death, who granted her ultimate powers - powers which she used to hunt and kill every person, until no one was left alive. Then, she killed herself to pay the price.", "Ikani", 6881, 1, 219},
  [16] = {"Legend says the witch will once again reincarnate, when all the 8 daughters get reunited at the cemetery - to take revenge and hunt any living creature, once again.", "Ikani", 6881, 1, 219},
  [17] = {"This tree marks the place where their house was burnt. <br> But this is just a legend - probably a tale to scare the children at night...", "Ikani", 6881, 1, 219},
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
	--screams
	if everySeconds(15 + math.random(10,25)) then
		if rnd() > 20 then
			queue_sound_event(nil, SND_EVENT_BEAMUP, SEF_FIXED_VARS)
		end
	end
	if turn() % (16-difficulty()*3) == 0 then
		if sh ~= nil then
			--remove devil progress
			if GetPop(tribe1) +  GetPop(tribe2) +  GetPop(tribe3) +  GetPop(tribe4) > 0 then devilProgress = devilProgress - 1 end
		end
	end
	if turn() % 8 == 0 then
		if sh ~= nil then
			--light strand on shaman
			if rnd() < 40 then local ls = createThing(T_EFFECT, M_EFFECT_LIGHTNING_STRAND, 0, sh.Pos.D3, false, false) ls.Pos.D3.Ypos = sh.Pos.D3.Ypos + 128 end
			--reset bloodlust and shield
			getShaman(0).u.Pers.MaxLife = 6666 
			getShaman(0).Flags3 = EnableFlag(getShaman(0).Flags3, TF3_BLOODLUST_ACTIVE)
			--getShaman(0).Flags3 = EnableFlag(getShaman(0).Flags3, TF3_SHIELD_ACTIVE) --? might be funnier without
			--nearby trees model and fire
			SearchMapCells(CIRCULAR, 0, 0, 2, world_coord3d_to_map_idx(sh.Pos.D3), function(me)
				me.MapWhoList:processList( function (t)
					if t.Type == T_SCENERY and t.DrawInfo.DrawNum > 16 and t.DrawInfo.DrawNum < 19 then
						t.DrawInfo.DrawNum = math.random(13,15)
						createThing(T_EFFECT,M_EFFECT_BURN_CELL_OBSTACLES,0,t.Pos.D3,false,false)
					end
				return true end)
			return true end)
			--refill spells (remove aod volc)
			set_player_cannot_cast(M_SPELL_ANGEL_OF_DEATH, 0) set_player_cannot_cast(M_SPELL_VOLCANO, 0) set_player_cannot_cast(M_SPELL_HYPNOTISM, 0) set_player_cannot_cast(M_SPELL_CONVERT_WILD, 0)
			createThing(T_EFFECT,M_EFFECT_FILL_ONE_SHOTS,0,marker_to_coord3d(66),false,false)
		end
	end
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
			--dark trail
			SearchMapCells(CIRCULAR, 0, 0 , 1, world_coord3d_to_map_idx(sh.Pos.D3), function(me)
				if me.ShadeIncr > -32 then
					me.ShadeIncr = me.ShadeIncr - 2
				end
			return true
			end)
		end
	end
	if sh ~= nil then
		--hyper hp regen
		if sh.u.Pers.Life < 5000 then sh.u.Pers.Life = sh.u.Pers.Life + 100 end
		if sh.State == 3 then sh.State = S_PERSON_DROWNING sh.Flags = EnableFlag(sh.Flags, TF_RESET_STATE ) sh.u.Pers.Life = 666 end
		--save from water
		if sh.State == S_PERSON_DROWNING then
			sh.Pos.D3.Ypos = 0
			SearchMapCells(CIRCULAR, 0, 0, 5, world_coord2d_to_map_idx(sh.Pos.D2), function(_me)
				if (is_map_elem_all_land(_me) > 0) then
					local land2D = Coord2D.new() ; map_ptr_to_world_coord2d(_me, land2D)
					local land3D = Coord3D.new() ; coord2D_to_coord3D(land2D,land3D)
					createThing(T_EFFECT,M_EFFECT_ORBITER,0,land3D,false,false)
					createThing(T_EFFECT,M_EFFECT_ORBITER,0,sh.Pos.D3,false,false)
					move_thing_within_mapwho(sh,land3D)
				return false end
			return true end)
		end
	end
end

function GroundDarken()
	--cemetery ground changing once all stones are set
	if turn() % 3 == 0 then
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
end

function CatchJewels()
	local sh = getShaman(0)
	if sh ~= nil then
		if IS_SHAMAN_IN_AREA(0,4,3) == 0 then
			if j1 ~= 1 and j2 ~= 1 and j3 ~= 1 and j4 ~= 1 and j5 ~= 1 and j6 ~= 1 and j7 ~= 1 and j8 ~= 1 then
				ProcessGlobalTypeList(T_EFFECT,function(Jewel)
					if Jewel.Model == 10 and Jewel.DrawInfo.DrawNum > 1743 then
						if get_world_dist_xz(sh.Pos.D2,Jewel.Pos.D2) < 256 then
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
	end
end

function MoveJewels()
	if devil == 0 then
		ProcessGlobalTypeList(T_EFFECT,function(Jewel)
			if Jewel.Model == 10 and Jewel.DrawInfo.DrawNum > 1743 then
				if rnd() > 70 then createThing(T_EFFECT,M_EFFECT_LIGHTNING_STRAND,8,Jewel.Pos.D3,false,false) end
				if up == 1 then Jewel.Pos.D3.Ypos = Jewel.Pos.D3.Ypos + 6 else Jewel.Pos.D3.Ypos = Jewel.Pos.D3.Ypos - 6 end
			end
		return true end)
		if turn() % 24 == 0 and turn() > 0 then
			if up == 0 then up = 1 else up = 0 end
		end
	end
end

function PlaceJewels()
	if devil == 0 then
		if IS_SHAMAN_IN_AREA(0,4,2) == 1 then
			ProcessGlobalTypeList(T_EFFECT,function(Jewel)
				if Jewel.Model == 10 and Jewel.DrawInfo.DrawNum == 683 then
					if j1 == 1 then move_thing_within_mapwho(Jewel,marker_to_coord3d(13)) Jewel.DrawInfo.DrawNum = 1744 j1 = 2 
					elseif j2 == 1 then move_thing_within_mapwho(Jewel,marker_to_coord3d(14)) Jewel.DrawInfo.DrawNum = 1745 j2 = 2 
					elseif j3 == 1 then move_thing_within_mapwho(Jewel,marker_to_coord3d(15)) Jewel.DrawInfo.DrawNum = 1746 j3 = 2 
					elseif j4 == 1 then move_thing_within_mapwho(Jewel,marker_to_coord3d(16)) Jewel.DrawInfo.DrawNum = 1747 j4 = 2 
					elseif j5 == 1 then move_thing_within_mapwho(Jewel,marker_to_coord3d(17)) Jewel.DrawInfo.DrawNum = 1748 j5 = 2 
					elseif j6 == 1 then move_thing_within_mapwho(Jewel,marker_to_coord3d(18)) Jewel.DrawInfo.DrawNum = 1749 j6 = 2 
					elseif j7 == 1 then move_thing_within_mapwho(Jewel,marker_to_coord3d(19)) Jewel.DrawInfo.DrawNum = 1750 j7 = 2 
					elseif j8 == 1 then move_thing_within_mapwho(Jewel,marker_to_coord3d(20)) Jewel.DrawInfo.DrawNum = 1751 j8 = 2 end
					centre_coord3d_on_block(Jewel.Pos.D3)
					createThing(T_EFFECT,M_EFFECT_EARTHQUAKE,8,marker_to_coord3d(37),false,false)
					queue_sound_event(nil, SND_EVENT_ROCK_SINK, SEF_FIXED_VARS)
				end
			return true end)
		end
	end
end

function InvokeGargoyle()
	if devil == 0 and IS_PLAYER_IN_WORLD_VIEW() == false then
		if jewels == 8 and IS_SHAMAN_IN_AREA(0,4,3) == 1 then
			if j1+j2+j3+j4+j5+j6+j7+j8 == 16 then
				createThing(T_EFFECT,M_EFFECT_EARTHQUAKE,8,marker_to_coord3d(37),false,false)
				jewels = -1
				queue_sound_event(nil, SND_EVENT_DISCOBLDG_CIRC, SEF_FIXED_VARS)
			end
		end
	end
end

function CrazyJewels()
	if jewels == -1 or jewels == -2 then
		--rise gargoyle
		if jewels == -1 then
			jewels = -2
			local a = createThing(T_SCENERY,M_SCENERY_HEAD,8,marker_to_coord3d(12),false,false) 
			a.DrawInfo.DrawNum = 21 a.AngleXZ = 666 --heheboi
		--go up one by one and disappear
		elseif jewels == -2 then
			local a = 0
			ProcessGlobalTypeList(T_EFFECT,function(Jewel)
				if Jewel.Type == T_EFFECT and Jewel.Model == 10 and Jewel.DrawInfo.DrawNum > 1743 then
					a = 1
					if Jewel.Pos.D3.Ypos < 2048 then
						Jewel.Pos.D3.Ypos = Jewel.Pos.D3.Ypos + math.floor(Jewel.Pos.D3.Ypos/4)
					else
						Jewel.u.Effect.Duration = 1
					end
					return false
				end
			return true end)
			if a == 1 and lateSpeech == 0 then
				lateSpeech = 12*6
			end
		end
	end
end

function PrayGargoyle()
	--[[if devil == 0 and IS_SHAMAN_IN_AREA(0,4,3) == 1 then
		if getShaman(0) ~= nil then
			if jewels < 0 then
				getShaman(0).State = 4
			else
				getShaman(0).State = 4
			end
		end
	end]]
end



function OnTurn() 															--log("flashes " .. flashes .. "   jewels " .. jewels)
	if turn() == 10 then
		FLYBY_CREATE_NEW()
		FLYBY_ALLOW_INTERRUPT(FALSE)

		--start
		FLYBY_SET_EVENT_POS(62, 4, 1, 144)
		FLYBY_SET_EVENT_ANGLE(250, 1, 12*4)
		
		FLYBY_SET_EVENT_POS(42, 244, 144+2, 12*8)
		FLYBY_SET_EVENT_ANGLE(215, 144+2, 12*4)
		
		FLYBY_SET_EVENT_POS(50, 242, 246, 12*6)
		FLYBY_SET_EVENT_ANGLE(1760, 246, 12*3)
		
		FLYBY_SET_EVENT_POS(38, 248, 320, 12*4)
		FLYBY_SET_EVENT_ZOOM (50,320,12*4)
		
		FLYBY_SET_EVENT_POS(40, 234, 400, 12*4)
		FLYBY_SET_EVENT_ANGLE(1600, 400, 12*2)
		
		FLYBY_SET_EVENT_POS(44, 232, 450, 12*14)
		FLYBY_SET_EVENT_ANGLE(0, 450, 12*3)
		
		FLYBY_SET_EVENT_POS(46, 230, 740, 12*3)
		FLYBY_SET_EVENT_ANGLE(1750, 740, 12*2)

		FLYBY_SET_EVENT_POS(60, 216, 800, 12*10)
		
		FLYBY_SET_EVENT_POS(62, 214, 933, 12*10)
		
		FLYBY_SET_EVENT_POS(66, 214, 1060, 12*18)
		FLYBY_SET_EVENT_ANGLE(750, 1060, 12*8)
		
		FLYBY_SET_EVENT_POS(64, 214, 1278, 12*3)
		
		FLYBY_SET_EVENT_POS(64, 216, 1316, 12*1)


		FLYBY_START()
	end
	if turn() == 54 then
		--command system stuff
		Engine:addCommand_CinemaRaise(0);
		Engine:hidePanel()
		--start of story
		Engine:addCommand_MoveThing(Brave1.ThingNum, marker_to_coord2d_centre(39), 1);
		Engine:addCommand_MoveThing(Brave2.ThingNum, marker_to_coord2d_centre(39), 1);
		Engine:addCommand_MoveThing(Brave3.ThingNum, marker_to_coord2d_centre(39), 1);
		Engine:addCommand_MoveThing(Brave4.ThingNum, marker_to_coord2d_centre(39), 1);
		Engine:addCommand_AngleThing(getShaman(0).ThingNum, 1800, 2);
		Engine:addCommand_QueueMsg(dialog_msgs[10][1], dialog_msgs[10][2], 24, false, dialog_msgs[10][3], dialog_msgs[10][4], dialog_msgs[10][5], 12*12);
		Engine:addCommand_MoveThing(Brave1.ThingNum, marker_to_coord2d_centre(32), 1);
		Engine:addCommand_MoveThing(Brave2.ThingNum, marker_to_coord2d_centre(32), 1);
		Engine:addCommand_MoveThing(Brave3.ThingNum, marker_to_coord2d_centre(32), 1);
		Engine:addCommand_MoveThing(Brave4.ThingNum, marker_to_coord2d_centre(32), 1);
		Engine:addCommand_MoveThing(getShaman(0).ThingNum, marker_to_coord2d_centre(32), 44);
		Engine:addCommand_AngleThing(getShaman(0).ThingNum, 1500, 8);
		Engine:addCommand_QueueMsg(dialog_msgs[11][1], dialog_msgs[11][2], 24, false, dialog_msgs[11][3], dialog_msgs[11][4], dialog_msgs[11][5], 12*14);
		--move people to zone2
		Engine:addCommand_MoveThing(Brave1.ThingNum, marker_to_coord2d_centre(43), 1);
		Engine:addCommand_MoveThing(Brave2.ThingNum, marker_to_coord2d_centre(43), 1);
		Engine:addCommand_MoveThing(Brave3.ThingNum, marker_to_coord2d_centre(43), 1);
		Engine:addCommand_MoveThing(Brave4.ThingNum, marker_to_coord2d_centre(43), 1);
		Engine:addCommand_MoveThing(getShaman(0).ThingNum, marker_to_coord2d_centre(44), 72);
		Engine:addCommand_QueueMsg(dialog_msgs[12][1], dialog_msgs[12][2], 24, false, dialog_msgs[12][3], dialog_msgs[12][4], dialog_msgs[12][5], 12*12);
		Engine:addCommand_AngleThing(getShaman(0).ThingNum, 1500, 6);
		Engine:addCommand_AngleThing(Brave1.ThingNum, 500, 1);
		Engine:addCommand_AngleThing(Brave2.ThingNum, 500, 1);
		Engine:addCommand_AngleThing(Brave3.ThingNum, 500, 1);
		Engine:addCommand_AngleThing(Brave4.ThingNum, 500, 3);
		Engine:addCommand_QueueMsg(dialog_msgs[13][1], dialog_msgs[13][2], 24, false, dialog_msgs[13][3], dialog_msgs[13][4], dialog_msgs[13][5], 12*14);
		--shaman moves closer alone
		Engine:addCommand_MoveThing(getShaman(0).ThingNum, marker_to_coord2d_centre(45), 6);
		Engine:addCommand_QueueMsg(dialog_msgs[14][1], dialog_msgs[14][2], 24, false, dialog_msgs[14][3], dialog_msgs[14][4], dialog_msgs[14][5], 12*5);
		Engine:addCommand_QueueMsg(dialog_msgs[15][1], dialog_msgs[15][2], 24, false, dialog_msgs[15][3], dialog_msgs[15][4], dialog_msgs[15][5], 12*20);
		Engine:addCommand_AngleThing(getShaman(0).ThingNum, 1750, 2);
		Engine:addCommand_MoveThing(Brave1.ThingNum, marker_to_coord2d_centre(33), 1);
		Engine:addCommand_MoveThing(Brave2.ThingNum, marker_to_coord2d_centre(33), 1);
		Engine:addCommand_MoveThing(Brave3.ThingNum, marker_to_coord2d_centre(33), 1);
		Engine:addCommand_MoveThing(Brave4.ThingNum, marker_to_coord2d_centre(33), 12);
		Engine:addCommand_QueueMsg(dialog_msgs[16][1], dialog_msgs[16][2], 24, false, dialog_msgs[16][3], dialog_msgs[16][4], dialog_msgs[16][5], 12*12);
		--move very close to cemetery
		Engine:addCommand_MoveThing(getShaman(0).ThingNum, marker_to_coord2d_centre(35), 6);
		Engine:addCommand_MoveThing(Brave1.ThingNum, marker_to_coord2d_centre(34), 1);
		Engine:addCommand_MoveThing(Brave2.ThingNum, marker_to_coord2d_centre(34), 1);
		Engine:addCommand_MoveThing(Brave3.ThingNum, marker_to_coord2d_centre(34), 1);
		Engine:addCommand_MoveThing(Brave4.ThingNum, marker_to_coord2d_centre(34), 36);
		Engine:addCommand_AngleThing(getShaman(0).ThingNum, 666, 4);
		Engine:addCommand_AngleThing(Brave1.ThingNum, 666, 2);
		Engine:addCommand_AngleThing(Brave2.ThingNum, 666, 5);
		Engine:addCommand_AngleThing(Brave3.ThingNum, 666, 2);
		Engine:addCommand_AngleThing(Brave4.ThingNum, 666, 3);
		Engine:addCommand_QueueMsg(dialog_msgs[17][1], dialog_msgs[17][2], 24, false, dialog_msgs[17][3], dialog_msgs[17][4], dialog_msgs[17][5], 12*10);
		Engine:addCommand_CinemaHide(16);
		Engine:addCommand_ShowPanel(12*2);
	elseif cinemaEnd == turn() and cinemaEnd ~= 0 then
		Engine:addCommand_CinemaHide(15);
		--Engine:addCommand_ShowPanel(12*2);
	elseif turn() == cinemaEnd+128 and cinemaEnd ~= 0 and devil == 0 then
		Engine:addCommand_QueueMsg(dialog_msgs[1][1], dialog_msgs[1][2], 36, false, dialog_msgs[1][3], dialog_msgs[1][4], dialog_msgs[1][5], 12*5);
	else
		Engine.DialogObj:processQueue();
		Engine:processCmd();
	end
	if game_loaded then
		game_loaded = false
		--kill honor loads
		if (difficulty() == 3) then --and turn() > honorSaveTurnLimit and honorSaveTurnLimit ~= -1 then
			ProcessGlobalSpecialList(TRIBE_BLUE, PEOPLELIST, function(t)
				damage_person(t, 8, 20000, TRUE)
				return true
			end)
			TRIGGER_LEVEL_LOST() ; SET_NO_REINC(0)
			log_msg(8,"WARNING:  You have loaded the game while playing in \"honour\" mode.")
		end
		if devil == 1 then
			--spells remove
			set_player_cannot_cast(M_SPELL_ANGEL_OF_DEATH, 0) set_player_cannot_cast(M_SPELL_VOLCANO, 0) set_player_cannot_cast(M_SPELL_HYPNOTISM, 0) set_player_cannot_cast(M_SPELL_CONVERT_WILD, 0)
			--reset devil sky, bank and spells sprites
			change_sprite_bank(0,1) ; draw_sky_clr_overlay(0,-1)
			for i = 2,17 do
				sti[i].AvailableSpriteIdx = 1750+i
			end
			sti[19].AvailableSpriteIdx = 1768
		end
	end
	if jewels == -3 then
		if flashes > turn() then
			DESELECT_ALL_PEOPLE(0)
		elseif flashes == turn() then
			jewels = -4
			devil = 1
			change_sprite_bank(0,1)
			if getShaman(0) ~= nil then
				getShaman(0).u.Pers.MaxLife = 6666 
				getShaman(0).u.Pers.Life = 6666
				getShaman(0).Flags3 = EnableFlag(getShaman(0).Flags3, TF3_BLOODLUST_ACTIVE)
				--getShaman(0).Flags3 = EnableFlag(getShaman(0).Flags3, TF3_SHIELD_ACTIVE)
			end
			local fullspells = {2,3,4,5,6,8,10,11,12,14,15,19}
			for k,v in ipairs(fullspells) do
				set_player_can_cast(v, 0)
			end
			set_player_cannot_cast(17, 0) set_player_cannot_cast(16, 0) set_player_cannot_cast(13, 0) set_player_cannot_cast(7, 0)
			devilProgress = 1024
			for i = 2,17 do
				sti[i].AvailableSpriteIdx = 1750+i
			end
			sti[19].AvailableSpriteIdx = 1768
		end
	elseif jewels == -4 and win == 0 then
		if flashes - turn() == -122 then
			Engine:addCommand_QueueMsg(dialog_msgs[2][1], dialog_msgs[2][2], 36, false, dialog_msgs[2][3], dialog_msgs[2][4], dialog_msgs[2][5], 12*2)
		end
		if flashes - turn() == -200 then
			Engine:addCommand_QueueMsg(dialog_msgs[3][1], dialog_msgs[3][2], 36, false, dialog_msgs[3][3], dialog_msgs[3][4], dialog_msgs[3][5], 12*3)
		end
		if flashes - turn() == -388 then
			Engine:addCommand_QueueMsg(dialog_msgs[4][1], dialog_msgs[4][2], 36, false, dialog_msgs[4][3], dialog_msgs[4][4], dialog_msgs[4][5], 12*5)
		end
		if flashes - turn() == -500 then
			Engine:addCommand_QueueMsg(dialog_msgs[5][1], dialog_msgs[5][2], 36, false, dialog_msgs[5][3], dialog_msgs[5][4], dialog_msgs[5][5], 12*4)
		end
		if flashes - turn() == -1400 and GetPop(4) > 0 then
			Engine:addCommand_QueueMsg(dialog_msgs[6][1], dialog_msgs[6][2], 36, false, dialog_msgs[6][3], dialog_msgs[6][4], dialog_msgs[6][5], 12*4)
		end
		if flashes - turn() == -1500 then
			Engine:addCommand_QueueMsg(dialog_msgs[7][1], dialog_msgs[7][2], 36, false, dialog_msgs[7][3], dialog_msgs[7][4], dialog_msgs[7][5], 12*4)
		end
	end
	if jewels == -2 then
		--suicide pact cemetery
		SearchMapCells(CIRCULAR, 0, 0, 2, world_coord3d_to_map_idx(marker_to_coord3d(4)), function(me)
			me.MapWhoList:processList( function (t)
				if t.Type == T_PERSON and t.Model ~= M_PERSON_MEDICINE_MAN then
					damage_person(t, 8, 100, TRUE)
				end
			return true end)
		return true end)
		--transform in devil
		if IS_SHAMAN_IN_AREA(0,4,2) == 1 and GetPop(0) == 1 then
			if _gsi.Players[0].NumBuildingsOfType[M_BUILDING_TEPEE]+_gsi.Players[0].NumBuildingsOfType[M_BUILDING_TEPEE_2]+_gsi.Players[0].NumBuildingsOfType[M_BUILDING_TEPEE_3] == 0 then
				flashes = turn() + 60
				jewels = -3
			end
		end
	end
	MoveJewels() ; PlaceJewels() ; InvokeGargoyle() ; CrazyJewels() ; PrayGargoyle()
	if lateSpeech > 2 then
		if lateSpeech == 12*6 then
			Engine:addCommand_CinemaRaise(0);
			Engine:addCommand_MoveThing(getShaman(0).ThingNum, marker_to_coord2d_centre(38), 60);
			Engine:addCommand_AngleThing(getShaman(0).ThingNum, 1333, 2);
			Engine:addCommand_QueueMsg(dialog_msgs[0][1], dialog_msgs[0][2], 36, false, dialog_msgs[0][3], dialog_msgs[0][4], dialog_msgs[0][5], 12*5);
			cinemaEnd = turn() + 12*25
			--
			FLYBY_CREATE_NEW()
			FLYBY_ALLOW_INTERRUPT(FALSE)

			--look at cemetery
			FLYBY_SET_EVENT_POS(72, 210, 1, 12*6)
			FLYBY_SET_EVENT_ANGLE(666, 1, 12*3)
			--FLYBY_SET_EVENT_ZOOM (60,48,60)
			--look at orb
			FLYBY_SET_EVENT_POS(68, 212, 12*7, 12*15)
			FLYBY_SET_EVENT_ANGLE(777, 12*7, 12*5)
			
			FLYBY_SET_EVENT_POS(66, 210, 12*7+12*15, 12*5)
			FLYBY_SET_EVENT_ANGLE(800, 12*7+12*15, 12*3)

			FLYBY_START()
		end
		lateSpeech = lateSpeech - 1 ; GroundDarken()
	elseif lateSpeech == 2 then
		GroundDarken()
	end
	
	if every2Pow(3) then
		if devil == 0 then
			CatchJewels()
		else
			if win == 0 and (GetPop(0) == 0 or devilProgress < 1) then
				win = -1 ; devilProgress = 0 ; devil = -1 
				if getShaman(0) ~= nil then
					local pit = createThing(T_EFFECT,M_EFFECT_LAVA_FLOW,8,getShaman(0).Pos.D3,false,false) centre_coord3d_on_block(pit.Pos.D3)
					getShaman(0).State = 3 --dying
				end
				queue_sound_event(nil, SND_EVENT_SHAMDIE_SWIRL, SEF_FIXED_VARS)
				TRIGGER_LEVEL_LOST()
				Engine:addCommand_QueueMsg(dialog_msgs[8][1], dialog_msgs[8][2], 66, false, dialog_msgs[8][3], dialog_msgs[8][4], dialog_msgs[8][5], 12*4)
			else
				if GetPop(4) + GetPop(5) + GetPop(6) + GetPop(7) == 0 then
					if win == 0 then
						win = 1
						WIN()
						Engine:addCommand_QueueMsg(dialog_msgs[9][1], dialog_msgs[9][2], 66, false, dialog_msgs[9][3], dialog_msgs[9][4], dialog_msgs[9][5], 12*4)
					end
				end
			end
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
	
	if devil == 1 and win == 0 then
		if t.Type == T_EFFECT and t.Model == 30 then
			t.DrawInfo.Alpha = 3
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
	local box = math.floor(h/20)
	local box2 = math.floor(h/26)
	local offset = 8
	local b2 = math.floor(box2/2)
	
	--flashes
	if jewels == -3 then
		local t = flashes - turn()
		if t == 58 then DrawBox(0,0,w,h,1) end
		if t == 46 then DrawBox(0,0,w,h,1) end
		if t == 34 or t == 22 or t == 16 or t == 10 then DrawBox(0,0,w,h,1) end
		if t == 2 then queue_sound_event(nil, SND_EVENT_BEAMDOWN, SEF_FIXED_VARS) end --demon scream
		if t < 4 then DrawBox(0,0,w,h,1) end
	elseif jewels == -4 then
		if flashes - turn() > -36 then
			DrawBox(0,0,w,h,1)
		elseif flashes - turn() == -60 then
			draw_sky_clr_overlay(0,-1)
		end
	end
	if devil == 0 then
		--collected
			if jewels > -2 then
			if j1 > 0 then LbDraw_ScaledSprite(guiW+4+(box*0)+(offset*0),4,get_sprite(0,1744),box,box) end
			if j2 > 0 then LbDraw_ScaledSprite(guiW+4+(box*1)+(offset*1),4,get_sprite(0,1745),box,box) end
			if j3 > 0 then LbDraw_ScaledSprite(guiW+4+(box*2)+(offset*2),4,get_sprite(0,1746),box,box) end
			if j4 > 0 then LbDraw_ScaledSprite(guiW+4+(box*3)+(offset*3),4,get_sprite(0,1747),box,box) end
			if j5 > 0 then LbDraw_ScaledSprite(guiW+4+(box*4)+(offset*4),4,get_sprite(0,1748),box,box) end
			if j6 > 0 then LbDraw_ScaledSprite(guiW+4+(box*5)+(offset*5),4,get_sprite(0,1749),box,box) end
			if j7 > 0 then LbDraw_ScaledSprite(guiW+4+(box*6)+(offset*6),4,get_sprite(0,1750),box,box) end
			if j8 > 0 then LbDraw_ScaledSprite(guiW+4+(box*7)+(offset*7),4,get_sprite(0,1751),box,box) end
			--placed
			if j1 > 1 then LbDraw_ScaledSprite(guiW+4+(box*0)+(offset*0)+b2,4+b2,get_sprite(0,38),box2,box2) end
			if j2 > 1 then LbDraw_ScaledSprite(guiW+4+(box*1)+(offset*1)+b2,4+b2,get_sprite(0,38),box2,box2) end
			if j3 > 1 then LbDraw_ScaledSprite(guiW+4+(box*2)+(offset*2)+b2,4+b2,get_sprite(0,38),box2,box2) end
			if j4 > 1 then LbDraw_ScaledSprite(guiW+4+(box*3)+(offset*3)+b2,4+b2,get_sprite(0,38),box2,box2) end
			if j5 > 1 then LbDraw_ScaledSprite(guiW+4+(box*4)+(offset*4)+b2,4+b2,get_sprite(0,38),box2,box2) end
			if j6 > 1 then LbDraw_ScaledSprite(guiW+4+(box*5)+(offset*5)+b2,4+b2,get_sprite(0,38),box2,box2) end
			if j7 > 1 then LbDraw_ScaledSprite(guiW+4+(box*6)+(offset*6)+b2,4+b2,get_sprite(0,38),box2,box2) end
			if j8 > 1 then LbDraw_ScaledSprite(guiW+4+(box*7)+(offset*7)+b2,4+b2,get_sprite(0,38),box2,box2) end
		end
	elseif devil == 1 then
		--devil progress
		local barLen = math.floor(w/3)
		local barThickness = math.floor(h/32)
		local percent = math.floor((devilProgress * 100)/1024)
		local barpercent = math.floor((barLen * percent) / 100)
		DrawBox(guiW + 16-1,h-4-barThickness-1,barLen+2,barThickness+2,0)
		DrawBox(guiW + 16,h-4-barThickness,barLen,barThickness,4)
		DrawBox(guiW + 16,h-4-barThickness,barpercent,barThickness,1)
		LbDraw_ScaledSprite(guiW + 2,h-4-barThickness-math.floor(box2/1.5),get_sprite(1,math.random(7119,7131)),box2,box2)
	end
end


function OnSave(save_data)
	save_data:push_int(win)
	save_data:push_int(flashes)
	save_data:push_int(cinemaEnd)
	save_data:push_int(lateSpeech)
	save_data:push_int(devilProgress)
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
	Engine:saveData(save_data)
end

function OnLoad(load_data)

	Engine:loadData(load_data)
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
	devilProgress = load_data:pop_int()
	lateSpeech = load_data:pop_int()
	cinemaEnd = load_data:pop_int()
	flashes = load_data:pop_int()
	win = load_data:pop_int()
	
	game_loaded = true
end

import(Module_Helpers)
function OnKeyDown(key)
	if key == LB_KEY_J then
		devil = 1 devilProgress = 1024
	end
	if key == LB_KEY_1 then
		LOG("hi")
	end
end
