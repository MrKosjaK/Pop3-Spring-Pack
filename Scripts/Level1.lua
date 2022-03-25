import(Module_Building);
import(Module_Commands);
import(Module_DataTypes);
import(Module_Defines);
import(Module_Draw);
import(Module_Features);
import(Module_Game);
import(Module_Globals);
import(Module_Helpers);
import(Module_Level);
import(Module_Map);
import(Module_Math);
import(Module_Objects);
import(Module_Person);
import(Module_Players);
import(Module_PopScript);
import(Module_Shapes);
import(Module_Sound);
import(Module_Spells);
import(Module_String);
import(Module_System);
import(Module_Table);

--includes
include("CSequence.lua");

--globals
local gs = gsi();
local gns = gnsi();
local spell_const = spells_type_info();
local bldg_const = building_type_info();
local ency = encyclopedia_info();

--player pointers
local pp = {
  [0] = getPlayer(0),
  [1] = getPlayer(1),
  [2] = getPlayer(2),
  [3] = getPlayer(3),
  [4] = getPlayer(4),
  [5] = getPlayer(5),
  [6] = getPlayer(6),
  [7] = getPlayer(7),
};

--these always have to be set on script load.
spell_const[M_SPELL_GHOST_ARMY].Active = SPAC_NORMAL;
spell_const[M_SPELL_GHOST_ARMY].NetworkOnly = 0;
spell_const[M_SPELL_INVISIBILITY].OneOffMaximum = 4
spell_const[M_SPELL_INVISIBILITY].WorldCoordRange = 4096
spell_const[M_SPELL_INVISIBILITY].CursorSpriteNum = 45
spell_const[M_SPELL_INVISIBILITY].ToolTipStrIdx = 818
spell_const[M_SPELL_INVISIBILITY].AvailableSpriteIdx = 359
spell_const[M_SPELL_INVISIBILITY].NotAvailableSpriteIdx = 377
spell_const[M_SPELL_INVISIBILITY].ClickedSpriteIdx = 395
spell_const[M_SPELL_SWAMP].OneOffMaximum = 3
spell_const[M_SPELL_SWAMP].WorldCoordRange = 4096
spell_const[M_SPELL_SWAMP].CursorSpriteNum = 53
spell_const[M_SPELL_SWAMP].ToolTipStrIdx = 823
spell_const[M_SPELL_SWAMP].AvailableSpriteIdx = 364
spell_const[M_SPELL_SWAMP].NotAvailableSpriteIdx = 382
spell_const[M_SPELL_SWAMP].ClickedSpriteIdx = 400
spell_const[M_SPELL_EROSION].Cost = 250000
spell_const[M_SPELL_EROSION].CursorSpriteNum = 50
spell_const[M_SPELL_EROSION].ToolTipStrIdx = 822
spell_const[M_SPELL_EROSION].AvailableSpriteIdx = 363
spell_const[M_SPELL_EROSION].NotAvailableSpriteIdx = 381
spell_const[M_SPELL_EROSION].ClickedSpriteIdx = 399
spell_const[M_SPELL_VOLCANO].Cost = 800000
spell_const[M_SPELL_VOLCANO].WorldCoordRange = 3072
spell_const[M_SPELL_VOLCANO].CursorSpriteNum = 56
spell_const[M_SPELL_VOLCANO].ToolTipStrIdx = 828
spell_const[M_SPELL_VOLCANO].AvailableSpriteIdx = 369
spell_const[M_SPELL_VOLCANO].NotAvailableSpriteIdx = 387
spell_const[M_SPELL_VOLCANO].ClickedSpriteIdx = 405
bldg_const[M_BUILDING_SPY_TRAIN].ToolTipStrId2 = 641;
ency[22].StrId = 689;
ency[27].StrId = 690;
ency[32].StrId = 691;
ency[35].StrId = 695;
ency[38].StrId = 696;

--disable wins on this level
gns.GameParams.Flags2 = gns.GameParams.Flags2 | GPF2_GAME_NO_WIN;
gns.GameParams.Flags3 = gns.GameParams.Flags3 & ~GPF3_NO_GAME_OVER_PROCESS;

--main engine
local Engine = CSequence:createNew();

--helper functions
local setPSVar = function(pn, idx, val) SET_USER_VARIABLE_VALUE(pn, idx, val); end;
local getPSVar = function(pn, idx) return GET_USER_VARIABLE_VALUE(pn, idx); end;

--variables local
local game_loaded = false;
local game_loaded_honour = false;

--features
enable_feature(F_SUPER_WARRIOR_NO_AMENDMENT); --fix fws not shooting
enable_feature(F_MINIMAP_ENEMIES); --who the hell plays with minimap off?
enable_feature(F_WILD_NO_RESPAWN); --disable wild respawning, oh boy.

--defines
local ai_tribe_1 = TRIBE_YELLOW;
local ai_tribe_2 = TRIBE_BLUE;
local player_tribe = TRIBE_RED;
local player_ally_tribe = TRIBE_CYAN;
local diff_beginner = 0;
local diff_experienced = 1;
local diff_veteran = 2;
local diff_honour = 3;

