--spring level 11: Eastern Winds

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
for i = 2,17 do
	sti[i].AvailableSpriteIdx = 353+i
end
sti[19].AvailableSpriteIdx = 408
tmi = thing_move_info()
bti = building_type_info()
ency = encyclopedia_info()
ency[27].StrId = 1010
ency[32].StrId = 1015
ency[22].StrId = 701
ency[35].StrId = 699
ency[38].StrId = 700
include("assets.lua")
change_sprite_bank(0,0)
gns.GameParams.Flags3 = gns.GameParams.Flags3 | GPF3_FOG_OF_WAR_KEEP_STATE
--------------------
sti[M_SPELL_GHOST_ARMY].Active = SPAC_OFF
sti[M_SPELL_GHOST_ARMY].NetworkOnly = 1
local balm = M_SPELL_INVISIBILITY --(healing balm): units in a 3x3 area get healed for 1/3 their max hp
local seed = M_SPELL_SWAMP --(seed of life): casts a seed that rises a tree and creates a wildman
local enrage = M_SPELL_EROSION --(enrage): enrages units in a area (max 6), giving them huge stats, but their health will permanently decay until they perish
local terra = M_SPELL_VOLCANO --(terra firma): dips the land a great amount, then lava flows
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
sti[enrage].Cost = 250000+(difficulty()*15000)
sti[enrage].CursorSpriteNum = 164
sti[enrage].ToolTipStrIdx = 697
sti[enrage].AvailableSpriteIdx = 1796
sti[enrage].NotAvailableSpriteIdx = 1798
sti[enrage].ClickedSpriteIdx = 1797 
sti[terra].Cost = 700000+(difficulty()*15000)
sti[terra].WorldCoordRange = 4096+2048
sti[terra].CursorSpriteNum = 165
sti[terra].ToolTipStrIdx = 698
sti[terra].AvailableSpriteIdx = 1799
sti[terra].NotAvailableSpriteIdx = 1801
sti[terra].ClickedSpriteIdx = 1800
set_correct_gui_menu()
--------------------
function Plant(IdxS,IdxE,drawnum)
	for i = IdxS,IdxE do
		local plants = createThing(T_SCENERY,M_SCENERY_PLANT_2,8,marker_to_coord3d(i),false,false) centre_coord3d_on_block(plants.Pos.D3)
		plants.DrawInfo.DrawNum = drawnum ; plants.DrawInfo.Alpha = -16
	end
end
if turn() == 0 then
	bard = createThing(T_SCENERY,M_SCENERY_PLANT_2,8,marker_to_coord3d(133),false,false) centre_coord3d_on_block(bard.Pos.D3)
	bard.DrawInfo.DrawNum = 1783 bard.DrawInfo.Alpha = -16
	Plant(1,8,1787)
	Plant(9,12,1788)
	Plant(13,18,1789)
	Plant(19,24,1790)
	Plant(25,33,1786)
	Plant(1,8,1787)
	for i = 34,41 do
		plants = createThing(T_SCENERY,M_SCENERY_PLANT_2,8,marker_to_coord3d(i),false,false) centre_coord3d_on_block(plants.Pos.D3)
		plants.DrawInfo.DrawNum = math.random(1791,1795) plants.DrawInfo.Alpha = -16
	end
	Plant(42,50,1788)
	Plant(51,59,1787)
	Plant(60,69,1788)
	Plant(70,71,1792)
	Plant(72,75,1794)
	for i = 76,78 do
		plants = createThing(T_SCENERY,M_SCENERY_PLANT_2,8,marker_to_coord3d(i),false,false) centre_coord3d_on_block(plants.Pos.D3)
		plants.DrawInfo.DrawNum = math.random(1791,1795) plants.DrawInfo.Alpha = -16
	end
	for i = 79,87 do
		plants = createThing(T_SCENERY,M_SCENERY_PLANT_2,8,marker_to_coord3d(i),false,false) centre_coord3d_on_block(plants.Pos.D3)
		plants.DrawInfo.DrawNum = math.random(1786,1790) plants.DrawInfo.Alpha = -16
	end
	Plant(88,91,1790)
	Plant(92,97,1789)
	Plant(98,103,1794)
	for i = 104,113 do
		plants = createThing(T_SCENERY,M_SCENERY_PLANT_2,8,marker_to_coord3d(i),false,false) centre_coord3d_on_block(plants.Pos.D3)
		plants.DrawInfo.DrawNum = math.random(1786,1795) plants.DrawInfo.Alpha = -16
	end
	Plant(114,117,1792)
	Plant(123,127,1794)
	for i = 128,132 do
		plants = createThing(T_SCENERY,M_SCENERY_PLANT_2,8,marker_to_coord3d(i),false,false) centre_coord3d_on_block(plants.Pos.D3)
		plants.DrawInfo.DrawNum = math.random(1786,1795) plants.DrawInfo.Alpha = -16
	end
	Plant(154,158,1787)
	for i = 134,153 do
		plants = createThing(T_SCENERY,M_SCENERY_PLANT_2,8,marker_to_coord3d(i),false,false) centre_coord3d_on_block(plants.Pos.D3)
		plants.DrawInfo.DrawNum = math.random(1786,1795) plants.DrawInfo.Alpha = -16
	end
	Plant(159,165,1794)
	Plant(166,170,1790)
	Plant(171,175,1788)
	Plant(176,181,1795)
	for i = 182,189 do
		plants = createThing(T_SCENERY,M_SCENERY_PLANT_2,8,marker_to_coord3d(i),false,false) centre_coord3d_on_block(plants.Pos.D3)
		plants.DrawInfo.DrawNum = math.random(1791,1795) plants.DrawInfo.Alpha = -16
	end
	for i = 190,220 do
		plants = createThing(T_SCENERY,M_SCENERY_PLANT_2,8,marker_to_coord3d(i),false,false) centre_coord3d_on_block(plants.Pos.D3)
		plants.DrawInfo.DrawNum = math.random(1786,1794) plants.DrawInfo.Alpha = -16
	end
	Plant(221,224,1795)
	for i = 225,231 do
		plants = createThing(T_SCENERY,M_SCENERY_PLANT_2,8,marker_to_coord3d(i),false,false) centre_coord3d_on_block(plants.Pos.D3)
		plants.DrawInfo.DrawNum = math.random(1791,1795) plants.DrawInfo.Alpha = -16
	end
	--fog reveals
	for i = 232,239 do
		if i <= 233 and difficulty() == 3 then createThing(T_EFFECT,M_EFFECT_REVEAL_FOG_AREA,8,marker_to_coord3d(i),false,false)
		elseif i <= 235 and difficulty() == 2 then createThing(T_EFFECT,M_EFFECT_REVEAL_FOG_AREA,8,marker_to_coord3d(i),false,false)
		elseif i <= 237 and difficulty() == 1 then createThing(T_EFFECT,M_EFFECT_REVEAL_FOG_AREA,8,marker_to_coord3d(i),false,false)
		elseif i <= 239 and difficulty() == 0 then createThing(T_EFFECT,M_EFFECT_REVEAL_FOG_AREA,8,marker_to_coord3d(i),false,false) end
	end
	--add wilds near CoR depending on diff
	local wildTbl = {91,237,41,78}
	local enemyWildTbl = {138,134,135,136, 221,227,228,226, 174,244,187,188}
	for i = 1,5-difficulty() do
		for idx,v in ipairs(wildTbl) do
			createThing(T_PERSON,M_PERSON_WILD,8,marker_to_coord3d(v),false,false)
		end
	end
	--add wilds near enemy depending on diff
	for i = 1,1+difficulty() do
		for idx,v in ipairs(enemyWildTbl) do
			createThing(T_PERSON,M_PERSON_WILD,8,marker_to_coord3d(v),false,false)
		end
	end
