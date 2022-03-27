--spring level 2: Tribal Ascending

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
ency[27].StrId = 690
ency[32].StrId = 691
ency[22].StrId = 692
ency[35].StrId = 695
ency[38].StrId = 696
include("assets.lua")
gns.GameParams.Flags3 = gns.GameParams.Flags3 | GPF3_FOG_OF_WAR_KEEP_STATE
set_level_type(13)
--------------------
sti[M_SPELL_GHOST_ARMY].Active = SPAC_OFF
sti[M_SPELL_GHOST_ARMY].NetworkOnly = 1
sti[M_SPELL_INVISIBILITY].OneOffMaximum = 4
sti[M_SPELL_INVISIBILITY].WorldCoordRange = 4096
sti[M_SPELL_INVISIBILITY].CursorSpriteNum = 45
sti[M_SPELL_INVISIBILITY].ToolTipStrIdx = 818
sti[M_SPELL_INVISIBILITY].AvailableSpriteIdx = 359
sti[M_SPELL_INVISIBILITY].NotAvailableSpriteIdx = 377
sti[M_SPELL_INVISIBILITY].ClickedSpriteIdx = 395
sti[M_SPELL_SWAMP].OneOffMaximum = 3
sti[M_SPELL_SWAMP].WorldCoordRange = 4096
sti[M_SPELL_SWAMP].CursorSpriteNum = 53
sti[M_SPELL_SWAMP].ToolTipStrIdx = 823
sti[M_SPELL_SWAMP].AvailableSpriteIdx = 364
sti[M_SPELL_SWAMP].NotAvailableSpriteIdx = 382
sti[M_SPELL_SWAMP].ClickedSpriteIdx = 400
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
local tribe1 = TRIBE_RED
local tribe2 = TRIBE_BLACK
computer_init_player(_gsi.Players[tribe1])
--computer_init_player(_gsi.Players[tribe2])
local AItribes = {TRIBE_RED,TRIBE_BLACK}
--
--vars
local game_loaded = false
local level = 0
local faction1,faction2,faction3 = 0,0,0 -- "flame","river" ; "thunder","nature" ; "pestilence","eagle"
local g_DrawMenu = false
local gameStage = 0 --early game
local honorSaveTurnLimit = 1200 +12*20
local factionTimerIncrement = 3400--~5mins
local levelUpTurn = 3400+(120*12)+math.random(400)+(difficulty()*300)
local talk1,talk2,talk3 = 0,0,0
local day = 1
local turnDayChanges = 720*2 +720
local thunderGet = 0
local pestilence1Get = 0
local pestilence2Get = 0
local eagleGet = 0
local atkRoulette = 0

function Plant(IdxS,IdxE,drawnum)
	for i = IdxS,IdxE do
		local plants = createThing(T_SCENERY,M_SCENERY_PLANT_2,8,marker_to_coord3d(i),false,false) centre_coord3d_on_block(plants.Pos.D3)
		plants.DrawInfo.DrawNum = drawnum ; plants.DrawInfo.Alpha = -16
	end
end

--vars that cant be initialized more than once
if turn() == 0 then
	Plant(153,155,1792)
	Plant(156,158,1794)
	Plant(159,164,1787)
	for i = 131,152 do
		plants = createThing(T_SCENERY,M_SCENERY_PLANT_2,8,marker_to_coord3d(i),false,false) centre_coord3d_on_block(plants.Pos.D3)
		plants.DrawInfo.DrawNum = math.random(1787,1795) plants.DrawInfo.Alpha = -16
	end
	--
	local fog = createThing(T_EFFECT, 95, 0, marker_to_coord3d(255), false, false) ; fog.u.Effect.Count = 2 --remove visual bug from textures (dark fog)
	set_player_reinc_site_off(getPlayer(TRIBE_BLUE))
	Ypreacher = createThing(T_PERSON,M_PERSON_RELIGIOUS,3,marker_to_coord3d(1),false,false)
	Bwar1 = createThing(T_PERSON,M_PERSON_WARRIOR,0,marker_to_coord3d(9),false,false)
	Bwar2 = createThing(T_PERSON,M_PERSON_WARRIOR,0,marker_to_coord3d(10),false,false)
	getPlayer(0).ReincarnSiteCoord = marker_to_coord3d(255)
	SearchMapCells(SQUARE, 0, 0 , 4, world_coord3d_to_map_idx(marker_to_coord3d(13)), function(me)
			me.Flags = me.Flags ~ (1<<16)
	return true
	end)
	SearchMapCells(SQUARE, 0, 0 , 0, world_coord3d_to_map_idx(marker_to_coord3d(130)), function(me)
			me.Flags = me.Flags ~ (1<<16)
	return true
	end)
	--create the magical artifact that grants factions
	local factionOrb = createThing(T_EFFECT,10,8,marker_to_coord3d(0),false,false) centre_coord3d_on_block(factionOrb.Pos.D3) ; set_thing_draw_info(factionOrb,TDI_SPRITE_F16_D1_ALPHA, 1417) 
	factionOrb.u.Effect.Duration = -1 ; factionOrb.DrawInfo.Alpha = -16
end
--------------------
botSpells = {M_SPELL_CONVERT_WILD,
             M_SPELL_BLAST,
             M_SPELL_LAND_BRIDGE,
             M_SPELL_LIGHTNING_BOLT,
             M_SPELL_INSECT_PLAGUE,
             M_SPELL_INVISIBILITY,
             M_SPELL_GHOST_ARMY,
             M_SPELL_SWAMP,
             M_SPELL_HYPNOTISM,
             M_SPELL_WHIRLWIND,
             M_SPELL_EROSION,
             M_SPELL_EARTHQUAKE,
             M_SPELL_FIRESTORM,
             M_SPELL_SHIELD,
             --M_SPELL_FLATTEN,
             --M_SPELL_VOLCANO,
             M_SPELL_ANGEL_OF_DEATH
}
botBldgs = {M_BUILDING_TEPEE,
            M_BUILDING_DRUM_TOWER,
            M_BUILDING_WARRIOR_TRAIN,
            M_BUILDING_TEMPLE,
            M_BUILDING_SUPER_TRAIN,
            --M_BUILDING_SPY_TRAIN,
			 M_BUILDING_BOAT_HUT_1,
            --M_BUILDING_AIRSHIP_HUT_1
}

--atk turns
tribe1Atk1 = 2500 + math.random(444) - difficulty()*100
--tribe1Atk2 = nil
tribe1MiniAtk1 = 1730 - difficulty()*50
--tribe1MiniAtk2 = nil
--tribe1MiniAtk3 = nil
tribe1AtkSpells = {M_SPELL_LIGHTNING_BOLT,M_SPELL_INSECT_PLAGUE,M_SPELL_HYPNOTISM,M_SPELL_WHIRLWIND}
tribe1NavStress = 0
--
tribe2Atk1 = 2900 + math.random(444) - difficulty()*100
--tribe2Atk2 = nil
tribe2MiniAtk1 = 2160 - difficulty()*50
--tribe2MiniAtk2 = nil
--tribe2MiniAtk3 = nil
tribe2AtkSpells = {M_SPELL_LIGHTNING_BOLT,M_SPELL_INSECT_PLAGUE,M_SPELL_HYPNOTISM,M_SPELL_WHIRLWIND}
tribe2NavStress = 0
--M_SPELL_LIGHTNING_BOLT,M_SPELL_INSECT_PLAGUE,M_SPELL_HYPNOTISM,M_SPELL_WHIRLWIND,M_SPELL_SWAMP,M_SPELL_EROSION,M_SPELL_EARTHQUAKE,M_SPELL_FIRESTORM,M_SPELL_ANGEL_OF_DEATH,M_SPELL_VOLCANO

SET_MARKER_ENTRY(tribe1,0,38,39,0,2+gameStage,0,0) --war,fw,pre
SET_MARKER_ENTRY(tribe1,1,40,-1,0,2+gameStage,1,0)
SET_MARKER_ENTRY(tribe1,2,41,-1,0,2+gameStage,0,0)
SET_MARKER_ENTRY(tribe1,3,42,43,0,2+gameStage,0,1)
SET_MARKER_ENTRY(tribe1,4,44,44,0,0,2,0)
SET_MARKER_ENTRY(tribe1,5,45,45,0,0,2,0)
SET_MARKER_ENTRY(tribe1,6,46,46,0,0,2,0)
SET_MARKER_ENTRY(tribe1,7,47,47,0,0,2,0)
SET_MARKER_ENTRY(tribe1,8,48,48,0,0,2,0)
SET_MARKER_ENTRY(tribe1,9,49,49,0,0,2,0)

SET_MARKER_ENTRY(tribe2,0,57,-1,0,2+gameStage,0,0)
SET_MARKER_ENTRY(tribe2,1,58,59,0,2+gameStage,1,0)
SET_MARKER_ENTRY(tribe2,2,60,-1,0,2+gameStage,0,1)
SET_MARKER_ENTRY(tribe2,3,61,61,0,0,2,0)
SET_MARKER_ENTRY(tribe2,4,62,62,0,0,2,0)
SET_MARKER_ENTRY(tribe2,5,63,63,0,0,2,0)
SET_MARKER_ENTRY(tribe2,6,64,64,0,0,2,0)
SET_MARKER_ENTRY(tribe2,7,65,65,0,0,2,0)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--LEVEL VARIABLES--------------------------------------------------------------------------------------------------------------------------------
AI = {
		ai1 = {
					pop = 0,
					troops = 0,
					braves = 0,
					wars = 0,
					fws = 0,
					spies = 0,
					preachers = 0,
					buildings = 0,
					huts = 0,
					towers = 0,
				 },
		ai2 = {
					pop = 0,
					troops = 0,
					braves = 0,
					wars = 0,
					fws = 0,
					spies = 0,
					preachers = 0,
					buildings = 0,
					huts = 0,
					towers = 0,
				 }
}

function TrainUnitsNow(pn)
	if rnd() < 80 then --80% chance for main code executte
		local braves = _gsi.Players[pn].NumPeopleOfType[M_PERSON_BRAVE]
		local troopAmmount = (_gsi.Players[pn].NumPeople-_gsi.Players[pn].NumPeopleOfType[M_PERSON_BRAVE])
		if	troopAmmount < math.floor(braves/3) then
			if rnd() < 55 and _gsi.Players[pn].NumPeopleOfType[M_PERSON_WARRIOR] < 8+gameStage*2 then TRAIN_PEOPLE_NOW(pn,1,M_PERSON_WARRIOR) end
			if rnd() < 55 and _gsi.Players[pn].NumPeopleOfType[M_PERSON_RELIGIOUS] < 7+gameStage*2 then TRAIN_PEOPLE_NOW(pn,1,M_PERSON_RELIGIOUS) end
			if rnd() < 55 and _gsi.Players[pn].NumPeopleOfType[M_PERSON_SUPER_WARRIOR] < 6+gameStage*2 then TRAIN_PEOPLE_NOW(pn,1,M_PERSON_SUPER_WARRIOR) end
		end
	end
end

function IncrementAtkVar(pn,amt,mainAttack)
	if mainAttack == true then
		if pn == tribe1 then
			if atkRoulette == 1 then tribe1Atk1 = amt
			elseif atkRoulette == 2 then tribe1Atk2 = amt end
		else
			if atkRoulette == 3 then tribe2Atk1 = amt
			elseif atkRoulette == 4 then tribe2Atk2 = amt end
		end
	else --mini attacks
		if pn == tribe1 then
			if atkRoulette == 5 then tribe1MiniAtk1 = amt
			elseif atkRoulette == 6 then tribe1MiniAtk2 = amt end
		else
			if atkRoulette == 7 then tribe2MiniAtk1 = amt
			elseif atkRoulette == 8 then tribe2MiniAtk2 = amt end
		end
	end
	--log_msg(pn,"amt: " .. amt .. "   tribe1MiniAtk1: " .. tribe1MiniAtk1 .. "   tribe2MiniAtk1: " .. tribe2MiniAtk1 .. "   roulette: " .. atkRoulette)
end

