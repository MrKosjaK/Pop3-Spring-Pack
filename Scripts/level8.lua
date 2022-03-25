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
import(Module_Helpers)
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
ency[35].StrId = 695
ency[38].StrId = 696
include("assets.lua")
gns.GameParams.Flags3 = gns.GameParams.Flags3 | GPF3_FOG_OF_WAR_KEEP_STATE
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
sti[M_SPELL_EROSION].Cost = 250000
sti[M_SPELL_EROSION].CursorSpriteNum = 50
sti[M_SPELL_EROSION].ToolTipStrIdx = 822
sti[M_SPELL_EROSION].AvailableSpriteIdx = 363
sti[M_SPELL_EROSION].NotAvailableSpriteIdx = 381
sti[M_SPELL_EROSION].ClickedSpriteIdx = 399
sti[M_SPELL_VOLCANO].Cost = 800000
sti[M_SPELL_VOLCANO].WorldCoordRange = 3072
sti[M_SPELL_VOLCANO].CursorSpriteNum = 56
sti[M_SPELL_VOLCANO].ToolTipStrIdx = 828
sti[M_SPELL_VOLCANO].AvailableSpriteIdx = 369
sti[M_SPELL_VOLCANO].NotAvailableSpriteIdx = 387
sti[M_SPELL_VOLCANO].ClickedSpriteIdx = 405
set_correct_gui_menu()
--------------------
local player = TRIBE_ORANGE
local tribe1 = TRIBE_YELLOW
computer_init_player(_gsi.Players[tribe1]) 
computer_init_player(_gsi.Players[4])
local AItribes = {TRIBE_YELLOW}
--
local balmCDR = -1
local seedCDR = -1
local balmC3D = marker_to_coord3d(0)
local seedC3D = marker_to_coord3d(0)
local replace1 = -1
local replace2 = -1
local bard = 0
local game_loaded = false
local honorSaveTurnLimit = 0
local gameStage = 0
local lbLock = 0
local BardLives = 6-difficulty()
local livesLock = 0
local removeHut = -1
if turn() == 0 then
	set_player_reinc_site_off(getPlayer(4))
	Csh = createThing(T_PERSON,M_PERSON_MEDICINE_MAN,4,marker_to_coord3d(16),false,false)
	local fireplace = createThing(T_EFFECT,M_EFFECT_FIRESTORM_SMOKE,8,marker_to_coord3d(2),false,false) fireplace.DrawInfo.Alpha = 1 centre_coord3d_on_block(fireplace.Pos.D3)
	local bf = createThing(T_EFFECT,M_EFFECT_BIG_FIRE,8,marker_to_coord3d(2),false,false) bf.u.Effect.Duration = -1 centre_coord3d_on_block(bf.Pos.D3)
	bf.Pos.D3.Ypos = bf.Pos.D3.Ypos - 2 ;	 bf.Pos.D3.Xpos = 6404
	ProcessGlobalTypeList(T_SCENERY, function(t)
		if t.Model == M_SCENERY_WOOD_PILE then
			t.DrawInfo.Flags = t.DrawInfo.Flags ~ DF_USE_ENGINE_SHADOW
		end
	return true end)
	for i = 40,59-difficulty()*3 do
		createThing(T_SCENERY,M_SCENERY_WOOD_PILE,8,marker_to_coord3d(i),false,false)
	end
	--fog reveals
	for i = 79,109 do
		if i <= 82 and difficulty() == 3 then createThing(T_EFFECT,M_EFFECT_REVEAL_FOG_AREA,8,marker_to_coord3d(i),false,false)
		elseif i <= 87 and difficulty() == 2 then createThing(T_EFFECT,M_EFFECT_REVEAL_FOG_AREA,8,marker_to_coord3d(i),false,false)
		elseif i <= 98 and difficulty() == 1 then createThing(T_EFFECT,M_EFFECT_REVEAL_FOG_AREA,8,marker_to_coord3d(i),false,false)
		elseif i <= 109 and difficulty() == 0 then createThing(T_EFFECT,M_EFFECT_REVEAL_FOG_AREA,8,marker_to_coord3d(i),false,false) end
	end
end
--atk turns
tribe1Atk1 = 1400 + 7000 + math.random(800) - difficulty()*500
tribe1MiniAtk1 = 1400 + 4000 - difficulty()*250
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
if difficulty() > 1 then
	TARGET_PLAYER_DT_AND_S(tribe1,player)
    TARGET_DRUM_TOWERS(tribe1)
