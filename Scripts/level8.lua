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
bti = building_type_info()
ency = encyclopedia_info()
ency[27].StrId = 1010
ency[32].StrId = 1015
ency[22].StrId = 1005
include("assets.lua")
--------------------
sti[M_SPELL_GHOST_ARMY].Active = SPAC_OFF
sti[M_SPELL_GHOST_ARMY].NetworkOnly = 1
local balm = M_SPELL_INVISIBILITY --(healing balm): units in a 3x3 area get healed for 1/3 their max hp
local seed = M_SPELL_SWAMP --(seed of life): casts a seed that rises a tree and creates a wildman
--sti[balm].Cost = 10000
sti[balm].OneOffMaximum = 3
sti[balm].WorldCoordRange = 4096
sti[balm].CursorSpriteNum = 162
sti[balm].ToolTipStrIdx = 687
sti[balm].AvailableSpriteIdx = 1776
sti[balm].NotAvailableSpriteIdx = 1780
sti[balm].ClickedSpriteIdx = 1778
--sti[seed].Cost = 10000
sti[seed].OneOffMaximum = 2
sti[seed].WorldCoordRange = 2048+1024
sti[seed].CursorSpriteNum = 163
sti[seed].ToolTipStrIdx = 688
sti[seed].AvailableSpriteIdx = 1777
sti[seed].NotAvailableSpriteIdx = 1781
sti[seed].ClickedSpriteIdx = 1779
bti[M_BUILDING_SPY_TRAIN].ToolTipStrId2 = 641
--------------------
local player = TRIBE_ORANGE
local tribe1 = TRIBE_YELLOW
computer_init_player(_gsi.Players[tribe1]) 
computer_init_player(_gsi.Players[4])
local AItribes = {TRIBE_YELLOW}
--
local balmCDR = -1
local seedCDR = -1
local balmC3D = 0
local seedC3D = 0
local replace1 = -1
local replace2 = -1
local bard = 0
local game_loaded = false
local honorSaveTurnLimit = 1600 +12*20
local gameStage = 0
local lbLock = 0
local BardLives = 2--6-difficulty()
local livesLock = 0
local removeHut = -1
if turn() == 0 then
	set_player_reinc_site_off(getPlayer(4))
	Csh = createThing(T_PERSON,M_PERSON_MEDICINE_MAN,4,marker_to_coord3d(16),false,false)
	local fireplace = createThing(T_EFFECT,M_EFFECT_FIRESTORM_SMOKE,8,marker_to_coord3d(2),false,false) fireplace.DrawInfo.Alpha = 1 centre_coord3d_on_block(fireplace.Pos.D3)
	local bf = createThing(T_EFFECT,M_EFFECT_BIG_FIRE,8,marker_to_coord3d(2),false,false) bf.u.Effect.Duration = -1 centre_coord3d_on_block(bf.Pos.D3)
end
--atk turns
tribe1Atk1 = 5700 + math.random(3333) - difficulty()*250
tribe1MiniAtk1 = 3800 - difficulty()*50
tribe1AtkSpells = {M_SPELL_LIGHTNING_BOLT,M_SPELL_INSECT_PLAGUE,M_SPELL_HYPNOTISM,M_SPELL_WHIRLWIND}
tribe1NavStress = 0