function SendMiniAttack(attacker)
	if (minutes() > 2) and (rnd() < 50+difficulty()*5 +gameStage*5) then
		WRITE_CP_ATTRIB(attacker, ATTR_DONT_GROUP_AT_DT, 1)
		WRITE_CP_ATTRIB(attacker, ATTR_GROUP_OPTION, 3)
		WRITE_CP_ATTRIB(attacker, ATTR_FIGHT_STOP_DISTANCE, 28 + G_RANDOM(16))
		WRITE_CP_ATTRIB(attacker, ATTR_BASE_UNDER_ATTACK_RETREAT, 0)
		WriteAiAttackers(attacker,0,math.random(30,40)+(difficulty()*5)+(gameStage*5),math.random(25,35)+(difficulty()*4)+(gameStage*4),math.random(0,20),0,0) --(pn,b,w,r,fw,spy,sh)
		local target = 0
		local numTroops = 0
		local mk1,mk2 = -1,-1
		if attacker == tribe1 then mk1 = math.random(91,93) else mk1 = math.random(94,96) end
		--check if enough pop and troops to attack
		local troopAmmount = (_gsi.Players[attacker].NumPeople-_gsi.Players[attacker].NumPeopleOfType[M_PERSON_BRAVE])
		if _gsi.Players[attacker].NumPeople > 16 and troopAmmount > 8 then
			numTroops = 2 + gameStage
		end
		--pick target
		if attacker == tribe1 then
			if rnd() < (35-(difficulty()*7)) and _gsi.Players[tribe2].NumPeople > 5 then target = tribe2 end
		else
			if rnd() < (35-(difficulty()*7)) and _gsi.Players[tribe1].NumPeople > 5 then target = tribe1 end
		end
		--LAUNCH MINI ATK
		if numTroops > 0 then
			if _gsi.Players[target].NumBuildings > 0 then
				if (NAV_CHECK(attacker,target,ATTACK_BUILDING,0,0) > 0) then
					ATTACK(attacker, target, numTroops, ATTACK_BUILDING, 0, 869+(difficulty()*10), 0, 0, 0, ATTACK_NORMAL, 0, mk1, mk2, -1)
					IncrementAtkVar(attacker,turn() + 1444 + G_RANDOM(1024) - (difficulty()*128) - (gameStage*64),false)
					TrainUnitsNow(attacker) --log_msg(attacker,"mini atk vs: " .. target .. "   bldg")
				elseif _gsi.Players[target].NumPeople > 0 then
					if (NAV_CHECK(attacker,target,ATTACK_PERSON,0,0) > 0) then
						ATTACK(attacker, target, numTroops, ATTACK_PERSON, 0, 869+(difficulty()*10), 0, 0, 0, ATTACK_NORMAL, 0, mk1, mk2, -1)
						IncrementAtkVar(attacker,turn() + 1444 + G_RANDOM(1024) - (difficulty()*128) - (gameStage*64),false)
						TrainUnitsNow(attacker) --log_msg(attacker,"mini atk vs: " .. target .. "   person")
					end
				else
					IncrementAtkVar(attacker,turn() + 256, false)
				end
			else
				if (NAV_CHECK(attacker,target,ATTACK_PERSON,0,0) > 0) then
					ATTACK(attacker, target, numTroops, ATTACK_PERSON, 0, 869+(difficulty()*10), 0, 0, 0, ATTACK_NORMAL, 0, mk1, mk2, -1)
					IncrementAtkVar(attacker,turn() + 1444 + G_RANDOM(1024) - (difficulty()*128) - (gameStage*64),false)
					TrainUnitsNow(attacker) --log_msg(attacker,"mini atk vs: " .. target .. "   person")
				else
					IncrementAtkVar(attacker,turn() + 256, false)
				end
			end
		else
			IncrementAtkVar(attacker,turn() + 256, false)
		end
	else
		IncrementAtkVar(attacker,turn()+256, false)
	end
end

