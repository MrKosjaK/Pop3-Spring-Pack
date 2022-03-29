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
change_sprite_bank(0,0)
sti = spells_type_info()
for i = 2,17 do
	sti[i].AvailableSpriteIdx = 353+i
end
sti[19].AvailableSpriteIdx = 408

--includes
include("CSequence.lua");
include("CTimer.lua");

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
ency[27].StrId = 690;
ency[32].StrId = 691;
ency[22].StrId = 692;
ency[35].StrId = 695;
ency[38].StrId = 696;

--disable wins on this level
gns.GameParams.Flags2 = gns.GameParams.Flags2 | GPF2_GAME_NO_WIN;
gns.GameParams.Flags3 = gns.GameParams.Flags3 & ~GPF3_NO_GAME_OVER_PROCESS;
gns.GameParams.Flags3 = gns.GameParams.Flags3 | GPF3_FOG_OF_WAR_KEEP_STATE;

--main engine
local Engine = CSequence:createNew();

--helper functions
local setPSVar = function(pn, idx, val) SET_USER_VARIABLE_VALUE(pn, idx, val); end;
local getPSVar = function(pn, idx) return GET_USER_VARIABLE_VALUE(pn, idx); end;

--variables local
local game_loaded = false;
local game_loaded_honour = false;

--defines
local ai_tribe_1 = TRIBE_BLUE;
local ai_tribe_2 = TRIBE_YELLOW;
local player_tribe = TRIBE_GREEN;
local player_ally_tribe = TRIBE_CYAN;
local diff_beginner = 0;
local diff_experienced = 1;
local diff_veteran = 2;
local diff_honour = 3;

--features
enable_feature(F_SUPER_WARRIOR_NO_AMENDMENT); --fix fws not shooting
enable_feature(F_MINIMAP_ENEMIES); --who the hell plays with minimap off?
enable_feature(F_WILD_NO_RESPAWN); --disable wild respawning, oh boy.

--for scaling purposes
local user_scr_height = ScreenHeight();
local user_scr_width = ScreenWidth();

if (user_scr_height > 600) then
  Engine.DialogObj:setFont(3);
end

--variables for saving
local init = true;
local current_game_difficulty = get_game_difficulty();
local death_stored_mana = 0;
local death_counter = 0;
local death_initiated = false;
local honour_saved_once = false;

--timers
local B_Atk1 = CTimer:register(); --small cripple attacks
local B_Atk2 = CTimer:register();
local B_Atk3 = CTimer:register(); -- shaman attack
local Y_Atk1 = CTimer:register(); -- small cripple attack
local Y_Atk2 = CTimer:register(); -- shaman attack with troops
local Y_Atk3 = CTimer:register(); -- annoying bullshit just to make life easier for computer players ofc not player lmao

--attack types
--BLUE DATA
local AT =
{
  --[0] = {TIMER_TIME, RANDOMNESS, GROUP_TYPE, DONT_GROUP_AT_DT, BRAVES, WARS, FWS, PRIESTS, SHAMAN, NUM_PEEPS, ATK_TYPE, ATK_TARGET, ATK_DMG, S1, S2, S3, MRK1, MRK2},
  [0] = {2384, 1024, 2, 0, 0, 25, 10, 10, 0, 5, ATTACK_BUILDING, M_BUILDING_DRUM_TOWER, 233, M_SPELL_NONE, M_SPELL_NONE, M_SPELL_NONE, 17, -1},
  [1] = {1811, 1024, 2, 0, 0, 5, 10, 50, 0, 4, ATTACK_BUILDING, M_BUILDING_TEMPLE, 453, M_SPELL_NONE, M_SPELL_NONE, M_SPELL_NONE, 18, -1},
  [2] = {2480, 1024, 2, 0, 5, 0, 50, 50, 0, 6, ATTACK_BUILDING, M_BUILDING_SUPER_TRAIN, 322, M_SPELL_NONE, M_SPELL_NONE, M_SPELL_NONE, 19, -1},
  [3] = {2745, 1024, 2, 0, 0, 50, 50, 50, 0, 6, ATTACK_BUILDING, M_BUILDING_SUPER_TRAIN, 513, M_SPELL_NONE, M_SPELL_NONE, M_SPELL_NONE, 18, -1},
  [4] = {2820, 1024, 3, 0, 25, 25, 25, 25, 0, 12, ATTACK_BUILDING, M_BUILDING_TEPEE, 800, M_SPELL_NONE, M_SPELL_NONE, M_SPELL_NONE, -1, -1},
};

local AT_S =
{
  [0] = {3199, 1024, 2, 0, ATTACK_BUILDING, M_BUILDING_DRUM_TOWER, 999, M_SPELL_LIGHTNING_BOLT, M_SPELL_LIGHTNING_BOLT, M_SPELL_INSECT_PLAGUE, 17, -1},
  [1] = {2899, 1024, 2, 0, ATTACK_BUILDING, M_BUILDING_DRUM_TOWER, 999, M_SPELL_INSECT_PLAGUE, M_SPELL_LIGHTNING_BOLT, M_SPELL_LIGHTNING_BOLT, 18, -1},
  [2] = {3299, 1024, 2, 0, ATTACK_BUILDING, M_BUILDING_DRUM_TOWER, 999, M_SPELL_LIGHTNING_BOLT, M_SPELL_INSECT_PLAGUE, M_SPELL_LIGHTNING_BOLT, 19, -1},
  [3] = {2472, 1024, 3, 1, ATTACK_BUILDING, M_BUILDING_DRUM_TOWER, 999, M_SPELL_LIGHTNING_BOLT, M_SPELL_LIGHTNING_BOLT, M_SPELL_LIGHTNING_BOLT, -1, -1},
  [4] = {2058, 1024, 3, 1, ATTACK_BUILDING, M_BUILDING_DRUM_TOWER, 999, M_SPELL_INSECT_PLAGUE, M_SPELL_INSECT_PLAGUE, M_SPELL_INSECT_PLAGUE, -1, -1},
};