botSpells = {M_SPELL_CONVERT_WILD,
             M_SPELL_BLAST,
             M_SPELL_LAND_BRIDGE,
             M_SPELL_LIGHTNING_BOLT,
             M_SPELL_INSECT_PLAGUE,
             M_SPELL_INVISIBILITY,
             --M_SPELL_GHOST_ARMY,
             --M_SPELL_SWAMP,
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
set_players_allied(7,4) set_players_allied(4,7)
--
-------------------------------------------------------------------------------------------------------------------------------------------------
include("CSequence.lua");
local Engine = CSequence:createNew();
local dialog_msgs = {
  [0] = {"This planet looks dull. <br> Are you sure this is this the place, Tiyao?", "Nomel", 6939, 2, 138},
  [1] = {"It is, indeed. You must be congratulated. You are about to unlock your shaman type. <br> There are plenty you could have picked from, but your decision was to become... a bard.", "Tiyao", 6883, 2, 146},
  [2] = {"Interesting choice, i must say. Bards are powerful in their own ways - lovers of nature, they manipulate the mana to create and restore life.", "Tiyao", 6883, 2, 146},
  [3] = {"Thank you, Tiyao! It is the wish of my inner self to connect to the earth, and all its living things.", "Nomel", 6939, 2, 138},
  [4] = {"I must go now. Your trials as a bard begin here. I wish you all the best.", "Tiyao", 6883, 2, 146},
  [5] = {"...", "Nomel", 6939, 2, 138},
  [6] = {"Free your mind, and empty your soul. <br> The path of the bard is a honourable one!", "Echoed Voice", 1783, 0, 225},
  [7] = {"You will be facing the Chumara tribe on this trial. I shall aid you with some bard spells, once you leave two of your own behind.", "Echoed Voice", 1783, 0, 225},
  --[8] = {"Cast any two spells - they will permanently leave your arsenal. You won't be able to use them on this trial. <br> It might be a good idea to not get rid of the convert spell. <br> (cast any spell, they will not trigger)", "Info", 173, 0, 160},
  [9] = {"Interesting... I shall concede you the status of bard. <br> And if you get out of this trial alive, I shall concede you with the rest of the knowledge and magic.", "Echoed Voice", 1783, 0, 225},
  [10] = {"Bards are powerful, but very susceptible to death. Your shaman will only reincarnate as long as you have lives left. <br> However, it is not mandatory to finish this trial with your shaman alive. <br> Notice your shaman lives at the top left corner.", "Info", 173, 0, 160},
  [11] = {"Bards have a strong connection with the earth. Although they can not charge land spells with mana, killing enemies will eventually earn the shaman free shots of this spells.", "Info", 173, 0, 160},
  [12] = {"Your other spell is the healing balm. <br> Cast it on your units (3x3 area) to heal them for 1/3 of their maximum health!", "Info", 173, 0, 160},
}
--for scaling purposes
local user_scr_height = ScreenHeight();
local user_scr_width = ScreenWidth();
if (user_scr_height > 600) then
  Engine.DialogObj:setFont(3);
end
-------------------------------------------------------------------------------------------------------------------------------------------------

function BalmSpell(pn,c3d)
	if balmC3D ~= nil then
		local a = 0
		SearchMapCells(SQUARE ,0, 0, 1, world_coord3d_to_map_idx(c3d), function(me)
			local cloud = createThing(T_EFFECT,M_EFFECT_SMOKE_CLOUD,8,c3d,false,false) centre_coord3d_on_block(cloud.Pos.D3)
			cloud.u.Effect.Duration = 12*1 ; --cloud.DrawInfo.Alpha = 3
			me.MapWhoList:processList( function (h)
				if (h.Owner == pn) and (h.Type == T_PERSON) and (h.Model < 8) and (h.u.Pers.Life < h.u.Pers.MaxLife) then
					if h.u.Pers.Life > 0 then
						local hp = h.u.Pers.Life
						local give = math.floor(h.u.Pers.MaxLife/3)
						if hp + give > h.u.Pers.MaxLife then
							h.u.Pers.Life = h.u.Pers.MaxLife
							a = 1
						else
							h.u.Pers.Life = hp + give
							a = 1
						end
						local sp = createThing(T_EFFECT,60,8,h.Pos.D3,false,false) centre_coord3d_on_block(sp.Pos.D3) sp.u.Effect.Duration = 12
					end
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
				createThing(T_EFFECT,M_EFFECT_WW_DUST,8,c3d,false,false)
				if is_map_cell_obstacle_free(world_coord3d_to_map_idx(c3d)) == 1 and is_cell_too_steep_for_building(world_coord3d_to_map_idx(c3d),4) == 0 then
					if is_building_on_map_cell(world_coord3d_to_map_idx(c3d)) == 0 and me.ShapeOrBldgIdx:isNull() then
						if is_map_cell_a_building_belonging_to_player(world_coord3d_to_map_idx(c3d),player) == 0 and is_map_cell_a_building_belonging_to_player(world_coord3d_to_map_idx(c3d),3) == 0 then
							local a = 0
							me.MapWhoList:processList(function(t)
								if t.Type == T_SCENERY then
									a = 1
								end
							return true end)
							if a == 0 then
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
	if game_loaded then
		game_loaded = false
	end
	if turn() == 10 then
		--[[FLYBY_CREATE_NEW()
		FLYBY_ALLOW_INTERRUPT(FALSE)

		--start
		FLYBY_SET_EVENT_POS(30, 224, 1, 70)
		FLYBY_SET_EVENT_ANGLE(500, 1, 40)
		
		FLYBY_SET_EVENT_POS(48, 224, 82, 100)
		
		FLYBY_SET_EVENT_POS(50, 214, 200, 140)
		FLYBY_SET_EVENT_ANGLE(800, 200, 50)
		
		FLYBY_SET_EVENT_POS(42, 218, 360, 120)
		FLYBY_SET_EVENT_ANGLE(1500, 360, 50)
		
		FLYBY_SET_EVENT_POS(40, 214, 400, 140)
		FLYBY_SET_EVENT_ANGLE(1000, 400, 50)
		
		FLYBY_SET_EVENT_POS(44, 206, 560, 100)
		FLYBY_SET_EVENT_ZOOM (-50,560,72)
			
		FLYBY_SET_EVENT_POS(38, 236, 670, 30)
		FLYBY_SET_EVENT_ANGLE(0, 670, 24)
		FLYBY_SET_EVENT_ZOOM (-10,670,24)
		
		FLYBY_SET_EVENT_POS(20, 254, 710, 200)
		FLYBY_SET_EVENT_ANGLE(0, 710, 40)
		
		FLYBY_SET_EVENT_POS(20, 4, 920, 100)
		
		FLYBY_SET_EVENT_POS(20, 250, 1030, 10)
		--
		
		FLYBY_START()]]
		DEFEND_SHAMEN(4,2)
	end
	if turn() == 24 then
		--Engine:hidePanel()
		--Engine:addCommand_CinemaRaise(0)
		Engine:addCommand_AngleThing(getShaman(4).ThingNum, 1500, 36);
		Engine:addCommand_QueueMsg(dialog_msgs[0][1], dialog_msgs[0][2], 24, false, dialog_msgs[0][3], dialog_msgs[0][4], dialog_msgs[0][5], 12*1);
		Engine:addCommand_MoveThing(getShaman(4).ThingNum, marker_to_coord2d_centre(21), 1);
		Engine:addCommand_AngleThing(getShaman(4).ThingNum, 1500, 30);
		Engine:addCommand_MoveThing(getShaman(player).ThingNum, marker_to_coord2d_centre(22), 12);
		Engine:addCommand_QueueMsg(dialog_msgs[1][1], dialog_msgs[1][2], 24, false, dialog_msgs[1][3], dialog_msgs[1][4], dialog_msgs[1][5], 1);
		Engine:addCommand_MoveThing(getShaman(4).ThingNum, marker_to_coord2d_centre(23), 84);
		Engine:addCommand_MoveThing(getShaman(4).ThingNum, marker_to_coord2d_centre(24), 36);
		Engine:addCommand_AngleThing(getShaman(4).ThingNum, 1600, 2);
		Engine:addCommand_QueueMsg(dialog_msgs[2][1], dialog_msgs[2][2], 24, false, dialog_msgs[2][3], dialog_msgs[2][4], dialog_msgs[2][5], 8);
		Engine:addCommand_AngleThing(getShaman(player).ThingNum, 600, 24);
		Engine:addCommand_AngleThing(getShaman(4).ThingNum, 1650, 36);
		Engine:addCommand_MoveThing(getShaman(4).ThingNum, marker_to_coord2d_centre(25), 108);
		Engine:addCommand_AngleThing(getShaman(player).ThingNum, 1100, 12);
		Engine:addCommand_AngleThing(getShaman(player).ThingNum, 1800, 8);
		Engine:addCommand_AngleThing(getShaman(player).ThingNum, 600, 4);
		Engine:addCommand_QueueMsg(dialog_msgs[3][1], dialog_msgs[3][2], 24, false, dialog_msgs[3][3], dialog_msgs[3][4], dialog_msgs[3][5], 60);
		Engine:addCommand_QueueMsg(dialog_msgs[4][1], dialog_msgs[4][2], 24, false, dialog_msgs[4][3], dialog_msgs[4][4], dialog_msgs[4][5], 120);
		Engine:addCommand_MoveThing(getShaman(4).ThingNum, marker_to_coord2d_centre(27), 64);
		Engine:addCommand_AngleThing(getShaman(4).ThingNum, 1880, 24);
		Engine:addCommand_AngleThing(getShaman(4).ThingNum, 750, 38);
		Engine:addCommand_QueueMsg(dialog_msgs[5][1], dialog_msgs[5][2], 24, false, dialog_msgs[5][3], dialog_msgs[5][4], dialog_msgs[5][5], 28);
		--front of bard's hut
		Engine:addCommand_MoveThing(getShaman(player).ThingNum, marker_to_coord2d_centre(5), 118);
		Engine:addCommand_AngleThing(getShaman(player).ThingNum, 0, 12);
		Engine:addCommand_QueueMsg(dialog_msgs[5][1], dialog_msgs[5][2], 12, false, dialog_msgs[5][3], dialog_msgs[5][4], dialog_msgs[5][5], 16);
		--inside hut
		Engine:addCommand_MoveThing(getShaman(player).ThingNum, marker_to_coord2d_centre(30), 48);
		Engine:addCommand_QueueMsg(dialog_msgs[6][1], dialog_msgs[6][2], 36, false, dialog_msgs[6][3], dialog_msgs[6][4], dialog_msgs[6][5], 16);
		Engine:addCommand_QueueMsg(dialog_msgs[7][1], dialog_msgs[7][2], 36, false, dialog_msgs[7][3], dialog_msgs[7][4], dialog_msgs[7][5], 180);
		Engine:addCommand_CinemaHide(1);
		Engine:addCommand_ShowPanel(1);
		Engine:addCommand_MoveThing(getShaman(player).ThingNum, marker_to_coord2d_centre(10), 72);
		--Engine:addCommand_QueueMsg(dialog_msgs[8][1], dialog_msgs[8][2], 256, true, dialog_msgs[8][3], dialog_msgs[8][4], dialog_msgs[8][5], 16);
	else
		Engine.DialogObj:processQueue();
		Engine:processCmd();
	end
	if turn() == 740 then
		createThing(T_EFFECT,M_EFFECT_ORBITER,8,getShaman(4).Pos.D3,false,false)
		delete_thing_type(getShaman(4))
		queue_sound_event(nil,SND_EVENT_HYPNOTISE, SEF_FIXED_VARS)
	elseif turn() == 752 then
		local a = 0
		ProcessGlobalSpecialList(TRIBE_CYAN, PEOPLELIST, function(t)
			if a == 0 then
				createThing(T_EFFECT,M_EFFECT_ORBITER,8,t.Pos.D3,false,false)
				delete_thing_type(t)
				queue_sound_event(nil,SND_EVENT_HYPNOTISE, SEF_FIXED_VARS)
				a = 1
			end
		return true end)
	elseif turn() == 760 then
		local a = 0
		ProcessGlobalSpecialList(TRIBE_CYAN, PEOPLELIST, function(t)
			if a == 0 then
				createThing(T_EFFECT,M_EFFECT_ORBITER,8,t.Pos.D3,false,false)
				delete_thing_type(t)
				queue_sound_event(nil,SND_EVENT_HYPNOTISE, SEF_FIXED_VARS)
				a = 1
			end
		return true end)
	elseif turn() == 960 then
		queue_sound_event(nil,SND_EVENT_BLDG_ROTATE, SEF_FIXED_VARS)
	elseif turn() == 1217 then
		queue_sound_event(nil,SND_EVENT_BLDG_ROTATE, SEF_FIXED_VARS)
		local t = {2,3,4,5,7,8,10,13,14,16,17,19}
		for i = 1,#t do
			GIVE_ONE_SHOT(t[i],player)
		end
		bard = 1
	elseif turn() == 1230 then
		ms_script_create_msg_information(693)
		SET_MSG_AUTO_OPEN_DLG()
	end
	--remove bard hut and smokes
	if turn() == removeHut then
		createThing(T_EFFECT,M_EFFECT_EARTHQUAKE,8,marker_to_coord3d(1),false,false)
		for i = 2,15 do
			createThing(T_EFFECT,M_EFFECT_SMOKE_CLOUD_CONSTANT,8,marker_to_coord3d(i),false,false)
			createThing(T_EFFECT,M_EFFECT_SMOKE_CLOUD,8,marker_to_coord3d(i),false,false)
		end
		DELETE_SMOKE_STUFF(24, 244,0)
		SearchMapCells(SQUARE, 0, 0, 1, world_coord3d_to_map_idx(marker_to_coord3d(3)), function(me)
			me.MapWhoList:processList( function (t)
				if t.Type ~= T_PERSON then
					delete_thing_type(t)
				end
			return true end)
		return true end)
		createThing(T_EFFECT,M_EFFECT_BLDG_DAMAGED_SMOKE,8,marker_to_coord3d(2),false,false)
	end
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
			SearchMapCells(CIRCULAR, 0, 0, 1, world_coord3d_to_map_idx(t.Pos.D3), function(me)
				me.MapWhoList:processList( function (h)
					if h.Type == T_SCENERY and h.Model < 7 then
						local dist = get_world_dist_xz(t.Pos.D2,h.Pos.D2) 
						if dist < 256 then
							local s = h.u.ObjectInfo.Scale
							if s+4 < 160 then h.u.ObjectInfo.Scale = s+1 else h.u.ObjectInfo.Scale = 160 end
							local s = h.u.ObjectInfo.Scale
							if s <= 40 then h.u.Scenery.ResourceRemaining = 100 elseif s <= 80 then h.u.Scenery.ResourceRemaining = 200 elseif h.u.Scenery.ResourceRemaining <= 120 then h.u.Scenery.ResourceRemaining = 300 else h.u.Scenery.ResourceRemaining = 400 end
							if s > 155 and s < 160 then
								queue_sound_event(nil,SND_EVENT_BIRTH, SEF_FIXED_VARS)
								local g = createThing(T_EFFECT,59,8,h.Pos.D3,false,false) g.DrawInfo.Alpha = 1
								createThing(T_PERSON,M_PERSON_WILD,8,h.Pos.D3,false,false)
								FIX_WILD_IN_AREA(ThingX(h),ThingZ(h),2)
							end
						end
					end
				return true end)
			return true end)
		end
	return true end)
	
	if every2Pow(4) then
		--remove seed flash
		if _gsi.Players[player].SpellsCast[seed] > 0 and _gsi.Players[player].SpellsCast[seed] < 3 then
			FLASH_BUTTON(27,0)
		end
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
	
	if every2Pow(3) then
		--remove a bard life
		if getShaman(player) == nil and livesLock == 0 then
			BardLives = BardLives - 1
			livesLock = 1
			if BardLives == 1 then	
				SET_NO_REINC(player)
			elseif BardLives == 0 then
				SearchMapCells(CIRCULAR, 0, 0 , 3, world_coord3d_to_map_idx(marker_to_coord3d(32)), function(me)
						me.Flags = me.Flags | (1<<16)
				return true
				end)
				ms_script_create_msg_information(694)
				SET_MSG_AUTO_OPEN_DLG()
			end
		elseif  getShaman(player) ~= nil and livesLock == 1 then
			livesLock = 0
		end
	end
	
	if every2Pow(2) then
		--bard earns lbs/flattens by killing enemies
		if _gsi.Players[player].PeopleKilled[tribe1] % (12+difficulty()*3+gameStage*3) == 0 and lbLock ~= _gsi.Players[player].PeopleKilled[tribe1] then
			lbLock = _gsi.Players[player].PeopleKilled[tribe1]
			local get,maxx = M_SPELL_LAND_BRIDGE,4
			if rnd() > 70 then get = M_SPELL_FLATTEN maxx = 3 end
			local shots = GET_NUM_ONE_OFF_SPELLS(player,get)
			if shots < maxx then
				_gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[get] = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[get] & 240
				_gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[get] = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[get] | shots+1
				queue_sound_event(nil,SND_EVENT_DISCOBLDG_START, SEF_FIXED_VARS)
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
	local box = math.floor(h/24)
	local offset = 8
	
	--bard lives
	if BardLives > 0 and bard > 2 then
		for i = 1,BardLives do
			LbDraw_ScaledSprite(guiW+((i-1)*4)+((i-1)*box),4,get_sprite(0,1782),box,box)
		end
	end
	
end


function OnCreateThing(t)
	--2 new spells
	if bard > 0 and bard < 3 then
		if (t.Type == T_SPELL) then
			if bard == 1 then replace1 = t.Model else replace2 = t.Model end
			local g = createThing(T_EFFECT,M_EFFECT_ORBITER,8,t.Pos.D3,false,false)
			if getShaman(player) ~= nil then
				createThing(T_EFFECT,58,8,getShaman(player).Pos.D3,false,false)
			end
			set_player_cannot_cast(t.Model, player)
			bard = bard+1
			queue_sound_event(nil,SND_EVENT_DISCOVERY_END, SEF_FIXED_VARS)
			if bard == 3 then
				createThing(T_EFFECT,M_EFFECT_EARTHQUAKE,8,marker_to_coord3d(1),false,false)
				Engine:addCommand_QueueMsg(dialog_msgs[9][1], dialog_msgs[9][2], 36, false, dialog_msgs[9][3], dialog_msgs[9][4], dialog_msgs[9][5], 512);
				Engine:addCommand_QueueMsg(dialog_msgs[10][1], dialog_msgs[10][2], 36, false, dialog_msgs[10][3], dialog_msgs[10][4], dialog_msgs[10][5], 512);
				Engine:addCommand_QueueMsg(dialog_msgs[12][1], dialog_msgs[12][2], 36, false, dialog_msgs[12][3], dialog_msgs[12][4], dialog_msgs[12][5], 1024);
				Engine:addCommand_QueueMsg(dialog_msgs[11][1], dialog_msgs[11][2], 36, false, dialog_msgs[11][3], dialog_msgs[11][4], dialog_msgs[11][5], 12);
				removeHut = turn() + 12*12
				local t = {2,3,4,5,7,8,10,13,14,16,17,19}
				for i = 1,#t do
					if t[i] ~= replace1 and t[i] ~= replace2 then
						set_player_can_cast(t[i],player)
						if t[i] == 17 then
							_gsi.ThisLevelInfo.PlayerThings[player].SpellsNotCharging = DisableFlag(_gsi.ThisLevelInfo.PlayerThings[player].SpellsNotCharging, (1 << (t[i] - 1)))
						else
							_gsi.ThisLevelInfo.PlayerThings[player].SpellsNotCharging = EnableFlag(_gsi.ThisLevelInfo.PlayerThings[player].SpellsNotCharging, (1 << (t[i] - 1)))
						end
					end
				end
				local t = {2,3,4,5,7,8,10,13,14,16,17,19}
				for i = 1,#t do
					if t[i] ~= 17 then
						_gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[t[i]] = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[t[i]] & 240
						_gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[t[i]] = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[t[i]] | 0
					end
				end
			end
		end
	end
	--healing balm (invisibility)
	if t.Owner == player then
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
end


function OnSoundEvent(t_thing, event, flags) 
  if (event == SND_EVENT_SHAM_INVIS) or (event == SND_EVENT_SHAM_SWAMP) then
    --log_msg(8, string.format("Event: %i, Flags: %i", event, flags))
    return 1
  end
end


function OnSave(save_data)
	for i = #tribe1AtkSpells, 1 do
		save_data:push_int(tribe1AtkSpells[i])
	end
	save_data:push_int(#tribe1AtkSpells)
	
	save_data:push_int(livesLock)
	save_data:push_int(removeHut)
	save_data:push_int(BardLives)
	save_data:push_int(lbLock)
	save_data:push_int(honorSaveTurnLimit)
	save_data:push_int(gameStage)
	save_data:push_int(tribe1Atk1)
	save_data:push_int(tribe1MiniAtk1)
	save_data:push_int(tribe1NavStress)
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
	tribe1NavStress = load_data:pop_int()
	tribe1MiniAtk1 = load_data:pop_int()
	tribe1Atk1 = load_data:pop_int()
	gameStage = load_data:pop_int()
	honorSaveTurnLimit = load_data:pop_int()
	lbLock = load_data:pop_int()
	BardLives = load_data:pop_int()
	removeHut = load_data:pop_int()
	livesLock = load_data:pop_int()
	
	local numSpellsAtk1 = load_data:pop_int();
	for i = 1, numSpellsAtk1 do
		 tribe1AtkSpells[i] = load_data:pop_int();
	end
end

import(Module_Helpers)
function OnKeyDown(k)
    if (k == LB_KEY_1) then
		
	end
	if k == LB_KEY_A then
		--queue_sound_event(nil,SND_EVENT_DISCOBLDG_START, SEF_FIXED_VARS)
		--DEFEND_SHAMEN(4,1)
	end
end