function SendAttack(attacker)
	if (minutes() > 6-difficulty()) and (rnd() < 65+difficulty()*5 +gameStage*5) then
		WRITE_CP_ATTRIB(attacker, ATTR_FIGHT_STOP_DISTANCE, 28 + G_RANDOM(16))
		WriteAiAttackers(attacker,G_RANDOM(5),19+G_RANDOM(10)+(difficulty()*6)+(gameStage*4),13+G_RANDOM(5)+(difficulty()*6)+(gameStage*4),13+G_RANDOM(7)+(difficulty()*6)+(gameStage*4),0,100) --(pn,b,w,r,fw,spy,sh)
		local target = 0
		local numTroops = 0
		local boats = _gsi.Players[attacker].NumVehiclesOfType[M_VEHICLE_BOAT_1]
		local spell1,spell2,spell3 = 0,0,0
		local mk1,mk2 = -1,-1
		local stress = 0
		if attacker == tribe1 then mk1 = math.random(91,93) else mk1 = math.random(94,96) end
		--check if enough pop and troops to attack
		local troopAmmount = (_gsi.Players[attacker].NumPeople-_gsi.Players[attacker].NumPeopleOfType[M_PERSON_BRAVE])
		if _gsi.Players[attacker].NumPeople > 20 and troopAmmount > 10 then
			numTroops = 3 + (difficulty()) + gameStage if difficulty() >= 2 then numTroops = numTroops + math.floor(troopAmmount/7) end
		end
		--pick target
		if attacker == tribe1 then
			if rnd() < (45-(difficulty()*7)) and _gsi.Players[tribe2].NumPeople > 5 then target = tribe2 end
		else
			if rnd() < (45-(difficulty()*7)) and _gsi.Players[tribe1].NumPeople > 5 then target = tribe1 end
		end
		--is shaman going
		if getShaman(attacker) ~= nil and gameStage >= 1 and IS_SHAMAN_AVAILABLE_FOR_ATTACK(attacker) == 1 then
			WRITE_CP_ATTRIB(attacker, ATTR_AWAY_MEDICINE_MAN, 100);
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
					if attacker == tribe1 then
						mk2 = math.random(91,93)
					else
						mk2 = math.random(91,93)
					end
				end
			end
		else
			WRITE_CP_ATTRIB(attacker, ATTR_AWAY_MEDICINE_MAN, 0);
			mk2 = -1
		end
		--group options
		if difficulty() >= 2 then
			WRITE_CP_ATTRIB(attacker, ATTR_DONT_GROUP_AT_DT, 1);
			WRITE_CP_ATTRIB(attacker, ATTR_GROUP_OPTION, 2);
		else
			WRITE_CP_ATTRIB(attacker, ATTR_DONT_GROUP_AT_DT, 0);
			WRITE_CP_ATTRIB(attacker, ATTR_GROUP_OPTION, 0);
		end
		--retreat
		if difficulty() < 2 then
			WRITE_CP_ATTRIB(attacker, ATTR_BASE_UNDER_ATTACK_RETREAT, 1)
			WRITE_CP_ATTRIB(attacker, ATTR_RETREAT_VALUE, math.random(0,8))
		else
			WRITE_CP_ATTRIB(attacker, ATTR_BASE_UNDER_ATTACK_RETREAT, 0)
			WRITE_CP_ATTRIB(attacker, ATTR_RETREAT_VALUE, 0)
		end
		--give spell 1 2 AND 3
		if READ_CP_ATTRIB(attacker,ATTR_AWAY_MEDICINE_MAN) == 100 then
			if attacker == tribe1 then
				if spell1 == 0 then
					spell1 = tribe1AtkSpells[math.random(#tribe1AtkSpells)]
				end
				spell2 = tribe1AtkSpells[math.random(#tribe1AtkSpells)]
				spell3 = tribe1AtkSpells[math.random(#tribe1AtkSpells)]
			else
				if spell1 == 0 then
					spell1 = tribe2AtkSpells[math.random(#tribe2AtkSpells)]
				end
				spell2 = tribe2AtkSpells[math.random(#tribe2AtkSpells)]
				spell3 = tribe2AtkSpells[math.random(#tribe2AtkSpells)]
			end
		end
		--LAUNCH ATTACK
		
		--has enough troops
		if numTroops > 0 then
			--prioritize buildings
			if _gsi.Players[target].NumBuildings > 0 then
				--can target bldg by land
				if (NAV_CHECK(attacker,target,ATTACK_BUILDING,0,0) > 0) then
					ATTACK(attacker, target, numTroops, ATTACK_BUILDING, 0, 969+(difficulty()*10), spell1, spell2, spell3, ATTACK_NORMAL, 1, mk1, mk2, 0)
					IncrementAtkVar(attacker,turn() + 2555 + G_RANDOM(1333) - (difficulty()*300) - (gameStage*200),true) --log_msg(attacker,"mini atk vs: " .. target .. "   bldg")
				else
					--try atk bldg from water
					if boats > 0 then
						WRITE_CP_ATTRIB(attacker, ATTR_FIGHT_STOP_DISTANCE, 4)
						WRITE_CP_ATTRIB(attacker, ATTR_GROUP_OPTION, 0)
						ATTACK(attacker, target, numTroops, ATTACK_BUILDING, 0, 969+(difficulty()*10), spell1, spell2, spell3, ATTACK_BY_BOAT, 1, -1, -1, -1)
						IncrementAtkVar(attacker,turn() + 2555 + G_RANDOM(1333) - (difficulty()*300) - (gameStage*200),true) --log_msg(attacker,"mini atk vs: " .. target .. "   bldg boat")
					else
						--else attack units
						if _gsi.Players[target].NumPeople > 0 then
							if (NAV_CHECK(attacker,target,ATTACK_PERSON,0,0) > 0) then
								ATTACK(attacker, target, numTroops, ATTACK_PERSON, 0, 969+(difficulty()*10), spell1, spell2, spell3, ATTACK_NORMAL, 1, mk1, mk2, 0)
								IncrementAtkVar(attacker,turn() + 2555 + G_RANDOM(1333) - (difficulty()*300) - (gameStage*200),true) --log_msg(attacker,"mini atk vs: " .. target .. "   person")
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
						IncrementAtkVar(attacker,turn() + 2555 + G_RANDOM(1333) - (difficulty()*300) - (gameStage*200),true) --log_msg(attacker,"mini atk vs: " .. target .. "   person")
					else
						--try to atk units from water
						if boats > 0 then
							WRITE_CP_ATTRIB(attacker, ATTR_FIGHT_STOP_DISTANCE, 4)
							WRITE_CP_ATTRIB(attacker, ATTR_GROUP_OPTION, 0)
							ATTACK(attacker, target, numTroops, ATTACK_PERSON, 0, 969+(difficulty()*10), spell1, spell2, spell3, ATTACK_BY_BOAT, 1, -1, -1, -1)
							IncrementAtkVar(attacker,turn() + 2555 + G_RANDOM(1333) - (difficulty()*300) - (gameStage*200),true) --log_msg(attacker,"mini atk vs: " .. target .. "   person boat")
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
			else
				tribe2NavStress = tribe2NavStress + 1
			end
		else
			if attacker == tribe1 then
				tribe1NavStress = 0
			else
				tribe2NavStress = 0
			end
		end
		TrainUnitsNow(attacker)
	else
		IncrementAtkVar(attacker,turn()+500, true)
	end
	--log_msg(8,"" .. attacker .. "  " .. target .. "  " .. numTroops .. "  " .. variable .. "  " .. stress)
end


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

function OnTurn()
	if game_loaded then
		game_loaded = false
		--if turn() < 1230 then Engine:hidePanel() end
		Engine:postLoadItems();
		--reset texture
		if day == 1 then
			set_level_type(13)
		else
			set_level_type(14)
		end
		--kill honor loads --add check if save was before x time it works cuz flyby boring
		if (difficulty() == 3) and turn() > honorSaveTurnLimit and honorSaveTurnLimit ~= -1 then
			ProcessGlobalSpecialList(TRIBE_BLUE, PEOPLELIST, function(t)
				damage_person(t, 8, 20000, TRUE)
				return true
			end)
			TRIGGER_LEVEL_LOST() ; SET_NO_REINC(0)
			log_msg(8,"WARNING:  You have loaded the game while playing in \"honour\" mode.")
		end
		--reinc if load on cinema's end
		if turn() < 1184 and turn() > 1130 then
			START_REINC_NOW(0)
		end
	end
	--blue speech after getting each faction
	if everySeconds(4) then
		if talk1 == 1 then
			talk1 = 2
			if faction1 == 1 then
				Engine:addCommand_QueueMsg(dialog_msgs[9][1], dialog_msgs[9][2], 36, false, dialog_msgs[9][3], dialog_msgs[9][4], dialog_msgs[9][5], 12*3);
			else
				Engine:addCommand_QueueMsg(dialog_msgs[10][1], dialog_msgs[10][2], 36, false, dialog_msgs[10][3], dialog_msgs[10][4], dialog_msgs[10][5], 12*3);
			end
		elseif talk2 == 1 then
			talk2 = 2
			if faction2 == 1 then
				Engine:addCommand_QueueMsg(dialog_msgs[11][1], dialog_msgs[11][2], 36, false, dialog_msgs[11][3], dialog_msgs[11][4], dialog_msgs[11][5], 12*3);
			else
				Engine:addCommand_QueueMsg(dialog_msgs[12][1], dialog_msgs[12][2], 36, false, dialog_msgs[12][3], dialog_msgs[12][4], dialog_msgs[12][5], 12*3);
			end
		elseif talk3 == 1 then
			talk3 = 2
			if faction3 == 1 then
				Engine:addCommand_QueueMsg(dialog_msgs[13][1], dialog_msgs[13][2], 36, false, dialog_msgs[13][3], dialog_msgs[13][4], dialog_msgs[13][5], 12*3);
			else
				Engine:addCommand_QueueMsg(dialog_msgs[14][1], dialog_msgs[14][2], 36, false, dialog_msgs[14][3], dialog_msgs[14][4], dialog_msgs[14][5], 12*3);
			end
		end
	end
	if turn() == 0 then 
		computer_init_player(_gsi.Players[tribe2]) 
		SHAMAN_DEFEND(tribe2, 100, 154, TRUE) 
		SET_DRUM_TOWER_POS(tribe2, 100, 154) 
		for t,w in ipairs (AItribes) do
			for k,v in ipairs(botSpells) do
				set_player_can_cast(v, w)
			end
			for k,v in ipairs(botBldgs) do
				set_player_can_build(v, w)
			end
		end
		for i = 1,7 do
			if (i == tribe1) or (i == tribe2) then
				for u,v in ipairs(botSpells) do
					PThing.SpellSet(i, v, TRUE, FALSE)
				end

				for y,v in ipairs(botBldgs) do
					PThing.BldgSet(i, v, TRUE)
				end
				--ATTRIBUTES

				--base
				WRITE_CP_ATTRIB(i, ATTR_EXPANSION, 12)
				WRITE_CP_ATTRIB(i, ATTR_HOUSE_PERCENTAGE, 80+G_RANDOM(30))
				WRITE_CP_ATTRIB(i, ATTR_MAX_BUILDINGS_ON_GO, 3+G_RANDOM(1))
				STATE_SET(i, TRUE, CP_AT_TYPE_BRING_NEW_PEOPLE_BACK)
				STATE_SET(i, TRUE, CP_AT_TYPE_HOUSE_A_PERSON)
				STATE_SET(i, TRUE, CP_AT_TYPE_FETCH_LOST_PEOPLE)
				STATE_SET(i, TRUE, CP_AT_TYPE_MED_MAN_GET_WILD_PEEPS)
				--train
				STATE_SET(i, TRUE, CP_AT_TYPE_TRAIN_PEOPLE)
				WRITE_CP_ATTRIB(i, ATTR_MAX_TRAIN_AT_ONCE, 4)
				--buildings
				STATE_SET(i, TRUE, CP_AT_TYPE_CONSTRUCT_BUILDING)
				STATE_SET(i, TRUE, CP_AT_TYPE_FETCH_WOOD)
				WRITE_CP_ATTRIB(i, ATTR_RANDOM_BUILD_SIDE, 1)
				WRITE_CP_ATTRIB(i, ATTR_PREF_WARRIOR_TRAINS, 1)
				WRITE_CP_ATTRIB(i, ATTR_PREF_SUPER_WARRIOR_TRAINS, 0)
				WRITE_CP_ATTRIB(i, ATTR_PREF_RELIGIOUS_TRAINS, 0)
				WRITE_CP_ATTRIB(i, ATTR_PREF_SPY_TRAINS, 0)
				--train
				WriteAiTrainTroops(i,6,4,8,0) --(pn,w,r,fw,spy)
				--vehicles
				STATE_SET(i, TRUE, CP_AT_TYPE_BUILD_VEHICLE)
				STATE_SET(i, TRUE, CP_AT_TYPE_FETCH_FAR_VEHICLE)
				WRITE_CP_ATTRIB(i, ATTR_PREF_BOAT_HUTS, 1)
				WRITE_CP_ATTRIB(i, ATTR_PREF_BOAT_DRIVERS, 2+difficulty())
				WRITE_CP_ATTRIB(i, ATTR_PEOPLE_PER_BOAT, 2+difficulty())
				--[[WRITE_CP_ATTRIB(i, ATTR_PREF_BALLOON_HUTS, 0)
				WRITE_CP_ATTRIB(i, ATTR_PREF_BALLOON_DRIVERS, 0)
				WRITE_CP_ATTRIB(i, ATTR_PEOPLE_PER_BALLOON, 0)]]
				--attack
				SET_ATTACK_VARIABLE(i,0)
				STATE_SET(i, TRUE, CP_AT_TYPE_AUTO_ATTACK)
				WRITE_CP_ATTRIB(i, ATTR_ATTACK_PERCENTAGE, 100)
				WRITE_CP_ATTRIB(i, ATTR_MAX_ATTACKS, 999)
				WRITE_CP_ATTRIB(i, ATTR_BASE_UNDER_ATTACK_RETREAT, 0)
				WRITE_CP_ATTRIB(i, ATTR_RETREAT_VALUE, 4)
				WRITE_CP_ATTRIB(i, ATTR_FIGHT_STOP_DISTANCE, 32)
				WRITE_CP_ATTRIB(i, ATTR_GROUP_OPTION, 0)
			--[[0 - Stop at waypoint (if exists) and before attack
				1 - Stop before attack only
				2 - Stop at waypoint (if exists) only
				3 - Don't stop anywhere]]
				WriteAiAttackers(i,0,70,40,40,0,100) --(pn,b,w,r,fw,spy,sh)
				--defense
				WRITE_CP_ATTRIB(i, ATTR_DEFENSE_RAD_INCR, 4)
				WRITE_CP_ATTRIB(i, ATTR_MAX_DEFENSIVE_ACTIONS, 3)
				WRITE_CP_ATTRIB(i, ATTR_USE_PREACHER_FOR_DEFENCE, 1)
				STATE_SET(i, TRUE, CP_AT_TYPE_POPULATE_DRUM_TOWER)
				STATE_SET(i, TRUE, CP_AT_TYPE_BUILD_OUTER_DEFENCES)
				STATE_SET(i, TRUE, CP_AT_TYPE_DEFEND)
				STATE_SET(i, TRUE, CP_AT_TYPE_DEFEND_BASE)
				STATE_SET(i, TRUE, CP_AT_TYPE_PREACH)
				STATE_SET(i, TRUE, CP_AT_TYPE_SUPER_DEFEND)
				--spies
				WRITE_CP_ATTRIB(i, ATTR_SPY_DISCOVER_CHANCE, 8) -- (% chance of a spy being uncovered when spotted in cps base)
				WRITE_CP_ATTRIB(i, ATTR_ENEMY_SPY_MAX_STAND, 128) --(number of game turns computer player will ignore a spy stood in their base doing nothing)
				WRITE_CP_ATTRIB(i, ATTR_SPY_CHECK_FREQUENCY, 128) --(0 - 128), 0 means AI wont redisguise spies
				WRITE_CP_ATTRIB(i, ATTR_MAX_SPY_ATTACKS, 256)	
				STATE_SET(i, FALSE, CP_AT_TYPE_SABOTAGE)
				--spells
				SET_BUCKET_USAGE(i, TRUE)
				SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_BLAST, 8)
				SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_CONVERT_WILD, 8)
				SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_GHOST_ARMY, 12)
				SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_INSECT_PLAGUE, 16)
				SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_LAND_BRIDGE, 32)
				SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_LIGHTNING_BOLT, 40)
				SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_INVISIBILITY, 28)
				SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_HYPNOTISM, 50)
				SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_WHIRLWIND, 80)
				SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_SWAMP, 100)
				SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_EARTHQUAKE, 175)
				SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_EROSION, 200)
				SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_FLATTEN, 125)
				SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_FIRESTORM, 275)
				SET_BUCKET_COUNT_FOR_SPELL(i, M_SPELL_SHIELD, 28)
				--defence spells
				SET_DEFENCE_RADIUS(i, 7)
				SET_SPELL_ENTRY(i, 0, M_SPELL_INSECT_PLAGUE, 25000, 64, 3, 0)
				SET_SPELL_ENTRY(i, 1, M_SPELL_LIGHTNING_BOLT, 40000, 64, 2, 0)
				SET_SPELL_ENTRY(i, 2, M_SPELL_INSECT_PLAGUE, 25000, 64, 3, 1)
				SET_SPELL_ENTRY(i, 3, M_SPELL_LIGHTNING_BOLT, 40000, 64, 2, 1)
			end
		end
		--shaman stuff
		WRITE_CP_ATTRIB(tribe1, ATTR_SHAMEN_BLAST, 8)
		WRITE_CP_ATTRIB(tribe2, ATTR_SHAMEN_BLAST, 16)
		SHAMAN_DEFEND(tribe1, 102, 250, TRUE)
		SET_DRUM_TOWER_POS(tribe1, 102, 250)
	end	
	if turn() == 1200 then
		--add wilds near CoR depending on diff
		local wildTbl = {19,20,21,22,23}
		local enemyWildTbl = {28,29,30,31,32, 33,34,35,36,37}
		for i = 1,4-difficulty() do
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
		--add some pop and fog reveals if lower diffs
		local d = difficulty()
		if d == 0 then
			for i = 97,125 do
				createThing(T_EFFECT,M_EFFECT_REVEAL_FOG_AREA,8,marker_to_coord3d(i),false,false)
			end
			for i = 126,128 do
				createThing(T_PERSON,M_PERSON_BRAVE,0,marker_to_coord3d(i),false,false)
				createThing(T_PERSON,M_PERSON_BRAVE,0,marker_to_coord3d(i),false,false)
			end
		elseif d == 1 then
			for i = 97,112 do
				createThing(T_EFFECT,M_EFFECT_REVEAL_FOG_AREA,8,marker_to_coord3d(i),false,false)
			end
			for i = 126,128 do
				createThing(T_PERSON,M_PERSON_BRAVE,0,marker_to_coord3d(i),false,false)
			end
		end
	elseif turn() == 1400 then
		Engine:addCommand_QueueMsg(dialog_msgs[7][1], dialog_msgs[7][2], 36, false, dialog_msgs[7][3], dialog_msgs[7][4], dialog_msgs[7][5], 12*4);
	elseif turn() == levelUpTurn and levelUpTurn ~= -1 then
		Engine:addCommand_QueueMsg(dialog_msgs[8][1], dialog_msgs[8][2], 36, false, dialog_msgs[8][3], dialog_msgs[8][4], dialog_msgs[8][5], 12*3);
	end
	if turn() == 12 then
		FLYBY_CREATE_NEW()
		FLYBY_ALLOW_INTERRUPT(FALSE)

		--start
		FLYBY_SET_EVENT_POS(8, 8, 1, 12*4)
		FLYBY_SET_EVENT_ANGLE(200, 1, 12*2)
		FLYBY_SET_EVENT_ANGLE(0, 1+12*2, 12*4)
		FLYBY_SET_EVENT_ZOOM (60,48,60)
		--look at orb
		FLYBY_SET_EVENT_POS(6, 228, 108, 12*6)
		FLYBY_SET_EVENT_ANGLE(1000, 108, 12*4)
		FLYBY_SET_EVENT_ZOOM (30,108,32)
		--near orb facing shamans
		FLYBY_SET_EVENT_POS(6, 242, 180, 12*4)
		FLYBY_SET_EVENT_ANGLE(0, 180, 12*4)
		FLYBY_SET_EVENT_ZOOM (10,180,24)
		FLYBY_SET_EVENT_POS(6, 246, 228, 12*10)
		--they moving to near the orb
		FLYBY_SET_EVENT_POS(8, 230, 348, 12*14)
		FLYBY_SET_EVENT_ANGLE(1750, 348, 12*14)
		FLYBY_SET_EVENT_ZOOM (-40,348,12*10)
		--focus on preacher near end
		FLYBY_SET_EVENT_POS(22, 232, 542, 12*38)
		FLYBY_SET_EVENT_ANGLE(1300, 542, 12*38)
		--go to CoR
		FLYBY_SET_EVENT_POS(0, 0, 1000, 12*5)
		FLYBY_SET_EVENT_ANGLE(0, 1000, 12*3)

		FLYBY_START()
	end
	if turn() == 1 then
		--command system stuff
		Engine:hidePanel()
		Engine:addCommand_CinemaRaise(0);
		--move to first stop and stare at orb
		Engine:addCommand_MoveThing(Ypreacher.ThingNum, marker_to_coord2d_centre(2), 1);
		Engine:addCommand_MoveThing(getShaman(0).ThingNum, marker_to_coord2d_centre(3), 44);
		Engine:addCommand_MoveThing(Bwar1.ThingNum, marker_to_coord2d_centre(11), 1);
		Engine:addCommand_MoveThing(Bwar2.ThingNum, marker_to_coord2d_centre(11), 1);
		Engine:addCommand_AngleThing(Ypreacher.ThingNum, 500, 12);
		Engine:addCommand_AngleThing(getShaman(0).ThingNum, 1500, 8);
		Engine:addCommand_AngleThing(Ypreacher.ThingNum, 1000, 12);
		Engine:addCommand_AngleThing(Ypreacher.ThingNum, 500, 4);
		Engine:addCommand_QueueMsg(dialog_msgs[0][1], dialog_msgs[0][2], 36, false, dialog_msgs[0][3], dialog_msgs[0][4], dialog_msgs[0][5], 12*17);
		--preacher movesa bit further and tells her to follow him
		Engine:addCommand_MoveThing(Ypreacher.ThingNum, marker_to_coord2d_centre(4), 36);
		Engine:addCommand_AngleThing(Ypreacher.ThingNum, 256, 6);
		Engine:addCommand_QueueMsg(dialog_msgs[1][1], dialog_msgs[1][2], 36, false, dialog_msgs[1][3], dialog_msgs[1][4], dialog_msgs[1][5], 16);
		--they continue walking to near the orb
		Engine:addCommand_MoveThing(getShaman(0).ThingNum, marker_to_coord2d_centre(6), 2);
		Engine:addCommand_MoveThing(Ypreacher.ThingNum, marker_to_coord2d_centre(5), 1);
		Engine:addCommand_MoveThing(Bwar1.ThingNum, marker_to_coord2d_centre(12), 1);
		Engine:addCommand_MoveThing(Bwar2.ThingNum, marker_to_coord2d_centre(12), 1);
		Engine:addCommand_QueueMsg(dialog_msgs[2][1], dialog_msgs[2][2], 36, false, dialog_msgs[2][3], dialog_msgs[2][4], dialog_msgs[2][5], 12*10);
		Engine:addCommand_AngleThing(getShaman(0).ThingNum, 400, 3);
		Engine:addCommand_AngleThing(Ypreacher.ThingNum, 1400, 4);
		Engine:addCommand_AngleThing(getShaman(0).ThingNum, 850, 2);
		Engine:addCommand_QueueMsg(dialog_msgs[3][1], dialog_msgs[3][2], 36, false, dialog_msgs[3][3], dialog_msgs[3][4], dialog_msgs[3][5], 12*10);
		--talking near the orb
		Engine:addCommand_QueueMsg(dialog_msgs[4][1], dialog_msgs[4][2], 36, false, dialog_msgs[4][3], dialog_msgs[4][4], dialog_msgs[4][5], 12*10);
		--last dialog
		Engine:addCommand_MoveThing(Ypreacher.ThingNum, marker_to_coord2d_centre(7), 36+48);
		Engine:addCommand_AngleThing(Ypreacher.ThingNum, 1500, 2);
		Engine:addCommand_MoveThing(getShaman(0).ThingNum, marker_to_coord2d_centre(8), 2);
		Engine:addCommand_QueueMsg(dialog_msgs[5][1], dialog_msgs[5][2], 36, false, dialog_msgs[5][3], dialog_msgs[5][4], dialog_msgs[5][5], 12*17);
		Engine:addCommand_MoveThing(Bwar1.ThingNum, marker_to_coord2d_centre(6), 1);
		Engine:addCommand_MoveThing(Bwar2.ThingNum, marker_to_coord2d_centre(6), 1);
		Engine:addCommand_AngleThing(getShaman(0).ThingNum, 1700, 36);
		Engine:addCommand_AngleThing(getShaman(0).ThingNum, 900, 12);
		Engine:addCommand_MoveThing(getShaman(0).ThingNum, marker_to_coord2d_centre(255), 2);
		Engine:addCommand_MoveThing(Bwar1.ThingNum, marker_to_coord2d_centre(7), 1);
		Engine:addCommand_MoveThing(Bwar2.ThingNum, marker_to_coord2d_centre(7), 1);
		Engine:addCommand_QueueMsg(dialog_msgs[6][1], dialog_msgs[6][2], 36, false, dialog_msgs[6][3], dialog_msgs[6][4], dialog_msgs[6][5], 12*8);
	else
		Engine.DialogObj:processQueue();
		Engine:processCmd();
		--day night cycle
		if turn() == turnDayChanges then
			if day == 0 then 
				day = 1
				turnDayChanges = turn() + (720*2) --; if faction2 == 2 then turnDayChanges = turnDayChanges + math.ceil((720*2)/2) end --only nights can last longer
				set_level_type(13)
			else 
				day = 0 
				turnDayChanges = turn() + (720*2) ; if faction2 == 2 then turnDayChanges = turnDayChanges + 720 end
				set_level_type(14)
			end
		end
		if turn() == 1080 then
			set_players_enemies(0,3)
		elseif turn() == 1130 then
			START_REINC_NOW(0)
			Engine:addCommand_CinemaHide(16);
			Engine:addCommand_ShowPanel(12*2);
		elseif turn() == 1200 then
			honorSaveTurnLimit = turn()+12*20
			--add wilds near CoR depending on diff
			local wildTbl = {19,20,21,22,23}
			local enemyWildTbl = {28,29,30,31,32, 33,34,35,36,37}
			for i = 1,4-difficulty() do
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
	end
	
	
	if everySeconds(42-(difficulty()*2)) then
		--go expand wish shaman (lb)
		if rnd() > 55 then
			local tribe2LB = AItribes[math.random(#AItribes)]
			if getShaman(tribe2LB) ~= nil and gameStage >= 2 and IS_SHAMAN_AVAILABLE_FOR_ATTACK(tribe2LB) == 1 then
				local lbs = GET_SPELLS_CAST(tribe2LB,M_SPELL_LAND_BRIDGE)
				local mk1 = -1 local mk2 = -1
				if tribe2LB == tribe1 then
					if lbs == 0 then
						mk1 = 77 mk2 = 78
					elseif lbs == 1 then
						mk1 = 79 mk2 = 80
					elseif lbs == 2 then
						mk1 = 81 mk2 = 82
					end
				else
					if lbs == 0 then
						mk1 = 71 mk2 = 72
					elseif lbs == 1 then
						mk1 = 73 mk2 = 74
					elseif lbs == 2 then
						mk1 = 75 mk2 = 76
					end
				end
				if lbs < 3 then GIVE_ONE_SHOT(M_SPELL_LAND_BRIDGE,tribe2LB) end
				if (NAV_CHECK(tribe2LB,0,ATTACK_MARKER,mk1,0) > 0) then
					WRITE_CP_ATTRIB(tribe2LB, ATTR_GROUP_OPTION, 2);
					WriteAiAttackers(tribe2LB,0,0,0,0,0,100) --(pn,b,w,r,fw,spy,sh)
					ATTACK(tribe2LB, TRIBE_BLUE, 1, ATTACK_PERSON, mk2, 1, M_SPELL_LAND_BRIDGE, 0, 0, ATTACK_NORMAL, 0, mk1, mk2, 0);
				end
			end
		end
	end
	
	--build towers
	if turn() == 9000-(difficulty()*1300) then
		BUILD_DRUM_TOWER(tribe1,84, 248)
		BUILD_DRUM_TOWER(tribe2,70, 134)
	end
	if turn() == 8000-(difficulty()*1500) then
		BUILD_DRUM_TOWER(tribe1,88, 254)
		BUILD_DRUM_TOWER(tribe2,70, 114)
	end
	if turn() == 11000-(difficulty()*400) then
		BUILD_DRUM_TOWER(tribe1,88, 12)
		BUILD_DRUM_TOWER(tribe2,86, 136)
	end
	if turn() == 13500-(difficulty()*2000) then
		BUILD_DRUM_TOWER(tribe1,100, 36)
		BUILD_DRUM_TOWER(tribe2,86, 186)
	end
	if turn() == 14000-(difficulty()*600) then
		BUILD_DRUM_TOWER(tribe1,158, 4)
	end
	if turn() == 7000-(difficulty()*1400) and difficulty() >= 2 then
		BUILD_DRUM_TOWER(tribe1,158, 8)
		BUILD_DRUM_TOWER(tribe2,96, 188)
	end
	if turn() == 8000-(difficulty()*2000) and difficulty() == 3 then
		BUILD_DRUM_TOWER(tribe1,106, 234)
	end
	-- new towers every x mins
	if everySeconds(240-(difficulty()*30)) and gameStage >= 3 then
		if AI.ai1.towers < 4+difficulty() then
			local rndTowMk = math.random(50,56)
			local coord = MapPosXZ.new() ; coord.Pos = world_coord3d_to_map_idx(marker_to_coord3d(rndTowMk))
			BUILD_DRUM_TOWER(tribe1,coord.XZ.X, coord.XZ.Z)
		end
		if AI.ai2.towers < 4+difficulty() then
			local rndTowMk = math.random(66,70)
			local coord = MapPosXZ.new() ; coord.Pos = world_coord3d_to_map_idx(marker_to_coord3d(rndTowMk))
			BUILD_DRUM_TOWER(tribe2,coord.XZ.X, coord.XZ.Z)
		end
	end
	
	--give AI spell shots occasionally
	if everySeconds(10-difficulty()) then
		for k,v in ipairs(AItribes) do
			if gameStage == 0 then
				GIVE_ONE_SHOT(M_SPELL_BLAST,v)
			elseif gameStage == 1 then
				GIVE_ONE_SHOT(M_SPELL_BLAST,v) GIVE_ONE_SHOT(M_SPELL_LIGHTNING_BOLT,v)
			elseif gameStage == 2 then
				GIVE_ONE_SHOT(M_SPELL_BLAST,v) GIVE_ONE_SHOT(M_SPELL_LIGHTNING_BOLT,v) GIVE_ONE_SHOT(M_SPELL_INSECT_PLAGUE,v)
			else
				GIVE_ONE_SHOT(M_SPELL_BLAST,v) GIVE_ONE_SHOT(M_SPELL_LIGHTNING_BOLT,v) GIVE_ONE_SHOT(M_SPELL_INSECT_PLAGUE,v) GIVE_ONE_SHOT(M_SPELL_HYPNOTISM,v)
			end
		end
	end
	--give AI spell shots rarely
	if everySeconds(48-(difficulty()*3)) then
		for k,v in ipairs(AItribes) do
			if gameStage == 0 then
				GIVE_ONE_SHOT(M_SPELL_WHIRLWIND,v)
			elseif gameStage == 1 then
				GIVE_ONE_SHOT(M_SPELL_EROSION,v)
			elseif gameStage == 2 then
				GIVE_ONE_SHOT(M_SPELL_EARTHQUAKE,v)
			else
				GIVE_ONE_SHOT(M_SPELL_FIRESTORM,v)
			end
		end
	end
	
	if everySeconds(60-(difficulty()*4)) then
		--defend stone head if enough troops
		local inStone = count_people_of_type_in_area(46,190,-1,TRIBE_BLUE,2)
		if rnd() > 50 then
			if inStone >= 1 and (NAV_CHECK(tribe1,0,ATTACK_MARKER,83,0) > 0) and AI.ai1.troops > (2+(inStone*2)) then
				WRITE_CP_ATTRIB(tribe1, ATTR_DONT_GROUP_AT_DT, 1);
				WRITE_CP_ATTRIB(tribe1, ATTR_GROUP_OPTION, 3);
				WriteAiAttackers(tribe1,0,50,50,0,0,0) --(pn,b,w,r,fw,spy,sh)
				ATTACK(tribe1, TRIBE_BLUE, 2+inStone, ATTACK_MARKER, 83, 500+difficulty()*100, 0, 0, 0, ATTACK_NORMAL, 1, -1, -1, 0);
			end
		else
			if inStone >= 1 and (NAV_CHECK(tribe2,0,ATTACK_MARKER,83,0) > 0) and AI.ai2.troops > (2+(inStone*2)) then
				WRITE_CP_ATTRIB(tribe2, ATTR_DONT_GROUP_AT_DT, 1);
				WRITE_CP_ATTRIB(tribe2, ATTR_GROUP_OPTION, 3);
				WriteAiAttackers(tribe2,0,50,50,0,0,0) --(pn,b,w,r,fw,spy,sh)
				ATTACK(tribe2, TRIBE_BLUE, 2+inStone, ATTACK_MARKER, 83, 500+difficulty()*100, 0, 0, 0, ATTACK_NORMAL, 1, -1, -1, 0);
			end
		end
	end
	
	if everySeconds(32-(difficulty()*3)) then
		--patrolling marker entries and preach at marker
		MARKER_ENTRIES(tribe1,math.random(0,1),math.random(2,3),-1,-1)--wars
		MARKER_ENTRIES(tribe1,math.random(4,5),math.random(6,7),math.random(8,9),-1)--fws
		if AI.ai1.preachers > 4 then
			if rnd() > 30 then
				PREACH_AT_MARKER(tribe1,84) PREACH_AT_MARKER(tribe1,85) PREACH_AT_MARKER(tribe1,86)
				if difficulty() > 0 then PREACH_AT_MARKER(tribe1,87) PREACH_AT_MARKER(tribe1,88) end
				if difficulty() >= 2 and rnd() > 50 then
					PREACH_AT_MARKER(tribe1,89)
					if rnd() > 50 then
						PREACH_AT_MARKER(tribe1,90)
					end
				end
			end
		end
		--
		MARKER_ENTRIES(tribe2,math.random(0,1),2,3,-1)--wars,3 is fw
		MARKER_ENTRIES(tribe2,math.random(4,5),math.random(6,7),-1,-1)--fws
		if AI.ai2.preachers > 4 then
			if rnd() > 30 then
				PREACH_AT_MARKER(tribe2,84) PREACH_AT_MARKER(tribe2,85) PREACH_AT_MARKER(tribe2,86)
				if difficulty() > 0 then PREACH_AT_MARKER(tribe2,87) PREACH_AT_MARKER(tribe2,88) end
				if difficulty() >= 2 and rnd() > 50 then
					PREACH_AT_MARKER(tribe2,89)
					if rnd() > 50 then
						PREACH_AT_MARKER(tribe2,90)
					end
				end
			end
		end
	end
	
	if everySeconds(10) then
		--send main attacks
		if tribe1Atk1 < turn() then  atkRoulette = 1 ; SendAttack(tribe1) end
		if tribe2Atk1 < turn() then atkRoulette = 3 ; SendAttack(tribe2) end
		--send mini attacks
		if tribe1MiniAtk1 < turn() then atkRoulette = 5 ; SendMiniAttack(tribe1) end
		if tribe2MiniAtk1 < turn() then atkRoulette = 7 ; SendMiniAttack(tribe2) end	
	end
	
	if every2Pow(3) then
		--faction benefits/curses
		if faction1 == 2 then
			ProcessGlobalSpecialList(TRIBE_BLUE, PEOPLELIST, function(t)
				if t.Type == T_PERSON and t.Model ~= M_PERSON_MEDICINE_MAN and t.Model ~= M_PERSON_ANGEL then
					local value = 3 --local br,wa,pr,fw,sp = 4,6,4,6,4 regen per 4 turns
					if t.Model == M_PERSON_WARRIOR or t.Model == M_PERSON_SUPER_WARRIOR then value = 5 end
					if t.u.Pers.Life < t.u.Pers.MaxLife-(value*2) then
						if day == 1 then
							t.u.Pers.Life = t.u.Pers.Life + value
						else
							t.u.Pers.Life = t.u.Pers.Life + (value*2)
						end
					end
				end
				return true
			end)
		end
		if faction2 == 1 then
			if GET_NUM_ONE_OFF_SPELLS(0,M_SPELL_BLAST) == 4 then
				_gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_BLAST] = _gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_BLAST] & 240
				_gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_BLAST] = _gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_BLAST] | 3
			end
			if day == 0 then
				GIVE_MANA_TO_PLAYER(0,math.floor(getPlayer(0).LastManaIncr/2))
			end
		elseif faction2 == 2 then
			HealingPreachers()
		end
	end
	
	if faction2 == 1 then
		if thunderGet > 0 then
			thunderGet = thunderGet - 1
		else
			local li = GET_NUM_ONE_OFF_SPELLS(0,M_SPELL_LIGHTNING_BOLT)
			local to = GET_NUM_ONE_OFF_SPELLS(0,M_SPELL_WHIRLWIND)
			if li < 4 then
				_gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_LIGHTNING_BOLT] = _gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_LIGHTNING_BOLT] & 240
				_gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_LIGHTNING_BOLT] = _gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_LIGHTNING_BOLT] | li+1
			end
			if to < 3 then
				_gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_WHIRLWIND] = _gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_WHIRLWIND] & 240
				_gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_WHIRLWIND] = _gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_WHIRLWIND] | to+1
			end
			thunderGet = 720
		end
	end
	if faction3 == 1 then
		if pestilence1Get > 0 then
			pestilence1Get = pestilence1Get - 1
		else
			local swa = GET_NUM_ONE_OFF_SPELLS(0,M_SPELL_INSECT_PLAGUE)
			if swa < 4 then
				_gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_INSECT_PLAGUE] = _gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_INSECT_PLAGUE] & 240
				_gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_INSECT_PLAGUE] = _gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_INSECT_PLAGUE] | swa+1
			end
			local swa = GET_NUM_ONE_OFF_SPELLS(0,M_SPELL_INSECT_PLAGUE)
			if swa < 4 then
				_gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_INSECT_PLAGUE] = _gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_INSECT_PLAGUE] & 240
				_gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_INSECT_PLAGUE] = _gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_INSECT_PLAGUE] | swa+1
			end
			pestilence1Get = 720
		end
		if pestilence2Get > 0 then
			pestilence2Get = pestilence2Get - 1
		else
			local aod = GET_NUM_ONE_OFF_SPELLS(0,M_SPELL_ANGEL_OF_DEATH)
			if aod < 4 then
				_gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_ANGEL_OF_DEATH] = _gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_ANGEL_OF_DEATH] & 240
				_gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_ANGEL_OF_DEATH] = _gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_ANGEL_OF_DEATH] | aod+1
			end
			pestilence2Get = 720*10
		end
	elseif faction3 == 2 then
		if eagleGet > 0 then
			eagleGet = eagleGet - 1
		else
			local inv = GET_NUM_ONE_OFF_SPELLS(0,M_SPELL_INVISIBILITY)
			local shi = GET_NUM_ONE_OFF_SPELLS(0,M_SPELL_SHIELD)
			if inv < 4 then
				_gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_INVISIBILITY] = _gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_INVISIBILITY] & 240
				_gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_INVISIBILITY] = _gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_INVISIBILITY] | inv+1
			end
			if shi < 4 then
				_gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_SHIELD] = _gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_SHIELD] & 240
				_gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_SHIELD] = _gsi.ThisLevelInfo.PlayerThings[0].SpellsAvailableOnce[M_SPELL_SHIELD] | shi+1
			end
			eagleGet = 720
		end
	end
	
	if every2Pow(4) then
		--faction benefits/curses
		if faction1 == 1 then
			set_player_can_build(M_BUILDING_SUPER_TRAIN, 0)
			set_player_can_cast(M_SPELL_FIRESTORM, 0)
		elseif faction1 == 2 then
			set_player_can_build(M_BUILDING_BOAT_HUT_1, 0)
			set_player_can_cast(M_SPELL_EROSION, 0)
			if day == 1 then
				ProcessGlobalSpecialList(TRIBE_BLUE, BUILDINGLIST, function(b)
					if (b.Model <= 3) then
						if (b.u.Bldg.UpgradeCount < 1850) then
							b.u.Bldg.UpgradeCount = b.u.Bldg.UpgradeCount - (b.u.Bldg.NumDwellers*8)
						end
						if (b.u.Bldg.SproggingCount < 1000) then
							b.u.Bldg.SproggingCount = b.u.Bldg.SproggingCount - (b.u.Bldg.NumDwellers*8) - 8
						end
					end
				return true end)
			end
		end
		if faction2 == 1 then
			set_player_can_build(M_BUILDING_AIRSHIP_HUT_1, 0)
		elseif faction2 == 2 then
			set_player_can_cast(M_SPELL_LAND_BRIDGE, 0)
			set_player_cannot_cast(M_SPELL_LIGHTNING_BOLT, 0)
			set_player_cannot_build(M_BUILDING_SPY_TRAIN, 0)
		end
		if faction3 == 1 then
			set_player_can_cast(M_SPELL_SWAMP, 0)
			set_player_cannot_cast(M_SPELL_EARTHQUAKE, 0)
			DiseaseBraves()
		elseif faction3 == 2 then
			set_player_can_cast(M_SPELL_HYPNOTISM, 0)
			set_player_cannot_cast(M_SPELL_INSECT_PLAGUE, 0)
			ProcessGlobalSpecialList(0,PEOPLELIST, function(t)
				if t.Type == T_PERSON and t.Owner == 0 and t.Model == M_PERSON_RELIGIOUS then
					t.u.Pers.Life = t.u.Pers.Life - 300
				end
			return true end)
		end
		--remove tower plan from orb location
		ProcessGlobalTypeList(T_SHAPE ,function(t)
			if t.Owner == 0 then
				if (t.Pos.D3.Xpos == 1792 and t.Pos.D3.Ypos == 448) or (t.Pos.D3.Xpos == 2304 and t.Pos.D3.Ypos == 448) then
					delete_thing_type(t)
				end
			end
		return true end)
		--stress from nav check, cast AoD
		if gameStage >= 2 then
			if tribe1NavStress > (7-difficulty()) then
				if getShaman(tribe1) ~= nil and IS_SHAMAN_AVAILABLE_FOR_ATTACK(tribe1) > 0 then
					--log_msg(8,"go cast AoD stress")
					GIVE_ONE_SHOT(M_SPELL_ANGEL_OF_DEATH,tribe1)
					SPELL_ATTACK(tribe1,M_SPELL_ANGEL_OF_DEATH,24,0)
					tribe1NavStress = 0
				end
			end
			if tribe2NavStress > (7-difficulty()) then
				if getShaman(tribe2) ~= nil and IS_SHAMAN_AVAILABLE_FOR_ATTACK(tribe2) > 0 then
					GIVE_ONE_SHOT(M_SPELL_ANGEL_OF_DEATH,tribe2)
					SPELL_ATTACK(tribe2,M_SPELL_ANGEL_OF_DEATH,25,0)
					tribe2NavStress = 0
				end
			end
		end
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
			if (b.Model <= 3) and b.Owner ~= 0 then
				if (b.u.Bldg.UpgradeCount < 1850) then
					b.u.Bldg.UpgradeCount = b.u.Bldg.UpgradeCount + (difficulty()*6)
				end
				if (b.u.Bldg.SproggingCount < 1000) then
					b.u.Bldg.SproggingCount = b.u.Bldg.SproggingCount + (difficulty()*6)
				end
			end
		return true end)
	end

	if every2Pow(6) then
		--update game stage (early,mid,late,very late)
		if minutes() < 6 then
			gameStage = 0
		elseif minutes() < 12 then
			gameStage = 1
		elseif minutes() < 18 then
			gameStage = 2
		elseif minutes() < 24 then
			gameStage = 3
		else
			gameStage = 4
		end
		--update AI ATTRS
		SET_MARKER_ENTRY(tribe1,0,38,39,0,2+gameStage,0,0) --war,fw,pre
		SET_MARKER_ENTRY(tribe1,1,40,-1,0,2+gameStage,1,0)
		SET_MARKER_ENTRY(tribe1,2,41,-1,0,2+gameStage,0,0)
		SET_MARKER_ENTRY(tribe1,3,42,43,0,2+gameStage,0,1)
		SET_MARKER_ENTRY(tribe2,0,57,-1,0,2+gameStage,0,0)
		SET_MARKER_ENTRY(tribe2,1,58,59,0,2+gameStage,1,0)
		SET_MARKER_ENTRY(tribe2,2,60,-1,0,2+gameStage,0,1)
		for i,v in ipairs(AItribes) do
			if turn() > 1300 then WRITE_CP_ATTRIB(v, ATTR_EXPANSION, math.random(16,24)) end
			WRITE_CP_ATTRIB(v, ATTR_HOUSE_PERCENTAGE, 60+G_RANDOM(1+5*difficulty())+(difficulty()*10)+(gameStage*(10+difficulty()))) --base size
			WriteAiTrainTroops(v,9+G_RANDOM(5)+(difficulty()*3)+(gameStage*3),5+G_RANDOM(4)+(difficulty()*3)+(gameStage*2),6+G_RANDOM(5)+(difficulty()*3)+(gameStage*3),0) --(pn,w,r,fw,spy)
			WRITE_CP_ATTRIB(v, ATTR_ATTACK_PERCENTAGE, 100+(minutes()*2)) --attack stuff
			if READ_CP_ATTRIB(v,ATTR_ATTACK_PERCENTAGE) > 200 then WRITE_CP_ATTRIB(v, ATTR_ATTACK_PERCENTAGE, 180) end
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_BLAST, math.random(6,8)-(difficulty()*1)) --spells
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_CONVERT_WILD, math.random(5,8)-(difficulty()*1))
			--SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_GHOST_ARMY, 12)
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_INSECT_PLAGUE, math.random(13,18)-(difficulty()*2))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_LAND_BRIDGE, math.random(26,34)-(difficulty()*2))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_LIGHTNING_BOLT, math.random(34,44)-(difficulty()*3))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_INVISIBILITY, math.random(24,30)-(difficulty()*2))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_HYPNOTISM, math.random(32,38)-(difficulty()*2))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_WHIRLWIND, math.random(26,30)-(difficulty()*2))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_SWAMP, math.random(15,30)-(difficulty()*2))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_EARTHQUAKE, math.random(30,45)-(difficulty()*2))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_EROSION, math.random(32,48)-(difficulty()*3))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_FLATTEN, math.random(25,30)-(difficulty()*2))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_FIRESTORM, math.random(35,50)-(difficulty()*3))
			SET_BUCKET_COUNT_FOR_SPELL(v, M_SPELL_SHIELD, math.random(20,30)-(difficulty()*2))
			--update AI table
			if v == 1 then
				if IS_SHAMAN_IN_AREA(v,24,24) then --CHANGE MARKER NUMBER!
					--spells in base defense
					SET_SPELL_ENTRY(v, 0, M_SPELL_BLAST, SPELL_COST(M_SPELL_BLAST) >> (1+difficulty()), 128, 1, 1)
					SET_SPELL_ENTRY(v, 1, M_SPELL_LIGHTNING_BOLT, SPELL_COST(M_SPELL_LIGHTNING_BOLT) >> (1+difficulty()), 128, 1, 1)
					SET_SPELL_ENTRY(v, 2, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> (1+difficulty()), 128, 5-difficulty(), 1)
					SET_SPELL_ENTRY(v, 3, M_SPELL_SWAMP, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> (1+difficulty()), 128, 13-difficulty(), 1)
					if gameStage > 1 then
						SET_SPELL_ENTRY(v, 4, M_SPELL_HYPNOTISM, SPELL_COST(M_SPELL_HYPNOTISM) >> (1+difficulty()), 128, 12-(difficulty()*2), 1)
					end
				else
					--spells when attacking
					SET_SPELL_ENTRY(v, 0, M_SPELL_BLAST, SPELL_COST(M_SPELL_BLAST) >> (1+difficulty()), 128, 1, 0)
					SET_SPELL_ENTRY(v, 1, M_SPELL_LIGHTNING_BOLT, SPELL_COST(M_SPELL_LIGHTNING_BOLT) >> (1+difficulty()), 128, 1, 0)
					SET_SPELL_ENTRY(v, 2, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> (1+difficulty()), 128, 5-difficulty(), 0)
					SET_SPELL_ENTRY(v, 3, M_SPELL_SWAMP, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> (1+difficulty()), 128, 12-difficulty(), 0)
					if gameStage > 1 then
						SET_SPELL_ENTRY(v, 4, M_SPELL_HYPNOTISM, SPELL_COST(M_SPELL_HYPNOTISM) >> (1+difficulty()), 128, 12-(difficulty()*2), 0)
						if gamestage == 3 then
							SET_SPELL_ENTRY(v, 5, M_SPELL_FIRESTORM, SPELL_COST(M_SPELL_FIRESTORM) >> (1+difficulty()), 128, 18-(difficulty()*2), 0)
							SET_SPELL_ENTRY(v, 6, M_SPELL_EARTHQUAKE, SPELL_COST(M_SPELL_EARTHQUAKE) >> (1+difficulty()), 128, 16-(difficulty()*2), 0)
							if difficulty() == 3 then
								SET_SPELL_ENTRY(v, 7, M_SPELL_ANGEL_OF_DEATH, SPELL_COST(M_SPELL_ANGEL_OF_DEATH) >> (1+difficulty()), 128, 32-(difficulty()*3), 0)
							end
						end
					end
				end
				AI.ai1.pop = _gsi.Players[v].NumPeople
				AI.ai1.troops = _gsi.Players[v].NumPeople-_gsi.Players[v].NumPeopleOfType[M_PERSON_BRAVE]
				AI.ai1.braves = _gsi.Players[v].NumPeopleOfType[M_PERSON_BRAVE]
				AI.ai1.wars = _gsi.Players[v].NumPeopleOfType[M_PERSON_WARRIOR]
				AI.ai1.fws = _gsi.Players[v].NumPeopleOfType[M_PERSON_SUPER_WARRIOR]
				AI.ai1.spies = _gsi.Players[v].NumPeopleOfType[M_PERSON_SPY]
				AI.ai1.preachers = _gsi.Players[v].NumPeopleOfType[M_PERSON_RELIGIOUS]
				AI.ai1.buildings = _gsi.Players[v].NumBuildings
				AI.ai1.huts = _gsi.Players[v].NumBuildingsOfType[M_BUILDING_TEPEE]+_gsi.Players[v].NumBuildingsOfType[M_BUILDING_TEPEE_2]+_gsi.Players[v].NumBuildingsOfType[M_BUILDING_TEPEE_3]
				AI.ai1.towers = _gsi.Players[v].NumBuildingsOfType[M_BUILDING_DRUM_TOWER]
				--conditional stuff
				if AI.ai1.huts > 3 then WRITE_CP_ATTRIB(v, ATTR_PREF_SUPER_WARRIOR_TRAINS, 1) else WRITE_CP_ATTRIB(v, ATTR_PREF_SUPER_WARRIOR_TRAINS, 0) end
				if AI.ai1.huts > 6 then WRITE_CP_ATTRIB(v, ATTR_PREF_RELIGIOUS_TRAINS, 1) else WRITE_CP_ATTRIB(v, ATTR_PREF_RELIGIOUS_TRAINS, 0) end
				if AI.ai1.pop < 2 then GIVE_UP_AND_SULK(v,TRUE) end
				if gameStage == 2 then
					if #tribe1AtkSpells == 4 then
						table.insert(tribe1AtkSpells,M_SPELL_WHIRLWIND)
						if #tribe1AtkSpells == 6 and difficulty() >= 3 then
							table.insert(tribe1AtkSpells,M_SPELL_EROSION)
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
			else
				if IS_SHAMAN_IN_AREA(v,25,19) then --CHANGE MARKER NUMBER(and radius)!
					--spells in base defense
					SET_SPELL_ENTRY(v, 0, M_SPELL_BLAST, SPELL_COST(M_SPELL_BLAST) >> (1+difficulty()), 128, 1, 1)
					SET_SPELL_ENTRY(v, 1, M_SPELL_LIGHTNING_BOLT, SPELL_COST(M_SPELL_LIGHTNING_BOLT) >> (1+difficulty()), 128, 1, 1)
					SET_SPELL_ENTRY(v, 2, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> (1+difficulty()), 128, 5-difficulty(), 1)
					SET_SPELL_ENTRY(v, 3, M_SPELL_SWAMP, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> (1+difficulty()), 128, 13-difficulty(), 1)
					if gameStage > 1 then
						SET_SPELL_ENTRY(v, 4, M_SPELL_HYPNOTISM, SPELL_COST(M_SPELL_HYPNOTISM) >> (1+difficulty()), 128, 12-(difficulty()*2), 1)
					end
				else
					--spells when attacking
					SET_SPELL_ENTRY(v, 0, M_SPELL_BLAST, SPELL_COST(M_SPELL_BLAST) >> (1+difficulty()), 128, 1, 0)
					SET_SPELL_ENTRY(v, 1, M_SPELL_LIGHTNING_BOLT, SPELL_COST(M_SPELL_LIGHTNING_BOLT) >> (1+difficulty()), 128, 1, 0)
					SET_SPELL_ENTRY(v, 2, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> (1+difficulty()), 128, 5-difficulty(), 0)
					SET_SPELL_ENTRY(v, 3, M_SPELL_SWAMP, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> (1+difficulty()), 128, 12-difficulty(), 0)
					if gameStage > 1 then
						SET_SPELL_ENTRY(v, 4, M_SPELL_HYPNOTISM, SPELL_COST(M_SPELL_HYPNOTISM) >> (1+difficulty()), 128, 12-(difficulty()*2), 0)
						if gamestage == 3 then
							SET_SPELL_ENTRY(v, 5, M_SPELL_FIRESTORM, SPELL_COST(M_SPELL_FIRESTORM) >> (1+difficulty()), 128, 18-(difficulty()*2), 0)
							SET_SPELL_ENTRY(v, 6, M_SPELL_EARTHQUAKE, SPELL_COST(M_SPELL_EARTHQUAKE) >> (1+difficulty()), 128, 16-(difficulty()*2), 0)
							if difficulty() == 3 then
								SET_SPELL_ENTRY(v, 7, M_SPELL_ANGEL_OF_DEATH, SPELL_COST(M_SPELL_ANGEL_OF_DEATH) >> (1+difficulty()), 128, 32-(difficulty()*3), 0)
							end
						end
					end
				end
				AI.ai2.pop = _gsi.Players[v].NumPeople
				AI.ai2.troops = _gsi.Players[v].NumPeople-_gsi.Players[v].NumPeopleOfType[M_PERSON_BRAVE]
				AI.ai2.braves = _gsi.Players[v].NumPeopleOfType[M_PERSON_BRAVE]
				AI.ai2.wars = _gsi.Players[v].NumPeopleOfType[M_PERSON_WARRIOR]
				AI.ai2.fws = _gsi.Players[v].NumPeopleOfType[M_PERSON_SUPER_WARRIOR]
				AI.ai2.spies = _gsi.Players[v].NumPeopleOfType[M_PERSON_SPY]
				AI.ai2.preachers = _gsi.Players[v].NumPeopleOfType[M_PERSON_RELIGIOUS]
				AI.ai2.buildings = _gsi.Players[v].NumBuildings
				AI.ai2.huts = _gsi.Players[v].NumBuildingsOfType[M_BUILDING_TEPEE]+_gsi.Players[v].NumBuildingsOfType[M_BUILDING_TEPEE_2]+_gsi.Players[v].NumBuildingsOfType[M_BUILDING_TEPEE_3]
				AI.ai2.towers = _gsi.Players[v].NumBuildingsOfType[M_BUILDING_DRUM_TOWER]
				--conditional stuff
				if AI.ai2.huts > 2 then WRITE_CP_ATTRIB(v, ATTR_PREF_SUPER_WARRIOR_TRAINS, 1) else WRITE_CP_ATTRIB(v, ATTR_PREF_SUPER_WARRIOR_TRAINS, 0) end
				if AI.ai2.huts > 5 then WRITE_CP_ATTRIB(v, ATTR_PREF_RELIGIOUS_TRAINS, 1) else WRITE_CP_ATTRIB(v, ATTR_PREF_RELIGIOUS_TRAINS, 0) end
				if AI.ai2.pop < 2 then GIVE_UP_AND_SULK(v,TRUE) end
				if gameStage == 2 then
					if #tribe2AtkSpells == 4 then
						table.insert(tribe2AtkSpells,M_SPELL_WHIRLWIND)
						if #tribe2AtkSpells == 6 and difficulty() >= 3 then
							table.insert(tribe2AtkSpells,M_SPELL_EARTHQUAKE)
						end
					end
				elseif gameStage == 3 then
					if #tribe2AtkSpells == 5 then
						table.insert(tribe2AtkSpells,M_SPELL_EARTHQUAKE)
						if #tribe2AtkSpells == 6 and difficulty() >= 3 then
							table.insert(tribe2AtkSpells,M_SPELL_EARTHQUAKE)
						end
					end	
				end
			end
		end	
	end

	if everySeconds(20-(difficulty()*4)) then
		--AI shamans near blue base burn trees occasionally
		for i,v in ipairs(AItribes) do
			if getShaman(v) ~= nil and IS_SHAMAN_IN_AREA(v,0,16) == 1 then --mk0 is middle of blue base
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
	end