end
--------------------
local player = TRIBE_ORANGE
local tribe1 = TRIBE_BLUE
local tribe2 = TRIBE_PINK
local tribe3 = TRIBE_BLACK
local tribe4 = TRIBE_GREEN
computer_init_player(_gsi.Players[tribe1]) 
computer_init_player(_gsi.Players[tribe2]) 
computer_init_player(_gsi.Players[tribe3]) 
computer_init_player(_gsi.Players[tribe4]) 
local AItribes = {TRIBE_BLUE,TRIBE_PINK,TRIBE_BLACK} --green is special
--
local balmCDR = -1
local seedCDR = -1
local enrageCDR = -1
local terraCDR = -1
local balmC3D = marker_to_coord3d(0)
local seedC3D = marker_to_coord3d(0)
local enrageC3D = marker_to_coord3d(0)
local terraC3D = marker_to_coord3d(0)
local game_loaded = false
local honorSaveTurnLimit = 0
local gameStage = 0
local BardLives = 6-difficulty()
local livesLock = 0
local lbLock = 0
--
--atk turns
tribe1Atk1 = 3500 + math.random(1000) - difficulty()*500
tribe1AtkSpells = {M_SPELL_LIGHTNING_BOLT,M_SPELL_INSECT_PLAGUE,M_SPELL_HYPNOTISM,M_SPELL_WHIRLWIND}
tribe1NavStress = 0
tribe2Atk1 = 4000 + math.random(1000) - difficulty()*500
tribe2AtkSpells = {M_SPELL_LIGHTNING_BOLT,M_SPELL_INSECT_PLAGUE,M_SPELL_HYPNOTISM,M_SPELL_WHIRLWIND}
tribe2NavStress = 0
tribe3Atk1 = 4500 + math.random(1000) - difficulty()*500
tribe3AtkSpells = {M_SPELL_LIGHTNING_BOLT,M_SPELL_INSECT_PLAGUE,M_SPELL_HYPNOTISM,M_SPELL_WHIRLWIND}
tribe3NavStress = 0
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
             --M_SPELL_EROSION,
             M_SPELL_EARTHQUAKE,
             M_SPELL_FIRESTORM,
             M_SPELL_SHIELD,
             --M_SPELL_FLATTEN,
             --	M_SPELL_VOLCANO,
             M_SPELL_ANGEL_OF_DEATH,
			 M_SPELL_BLOODLUST,
			 M_SPELL_TELEPORT
}
botBldgs = {M_BUILDING_TEPEE,
            M_BUILDING_DRUM_TOWER,
            M_BUILDING_WARRIOR_TRAIN,
            M_BUILDING_TEMPLE,
            M_BUILDING_SUPER_TRAIN,
            M_BUILDING_SPY_TRAIN,
			M_BUILDING_BOAT_HUT_1,
            --M_BUILDING_AIRSHIP_HUT_1
}
for t,w in ipairs (AItribes) do
	for k,v in ipairs(botSpells) do
		set_player_can_cast(v, w)
	end
	for k,v in ipairs(botBldgs) do
		set_player_can_build(v, w)
	end