--YELLOW DATA
local ATY =
{
  [0] = {2320, 1024, 2, 0, 0, 25, 5, 10, 0, 5, ATTACK_BUILDING, M_BUILDING_DRUM_TOWER, 233, M_SPELL_NONE, M_SPELL_NONE, M_SPELL_NONE, 39, -1},
  [1] = {2599, 1024, 2, 0, 0, 5, 5, 50, 0, 4, ATTACK_BUILDING, M_BUILDING_TEMPLE, 453, M_SPELL_NONE, M_SPELL_NONE, M_SPELL_NONE, 40, -1},
  [2] = {2999, 1024, 2, 0, 5, 0, 5, 50, 1, 6, ATTACK_BUILDING, M_BUILDING_SUPER_TRAIN, 322, M_SPELL_INSECT_PLAGUE, M_SPELL_HYPNOTISM, M_SPELL_INSECT_PLAGUE, 41, -1},
  [3] = {2999, 1024, 2, 0, 0, 50, 5, 50, 1, 6, ATTACK_BUILDING, M_BUILDING_SUPER_TRAIN, 513, M_SPELL_INSECT_PLAGUE, M_SPELL_INSECT_PLAGUE, M_SPELL_INSECT_PLAGUE, 39, -1},
  [4] = {3800, 1024, 3, 0, 25, 25, 5, 25, 1, 12, ATTACK_BUILDING, M_BUILDING_TEPEE, 800, M_SPELL_HYPNOTISM, M_SPELL_HYPNOTISM, M_SPELL_HYPNOTISM, -1, -1},
  [5] = {3800, 1024, 2, 0, 25, 25, 5, 25, 1, 12, ATTACK_BUILDING, M_BUILDING_TEPEE, 900, M_SPELL_HYPNOTISM, M_SPELL_HYPNOTISM, M_SPELL_HYPNOTISM, 41, -1},
};

function OnSave(save_data)
  --Globals save
  save_data:push_int(current_game_difficulty);
  save_data:push_int(death_stored_mana);
  save_data:push_int(death_counter);

  save_data:push_bool(init);
  save_data:push_bool(death_initiated);

  if (getTurn() >= 12*60 and current_game_difficulty == diff_honour) then
    honour_saved_once = true;
  end

  save_data:push_bool(honour_saved_once);
  log("[INFO] Globals saved.")

  --Engine save
  Engine:saveData(save_data);

  --Timers
  B_Atk1:saveData(save_data);
  B_Atk2:saveData(save_data);
  B_Atk3:saveData(save_data);
  Y_Atk1:saveData(save_data);
  Y_Atk2:saveData(save_data);
  Y_Atk3:saveData(save_data);
  log("[INFO] Timers saved.");
end

function OnLoad(load_data)
  --Timers
  Y_Atk3:loadData(load_data);
  Y_Atk2:loadData(load_data);
  Y_Atk1:loadData(load_data);
  B_Atk3:loadData(load_data);
  B_Atk2:loadData(load_data);
  B_Atk1:loadData(load_data);
  log("[INFO] Timers loaded.");

  --Engine
  Engine:loadData(load_data);

  --Globals load
  death_counter = load_data:pop_int();
  death_stored_mana = load_data:pop_int();
  current_game_difficulty = load_data:pop_int();

  honour_saved_once = load_data:pop_bool();
  death_initiated = load_data:pop_bool();
  init = load_data:pop_bool();
  log("[INFO] Globals loaded.")

  game_loaded = true;

  if (current_game_difficulty == diff_honour) then
    game_loaded_honour = true;
  end
end

local function process_area(x, z)
  local stop_now = false;
  SearchMapCells(SQUARE, 0, 0, 5, world_coord3d_to_map_idx(MAP_XZ_2_WORLD_XYZ(x, z)), function(me)
    if (not me.MapWhoList:isEmpty() and (not stop_now)) then
      me.MapWhoList:processList(function(t)
        if (t.Type == T_PERSON) then
          if (t.Model > M_PERSON_WILD) then
            if (t.Owner == player_tribe) then
              stop_now = true;
              return false;
            end
          end
        end
        return true;
      end);
    end
    return true;
  end);

  return stop_now;
end

local function reveal_fog_at(x, z)
  SearchMapCells(CIRCULAR, 0, 0, 2, world_coord3d_to_map_idx(MAP_XZ_2_WORLD_XYZ(x, z)), function(me)
    gs.FogOfWar:perm_uncover(player_tribe, me);
    return true;
  end);
  set_square_map_params(world_coord3d_to_map_idx(MAP_XZ_2_WORLD_XYZ(x, z)), 3, TRUE);
end