end


local safeZones = {}
local m1 = MapPosXZ.new()
for x= 0,10 do ; for z= 226,238 do
    m1.XZ.X = x ; m1.XZ.Z = z ; table.insert(safeZones, m1.Pos)
end end
function OnCreateThing(t)
	--factions stuff
	if faction1 == 1 then
		if t.Type == T_PERSON and t.Model == M_PERSON_WARRIOR and t.Owner == 0 then -- -25% war hp
			t.u.Pers.MaxLife = math.ceil(t.u.Pers.MaxLife-((t.u.Pers.MaxLife*25)/100)) ; t.u.Pers.Life = t.u.Pers.MaxLife
		elseif t.Type == T_PERSON and t.Model == M_PERSON_SUPER_WARRIOR and t.Owner == 0 then -- no regen hp night/rain
			if day == 0 then
				t.u.Pers.MaxLife = t.u.Pers.Life
			else
				if t.u.Pers.MaxLife < 500 then t.u.Pers.MaxLife = math.random(500,600) end
			end
		end
	end
	if faction2 == 1 then
		if t.Type == T_PERSON and t.Model == M_PERSON_RELIGIOUS and t.Owner == 0 then -- -20% preacher hp
			t.u.Pers.MaxLife = math.ceil(t.u.Pers.MaxLife-((t.u.Pers.MaxLife*20)/100)) ; t.u.Pers.Life = t.u.Pers.MaxLife
		end
	end
	if faction3 == 2 then
		if t.Type == T_PERSON and t.Model == M_PERSON_SUPER_WARRIOR and t.Owner == 0 then -- +20% fw hp
			t.u.Pers.MaxLife = math.ceil(t.u.Pers.MaxLife+((t.u.Pers.MaxLife*20)/100)) ; t.u.Pers.Life = t.u.Pers.MaxLife
		end
		if t.Type == T_PERSON and t.Model == M_PERSON_WARRIOR and t.Owner == 0 then -- +10% war hp
			t.u.Pers.MaxLife = math.ceil(t.u.Pers.MaxLife+((t.u.Pers.MaxLife*10)/100)) ; t.u.Pers.Life = t.u.Pers.MaxLife
		end
	end

	--safe zones
	local m = t.Model
	if m == M_SPELL_EARTHQUAKE or m == M_SPELL_EROSION or m == M_SPELL_VOLCANO or m == M_SPELL_LAND_BRIDGE then
		if (t.Type == T_SPELL) then
			local pos = world_coord3d_to_map_idx(t.Pos.D3)
			for k, v in pairs(safeZones) do
				if (v == pos) then
					t.Model = M_SPELL_NONE
				end
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
	
	if turn() > levelUpTurn and level == 0 and getShaman(0) ~= nil and IS_SHAMAN_IN_AREA(0,0,1) == 1 then
		gns.Flags = gns.Flags | GNS_PAUSED
		local normalFont = 3 ; local titleFont = 1
		if w <= 800 then normalFont = 8 titleFont = 3 end
		PopSetFont(normalFont)
		local longestLeftStr = string_width("-  firewarriors don't regen HP during the night")
		local longestRightStr = string_width("+  units 40% HP regen, up to 80% during the night")
		local numLines = 8
		DrawBox(middle-32-longestLeftStr-2,math.floor(h/4),longestLeftStr+4,numLines*18,1)
		DrawBox(middle+32-2,math.floor(h/4),longestRightStr+4,numLines*18,1)
		local Ltitle = "Order of the Flame"
		local L1 = "+  firewarrior training hut"
		local L2 = "+  firestorm spell"
		local L3 = "-  25% warrior HP"
		local L4 = "-  firewarriors don't regen HP during the night"
		local Rtitle = "Order of the River"
		local R1 = "+  boat hut"
		local R2 = "+  erosion spell"
		local R3 = "+  units 40% HP regen, up to 80% during night time"
		local R4 = "-  100% hut upgrade/sprogging during the day"
		PopSetFont(titleFont)
		LbDraw_Text(middle-32-longestLeftStr-2+math.floor((longestLeftStr)/2)-math.floor(string_width(Ltitle)/2),math.floor(h/4),Ltitle,0)
		LbDraw_Text(middle+32-2+math.floor((longestRightStr)/2)-math.floor(string_width(Rtitle)/2),math.floor(h/4),Rtitle,0)
		PopSetFont(4)
		LbDraw_Text(math.floor(middle-32-(longestLeftStr/2)-(string_width"Press F Key")/2),math.floor(h/4)+18*numLines+18,"Press F Key",0)
		LbDraw_Text(math.floor(middle+32+(longestRightStr/2)-(string_width"Press R Key")/2),math.floor(h/4)+18*numLines+18,"Press R Key",0)
		PopSetFont(normalFont)
		LbDraw_Text(middle-32-longestLeftStr,math.floor((h/4)+18*2),L1,0)
		LbDraw_Text(middle-32-longestLeftStr,math.floor((h/4)+18*3),L2,0)
		LbDraw_Text(middle-32-longestLeftStr,math.floor((h/4)+18*5),L3,0)
		LbDraw_Text(middle-32-longestLeftStr,math.floor((h/4)+18*6),L4,0)
		LbDraw_Text(middle+32,math.floor((h/4)+18*2),R1,0)
		LbDraw_Text(middle+32,math.floor((h/4)+18*3),R2,0)
		LbDraw_Text(middle+32,math.floor((h/4)+18*4),R3,0)
		LbDraw_Text(middle+32,math.floor((h/4)+18*6),R4,0)
	elseif turn() > levelUpTurn and level == 1 and getShaman(0) ~= nil and IS_SHAMAN_IN_AREA(0,0,1) == 1 then
		gns.Flags = gns.Flags | GNS_PAUSED
		local normalFont = 3 ; local titleFont = 1
		if w <= 800 then normalFont = 8 titleFont = 3 end
		PopSetFont(normalFont)
		local longestLeftStr = string_width("+  1 lightning and tornado shot / minute")
		local longestRightStr = string_width("+  preacher ability to heal the closest unit")
		local numLines = 11
		DrawBox(middle-32-longestLeftStr-2,math.floor(h/4),longestLeftStr+4,numLines*18,1)
		DrawBox(middle+32-2,math.floor(h/4),longestRightStr+4,numLines*18,1)
		local Ltitle = "Order of the Thunder"
		local L1 = "+  1 lightning and tornado shot / minute"
		local L2 = "+  balloon hut"
		local L3 = "+  mana income at night"
		local L4 = "-  20% preacher HP"
		local L5 = "-  1 max shot of blast spell"
		local Rtitle = "Order of the Nature"
		local R1 = "+  preacher ability to heal the closest unit"
		local R2 = "   (except preachers/shaman)"
		local R3 = "+  landbridge spell"
		local R4 = "~  nights last 50% longer"
		local R5 = "-  lightning spell"
		local R6 = "-  spy training hut"
		PopSetFont(titleFont)
		LbDraw_Text(middle-32-longestLeftStr-2+math.floor((longestLeftStr)/2)-math.floor(string_width(Ltitle)/2),math.floor(h/4),Ltitle,0)
		LbDraw_Text(middle+32-2+math.floor((longestRightStr)/2)-math.floor(string_width(Rtitle)/2),math.floor(h/4),Rtitle,0)
		PopSetFont(4)
		LbDraw_Text(math.floor(middle-32-(longestLeftStr/2)-(string_width"Press T Key")/2),math.floor(h/4)+18*numLines+18,"Press T Key",0)
		LbDraw_Text(math.floor(middle+32+(longestRightStr/2)-(string_width"Press N Key")/2),math.floor(h/4)+18*numLines+18,"Press N Key",0)
		PopSetFont(normalFont)
		LbDraw_Text(middle-32-longestLeftStr,math.floor((h/4)+18*2),L1,0)
		LbDraw_Text(middle-32-longestLeftStr,math.floor((h/4)+18*3),L2,0)
		LbDraw_Text(middle-32-longestLeftStr,math.floor((h/4)+18*4),L3,0)
		LbDraw_Text(middle-32-longestLeftStr,math.floor((h/4)+18*6),L4,0)
		LbDraw_Text(middle-32-longestLeftStr,math.floor((h/4)+18*7),L5,0)
		LbDraw_Text(middle+32,math.floor((h/4)+18*2),R1,0)
		LbDraw_Text(middle+32,math.floor((h/4)+18*3),R2,0)
		LbDraw_Text(middle+32,math.floor((h/4)+18*4),R3,0)
		LbDraw_Text(middle+32,math.floor((h/4)+18*6),R4,0)
		LbDraw_Text(middle+32,math.floor((h/4)+18*8),R5,0)
		LbDraw_Text(middle+32,math.floor((h/4)+18*9),R6,0)
	elseif turn() > levelUpTurn and level == 2 and getShaman(0) ~= nil and IS_SHAMAN_IN_AREA(0,0,1) == 1 then
		gns.Flags = gns.Flags | GNS_PAUSED
		local normalFont = 3 ; local titleFont = 1
		if w <= 800 then normalFont = 8 titleFont = 3 end
		PopSetFont(normalFont)
		local longestLeftStr = string_width("   2% of nearby units' max HP/sec (1 radius)")
		local longestRightStr = string_width("+  1 invisibility and magical shield shot / minute")
		local numLines = 10
		DrawBox(middle-32-longestLeftStr-2,math.floor(h/4),longestLeftStr+4,numLines*18,1)
		DrawBox(middle+32-2,math.floor(h/4),longestRightStr+4,numLines*18,1)
		local Ltitle = "Order of the Pestilence"
		local L1 = "+  2 swarm shots / minute"
		local L2 = "+  swamp spell"
		local L3 = "+  1 angel of death shot / 10 minutes"
		local L4 = "+  your braves carry disease: they deal"
		local L5 = "   2% of nearby units' max HP/sec (1 radius)"
		local L6 = "-  earthquake spell"
		local Rtitle = "Order of the Eagle"
		local R1 = "+  1 invisibility and magical shield shot / minute"
		local R2 = "+  hypnotise spell"
		local R3 = "+  20% firewarrior HP"
		local R4 = "+  10% warrior HP"
		local R5 = "-  swarm spell"
		local R6 = "-  you can not own preachers"
		PopSetFont(titleFont)
		LbDraw_Text(middle-32-longestLeftStr-2+math.floor((longestLeftStr)/2)-math.floor(string_width(Ltitle)/2),math.floor(h/4),Ltitle,0)
		LbDraw_Text(middle+32-2+math.floor((longestRightStr)/2)-math.floor(string_width(Rtitle)/2),math.floor(h/4),Rtitle,0)
		PopSetFont(4)
		LbDraw_Text(math.floor(middle-32-(longestLeftStr/2)-(string_width"Press X Key")/2),math.floor(h/4)+18*numLines+18,"Press X Key",0)
		LbDraw_Text(math.floor(middle+32+(longestRightStr/2)-(string_width"Press E Key")/2),math.floor(h/4)+18*numLines+18,"Press E Key",0)
		PopSetFont(normalFont)
		LbDraw_Text(middle-32-longestLeftStr,math.floor((h/4)+18*2),L1,0)
		LbDraw_Text(middle-32-longestLeftStr,math.floor((h/4)+18*3),L2,0)
		LbDraw_Text(middle-32-longestLeftStr,math.floor((h/4)+18*4),L3,0)
		LbDraw_Text(middle-32-longestLeftStr,math.floor((h/4)+18*5),L4,0)
		LbDraw_Text(middle-32-longestLeftStr,math.floor((h/4)+18*6),L5,0)
		LbDraw_Text(middle-32-longestLeftStr,math.floor((h/4)+18*8),L6,0)
		LbDraw_Text(middle+32,math.floor((h/4)+18*2),R1,0)
		LbDraw_Text(middle+32,math.floor((h/4)+18*3),R2,0)
		LbDraw_Text(middle+32,math.floor((h/4)+18*4),R3,0)
		LbDraw_Text(middle+32,math.floor((h/4)+18*5),R4,0)
		LbDraw_Text(middle+32,math.floor((h/4)+18*7),R5,0)
		LbDraw_Text(middle+32,math.floor((h/4)+18*8),R6,0)
	end
	
	--honor save timer
	if turn() < honorSaveTurnLimit and turn() > 1200 and difficulty() == 3 then
		PopSetFont(3)
		local hstl = "WARNING (honour mode): You are able to save the game before the timer ends, to avoid rewatching the intro     "
		LbDraw_Text(math.floor(w-2-(string_width("77:77")+string_width(tostring(hstl)))),2,tostring(hstl),0)
		LbDraw_Text(math.floor(w-2-(string_width("77:77"))),2,tostring(TurnsToClock(math.floor((honorSaveTurnLimit-turn())/12))),0)
	end
	--faction symbols top left screen
	local boxClr = 1 --black
	local offset = guiW+8
	local separate = box+8
	local outBoxClr = 4
	if level >= 1 then
		--show TAB text
		PopSetFont(11)
		local tab = "Press TAB for factions" ; LbDraw_Text(2,2,tostring(tab),0)
		DrawBox(1,1,4+string_width(tostring(tab)),4+10,0) ; DrawBox(3,3,string_width(tostring(tab)),10,1) ; LbDraw_Text(3,3,tostring(tab),0)
		--
		DrawBox(guiW+6,2,box+4,box+4,outBoxClr)--
		if faction1 == 1 then
			DrawBox(offset,4,box,box,boxClr)
			local spr = 1734 ; LbDraw_ScaledSprite(offset,4,get_sprite(0,spr),box,box)
		elseif faction1 == 2 then
			DrawBox(offset,4,box,box,boxClr)
			local spr = 1735 ; LbDraw_ScaledSprite(offset,4,get_sprite(0,spr),box,box)
		end
	end
	if level >= 2 then
		DrawBox(guiW+6+separate,2,box+4,box+4,outBoxClr)--
		if faction2 == 1 then
			DrawBox(offset+separate,4,box,box,boxClr)
			local spr = 1736 ; LbDraw_ScaledSprite(offset+separate,4,get_sprite(0,spr),box,box)
		elseif faction2 == 2 then
			DrawBox(offset+separate,4,box,box,boxClr)
			local spr = 1737 ; LbDraw_ScaledSprite(offset+separate,4,get_sprite(0,spr),box,box)
		end
	end
	if level >= 3 then
		DrawBox(guiW+6+separate+separate,2,box+4,box+4,outBoxClr)--
		if faction3 == 1 then
			DrawBox(offset+separate+separate,4,box,box,boxClr)
			local spr = 1738 ; LbDraw_ScaledSprite(offset+separate+separate,4,get_sprite(0,spr),box,box)
		elseif faction3 == 2 then
			DrawBox(offset+separate+separate,4,box,box,boxClr)
			local spr = 1739 ; LbDraw_ScaledSprite(offset+separate+separate,4,get_sprite(0,spr),box,box)
		end
	end