local dialog_msgs = {
  [0] = {"I'm close to my destination, Tiyao should be awaiting me.", "Dakini", 6903, 1, 245},
  [1] = {"Ah, there you are, Dakini.", "Tiyao", 6883, 2, 146},
  [2] = {"Anyway, we're running out of time, all of chit-chat talking later. Ikani and Chumara have settled near us and are preparing forces to get access to the portal, which is direct connection to my tribe.", "Tiyao", 6883, 2, 146},
  [3] = {"Cannot You close the portal?", "Dakini", 6903, 1, 245},
  [4] = {"I'm afraid, this is not possible, I'm not enough knowledgable to do that.", "Tiyao", 6883, 2, 146},
  [5] = {"Or at least for now... <bp> There's possibility that Chumara or Ikani have some secrets, doubt they would share it.", "Tiyao", 6883, 2, 146},
  [6] = {"Well, let's not think about it, leave protection of portal and defeating foes to me.", "Dakini", 6903, 1, 245},
  [7] = {"Then may gods help in your quest. <br> It's time for me to leave, my tribe is in danger and I must protect it.", "Tiyao", 6883, 2, 146},
  [8] = {"Forgive me for not staying with You.", "Tiyao", 6883, 2, 146},
  [9] = {"Stay cautious, my friend.", "Tiyao", 6883, 2, 146},
  [10] = {"Do not let Chumara and Ikani pass through You and access a portal. Defeat your foes and hurry to Tiyao's tribe. <br> Additionally, keep yourself alive.", "Objective", 174, 0, 128}
}

--for scaling purposes
local user_scr_height = ScreenHeight();
local user_scr_width = ScreenWidth();

if (user_scr_height > 600) then
  Engine.DialogObj:setFont(3);
end

--variables for saving
local current_game_difficulty = get_game_difficulty();
local init = true;
local contributed_braves = 0;
local contributed_trained = 0;
local contributed_shaman = false;
local cyan_shaman_teleported = false;
local death_stored_mana = 0;
local death_counter = 0;
local death_initiated = false;
local honour_saved_once = false;

function OnSave(save_data)
  --Globals save
  save_data:push_int(death_stored_mana);
  save_data:push_int(death_counter);
  save_data:push_int(contributed_braves);
  save_data:push_int(contributed_trained);
  save_data:push_int(current_game_difficulty);
  save_data:push_bool(init);
  save_data:push_bool(contributed_shaman);
  save_data:push_bool(cyan_shaman_teleported);
  save_data:push_bool(death_initiated);

  if (getTurn() >= 12*150 and current_game_difficulty == diff_honour) then
    honour_saved_once = true;
  end

  save_data:push_bool(honour_saved_once);
  log("[INFO] Globals saved.")

  --Engine save
  Engine:saveData(save_data);
end

function OnLoad(load_data)
  --Engine load
  Engine:loadData(load_data);

  --Globals load
  current_game_difficulty = load_data:pop_int();
  contributed_trained = load_data:pop_int();
  contributed_braves = load_data:pop_int();
  death_counter = load_data:pop_int();
  death_stored_mana = load_data:pop_int();
  honour_saved_once = load_data:pop_bool();
  death_initiated = load_data:pop_bool();
  cyan_shaman_teleported = load_data:pop_bool();
  contributed_shaman = load_data:pop_bool();
  init = load_data:pop_bool();
  log("[INFO] Globals loaded.")

  game_loaded = true;

  if (current_game_difficulty == diff_honour) then
    --this is honour difficulty, play like a man or die.
    log("WARNING! GAME WAS LOADED IN HONOUR DIFFICULTY! PROCEED TO EXECUTE CHEATER.");
    game_loaded_honour = true;
  end
end

