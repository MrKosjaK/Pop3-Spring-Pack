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
bti = building_type_info()
include("assets.lua")
change_sprite_bank(0,0)
set_level_type(10) --A
--------------------
sti[M_SPELL_INVISIBILITY].OneOffMaximum = 4
sti[M_SPELL_INVISIBILITY].WorldCoordRange = 4096
sti[M_SPELL_INVISIBILITY].CursorSpriteNum = 45
sti[M_SPELL_INVISIBILITY].ToolTipStrIdx = 818
sti[M_SPELL_INVISIBILITY].AvailableSpriteIdx = 359
sti[M_SPELL_INVISIBILITY].NotAvailableSpriteIdx = 377
sti[M_SPELL_INVISIBILITY].ClickedSpriteIdx = 395
sti[M_SPELL_SWAMP].OneOffMaximum = 4
sti[M_SPELL_SWAMP].WorldCoordRange = 4096
sti[M_SPELL_SWAMP].CursorSpriteNum = 53
sti[M_SPELL_SWAMP].ToolTipStrIdx = 823
sti[M_SPELL_SWAMP].AvailableSpriteIdx = 364
sti[M_SPELL_SWAMP].NotAvailableSpriteIdx = 382
sti[M_SPELL_SWAMP].ClickedSpriteIdx = 400
bti[M_BUILDING_SPY_TRAIN].ToolTipStrId2 = 641
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
sti[M_SPELL_GHOST_ARMY].Active = SPAC_NORMAL
sti[M_SPELL_GHOST_ARMY].NetworkOnly = 0
set_player_can_cast(M_SPELL_GHOST_ARMY, 0)
set_correct_gui_menu()
if difficulty() == 0 then
	set_player_can_cast(M_SPELL_INVISIBILITY, 0)
	set_player_can_cast(M_SPELL_LIGHTNING_BOLT, 0)
elseif difficulty() == 1 then
	set_player_can_cast(M_SPELL_INVISIBILITY, 0)
end
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
for t,w in ipairs (AItribes) do
	for k,v in ipairs(botSpells) do
		set_player_can_cast(v, w)
	end
	for k,v in ipairs(botBldgs) do
		set_player_can_build(v, w)
	end
end
--atk turns
tribe1Atk1 = 5700 + math.random(3333) - difficulty()*250
tribe1MiniAtk1 = 3800 - difficulty()*50
tribe1AtkSpells = {M_SPELL_LIGHTNING_BOLT,M_SPELL_INSECT_PLAGUE,M_SPELL_HYPNOTISM,M_SPELL_WHIRLWIND}
tribe1NavStress = 0
--
tribe2Atk1 = 8700 + math.random(3333) - difficulty()*250
tribe2MiniAtk1 = 3000 - difficulty()*50
tribe2AtkSpells = {M_SPELL_WHIRLWIND,M_SPELL_INSECT_PLAGUE,M_SPELL_HYPNOTISM,M_SPELL_WHIRLWIND}
tribe2NavStress = 0
--
tribe3Atk1 = 6000 + math.random(3333) - difficulty()*250
tribe3MiniAtk1 = 3100 - difficulty()*50
tribe3AtkSpells = {M_SPELL_LIGHTNING_BOLT,M_SPELL_HYPNOTISM,M_SPELL_HYPNOTISM,M_SPELL_WHIRLWIND}
tribe3NavStress = 0
--
tribe4Atk1 = 6300 + math.random(3333) - difficulty()*250
tribe4MiniAtk1 = 2950 - difficulty()*50
tribe4AtkSpells = {M_SPELL_LIGHTNING_BOLT,M_SPELL_INSECT_PLAGUE,M_SPELL_HYPNOTISM,M_SPELL_WHIRLWIND,M_SPELL_WHIRLWIND,M_SPELL_WHIRLWIND}
tribe4NavStress = 0
--M_SPELL_LIGHTNING_BOLT,M_SPELL_INSECT_PLAGUE,M_SPELL_HYPNOTISM,M_SPELL_WHIRLWIND,M_SPELL_SWAMP,M_SPELL_EROSION,M_SPELL_EARTHQUAKE,M_SPELL_FIRESTORM,M_SPELL_ANGEL_OF_DEATH,M_SPELL_VOLCANO