end


--TAB (check factions descriptions)
import(Module_Helpers)
function OnKeyDown(key)
	if key == LB_KEY_1 then
		level = 1 faction1 = 1
	elseif key == LB_KEY_2 then
		level = 2 faction2 = 1
	elseif key == LB_KEY_3 then
		level = 3 faction3 = 1
	end
    if (key == LB_KEY_TAB) and (level > 0) then
        g_DrawMenu = not g_DrawMenu
    end
	if turn() > levelUpTurn and getShaman(0) ~= nil and IS_SHAMAN_IN_AREA(0,0,1) == 1 then
		if level == 0 then
			if key == LB_KEY_F then
				gns.Flags = gns.Flags ~ GNS_PAUSED
				level = 1 ; faction1 = 1 ; talk1 = 1
				levelUpTurn = turn() + factionTimerIncrement + math.random(400)+(difficulty()*300)
				queue_sound_event(nil, SND_EVENT_DISCOBLDG_CIRC, SEF_FIXED_VARS)
				ProcessGlobalSpecialList(TRIBE_BLUE, PEOPLELIST, function(t)
					if t.Type == T_PERSON and t.Model == M_PERSON_WARRIOR and t.Owner == 0 then -- -25% war hp
						t.u.Pers.MaxLife = math.ceil(t.u.Pers.MaxLife-((t.u.Pers.MaxLife*25)/100)) ; t.u.Pers.Life = t.u.Pers.MaxLife
					end
				return true end)
			elseif key == LB_KEY_R then
				gns.Flags = gns.Flags ~ GNS_PAUSED
				level = 1 ; faction1 = 2 ; talk1 = 1
				levelUpTurn = turn() + factionTimerIncrement + math.random(400)+(difficulty()*300)
				queue_sound_event(nil, SND_EVENT_DISCOBLDG_CIRC, SEF_FIXED_VARS)
			end
		elseif level == 1 then
			if key == LB_KEY_T then
				gns.Flags = gns.Flags ~ GNS_PAUSED
				level = 2 ; faction2 = 1 ; talk2 = 1 ; thunderGet = 720
				levelUpTurn = turn() + factionTimerIncrement + math.random(400)+(difficulty()*300)
				queue_sound_event(nil, SND_EVENT_DISCOBLDG_CIRC, SEF_FIXED_VARS)
				ProcessGlobalSpecialList(TRIBE_BLUE, PEOPLELIST, function(t)
					if t.Type == T_PERSON and t.Model == M_PERSON_RELIGIOUS and t.Owner == 0 then -- -20% preacher hp
						t.u.Pers.MaxLife = math.ceil(t.u.Pers.MaxLife-((t.u.Pers.MaxLife*20)/100)) ; t.u.Pers.Life = t.u.Pers.MaxLife
					end
				return true end)
			elseif key == LB_KEY_N then
				gns.Flags = gns.Flags ~ GNS_PAUSED
				level = 2 ; faction2 = 2 ; talk2 = 1
				levelUpTurn = turn() + factionTimerIncrement + math.random(400)+(difficulty()*300)
				queue_sound_event(nil, SND_EVENT_DISCOBLDG_CIRC, SEF_FIXED_VARS)
			end
		elseif level == 2 then
			if key == LB_KEY_X then
				gns.Flags = gns.Flags ~ GNS_PAUSED
				level = 3 ; faction3 = 1 ; talk3 = 1 ; pestilence1Get = 720 ; pestilence2Get = 720*10
				levelUpTurn = -1
				queue_sound_event(nil, SND_EVENT_DISCOBLDG_CIRC, SEF_FIXED_VARS)
				ProcessGlobalTypeList(T_EFFECT ,function(t)
					if t.Model == 10 then
						t.u.Effect.Duration = 24
					end
				return true end)
			elseif key == LB_KEY_E then
				gns.Flags = gns.Flags ~ GNS_PAUSED
				level = 3 ; faction3 = 2 ; talk3 = 1 ; eagleGet = 720
				levelUpTurn = -1
				queue_sound_event(nil, SND_EVENT_DISCOBLDG_CIRC, SEF_FIXED_VARS)
				ProcessGlobalSpecialList(TRIBE_BLUE, PEOPLELIST, function(t)
					if t.Type == T_PERSON and t.Model == M_PERSON_SUPER_WARRIOR and t.Owner == 0 then -- +20% fw hp
						t.u.Pers.MaxLife = math.ceil(t.u.Pers.MaxLife+((t.u.Pers.MaxLife*20)/100)) ; t.u.Pers.Life = t.u.Pers.MaxLife
					end
					if t.Type == T_PERSON and t.Model == M_PERSON_WARRIOR and t.Owner == 0 then -- +10% war hp
						t.u.Pers.MaxLife = math.ceil(t.u.Pers.MaxLife+((t.u.Pers.MaxLife*10)/100)) ; t.u.Pers.Life = t.u.Pers.MaxLife
					end
				return true end)
				ProcessGlobalTypeList(T_EFFECT ,function(t)
					if t.Model == 10 then
						t.u.Effect.Duration = 24
					end
				return true end)
			end
		end
	end
