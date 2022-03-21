-- gonna cry?

import(Module_Defines)
import(Module_Map)
import(Module_Objects)
import(Module_DataTypes)
import(Module_Game)
import(Module_Table)
import(Module_MapWho)
import(Module_System)
import(Module_Globals)
import(Module_Players)
import(Module_PopScript)
import(Module_Math)
import(Module_String)
import(Module_ImGui)
import(Module_Draw)
import(Module_Person)
import(Module_Package)
import(Module_GameStates)
import(Module_StringTools)
import(Module_Sound)
include("assets.lua")
local gns = gnsi()
local gs = gsi()
computer_init_player(_gsi.Players[TRIBE_GREEN])
--[[

 0 - Stop at waypoint (if exists) and before attack
 1 - Stop before attack only
 2 - Stop at waypoint (if exists) only
 3 - Don't stop anywhere

]]
		WRITE_CP_ATTRIB(3, ATTR_DONT_GROUP_AT_DT, 0)
		
		
		
		
		STATE_SET(3, TRUE, CP_AT_TYPE_BUILD_VEHICLE)
		STATE_SET(3, TRUE, CP_AT_TYPE_FETCH_FAR_VEHICLE)
		WRITE_CP_ATTRIB(3, ATTR_PREF_BOAT_HUTS, 1)
		WRITE_CP_ATTRIB(3, ATTR_PREF_BOAT_DRIVERS, 5)
		WRITE_CP_ATTRIB(3, ATTR_PEOPLE_PER_BOAT, 5)
		WRITE_CP_ATTRIB(3, ATTR_PREF_BALLOON_HUTS, 1)
		WRITE_CP_ATTRIB(3, ATTR_PREF_BALLOON_DRIVERS, 4)
		WRITE_CP_ATTRIB(3, ATTR_PEOPLE_PER_BALLOON, 4)