end
for i = 2,3 do
	WRITE_CP_ATTRIB(i, ATTR_EXPANSION, 16)
	WRITE_CP_ATTRIB(i, ATTR_HOUSE_PERCENTAGE, 80+G_RANDOM(30))
	WRITE_CP_ATTRIB(i, ATTR_MAX_BUILDINGS_ON_GO, 3+G_RANDOM(1))
	STATE_SET(i, TRUE, CP_AT_TYPE_BRING_NEW_PEOPLE_BACK)
	STATE_SET(i, TRUE, CP_AT_TYPE_HOUSE_A_PERSON)
	STATE_SET(i, TRUE, CP_AT_TYPE_FETCH_LOST_PEOPLE)
	STATE_SET(i, TRUE, CP_AT_TYPE_MED_MAN_GET_WILD_PEEPS)
	--train
	STATE_SET(i, TRUE, CP_AT_TYPE_TRAIN_PEOPLE)
	WRITE_CP_ATTRIB(i, ATTR_MAX_TRAIN_AT_ONCE, 4)
	WriteAiTrainTroops(i,14,14,14,0) --(pn,w,r,fw,spy)
	--buildings
	STATE_SET(i, TRUE, CP_AT_TYPE_CONSTRUCT_BUILDING)
	STATE_SET(i, TRUE, CP_AT_TYPE_FETCH_WOOD)
	WRITE_CP_ATTRIB(i, ATTR_RANDOM_BUILD_SIDE, 1)
	WRITE_CP_ATTRIB(i, ATTR_PREF_WARRIOR_TRAINS, 1)
	WRITE_CP_ATTRIB(i, ATTR_PREF_SUPER_WARRIOR_TRAINS, 1)
	WRITE_CP_ATTRIB(i, ATTR_PREF_RELIGIOUS_TRAINS, 1)
	WRITE_CP_ATTRIB(i, ATTR_PREF_SPY_TRAINS, 0)
	--vehicles
	STATE_SET(i, TRUE, CP_AT_TYPE_BUILD_VEHICLE)
	STATE_SET(i, TRUE, CP_AT_TYPE_FETCH_FAR_VEHICLE)
	--boats
	--WRITE_CP_ATTRIB(i, ATTR_PREF_BOAT_HUTS, 1)
	--WRITE_CP_ATTRIB(i, ATTR_PREF_BOAT_DRIVERS, 2+difficulty())
	--WRITE_CP_ATTRIB(i, ATTR_PEOPLE_PER_BOAT, 2+difficulty())
	--WRITE_CP_ATTRIB(i, ATTR_DONT_USE_BOATS, 0)
	--balloons
	WRITE_CP_ATTRIB(i, ATTR_PREF_BALLOON_HUTS, 1)
	WRITE_CP_ATTRIB(i, ATTR_PREF_BALLOON_DRIVERS, 2+difficulty())
	WRITE_CP_ATTRIB(i, ATTR_PEOPLE_PER_BALLOON, 2+difficulty())
	WRITE_CP_ATTRIB(i, ATTR_EMPTY_AT_WAYPOINT, 0) --leave balloon midway, and go on foot
	--attack
	SET_ATTACK_VARIABLE(i,0)
	STATE_SET(i, TRUE, CP_AT_TYPE_AUTO_ATTACK)
	WRITE_CP_ATTRIB(i, ATTR_ATTACK_PERCENTAGE, 100)
	WRITE_CP_ATTRIB(i, ATTR_MAX_ATTACKS, 999)
	WRITE_CP_ATTRIB(i, ATTR_BASE_UNDER_ATTACK_RETREAT, 0)
	WRITE_CP_ATTRIB(i, ATTR_RETREAT_VALUE, 5)
	--WRITE_CP_ATTRIB(i, ATTR_FIGHT_STOP_DISTANCE, 32)
	--WRITE_CP_ATTRIB(i, ATTR_GROUP_OPTION, 2)
	--[[0 - Stop at waypoint (if exists) and before attack
	1 - Stop before attack only
	2 - Stop at waypoint (if exists) only
	3 - Don't stop anywhere]]
	WriteAiAttackers(i,0,35,35,35,0,100) --(pn,b,w,r,fw,spy,sh)
	--defense
	WRITE_CP_ATTRIB(i, ATTR_DEFENSE_RAD_INCR, 5)
	WRITE_CP_ATTRIB(i, ATTR_MAX_DEFENSIVE_ACTIONS, 2)
	WRITE_CP_ATTRIB(i, ATTR_USE_PREACHER_FOR_DEFENCE, 1)
	STATE_SET(i, TRUE, CP_AT_TYPE_POPULATE_DRUM_TOWER)
	STATE_SET(i, TRUE, CP_AT_TYPE_BUILD_OUTER_DEFENCES)
	STATE_SET(i, TRUE, CP_AT_TYPE_DEFEND)
	STATE_SET(i, TRUE, CP_AT_TYPE_DEFEND_BASE)
	STATE_SET(i, TRUE, CP_AT_TYPE_SUPER_DEFEND)
	STATE_SET(i, TRUE, CP_AT_TYPE_PREACH)
	--spies
	WRITE_CP_ATTRIB(i, ATTR_SPY_DISCOVER_CHANCE, 8) -- (% chance of a spy being uncovered when spotted in cps base)
	WRITE_CP_ATTRIB(i, ATTR_ENEMY_SPY_MAX_STAND, 128) --(number of game turns computer player will ignore a spy stood in their base doing nothing)
	WRITE_CP_ATTRIB(i, ATTR_SPY_CHECK_FREQUENCY, 128) --(0 - 128), 0 means AI wont redisguise spies
	WRITE_CP_ATTRIB(i, ATTR_MAX_SPY_ATTACKS, 256)	
	STATE_SET(i, FALSE, CP_AT_TYPE_SABOTAGE)
	--spells
	SET_BUCKET_USAGE(i, TRUE)
	SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_BLAST, 6)
	SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_CONVERT_WILD, 6)
	SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_GHOST_ARMY, 12)
	SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_INSECT_PLAGUE, 16)
	SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_LAND_BRIDGE, 28)
	SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_LIGHTNING_BOLT, 30)
	SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_INVISIBILITY, 28)
	SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_HYPNOTISM, 48)
	SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_WHIRLWIND, 40)
	SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_SWAMP, 50)
	SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_EARTHQUAKE, 60)
	SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_EROSION, 66)
	SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_FLATTEN, 50)
	SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_FIRESTORM, 72)
	SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_SHIELD, 12)
	--defence spells
	SET_DEFENCE_RADIUS(i, 7)
	SET_SPELL_ENTRY(i, 0, M_SPELL_INSECT_PLAGUE, 25000, 64, 3, 0)
	SET_SPELL_ENTRY(i, 1, M_SPELL_LIGHTNING_BOLT, 40000, 64, 2, 0)
	SET_SPELL_ENTRY(i, 2, M_SPELL_INSECT_PLAGUE, 25000, 64, 3, 1)
	SET_SPELL_ENTRY(i, 3, M_SPELL_LIGHTNING_BOLT, 40000, 64, 2, 1)

	WRITE_CP_ATTRIB(i, ATTR_SHAMEN_BLAST, 64 >> 1+difficulty())