end
function OnImGuiFrame()
    if (g_DrawMenu) and level >= 1 then
		imgui.Begin('Your choosen factions:', nil, ImGuiWindowFlags_AlwaysAutoResize)
		
		if faction1 == 1 then
			imgui.TextUnformatted("Faction 1: Order of the Flame:")
			imgui.NextColumn()
			imgui.TextUnformatted("   + firewarrior hut")
			imgui.NextColumn()
			imgui.TextUnformatted("   + firestorm spell")
			imgui.NextColumn()
			imgui.TextUnformatted("   - 25% warrior HP")
			imgui.NextColumn()
			imgui.TextUnformatted("   - firewarrior HP regen during night")
			imgui.NextColumn()
		elseif faction1 == 2 then
			imgui.TextUnformatted("Faction 1: Order of the River:")
			imgui.NextColumn()
			imgui.TextUnformatted("   + boat hut")
			imgui.NextColumn()
			imgui.TextUnformatted("   + erosion spell")
			imgui.NextColumn()
			imgui.TextUnformatted("   + units 40% HP regen, up to 80% at night")
			imgui.NextColumn()
			imgui.TextUnformatted("   - 100% hut upgrade/sprogging progress during day")
		end
		if level >= 2 then
			imgui.TextUnformatted("")
			imgui.NextColumn()
			
			if faction2 == 1 then
				imgui.TextUnformatted("Faction 2: Order of the Thunder:")
				imgui.NextColumn()
				imgui.TextUnformatted("   + 1 lightning and tornado shot / minute")
				imgui.NextColumn()
				imgui.TextUnformatted("   + balloon hut")
				imgui.NextColumn()
				imgui.TextUnformatted("   + mana income at night")
				imgui.NextColumn()
				imgui.TextUnformatted("   - 20% preacher HP")
				imgui.NextColumn()
				imgui.TextUnformatted("   - 1 max shot of blast spell")
			elseif faction2 == 2 then
				imgui.TextUnformatted("Faction 2: Order of the Nature:")
				imgui.NextColumn()
				imgui.TextUnformatted("   + preacher ability to heal the closest unit (except preachers/shaman)")
				imgui.NextColumn()
				imgui.TextUnformatted("   + landbridge spell")
				imgui.NextColumn()
				imgui.TextUnformatted("   | nights last 50% longer")
				imgui.NextColumn()
				imgui.TextUnformatted("   - lightning spell")
				imgui.NextColumn()
				imgui.TextUnformatted("   - spy hut")
			end
		end
		if level == 3 then
			imgui.TextUnformatted("")
			imgui.NextColumn()
			
			if faction3 == 1 then
				imgui.TextUnformatted("Faction 3: Order of the Pestilence:")
				imgui.NextColumn()
				imgui.TextUnformatted("   + 2 swarm shots / minute")
				imgui.NextColumn()
				imgui.TextUnformatted("   + swamp spell")
				imgui.NextColumn()
				imgui.TextUnformatted("   + 1 angel of death shot / 10 minutes")
				imgui.NextColumn()
				imgui.TextUnformatted("   + your braves carry disease: they deal 2% of nearby units' max HP/sec (1 radius)")
				imgui.NextColumn()
				imgui.TextUnformatted("   - earthquake spell")
			elseif faction3 == 2 then
				imgui.TextUnformatted("Faction 3: Order of the Eagle:")
				imgui.NextColumn()
				imgui.TextUnformatted("   + 1 invisibility and magical shield shot / minute")
				imgui.NextColumn()
				imgui.TextUnformatted("   + hypnotise spell")
				imgui.NextColumn()
				imgui.TextUnformatted("   + 20% firewarrior HP")
				imgui.NextColumn()
				imgui.TextUnformatted("   + 10% warrior HP")
				imgui.NextColumn()
				imgui.TextUnformatted("   - swarm spell")
				imgui.NextColumn()
				imgui.TextUnformatted("   - you can not own preachers")
			end
		end
		
		imgui.End()
	end