function OnTurn()
  if (init) then
    init = false;

    --plants
    ProcessGlobalTypeList(T_SCENERY, function(t)
      if (t.Model == M_SCENERY_PLANT_1) then
        t.DrawInfo.DrawNum = 1786 + G_RANDOM(5);
        return true;
      end
      return true;
    end);

    --portals (decor)
    local p1 = createThing(T_SCENERY, M_SCENERY_TOP_LEVEL_SCENERY, TRIBE_HOSTBOT, marker_to_coord3d_centre(13), false, false);
    set_map_elem_object_shadow(world_coord2d_to_map_ptr(p1.Pos.D2), 8);
    set_square_map_params(world_coord2d_to_map_idx(p1.Pos.D2), 2, TRUE);
    p1.DrawInfo.DrawNum = 159;
    p1.DrawInfo.DrawTableIdx = 2;
    p1.DrawInfo.Flags = p1.DrawInfo.Flags | DF_POINTABLE;
    p1.AngleXZ = 512;

    local p2 = createThing(T_SCENERY, M_SCENERY_TOP_LEVEL_SCENERY, TRIBE_HOSTBOT, marker_to_coord3d_centre(33), false, false);
    set_map_elem_object_shadow(world_coord2d_to_map_ptr(p2.Pos.D2), 8);
    set_square_map_params(world_coord2d_to_map_idx(p2.Pos.D2), 2, TRUE);
    p2.DrawInfo.DrawNum = 158;
    p2.DrawInfo.DrawTableIdx = 2;
    p2.DrawInfo.Flags = p2.DrawInfo.Flags | DF_POINTABLE;
    p2.AngleXZ = 1536;

    pp[TRIBE_CYAN].DeadCount = (1 << 4) * 7;

    --setup alliances
    set_players_allied(player_tribe, TRIBE_CYAN);
    set_players_allied(TRIBE_CYAN, player_tribe);

    set_players_allied(ai_tribe_2, ai_tribe_1);
    set_players_allied(ai_tribe_1, ai_tribe_2);

    --disable red's CoR
    set_player_reinc_site_off(pp[player_tribe]);
    mark_reincarnation_site_mes(gs.Players[player_tribe].ReincarnSiteCoord, OWNER_NONE, UNMARK);

    --disable cyan's CoR
    set_player_reinc_site_off(pp[TRIBE_CYAN]);
    mark_reincarnation_site_mes(gs.Players[TRIBE_CYAN].ReincarnSiteCoord, OWNER_NONE, UNMARK);

    --give player ghost army
    set_player_can_cast(M_SPELL_GHOST_ARMY, player_tribe);
    set_correct_gui_menu();

    --command system stuff
    Engine:hidePanel();
    Engine:addCommand_CinemaRaise(0);
    Engine:addCommand_MoveThing(getShaman(player_tribe).ThingNum, marker_to_coord2d_centre(0), 10);
    Engine:addCommand_QueueMsg(dialog_msgs[0][1], dialog_msgs[0][2], 48, false, dialog_msgs[0][3], dialog_msgs[0][4], dialog_msgs[0][5], 12*13);
    Engine:addCommand_AngleThing(getShaman(player_tribe).ThingNum, 1536, 1);
    Engine:addCommand_AngleThing(getShaman(TRIBE_CYAN).ThingNum, 512, 1);
    Engine:addCommand_QueueMsg(dialog_msgs[1][1], dialog_msgs[1][2], 48, false, dialog_msgs[1][3], dialog_msgs[1][4], dialog_msgs[1][5], 12*5);
    Engine:addCommand_QueueMsg(dialog_msgs[2][1], dialog_msgs[2][2], 48, false, dialog_msgs[2][3], dialog_msgs[2][4], dialog_msgs[2][5], 12*2);
    Engine:addCommand_MoveThing(getShaman(TRIBE_CYAN).ThingNum, marker_to_coord2d_centre(5), 1);
    Engine:addCommand_MoveThing(getShaman(player_tribe).ThingNum, marker_to_coord2d_centre(6), 12*7);
    Engine:addCommand_QueueMsg(dialog_msgs[3][1], dialog_msgs[3][2], 48, false, dialog_msgs[3][3], dialog_msgs[3][4], dialog_msgs[3][5], 0);
    Engine:addCommand_AngleThing(getShaman(TRIBE_CYAN).ThingNum, 0, 2);
    Engine:addCommand_AngleThing(getShaman(player_tribe).ThingNum, 2012, 12*8);
    Engine:addCommand_MoveThing(getShaman(TRIBE_CYAN).ThingNum, marker_to_coord2d_centre(7), 0);
    Engine:addCommand_QueueMsg(dialog_msgs[4][1], dialog_msgs[4][2], 48, false, dialog_msgs[4][3], dialog_msgs[4][4], dialog_msgs[4][5], 0);
    Engine:addCommand_QueueMsg(dialog_msgs[5][1], dialog_msgs[5][2], 48, false, dialog_msgs[5][3], dialog_msgs[5][4], dialog_msgs[5][5], 0);
    Engine:addCommand_MoveThing(getShaman(player_tribe).ThingNum, marker_to_coord2d_centre(8), 12*12);
    Engine:addCommand_AngleThing(getShaman(TRIBE_CYAN).ThingNum, 1024, 2);
    Engine:addCommand_AngleThing(getShaman(player_tribe).ThingNum, 1098, 12*10);
    Engine:addCommand_MoveThing(getShaman(TRIBE_CYAN).ThingNum, marker_to_coord2d_centre(9), 1);
    Engine:addCommand_MoveThing(getShaman(player_tribe).ThingNum, marker_to_coord2d_centre(10), 12*11);
    Engine:addCommand_QueueMsg(dialog_msgs[6][1], dialog_msgs[6][2], 48, false, dialog_msgs[6][3], dialog_msgs[6][4], dialog_msgs[6][5], 6);
    Engine:addCommand_QueueMsg(dialog_msgs[7][1], dialog_msgs[7][2], 48, false, dialog_msgs[7][3], dialog_msgs[7][4], dialog_msgs[7][5], 6);
    Engine:addCommand_AngleThing(getShaman(player_tribe).ThingNum, 1536, 12);
    Engine:addCommand_AngleThing(getShaman(TRIBE_CYAN).ThingNum, 512, 12*15);
    Engine:addCommand_AngleThing(getShaman(TRIBE_CYAN).ThingNum, 1536, 6);
    Engine:addCommand_QueueMsg(dialog_msgs[8][1], dialog_msgs[8][2], 48, false, dialog_msgs[8][3], dialog_msgs[8][4], dialog_msgs[8][5], 0);
    Engine:addCommand_MoveThing(getShaman(TRIBE_CYAN).ThingNum, marker_to_coord2d_centre(11), 1);

    local OFFSET = 0;
    if (current_game_difficulty < diff_veteran) then
      --TOWER
      Engine:addCommand_PlacePlan(4, G_RANDOM(4), player_tribe, marker_to_coord2d_centre(14), 2);
      Engine:addCommand_SpawnThings(1, 2, T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(13), 2);
      Engine:addCommand_ChopTree(1, marker_to_coord2d_centre(17), 1, marker_to_coord2d_centre(14), 2);
      Engine:addCommand_ClearThingBuf(1, 6);

      OFFSET = OFFSET + 12 + 4;
      --HUT
      Engine:addCommand_PlacePlan(1, G_RANDOM(4), player_tribe, marker_to_coord2d_centre(18), 2);
      Engine:addCommand_SpawnThings(1, 2, T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(13), 2);
      Engine:addCommand_ChopTree(1, marker_to_coord2d_centre(16), 1, marker_to_coord2d_centre(18), 2);
      Engine:addCommand_ClearThingBuf(1, 6);

      OFFSET = OFFSET + 12 + 4;

      if (current_game_difficulty == diff_beginner) then
        --EXTRA HUT
        Engine:addCommand_PlacePlan(1, G_RANDOM(4), player_tribe, marker_to_coord2d_centre(21), 2);
        Engine:addCommand_SpawnThings(1, 2, T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(13), 2);
        Engine:addCommand_BuildBldg(1, marker_to_coord2d_centre(21), 2);
        Engine:addCommand_ClearThingBuf(1, 6);

        OFFSET = OFFSET + 12 + 4;

        --FIREWARRIOR TRAIN BONUS
        Engine:addCommand_PlacePlan(8, G_RANDOM(4), player_tribe, marker_to_coord2d_centre(22), 2);
        Engine:addCommand_SpawnThings(1, 2, T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(13), 2);
        Engine:addCommand_BuildBldg(1, marker_to_coord2d_centre(22), 2);
        Engine:addCommand_ClearThingBuf(1, 6);

        OFFSET = OFFSET + 12 + 4;

        -- 4 FWS and 4 WARS
        Engine:addCommand_SpawnThings(1, 2, T_PERSON, M_PERSON_SUPER_WARRIOR, player_tribe, marker_to_coord2d_centre(13), 2);
        Engine:addCommand_SpawnThings(1, 2, T_PERSON, M_PERSON_WARRIOR, player_tribe, marker_to_coord2d_centre(13), 2);
        Engine:addCommand_PatrolArea(1, marker_to_coord2d_centre(5), 5, 2);
        Engine:addCommand_ClearThingBuf(1, 6);
        Engine:addCommand_SpawnThings(1, 2, T_PERSON, M_PERSON_SUPER_WARRIOR, player_tribe, marker_to_coord2d_centre(13), 2);
        Engine:addCommand_SpawnThings(1, 2, T_PERSON, M_PERSON_WARRIOR, player_tribe, marker_to_coord2d_centre(13), 2);
        Engine:addCommand_PatrolArea(1, marker_to_coord2d_centre(7), 5, 2);
        Engine:addCommand_ClearThingBuf(1, 6);

        OFFSET = OFFSET + 24 + 8;
      end

      --HUT
      Engine:addCommand_PlacePlan(1, G_RANDOM(4), 1, marker_to_coord2d_centre(19), 2);
      Engine:addCommand_SpawnThings(1, 2, T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(13), 2);
      Engine:addCommand_ChopTree(1, marker_to_coord2d_centre(15), 1, marker_to_coord2d_centre(19), 2);

      OFFSET = OFFSET + 6 + 3;
    end
    Engine:addCommand_ClearThingBuf(1, (12*13)-OFFSET);

    -- red gonna build yes
    Engine:addCommand_AngleThing(getShaman(TRIBE_CYAN).ThingNum, 512, 8);
    Engine:addCommand_QueueMsg(dialog_msgs[9][1], dialog_msgs[9][2], 48, false, dialog_msgs[9][3], dialog_msgs[9][4], dialog_msgs[9][5], 12*4);
    Engine:addCommand_AngleThing(getShaman(TRIBE_CYAN).ThingNum, 1536, 6);
    Engine:addCommand_MoveThing(getShaman(TRIBE_CYAN).ThingNum, marker_to_coord2d_centre(12), 12*2);
    Engine:addCommand_MoveThing(getShaman(player_tribe).ThingNum, marker_to_coord2d_centre(20), 12*5);
    Engine:addCommand_CinemaHide(15);
    Engine:addCommand_ShowPanel(12*2);

    local time_difficulty_offset = current_game_difficulty * 72;
    if (time_difficulty_offset >= 72 * 3) then time_difficulty_offset = 72 * 3; end -- this is to prevent honour difficulty being too hardcore, damn im generous to people

    if (current_game_difficulty == diff_honour) then
      Engine:addCommand_QueueMsg(dialog_msgs[10][1], dialog_msgs[10][2], 128, false, dialog_msgs[10][3], dialog_msgs[10][4], dialog_msgs[10][5], 0);
      Engine:addCommand_QueueMsg("Warning! You've chosen hardest difficulty possibly available which is Honour. You won't be allowed to save or load a little after initial intro in this mode. Enemies will have no mercy on you and Finish you in worst and saddest possible way. Are you brave enough for this suffering? You've been warned.", "Honour Mode", 256, true, 176, 0, 245, (12*150 - (time_difficulty_offset)));
    else
      Engine:addCommand_QueueMsg(dialog_msgs[10][1], dialog_msgs[10][2], 128, false, dialog_msgs[10][3], dialog_msgs[10][4], dialog_msgs[10][5], (12*150 - (time_difficulty_offset)));
    end
    Engine:addCommand_SetVar(1, 1, 0);

    --FLYBY, OH BOI
    --set_myplayer_camera_new_postion(marker_to_coord2d(13), 0);
    FLYBY_CREATE_NEW();
    FLYBY_ALLOW_INTERRUPT(FALSE);

    --MOVE TO CYAN'S SHAMAN
    FLYBY_SET_EVENT_POS(88, 120, 7, 12*10);
    FLYBY_SET_EVENT_ANGLE(1535, 80, 12*9);

    --MOVE TO CHUMARA'S FRONT
    FLYBY_SET_EVENT_POS(78, 136, 200, 12*8);
    FLYBY_SET_EVENT_ANGLE(0, 200, 12*4);

    --MOVE TO CHUMARA'S BASE
    FLYBY_SET_EVENT_POS(86, 210, 270, 12*6);
    FLYBY_SET_EVENT_ANGLE(759, 290, 12*7);

    --MOVE TO IKANI'S FRONT
    FLYBY_SET_EVENT_POS(82, 100, 340, 12*10);
    FLYBY_SET_EVENT_ANGLE(1024, 358, 12*6);

    --MOVE TO IKANI'S FRONT BASE
    FLYBY_SET_EVENT_POS(86, 48, 458, 12*4);
    FLYBY_SET_EVENT_ANGLE(1304, 470, 12*5);

    --MOVE TO IKANI'S CORE BASE
    FLYBY_SET_EVENT_POS(50, 26, 516, 12*6);
    FLYBY_SET_EVENT_ANGLE(2000, 517, 12*5);

    --MOVE TO ISLAND'S CONNECTION
    FLYBY_SET_EVENT_POS(60, 122, 578, 12*9);
    FLYBY_SET_EVENT_ANGLE(1401, 576, 12*12);
    FLYBY_SET_EVENT_ANGLE(256, 686, 12*16);

    --MOVE TO PORTAL
    FLYBY_SET_EVENT_POS(26, 124, 900, 12*8);
    FLYBY_SET_EVENT_ANGLE(1024, 906, 12*25);

    -- MOVE BACK TO BASE
    FLYBY_SET_EVENT_POS(86, 120, 1100, 12*7);
    FLYBY_SET_EVENT_ANGLE(256, 1112, 12*7);

    FLYBY_START();

    --enable computer players

    --yellow
    set_player_can_build(M_BUILDING_TEPEE, ai_tribe_1);
    set_player_can_build(M_BUILDING_DRUM_TOWER, ai_tribe_1);
    set_player_can_build(M_BUILDING_WARRIOR_TRAIN, ai_tribe_1)
    set_player_can_build(M_BUILDING_SUPER_TRAIN, ai_tribe_1);

    computer_init_player(pp[ai_tribe_1]);
    STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_CONSTRUCT_BUILDING);
    STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_AUTO_ATTACK);
    STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_TRAIN_PEOPLE);
    SET_ATTACK_VARIABLE(ai_tribe_1, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_BUILDINGS_ON_GO, 3);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_HOUSE_PERCENTAGE, 30);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_TRAINS, 1);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_TRAIN_AT_ONCE, 4);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_ATTACKS, 3);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_ATTACK_PERCENTAGE, 100);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_DEFENSIVE_ACTIONS, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_RETREAT_VALUE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_BASE_UNDER_ATTACK_RETREAT, 0);

    if (current_game_difficulty >= diff_experienced) then
      set_player_can_cast(M_SPELL_INSECT_PLAGUE, ai_tribe_1);
      set_player_can_cast(M_SPELL_CONVERT_WILD, ai_tribe_1);

      WRITE_CP_ATTRIB(ai_tribe_1, ATTR_EXPANSION, 28);
      WRITE_CP_ATTRIB(ai_tribe_1, ATTR_SHAMEN_BLAST, 16);
      WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_SUPER_WARRIOR_TRAINS, 1);
      STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_MED_MAN_GET_WILD_PEEPS);
      STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_FETCH_WOOD);
      STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_BRING_NEW_PEOPLE_BACK);
      STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_POPULATE_DRUM_TOWER);

      SET_MARKER_ENTRY(ai_tribe_1, 0, 31, -1, 0, 1, 3, 0);
      SET_MARKER_ENTRY(ai_tribe_1, 1, 32, -1, 0, 1, 3, 0);

      SET_BUCKET_USAGE(ai_tribe_1, TRUE);
      SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_1, M_SPELL_CONVERT_WILD, 1);
      SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_1, M_SPELL_BLAST, 1);
      SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_1, M_SPELL_INSECT_PLAGUE, 8);

      if (current_game_difficulty >= diff_veteran) then
        SET_SPELL_ENTRY(ai_tribe_1, 0, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> 4, 128, 2, 1);
        SET_SPELL_ENTRY(ai_tribe_1, 1, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> 4, 128, 2, 0);
      end
    end

    SET_DRUM_TOWER_POS(ai_tribe_1, 84, 228);
    SHAMAN_DEFEND(ai_tribe_1, 84, 228, TRUE);
    SET_DEFENCE_RADIUS(ai_tribe_1, 5);

    --blue
    set_player_can_build(M_BUILDING_TEPEE, ai_tribe_2);
    set_player_can_build(M_BUILDING_DRUM_TOWER, ai_tribe_2);
    set_player_can_build(M_BUILDING_WARRIOR_TRAIN, ai_tribe_2)
    set_player_can_build(M_BUILDING_SUPER_TRAIN, ai_tribe_2);

    computer_init_player(pp[ai_tribe_2]);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_CONSTRUCT_BUILDING);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_AUTO_ATTACK);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_TRAIN_PEOPLE);
    SET_ATTACK_VARIABLE(ai_tribe_2, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_BUILDINGS_ON_GO, 3);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_HOUSE_PERCENTAGE, 30);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_TRAINS, 1);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_TRAIN_AT_ONCE, 4);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_ATTACKS, 3);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_ATTACK_PERCENTAGE, 100);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_DEFENSIVE_ACTIONS, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_RETREAT_VALUE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_BASE_UNDER_ATTACK_RETREAT, 0);

    if (current_game_difficulty >= diff_experienced) then
      set_player_can_cast(M_SPELL_INSECT_PLAGUE, ai_tribe_2);
      set_player_can_cast(M_SPELL_BLAST, ai_tribe_2);
      set_player_can_cast(M_SPELL_CONVERT_WILD, ai_tribe_2);

      WRITE_CP_ATTRIB(ai_tribe_2, ATTR_SHAMEN_BLAST, 8);
      WRITE_CP_ATTRIB(ai_tribe_2, ATTR_EXPANSION, 16);
      WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_TRAINS, 1);
      STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_MED_MAN_GET_WILD_PEEPS);
      STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_FETCH_WOOD);
      STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_BRING_NEW_PEOPLE_BACK);
      STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_POPULATE_DRUM_TOWER);

      SET_BUCKET_USAGE(ai_tribe_2, TRUE);
      SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_2, M_SPELL_CONVERT_WILD, 1);
      SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_2, M_SPELL_BLAST, 1);
      SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_2, M_SPELL_INSECT_PLAGUE, 8);

      if (current_game_difficulty >= diff_veteran) then
        SET_SPELL_ENTRY(ai_tribe_2, 0, M_SPELL_BLAST, SPELL_COST(M_SPELL_BLAST) >> 4, 128, 1, 1);
        SET_SPELL_ENTRY(ai_tribe_2, 1, M_SPELL_BLAST, SPELL_COST(M_SPELL_BLAST) >> 4, 128, 1, 0);
      end
    end

    SET_DRUM_TOWER_POS(ai_tribe_2, 78, 40);
    SHAMAN_DEFEND(ai_tribe_2, 78, 40, TRUE);
    SET_DEFENCE_RADIUS(ai_tribe_2, 5);
  else
    Engine:process();

    if (not cyan_shaman_teleported) then
      local port_me = marker_to_elem_ptr(33);
      port_me.MapWhoList:processList(function(t)
        if (t.Type == T_PERSON and t.Owner == TRIBE_CYAN and (t.Flags2 & TF2_THING_IS_A_GHOST_PERSON) == 0) then
          if (t.Model == M_PERSON_MEDICINE_MAN) then
            cyan_shaman_teleported = true;
            createThing(T_EFFECT, M_EFFECT_SPHERE_EXPLODE_1, 8, t.Pos.D3, false, false);
            delete_thing_type(t);
            return false;
          end
        end
        return true;
      end);
    end

    if (Engine:getVar(4) == 0) then
      if (Engine:getVar(2) == 1 and Engine:getVar(3) == 1) then
        Engine:setVar(4, 1); -- to only process this once.
        Engine:addCommand_SetVar(4, 1, 12*4); --just for delay purposes
        Engine:addCommand_QueueMsg("Our foes have been defeated, now I must hurry to Tiyao's tribe.", "Dakini", 48, false, 7758, 1, 245, 12*4);
        Engine:addCommand_QueueMsg("Shaman, enter the portal with at least 20 trained followers and 10 braves.", "Objective", 256, true, 174, 0, 128, 1);
      end
    elseif (Engine:getVar(4) == 1) then
      if (getTurn() % (1 << 3) == 0) then
        SearchMapCells(SQUARE, 0, 0, 1, world_coord2d_to_map_idx(marker_to_coord2d(33)), function(me)
          if (not me.MapWhoList:isEmpty()) then
            me.MapWhoList:processList(function(t)
              if (t.Type == T_PERSON and t.Owner == player_tribe and (t.Flags2 & TF2_THING_IS_A_GHOST_PERSON) == 0) then
                if (t.Model == M_PERSON_BRAVE and contributed_braves < 10) then
                  contributed_braves = contributed_braves + 1;
                  createThing(T_EFFECT, M_EFFECT_SPHERE_EXPLODE_1, 8, t.Pos.D3, false, false);
                  delete_thing_type(t);
                  return true;
                end

                if (t.Model == M_PERSON_WARRIOR or t.Model == M_PERSON_SUPER_WARRIOR or t.Model == M_PERSON_RELIGIOUS or t.Model == M_PERSON_SPY) then
                  if (contributed_trained < 20) then
                    contributed_trained = contributed_trained + 1;
                    createThing(T_EFFECT, M_EFFECT_SPHERE_EXPLODE_1, 8, t.Pos.D3, false, false);
                    delete_thing_type(t);
                    return true;
                  end
                end

                if (t.Model == M_PERSON_MEDICINE_MAN and (not contributed_shaman)) then
                  contributed_shaman = true;
                  createThing(T_EFFECT, M_EFFECT_SPHERE_EXPLODE_1, 8, t.Pos.D3, false, false);
                  delete_thing_type(t);
                  return true;
                end
              end
              return true;
            end);
          end
          return true;
        end);

        if (contributed_braves >= 10 and contributed_trained >= 20 and contributed_shaman) then
          Engine:setVar(4, 2);
          gns.GameParams.Flags2 = gns.GameParams.Flags2 & ~GPF2_GAME_NO_WIN;
          Engine:addCommand_ClearThingBuf(1, 12*1);
          Engine:addCommand_QueueMsg("Well done shaman!", "Mission Complete", 512, true, nil, nil, 128, 0);
          local portal_me = marker_to_elem_ptr(33);
          portal_me.MapWhoList:processList(function(t)
            if (t.Type == T_SCENERY) then
              if (t.Model == M_SCENERY_TOP_LEVEL_SCENERY and t.DrawInfo.DrawNum == 158) then
                t.DrawInfo.DrawNum = 159;
                return false;
              end
            end
            return true;
          end);
        end
      end
    end

    --MODIFY GAINING MANA
    if (death_counter > 0) then
      death_counter = death_counter - 1;

      if (death_counter == 0 and death_initiated) then
        local plr = pp[player_tribe];
        local current_mana = plr.ManaTransferAmt;
        local multiplier = current_game_difficulty; if (multiplier > 2) then multiplier = 2 end;
        local final_mana = (current_mana - death_stored_mana) >> multiplier;
        if (final_mana <= 0) then final_mana = 0 end;
        plr.ManaTransferAmt = death_stored_mana + final_mana;
      end
    end

    --BLUE CODE
    if (pp[ai_tribe_2].NumPeople > 0 and is_player_in_submit_mode(pp[ai_tribe_2]) == 0) then
      --gib down and sink
      if (getTurn() % (32+ai_tribe_2) == 0) then
        local num_dead = pp[player_tribe].PeopleKilled[ai_tribe_2];
        num_dead = num_dead + pp[TRIBE_CYAN].PeopleKilled[ai_tribe_2];

        local num_braves = pp[ai_tribe_2].NumPeopleOfType[M_PERSON_BRAVE];
        local num_huts = pp[ai_tribe_2].NumBuildingsOfType[1];
        num_huts = num_huts + pp[ai_tribe_2].NumBuildingsOfType[2];
        num_huts = num_huts + pp[ai_tribe_2].NumBuildingsOfType[3];

        if (num_braves < 1 and num_huts == 0 and num_dead > 60) then
          GIVE_UP_AND_SULK(ai_tribe_2, TRUE);
        end
      end

      if ((getTurn() % (180 << 1)) == 0) then
        if (pp[ai_tribe_2].NumPeopleOfType[M_PERSON_BRAVE] > 40 and current_game_difficulty >= diff_experienced) then
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 28);
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_PEOPLE, 17);
        elseif (pp[ai_tribe_2].NumPeopleOfType[M_PERSON_BRAVE] > 20) then
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 15);
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_PEOPLE, 10);
        else
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 0);
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_PEOPLE, 0);
        end
      end

      if (getTurn() % (72 << 1) == 0) then
        if (current_game_difficulty >= diff_experienced) then
          CONVERT_AT_MARKER(ai_tribe_2, 25 + G_RANDOM(6));
        end
      end

      --ATTACKING CODE
      if (Engine:getVar(1) == 1) then
        if (getTurn() % (2160 << 1) == 0) then
          if (current_game_difficulty >= diff_experienced) then
            if (pp[ai_tribe_2].NumPeopleOfType[M_PERSON_SUPER_WARRIOR] > 6 and pp[ai_tribe_2].NumPeopleOfType[M_PERSON_WARRIOR] > 5) then
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_MEDICINE_MAN, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 50);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 50);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_DONT_GROUP_AT_DT, 1);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_GROUP_OPTION, 3);
              ATTACK(ai_tribe_2, player_tribe, 10 + current_game_difficulty * 2, ATTACK_BUILDING, M_BUILDING_TEPEE, 480, 0, 0, 0, ATTACK_NORMAL, 1, -1, -1, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 1);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 100);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 1);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_MEDICINE_MAN, 0);
            end
          end
        elseif (getTurn() % (1222 << 1) == 0) then
          if (current_game_difficulty >= diff_experienced) then
            if (IS_SHAMAN_AVAILABLE_FOR_ATTACK(ai_tribe_2) > 0 and MANA(ai_tribe_2) >= SPELL_COST(M_SPELL_BLAST) * 3) then
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_MEDICINE_MAN, 1);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_DONT_GROUP_AT_DT, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_GROUP_OPTION, 2);
              ATTACK(ai_tribe_2, player_tribe, 0, ATTACK_BUILDING, M_BUILDING_TEPEE, 120, M_SPELL_BLAST, M_SPELL_BLAST, M_SPELL_BLAST, ATTACK_NORMAL, 1, 24, -1, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 1);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 100);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 1);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_MEDICINE_MAN, 0);
            end
          end
        elseif ((getTurn() % (510 << 1)) == 0) then
          if (pp[ai_tribe_2].NumPeopleOfType[M_PERSON_WARRIOR] > 0) then
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 100);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 0);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 0);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_MEDICINE_MAN, 0);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_DONT_GROUP_AT_DT, 1);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_GROUP_OPTION, 2);
            ATTACK(ai_tribe_2, player_tribe, 1 + current_game_difficulty, ATTACK_BUILDING, M_BUILDING_DRUM_TOWER, 60, 0, 0, 0, ATTACK_NORMAL, 1, 24, -1, 0);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 1);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 100);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 1);
          end
        elseif ((getTurn() % (625 << 1)) == 0) then
          if (pp[ai_tribe_2].NumPeopleOfType[M_PERSON_SUPER_WARRIOR] > 3) then
            if (getShaman(player_tribe) ~= nil and G_RANDOM(4) == 0) then
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 100);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_MEDICINE_MAN, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_DONT_GROUP_AT_DT, 1);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_GROUP_OPTION, 3);
              ATTACK(ai_tribe_2, player_tribe, 2, ATTACK_PERSON, M_PERSON_MEDICINE_MAN, 60, 0, 0, 0, ATTACK_NORMAL, 1, -1, -1, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 1);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 1);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 100);
            else
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 50);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 50);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_MEDICINE_MAN, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_DONT_GROUP_AT_DT, 1);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_GROUP_OPTION, 2);
              ATTACK(ai_tribe_2, player_tribe, 4, ATTACK_BUILDING, M_BUILDING_DRUM_TOWER, 200, 0, 0, 0, ATTACK_NORMAL, 1, 24, -1, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 1);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 1);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 100);
            end
          end
        end
      end
    end

    --YELLOW CODE
    if (pp[ai_tribe_1].NumPeople > 0 and is_player_in_submit_mode(pp[ai_tribe_1]) == 0) then
      --gib down and sink
      if (getTurn() % (32+ai_tribe_1) == 0) then
        local num_dead = pp[player_tribe].PeopleKilled[ai_tribe_1];
        num_dead = num_dead + pp[player_ally_tribe].PeopleKilled[ai_tribe_1];

        local num_braves = pp[ai_tribe_1].NumPeopleOfType[M_PERSON_BRAVE];
        local num_huts = pp[ai_tribe_1].NumBuildingsOfType[1];
        num_huts = num_huts + pp[ai_tribe_1].NumBuildingsOfType[2];
        num_huts = num_huts + pp[ai_tribe_1].NumBuildingsOfType[3];

        if (num_braves < 1 and num_huts == 0 and num_dead > 60) then
          GIVE_UP_AND_SULK(ai_tribe_1, TRUE);
        end
      end
      --TOWERS
      if (getTurn() % (444 << 1) == 0) then
        if (current_game_difficulty >= diff_experienced) then
          if (FREE_ENTRIES(ai_tribe_1) > 2) then
            if (pp[ai_tribe_1].NumPeopleOfType[M_PERSON_SUPER_WARRIOR] > 3) then
              if (getPSVar(ai_tribe_1, 1) == 0) then
                setPSVar(ai_tribe_1, 1, 1);
                BUILD_DRUM_TOWER(ai_tribe_1, 68, 184);
              elseif(getPSVar(ai_tribe_1, 1) == 1) then
                setPSVar(ai_tribe_1, 1, 2);
                BUILD_DRUM_TOWER(ai_tribe_1, 92, 182);
              elseif(getPSVar(ai_tribe_1, 1) == 2) then
                MARKER_ENTRIES(ai_tribe_1, 0, 1, -1, -1);
              end
            end
          end
        end
      end

      --TROOPS MANAGEMENT
      if ((getTurn() % (180 << 1)) == 0) then
        if (pp[ai_tribe_1].NumPeopleOfType[M_PERSON_BRAVE] > 38 and current_game_difficulty >= diff_experienced) then
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_PEOPLE, 25);
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 17);
        elseif (pp[ai_tribe_1].NumPeopleOfType[M_PERSON_BRAVE] > 16) then
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_PEOPLE, 15);
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 10);
        else
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_PEOPLE, 0);
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 0);
        end
      end

      --ATTACKING CODE
      if (Engine:getVar(1) == 1) then
        if (getTurn() % (1001 << 1) == 0) then
          if (current_game_difficulty >= diff_experienced) then
            if (IS_SHAMAN_AVAILABLE_FOR_ATTACK(ai_tribe_1) > 0 and MANA(ai_tribe_1) >= SPELL_COST(M_SPELL_INSECT_PLAGUE) * 2) then
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_MEDICINE_MAN, 1);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_DONT_GROUP_AT_DT, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_GROUP_OPTION, 2);
              ATTACK(ai_tribe_1, player_tribe, 0, ATTACK_BUILDING, M_BUILDING_DRUM_TOWER, 120, M_SPELL_INSECT_PLAGUE, M_SPELL_INSECT_PLAGUE, M_SPELL_INSECT_PLAGUE, ATTACK_NORMAL, 1, 4, -1, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, 1);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, 100);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, 1);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_MEDICINE_MAN, 0);
            end
          end
        elseif ((getTurn() % (570 << 1)) == 0) then
          if (pp[ai_tribe_1].NumPeopleOfType[M_PERSON_WARRIOR] > 0) then
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, 100);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, 0);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, 0);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_MEDICINE_MAN, 0);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_DONT_GROUP_AT_DT, 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_GROUP_OPTION, 2);
            ATTACK(ai_tribe_1, player_tribe, 1 + current_game_difficulty, ATTACK_BUILDING, M_BUILDING_DRUM_TOWER, 60, 0, 0, 0, ATTACK_NORMAL, 1, 4, -1, 0);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, 100);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, 1);
          end
        elseif ((getTurn() % (710 << 1)) == 0) then
          if (pp[ai_tribe_1].NumPeopleOfType[M_PERSON_WARRIOR] > 4) then
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, 100);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, 0);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, 0);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_MEDICINE_MAN, 0);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_DONT_GROUP_AT_DT, 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_GROUP_OPTION, 3);
            ATTACK(ai_tribe_1, player_tribe, 4, ATTACK_BUILDING, M_BUILDING_WARRIOR_TRAIN, 180, 0, 0, 0, ATTACK_NORMAL, 1, -1, -1, 0);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, 100);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, 1);
          end
        end
      end
    end

    --handle any post-loading stuff
    if (game_loaded) then
      Engine:postLoadItems();

      game_loaded = false;

      --yep.
      if (game_loaded_honour and honour_saved_once) then
        game_loaded_honour = false;
        ProcessGlobalSpecialList(player_tribe, PEOPLELIST, function(t)
          damage_person(t, 8, 65535, TRUE);
          return true;
        end);

        exit();
      end
    end
  end