end
--end
--shaman stuff
SHAMAN_DEFEND(tribe1, 130, 88, TRUE)
SET_DRUM_TOWER_POS(tribe1, 130, 88)

-------------------------------------------------------------------------------------------------------------------------------------------------
include("CSequence.lua");
local Engine = CSequence:createNew();
local dialog_msgs = {
  [0] = {"This planet looks lifeless. <br> Are you sure this is this the place, Tiyao?", "Nomel", 6939, 2, 138},
  [1] = {"It is, indeed. You must be congratulated. You are about to unlock your shaman type. <br> There are plenty you could have picked from, but your decision was to become... a bard.", "Tiyao", 6883, 2, 146},
  [2] = {"Interesting choice, i must say. Bards are powerful in their own ways - lovers of nature, they manipulate the mana to create and restore life.", "Tiyao", 6883, 2, 146},
  [3] = {"Thank you, Tiyao! It is the wish of my inner self to connect to the earth, and all its living things.", "Nomel", 6939, 2, 138},
  [4] = {"I must go now. Your trials as a bard begin here. I wish you all the best.", "Tiyao", 6883, 2, 146},
  [5] = {"...", "Nomel", 6939, 2, 138},
  [6] = {"Free your mind, and empty your soul. <br> The path of the bard is a honourable one!", "The Bard", 1783, 0, 225},
  [7] = {"You will be facing the Chumara tribe on this trial. I shall aid you with some bard spells, once you leave two of your own behind.", "The Bard", 1783, 0, 225},
  --[8] = {"Cast any two spells - they will permanently leave your arsenal. You won't be able to use them on this trial. <br> It might be a good idea to not get rid of the convert spell. <br> (cast any spell, they will not trigger)", "Info", 173, 0, 160},
  [9] = {"Interesting... I shall concede you the status of bard. <br> And if you get out of this trial alive, I shall grant you with the rest of the knowledge and magic.", "The Bard", 1783, 0, 225},
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
								local tree = CREATE_THING_WITH_PARAMS4(T_SCENERY, M_SCENERY_DORMANT_TREE, TRIBE_HOSTBOT, c3d, T_SCENERY, math.random(1,6), 0, 0);
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
		
		--kill honor loads
		if (difficulty() == 3) and turn() > honorSaveTurnLimit and honorSaveTurnLimit ~= 0 then
			ProcessGlobalSpecialList(TRIBE_BLUE, PEOPLELIST, function(t)
				damage_person(t, 8, 20000, TRUE)
				return true
			end)
			TRIGGER_LEVEL_LOST() ; SET_NO_REINC(0)
			log_msg(8,"WARNING:  You have loaded the game while playing in \"honour\" mode.")
		end
	end
	if turn() == 10 then
		FLYBY_CREATE_NEW()
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
		
		FLYBY_START()
		DEFEND_SHAMEN(4,2)
	end
	if turn() == 24 then
		Engine:hidePanel()
		Engine:addCommand_CinemaRaise(0)
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
		honorSaveTurnLimit = turn() + 12*20
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
	
	if everySeconds(32 - difficulty()*4 - (gameStage*2)) then
		--occasionally shield troops when attacking
		for i = 2,3 do
			local r = 0
			if getShaman(i) ~= nil and IS_SHAMAN_IN_AREA(i,32,18) == 1 then
				if gameStage >= 2 and difficulty() > 0 then
					SearchMapCells(SQUARE, 0, 0 , 6, world_coord3d_to_map_idx(getShaman(i).Pos.D3), function(me)
						me.MapWhoList:processList(function (t)
							if t.Type == T_PERSON and t.Owner == i and t.Model > 2 and t.Model < 7 then
								if ((t.Flags3 & TF3_SHIELD_ACTIVE) == 0 and (t.Flags2 & TF2_THING_IS_A_GHOST_PERSON == 0)) and r == 0 then
									createThing(T_SPELL,M_SPELL_SHIELD,i,t.Pos.D3,false,false)
									GIVE_MANA_TO_PLAYER(i,-25000)
									r = 1
								end
							end
						return true end)
					return true end)
				end
			elseif getShaman(i) ~= nil and IS_SHAMAN_IN_AREA(i,33,8) == 1 then
				--when defending
				if gameStage >= 3 and difficulty() > 1 then
					SearchMapCells(SQUARE, 0, 0 , 6, world_coord3d_to_map_idx(getShaman(i).Pos.D3), function(me)
						me.MapWhoList:processList(function (t)
							if t.Type == T_PERSON and t.Owner == i and t.Model > 2 and t.Model < 7 then
								if ((t.Flags3 & TF3_SHIELD_ACTIVE) == 0 and (t.Flags2 & TF2_THING_IS_A_GHOST_PERSON == 0)) and r == 0 then
									createThing(T_SPELL,M_SPELL_SHIELD,i,t.Pos.D3,false,false)
									GIVE_MANA_TO_PLAYER(i,-20000)
									r = 1
								end
							end
						return true end)
					return true end)
				end
			end
		end
		--occasionally do a balloon patrol near stone head
		if count_people_of_type_in_area(162,202,-1,player,3) > 0 then
			if _gsi.Players[tribe1].NumPeopleOfType[M_PERSON_SUPER_WARRIOR] > 8 then
				if _gsi.Players[tribe1].NumVehiclesOfType[M_VEHICLE_AIRSHIP_1] > 1 then
					BOAT_PATROL(2,math.random(2,4),60,61,62,63,M_VEHICLE_AIRSHIP_1)
				end
			end
		end
	end
	
	if everySeconds(20-(difficulty()*4)) then
		--AI shamans near blue base burn trees occasionally
		for i,v in ipairs(AItribes) do
			if getShaman(v) ~= nil and IS_SHAMAN_IN_AREA(v,49,16) == 1 and (getShaman(v).Flags2 & TF2_THING_IS_A_GHOST_PERSON == 0) then
				SearchMapCells(SQUARE, 0, 0 , 5, world_coord3d_to_map_idx(getShaman(v).Pos.D3), function(me)
					me.MapWhoList:processList(function (t)
						if t.Type == T_SCENERY and t.Model < 7 then
							if t.State == 1 then
								local Sstate = getShaman(v).State
								if Sstate == 10 or Sstate == 17 or Sstate == 18 or Sstate == 19 then
									createThing(T_SPELL,M_SPELL_BLAST,v,t.Pos.D3,false,false)
								end
							end
						end
					return true end)
				return true end)
			end
		end
		--stop or restart vehicle construction if too many in base
		if READ_CP_ATTRIB(tribe1,ATTR_PREF_BALLOON_DRIVERS) > 0 then
			if CountThingsOfTypeInArea(T_VEHICLE,M_VEHICLE_AIRSHIP_1,tribe1,152,76,16) > 5+gameStage then
				WRITE_CP_ATTRIB(tribe1, ATTR_PREF_BALLOON_DRIVERS, 0)
				WRITE_CP_ATTRIB(tribe1, ATTR_PEOPLE_PER_BALLOON, 0)
			end
		else
			if CountThingsOfTypeInArea(T_VEHICLE,M_VEHICLE_AIRSHIP_1,tribe1,152,76,16) < 5+gameStage then
				WRITE_CP_ATTRIB(tribe1, ATTR_PREF_BALLOON_DRIVERS, 2+difficulty())
				WRITE_CP_ATTRIB(tribe1, ATTR_PEOPLE_PER_BALLOON, 2+difficulty())
			end
		end
	end
	
	if everySeconds(32-difficulty()*3) then
		--more frequently explode solo balloons in player's base (if too many)
		local pos = MapPosXZ.new() ; pos.XZ.X = 24 ; pos.XZ.Z = 224
		local r = 0
		SearchMapCells(SQUARE ,0, 0, 16, pos.Pos, function(me)
			me.MapWhoList:processList( function (t)
				if t.Type == T_VEHICLE and t.Model == M_VEHICLE_AIRSHIP_1 and t.Owner ~= player then
					if r == 0 and  t.u.Vehicle.NumOccupants == 0 then
						t.State = S_VEHICLE_AIRSHIP_DYING 
						r = 1
					end
				end
			return true end)
		return true end)
	end
	
	-- new towers every x mins
	if everySeconds(256-(difficulty()*20)) and gameStage >= 1 then
		if _gsi.Players[tribe1].NumBuildingsOfType[M_BUILDING_DRUM_TOWER] < (12+(difficulty()*2)) then
			local rndTowMk = math.random(65,78)
			local coord = MapPosXZ.new() ; coord.Pos = world_coord3d_to_map_idx(marker_to_coord3d(rndTowMk))
			BUILD_DRUM_TOWER(tribe1,coord.XZ.X, coord.XZ.Z)
		end
	end
	
	if everySeconds(8) then
		--send main attacks
		if tribe1Atk1 < turn() then SendAttack(tribe1) end
		--send mini attacks
		if tribe1MiniAtk1 < turn() then SendMiniAttack(tribe1) end
	end
	
	if every2Pow(4) then
		--troops train faster depending on difficulty
		ProcessGlobalTypeList(T_BUILDING, function(t)
			if (t.Type == T_BUILDING) then
				if (_gsi.Players[t.Owner].PlayerType == COMPUTER_PLAYER) then
					if (t.u.Bldg.ShapeThingIdx:isNull()) then
						if (t.u.Bldg.TrainingManaCost > 0) then
							t.u.Bldg.TrainingManaStored = t.u.Bldg.TrainingManaStored + (64*difficulty())
						end
					end
				end
			end
		return true end)
		--buildings faster green red bar if hard
		ProcessGlobalSpecialListAll(BUILDINGLIST, function(b)
			if (b.Model <= 3) and b.Owner ~= player then
				if (b.u.Bldg.UpgradeCount < 1850) then
					b.u.Bldg.UpgradeCount = b.u.Bldg.UpgradeCount + (difficulty()*4)
				end
				if (b.u.Bldg.SproggingCount < 1000) then
					b.u.Bldg.SproggingCount = b.u.Bldg.SproggingCount + (difficulty()*4)
				end
			end
		return true end)
		--stress from nav check, cast AoD
		if gameStage >= 2 then
			if tribe1NavStress > (7-difficulty()) then
				if getShaman(tribe1) ~= nil and IS_SHAMAN_AVAILABLE_FOR_ATTACK(tribe1) > 0 then
					GIVE_ONE_SHOT(M_SPELL_ANGEL_OF_DEATH,tribe1) ; SPELL_ATTACK(tribe1,M_SPELL_ANGEL_OF_DEATH,99,99) ; tribe1NavStress = 0
				end
			end
		end
	end
	
	--casts aod sometimes
	if everySeconds(1200-(difficulty()*80)-(gameStage*50)) then
		if gameStage > 2 and difficulty() > 0 then
			if getShaman(tribe1) ~= nil and IS_SHAMAN_AVAILABLE_FOR_ATTACK(tribe1) > 0 then
				GIVE_ONE_SHOT(M_SPELL_ANGEL_OF_DEATH,tribe1) ; SPELL_ATTACK(tribe1,M_SPELL_ANGEL_OF_DEATH,99,99)
			end
		end
	end
	
	--give AI spell shots occasionally
	if everySeconds(64-difficulty()*2) then
		for k,v in ipairs(AItribes) do
			if gameStage == 0 then
				GIVE_ONE_SHOT(M_SPELL_BLAST,v)
			elseif gameStage == 1 then
				GIVE_ONE_SHOT(M_SPELL_BLAST,v) if rnd() > 50 then GIVE_ONE_SHOT(M_SPELL_WHIRLWIND,v) end
			elseif gameStage == 2 then
				GIVE_ONE_SHOT(M_SPELL_BLAST,v) if rnd() > 50 then GIVE_ONE_SHOT(M_SPELL_WHIRLWIND,v) GIVE_ONE_SHOT(M_SPELL_HYPNOTISM,v) end
			else
				GIVE_ONE_SHOT(M_SPELL_BLAST,v) if rnd() > 50 then GIVE_ONE_SHOT(M_SPELL_WHIRLWIND,v) GIVE_ONE_SHOT(M_SPELL_HYPNOTISM,v) GIVE_ONE_SHOT(M_SPELL_SWAMP,v) end
			end
		end
	end
	--give AI spell shots rarely
	if everySeconds(60-(difficulty()*3)) then
		for k,v in ipairs(AItribes) do
			if gameStage == 0 then
				GIVE_ONE_SHOT(M_SPELL_INSECT_PLAGUE,v)
			elseif gameStage == 1 then
				GIVE_ONE_SHOT(M_SPELL_EROSION,v)
			elseif gameStage == 2 then
				GIVE_ONE_SHOT(M_SPELL_EARTHQUAKE,v)
			else
				GIVE_ONE_SHOT(M_SPELL_FIRESTORM,v)
			end
		end
		--increase spells in their atk arsenal
		if #tribe1AtkSpells < 20 then
			local rndS = {4,7,8,10,11,14,13}
			table.insert(tribe1AtkSpells,rndS[math.random(#rndS)])
		end
	end
	
	if every2Pow(6) then
		--update game stage (early,mid,late,very late)
		if minutes() < 10 then
			gameStage = 0
		elseif minutes() < 20 then
			gameStage = 1
		elseif minutes() < 30 then
			gameStage = 2
		elseif minutes() < 40 then
			gameStage = 3
		else
			gameStage = 4
		end

		for i,v in ipairs(AItribes) do
			if turn() > 1400 then WRITE_CP_ATTRIB(v, ATTR_EXPANSION, math.random(16,24)) end
			WRITE_CP_ATTRIB(v, ATTR_HOUSE_PERCENTAGE, 50+G_RANDOM(1+4*difficulty())+(difficulty()*8)+(gameStage*(6+difficulty()))) --base size
			WriteAiTrainTroops(v,12+(difficulty()*2)+(gameStage*1),10+(gameStage*1),15+(difficulty()*2)+(gameStage*1),0) --(pn,w,r,fw,spy)
			WRITE_CP_ATTRIB(v, ATTR_ATTACK_PERCENTAGE, 85+(minutes()*2)) --attack stuff
			if READ_CP_ATTRIB(v,ATTR_ATTACK_PERCENTAGE) > 120 then WRITE_CP_ATTRIB(v, ATTR_ATTACK_PERCENTAGE, 90) end
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_BLAST, math.random(6,8)-(difficulty()*1)) --spells
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_CONVERT_WILD, math.random(5,8)-(difficulty()*1))
			--SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_GHOST_ARMY, 12)
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_INSECT_PLAGUE, math.random(13,18)-(difficulty()*2))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_LAND_BRIDGE, math.random(26,34)-(difficulty()*2))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_LIGHTNING_BOLT, math.random(34,44)-(difficulty()*3))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_INVISIBILITY, math.random(24,30)-(difficulty()*2))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_HYPNOTISM, math.random(32,38)-(difficulty()*2))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_WHIRLWIND, math.random(26,30)-(difficulty()*2))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_SWAMP, math.random(16,28)-(difficulty()*2))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_EARTHQUAKE, math.random(30,45)-(difficulty()*2))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_EROSION, math.random(26,34)-(difficulty()*3))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_FLATTEN, math.random(25,30)-(difficulty()*2))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_FIRESTORM, math.random(35,50)-(difficulty()*3))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_SHIELD, math.random(20,30)-(difficulty()*2))
			local baseMK = 33
			--spell entries base and outside
			if IS_SHAMAN_IN_AREA(v,baseMK,16) == 1 then
				--spells in base defense
				SET_SPELL_ENTRY(v, 0, M_SPELL_BLAST, SPELL_COST(M_SPELL_BLAST) >> (1+difficulty()), 64, 1, 1)
				SET_SPELL_ENTRY(v, 1, M_SPELL_LIGHTNING_BOLT, SPELL_COST(M_SPELL_LIGHTNING_BOLT) >> (1+difficulty()), 256, 3, 1)
				SET_SPELL_ENTRY(v, 2, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> (1+difficulty()), 128, 5-difficulty(), 1)
				SET_SPELL_ENTRY(v, 3, M_SPELL_SWAMP, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> (1+difficulty()), 128, 13-difficulty(), 1)
				if gameStage > 1 then
					SET_SPELL_ENTRY(v, 4, M_SPELL_HYPNOTISM, SPELL_COST(M_SPELL_HYPNOTISM) >> (1+difficulty()), 128, 12-(difficulty()*2), 1)
					if gameStage >= 3 and difficulty() >= 2 then
						SET_SPELL_ENTRY(v, 5, M_SPELL_ANGEL_OF_DEATH, SPELL_COST(M_SPELL_ANGEL_OF_DEATH) >> (1+difficulty()), 128, 24-(difficulty()*2), 1)
					end
				end
			else
				--spells when attacking
				SET_SPELL_ENTRY(v, 0, M_SPELL_BLAST, SPELL_COST(M_SPELL_BLAST) >> (1+difficulty()), 64, 1, 0)
				SET_SPELL_ENTRY(v, 1, M_SPELL_LIGHTNING_BOLT, SPELL_COST(M_SPELL_LIGHTNING_BOLT) >> (1+difficulty()), 256, 1, 0)
				SET_SPELL_ENTRY(v, 2, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> (1+difficulty()), 128, 5-difficulty(), 0)
				SET_SPELL_ENTRY(v, 3, M_SPELL_SWAMP, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> (1+difficulty()), 128, 12-difficulty(), 0)
				if gameStage > 1 then
					SET_SPELL_ENTRY(v, 4, M_SPELL_HYPNOTISM, SPELL_COST(M_SPELL_HYPNOTISM) >> (1+difficulty()), 128, 12-(difficulty()*2), 0)
					if gameStage < 2 then
						SET_SPELL_ENTRY(v, 5, M_SPELL_FIRESTORM, SPELL_COST(M_SPELL_FIRESTORM) >> (1+difficulty()), 128, 18-(difficulty()*2), 0)
						SET_SPELL_ENTRY(v, 6, M_SPELL_EARTHQUAKE, SPELL_COST(M_SPELL_EARTHQUAKE) >> (1+difficulty()), 128, 16-(difficulty()*2), 0)
						if difficulty() == 3 then
							SET_SPELL_ENTRY(v, 7, M_SPELL_ANGEL_OF_DEATH, SPELL_COST(M_SPELL_ANGEL_OF_DEATH) >> (1+difficulty()), 128, 32-(difficulty()*3), 0)
						end
					end
				end
			end
			--conditional stuff
			if _gsi.Players[v].NumBuildingsOfType[M_BUILDING_TEPEE]+_gsi.Players[v].NumBuildingsOfType[M_BUILDING_TEPEE_2]+_gsi.Players[v].NumBuildingsOfType[M_BUILDING_TEPEE_3] > 3 then WRITE_CP_ATTRIB(v, ATTR_PREF_SUPER_WARRIOR_TRAINS, 1) else WRITE_CP_ATTRIB(v, ATTR_PREF_SUPER_WARRIOR_TRAINS, 0) end
			if _gsi.Players[v].NumBuildingsOfType[M_BUILDING_TEPEE]+_gsi.Players[v].NumBuildingsOfType[M_BUILDING_TEPEE_2]+_gsi.Players[v].NumBuildingsOfType[M_BUILDING_TEPEE_3] > 5 then WRITE_CP_ATTRIB(v, ATTR_PREF_RELIGIOUS_TRAINS, 1) else WRITE_CP_ATTRIB(v, ATTR_PREF_RELIGIOUS_TRAINS, 0) end
			if _gsi.Players[v].NumPeople < 5 then GIVE_UP_AND_SULK(v,TRUE) end
			--add lategame spells to atkspells
			if gameStage == 2 then
				if #tribe1AtkSpells == 4 then
					table.insert(tribe1AtkSpells,M_SPELL_EROSION)
					if #tribe1AtkSpells == 6 and difficulty() >= 3 then
						table.insert(tribe1AtkSpells,M_SPELL_FIRESTORM)
					end
				end
			elseif gameStage == 3 then
				if #tribe1AtkSpells == 5 then
					table.insert(tribe1AtkSpells,M_SPELL_ANGEL_OF_DEATH)
					if #tribe1AtkSpells == 6 and difficulty() >= 3 then
						table.insert(tribe1AtkSpells,M_SPELL_FIRESTORM)
					end
				end
			end
		end
	end