end

function HealingPreachers()
	ProcessGlobalSpecialList(0,PEOPLELIST, function(t)
		if (t.Type == T_PERSON and t.Model == M_PERSON_RELIGIOUS) then
			local a = 0
			SearchMapCells(CIRCULAR, 0, 0, 1, world_coord3d_to_map_idx(t.Pos.D3), function(me)
				me.MapWhoList:processList( function (h)
					if (h.Owner == 0) and (h.Type == T_PERSON) and (h.Model < 7) and (h.Model ~= t.Model) then
						if h.u.Pers.Life <  h.u.Pers.MaxLife - 40 and a == 0 then
							damage_person (h,8,-40,1)
							a = 1
							local effect = createThing(T_EFFECT,M_EFFECT_SPARKLE,8,h.Pos.D3,false,false) ; effect.DrawInfo.Alpha = G_RANDOM(2)
							queue_sound_event(h,SND_EVENT_BIRTH, SEF_FIXED_VARS) --annoying? omegaKEKW ty inca for sounds not attaching to things
						end
					end
				return true end)
			return true end)
		end
	return true end)
end

function DiseaseBraves()
	ProcessGlobalSpecialList(0,PEOPLELIST, function(t)
		if (t.Type == T_PERSON and t.Model == M_PERSON_BRAVE) then
			SearchMapCells(CIRCULAR, 0, 0, 1, world_coord3d_to_map_idx(t.Pos.D3), function(me)
				me.MapWhoList:processList( function (h)
					if (h.Owner ~= 0) and (h.Type == T_PERSON) and (h.Model < 8) and (h.Model ~= M_PERSON_WILD) and (t.State ~= 23) then
						damage_person (h,8,math.floor(h.u.Pers.MaxLife/50),1) --2%/sec
						local effect = createThing(T_EFFECT,M_EFFECT_SMALL_SPARKLE,8,t.Pos.D3,false,false) ; effect.DrawInfo.Alpha = 1
						local effect = createThing(T_EFFECT,M_EFFECT_SMALL_SPARKLE,8,h.Pos.D3,false,false) ; effect.DrawInfo.Alpha = 1
					end
				return true end)
			return true end)
		end
	return true end)