function OnTurn()

	if (gs.Counts.ProcessThings == 120) then
		log_msg(0,"1st attack: group 0 (Stop before attack, and at waypoint (if exists)) - without waypoint")
		log_msg(1,"the fire is the ATTR_FIGHT_STOP_DISTANCE (13 radius from target)")
		log_msg(3,"the mini island is the waypoint")
		--WRITE_CP_ATTRIB(TRIBE_GREEN, ATTR_FIGHT_STOP_DISTANCE, 16)
		ATTACK(TRIBE_GREEN, TRIBE_BLUE, 2, ATTACK_BUILDING, 0, 999, INT_NO_SPECIFIC_SPELL, INT_NO_SPECIFIC_SPELL, INT_NO_SPECIFIC_SPELL , ATTACK_BY_BOAT, 0, -1, -1, 0)
		--4 is sending like 8 people wtf, 3 sends like 5, 1 sends 1 nice logic
		--LOG(GET_NUM_OF_AVAILABLE_BOATS(3))
		--GET_NUM_OF_AVAILABLE_BOATS() WHY THIS DOESNT EXIST FOR BALLOONS???????????? GG; and i think even this func bugs
	end
	
	if (gs.Counts.ProcessThings == 666) then
		log_msg(0,"2nd attack: group 0 (Stop before attack, and at waypoint (if exists)) - with waypoint")
		log_msg(1,"the fire is the ATTR_FIGHT_STOP_DISTANCE (13 radius from target)")
		log_msg(3,"the mini island is the waypoint")
		ATTACK(TRIBE_GREEN, TRIBE_BLUE, 1, ATTACK_BUILDING, 0, 999, INT_NO_SPECIFIC_SPELL, INT_NO_SPECIFIC_SPELL, INT_NO_SPECIFIC_SPELL , ATTACK_BY_BOAT, 0, 1, -1, 0)
	end
	
	if (gs.Counts.ProcessThings == 1111) then
		WRITE_CP_ATTRIB(3, ATTR_GROUP_OPTION, 1)
		log_msg(0,"3rd attack: group 1 (Stop before attack only)")
		log_msg(1,"the fire is the ATTR_FIGHT_STOP_DISTANCE (13 radius from target)")
		log_msg(3,"the mini island is the waypoint")
		ATTACK(TRIBE_GREEN, TRIBE_BLUE, 1, ATTACK_BUILDING, 0, 999, INT_NO_SPECIFIC_SPELL, INT_NO_SPECIFIC_SPELL, INT_NO_SPECIFIC_SPELL , ATTACK_BY_BALLOON, 0, -1, -1, 0)
	end
	
	if (gs.Counts.ProcessThings == 1666) then
		WRITE_CP_ATTRIB(3, ATTR_GROUP_OPTION, 1)
		log_msg(0,"4th attack: group 1 (Stop before attack only - but this time using a waypoint on island (shouldn't affect))")
		log_msg(1,"the fire is the ATTR_FIGHT_STOP_DISTANCE (13 radius from target)")
		log_msg(3,"the mini island is the waypoint")
		ATTACK(TRIBE_GREEN, TRIBE_BLUE, 1, ATTACK_BUILDING, 0, 999, INT_NO_SPECIFIC_SPELL, INT_NO_SPECIFIC_SPELL, INT_NO_SPECIFIC_SPELL , ATTACK_BY_BALLOON, 0, 1, -1, 0)
	end
	
	if (gs.Counts.ProcessThings == 2111) then
		WRITE_CP_ATTRIB(3, ATTR_GROUP_OPTION, 2)
		log_msg(0,"5th attack: group 2 (Stop at waypoint (if exists) only) - without waypoint")
		log_msg(1,"the fire is the ATTR_FIGHT_STOP_DISTANCE (13 radius from target)")
		log_msg(3,"the mini island is the waypoint")
		ATTACK(TRIBE_GREEN, TRIBE_BLUE, 1, ATTACK_BUILDING, 0, 999, INT_NO_SPECIFIC_SPELL, INT_NO_SPECIFIC_SPELL, INT_NO_SPECIFIC_SPELL , ATTACK_BY_BALLOON, 0, -1, -1, 0)
	end
	
	if (gs.Counts.ProcessThings == 2666) then
		WRITE_CP_ATTRIB(3, ATTR_GROUP_OPTION, 2)
		log_msg(0,"6th attack: group 2 (Stop at waypoint (if exists) only) - now with waypoint")
		log_msg(1,"the fire is the ATTR_FIGHT_STOP_DISTANCE (13 radius from target)")
		log_msg(3,"the mini island is the waypoint")
		ATTACK(TRIBE_GREEN, TRIBE_BLUE, 1, ATTACK_BUILDING, 0, 999, INT_NO_SPECIFIC_SPELL, INT_NO_SPECIFIC_SPELL, INT_NO_SPECIFIC_SPELL , ATTACK_BY_BALLOON, 0, 1, -1, 0)
	end
	
	if (gs.Counts.ProcessThings == 3111) then
		WRITE_CP_ATTRIB(3, ATTR_GROUP_OPTION, 3)
		log_msg(0,"7th attack: group 3 (Don't stop anywhere) - without waypoint")
		log_msg(1,"the fire is the ATTR_FIGHT_STOP_DISTANCE (13 radius from target)")
		log_msg(3,"the mini island is the waypoint")
		ATTACK(TRIBE_GREEN, TRIBE_BLUE, 1, ATTACK_BUILDING, 0, 999, INT_NO_SPECIFIC_SPELL, INT_NO_SPECIFIC_SPELL, INT_NO_SPECIFIC_SPELL , ATTACK_BY_BALLOON, 0, -1, -1, 0)
	end
	
	if (gs.Counts.ProcessThings == 3666) then
		WRITE_CP_ATTRIB(3, ATTR_GROUP_OPTION, 3)
		log_msg(0,"8th attack: group 3 (Don't stop anywhere) - with waypoint")
		log_msg(1,"the fire is the ATTR_FIGHT_STOP_DISTANCE (13 radius from target)")
		log_msg(3,"the mini island is the waypoint")
		ATTACK(TRIBE_GREEN, TRIBE_BLUE, 1, ATTACK_BUILDING, 0, 999, INT_NO_SPECIFIC_SPELL, INT_NO_SPECIFIC_SPELL, INT_NO_SPECIFIC_SPELL , ATTACK_BY_BALLOON, 0, 1, -1, 0)
	end


end -- END OF ON TURN --


-- GREEN



_gsi.ThisLevelInfo.PlayerThings[TRIBE_GREEN].BuildingsAvailable = _gsi.ThisLevelInfo.PlayerThings[TRIBE_GREEN].BuildingsAvailable | (1<<M_BUILDING_TEPEE)
_gsi.ThisLevelInfo.PlayerThings[TRIBE_GREEN].BuildingsAvailable = _gsi.ThisLevelInfo.PlayerThings[TRIBE_GREEN].BuildingsAvailable | (1<<M_BUILDING_WARRIOR_TRAIN)
_gsi.ThisLevelInfo.PlayerThings[TRIBE_GREEN].BuildingsAvailable = _gsi.ThisLevelInfo.PlayerThings[TRIBE_GREEN].BuildingsAvailable | (1<<M_BUILDING_DRUM_TOWER)
_gsi.ThisLevelInfo.PlayerThings[TRIBE_GREEN].BuildingsAvailable = _gsi.ThisLevelInfo.PlayerThings[TRIBE_GREEN].BuildingsAvailable | (1<<M_BUILDING_SUPER_TRAIN)