end

function IncrementAtkVar(pn,amt,mainAttack)
	if mainAttack == true then
		tribe1Atk1 = amt 
	else --mini attacks
		tribe1MiniAtk1 = amt 
	end
end

function SendMiniAttack(attacker)
	if (minutes() > (4-difficulty())) and (rnd() < 50+difficulty()*5 +gameStage*5) then
		--WRITE_CP_ATTRIB(attacker, ATTR_DONT_GROUP_AT_DT, math.random(0,1))
		--WRITE_CP_ATTRIB(attacker, ATTR_GROUP_OPTION, math.random(0,3))
		--WRITE_CP_ATTRIB(attacker, ATTR_FIGHT_STOP_DISTANCE, 32 + G_RANDOM(16))
		WRITE_CP_ATTRIB(attacker, ATTR_BASE_UNDER_ATTACK_RETREAT, 0)
		WriteAiAttackers(attacker,0,math.random(30,40)+(difficulty()*5)+(gameStage*5),math.random(25,35)+(difficulty()*4)+(gameStage*4),math.random(20,30),0,0) --(pn,b,w,r,fw,spy,sh)
		local target = player
		local numTroops = 0
		local balloons = CountThingsOfTypeInArea(T_VEHICLE,M_VEHICLE_AIRSHIP_1,tribe1,152,76,16)
		local focus = -1
		--check if enough pop and troops to attack
		if _gsi.Players[attacker].NumPeople > 16 and GetTroops(attacker) > 8 then
			numTroops = 2 + gameStage
		end
		--LAUNCH MINI ATK
		if numTroops > 0 and balloons > 0 then
			local targBldgs =  _gsi.Players[target].NumBuildings
			local targPpl  = _gsi.Players[target].NumPeople
			if targBldgs > 0 then
				if rnd() < 50 then
					focus = ATTACK_BUILDING
				else
					focus = ATTACK_PERSON
					if rnd() < 50 then
						TARGET_PLAYER_DT_AND_S(tribe1,player)
						TARGET_DRUM_TOWERS(tribe1)
					else
						TARGET_S_WARRIORS(tribe1)
					end
				end
			else
				focus = ATTACK_PERSON
			end
			--SEND ATK
			ATTACK(attacker, target, numTroops, focus, 0, 999, 0, 0, 0, ATTACK_BY_BALLOON, 0, math.random(34,39), 0, 0)
			IncrementAtkVar(attacker,turn() + 2100 + G_RANDOM(2100) - (difficulty()*400) - (gameStage*200),false) 
			--log_msg(attacker,"mini atk vs player: " .. target .. "  , by (0norm,1boat,2ball) " .. 2 .. "  , targetting (0mk,1bldg,2person) " .. focus)
			
		else
			IncrementAtkVar(attacker,turn() + 555, false)
		end
	else
		IncrementAtkVar(attacker,turn() + 555, false)
	end