local function did_player_kill_any_enemy()
  local result = false;
  local people_killed_by_player = gs.Players[player_tribe].PeopleKilled[ai_tribe_1];
  people_killed_by_player = people_killed_by_player + gs.Players[player_tribe].PeopleKilled[ai_tribe_2];

  if (people_killed_by_player > 0) then
    result = true;
  end

  return result;
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

    ProcessGlobalTypeList(T_EFFECT, function(t)
      if (t.Model == M_EFFECT_SWAMP_MIST) then
        t.Flags3 = t.Flags3 | TF3_RESTRICT_ANIM_SPEED;
        return true;
      end
      return true;
    end);

    set_players_allied(ai_tribe_1, ai_tribe_2);
    set_players_allied(ai_tribe_2, ai_tribe_1);

    set_players_allied(player_tribe, player_ally_tribe);
    set_players_allied(player_ally_tribe, player_tribe);

    set_player_can_cast(M_SPELL_GHOST_ARMY, player_tribe);
    set_correct_gui_menu();

    --delete initial brave lol
    ProcessGlobalSpecialList(player_tribe, PEOPLELIST, function(t)
      delete_thing_type(t);
      return true;
    end)

    --portals (decor)
    local p1 = createThing(T_SCENERY, M_SCENERY_TOP_LEVEL_SCENERY, TRIBE_HOSTBOT, marker_to_coord3d_centre(0), false, false);
    set_map_elem_object_shadow(world_coord2d_to_map_ptr(p1.Pos.D2), 8);
    set_square_map_params(world_coord2d_to_map_idx(p1.Pos.D2), 2, TRUE);
    p1.DrawInfo.DrawNum = 158;
    p1.DrawInfo.DrawTableIdx = 2;
    p1.DrawInfo.Flags = p1.DrawInfo.Flags | DF_POINTABLE;
    p1.AngleXZ = 512;

    set_player_reinc_site_off(pp[player_tribe]);
    mark_reincarnation_site_mes(gs.Players[player_tribe].ReincarnSiteCoord, OWNER_NONE, UNMARK);

    reveal_fog_at(224, 186);

    -- ITS TALE TIME

    Engine:hidePanel();
    Engine:addCommand_CinemaRaise(0);

    local multiplier = current_game_difficulty; if (multiplier > 2) then multiplier = 2; end

    Engine:addCommand_SpawnThings(1, 1, T_PERSON, M_PERSON_MEDICINE_MAN, player_tribe, marker_to_coord2d_centre(0), 1);
    Engine:addCommand_GotoPoint(1, marker_to_coord2d_centre(1), 12);
    Engine:addCommand_SpawnThings(2, 10 - (multiplier * 2), T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(0), 1);
    Engine:addCommand_GotoPoint(2, marker_to_coord2d_centre(2), 8);
    Engine:addCommand_SpawnThings(3, 4 - multiplier, T_PERSON, M_PERSON_WARRIOR, player_tribe, marker_to_coord2d_centre(0), 1);
    Engine:addCommand_GotoPoint(3, marker_to_coord2d_centre(3), 8);
    Engine:addCommand_SpawnThings(3, 4 - multiplier, T_PERSON, M_PERSON_SUPER_WARRIOR, player_tribe, marker_to_coord2d_centre(0), 1);
    Engine:addCommand_GotoPoint(3, marker_to_coord2d_centre(3), 8);
    Engine:addCommand_SpawnThings(3, 4 - multiplier, T_PERSON, M_PERSON_RELIGIOUS, player_tribe, marker_to_coord2d_centre(0), 1);
    Engine:addCommand_GotoPoint(3, marker_to_coord2d_centre(3), 12);
    Engine:addCommand_QueueMsg("This is...", "Matak", 36, false, 6943, 1, 229, 12);
    Engine:addCommand_GotoPoint(1, marker_to_coord2d_centre(4), 12*5);
    Engine:addCommand_QueueMsg("Canyon?", "Matak", 36, false, 6943, 1, 229, 12*4);
    Engine:addCommand_GotoPoint(2, marker_to_coord2d_centre(4), 0);
    Engine:addCommand_GotoPoint(3, marker_to_coord2d_centre(4), 0);
    Engine:addCommand_GotoPoint(1, marker_to_coord2d_centre(5), 12*5);
    Engine:addCommand_GotoPoint(2, marker_to_coord2d_centre(7), 0);
    Engine:addCommand_GotoPoint(3, marker_to_coord2d_centre(8), 0);
    Engine:addCommand_GotoPoint(1, marker_to_coord2d_centre(6), 12*12);

    Engine:addCommand_ClearThingBuf(1, 0);
    Engine:addCommand_ClearThingBuf(2, 0);
    Engine:addCommand_ClearThingBuf(3, 0);
    Engine:addCommand_ClearThingBuf(4, 0);
    Engine:addCommand_QueueMsg("Maybe we can setup a temporary base here?", "Matak", 36, false, 6943, 1, 229, 12*4);

    Engine:addCommand_CinemaHide(15);
    Engine:addCommand_ShowPanel(12*2);

    Engine:addCommand_QueueMsg("Shaman. Build a base before exploring area around. You never know what dangers lurk in the mist. <br> Build at least 5 huts. <br> Build at least 3 towers. <br> Build at least one of any training hut.", "Objective", 256, true, 174, 0, 128, 0);

    if (current_game_difficulty == diff_honour) then
      Engine:addCommand_QueueMsg("Warning! You've chosen hardest difficulty possibly available which is Honour. You won't be allowed to save or load a little after initial intro in this mode. Enemies will have no mercy on you and Finish you in worst and saddest possible way. Are you brave enough for this suffering? You've been warned.", "Honour Mode", 256, true, 176, 0, 245, 0);
    end

    -- A LITTLE LORE NOW, A LOTTA TALE LATER

    --SCP FLYBY INITIATE.
    FLYBY_CREATE_NEW();
    FLYBY_ALLOW_INTERRUPT(FALSE);

    FLYBY_SET_EVENT_POS(42, 252, 12, 60);
    FLYBY_SET_EVENT_POS(52, 4, 72, 60);
    FLYBY_SET_EVENT_POS(60, 18, 132, 96);
    FLYBY_SET_EVENT_POS(76, 46, 224, 96);

    FLYBY_SET_EVENT_ANGLE(125, 24, 48);
    FLYBY_SET_EVENT_ANGLE(202, 132, 36);
    FLYBY_SET_EVENT_ANGLE(402, 300, 60);
    FLYBY_SET_EVENT_ANGLE(1202, 348, 60);

    FLYBY_START();
    --SCP FLYBY TERMINATE.

    --BEE BOO BEEP ME ACTIVATE
    set_player_can_build(M_BUILDING_TEPEE, ai_tribe_1);
    set_player_can_build(M_BUILDING_DRUM_TOWER, ai_tribe_1);
    set_player_can_build(M_BUILDING_WARRIOR_TRAIN, ai_tribe_1)
    set_player_can_build(M_BUILDING_SUPER_TRAIN, ai_tribe_1);
    set_player_can_build(M_BUILDING_TEMPLE, ai_tribe_1);
    set_player_can_cast(M_SPELL_BLAST, ai_tribe_1);
    set_player_can_cast(M_SPELL_INSECT_PLAGUE, ai_tribe_1);
    set_player_can_cast(M_SPELL_CONVERT_WILD, ai_tribe_1);
    set_player_can_cast(M_SPELL_HYPNOTISM, ai_tribe_1);

    computer_init_player(pp[ai_tribe_1]);

    STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_CONSTRUCT_BUILDING);
    STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_AUTO_ATTACK);
    STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_TRAIN_PEOPLE);
    STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_POPULATE_DRUM_TOWER);
    STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_MED_MAN_GET_WILD_PEEPS);
    STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_BRING_NEW_PEOPLE_BACK);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_EXPANSION, 24);
    SET_ATTACK_VARIABLE(ai_tribe_1, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_BUILDINGS_ON_GO, 3);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_HOUSE_PERCENTAGE, 60);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_TRAINS, 1);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_SUPER_WARRIOR_TRAINS, 1);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_RELIGIOUS_TRAINS, 1);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_RELIGIOUS_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_TRAIN_AT_ONCE, 4);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_ATTACKS, 2);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_ATTACK_PERCENTAGE, 100);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_DEFENSIVE_ACTIONS, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_RETREAT_VALUE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_BASE_UNDER_ATTACK_RETREAT, 0);
    STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_DEFEND);
    STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_DEFEND_BASE);
    STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_SUPER_DEFEND);
    STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_PREACH);
    STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_FETCH_LOST_PEOPLE);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_USE_PREACHER_FOR_DEFENCE, 1);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_SHAMEN_BLAST, 32);

    SET_DRUM_TOWER_POS(ai_tribe_1, 30, 182);
    SHAMAN_DEFEND(ai_tribe_1, 30, 182, TRUE);
    SET_DEFENCE_RADIUS(ai_tribe_1, 5);

    SET_MARKER_ENTRY(ai_tribe_1, 0, 16, -1, 0, 2, 0, 0);
    SET_MARKER_ENTRY(ai_tribe_1, 1, 10, -1, 0, 2, 0, 0);
    SET_MARKER_ENTRY(ai_tribe_1, 2, 14, 15, 0, 5, 0, 0);
    MARKER_ENTRIES(ai_tribe_1, 0, 1, 2, -1);

    SET_BUCKET_USAGE(ai_tribe_1, TRUE);
    SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_1, M_SPELL_CONVERT_WILD, 1);
    SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_1, M_SPELL_BLAST, 1);
    SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_1, M_SPELL_INSECT_PLAGUE, 8);
    SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_1, M_SPELL_HYPNOTISM, 12);

    SET_SPELL_ENTRY(ai_tribe_1, 0, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> 4, 128, 2, 1);
    SET_SPELL_ENTRY(ai_tribe_1, 1, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> 4, 128, 2, 0);
    SET_SPELL_ENTRY(ai_tribe_1, 2, M_SPELL_HYPNOTISM, SPELL_COST(M_SPELL_HYPNOTISM) >> 4, 128, 5, 1);
    SET_SPELL_ENTRY(ai_tribe_1, 3, M_SPELL_HYPNOTISM, SPELL_COST(M_SPELL_HYPNOTISM) >> 4, 128, 5, 0);

    if (current_game_difficulty >= diff_experienced) then
      set_player_can_cast(M_SPELL_LIGHTNING_BOLT, ai_tribe_1);
      WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_ATTACKS, 3);
      WRITE_CP_ATTRIB(ai_tribe_1, ATTR_SHAMEN_BLAST, 16);
      SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_1, M_SPELL_LIGHTNING_BOLT, 10);

      SET_SPELL_ENTRY(ai_tribe_1, 4, M_SPELL_LIGHTNING_BOLT, SPELL_COST(M_SPELL_LIGHTNING_BOLT) >> 4, 128, 3, 1);
      SET_SPELL_ENTRY(ai_tribe_1, 5, M_SPELL_LIGHTNING_BOLT, SPELL_COST(M_SPELL_LIGHTNING_BOLT) >> 4, 128, 3, 0);

      TARGET_PLAYER_DT_AND_S(ai_tribe_1, player_tribe);
      TARGET_DRUM_TOWERS(ai_tribe_1);

      if (current_game_difficulty >= diff_veteran) then
        WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_ATTACKS, 4); --really wow!
        WRITE_CP_ATTRIB(ai_tribe_1, ATTR_SHAMEN_BLAST, 8);
        TARGET_SHAMAN(ai_tribe_1);
        TARGET_S_WARRIORS(ai_tribe_1);
      end
    end

    --BEE BOO BEEP ME ACTIVATE
    set_player_can_build(M_BUILDING_TEPEE, ai_tribe_2);
    set_player_can_build(M_BUILDING_DRUM_TOWER, ai_tribe_2);
    set_player_can_build(M_BUILDING_WARRIOR_TRAIN, ai_tribe_2)
    set_player_can_build(M_BUILDING_SUPER_TRAIN, ai_tribe_2);
    set_player_can_build(M_BUILDING_TEMPLE, ai_tribe_2);
    set_player_can_cast(M_SPELL_BLAST, ai_tribe_2);
    set_player_can_cast(M_SPELL_INSECT_PLAGUE, ai_tribe_2);
    set_player_can_cast(M_SPELL_CONVERT_WILD, ai_tribe_2);
    set_player_can_cast(M_SPELL_HYPNOTISM, ai_tribe_2);

    computer_init_player(pp[ai_tribe_2]);

    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_CONSTRUCT_BUILDING);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_AUTO_ATTACK);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_TRAIN_PEOPLE);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_POPULATE_DRUM_TOWER);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_MED_MAN_GET_WILD_PEEPS);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_BRING_NEW_PEOPLE_BACK);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_EXPANSION, 24);
    SET_ATTACK_VARIABLE(ai_tribe_2, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_BUILDINGS_ON_GO, 3);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_HOUSE_PERCENTAGE, 60);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_TRAINS, 1);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_TRAINS, 1);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_RELIGIOUS_TRAINS, 1);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_RELIGIOUS_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_TRAIN_AT_ONCE, 4);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_ATTACKS, 2);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_ATTACK_PERCENTAGE, 100);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_DEFENSIVE_ACTIONS, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_RETREAT_VALUE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_BASE_UNDER_ATTACK_RETREAT, 0);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_DEFEND);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_DEFEND_BASE);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_SUPER_DEFEND);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_PREACH);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_FETCH_LOST_PEOPLE);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_USE_PREACHER_FOR_DEFENCE, 1);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_SHAMEN_BLAST, 32);

    SET_DRUM_TOWER_POS(ai_tribe_2, 194, 84);
    SHAMAN_DEFEND(ai_tribe_2, 194, 84, TRUE);
    SET_DEFENCE_RADIUS(ai_tribe_2, 5);

    SET_MARKER_ENTRY(ai_tribe_2, 0, 24, -1, 0, 2, 0, 0);
    SET_MARKER_ENTRY(ai_tribe_2, 1, 25, -1, 0, 2, 0, 0);
    SET_MARKER_ENTRY(ai_tribe_2, 2, 26, -1, 0, 2, 0, 0);
    MARKER_ENTRIES(ai_tribe_2, 0, 1, 2, -1);

    SET_BUCKET_USAGE(ai_tribe_2, TRUE);
    SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_2, M_SPELL_CONVERT_WILD, 1);
    SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_2, M_SPELL_BLAST, 1);
    SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_2, M_SPELL_INSECT_PLAGUE, 8);
    SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_2, M_SPELL_HYPNOTISM, 12);

    SET_SPELL_ENTRY(ai_tribe_2, 0, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> 4, 128, 2, 1);
    SET_SPELL_ENTRY(ai_tribe_2, 1, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> 4, 128, 2, 0);
    SET_SPELL_ENTRY(ai_tribe_2, 2, M_SPELL_HYPNOTISM, SPELL_COST(M_SPELL_HYPNOTISM) >> 4, 128, 5, 1);
    SET_SPELL_ENTRY(ai_tribe_2, 3, M_SPELL_HYPNOTISM, SPELL_COST(M_SPELL_HYPNOTISM) >> 4, 128, 5, 0);

    if (current_game_difficulty >= diff_experienced) then
      set_player_can_cast(M_SPELL_LIGHTNING_BOLT, ai_tribe_2);
      WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_ATTACKS, 3);
      WRITE_CP_ATTRIB(ai_tribe_2, ATTR_SHAMEN_BLAST, 16);
      SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_2, M_SPELL_LIGHTNING_BOLT, 10);

      SET_SPELL_ENTRY(ai_tribe_2, 4, M_SPELL_LIGHTNING_BOLT, SPELL_COST(M_SPELL_LIGHTNING_BOLT) >> 4, 128, 3, 1);
      SET_SPELL_ENTRY(ai_tribe_2, 5, M_SPELL_LIGHTNING_BOLT, SPELL_COST(M_SPELL_LIGHTNING_BOLT) >> 4, 128, 3, 0);

      TARGET_PLAYER_DT_AND_S(ai_tribe_2, player_tribe);
      TARGET_DRUM_TOWERS(ai_tribe_2);

      if (current_game_difficulty >= diff_veteran) then
        WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_ATTACKS, 4); --really wow!
        WRITE_CP_ATTRIB(ai_tribe_2, ATTR_SHAMEN_BLAST, 8);
        TARGET_SHAMAN(ai_tribe_2);
        TARGET_S_WARRIORS(ai_tribe_2);
      end
    end
  else

    Engine:process();

    if (Engine:getVar(1) == 0) then
      if (Engine:getVar(2) == 0 and pp[player_tribe].NumBuildingsOfType[M_BUILDING_DRUM_TOWER] >= 3) then
        Engine:setVar(2, 1);
        Engine:addCommand_QueueMsg("Shaman, we've finished building towers!", "Worker", 36, false, 1784, 0, 229, 12*4);
      end

      if (Engine:getVar(3) == 0) then
        local h1 = pp[player_tribe].NumBuildingsOfType[1];
        h1 = h1 + pp[player_tribe].NumBuildingsOfType[2];
        h1 = h1 + pp[player_tribe].NumBuildingsOfType[3];
        if (h1 >= 5) then
          Engine:setVar(3, 1);
          Engine:addCommand_QueueMsg("Shaman, we've finished building huts!", "Worker", 36, false, 1784, 0, 229, 12*4);
        end
      end

      if (Engine:getVar(4) == 0) then
        if (pp[player_tribe].NumBuildingsOfType[5] > 0 or pp[player_tribe].NumBuildingsOfType[6] > 0 or pp[player_tribe].NumBuildingsOfType[7] > 0 or pp[player_tribe].NumBuildingsOfType[8] > 0) then
          Engine:setVar(4, 1);
          Engine:addCommand_QueueMsg("Shaman, we've finished building a training hut!", "Worker", 36, false, 1784, 0, 229, 12*4);
        end
      end

      if (Engine:getVar(2) == 1 and Engine:getVar(3) == 1 and Engine:getVar(4) == 1) then
        Engine:setVar(1, 1);
        Engine:addCommand_QueueMsg("Our temporary base is established! We can begin scouting area around.", "Worker", 36, false, 1784, 0, 229, 12*4);
      end
    end

    if (Engine:getVar(1) == 1) then
      --check places near blue and yellow and alert player.
      if (getTurn() % (1<<4)-1 == 0) then
        if (Engine:getVar(5) == 0) then
          if (process_area(46, 104) or process_area(54, 124)) then
            Engine:setVar(5, 1);
            Engine:addCommand_QueueMsg("Ikani have been spotted!", "Scout", 36, false, 1785, 0, 229, 12*4);
          end
        end
      end

      if (getTurn() % (1<<4) == 0) then
        if (Engine:getVar(6) == 0) then
          if (process_area(134, 84) or process_area(142, 66)) then
            Engine:setVar(6, 1);
            Engine:addCommand_QueueMsg("Chumara have been spotted!", "Scout", 36, false, 1785, 0, 229, 12*4);
          end
        end
      end

      if (Engine:getVar(5) == 1 and Engine:getVar(6) == 1) then
        Engine:addCommand_QueueMsg("We're not alone here, as I thought. Tiyao should arrive soon or late to help us.", "Matak", 36, false, 6943, 1, 229, 12*4);
        Engine:addCommand_QueueMsg("Destroy your enemies without losing your own shaman.", "Objective", 256, true, 174, 0, 128, 0);
        Engine:setVar(7, 1);
        Engine:setVar(1, 2);
        B_Atk1:setTime(1440, 1);
        Y_Atk2:setTime(4096, 1);
        if (current_game_difficulty >= diff_experienced) then
          B_Atk2:setTime(2280, 1);
          B_Atk3:setTime(3000, 1);
          Y_Atk1:setTime(2048, 1);
          if (current_game_difficulty >= diff_veteran) then
            Y_Atk3:setTime(5155, 1); -- very bad man
          end
        end
      end
    end

    if ((getTurn() >= 720*8 and Engine:getVar(7) == 0) or (did_player_kill_any_enemy() and Engine:getVar(7) == 0)) then
      Engine:addCommand_QueueMsg("Destroy your enemies without losing your own shaman. <br> But enemies are already coming...", "Objective", 256, true, 174, 0, 128, 0);
      Engine:setVar(7, 1); --if player doesn't explore around just activate attacking phase.
      Engine:setVar(1, 2);
      B_Atk1:setTime(256, 1);
      Y_Atk2:setTime(2048, 1);
      if (current_game_difficulty >= diff_experienced) then
        B_Atk2:setTime(2280, 1);
        B_Atk3:setTime(512, 1);
        Y_Atk1:setTime(1024, 1);
        if (current_game_difficulty >= diff_veteran) then
          Y_Atk3:setTime(4096, 1); -- super annoying
        end
      end
    end

    if (Engine:getVar(9) == 1 and Engine:getVar(10) == 1 and Engine:getVar(11) == 0) then
      Engine:addCommand_ClearThingBuf(1, 12*6);
      Engine:addCommand_QueueMsg("We were victorious, but... Where is Tiyao?", "Matak", 36, false, 6943, 1, 229, 12*6);
      Engine:addCommand_SetVar(11, 1, 0);
    end

    if (Engine:getVar(11) == 1) then
      Engine:setVar(11, 2);
      gns.GameParams.Flags2 = gns.GameParams.Flags2 & ~GPF2_GAME_NO_WIN;
      Engine:addCommand_QueueMsg("Well done shaman!", "Mission Complete", 512, true, nil, nil, 128, 0);
    end

    if (current_game_difficulty >= diff_experienced) then
      if ((getTurn() & (1 << 10)-1) == 0) then
        ProcessGlobalTypeList(T_BUILDING, function(t)
          if (t.Owner == ai_tribe_1 or t.Owner == ai_tribe_2) then
            if (t.State == S_BUILDING_STAND) then
              if (t.Model <= 3 and pp[t.Owner].NumPeopleOfType[M_PERSON_BRAVE] < (40 + current_game_difficulty * 10)) then
                t.u.Bldg.SproggingCount = 9999;
                return true;
              end
            end
          end
          return true;
        end);
      end
    end

    --YELLOW CODE BRUH
    if (pp[ai_tribe_2].NumPeople > 0 and is_player_in_submit_mode(pp[ai_tribe_2]) == 0) then
      --gib down and sink
      if (getTurn() % (32+ai_tribe_2) == 0) then
        local num_dead = pp[player_tribe].PeopleKilled[ai_tribe_2];
        num_dead = num_dead + pp[player_ally_tribe].PeopleKilled[ai_tribe_2];

        local num_braves = pp[ai_tribe_2].NumPeopleOfType[M_PERSON_BRAVE];
        local num_huts = pp[ai_tribe_2].NumBuildingsOfType[1];
        num_huts = num_huts + pp[ai_tribe_2].NumBuildingsOfType[2];
        num_huts = num_huts + pp[ai_tribe_2].NumBuildingsOfType[3];

        if (num_braves < 1 and num_huts == 0 and num_dead > 70) then
          GIVE_UP_AND_SULK(ai_tribe_2, TRUE);
        end
      end

      if (Engine:getVar(7) == 1) then
        --ATTACKING HERE M8
        if (Y_Atk3:process()) then
          if (pp[ai_tribe_2].NumPeopleOfType[M_PERSON_SUPER_WARRIOR] > 12) then
            if (FREE_ENTRIES(ai_tribe_2) > 3) then
              --so now we want to annoy player .. check if area is clear.
              local should_care = true;
              if (getPSVar(ai_tribe_2, 3) == 1) then
                -- lets check if fws still alive
                if (count_people_of_type_in_area(82, 18, M_PERSON_SUPER_WARRIOR, ai_tribe_2, 5) >= 2) then
                  -- they're alive still, then don't check.
                  should_care = false;
                else
                  -- ok there's few fws left, check then!
                  setPSVar(ai_tribe_2, 3, 0);
                  should_care = true;
                end
              end

              if (should_care) then
                if (count_people_of_type_in_area(82, 18, -1, player_tribe, 3) < 5) then
                  local mk = 42 + G_RANDOM(5);

                  SET_MARKER_ENTRY(ai_tribe_2, 3, mk, mk, 0, 0, 2, 0);

                  local mk2 = 42 + G_RANDOM(5);

                  while (mk2 == mk) do
                    mk2 = 42 + G_RANDOM(5);
                  end

                  SET_MARKER_ENTRY(ai_tribe_2, 4, mk2, mk2, 0, 0, 2, 0);
                  MARKER_ENTRIES(ai_tribe_2, 3, 4, -1 ,-1);
                  Y_Atk3:setTime(4096, 2048);
                  setPSVar(ai_tribe_2, 3, 1);
                else
                  Y_Atk3:setTime(1440, 1);
                end
              else
                Y_Atk3:setTime(1440, 1);
              end
            else
              Y_Atk3:setTime(720, 1);
            end
          else
            Y_Atk3:setTime(1440, 1);
          end
        end

        if (Y_Atk2:process()) then
          if (pp[ai_tribe_2].NumPeopleOfType[M_PERSON_WARRIOR] > 5 or pp[ai_tribe_2].NumPeopleOfType[M_PERSON_RELIGIOUS] > 6) then
            local ac = G_RANDOM(#ATY);
            local shaman_away = ATY[ac][9];
            local defensive_spell = ATY[ac][14];
            local spell2 = ATY[ac][15];
            local spell3 = ATY[ac][16];
            local s = getShaman(ai_tribe_2);
            local should_care = false;

            if (s ~= nil) then
              if (s.u.Pers.u.Owned.FightGroup == 0) then
                should_care = true;
              end
            end

            if (should_care) then
              local num_winds = GET_NUM_ONE_OFF_SPELLS(ai_tribe_2, M_SPELL_WHIRLWIND);
              local num_eqs = GET_NUM_ONE_OFF_SPELLS(ai_tribe_2, M_SPELL_EARTHQUAKE);

              if (GET_NUM_ONE_OFF_SPELLS(ai_tribe_2, M_SPELL_SHIELD) > 0) then
                defensive_spell = M_SPELL_SHIELD;
                shaman_away = 1;
              elseif (defensive_spell ~= M_SPELL_NONE) then
                if (num_winds > 0) then
                  defensive_spell = M_SPELL_WHIRLWIND;
                  num_winds = num_winds - 1;
                elseif (num_eqs > 0) then
                  defensive_spell = M_SPELL_EARTHQUAKE;
                  num_eqs = num_eqs - 1;
                end
              end

              if (spell2 ~= M_SPELL_NONE) then
                if (num_winds > 0) then
                  spell2 = M_SPELL_WHIRLWIND;
                  num_winds = num_winds - 1;
                elseif (num_eqs > 0) then
                  spell2 = M_SPELL_EARTHQUAKE;
                  num_eqs = num_eqs - 1;
                end
              end

              if (spell3 ~= M_SPELL_NONE) then
                if (num_winds > 0) then
                  spell3 = M_SPELL_WHIRLWIND;
                  num_winds = num_winds - 1;
                elseif (num_eqs > 0) then
                  spell3 = M_SPELL_EARTHQUAKE;
                  num_eqs = num_eqs - 1;
                end
              end
            end


            Y_Atk2:setTime(ATY[ac][1], ATY[ac][2]);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_GROUP_OPTION, ATY[ac][3])
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_DONT_GROUP_AT_DT, ATY[ac][4]);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, ATY[ac][5]);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, ATY[ac][6]);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, ATY[ac][7]);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_RELIGIOUS, ATY[ac][8]);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_MEDICINE_MAN, shaman_away); --NUM_PEEPS, ATK_TYPE, ATK_TARGET, ATK_DMG, S1, S2, S3, MRK1, MRK2
            ATTACK(ai_tribe_2, player_tribe, ATY[ac][10] + G_RANDOM(AT[ac][10] << 1), ATY[ac][11], ATY[ac][12], ATY[ac][13], defensive_spell, spell2, spell3, ATTACK_NORMAL, 0, ATY[ac][17], ATY[ac][18], 0);
          else
            Y_Atk2:setTime(720, 1);
          end
        end

        if (Y_Atk1:process()) then
          if (pp[ai_tribe_2].NumPeopleOfType[M_PERSON_WARRIOR] > 2 or pp[ai_tribe_2].NumPeopleOfType[M_PERSON_RELIGIOUS] > 3) then
            local ac = G_RANDOM(#AT);
            local shaman_away = ATY[ac][9];
            local defensive_spell = ATY[ac][14];
            local spell2 = M_SPELL_NONE;
            local spell3 = M_SPELL_NONE
            local s = getShaman(ai_tribe_2);
            local should_care = false;

            if (s ~= nil) then
              if (s.u.Pers.u.Owned.FightGroup == 0) then
                should_care = true;
              end
            end

            if (should_care) then
              if (GET_NUM_ONE_OFF_SPELLS(ai_tribe_2, M_SPELL_SHIELD) > 0) then
                defensive_spell = M_SPELL_SHIELD;
                shaman_away = 1;
              end
            end

            Y_Atk1:setTime(ATY[ac][1], ATY[ac][2]);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_GROUP_OPTION, ATY[ac][3])
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_DONT_GROUP_AT_DT, ATY[ac][4]);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, ATY[ac][5]);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, ATY[ac][6]);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, ATY[ac][7]);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_RELIGIOUS, ATY[ac][8]);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_MEDICINE_MAN, shaman_away); --NUM_PEEPS, ATK_TYPE, ATK_TARGET, ATK_DMG, S1, S2, S3, MRK1, MRK2
            ATTACK(ai_tribe_2, player_tribe, ATY[ac][10], ATY[ac][11], ATY[ac][12], ATY[ac][13], defensive_spell, spell2, spell3, ATTACK_NORMAL, 0, ATY[ac][17], ATY[ac][18], 0);
          else
            Y_Atk1:setTime(720, 1);
          end
        end
      end

      --converting :n
      if (getTurn() % (72 << 1) == 0) then
        if (pp[ai_tribe_2].NumPeople < 35 and getTurn() < 720*2) then
          CONVERT_AT_MARKER(ai_tribe_2, 27 + G_RANDOM(5));
        end
      end

      if (getPSVar(ai_tribe_2, 2) < getTurn() and getPSVar(ai_tribe_2, 1) == 1) then
        setPSVar(ai_tribe_2, 1, 0);
      end

      if ((getTurn() % (360+ai_tribe_2)) == 0) then
        if (pp[ai_tribe_2].NumPeopleOfType[M_PERSON_BRAVE] > 44 and current_game_difficulty >= diff_experienced) then
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 40);
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_PEOPLE, 25);
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_RELIGIOUS_PEOPLE, 25);
        elseif (pp[ai_tribe_2].NumPeopleOfType[M_PERSON_BRAVE] > 20) then
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 25);
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_PEOPLE, 13);
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_RELIGIOUS_PEOPLE, 12);
        else
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 0);
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_PEOPLE, 0);
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_RELIGIOUS_PEOPLE, 0);
        end
      end

      --pray at moyai
      if (Engine:getVar(7) == 1 or current_game_difficulty >= diff_veteran) then
        --earthquake stone head
        if (getTurn() >= 720*20 and current_game_difficulty >= diff_veteran) then
          if (getPSVar(ai_tribe_2, 1) == 0 and GET_HEAD_TRIGGER_COUNT(118, 104) > 0) then
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 99);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 1);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 1);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_RELIGIOUS, 1);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SPY, 1);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_MEDICINE_MAN, 0);
            PRAY_AT_HEAD(ai_tribe_2, 6, 38);
            setPSVar(ai_tribe_2, 1, 1);
            setPSVar(ai_tribe_2, 2, getTurn() + 2048);
          end
        end

        --tornado stone head
        if (getTurn() >= 720*10 and current_game_difficulty >= diff_experienced) then
          if (getPSVar(ai_tribe_2, 1) == 0 and GET_HEAD_TRIGGER_COUNT(152, 42) > 0) then
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 99);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 1);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 1);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_RELIGIOUS, 1);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SPY, 1);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_MEDICINE_MAN, 0);
            PRAY_AT_HEAD(ai_tribe_2, 3, 37);
            setPSVar(ai_tribe_2, 1, 1);
            setPSVar(ai_tribe_2, 2, getTurn() + 2048);
          end
        end
        --magical shield stone head
        if (getTurn() % 840 == 0 and getPSVar(ai_tribe_2, 1) == 0) then
          --ok we want to check if magical shield stone head isn't occupied right
          if (count_people_of_type_in_area(204, 38, -1, player_tribe, 4) == 0) then
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 99);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 1);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 1);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_RELIGIOUS, 1);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SPY, 1);
            WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_MEDICINE_MAN, 0);
            PRAY_AT_HEAD(ai_tribe_2, 5, 36);
            setPSVar(ai_tribe_2, 1, 1);
            setPSVar(ai_tribe_2, 2, getTurn() + 2048);
          end
        end
      end
    end

    --BLUE CODE PART
    if (pp[ai_tribe_1].NumPeople > 0 and is_player_in_submit_mode(pp[ai_tribe_1]) == 0) then
      --gib down and sink
      if (getTurn() % (32+ai_tribe_1) == 0) then
        local num_dead = pp[player_tribe].PeopleKilled[ai_tribe_1];
        num_dead = num_dead + pp[player_ally_tribe].PeopleKilled[ai_tribe_1];

        local num_braves = pp[ai_tribe_1].NumPeopleOfType[M_PERSON_BRAVE];
        local num_huts = pp[ai_tribe_1].NumBuildingsOfType[1];
        num_huts = num_huts + pp[ai_tribe_1].NumBuildingsOfType[2];
        num_huts = num_huts + pp[ai_tribe_1].NumBuildingsOfType[3];

        if (num_braves < 1 and num_huts == 0 and num_dead > 70) then
          GIVE_UP_AND_SULK(ai_tribe_1, TRUE);
        end
      end
      --converting :n
      if (getTurn() % (72 << 1) == 0) then
        if (pp[ai_tribe_1].NumPeople < 35 and getTurn() < 720*2) then
          CONVERT_AT_MARKER(ai_tribe_1, 32 + G_RANDOM(4));
        end
      end

      if (Engine:getVar(7) == 1) then
        --ATTACKING HERE M8
        if (B_Atk3:process()) then
          local s = getShaman(ai_tribe_1);
          local should_care = false;

          if (s ~= nil) then
            if (s.u.Pers.u.Owned.FightGroup == 0) then
              should_care = true;
            end
          end

          if (should_care) then
            if (MANA(ai_tribe_1) > 200000) then
              local ac = G_RANDOM(#AT_S);
              local spell1 = AT_S[ac][8];
              local spell2 = AT_S[ac][9];

              if (GET_NUM_ONE_OFF_SPELLS(ai_tribe_1, M_SPELL_SWAMP) > 0) then
                spell1 = M_SPELL_SWAMP;
              end

              if (spell1 == AT_S[ac][8]) then
                if (GET_NUM_ONE_OFF_SPELLS(ai_tribe_1, M_SPELL_FIRESTORM) > 0) then
                  spell1 = M_SPELL_FIRESTORM;
                end
              else
                if (GET_NUM_ONE_OFF_SPELLS(ai_tribe_1, M_SPELL_FIRESTORM) > 0) then
                  spell2 = M_SPELL_FIRESTORM;
                end
              end

              B_Atk3:setTime(AT_S[ac][1], AT_S[ac][2]);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_GROUP_OPTION, AT_S[ac][3]);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_DONT_GROUP_AT_DT, AT_S[ac][4]);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_RELIGIOUS, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_MEDICINE_MAN, 1);
              ATTACK(ai_tribe_1, player_tribe, 0, AT_S[ac][5], AT_S[ac][6], AT_S[ac][7], spell1, spell2, AT_S[ac][10], ATTACK_NORMAL, 0, AT_S[ac][11], AT_S[ac][12], 0);
            else
              B_Atk3:setTime(720, 1);
            end
          else
            B_Atk3:setTime(720, 1);
          end
        end
        if (B_Atk2:process()) then
          if (pp[ai_tribe_1].NumPeopleOfType[M_PERSON_WARRIOR] > 2 or pp[ai_tribe_1].NumPeopleOfType[M_PERSON_RELIGIOUS] > 3) then
            local ac = G_RANDOM(#AT);
            local shaman_away = AT[ac][9];
            local defensive_spell = AT[ac][14];
            local s = getShaman(ai_tribe_1);
            local should_care = false;

            if (s ~= nil) then
              if (s.u.Pers.u.Owned.FightGroup == 0) then
                should_care = true;
              end
            end

            if (should_care) then
              if (GET_NUM_ONE_OFF_SPELLS(ai_tribe_1, M_SPELL_SHIELD) > 0) then
                defensive_spell = M_SPELL_SHIELD;
                shaman_away = 1;
              end
            end

            B_Atk2:setTime(AT[ac][1], AT[ac][2] << 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_GROUP_OPTION, AT[ac][3])
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_DONT_GROUP_AT_DT, AT[ac][4]);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, AT[ac][5]);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, AT[ac][6]);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, AT[ac][7]);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_RELIGIOUS, AT[ac][8]);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_MEDICINE_MAN, shaman_away); --NUM_PEEPS, ATK_TYPE, ATK_TARGET, ATK_DMG, S1, S2, S3, MRK1, MRK2
            ATTACK(ai_tribe_1, player_tribe, AT[ac][10] + G_RANDOM(AT[ac][10] << 1), AT[ac][11], AT[ac][12], AT[ac][13], defensive_spell, AT[ac][15], AT[ac][16], ATTACK_NORMAL, 0, AT[ac][17], AT[ac][18], 0);
          else
            B_Atk2:setTime(720, 1);
          end
        end

        if (B_Atk1:process()) then
          if (pp[ai_tribe_1].NumPeopleOfType[M_PERSON_WARRIOR] > 2 or pp[ai_tribe_1].NumPeopleOfType[M_PERSON_RELIGIOUS] > 3) then
            local ac = G_RANDOM(#AT);
            local shaman_away = AT[ac][9];
            local defensive_spell = AT[ac][14];
            local s = getShaman(ai_tribe_1);
            local should_care = false;

            if (s ~= nil) then
              if (s.u.Pers.u.Owned.FightGroup == 0) then
                should_care = true;
              end
            end

            if (should_care) then
              if (GET_NUM_ONE_OFF_SPELLS(ai_tribe_1, M_SPELL_SHIELD) > 0) then
                defensive_spell = M_SPELL_SHIELD;
                shaman_away = 1;
              end
            end

            B_Atk1:setTime(AT[ac][1], AT[ac][2]);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_GROUP_OPTION, AT[ac][3])
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_DONT_GROUP_AT_DT, AT[ac][4]);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, AT[ac][5]);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, AT[ac][6]);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, AT[ac][7]);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_RELIGIOUS, AT[ac][8]);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_MEDICINE_MAN, shaman_away); --NUM_PEEPS, ATK_TYPE, ATK_TARGET, ATK_DMG, S1, S2, S3, MRK1, MRK2
            ATTACK(ai_tribe_1, player_tribe, AT[ac][10], AT[ac][11], AT[ac][12], AT[ac][13], defensive_spell, AT[ac][15], AT[ac][16], ATTACK_NORMAL, 0, AT[ac][17], AT[ac][18], 0);
          else
            B_Atk1:setTime(720, 1);
          end
        end
      end

      --PRAYING STONE HEADS
      if (getPSVar(ai_tribe_1, 2) < getTurn() and getPSVar(ai_tribe_1, 1) == 1) then
        setPSVar(ai_tribe_1, 1, 0);
      end

      if (Engine:getVar(7) == 1 or current_game_difficulty >= diff_veteran) then
        --firestorm stone head
        if (getTurn() >= 720*20 and current_game_difficulty >= diff_experienced) then
          if (getPSVar(ai_tribe_1, 1) == 0 and GET_HEAD_TRIGGER_COUNT(224, 186) > 0) then
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, 99);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_RELIGIOUS, 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SPY, 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_MEDICINE_MAN, 0);
            PRAY_AT_HEAD(ai_tribe_1, 1, 21);
            setPSVar(ai_tribe_1, 1, 1);
            setPSVar(ai_tribe_1, 2, getTurn() + 2048);
          end
        end

        --swamp stone head
        if (getTurn() >= 720*10 and current_game_difficulty >= diff_veteran) then
          if (getPSVar(ai_tribe_1, 1) == 0 and GET_HEAD_TRIGGER_COUNT(18, 94) > 0) then
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, 99);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_RELIGIOUS, 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SPY, 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_MEDICINE_MAN, 0);
            PRAY_AT_HEAD(ai_tribe_1, 6, 22);
            setPSVar(ai_tribe_1, 1, 1);
            setPSVar(ai_tribe_1, 2, getTurn() + 2048);
          end
        end
        --magical shield stone head
        if (getTurn() % 840+ai_tribe_1 == 0 and getPSVar(ai_tribe_1, 1) == 0) then
          --ok we want to check if magical shield stone head isn't occupied right
          if (count_people_of_type_in_area(78, 138, -1, player_tribe, 4) == 0) then
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, 99);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_RELIGIOUS, 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SPY, 1);
            WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_MEDICINE_MAN, 0);
            PRAY_AT_HEAD(ai_tribe_1, 5, 20);
            setPSVar(ai_tribe_1, 1, 1);
            setPSVar(ai_tribe_1, 2, getTurn() + 2048);
          end
        end
      end

      if (getTurn() % 720+ai_tribe_1 == 0) then
        if (pp[ai_tribe_1].NumPeopleOfType[M_PERSON_WARRIOR] > 3) then
          MARKER_ENTRIES(player_ally_tribe, 0, 1, 2, -1);
        end
      end

      if ((getTurn() % 360+ai_tribe_1) == 0) then
        if (pp[ai_tribe_1].NumPeopleOfType[M_PERSON_BRAVE] > 49 and current_game_difficulty >= diff_experienced) then
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 35);
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_PEOPLE, 35);
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_RELIGIOUS_PEOPLE, 35);
        elseif (pp[ai_tribe_1].NumPeopleOfType[M_PERSON_BRAVE] > 20) then
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 17);
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_PEOPLE, 22);
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_RELIGIOUS_PEOPLE, 14);
        else
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 0);
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_PEOPLE, 0);
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_RELIGIOUS_PEOPLE, 0);
        end
      end
    end

    --MODIFY GAINING MANA
    if (death_counter > 0) then
      death_counter = death_counter - 1;

      if (death_counter == 0 and death_initiated) then
        local current_mana = pp[player_tribe].ManaTransferAmt;
        local multiplier = current_game_difficulty; if (multiplier > 2) then multiplier = 2 end;
        local final_mana = (current_mana - death_stored_mana) >> multiplier;
        if (final_mana <= 0) then final_mana = 0 end;
        pp[player_tribe].ManaTransferAmt = death_stored_mana + final_mana;
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

  if (pn == ai_tribe_2) then
    Engine:setVar(10, 1);
    Engine.DialogObj:queueMessage("... ... ... <br> Is this really happening to us, again?", "Chumara", 36, false, 7869, 1, 238);
  end

  if (pn == ai_tribe_1) then
    Engine:setVar(9, 1);
    Engine.DialogObj:queueMessage("... ... ... <br> Once again it has been proven... That my sidekick is an absolute idiot...", "Ikani", 36, false, 7809, 1, 222);
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