SET_DRUM_TOWER_POS(TRIBE_GREEN, 238, 82)
SHAMAN_DEFEND(TRIBE_GREEN, 238, 82, TRUE)

STATE_SET(3, TRUE, CP_AT_TYPE_FETCH_WOOD)
STATE_SET(3, TRUE, CP_AT_TYPE_CONSTRUCT_BUILDING)
STATE_SET(3, TRUE, CP_AT_TYPE_BUILD_OUTER_DEFENCES)
STATE_SET(3, TRUE, CP_AT_TYPE_DEFEND)
STATE_SET(3, TRUE, CP_AT_TYPE_DEFEND_BASE)
STATE_SET(3, FALSE, CP_AT_TYPE_PREACH)
STATE_SET(3, TRUE, CP_AT_TYPE_BRING_NEW_PEOPLE_BACK)
STATE_SET(3, TRUE, CP_AT_TYPE_SUPER_DEFEND)
STATE_SET(3, TRUE, CP_AT_TYPE_TRAIN_PEOPLE)
STATE_SET(3, TRUE, CP_AT_TYPE_AUTO_ATTACK)
STATE_SET(3, TRUE, CP_AT_TYPE_HOUSE_A_PERSON)
STATE_SET(3, TRUE, CP_AT_TYPE_POPULATE_DRUM_TOWER)
STATE_SET(3, TRUE, CP_AT_TYPE_FETCH_LOST_PEOPLE)
STATE_SET(3, TRUE, CP_AT_TYPE_MED_MAN_GET_WILD_PEEPS)

WRITE_CP_ATTRIB(3, ATTR_EXPANSION, 0)
WRITE_CP_ATTRIB(3, ATTR_HOUSE_PERCENTAGE, 20 +G_RANDOM(5))
WRITE_CP_ATTRIB(3, ATTR_MAX_BUILDINGS_ON_GO, 1)
WRITE_CP_ATTRIB(3, ATTR_PREF_WARRIOR_TRAINS, 1)
WRITE_CP_ATTRIB(3, ATTR_PREF_WARRIOR_PEOPLE, 16)
WRITE_CP_ATTRIB(3, ATTR_PREF_RELIGIOUS_TRAINS, 0)
WRITE_CP_ATTRIB(3, ATTR_PREF_RELIGIOUS_PEOPLE, 0)
WRITE_CP_ATTRIB(3, ATTR_PREF_SUPER_WARRIOR_TRAINS, 0)
WRITE_CP_ATTRIB(3, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 0)
WRITE_CP_ATTRIB(3, ATTR_PREF_SPY_TRAINS, 0)
WRITE_CP_ATTRIB(3, ATTR_PREF_SPY_PEOPLE, 0)

WRITE_CP_ATTRIB(3, ATTR_GROUP_OPTION, 0)
WRITE_CP_ATTRIB(3, ATTR_AWAY_BRAVE, 0)
WRITE_CP_ATTRIB(3, ATTR_AWAY_WARRIOR, 100)
WRITE_CP_ATTRIB(3, ATTR_AWAY_RELIGIOUS, 50)
WRITE_CP_ATTRIB(3, ATTR_AWAY_SUPER_WARRIOR, 50)
WRITE_CP_ATTRIB(3, ATTR_AWAY_SPY, 0)
WRITE_CP_ATTRIB(3, ATTR_AWAY_MEDICINE_MAN, 0)

SET_DEFENCE_RADIUS(3, 5)
WRITE_CP_ATTRIB(3, ATTR_USE_PREACHER_FOR_DEFENCE, 0)
WRITE_CP_ATTRIB(3, ATTR_DEFENSE_RAD_INCR, 2)
WRITE_CP_ATTRIB(3, ATTR_MAX_DEFENSIVE_ACTIONS, 3)
WRITE_CP_ATTRIB(3, ATTR_ATTACK_PERCENTAGE, 100)
WRITE_CP_ATTRIB(3, ATTR_MAX_ATTACKS, 999)
WRITE_CP_ATTRIB(3, ATTR_RETREAT_VALUE, 2 +G_RANDOM(3))
WRITE_CP_ATTRIB(3, ATTR_BASE_UNDER_ATTACK_RETREAT, 0)
WRITE_CP_ATTRIB(3, ATTR_RANDOM_BUILD_SIDE, 1)

WRITE_CP_ATTRIB(3, ATTR_ENEMY_SPY_MAX_STAND, 255)
WRITE_CP_ATTRIB(3, ATTR_SPY_CHECK_FREQUENCY, 128)
WRITE_CP_ATTRIB(3, ATTR_SPY_DISCOVER_CHANCE, 30)
WRITE_CP_ATTRIB(3, ATTR_MAX_TRAIN_AT_ONCE, 2)
WRITE_CP_ATTRIB(3, ATTR_SHAMEN_BLAST, 64)