end

function SendAttack(attacker)
	if (minutes() > 5-difficulty()) and (rnd() < 65+difficulty()*5 +gameStage*5) then
		--WRITE_CP_ATTRIB(attacker, ATTR_FIGHT_STOP_DISTANCE, 28 + G_RANDOM(16))
		WriteAiAttackers(attacker,0,15+G_RANDOM(10)+(difficulty()*6)+(gameStage*4),15+G_RANDOM(5)+(difficulty()*5)+(gameStage*4),15+G_RANDOM(7)+(difficulty()*7)+(gameStage*4),0,100) --(pn,b,w,r,fw,spy,sh)
		local target = player
		local numTroops = 0
		local vehicles = CountThingsOfTypeInArea(T_VEHICLE,M_VEHICLE_AIRSHIP_1,tribe1,152,76,16)
		local spell1,spell2,spell3 = 0,0,0
		local mk1,mk2 = math.random(34,39),-1
		local stress = 0
		--check if enough pop and troops to attack
		local troopAmmount = GetTroops(attacker)
		if _gsi.Players[attacker].NumPeople > 40 and troopAmmount > 15 then
			numTroops = 2 + (difficulty()) + gameStage --if difficulty() >= 2 then numTroops = numTroops + math.floor(troopAmmount/7) end
			if numTroops > 6 then numTroops = 6 end
		end
		--group options
		--[[if difficulty() >= 2 then
			WRITE_CP_ATTRIB(attacker, ATTR_DONT_GROUP_AT_DT, 1);
			WRITE_CP_ATTRIB(attacker, ATTR_GROUP_OPTION, 2);
		else
			WRITE_CP_ATTRIB(attacker, ATTR_DONT_GROUP_AT_DT, 0);
			WRITE_CP_ATTRIB(attacker, ATTR_GROUP_OPTION, 0);
		end]]
		--retreat
		if difficulty() < 2 then
			WRITE_CP_ATTRIB(attacker, ATTR_BASE_UNDER_ATTACK_RETREAT, 1)
			WRITE_CP_ATTRIB(attacker, ATTR_RETREAT_VALUE, math.random(2,6))
		else
			WRITE_CP_ATTRIB(attacker, ATTR_BASE_UNDER_ATTACK_RETREAT, 0)
			WRITE_CP_ATTRIB(attacker, ATTR_RETREAT_VALUE, 0)
		end
		--is shaman going
		if getShaman(attacker) ~= nil and gameStage >= 1 and IS_SHAMAN_AVAILABLE_FOR_ATTACK(attacker) > 0 then
			WRITE_CP_ATTRIB(attacker, ATTR_AWAY_MEDICINE_MAN, 1)
			--lategame and hard and shaman, might cast invi/shield
			if difficulty() >= 2 and gameStage >= 2 then
				if rnd() > 50 then
					if rnd() > 50 then
						spell1 = M_SPELL_INVISIBILITY
						GIVE_ONE_SHOT(M_SPELL_INVISIBILITY,attacker)
					else
						spell1 = M_SPELL_SHIELD
						GIVE_ONE_SHOT(M_SPELL_SHIELD,attacker)
					end
					if attacker == tribe1 then mk2 = mk1 end
				end
			end
		else
			WRITE_CP_ATTRIB(attacker, ATTR_AWAY_MEDICINE_MAN, 0);
			mk2 = -1
		end
		--give spell 1, 2 AND 3
		if READ_CP_ATTRIB(attacker,ATTR_AWAY_MEDICINE_MAN) > 0 then
			if spell1 == 0 then
				spell1 = tribe1AtkSpells[math.random(#tribe1AtkSpells)]
			end
			spell2 = tribe1AtkSpells[math.random(#tribe1AtkSpells)]
			spell3 = tribe1AtkSpells[math.random(#tribe1AtkSpells)]
		end
		--LAUNCH ATTACK
		
		--has enough troops
		if numTroops > 0 then
			local navBldg = NAV_CHECK(attacker,target,ATTACK_BUILDING,0,0)
			local navPpl = NAV_CHECK(attacker,target,ATTACK_PERSON,0,0)
			local targBldgs =  _gsi.Players[target].NumBuildings
			local targPpl  = _gsi.Players[target].NumPeople
			local wait = 0
			local focus = -1
			local atktype = -1
			local returnVehicle = 0
			--prioritize buildings
			if targBldgs > 0 then
				--bldg by land
				if navBldg > 0 then
					wait = -1 ; focus = ATTACK_BUILDING ; atktype = ATTACK_BY_BALLOON--ATTACK_NORMAL
				else
					--bldg with vehicle
					if vehicles >= math.floor(numTroops/3) then
						--has vehicles
						wait = -1 ; focus = ATTACK_BUILDING ; atktype = ATTACK_BY_BALLOON
					else
						--has no vehicles
						if targPpl > 0 then
							--will then target a person
							if navPpl > 0 then
								--ppl by land
								wait = -1 ; focus = ATTACK_PERSON ; atktype = ATTACK_BY_BALLOON--ATTACK_NORMAL
							else
								--ppl with vehicle
								if vehicles >= math.floor(numTroops/3) then
									wait = -1 ; focus = ATTACK_PERSON ; atktype = ATTACK_BY_BALLOON
								else
									wait = 0
								end
							end
						else
							wait = 1
						end
					end
				end
			else
				--prioritize people
				if targPpl > 0 then
					--will then target a person
					if navPpl > 0 then
						--ppl by land
						wait = -1 ; focus = ATTACK_PERSON ; atktype = ATTACK_BY_BALLOON--ATTACK_NORMAL
					else
						--ppl with vehicle
						if vehicles >= math.floor(numTroops/3) then
							wait = -1 ; focus = ATTACK_PERSON ; atktype = ATTACK_BY_BALLOON
						else
							wait = 0
						end
					end
				else
					wait = 1
				end
			end
			--SEND THE ATTACK--SEND THE ATTACK--SEND THE ATTACK--SEND THE ATTACK--SEND THE ATTACK--SEND THE ATTACK
			if wait == -1 then
				if atktype ~= ATTACK_NORMAL then
					mk1 = -1
					mk2 = -1
					--WRITE_CP_ATTRIB(attacker, ATTR_GROUP_OPTION, 0)
					returnVehicle = 0
				end
				ATTACK(attacker, target, numTroops, focus, 0, 999, spell1, spell2, spell3, atktype, returnVehicle, mk1, mk2, 0)
				IncrementAtkVar(attacker,turn() + 3100 + G_RANDOM(3100) - (difficulty()*400) - (gameStage*200),true) 
				--log_msg(attacker,"main atk vs player: " .. target .. "  , by (0norm,1boat,2ball) " .. atktype .. "  , targetting (0mk,1bldg,2person) " .. focus)
			elseif wait == 1 then
				IncrementAtkVar(attacker,turn()+100, true)
			else
				IncrementAtkVar(attacker,turn()+500, true)
			end
		else
			IncrementAtkVar(attacker,turn()+500, true)
		end
	else
		IncrementAtkVar(attacker,turn()+500, true)
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
	
	PopSetFont(4)
	LbDraw_Text(guiW+2,100+10*2,"seconds: " .. seconds(),0)    --104
	PopSetFont(1)
	LbDraw_Text(guiW+2,100+12*7,"atk: " .. tribe1Atk1,0)
	LbDraw_Text(guiW+2,100+12*9,"mini: " .. tribe1MiniAtk1,0)
	
	--honor save timer
	if turn() < honorSaveTurnLimit and honorSaveTurnLimit ~= 0 and difficulty() == 3 then
		PopSetFont(3)
		local hstl = "WARNING (honour mode): You can save, to avoid rewatching the intro   "
		LbDraw_Text(math.floor(w-2-(string_width("77:77:77 ")+string_width(tostring(hstl)))),2,tostring(hstl),0)
		LbDraw_Text(math.floor(w-2-(string_width("77:77:77 "))),2,tostring(TurnsToClock(math.floor((honorSaveTurnLimit-turn())/12))),0)
	end
	
	--bard lives
	if BardLives > 0 and bard > 2 then
		for i = 1,BardLives do
			LbDraw_ScaledSprite(guiW+((i-1)*4)+((i-1)*box),4,get_sprite(0,1782),box,box)
		end
	end
end


function OnCreateThing(t)
	--tree's angles
	if (t.Type == T_SCENERY) then
		if (t.Model < 7) then
			t.AngleXZ = G_RANDOM(2048)
		end
	end
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
				Engine:addCommand_QueueMsg(dialog_msgs[9][1], dialog_msgs[9][2], 36, false, dialog_msgs[9][3], dialog_msgs[9][4], dialog_msgs[9][5], 888);
				Engine:addCommand_QueueMsg(dialog_msgs[10][1], dialog_msgs[10][2], 72, false, dialog_msgs[10][3], dialog_msgs[10][4], dialog_msgs[10][5], 888);
				Engine:addCommand_QueueMsg(dialog_msgs[12][1], dialog_msgs[12][2], 72, false, dialog_msgs[12][3], dialog_msgs[12][4], dialog_msgs[12][5], 1024);
				Engine:addCommand_QueueMsg(dialog_msgs[11][1], dialog_msgs[11][2], 72, false, dialog_msgs[11][3], dialog_msgs[11][4], dialog_msgs[11][5], 12);
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
				--give lbs/flattens at start
				for i = 4-difficulty(),1,-1 do GIVE_ONE_SHOT(M_SPELL_LAND_BRIDGE,player) end
				for i = 3-difficulty(),1,-1 do GIVE_ONE_SHOT(M_SPELL_FLATTEN,player) end
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
	
	save_data:push_int(balmC3D.Xpos)
	save_data:push_int(balmC3D.Zpos)
	save_data:push_int(balmC3D.Ypos)
	save_data:push_int(seedC3D.Xpos)
	save_data:push_int(seedC3D.Zpos)
	save_data:push_int(seedC3D.Ypos)
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
	seedC3D.Ypos = load_data:pop_int()
	seedC3D.Zpos = load_data:pop_int()
	seedC3D.Xpos = load_data:pop_int()
	balmC3D.Ypos = load_data:pop_int()
	balmC3D.Zpos = load_data:pop_int()
	balmC3D.Xpos = load_data:pop_int()
	
	local numSpellsAtk1 = load_data:pop_int();
	for i = 1, numSpellsAtk1 do
		 tribe1AtkSpells[i] = load_data:pop_int();
	end
end