end
--green
SET_ATTACK_VARIABLE(3,0)
STATE_SET(3, TRUE, CP_AT_TYPE_AUTO_ATTACK)
WRITE_CP_ATTRIB(3, ATTR_ATTACK_PERCENTAGE, 100)
WRITE_CP_ATTRIB(3, ATTR_MAX_ATTACKS, 999)
WRITE_CP_ATTRIB(3, ATTR_BASE_UNDER_ATTACK_RETREAT, 0)
WRITE_CP_ATTRIB(3, ATTR_RETREAT_VALUE, 0)
WRITE_CP_ATTRIB(3, ATTR_FIGHT_STOP_DISTANCE, 32)
WRITE_CP_ATTRIB(3, ATTR_GROUP_OPTION, 3)
STATE_SET(3, TRUE, CP_AT_TYPE_BRING_NEW_PEOPLE_BACK)
STATE_SET(3, TRUE, CP_AT_TYPE_HOUSE_A_PERSON)
STATE_SET(3, TRUE, CP_AT_TYPE_TRAIN_PEOPLE)
WRITE_CP_ATTRIB(3, ATTR_MAX_TRAIN_AT_ONCE, 3)
--
for i = 0,6 do
if i ~= 3 then
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
	if i == tribe3 then
		--boats
		WRITE_CP_ATTRIB(i, ATTR_PREF_BOAT_HUTS, 1)
		WRITE_CP_ATTRIB(i, ATTR_PREF_BOAT_DRIVERS, 2+difficulty())
		WRITE_CP_ATTRIB(i, ATTR_PEOPLE_PER_BOAT, 2+difficulty())
		WRITE_CP_ATTRIB(i, ATTR_DONT_USE_BOATS, 0)
	end
	--balloons
	--WRITE_CP_ATTRIB(i, ATTR_PREF_BALLOON_HUTS, 1)
	--WRITE_CP_ATTRIB(i, ATTR_PREF_BALLOON_DRIVERS, 2+difficulty())
	--WRITE_CP_ATTRIB(i, ATTR_PEOPLE_PER_BALLOON, 2+difficulty())
	--WRITE_CP_ATTRIB(i, ATTR_EMPTY_AT_WAYPOINT, 0) --leave balloon midway, and go on foot
	--attack
	SET_ATTACK_VARIABLE(i,0)
	STATE_SET(i, TRUE, CP_AT_TYPE_AUTO_ATTACK)
	WRITE_CP_ATTRIB(i, ATTR_ATTACK_PERCENTAGE, 100)
	WRITE_CP_ATTRIB(i, ATTR_MAX_ATTACKS, 999)
	WRITE_CP_ATTRIB(i, ATTR_BASE_UNDER_ATTACK_RETREAT, 0)
	WRITE_CP_ATTRIB(i, ATTR_RETREAT_VALUE, 0)
	WRITE_CP_ATTRIB(i, ATTR_FIGHT_STOP_DISTANCE, 32)
	WRITE_CP_ATTRIB(i, ATTR_GROUP_OPTION, 0)
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
end
SET_MARKER_ENTRY(tribe1,0,254,255,0,2+difficulty(),2+difficulty(),2) --br,war,fw,pre
SET_MARKER_ENTRY(tribe2,0,169,171,0,2+difficulty(),2+difficulty(),1) --br,war,fw,pre
SET_MARKER_ENTRY(tribe2,1,162,189,0,2+difficulty(),2+difficulty(),1) --br,war,fw,pre
SET_MARKER_ENTRY(tribe3,0,148,154,0,2+difficulty(),2+difficulty(),1) --br,war,fw,pre
--end
--shaman stuff
SHAMAN_DEFEND(tribe1, 138, 44, TRUE)
SET_DRUM_TOWER_POS(tribe1, 138, 44)
SHAMAN_DEFEND(tribe2, 76, 126, TRUE)
SET_DRUM_TOWER_POS(tribe2, 76, 126)
SHAMAN_DEFEND(tribe3, 34, 208, TRUE)
SET_DRUM_TOWER_POS(tribe3, 34, 208)
-------------------------------------------------------------------------------------------------------------------------------------------------
include("CSequence.lua");
local Engine = CSequence:createNew();
local dialog_msgs = {
	[0] = {"I can sense enemies nearby... My first challenge since my trial. <br> Guide me to victory, mother earth!", "Nomel", 6939, 2, 138},
	[1] = {"Congratulations on your trial, Nomel. You are now officially a bard! <br> Remember your limits: your lives are scarce - but acknowledge your perks: new unique ways of controlling your mana to create and maintain life. <br> But not only this - as promised, you have unlocked two higher tier bard spells. Use them wisely. ", "The Bard", 1783, 0, 225},
	[2] = {"I am grateful. The eastern winds whisper to me that four tribes defend this land. I must stand my ground.", "Nomel", 6939, 2, 138},
	[3] = {"...", "Nomel", 6939, 2, 138},
	[4] = {"Remember, your shaman will not reincarnate if you lose all your lives. <br> Bards can not charge land altering spells with mana, but they earn them occasionally, by killing enemies.", "Info", 173, 0, 160},
	[5] = {"Enrage is a new spell you can charge as a bard. <br> It affects some of your units in a area, sending them into a frenzy. They will temporarily become stronger, but their health will decay until they perish.", "Info", 173, 0, 160},
	[6] = {"Terra firma is the bard's destructive spell. <br> It calls upon mother earth, lowering and sinking the land in a great area, while lava gets expelled from the core. <br> You can read this spells info by using the encyclopaedia.", "Info", 173, 0, 160},
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

function EnrageSpell(pn,c3d)
	if enrageC3D ~= nil then
		local limit = 0
		SearchMapCells(SQUARE, 0, 0 , 3, world_coord3d_to_map_idx(c3d), function(me)
			me.MapWhoList:processList( function (t)
				if t.Type == T_PERSON and t.Model > 1 and t.Model < 7 and limit < 6-difficulty() and t.Owner == pn then --limit is 6-difficulty
					if (t.Flags2 & TF2_THING_IS_A_GHOST_PERSON == 0) then
						limit = limit + 1
						if (t.Flags3 & TF3_SHIELD_ACTIVE) == 0 then
							t.Flags3 = t.Flags3 | TF3_SHIELD_ACTIVE
							t.u.Pers.u.Owned.ShieldCount = -1
						end
						if (t.Flags3 & TF3_BLOODLUST_ACTIVE) == 0 then
							t.Flags3 = t.Flags3 | TF3_BLOODLUST_ACTIVE
							t.u.Pers.u.Owned.BloodlustCount = -1
						end
					end
				end
			return true end)
		return true end)
		if limit > 0 then queue_sound_event(nil,SND_EVENT_CMD_MENU_HILITE, SEF_FIXED_VARS) end
	end
end

function TerraSpell(pn,c3d)
	createThing(T_EFFECT,M_EFFECT_LAVA_FLOW,pn,c3d,false,false)
	createThing(T_EFFECT,M_EFFECT_GROUND_SHOCKWAVE,8,c3d,false,false)
	for i = 1,7 do
		local a = rnd()
		local dip = c3d
		if a < 25 then
			dip.Xpos = dip.Xpos + math.random(0,2200)
			dip.Zpos = dip.Zpos + math.random(0,2200)
		elseif a < 50 then
			dip.Xpos = dip.Xpos - math.random(0,2200)
			dip.Zpos = dip.Zpos - math.random(0,2200)
		elseif a < 75 then
			dip.Xpos = dip.Xpos - math.random(0,2200)
			dip.Zpos = dip.Zpos + math.random(0,2200)
		else
			dip.Xpos = dip.Xpos + math.random(0,2200)
			dip.Zpos = dip.Zpos - math.random(0,2200)
		end
		createThing(T_EFFECT,M_EFFECT_DIP,8,dip,false,false)
	end
	for i = 1,6 do
		local valley = c3d
		local a = rnd()
		if a < 25 then
			valley.Xpos = valley.Xpos + math.random(0,1700)
			valley.Zpos = valley.Zpos + math.random(0,1700)
		elseif a < 50 then
			valley.Xpos = valley.Xpos - math.random(0,1700)
			valley.Zpos = valley.Zpos - math.random(0,1700)
		elseif a < 75 then
			valley.Xpos = valley.Xpos - math.random(0,1700)
			valley.Zpos = valley.Zpos + math.random(0,1700)
		else
			valley.Xpos = valley.Xpos + math.random(0,1700)
			valley.Zpos = valley.Zpos - math.random(0,1700)
		end
		createThing(T_EFFECT,M_EFFECT_VALLEY,8,valley,false,false)
		createThing(T_EFFECT,M_EFFECT_VALLEY,8,valley,false,false)
	end
end



function OnTurn()
	if game_loaded then
		game_loaded = false
		
		Engine:postLoadItems()
		--kill honor loads
		if (difficulty() == 3) and turn() > honorSaveTurnLimit and honorSaveTurnLimit ~= 0 then
			ProcessGlobalSpecialList(player, PEOPLELIST, function(t)
				damage_person(t, 8, 20000, TRUE)
				return true
			end)
			TRIGGER_LEVEL_LOST() ; SET_NO_REINC(player)
			log_msg(8,"WARNING:  You have loaded the game while playing in \"honour\" mode.")
		end
	end
	if turn() == 12 then
		FLYBY_CREATE_NEW()
		FLYBY_ALLOW_INTERRUPT(FALSE)

		--start
		FLYBY_SET_EVENT_POS(232, 212, 1, 30)
		FLYBY_SET_EVENT_ANGLE(250, 1, 20)
		
		--bard
		FLYBY_SET_EVENT_POS(206, 214, 80, 30)
		FLYBY_SET_EVENT_ANGLE(1900, 80, 30)
		
		FLYBY_SET_EVENT_POS(206, 214, 115, 120)
		FLYBY_SET_EVENT_ANGLE(1800, 115, 120)
		
		FLYBY_SET_EVENT_POS(212, 208, 240, 400)
		FLYBY_SET_EVENT_ANGLE(1780, 240, 400)
		
		FLYBY_SET_EVENT_POS(224, 202, 440, 70)
		FLYBY_SET_EVENT_ANGLE(250, 440, 70)
		
		FLYBY_SET_EVENT_POS(226, 200, 520, 10)
		FLYBY_SET_EVENT_ANGLE(248, 520, 5)
		--
		
		FLYBY_START()
	elseif turn() == 24 then
		Engine:hidePanel()
		Engine:addCommand_CinemaRaise(0)
		Engine:addCommand_QueueMsg(dialog_msgs[0][1], dialog_msgs[0][2], 36, false, dialog_msgs[0][3], dialog_msgs[0][4], dialog_msgs[0][5], 12*8);
		Engine:addCommand_MoveThing(getShaman(player).ThingNum, marker_to_coord2d_centre(82), 60);
		Engine:addCommand_AngleThing(getShaman(player).ThingNum, 1750, 8);
		Engine:addCommand_QueueMsg(dialog_msgs[1][1], dialog_msgs[1][2], 36, false, dialog_msgs[1][3], dialog_msgs[1][4], dialog_msgs[1][5], 12*20);
		Engine:addCommand_MoveThing(getShaman(player).ThingNum, marker_to_coord2d_centre(0), 60);
		Engine:addCommand_AngleThing(getShaman(player).ThingNum, 1750, 8);
		Engine:addCommand_QueueMsg(dialog_msgs[2][1], dialog_msgs[2][2], 36, false, dialog_msgs[2][3], dialog_msgs[2][4], dialog_msgs[2][5], 12*3);
		Engine:addCommand_AngleThing(getShaman(player).ThingNum, 1000, 16);
		Engine:addCommand_QueueMsg(dialog_msgs[3][1], dialog_msgs[3][2], 36, false, dialog_msgs[3][3], dialog_msgs[3][4], dialog_msgs[3][5], 12*5);
		Engine:addCommand_CinemaHide(12);
		Engine:addCommand_ShowPanel(360);
		Engine:addCommand_QueueMsg(dialog_msgs[4][1], dialog_msgs[4][2], 60, false, dialog_msgs[4][3], dialog_msgs[4][4], dialog_msgs[4][5], 12*35);
		Engine:addCommand_QueueMsg(dialog_msgs[5][1], dialog_msgs[5][2], 60, false, dialog_msgs[5][3], dialog_msgs[5][4], dialog_msgs[5][5], 12*35);
		Engine:addCommand_QueueMsg(dialog_msgs[6][1], dialog_msgs[6][2], 60, false, dialog_msgs[6][3], dialog_msgs[6][4], dialog_msgs[6][5], 12);
	else
		Engine.DialogObj:processQueue();
		Engine:processCmd();
	end
	if turn() == 450 then createThing(T_EFFECT,M_EFFECT_BURN_CELL_OBSTACLES,8,marker_to_coord3d(133),false,false) end
	if turn() == 750 then honorSaveTurnLimit = turn() + 12*20 end
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
	--enrage spell
	if enrageCDR > 0 then 
		enrageCDR = enrageCDR - 1
	elseif enrageCDR == 0 then
		enrageCDR = -1
		EnrageSpell(player,enrageC3D)
	end
	--terra spell
	if terraCDR > 0 then 
		terraCDR = terraCDR - 1
	elseif terraCDR == 0 then
		terraCDR = -1
		TerraSpell(player,terraC3D)
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
	
	if every2Pow(3) then
		--remove a bard life
		if getShaman(player) == nil and livesLock == 0 then
			BardLives = BardLives - 1
			livesLock = 1
			if BardLives == 1 then	
				SET_NO_REINC(player)
			elseif BardLives == 0 then
				SearchMapCells(CIRCULAR, 0, 0 , 3, world_coord3d_to_map_idx(marker_to_coord3d(0)), function(me)
						me.Flags = me.Flags | (1<<16)
				return true
				end)
				TRIGGER_THING(248)
				ms_script_create_msg_information(702)
				SET_MSG_AUTO_OPEN_DLG()
			end
		elseif  getShaman(player) ~= nil and livesLock == 1 then
			livesLock = 0
		end
	end
	
	if every2Pow(2) then
		--bard earns lbs/flattens by killing enemies
		local pplKilled = _gsi.Players[player].PeopleKilled[tribe1] + _gsi.Players[player].PeopleKilled[tribe2] + _gsi.Players[player].PeopleKilled[tribe3] + _gsi.Players[player].PeopleKilled[tribe4]
		if pplKilled % (12+difficulty()*3+gameStage*3) == 0 and lbLock ~= pplKilled and pplKilled ~= 0 then
			lbLock = pplKilled
			local get,maxx = M_SPELL_LAND_BRIDGE,4
			if rnd() > 85 then get = M_SPELL_FLATTEN maxx = 3 end
			local shots = GET_NUM_ONE_OFF_SPELLS(player,get)
			if shots < maxx then
				_gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[get] = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[get] & 240
				_gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[get] = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[get] | shots+1
				queue_sound_event(nil,SND_EVENT_DISCOBLDG_START, SEF_FIXED_VARS)
			end
		end
		--enraged units lose HP
		ProcessGlobalSpecialList(player, PEOPLELIST, function(t)
			if (t.Flags3 & TF3_BLOODLUST_ACTIVE) > 0 and t.u.Pers.Life > 0 then
				if t ~= nil then
					local lose = math.floor((t.u.Pers.MaxLife*0.90)/100) --~1%
					t.u.Pers.Life = t.u.Pers.Life - lose
					if t.Model == M_PERSON_SUPER_WARRIOR then
						t.u.Pers.Life = math.floor(t.u.Pers.Life - (lose/2))
					end
				end
			end
		return true end)
	end
	
	-- new towers every x mins
	if everySeconds(200-(difficulty()*20)) and gameStage >= 1 then
		if _gsi.Players[tribe1].NumBuildingsOfType[M_BUILDING_DRUM_TOWER] < (12+(difficulty()*2)) then
			local rndTowMk = {250,220,38,230,226}
			local coord = MapPosXZ.new() ; coord.Pos = world_coord3d_to_map_idx(marker_to_coord3d(rndTowMk[math.random(#rndTowMk)]))
			BUILD_DRUM_TOWER(tribe1,coord.XZ.X, coord.XZ.Z)
		elseif _gsi.Players[tribe2].NumBuildingsOfType[M_BUILDING_DRUM_TOWER] < (12+(difficulty()*2)) then
			local rndTowMk = {182,251,188,161}
			local coord = MapPosXZ.new() ; coord.Pos = world_coord3d_to_map_idx(marker_to_coord3d(rndTowMk[math.random(#rndTowMk)]))
			BUILD_DRUM_TOWER(tribe2,coord.XZ.X, coord.XZ.Z)
		elseif _gsi.Players[tribe3].NumBuildingsOfType[M_BUILDING_DRUM_TOWER] < (12+(difficulty()*2)) then
			local rndTowMk = {158,149,146,252}
			local coord = MapPosXZ.new() ; coord.Pos = world_coord3d_to_map_idx(marker_to_coord3d(rndTowMk[math.random(#rndTowMk)]))
			BUILD_DRUM_TOWER(tribe3,coord.XZ.X, coord.XZ.Z)
		end
	end
	
	if everySeconds(32 - difficulty()*4 - (gameStage*2)) then
		--occasionally shield troops when attacking
		for i = 0,6 do
			local r = 0
			local defMk = 229 if i == 5 then defMk = 241 elseif i == 6 then defMk = 242 end
			if getShaman(i) ~= nil and IS_SHAMAN_IN_AREA(i,233,18) == 1 then
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
			elseif getShaman(i) ~= nil and IS_SHAMAN_IN_AREA(i,defMk,12) == 1 then
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
	end
	
	if everySeconds(20-(difficulty()*4)) then
		--AI shamans near blue base burn trees occasionally
		for i,v in ipairs(AItribes) do
			if getShaman(v) ~= nil and IS_SHAMAN_IN_AREA(v,233,16) == 1 and (getShaman(v).Flags2 & TF2_THING_IS_A_GHOST_PERSON == 0) then
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
		if READ_CP_ATTRIB(tribe3,ATTR_PREF_BOAT_DRIVERS) > 0 then
			if CountThingsOfTypeInArea(T_VEHICLE,M_VEHICLE_BOAT_1,tribe3,62,8,12) > 5+gameStage then
				WRITE_CP_ATTRIB(tribe3, ATTR_PREF_BOAT_DRIVERS, 0)
				WRITE_CP_ATTRIB(tribe3, ATTR_PEOPLE_PER_BOAT, 0)
			end
		else
			if CountThingsOfTypeInArea(T_VEHICLE,M_VEHICLE_BOAT_1,tribe3,62,8,12) < 5+gameStage then
				WRITE_CP_ATTRIB(tribe3, ATTR_PREF_BOAT_DRIVERS, 2+difficulty())
				WRITE_CP_ATTRIB(tribe3, ATTR_PEOPLE_PER_BOAT, 2+difficulty())
			end
		end
	end
	
	if every2Pow(4) then
		--troops train faster depending on difficulty
		ProcessGlobalTypeList(T_BUILDING, function(t)
			if (t.Type == T_BUILDING) then
				if (_gsi.Players[t.Owner].PlayerType == COMPUTER_PLAYER) then
					if (t.u.Bldg.ShapeThingIdx:isNull()) then
						if (t.u.Bldg.TrainingManaCost > 0) then
							t.u.Bldg.TrainingManaStored = t.u.Bldg.TrainingManaStored + (96*difficulty())
						end
					end
				end
			end
		return true end)
		--buildings faster green red bar if hard
		ProcessGlobalSpecialListAll(BUILDINGLIST, function(b)
			if (b.Model <= 3) and b.Owner ~= player then
				if (b.u.Bldg.UpgradeCount < 1850) then
					b.u.Bldg.UpgradeCount = b.u.Bldg.UpgradeCount + (difficulty()*5)
				end
				if (b.u.Bldg.SproggingCount < 1000) then
					b.u.Bldg.SproggingCount = b.u.Bldg.SproggingCount + (difficulty()*5)
				end
			end
		return true end)
		--stress from nav check, cast AoD
		if gameStage >= 2 then
			for k,v in ipairs(AItribes) do
				if v == 0 and tribe1NavStress > (7-difficulty()) then
					if getShaman(tribe1) ~= nil and IS_SHAMAN_AVAILABLE_FOR_ATTACK(tribe1) > 0 then
						GIVE_ONE_SHOT(M_SPELL_ANGEL_OF_DEATH,tribe1) ; SPELL_ATTACK(tribe1,M_SPELL_ANGEL_OF_DEATH,240,240) ; tribe1NavStress = 0
					end
				elseif v == 5 and tribe2NavStress > (7-difficulty()) then
					if getShaman(tribe2) ~= nil and IS_SHAMAN_AVAILABLE_FOR_ATTACK(tribe2) > 0 then
						GIVE_ONE_SHOT(M_SPELL_ANGEL_OF_DEATH,tribe2) ; SPELL_ATTACK(tribe2,M_SPELL_ANGEL_OF_DEATH,240,240) ; tribe2NavStress = 0
					end
				elseif v == 6 and tribe3NavStress > (7-difficulty()) then
					if getShaman(tribe3) ~= nil and IS_SHAMAN_AVAILABLE_FOR_ATTACK(tribe3) > 0 then
						GIVE_ONE_SHOT(M_SPELL_ANGEL_OF_DEATH,tribe3) ; SPELL_ATTACK(tribe3,M_SPELL_ANGEL_OF_DEATH,240,240) ; tribe3NavStress = 0
					end
				end
			end
		end
		--green tribe trains
		local housed = COUNT_PEOPLE_IN_HOUSES(tribe4)
		if housed > 3 then
			TRAIN_PEOPLE_NOW(tribe4,1,M_PERSON_WARRIOR)
		end
	end
	
	if everySeconds(60-(difficulty()*3)-gameStage*2) then
		--pray at guest spells stones
		if rnd() < 50 then
			local praying = count_people_of_type_in_area(90, 54, -1, -1, 1)
			if praying < 4 then
				WriteAiAttackers(TRIBE_BLUE,100,0,0,0,0,0)
				PRAY_AT_HEAD(TRIBE_BLUE,4-praying,253)
				WriteAiAttackers(TRIBE_BLUE,0,35,35,35,0,100)
			end
		else
			local praying = count_people_of_type_in_area(68, 160, -1, -1, 1)
			if praying < 3 then
				WriteAiAttackers(TRIBE_PINK,100,0,0,0,0,0)
				PRAY_AT_HEAD(TRIBE_PINK,3-praying,249)
				WriteAiAttackers(TRIBE_PINK,0,35,35,35,0,100)
			end
		end
		--green attacks
		if rnd() > 30 then
			if turn() > 1500 then
				if _gsi.Players[tribe4].NumPeopleOfType[M_PERSON_WARRIOR] > 1 + difficulty() + gameStage then
					WRITE_CP_ATTRIB(tribe4, ATTR_DONT_GROUP_AT_DT, 1)
					WRITE_CP_ATTRIB(tribe4, ATTR_FIGHT_STOP_DISTANCE, 26 + G_RANDOM(14))
					WriteAiAttackers(tribe4,0,100,0,0,0,0)
					local target = player
					local focus = ATTACK_BUILDING
					if _gsi.Players[player].NumBuildings == 0 then focus = ATTACK_PERSON end
					ATTACK(tribe4, player, 1 + difficulty() + gameStage, focus, 0, 999, 0, 0, 0, ATTACK_NORMAL, 0, -1, -1, 0)
				end
			end
		end
	end
	
	if everySeconds(90-difficulty()*5) then
		--preach mks
		local preachmks = {73,235,78,77,94,35,82}
		for k,v in ipairs(AItribes) do
			if _gsi.Players[v].NumPeopleOfType[M_PERSON_RELIGIOUS] > gameStage and rnd() > 40 and gameStage > 0 then
				PREACH_AT_MARKER(v,preachmks[math.random(#preachmks)])
			end
		end
		--defensive patrols
		MARKER_ENTRIES(tribe1,0,-1,-1,-1) MARKER_ENTRIES(tribe2,0,1,-1,-1) MARKER_ENTRIES(tribe3,0,-1,-1,-1)
	end
	
	--give AI spell shots occasionally
	if everySeconds(32-difficulty()*2) then
		for k,v in ipairs(AItribes) do
			if gameStage == 0 then
				GIVE_ONE_SHOT(M_SPELL_BLAST,v)
			elseif gameStage == 1 then
				GIVE_ONE_SHOT(M_SPELL_BLAST,v) if rnd() > 50 then GIVE_ONE_SHOT(M_SPELL_WHIRLWIND,v) end
			elseif gameStage == 2 then
				GIVE_ONE_SHOT(M_SPELL_BLAST,v) if rnd() > 50 then GIVE_ONE_SHOT(M_SPELL_WHIRLWIND,v) GIVE_ONE_SHOT(M_SPELL_HYPNOTISM,v) end
			else
				GIVE_ONE_SHOT(M_SPELL_BLAST,v) if rnd() > 50 then GIVE_ONE_SHOT(M_SPELL_WHIRLWIND,v) GIVE_ONE_SHOT(M_SPELL_HYPNOTISM,v) GIVE_ONE_SHOT(M_SPELL_EARTHQUAKE,v) end
			end
		end
	end
	--give AI spell shots rarely
	if everySeconds(64-(difficulty()*3)) then
		for k,v in ipairs(AItribes) do
			if gameStage == 0 then
				GIVE_ONE_SHOT(M_SPELL_INSECT_PLAGUE,v)
			elseif gameStage == 1 then
				GIVE_ONE_SHOT(M_SPELL_HYPNOTISM,v)
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
	
	if everySeconds(64-(difficulty()*3)) then
		--go expand wish shaman (lb)
		if rnd() > 60 then
			LBexpand(tribe2,244,245,2,3)
		elseif rnd() > 60 then
			LBexpand(tribe1,246,247,2,3)
		end
		--teleport attack pink
		if gameStage > 2 and getShaman(tribe2) ~= nil and IS_SHAMAN_AVAILABLE_FOR_ATTACK(tribe2) > 0 and FREE_ENTRIES(tribe2) > 4 then
			if I_HAVE_ONE_SHOT(tribe2,T_SPELL,M_SPELL_TELEPORT) == true and getShaman(tribe2).State ~= S_PERSON_WAIT_IN_BLDG and rnd() > 50 then
				local s1,s2,s3 = M_SPELL_HYPNOTISM,M_SPELL_LIGHTNING_BOLT,M_SPELL_ANGEL_OF_DEATH
				if _gsi.Players[player].NumBuildings > 0 then
					if difficulty() == 0 then
						s1,s2,s3 = M_SPELL_WHIRLWIND,M_SPELL_LIGHTNING_BOLT,M_SPELL_WHIRLWIND
						if gameStage > 1 then s2 = M_SPELL_HYPNOTISM end ; if gameStage > 2 then s3 = M_SPELL_EARTHQUAKE end
					elseif difficulty() == 1 then
						s1,s2,s3 = M_SPELL_WHIRLWIND,M_SPELL_WHIRLWIND,M_SPELL_WHIRLWIND
						if gameStage > 2 then s3 = M_SPELL_EARTHQUAKE end
					else
						s1,s2,s3 = M_SPELL_WHIRLWIND,M_SPELL_EARTHQUAKE,M_SPELL_WHIRLWIND
						if gameStage > 1 then s2 = M_SPELL_FIRESTORM end ; if gameStage > 2 then s3 = M_SPELL_ANGEL_OF_DEATH end
					end
				end
				GIVE_ONE_SHOT(s1,tribe2) GIVE_ONE_SHOT(s2,tribe2) GIVE_ONE_SHOT(s3,tribe2)
				local mks = {75,78,82,79,236,95,99}
				local mk = mks[math.random(#mks)]
				--SPELL_ATTACK(tribe2,M_SPELL_TELEPORT,mk,mk)
				WRITE_CP_ATTRIB(tribe2, ATTR_DONT_GROUP_AT_DT, 1)
				WRITE_CP_ATTRIB(tribe2, ATTR_GROUP_OPTION, 3)
				TARGET_S_WARRIORS(tribe2)
				WriteAiAttackers(tribe2,0,0,0,0,0,100)
				ATTACK(tribe2, player, 0, ATTACK_BUILDING, 0, 999, M_SPELL_WHIRLWIND, M_SPELL_EARTHQUAKE, M_SPELL_LIGHTNING_BOLT, ATTACK_NORMAL, 0, -1, -1, 0)
				createThing(T_EFFECT,M_EFFECT_TELEPORT, tribe2, marker_to_coord3d(mk), false, false)
				WRITE_CP_ATTRIB(tribe2, ATTR_DONT_GROUP_AT_DT, 0) WRITE_CP_ATTRIB(tribe2, ATTR_GROUP_OPTION, 0)
				local shots = GET_NUM_ONE_OFF_SPELLS(tribe2,M_SPELL_TELEPORT)
				if shots > 0 then
					_gsi.ThisLevelInfo.PlayerThings[tribe2].SpellsAvailableOnce[M_SPELL_TELEPORT] = _gsi.ThisLevelInfo.PlayerThings[tribe2].SpellsAvailableOnce[M_SPELL_TELEPORT] & 240
					_gsi.ThisLevelInfo.PlayerThings[tribe2].SpellsAvailableOnce[M_SPELL_TELEPORT] = _gsi.ThisLevelInfo.PlayerThings[tribe2].SpellsAvailableOnce[M_SPELL_TELEPORT] | shots-1
				else
					_gsi.ThisLevelInfo.PlayerThings[tribe2].SpellsAvailableOnce[M_SPELL_TELEPORT] = _gsi.ThisLevelInfo.PlayerThings[tribe2].SpellsAvailableOnce[M_SPELL_TELEPORT] & 240
					_gsi.ThisLevelInfo.PlayerThings[tribe2].SpellsAvailableOnce[M_SPELL_TELEPORT] = _gsi.ThisLevelInfo.PlayerThings[tribe2].SpellsAvailableOnce[M_SPELL_TELEPORT] | 0
				end
			end
		end
	end
	
	if everySeconds(10) then
		--send main attacks
		if tribe1Atk1 < turn() then SendAttack(tribe1) end
		if tribe2Atk1 < turn() then SendAttack(tribe2) end
		if tribe3Atk1 < turn() then SendAttack(tribe3) end
	end
	
	if every2Pow(6) then
		--update game stage (early,mid,late,very late)
		if minutes() < 8 then
			gameStage = 0
		elseif minutes() < 16 then
			gameStage = 1
		elseif minutes() < 24 then
			gameStage = 2
		elseif minutes() < 32 then
			gameStage = 3
		else
			gameStage = 4
		end
		
		for i,v in ipairs(AItribes) do
			if turn() > 1400 then WRITE_CP_ATTRIB(v, ATTR_EXPANSION, math.random(16,24)) end
			WRITE_CP_ATTRIB(v, ATTR_HOUSE_PERCENTAGE, 70+G_RANDOM(1+4*difficulty())+(difficulty()*6)+(gameStage*(4+difficulty()))) --base size
			WriteAiTrainTroops(v,12+difficulty(),13+difficulty(),15+difficulty(),0) --(pn,w,r,fw,spy)
			WRITE_CP_ATTRIB(v, ATTR_ATTACK_PERCENTAGE, 90+(minutes()*2)) --attack stuff
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
				--SET_SPELL_ENTRY(v, 3, M_SPELL_SWAMP, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> (1+difficulty()), 128, 13-difficulty(), 1)
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
				--SET_SPELL_ENTRY(v, 3, M_SPELL_SWAMP, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> (1+difficulty()), 128, 12-difficulty(), 0)
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
				if #tribe1AtkSpells < 6 then
					table.insert(tribe1AtkSpells,M_SPELL_ANGEL_OF_DEATH)
					if #tribe1AtkSpells == 6 and difficulty() >= 3 then
						table.insert(tribe1AtkSpells,M_SPELL_FIRESTORM)
					end
				end
				if #tribe2AtkSpells < 6 then
					table.insert(tribe2AtkSpells,M_SPELL_ANGEL_OF_DEATH)
					if #tribe2AtkSpells == 6 and difficulty() >= 3 then
						table.insert(tribe2AtkSpells,M_SPELL_FIRESTORM)
					end
				end
				if #tribe3AtkSpells < 6 then
					table.insert(tribe2AtkSpells,M_SPELL_WHIRLWIND)
					if #tribe2AtkSpells == 6 and difficulty() >= 3 then
						table.insert(tribe2AtkSpells,M_SPELL_FIRESTORM)
					end
				end
			elseif gameStage == 3 then
				if #tribe1AtkSpells < 6 then
					table.insert(tribe1AtkSpells,M_SPELL_EARTHQUAKE)
					if #tribe1AtkSpells == 6 and difficulty() >= 3 then
						table.insert(tribe1AtkSpells,M_SPELL_VOLCANO)
					end
				end
				if #tribe2AtkSpells < 6 then
					table.insert(tribe2AtkSpells,M_SPELL_EARTHQUAKE)
					if #tribe2AtkSpells == 6 and difficulty() >= 3 then
						table.insert(tribe2AtkSpells,M_SPELL_ANGEL_OF_DEATH)
					end
				end
				if #tribe3AtkSpells < 6 then
					table.insert(tribe3AtkSpells,M_SPELL_EARTHQUAKE)
					if #tribe3AtkSpells == 6 and difficulty() >= 3 then
						table.insert(tribe3AtkSpells,M_SPELL_FIRESTORM)
					end
				end
			end
			local atkpatrol = {78,77,74,85,87,133}
			local mk,mk2 = atkpatrol[math.random(#atkpatrol)],atkpatrol[math.random(#atkpatrol)]
			SET_MARKER_ENTRY(v,2,mk,mk2,0,2+gameStage,2+gameStage,2+gameStage) --br,war,fw,pre
		end
	end
end

--go LB expand
function LBexpand(tribe,mk1,mk2,stage,limit)
	--use 0 in stage and/or limit to ignore them (stage = only cast if game stage if equal or higher ; limit = only cast if hasnt expanded the limit ammount of times)
	if getShaman(tribe) ~= nil and gameStage >= stage and IS_SHAMAN_AVAILABLE_FOR_ATTACK(tribe) == 1 then
		if GET_SPELLS_CAST(tribe,M_SPELL_LAND_BRIDGE) < limit then
			GIVE_ONE_SHOT(M_SPELL_LAND_BRIDGE,tribe)
			if (NAV_CHECK(tribe,player,ATTACK_MARKER,mk1,0) > 0) then
				WRITE_CP_ATTRIB(tribe, ATTR_GROUP_OPTION, 2)
				WriteAiAttackers(tribe,0,0,0,0,0,100) --(pn,b,w,r,fw,spy,sh)
				ATTACK(tribe, player, 1, ATTACK_MARKER, mk2, 0, M_SPELL_LAND_BRIDGE, 0, 0, ATTACK_NORMAL, 0, mk1, mk2, 0)
				WRITE_CP_ATTRIB(tribe, ATTR_GROUP_OPTION, 0)
			end
		end
	end
end


function SendAttack(attacker)
	if (minutes() > 3-difficulty()) and (rnd() < 65+difficulty()*5 +gameStage*5) then
		WRITE_CP_ATTRIB(attacker, ATTR_FIGHT_STOP_DISTANCE, 28 + G_RANDOM(16))
		WriteAiAttackers(attacker,0,30+(gameStage*2),30,30+(gameStage*2),0,100) --(pn,b,w,r,fw,spy,sh)
		local target = player
		local numTroops = 0
		local boats = _gsi.Players[attacker].NumVehiclesOfType[M_VEHICLE_BOAT_1]
		local spell1,spell2,spell3 = 0,0,0
		local mk1,mk2 = -1,-1
		local stress = 0
		--check if enough pop and troops to attack
		local troopAmmount = GetTroops(attacker)
		if _gsi.Players[attacker].NumPeople > 32 and troopAmmount > 12 then
			numTroops = 3 + (difficulty()) + gameStage
		end
		--group options
		--if difficulty() >= 2 then
			WRITE_CP_ATTRIB(attacker, ATTR_DONT_GROUP_AT_DT, 0);
			WRITE_CP_ATTRIB(attacker, ATTR_GROUP_OPTION, 0);
		--else
			--WRITE_CP_ATTRIB(attacker, ATTR_DONT_GROUP_AT_DT, 0);
			--WRITE_CP_ATTRIB(attacker, ATTR_GROUP_OPTION, 0);
		--end
		--retreat
		if difficulty() < 2 then
			WRITE_CP_ATTRIB(attacker, ATTR_BASE_UNDER_ATTACK_RETREAT, 1)
			WRITE_CP_ATTRIB(attacker, ATTR_RETREAT_VALUE, math.random(2,6))
		else
			WRITE_CP_ATTRIB(attacker, ATTR_BASE_UNDER_ATTACK_RETREAT, 0)
			WRITE_CP_ATTRIB(attacker, ATTR_RETREAT_VALUE, 0)
		end
		--is shaman going
		if getShaman(attacker) ~= nil and gameStage > 0 and IS_SHAMAN_AVAILABLE_FOR_ATTACK(attacker) == 1 then
			WRITE_CP_ATTRIB(attacker, ATTR_AWAY_MEDICINE_MAN, 100);
			--lategame and hard and shaman, might cast invi/shield
			if difficulty() >= 1 and gameStage >= 2 then
				if rnd() > 50 then
					if rnd() > 50 then
						spell1 = M_SPELL_INVISIBILITY
						GIVE_ONE_SHOT(M_SPELL_INVISIBILITY,attacker)
					else
						spell1 = M_SPELL_SHIELD
						GIVE_ONE_SHOT(M_SPELL_SHIELD,attacker)
					end
					--if attacker == tribe1 then mk2 = 196 elseif attacker == tribe2 then mk2 = 197 elseif attacker == tribe3 then mk2 = 198 end
				end
			end
		else
			WRITE_CP_ATTRIB(attacker, ATTR_AWAY_MEDICINE_MAN, 0);
			mk2 = -1
		end
		if attacker == tribe1 then
			if GET_SPELLS_CAST(tribe1,M_SPELL_LAND_BRIDGE) > 0 then
				if rnd() < 50 then
					mk1 = 118
				else
					mk1 = 222
				end
			else
				mk1 = 222
			end
		elseif attacker == tribe2 then
			if rnd() < 50 then
				mk1 = 174
			else
				mk1 = 105 if rnd() < 50 then mk1 = 110 end
			end
		elseif attacker == tribe2 then
			mk1 = 154 if rnd() < 50 then mk1 = 136 end
		end
		--if attacker == tribe1 then mk1 = 196 elseif attacker == tribe2 then mk1 = 197 elseif attacker == tribe3 then mk1 = 198 end
		--give spell 1, 2 AND 3
		if READ_CP_ATTRIB(attacker,ATTR_AWAY_MEDICINE_MAN) == 100 then
			if attacker == tribe1 then
				if spell1 == 0 then
					spell1 = tribe1AtkSpells[math.random(#tribe1AtkSpells)]
				end
				spell2 = tribe1AtkSpells[math.random(#tribe1AtkSpells)]
				spell3 = tribe1AtkSpells[math.random(#tribe1AtkSpells)]
			elseif attacker == tribe2 then
				if spell1 == 0 then
					spell1 = tribe2AtkSpells[math.random(#tribe2AtkSpells)]
				end
				spell2 = tribe2AtkSpells[math.random(#tribe2AtkSpells)]
				spell3 = tribe2AtkSpells[math.random(#tribe2AtkSpells)]
			elseif attacker == tribe3 then
				if spell1 == 0 then
					spell1 = tribe3AtkSpells[math.random(#tribe3AtkSpells)]
				end
				spell2 = tribe3AtkSpells[math.random(#tribe3AtkSpells)]
				spell3 = tribe3AtkSpells[math.random(#tribe3AtkSpells)]
			end
		end
		if attacker == 0 and gameStage > 0 and rnd() > 20 then
			if I_HAVE_ONE_SHOT(tribe1,T_SPELL,M_SPELL_BLOODLUST) == true then
				spell1 = M_SPELL_BLOODLUST
			end
		end
		if rnd() > 70 then
			if attacker == tribe1 then
				if rnd() < 50 then target = tribe2 else target = tribe3 end
			elseif attacker == tribe2 then
				if rnd() < 50 then target = tribe1 else target = tribe3 end
			else
				if rnd() < 50 then target = tribe2 else target = tribe1 end
			end
		end
		if GetPop(target) == 0 then target = player end
		--LAUNCH ATTACK
		
		--has enough troops
		if numTroops > 0 then
			--prioritize buildings
			if _gsi.Players[target].NumBuildings > 0 then
				--can target bldg by land
				if (NAV_CHECK(attacker,target,ATTACK_BUILDING,0,0) > 0) then
					ATTACK(attacker, target, numTroops, ATTACK_BUILDING, 0, 969+(difficulty()*10), spell1, spell2, spell3, ATTACK_NORMAL, 1, mk1, mk2, 0)
					IncrementAtkVar(attacker,turn() + 2000 + G_RANDOM(2000) - (difficulty()*128) - (gameStage*100),true) --log_msg(attacker,"mini atk vs: " .. target .. "   bldg")
				else
					--try atk bldg from water
					if boats > 0 then
						ATTACK(attacker, target, numTroops, ATTACK_BUILDING, 0, 969+(difficulty()*10), spell1, spell2, spell3, ATTACK_BY_BOAT, 1, -1, -1, -1)
						IncrementAtkVar(attacker,turn() + 2000 + G_RANDOM(2000) - (difficulty()*128) - (gameStage*100),true) --log_msg(attacker,"mini atk vs: " .. target .. "   bldg boat")
					else
						--else attack units
						if _gsi.Players[target].NumPeople > 0 then
							if (NAV_CHECK(attacker,target,ATTACK_PERSON,0,0) > 0) then
								ATTACK(attacker, target, numTroops, ATTACK_PERSON, 0, 969+(difficulty()*10), spell1, spell2, spell3, ATTACK_NORMAL, 1, mk1, mk2, 0)
								IncrementAtkVar(attacker,turn() + 2000 + G_RANDOM(2000) - (difficulty()*128) - (gameStage*100),true) --log_msg(attacker,"mini atk vs: " .. target .. "   person")
							else
								--fail
								IncrementAtkVar(attacker,turn() + 500 + G_RANDOM(200) - (difficulty()*100) - (gameStage*50),true)
								stress = 1
							end
						else
							--fail
							IncrementAtkVar(attacker,turn() + 500 + G_RANDOM(200) - (difficulty()*100) - (gameStage*50),true)
							stress = 1
						end
					end
				end
			else
				--if no buildings, focus on units
				if _gsi.Players[target].NumPeople > 0 then
					if (NAV_CHECK(attacker,target,ATTACK_PERSON,0,0) > 0) then
						ATTACK(attacker, target, numTroops, ATTACK_PERSON, 0, 969+(difficulty()*10), spell1, spell2, spell3, ATTACK_NORMAL, 1, mk1, mk2, 0)
						IncrementAtkVar(attacker,turn() + 2000 + G_RANDOM(2000) - (difficulty()*128) - (gameStage*100),true) --log_msg(attacker,"mini atk vs: " .. target .. "   person")
					else
						--try to atk units from water
						if boats > 0 then
							ATTACK(attacker, target, numTroops, ATTACK_PERSON, 0, 969+(difficulty()*10), spell1, spell2, spell3, ATTACK_BY_BOAT, 1, -1, -1, -1)
							IncrementAtkVar(attacker,turn() + 2000 + G_RANDOM(2000) - (difficulty()*128) - (gameStage*100),true) --log_msg(attacker,"mini atk vs: " .. target .. "   person boat")
						else
							--fail
							IncrementAtkVar(attacker,turn() + 500 + G_RANDOM(200) - (difficulty()*100) - (gameStage*50),true)
							stress = 1
						end
					end
				else
					--fail
					IncrementAtkVar(attacker,turn() + 500 + G_RANDOM(200) - (difficulty()*100) - (gameStage*50),true)
					stress = 1
				end
			end
		end
		--increase nav stress (to cast AoD if cant attack many times in a row)
		if stress > 0 then
			if attacker == tribe1 then
				tribe1NavStress = tribe1NavStress + 1
			elseif attacker == tribe2 then
				tribe2NavStress = tribe2NavStress + 1
			elseif attacker == tribe3 then
				tribe3NavStress = tribe3NavStress + 1
			end
		else
			MARKER_ENTRIES(attacker,2,-1,-1,-1)
			local preachmks = {73,235,78,77,94,35,82}
			for i = 0,difficulty() do
				if _gsi.Players[attacker].NumPeopleOfType[M_PERSON_RELIGIOUS] > difficulty() then
					PREACH_AT_MARKER(attacker,preachmks[math.random(#preachmks)])
				end
			end
			if attacker == tribe1 then
				tribe1NavStress = 0
			elseif attacker == tribe2 then
				tribe2NavStress = 0
			elseif attacker == tribe3 then
				tribe3NavStress = 0
			end
		end
		--TrainUnitsNow(attacker)
	else
		IncrementAtkVar(attacker,turn()+500, true)
	end
	--log_msg(8,"" .. attacker .. "  " .. target .. "  " .. numTroops .. "  " .. variable .. "  " .. stress)
end

function IncrementAtkVar(pn,amt,mainAttack)
	if mainAttack == true then
		if pn == tribe1 then tribe1Atk1 = amt
		elseif pn == tribe2 then tribe2Atk1 = amt
		else tribe3Atk1 = amt end
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
	
	--honor save timer
	if turn() < honorSaveTurnLimit and honorSaveTurnLimit ~= 0 and difficulty() == 3 then
		PopSetFont(3)
		local hstl = "WARNING (honour mode): You can save, to avoid rewatching the intro   "
		LbDraw_Text(math.floor(w-2-(string_width("77:77:77 ")+string_width(tostring(hstl)))),2,tostring(hstl),0)
		LbDraw_Text(math.floor(w-2-(string_width("77:77:77 "))),2,tostring(TurnsToClock(math.floor((honorSaveTurnLimit-turn())/12))),0)
	end
	
	--bard lives
	for i = 1,BardLives do
		LbDraw_ScaledSprite(guiW+((i-1)*4)+((i-1)*box),4,get_sprite(0,1782),box,box)
	end
end



function OnCreateThing(t)
	--tree's angles
	if (t.Type == T_SCENERY) then
		if (t.Model < 7) then
			t.AngleXZ = G_RANDOM(2048)
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
		--enrage (erosion)
		if (t.Type == T_SPELL) and (t.Model == enrage) then
			t.Model = M_SPELL_NONE
			enrageCDR = 8
			enrageC3D = CopyC3d(t.Pos.D3)
			queue_sound_event(nil,SND_EVENT_BLDG_MENU_SPIN, SEF_FIXED_VARS)
			local shots = GET_NUM_ONE_OFF_SPELLS(t.Owner,enrage)
			_gsi.ThisLevelInfo.PlayerThings[t.Owner].SpellsAvailableOnce[enrage] = _gsi.ThisLevelInfo.PlayerThings[t.Owner].SpellsAvailableOnce[enrage] & 240
			_gsi.ThisLevelInfo.PlayerThings[t.Owner].SpellsAvailableOnce[enrage] = _gsi.ThisLevelInfo.PlayerThings[t.Owner].SpellsAvailableOnce[enrage] | shots-1
		end
		--terra Firma (volcano)
		if (t.Type == T_SPELL) and (t.Model == terra) then
			t.Model = M_SPELL_NONE
			queue_sound_event(nil,SND_EVENT_DO_CMDS, SEF_FIXED_VARS)
			terraCDR = 8
			terraC3D = CopyC3d(t.Pos.D3)
			queue_sound_event(nil,SND_EVENT_BLDG_MENU_POPUP, SEF_FIXED_VARS)
			local shots = GET_NUM_ONE_OFF_SPELLS(t.Owner,terra)
			_gsi.ThisLevelInfo.PlayerThings[t.Owner].SpellsAvailableOnce[terra] = _gsi.ThisLevelInfo.PlayerThings[t.Owner].SpellsAvailableOnce[terra] & 240
			_gsi.ThisLevelInfo.PlayerThings[t.Owner].SpellsAvailableOnce[terra] = _gsi.ThisLevelInfo.PlayerThings[t.Owner].SpellsAvailableOnce[terra] | shots-1
		end
	end
end


function OnSoundEvent(t_thing, event, flags) 
	if (event == SND_EVENT_SHAM_INVIS) or (event == SND_EVENT_SHAM_SWAMP) or (event == SND_EVENT_SHAM_ERODE) or (event == SND_EVENT_SHAM_VOLCANO) then
		--log_msg(8, string.format("Event: %i, Flags: %i", event, flags))
		return 1
	end
end


function OnSave(save_data)

	for i = #tribe1AtkSpells, 1 do
		save_data:push_int(tribe1AtkSpells[i])
	end
	save_data:push_int(#tribe1AtkSpells)
	for i = #tribe2AtkSpells, 1 do
		save_data:push_int(tribe2AtkSpells[i])
	end
	save_data:push_int(#tribe2AtkSpells)
	for i = #tribe3AtkSpells, 1 do
		save_data:push_int(tribe3AtkSpells[i])
	end
	save_data:push_int(#tribe3AtkSpells)
	
	save_data:push_int(enrageC3D.Xpos)
	save_data:push_int(enrageC3D.Zpos)
	save_data:push_int(enrageC3D.Ypos)
	save_data:push_int(terraC3D.Xpos)
	save_data:push_int(terraC3D.Zpos)
	save_data:push_int(terraC3D.Ypos)
	save_data:push_int(balmC3D.Xpos)
	save_data:push_int(balmC3D.Zpos)
	save_data:push_int(balmC3D.Ypos)
	save_data:push_int(seedC3D.Xpos)
	save_data:push_int(seedC3D.Zpos)
	save_data:push_int(seedC3D.Ypos)
	save_data:push_int(livesLock)
	save_data:push_int(BardLives)
	save_data:push_int(lbLock)
	save_data:push_int(honorSaveTurnLimit)
	save_data:push_int(gameStage)
	save_data:push_int(tribe1Atk1)
	save_data:push_int(tribe1NavStress)
	save_data:push_int(tribe2Atk1)
	save_data:push_int(tribe2NavStress)
	save_data:push_int(tribe3Atk1)
	save_data:push_int(tribe3NavStress)
	save_data:push_int(balmCDR)
	save_data:push_int(seedCDR)
	save_data:push_int(enrageCDR)
	save_data:push_int(terraCDR)
	Engine:saveData(save_data)
end

function OnLoad(load_data) 
	game_loaded = true

	Engine:loadData(load_data)
	terraCDR = load_data:pop_int()
	enrageCDR = load_data:pop_int()
	seedCDR = load_data:pop_int()
	balmCDR = load_data:pop_int()
	tribe3NavStress = load_data:pop_int()
	tribe3Atk1 = load_data:pop_int()
	tribe2NavStress = load_data:pop_int()
	tribe2Atk1 = load_data:pop_int()
	tribe1NavStress = load_data:pop_int()
	tribe1Atk1 = load_data:pop_int()
	gameStage = load_data:pop_int()
	honorSaveTurnLimit = load_data:pop_int()
	lbLock = load_data:pop_int()
	BardLives = load_data:pop_int()
	livesLock = load_data:pop_int()
	seedC3D.Ypos = load_data:pop_int()
	seedC3D.Zpos = load_data:pop_int()
	seedC3D.Xpos = load_data:pop_int()
	balmC3D.Ypos = load_data:pop_int()
	balmC3D.Zpos = load_data:pop_int()
	balmC3D.Xpos = load_data:pop_int()
	terraC3D.Zpos = load_data:pop_int()
	terraC3D.Ypos = load_data:pop_int()
	terraC3D.Xpos = load_data:pop_int()
	enrageC3D.Zpos = load_data:pop_int()
	enrageC3D.Ypos = load_data:pop_int()
	enrageC3D.Xpos = load_data:pop_int()
	
	local numSpellsAtk3 = load_data:pop_int();
	for i = 1, numSpellsAtk3 do
		 tribe3AtkSpells[i] = load_data:pop_int();
	end
	local numSpellsAtk2 = load_data:pop_int();
	for i = 1, numSpellsAtk2 do
		 tribe2AtkSpells[i] = load_data:pop_int();
	end
	local numSpellsAtk1 = load_data:pop_int();
	for i = 1, numSpellsAtk1 do
		 tribe1AtkSpells[i] = load_data:pop_int();
	end
end