--vars
local game_loaded = false
local honorSaveTurnLimit = 1600 +12*20
local gameStage = 0
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
local teach = 0
local hiddenJ = 200
--
for i = 4,7 do
	--if (i == tribe1) or (i == tribe2) then
		--ATTRIBUTES

		--base
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
		--buildings
		STATE_SET(i, TRUE, CP_AT_TYPE_CONSTRUCT_BUILDING)
		STATE_SET(i, TRUE, CP_AT_TYPE_FETCH_WOOD)
		WRITE_CP_ATTRIB(i, ATTR_RANDOM_BUILD_SIDE, 1)
		WRITE_CP_ATTRIB(i, ATTR_PREF_WARRIOR_TRAINS, 1)
		WRITE_CP_ATTRIB(i, ATTR_PREF_SUPER_WARRIOR_TRAINS, 1)
		WRITE_CP_ATTRIB(i, ATTR_PREF_RELIGIOUS_TRAINS, 1)
		WRITE_CP_ATTRIB(i, ATTR_PREF_SPY_TRAINS, 0)
		--train
		WriteAiTrainTroops(i,14,14,14,0) --(pn,w,r,fw,spy)
		--vehicles
		--[[STATE_SET(i, TRUE, CP_AT_TYPE_BUILD_VEHICLE)
		STATE_SET(i, TRUE, CP_AT_TYPE_FETCH_FAR_VEHICLE)
		WRITE_CP_ATTRIB(i, ATTR_PREF_BOAT_HUTS, 1)
		WRITE_CP_ATTRIB(i, ATTR_PREF_BOAT_DRIVERS, 2+difficulty())
		WRITE_CP_ATTRIB(i, ATTR_PEOPLE_PER_BOAT, 2+difficulty())
		WRITE_CP_ATTRIB(i, ATTR_PREF_BALLOON_HUTS, 0)
		WRITE_CP_ATTRIB(i, ATTR_PREF_BALLOON_DRIVERS, 0)
		WRITE_CP_ATTRIB(i, ATTR_PEOPLE_PER_BALLOON, 0)]]
		--attack
		SET_ATTACK_VARIABLE(i,0)
		STATE_SET(i, TRUE, CP_AT_TYPE_AUTO_ATTACK)
		WRITE_CP_ATTRIB(i, ATTR_ATTACK_PERCENTAGE, 100)
		WRITE_CP_ATTRIB(i, ATTR_MAX_ATTACKS, 999)
		WRITE_CP_ATTRIB(i, ATTR_BASE_UNDER_ATTACK_RETREAT, 0)
		WRITE_CP_ATTRIB(i, ATTR_RETREAT_VALUE, 5)
		WRITE_CP_ATTRIB(i, ATTR_FIGHT_STOP_DISTANCE, 32)
		WRITE_CP_ATTRIB(i, ATTR_GROUP_OPTION, 0)
	--[[0 - Stop at waypoint (if exists) and before attack
		1 - Stop before attack only
		2 - Stop at waypoint (if exists) only
		3 - Don't stop anywhere]]
		WriteAiAttackers(i,0,35,35,35,0,100) --(pn,b,w,r,fw,spy,sh)
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
		
		WRITE_CP_ATTRIB(i, ATTR_SHAMEN_BLAST, 8)
	--end
end
--shaman stuff
SHAMAN_DEFEND(tribe1, 132, 106, TRUE)
SET_DRUM_TOWER_POS(tribe1, 132, 106)
SHAMAN_DEFEND(tribe2, 188, 194, TRUE)
SET_DRUM_TOWER_POS(tribe2, 188, 194)
SHAMAN_DEFEND(tribe3, 200, 60, TRUE)
SET_DRUM_TOWER_POS(tribe3, 200, 60)
SHAMAN_DEFEND(tribe4, 238, 132, TRUE)
SET_DRUM_TOWER_POS(tribe4, 238, 132)

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
		table.remove(staticJewelMk,idx) ; Jsprite = Jsprite + 1
	end
	for i = 22,27 do
		if i ~= 26 then createThing(T_EFFECT,M_EFFECT_REVEAL_FOG_AREA,8,marker_to_coord3d(i),false,false) end
	end
	hiddenJ = possibleJewelMk[math.random(1,#possibleJewelMk)]
	local jewel = createThing(T_EFFECT,10,8,marker_to_coord3d(hiddenJ),false,false) centre_coord3d_on_block(jewel.Pos.D3) ; set_thing_draw_info(jewel,TDI_SPRITE_F1_D1, Jsprite) 
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
  [2] = {"Huh!?..........! <br> .......... Did you hear that?!.......... It sounded like........... like.....", "villager #1", 1769, 0, 138},
  [3] = {"The earthquakes were the first warnings... and now that scream... I fear it has happened: The curse has been unleashed, once again, after so many centuries... We failed to protect the jewels... The culprit was that intruder, the Ikani!", "villager #2", 1770, 0, 146},
  [4] = {"(!) <br> We are all doomed! But there is hope - the curse will be lifted and abandon the host if it senses sign of life on the planet. <br> As long as one of us is alive by the end of the hunt, Ikani will perish. ", "Preacher #1", 1771, 0, 212},
  [5] = {"Don't bother engaging, she's currently immortal and unstoppable - run... run and hide! We stand no chance at war, but time is against her.", "villager #3", 1772, 0, 175},
  [6] = {"What have you done, Ikani...", "Tiyao", 6883, 2, 146},
  [7] = {"Yesss... If i knew it felt this way, i would have killed my whole tribe long ago... Now, prepare to die.", "Dark-Ikani", 1773, 0, 216},
  [8] = {"...................... <br> ... I can still hear the sound of pulsating hearts in this world... I failed to kill every remaining living thing...", "Dark-Ikani", 1775, 0, 216},
  [9] = {"Beautiful... Not a remaining living thing on this planet... Once again, justice has been made! Rest in peace, my daughters...", "Dark-Ikani", 1773, 0, 216},
  [10] = {"About 2000 years ago, on this very planet, a tragedy took place. <br> All the community leaders gathered and planned a hunt on a villager, who was suspected of witchcraft.", "Ikani", 6881, 1, 219},
  [11] = {"They were supposed to enter her home and arrest her the following day. But the villagers, tempered in anger, disobeyed the orders and secretly went to her place, that same night, burning the house to the ground.", "Ikani", 6881, 1, 219},
  [12] = {"Little they knew at the time, for the witch was not home - but instead, all her 8 daughters, who were fated to burn on their sleep.", "Ikani", 6881, 1, 219},
  [13] = {"Once the witch arrived home and came across the ashes of her daughters, sorrow, pain and revenge took over, and she conjured a curse so powerful that all her enemies wish they were never born.", "Ikani", 6881, 1, 219},
  [14] = {"First, she forged 8 jewels from the ashes of each daughter, and scattered them around the planet, granting them eternal rest.", "Ikani", 6881, 1, 219},
  [15] = {"Then, she pacted with a god of death, who granted her ultimate powers - powers which she used to hunt and kill every person, until no one was left alive. Then, she killed herself to pay the price.", "Ikani", 6881, 1, 219},
  [16] = {"Legend says the witch will once again reincarnate, when all the 8 daughters get reunited at the place they got murdered - to take revenge and hunt any living creature, once more.", "Ikani", 6881, 1, 219},
  [17] = {"This tree marks the place where their house was burnt. <br> But this is just a legend - probably a tale to scare the children at night...", "Ikani", 6881, 1, 219},
  [18] = {"Is that... i should collect it.", "Ikani", 6881, 1, 219},
  [19] = {"Only the shaman can collect jewels, and only one jewel at a time can be carried - they are to be disposed at the cemetery - the location where, according to the legend, the witch's house was burned.", "Info", 173, 0, 160},
  [20] = {"The land is weeping... One of the witch's daughters is once again reunited at the place where she met her grim end... I must find the others.", "Ikani", 6881, 1, 219},
  [21] = {"Justice shall be done.", "Dark-Ikani", 1773, 0, 216},
  [22] = {"All for my daughters...", "Dark-Ikani", 1773, 0, 216},
  [23] = {"Everyone shall feel the pain that i felt that day...", "Dark-Ikani", 1773, 0, 216},
  [24] = {"You can run, but you can not hide.", "Dark-Ikani", 1773, 0, 216},
  [25] = {"Tonight, every last of you shall see how it feels to see your loved ones being murdered.", "Dark-Ikani", 1773, 0, 216},
  [26] = {"The dark mist flows through me. My heart has stopped beating, and my flesh is rotting.", "Dark-Ikani", 1773, 0, 216},
  [27] = {"Come before me, and accept your fate.", "Dark-Ikani", 1773, 0, 216},
  [28] = {"Tribes started repopulating this world, centuries after the tragedy. I sense four allied tribes live in harmony, but they are not too welcoming, and i'm afraid we've been spotted...", "Ikani", 6881, 1, 219},
  [29] = {"The gods guide me... I can sense the location to most of the witch's daughters... <br> It could be a good idea to fortify out defenses, and later use my spells and troops to breach into the enemy's settlements, to steal the jewels. Ghost armies could also be excellent distractions, or even used for scouting.", "Ikani", 6881, 1, 219}
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
	if turn() % (16-difficulty()) == 0 then
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
		if IS_SHAMAN_IN_AREA(0,4,3) == 0 and (getShaman(0).Flags2 & TF2_THING_IS_A_GHOST_PERSON == 0) then
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
		if IS_SHAMAN_IN_AREA(0,4,2) == 1 and (getShaman(0).Flags2 & TF2_THING_IS_A_GHOST_PERSON == 0) then
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
					placedJewels = placedJewels + 1
					queue_sound_event(nil, SND_EVENT_ROCK_SINK, SEF_FIXED_VARS)
				end
			return true end)
		end
	end
end

function InvokeGargoyle()
	if devil == 0 and IS_PLAYER_IN_WORLD_VIEW() == false then
		if jewels == 8 and IS_SHAMAN_IN_AREA(0,4,3) == 1 and (getShaman(0).Flags2 & TF2_THING_IS_A_GHOST_PERSON == 0) then
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



function OnTurn()
	if game_loaded then
		game_loaded = false
		--if turn() > 54 and turn() < 1230 then Engine:hidePanel() end
		--if cinemaEnd > turn() and cinemaEnd ~= 0 then Engine:hidePanel() end
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
		--kill honor loads
		if (difficulty() == 3) and turn() > honorSaveTurnLimit and honorSaveTurnLimit ~= -1 then
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
		Engine:hidePanel()
		Engine:addCommand_CinemaRaise(0);
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
	elseif turn() == 22000 - difficulty()*2000 then
		--cast 1 aod mid game
		if getShaman(4) ~= nil and IS_SHAMAN_AVAILABLE_FOR_ATTACK(4) > 0 then
			GIVE_ONE_SHOT(M_SPELL_ANGEL_OF_DEATH,4) SPELL_ATTACK(4,M_SPELL_ANGEL_OF_DEATH,99,99) 
		elseif getShaman(5) ~= nil and IS_SHAMAN_AVAILABLE_FOR_ATTACK(5) > 0 then
			GIVE_ONE_SHOT(M_SPELL_ANGEL_OF_DEATH,5) SPELL_ATTACK(4,M_SPELL_ANGEL_OF_DEATH,98,98) 
		elseif getShaman(6) ~= nil and IS_SHAMAN_AVAILABLE_FOR_ATTACK(6) > 0 then
			GIVE_ONE_SHOT(M_SPELL_ANGEL_OF_DEATH,6) SPELL_ATTACK(4,M_SPELL_ANGEL_OF_DEATH,97,97) 
		elseif getShaman(7) ~= nil and IS_SHAMAN_AVAILABLE_FOR_ATTACK(7) > 0 then
			GIVE_ONE_SHOT(M_SPELL_ANGEL_OF_DEATH,7) SPELL_ATTACK(4,M_SPELL_ANGEL_OF_DEATH,96,96) 
		end
	elseif turn() == 500 then
		--add wilds near CoR depending on diff
		local wildTbl = {171,172,173,174}
		local enemyWildTbl = {175,176,177,178,179,180,181,182,183,184,185,186}
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
		--add some braves and troops if easier diffs
		if difficulty() == 0 then
			for i = 1,6 do createThing(T_PERSON,M_PERSON_BRAVE,0,marker_to_coord3d(0),false,false) end
			for i = 1,6 do createThing(T_PERSON,M_PERSON_WARRIOR,0,marker_to_coord3d(math.random(39,42)),false,false) end
			for i = 1,6 do createThing(T_PERSON,M_PERSON_SUPER_WARRIOR,0,marker_to_coord3d(math.random(39,42)),false,false) end
			for i = 1,6 do createThing(T_PERSON,M_PERSON_RELIGIOUS,0,marker_to_coord3d(math.random(39,42)),false,false) end
		elseif difficulty() == 1 then
			for i = 1,5 do createThing(T_PERSON,M_PERSON_BRAVE,0,marker_to_coord3d(0),false,false) end
			for i = 1,5 do createThing(T_PERSON,M_PERSON_WARRIOR,0,marker_to_coord3d(math.random(39,42)),false,false) end
			for i = 1,5 do createThing(T_PERSON,M_PERSON_SUPER_WARRIOR,0,marker_to_coord3d(math.random(39,42)),false,false) end
			for i = 1,5 do createThing(T_PERSON,M_PERSON_RELIGIOUS,0,marker_to_coord3d(math.random(39,42)),false,false) end
		elseif difficulty() == 2 then
			for i = 1,4 do createThing(T_PERSON,M_PERSON_BRAVE,0,marker_to_coord3d(0),false,false) end
			for i = 1,4 do createThing(T_PERSON,M_PERSON_WARRIOR,0,marker_to_coord3d(math.random(39,42)),false,false) end
			for i = 1,4 do createThing(T_PERSON,M_PERSON_SUPER_WARRIOR,0,marker_to_coord3d(math.random(39,42)),false,false) end
			for i = 1,4 do createThing(T_PERSON,M_PERSON_RELIGIOUS,0,marker_to_coord3d(math.random(39,42)),false,false) end
		else
			for i = 1,3 do createThing(T_PERSON,M_PERSON_BRAVE,0,marker_to_coord3d(0),false,false) end
			for i = 1,3 do createThing(T_PERSON,M_PERSON_WARRIOR,0,marker_to_coord3d(math.random(39,42)),false,false) end
			for i = 1,3 do createThing(T_PERSON,M_PERSON_SUPER_WARRIOR,0,marker_to_coord3d(math.random(39,42)),false,false) end
			for i = 1,3 do createThing(T_PERSON,M_PERSON_RELIGIOUS,0,marker_to_coord3d(math.random(39,42)),false,false) end	
		end
		--add some pop and fog reveals if lower diffs
		local d = difficulty()
		if d == 0 then
			for i = 187,195 do
				createThing(T_EFFECT,M_EFFECT_REVEAL_FOG_AREA,8,marker_to_coord3d(i),false,false)
			end
		elseif d == 1 then
			for i = 187,190 do
				createThing(T_EFFECT,M_EFFECT_REVEAL_FOG_AREA,8,marker_to_coord3d(i),false,false)
			end
		end
	else
		Engine.DialogObj:processQueue();
		Engine:processCmd();
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
			Engine:addCommand_QueueMsg(dialog_msgs[7][1], dialog_msgs[7][2], 36, false, dialog_msgs[7][3], dialog_msgs[7][4], dialog_msgs[7][5], 12*30)
			Engine:addCommand_QueueMsg(dialog_msgs[21][1], dialog_msgs[21][2], 36, false, dialog_msgs[21][3], dialog_msgs[21][4], dialog_msgs[21][5], 12*36)
			Engine:addCommand_QueueMsg(dialog_msgs[22][1], dialog_msgs[22][2], 36, false, dialog_msgs[22][3], dialog_msgs[22][4], dialog_msgs[22][5], 12*32)
			Engine:addCommand_QueueMsg(dialog_msgs[23][1], dialog_msgs[23][2], 36, false, dialog_msgs[23][3], dialog_msgs[23][4], dialog_msgs[23][5], 12*28)
			Engine:addCommand_QueueMsg(dialog_msgs[24][1], dialog_msgs[24][2], 36, false, dialog_msgs[24][3], dialog_msgs[24][4], dialog_msgs[24][5], 12*42)
			Engine:addCommand_QueueMsg(dialog_msgs[25][1], dialog_msgs[25][2], 36, false, dialog_msgs[25][3], dialog_msgs[25][4], dialog_msgs[25][5], 12*60)
			Engine:addCommand_QueueMsg(dialog_msgs[26][1], dialog_msgs[26][2], 36, false, dialog_msgs[26][3], dialog_msgs[26][4], dialog_msgs[26][5], 12*70)
			Engine:addCommand_QueueMsg(dialog_msgs[27][1], dialog_msgs[27][2], 36, false, dialog_msgs[27][3], dialog_msgs[27][4], dialog_msgs[27][5], 12*80)
		end
		if flashes - turn() == -2300 and GetPop(4) > 0 and getShaman(4) ~= nil then
			createThing(T_SPELL,M_SPELL_ANGEL_OF_DEATH,4,getShaman(4).Pos.D3,false,false)
		end
		if flashes - turn() == -2700 and GetPop(6) > 0 and getShaman(6) ~= nil then
			createThing(T_SPELL,M_SPELL_ANGEL_OF_DEATH,6,getShaman(6).Pos.D3,false,false)
		end
		if flashes - turn() == -2720 and GetPop(6) > 0 and getShaman(6) ~= nil then
			createThing(T_SPELL,M_SPELL_ANGEL_OF_DEATH,6,getShaman(6).Pos.D3,false,false)
		end
		if flashes - turn() == -3400 and GetPop(5) > 0 and getShaman(5) ~= nil then
			createThing(T_SPELL,M_SPELL_ANGEL_OF_DEATH,5,getShaman(5).Pos.D3,false,false)
		end
		if flashes - turn() == -3420 and GetPop(5) > 0 and getShaman(5) ~= nil then
			createThing(T_SPELL,M_SPELL_ANGEL_OF_DEATH,5,getShaman(5).Pos.D3,false,false)
		end
		if flashes - turn() == -3500 and GetPop(5) > 0 and getShaman(5) ~= nil then
			createThing(T_SPELL,M_SPELL_ANGEL_OF_DEATH,5,getShaman(5).Pos.D3,false,false)
		end
		if flashes - turn() == -3540 and GetPop(5) > 0 and getShaman(5) ~= nil then
			createThing(T_SPELL,M_SPELL_ANGEL_OF_DEATH,5,getShaman(5).Pos.D3,false,false)
		end
		if flashes - turn() == -4000 and GetPop(7) > 0 and getShaman(7) ~= nil then
			createThing(T_SPELL,M_SPELL_ANGEL_OF_DEATH,7,getShaman(7).Pos.D3,false,false)
		end
		if flashes - turn() == -4200 and GetPop(4) > 0 and getShaman(4) ~= nil then
			createThing(T_SPELL,M_SPELL_ANGEL_OF_DEATH,4,getShaman(4).Pos.D3,false,false)
		end
		if flashes - turn() == -4700 and GetPop(6) > 0 and getShaman(6) ~= nil then
			createThing(T_SPELL,M_SPELL_ANGEL_OF_DEATH,6,getShaman(6).Pos.D3,false,false)
		end
		if everySeconds(math.random(28,32)) and flashes - turn() < -2000 then
			local x = math.random(4,7)
			if GetPop(x) > 0 and getShaman(x) ~= nil then
				createThing(T_SPELL,M_SPELL_ANGEL_OF_DEATH,x,getShaman(x).Pos.D3,false,false)
			end
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
		if IS_SHAMAN_IN_AREA(0,4,2) == 1 and GetPop(0) == 1 and (getShaman(0).Flags2 & TF2_THING_IS_A_GHOST_PERSON == 0) then
			if _gsi.Players[0].NumBuildingsOfType[M_BUILDING_TEPEE]+_gsi.Players[0].NumBuildingsOfType[M_BUILDING_TEPEE_2]+_gsi.Players[0].NumBuildingsOfType[M_BUILDING_TEPEE_3] == 0 then
				flashes = turn() + 60
				jewels = -3
			end
		end
	end
	MoveJewels() ; PlaceJewels() ; InvokeGargoyle() ; CrazyJewels()
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
	
	--"we've been spotted..."
	if turn() == 2700 then
		Engine:addCommand_QueueMsg(dialog_msgs[28][1], dialog_msgs[28][2], 36, false, dialog_msgs[28][3], dialog_msgs[28][4], dialog_msgs[28][5], 12*3)
	elseif turn() == 2200 then
		--"fortify..."
		Engine:addCommand_QueueMsg(dialog_msgs[29][1], dialog_msgs[29][2], 36, false, dialog_msgs[29][3], dialog_msgs[29][4], dialog_msgs[29][5], 12*3)
	end
	
	if every2Pow(3) then
		--kill ghost shamans
		ProcessGlobalSpecialList(TRIBE_BLUE, PEOPLELIST, function(t)
			if t.Model == M_PERSON_MEDICINE_MAN and (t.Flags2 & TF2_THING_IS_A_GHOST_PERSON > 0) then
				damage_person(t, 8, 20000, TRUE) LOG("killed")
			end
		return true end)
		--give invi for experienced if 1 jewel left
		if difficulty() == 1 and placedJewels >= 7 then
			set_player_can_cast(M_SPELL_INVISIBILITY, 0)
		end
		if teach == 0 and jewels == 0 then
			if (IS_SHAMAN_IN_AREA(0,21,3) == 1) or (IS_SHAMAN_IN_AREA(0,26,3) == 1) or (IS_SHAMAN_IN_AREA(0,22,3) == 1) or (IS_SHAMAN_IN_AREA(0,23,3) == 1)
			or (IS_SHAMAN_IN_AREA(0,24,3) == 1) or (IS_SHAMAN_IN_AREA(0,25,3) == 1) or (IS_SHAMAN_IN_AREA(0,27,3) == 1) or (IS_SHAMAN_IN_AREA(0,hiddenJ,3) == 1)
			and (getShaman(0).Flags2 & TF2_THING_IS_A_GHOST_PERSON == 0) then
				Engine:addCommand_QueueMsg(dialog_msgs[18][1], dialog_msgs[18][2], 36, false, dialog_msgs[18][3], dialog_msgs[18][4], dialog_msgs[18][5], 12*10)
				teach = 1
			end
		elseif teach == 1 and jewels == 1 then
			Engine:addCommand_QueueMsg(dialog_msgs[19][1], dialog_msgs[19][2], 36, false, dialog_msgs[19][3], dialog_msgs[19][4], dialog_msgs[19][5], 12*10)
			teach = 2
		elseif teach == 2 and placedJewels == 1 then
			Engine:addCommand_QueueMsg(dialog_msgs[20][1], dialog_msgs[20][2], 36, false, dialog_msgs[20][3], dialog_msgs[20][4], dialog_msgs[20][5], 12*10)
			teach = 3
		end
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
	
	if every(1800-(difficulty()*100)-(gameStage*100)) then
		if turn() > 3000 then
			for k,v in ipairs(AItribes) do
				MARKER_ENTRIES(v,5,-1,-1,-1)--atk patrols
			end
		end
	end
	
	if everySeconds(32-(difficulty()*3)) then
		--patrolling marker entries and preach at marker
		for idx,v in ipairs(AItribes) do
			MARKER_ENTRIES(v,0,math.random(1,2),-1,-1)--wars
			MARKER_ENTRIES(v,math.random(3,4),-1,-1,-1)--fws
			if _gsi.Players[v].NumPeopleOfType[M_PERSON_RELIGIOUS] > 4 then
				if rnd() > 40 then
					for i = 0,3 do PREACH_AT_MARKER(v,(155+(4*(v-4))+i)) end
					if difficulty() > 1 then PREACH_AT_MARKER(v,math.random(141,154)) PREACH_AT_MARKER(v,math.random(141,154)) end
					if difficulty() == 3 and rnd() > 50 then
						PREACH_AT_MARKER(v,math.random(141,154))
						if rnd() > 50 and gameStage > 2 then
							PREACH_AT_MARKER(v,math.random(141,154))
						end
					end
				end
			end
		end
	end
	
	--occasionally shield troops when attacking
	if everySeconds(36 - difficulty()*5) then
		for i = 4,7 do
			local r = 0
			if getShaman(i) ~= nil and IS_SHAMAN_IN_AREA(i,49,18) == 1 then
				if gameStage >= 1 and difficulty() > 0 then
					SearchMapCells(SQUARE, 0, 0 , 6, world_coord3d_to_map_idx(getShaman(i).Pos.D3), function(me)
						me.MapWhoList:processList(function (t)
							if t.Type == T_PERSON and t.Owner == i and t.Model > 2 and t.Model < 7 then
								if ((t.Flags3 & TF3_SHIELD_ACTIVE) == 0 and (t.Flags2 & TF2_THING_IS_A_GHOST_PERSON == 0)) and r == 0 then
									createThing(T_SPELL,M_SPELL_SHIELD,i,t.Pos.D3,false,false)
									GIVE_MANA_TO_PLAYER(i,-30000)
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
	end
	
	if everySeconds(48-(difficulty()*2)) then
		--go expand wish shaman (lb)
		if rnd() > 60 then
			local tbl = {72,74,76}
			local mk = tbl[math.random(#tbl)] ; LBexpand(4,mk,mk+1,2,3)
		elseif rnd() > 60 then
			local tbl = {78,80,82}
			local mk = tbl[math.random(#tbl)] ; LBexpand(5,mk,mk+1,2,3)
		elseif rnd() > 60 then
			local tbl = {84,86,88}
			local mk = tbl[math.random(#tbl)] ; LBexpand(6,mk,mk+1,2,3)
		elseif rnd() > 60 then
			local tbl = {90,92,94}
			local mk = tbl[math.random(#tbl)] ; LBexpand(7,mk,mk+1,2,3)
		end
	end
	
	if everySeconds(20) then
		--send main attacks
		if tribe1Atk1 < turn() then SendAttack(tribe1) end
		if tribe2Atk1 < turn() then SendAttack(tribe2) end
		if tribe3Atk1 < turn() then SendAttack(tribe3) end
		if tribe4Atk1 < turn() then SendAttack(tribe4) end
		--send mini attacks
		if tribe1MiniAtk1 < turn() then SendMiniAttack(tribe1) end
		if tribe2MiniAtk1 < turn() then SendMiniAttack(tribe2) end
		if tribe3MiniAtk1 < turn() then SendMiniAttack(tribe3) end
		if tribe4MiniAtk1 < turn() then SendMiniAttack(tribe4) end
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
			if (b.Model <= 3) and b.Owner ~= 0 then
				if (b.u.Bldg.UpgradeCount < 1850) then
					b.u.Bldg.UpgradeCount = b.u.Bldg.UpgradeCount + (difficulty()*6)
				end
				if (b.u.Bldg.SproggingCount < 1000) then
					b.u.Bldg.SproggingCount = b.u.Bldg.SproggingCount + (difficulty()*6)
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
			if tribe2NavStress > (7-difficulty()) then
				if getShaman(tribe2) ~= nil and IS_SHAMAN_AVAILABLE_FOR_ATTACK(tribe2) > 0 then
					GIVE_ONE_SHOT(M_SPELL_ANGEL_OF_DEATH,tribe2) ; SPELL_ATTACK(tribe2,M_SPELL_ANGEL_OF_DEATH,98,98) ; tribe2NavStress = 0
				end
			end
			if tribe3NavStress > (7-difficulty()) then
				if getShaman(tribe3) ~= nil and IS_SHAMAN_AVAILABLE_FOR_ATTACK(tribe3) > 0 then
					GIVE_ONE_SHOT(M_SPELL_ANGEL_OF_DEATH,tribe3) ; SPELL_ATTACK(tribe3,M_SPELL_ANGEL_OF_DEATH,97,97) ; tribe3NavStress = 0
				end
			end
			if tribe4NavStress > (7-difficulty()) then
				if getShaman(tribe4) ~= nil and IS_SHAMAN_AVAILABLE_FOR_ATTACK(tribe4) > 0 then
					GIVE_ONE_SHOT(M_SPELL_ANGEL_OF_DEATH,tribe4) ; SPELL_ATTACK(tribe4,M_SPELL_ANGEL_OF_DEATH,96,96) ; tribe4NavStress = 0
				end
			end
		end
	end
	
	-- new towers every x mins
	if everySeconds(220-(difficulty()*28)) and gameStage >= 1 then
		if _gsi.Players[tribe1].NumBuildingsOfType[M_BUILDING_DRUM_TOWER] < (6+(difficulty()*2)) then
			local rndTowMk = math.random(54,58)
			local coord = MapPosXZ.new() ; coord.Pos = world_coord3d_to_map_idx(marker_to_coord3d(rndTowMk))
			BUILD_DRUM_TOWER(tribe1,coord.XZ.X, coord.XZ.Z)
		end
		if _gsi.Players[tribe2].NumBuildingsOfType[M_BUILDING_DRUM_TOWER] < (6+(difficulty()*2)) then
			local rndTowMk = math.random(59,63)
			local coord = MapPosXZ.new() ; coord.Pos = world_coord3d_to_map_idx(marker_to_coord3d(rndTowMk))
			BUILD_DRUM_TOWER(tribe2,coord.XZ.X, coord.XZ.Z)
		end
		if _gsi.Players[tribe3].NumBuildingsOfType[M_BUILDING_DRUM_TOWER] < (6+(difficulty()*2)) then
			local rndTowMk = math.random(64,67)
			local coord = MapPosXZ.new() ; coord.Pos = world_coord3d_to_map_idx(marker_to_coord3d(rndTowMk))
			BUILD_DRUM_TOWER(tribe3,coord.XZ.X, coord.XZ.Z)
		end
		if _gsi.Players[tribe4].NumBuildingsOfType[M_BUILDING_DRUM_TOWER] < (6+(difficulty()*2)) then
			local rndTowMk = math.random(68,71)
			local coord = MapPosXZ.new() ; coord.Pos = world_coord3d_to_map_idx(marker_to_coord3d(rndTowMk))
			BUILD_DRUM_TOWER(tribe4,coord.XZ.X, coord.XZ.Z)
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
				GIVE_ONE_SHOT(M_SPELL_HYPNOTISM,v)
			elseif gameStage == 2 then
				GIVE_ONE_SHOT(M_SPELL_SWAMP,v)
			else
				GIVE_ONE_SHOT(M_SPELL_FIRESTORM,v)
			end
		end
	end
	
	if everySeconds(90-(difficulty()*5)) and turn() > 2700 then
		--some preach at attacks
		if rnd() > 30 then
			PREACH_AT_MARKER(tribe1,50) 
		end
		if rnd() > 30 then
			PREACH_AT_MARKER(tribe2,51)
		end
		if rnd() > 30 then
			PREACH_AT_MARKER(tribe3,52)
		end
		if rnd() > 30 then
			PREACH_AT_MARKER(tribe4,53)
		end
	end
	
	if every2Pow(6) then
		--update game stage (early,mid,late,very late)
		if minutes() < 6 then
			gameStage = 0
		elseif minutes() >= 6 and minutes() < 12 then
			gameStage = 1
		elseif minutes() >= 12 and minutes() < 18 then
			gameStage = 2
		else
			gameStage = 3
		end
		--update AI ATTRS
		SET_MARKER_ENTRY(tribe1,0,100,101,0,2+difficulty(),2+difficulty(),1) --br,war,fw,pre
		SET_MARKER_ENTRY(tribe1,1,102,103,0,2,0,0)
		SET_MARKER_ENTRY(tribe1,2,104,104,0,0,2,0)
		SET_MARKER_ENTRY(tribe1,3,105,105,0,0,2,0)
		SET_MARKER_ENTRY(tribe1,4,106,106,0,0,2,0)
		SET_MARKER_ENTRY(tribe1,5,107,108,0,gameStage+difficulty(),gameStage+difficulty(),2) --atk
		
		SET_MARKER_ENTRY(tribe2,0,109,110,0,2+difficulty(),2+difficulty(),1) --br,war,fw,pre
		SET_MARKER_ENTRY(tribe2,1,111,112,0,2,0,0)
		SET_MARKER_ENTRY(tribe2,2,113,113,0,0,2,0)
		SET_MARKER_ENTRY(tribe2,3,114,114,0,0,2,0)
		SET_MARKER_ENTRY(tribe2,4,115,115,0,0,2,0)
		SET_MARKER_ENTRY(tribe2,5,116,117,0,gameStage+difficulty(),gameStage+difficulty(),2) --atk

		SET_MARKER_ENTRY(tribe3,0,120,121,0,2+difficulty(),2+difficulty(),1) --br,war,fw,pre
		SET_MARKER_ENTRY(tribe3,1,118,119,0,2,0,0)
		SET_MARKER_ENTRY(tribe3,2,122,122,0,0,2,0)
		SET_MARKER_ENTRY(tribe3,3,123,123,0,0,2,0)
		SET_MARKER_ENTRY(tribe3,4,124,124,0,0,2,0)
		SET_MARKER_ENTRY(tribe3,5,125,126,0,gameStage+difficulty(),gameStage+difficulty(),2) --atk
		
		SET_MARKER_ENTRY(tribe4,0,127,128,0,2+difficulty(),2+difficulty(),1) --br,war,fw,pre
		SET_MARKER_ENTRY(tribe4,1,129,130,0,2,0,0)
		SET_MARKER_ENTRY(tribe4,2,131,131,0,0,2,0)
		SET_MARKER_ENTRY(tribe4,3,132,132,0,0,2,0)
		SET_MARKER_ENTRY(tribe4,4,133,133,0,0,2,0)
		SET_MARKER_ENTRY(tribe4,5,134,135,0,gameStage+difficulty(),gameStage+difficulty(),2) --atk

		for i,v in ipairs(AItribes) do
			if turn() > 1000 then WRITE_CP_ATTRIB(v, ATTR_EXPANSION, math.random(16,24)) end
			WRITE_CP_ATTRIB(v, ATTR_HOUSE_PERCENTAGE, 90+G_RANDOM(1+5*difficulty())+(difficulty()*10)+(gameStage*(10+difficulty()))) --base size
			WriteAiTrainTroops(v,10+(difficulty()*2)+(gameStage*1),10+(difficulty()*2)+(gameStage*1),10+(difficulty()*2)+(gameStage*1),0) --(pn,w,r,fw,spy)
			WRITE_CP_ATTRIB(v, ATTR_ATTACK_PERCENTAGE, 70+(minutes()*2)) --attack stuff
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
			local baseMK = -1
			if v == 4 then baseMK = 106 elseif v == 5 then baseMK = 97 elseif v == 6 then baseMK = 136 else baseMK = 96 end
			--spell entries base and outside
			if IS_SHAMAN_IN_AREA(v,baseMK,18) == 1 then
				--spells in base defense
				SET_SPELL_ENTRY(v, 0, M_SPELL_BLAST, SPELL_COST(M_SPELL_BLAST) >> (1+difficulty()), 128, 1, 1)
				SET_SPELL_ENTRY(v, 1, M_SPELL_LIGHTNING_BOLT, SPELL_COST(M_SPELL_LIGHTNING_BOLT) >> (1+difficulty()), 128, 1, 1)
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
				SET_SPELL_ENTRY(v, 0, M_SPELL_BLAST, SPELL_COST(M_SPELL_BLAST) >> (1+difficulty()), 128, 1, 0)
				SET_SPELL_ENTRY(v, 1, M_SPELL_LIGHTNING_BOLT, SPELL_COST(M_SPELL_LIGHTNING_BOLT) >> (1+difficulty()), 128, 1, 0)
				SET_SPELL_ENTRY(v, 2, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> (1+difficulty()), 128, 5-difficulty(), 0)
				SET_SPELL_ENTRY(v, 3, M_SPELL_SWAMP, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> (1+difficulty()), 128, 12-difficulty(), 0)
				if gameStage > 1 then
					SET_SPELL_ENTRY(v, 4, M_SPELL_HYPNOTISM, SPELL_COST(M_SPELL_HYPNOTISM) >> (1+difficulty()), 128, 12-(difficulty()*2), 0)
					if gameStage == 3 then
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
			if _gsi.Players[v].NumPeople < 3 then GIVE_UP_AND_SULK(v,TRUE) end
			--add lategame spells to atkspells
			if gameStage == 2 then
				if #tribe1AtkSpells == 4 then
					table.insert(tribe1AtkSpells,M_SPELL_WHIRLWIND)
					if #tribe1AtkSpells == 6 and difficulty() >= 3 then
						table.insert(tribe1AtkSpells,M_SPELL_FIRESTORM)
					end
				end
				if #tribe2AtkSpells == 4 then
					table.insert(tribe2AtkSpells,M_SPELL_WHIRLWIND)
					if #tribe2AtkSpells == 6 and difficulty() >= 3 then
						table.insert(tribe2AtkSpells,M_SPELL_FIRESTORM)
					end
				end
				if #tribe3AtkSpells == 4 then
					table.insert(tribe3AtkSpells,M_SPELL_WHIRLWIND)
					if #tribe3AtkSpells == 6 and difficulty() >= 3 then
						table.insert(tribe3AtkSpells,M_SPELL_FIRESTORM)
					end
				end
				if #tribe4AtkSpells == 4 then
					table.insert(tribe4AtkSpells,M_SPELL_WHIRLWIND)
					if #tribe4AtkSpells == 6 and difficulty() >= 3 then
						table.insert(tribe4AtkSpells,M_SPELL_FIRESTORM)
					end
				end
			elseif gameStage == 3 then
				if #tribe1AtkSpells == 5 then
					table.insert(tribe1AtkSpells,M_SPELL_ANGEL_OF_DEATH)
					if #tribe1AtkSpells == 6 and difficulty() >= 3 then
						table.insert(tribe1AtkSpells,M_SPELL_FIRESTORM)
					end
				end
				if #tribe2AtkSpells == 5 then
					table.insert(tribe2AtkSpells,M_SPELL_ANGEL_OF_DEATH)
					if #tribe2AtkSpells == 6 and difficulty() >= 3 then
						table.insert(tribe2AtkSpells,M_SPELL_FIRESTORM)
					end
				end	
				if #tribe3AtkSpells == 5 then
					table.insert(tribe3AtkSpells,M_SPELL_ANGEL_OF_DEATH)
					if #tribe3AtkSpells == 6 and difficulty() >= 3 then
						table.insert(tribe3AtkSpells,M_SPELL_FIRESTORM)
					end
				end	
				if #tribe4AtkSpells == 5 then
					table.insert(tribe4AtkSpells,M_SPELL_ANGEL_OF_DEATH)
					if #tribe4AtkSpells == 6 and difficulty() >= 3 then
						table.insert(tribe4AtkSpells,M_SPELL_FIRESTORM)
					end
				end
			end
		end
	end

	if devil == 1 then
		DevilMode()
	end
	
end

--go LB expand
function LBexpand(tribe,mk1,mk2,stage,limit)
	--use 0 in stage and/or limit to ignore them (stage = only cast if game stage if equal or higher ; limit = only cast if hasnt expanded the limit ammount of times)
	if getShaman(tribe) ~= nil and gameStage >= stage and IS_SHAMAN_AVAILABLE_FOR_ATTACK(tribe) == 1 then
		if GET_SPELLS_CAST(tribe,M_SPELL_LAND_BRIDGE) < limit then
			GIVE_ONE_SHOT(M_SPELL_LAND_BRIDGE,tribe)
			if (NAV_CHECK(tribe,0,ATTACK_MARKER,mk1,0) > 0) then
				WRITE_CP_ATTRIB(tribe, ATTR_GROUP_OPTION, 2)
				WriteAiAttackers(tribe,0,0,0,0,0,100) --(pn,b,w,r,fw,spy,sh)
				ATTACK(tribe, TRIBE_BLUE, 1, ATTACK_PERSON, 0, 1, M_SPELL_LAND_BRIDGE, 0, 0, ATTACK_NORMAL, 0, mk1, mk2, 0)
			end
		end
	end
end

function IncrementAtkVar(pn,amt,mainAttack)
	if mainAttack == true then
		if pn == tribe1 then
			tribe1Atk1 = amt 
		elseif pn == tribe2 then
			tribe2Atk1 = amt
		elseif pn == tribe3 then
			tribe3Atk1 = amt 
		elseif pn == tribe4 then
			tribe4Atk1 = amt 
		end
	else --mini attacks
		if pn == tribe1 then
			tribe1MiniAtk1 = amt 
		elseif pn == tribe2 then
			tribe2MiniAtk1 = amt
		elseif pn == tribe3 then
			tribe3MiniAtk1 = amt 
		elseif pn == tribe4 then
			tribe4MiniAtk1 = amt 
		end
	end
end

function SendMiniAttack(attacker)
	if (minutes() > (4-difficulty())) and (rnd() < 50+difficulty()*5 +gameStage*5) then
		WRITE_CP_ATTRIB(attacker, ATTR_DONT_GROUP_AT_DT, 1)
		WRITE_CP_ATTRIB(attacker, ATTR_GROUP_OPTION, 3)
		WRITE_CP_ATTRIB(attacker, ATTR_FIGHT_STOP_DISTANCE, 28 + G_RANDOM(16))
		WRITE_CP_ATTRIB(attacker, ATTR_BASE_UNDER_ATTACK_RETREAT, 0)
		WriteAiAttackers(attacker,0,math.random(30,40)+(difficulty()*5)+(gameStage*5),math.random(25,35)+(difficulty()*4)+(gameStage*4),math.random(20,30),0,0) --(pn,b,w,r,fw,spy,sh)
		local target = 0
		local numTroops = 0
		local mk1,mk2 = -1,-1
		--check if enough pop and troops to attack
		if _gsi.Players[attacker].NumPeople > 16 and GetTroops(attacker) > 8 then
			numTroops = 2 + gameStage
		end
		--LAUNCH MINI ATK
		if numTroops > 0 then
			if _gsi.Players[target].NumBuildings > 0 then
				if (NAV_CHECK(attacker,target,ATTACK_BUILDING,0,0) > 0) then
					ATTACK(attacker, target, numTroops, ATTACK_BUILDING, 0, 869+(difficulty()*10), 0, 0, 0, ATTACK_NORMAL, 0, mk1, mk2, -1)
					IncrementAtkVar(attacker,turn() + 2200 + G_RANDOM(1800) - (difficulty()*256) - (gameStage*128),false)
					--TrainUnitsNow(attacker) --log_msg(attacker,"mini atk vs: " .. target .. "   bldg")
				elseif _gsi.Players[target].NumPeople > 0 then
					if (NAV_CHECK(attacker,target,ATTACK_PERSON,0,0) > 0) then
						ATTACK(attacker, target, numTroops, ATTACK_PERSON, 0, 869+(difficulty()*10), 0, 0, 0, ATTACK_NORMAL, 0, mk1, mk2, -1)
						IncrementAtkVar(attacker,turn() + 2200 + G_RANDOM(1800) - (difficulty()*256) - (gameStage*128),false)
						--TrainUnitsNow(attacker) --log_msg(attacker,"mini atk vs: " .. target .. "   person")
					end
				else
					IncrementAtkVar(attacker,turn() + 555, false)
				end
			else
				if (NAV_CHECK(attacker,target,ATTACK_PERSON,0,0) > 0) then
					ATTACK(attacker, target, numTroops, ATTACK_PERSON, 0, 869+(difficulty()*10), 0, 0, 0, ATTACK_NORMAL, 0, mk1, mk2, -1)
					IncrementAtkVar(attacker,turn() + 2200 + G_RANDOM(1800) - (difficulty()*256) - (gameStage*128),false)
					--TrainUnitsNow(attacker) --log_msg(attacker,"mini atk vs: " .. target .. "   person")
				else
					IncrementAtkVar(attacker,turn() + 555, false)
				end
			end
		else
			IncrementAtkVar(attacker,turn() + 555, false)
		end
	else
		IncrementAtkVar(attacker,turn()+555, false)
	end
end

function SendAttack(attacker)
	if (minutes() > 6-difficulty()) and (rnd() < 65+difficulty()*5 +gameStage*5) then
		WRITE_CP_ATTRIB(attacker, ATTR_FIGHT_STOP_DISTANCE, 28 + G_RANDOM(16))
		WriteAiAttackers(attacker,G_RANDOM(5),15+G_RANDOM(10)+(difficulty()*6)+(gameStage*4),15+G_RANDOM(5)+(difficulty()*6)+(gameStage*4),15+G_RANDOM(7)+(difficulty()*6)+(gameStage*4),0,100) --(pn,b,w,r,fw,spy,sh)
		local target = 0
		local numTroops = 0
		local boats = _gsi.Players[attacker].NumVehiclesOfType[M_VEHICLE_BOAT_1]
		local spell1,spell2,spell3 = 0,0,0
		local mk1,mk2 = -1,-1
		local stress = 0
		--check if enough pop and troops to attack
		local troopAmmount = (_gsi.Players[attacker].NumPeople-_gsi.Players[attacker].NumPeopleOfType[M_PERSON_BRAVE])
		if _gsi.Players[attacker].NumPeople > 20 and troopAmmount > 10 then
			numTroops = 3 + (difficulty()) + gameStage if difficulty() >= 2 then numTroops = numTroops + math.floor(troopAmmount/7) end
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
			WRITE_CP_ATTRIB(attacker, ATTR_RETREAT_VALUE, math.random(2,6))
		else
			WRITE_CP_ATTRIB(attacker, ATTR_BASE_UNDER_ATTACK_RETREAT, 0)
			WRITE_CP_ATTRIB(attacker, ATTR_RETREAT_VALUE, 0)
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
					if attacker == tribe1 then mk2 = 196 elseif attacker == tribe2 then mk2 = 197 elseif attacker == tribe3 then mk2 = 198 else mk2 = 199 end
				end
			end
		else
			WRITE_CP_ATTRIB(attacker, ATTR_AWAY_MEDICINE_MAN, 0);
			mk2 = -1
		end
		if attacker == tribe1 then mk1 = 196 elseif attacker == tribe2 then mk1 = 197 elseif attacker == tribe3 then mk1 = 198 else mk1 = 199 end
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
			else
				if spell1 == 0 then
					spell1 = tribe4AtkSpells[math.random(#tribe4AtkSpells)]
				end
				spell2 = tribe4AtkSpells[math.random(#tribe4AtkSpells)]
				spell3 = tribe4AtkSpells[math.random(#tribe4AtkSpells)]
			end
		end
		--LAUNCH ATTACK
		
		--has enough troops
		if numTroops > 0 then
			--prioritize buildings
			if _gsi.Players[target].NumBuildings > 0 then
				--can target bldg by land
				if (NAV_CHECK(attacker,target,ATTACK_BUILDING,0,0) > 0) then
					ATTACK(attacker, target, numTroops, ATTACK_BUILDING, 0, 869+(difficulty()*10), spell1, spell2, spell3, ATTACK_NORMAL, 1, mk1, mk2, 0)
					IncrementAtkVar(attacker,turn() + 3333 + G_RANDOM(2222) - (difficulty()*300) - (gameStage*200),true) --log_msg(attacker,"mini atk vs: " .. target .. "   bldg")
				else
					--try atk bldg from water
					if boats > 0 then
						WRITE_CP_ATTRIB(attacker, ATTR_FIGHT_STOP_DISTANCE, 4)
						WRITE_CP_ATTRIB(attacker, ATTR_GROUP_OPTION, 0)
						ATTACK(attacker, target, numTroops, ATTACK_BUILDING, 0, 869+(difficulty()*10), spell1, spell2, spell3, ATTACK_BY_BOAT, 1, -1, -1, -1)
						IncrementAtkVar(attacker,turn() + 3333 + G_RANDOM(2222) - (difficulty()*300) - (gameStage*200),true) --log_msg(attacker,"mini atk vs: " .. target .. "   bldg boat")
					else
						--else attack units
						if _gsi.Players[target].NumPeople > 0 then
							if (NAV_CHECK(attacker,target,ATTACK_PERSON,0,0) > 0) then
								ATTACK(attacker, target, numTroops, ATTACK_PERSON, 0, 869+(difficulty()*10), spell1, spell2, spell3, ATTACK_NORMAL, 1, mk1, mk2, 0)
								IncrementAtkVar(attacker,turn() + 3333 + G_RANDOM(2222) - (difficulty()*300) - (gameStage*200),true) --log_msg(attacker,"mini atk vs: " .. target .. "   person")
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
						ATTACK(attacker, target, numTroops, ATTACK_PERSON, 0, 869+(difficulty()*10), spell1, spell2, spell3, ATTACK_NORMAL, 1, mk1, mk2, 0)
						IncrementAtkVar(attacker,turn() + 3333 + G_RANDOM(2222) - (difficulty()*300) - (gameStage*200),true) --log_msg(attacker,"mini atk vs: " .. target .. "   person")
					else
						--try to atk units from water
						if boats > 0 then
							WRITE_CP_ATTRIB(attacker, ATTR_FIGHT_STOP_DISTANCE, 4)
							WRITE_CP_ATTRIB(attacker, ATTR_GROUP_OPTION, 0)
							ATTACK(attacker, target, numTroops, ATTACK_PERSON, 0, 869+(difficulty()*10), spell1, spell2, spell3, ATTACK_BY_BOAT, 1, -1, -1, -1)
							IncrementAtkVar(attacker,turn() + 3333 + G_RANDOM(2222) - (difficulty()*300) - (gameStage*200),true) --log_msg(attacker,"mini atk vs: " .. target .. "   person boat")
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
			else
				tribe4NavStress = tribe4NavStress + 1
			end
		else
			if attacker == tribe1 then
				tribe1NavStress = 0
			elseif attacker == tribe2 then
				tribe2NavStress = 0
			elseif attacker == tribe3 then
				tribe3NavStress = 0
			else
				tribe4NavStress = 0
			end
		end
		--TrainUnitsNow(attacker)
	else
		IncrementAtkVar(attacker,turn()+500, true)
	end
	--log_msg(8,"" .. attacker .. "  " .. target .. "  " .. numTroops .. "  " .. variable .. "  " .. stress)
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
	
	--honor save timer
	if turn() < honorSaveTurnLimit and turn() > 1600 and difficulty() == 3 then
		PopSetFont(3)
		local hstl = "WARNING (honour mode): You can save, to avoid rewatching the intro   "
		LbDraw_Text(math.floor(w-2-(string_width("77:77:77 ")+string_width(tostring(hstl)))),2,tostring(hstl),0)
		LbDraw_Text(math.floor(w-2-(string_width("77:77:77 "))),2,tostring(TurnsToClock(math.floor((honorSaveTurnLimit-turn())/12))),0)
	end
	
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
	for i = #tribe4AtkSpells, 1 do
		save_data:push_int(tribe4AtkSpells[i])
	end
	save_data:push_int(#tribe4AtkSpells)
	
	if turn() < 1600 then
		save_data:push_int(Brave1.ThingNum)
		save_data:push_int(Brave2.ThingNum)
		save_data:push_int(Brave3.ThingNum)
		save_data:push_int(Brave4.ThingNum)
	end
	save_data:push_int(honorSaveTurnLimit)
	save_data:push_int(tribe1Atk1)
	save_data:push_int(tribe1MiniAtk1)
	save_data:push_int(tribe1NavStress)
	save_data:push_int(tribe2Atk1)
	save_data:push_int(tribe2MiniAtk1)
	save_data:push_int(tribe2NavStress)
	save_data:push_int(tribe3Atk1)
	save_data:push_int(tribe3MiniAtk1)
	save_data:push_int(tribe3NavStress)
	save_data:push_int(tribe4Atk1)
	save_data:push_int(tribe4MiniAtk1)
	save_data:push_int(tribe4NavStress)
	save_data:push_int(gameStage)
	save_data:push_int(hiddenJ)
	save_data:push_int(teach)
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
	game_loaded = true
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
	teach = load_data:pop_int()
	hiddenJ = load_data:pop_int()
	gameStage = load_data:pop_int()
	tribe4NavStress = load_data:pop_int()
	tribe4MiniAtk1 = load_data:pop_int()
	tribe4Atk1 = load_data:pop_int()
	tribe3NavStress = load_data:pop_int()
	tribe3MiniAtk1 = load_data:pop_int()
	tribe3Atk1 = load_data:pop_int()
	tribe2NavStress = load_data:pop_int()
	tribe2MiniAtk1 = load_data:pop_int()
	tribe2Atk1 = load_data:pop_int()
	tribe1NavStress = load_data:pop_int()
	tribe1MiniAtk1 = load_data:pop_int()
	tribe1Atk1 = load_data:pop_int()
	honorSaveTurnLimit = load_data:pop_int()
	if turn() < 1600 then
		Brave4 = GetThing(load_data:pop_int())
		Brave3 = GetThing(load_data:pop_int())
		Brave2 = GetThing(load_data:pop_int())
		Brave1 = GetThing(load_data:pop_int())
	end
	
	local numSpellsAtk4 = load_data:pop_int();
	for i = 1, numSpellsAtk4 do
		 tribe4AtkSpells[i] = load_data:pop_int();
	end
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