end



function OnSave(save_data)
	
	for i = #tribe2AtkSpells, 1 do
		save_data:push_int(tribe2AtkSpells[i]);
	end
	save_data:push_int(#tribe2AtkSpells)
	for i = #tribe1AtkSpells, 1 do
		save_data:push_int(tribe1AtkSpells[i]);
	end
	save_data:push_int(#tribe1AtkSpells)
	save_data:push_int(atkRoulette)
	save_data:push_int(thunderGet)
	save_data:push_int(pestilence1Get)
	save_data:push_int(pestilence2Get)
	save_data:push_int(eagleGet)
	save_data:push_int(tribe1Atk1)
	save_data:push_int(tribe1MiniAtk1)
	save_data:push_int(tribe1NavStress)
	save_data:push_int(tribe2Atk1)
	save_data:push_int(tribe2MiniAtk1)
	save_data:push_int(tribe2NavStress)
	save_data:push_int(talk1)
	save_data:push_int(talk2)
	save_data:push_int(talk3)
	save_data:push_int(faction1)
	save_data:push_int(faction2)
	save_data:push_int(faction3)
	save_data:push_int(levelUpTurn)
	save_data:push_int(gameStage)
	save_data:push_int(day)
	save_data:push_int(turnDayChanges)
	save_data:push_int(honorSaveTurnLimit)
	save_data:push_int(level)
	save_data:push_bool(g_DrawMenu)
	Engine:saveData(save_data)
	
end

function OnLoad(load_data)
	game_loaded = true

	Engine:loadData(load_data);
	g_DrawMenu = load_data:pop_bool()
	level = load_data:pop_int()
	honorSaveTurnLimit = load_data:pop_int()
	turnDayChanges = load_data:pop_int()
	day = load_data:pop_int()
	gameStage = load_data:pop_int()
	levelUpTurn = load_data:pop_int()
	faction3 = load_data:pop_int()
	faction2 = load_data:pop_int()
	faction1 = load_data:pop_int()
	talk3 = load_data:pop_int()
	talk2 = load_data:pop_int()
	talk1 = load_data:pop_int()
	tribe2NavStress = load_data:pop_int()
	tribe2MiniAtk1 = load_data:pop_int()
	tribe2Atk1 = load_data:pop_int()
	tribe1NavStress = load_data:pop_int()
	tribe1MiniAtk1 = load_data:pop_int()
	tribe1Atk1 = load_data:pop_int()
	eagleGet = load_data:pop_int()
	pestilence2Get = load_data:pop_int()
	pestilence1Get = load_data:pop_int()
	thunderGet = load_data:pop_int()
	atkRoulette = load_data:pop_int()
	local numSpellsAtk1 = load_data:pop_int();
	for i = 1, numSpellsAtk1 do
		 tribe1AtkSpells[i] = load_data:pop_int();
	end
	local numSpellsAtk2 = load_data:pop_int();
	for i = 1, numSpellsAtk2 do
		 tribe2AtkSpells[i] = load_data:pop_int();
	end
end

--log_msg(8,"script ran successfully. Difficulty level: " .. difficulty())	