end

function OnPlayerDeath(pn)
  if (pn == player_tribe) then
    if (current_game_difficulty == diff_honour) then
      Engine.DialogObj:queueMessage("You're not ready for the challenge yet.", "Mission Failed", 512, true, nil, nil, 128);
    else
      Engine.DialogObj:queueMessage("You have been defeated.", "Mission Failed", 512, true, nil, nil, 128);
    end
  end

  if (pn == ai_tribe_1) then
    Engine:setVar(2, 1);
    Engine.DialogObj:queueMessage("Darn You Dakini! I'll retreat for now, but do not get too cocky!", "Chumara", 48, false, 7869, 1, 238);
  end

  if (pn == ai_tribe_2) then
    Engine:setVar(3, 1);
    Engine.DialogObj:queueMessage("Chumara, You're supposed to be helping me!", "Ikani", 48, false, 7809, 1, 222);
  end
end

function OnCreateThing(t_thing)
  if ((t_thing.Flags3 & TF3_LOCAL) == 0) then
    if (t_thing.Type == T_INTERNAL and t_thing.Model == M_INTERNAL_SOUL_CONVERT_2) then
      if (t_thing.u.SoulConvert.ReturnModel == M_PERSON_MEDICINE_MAN and t_thing.u.SoulConvert.ReturnOwner ~= player_tribe) then
        death_initiated = true;
        death_counter = 1;
        death_stored_mana = pp[player_tribe].ManaTransferAmt;
      end
    end
  end
end

function OnFrame()
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
end
