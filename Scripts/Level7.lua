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
include("CPrisonThing.lua");

--globals
local gs = gsi();
local gns = gnsi();
local spell_const = spells_type_info();
local bldg_const = building_type_info();

--player pointers
local pp = {
  [0] = getPlayer(0),
  [1] = getPlayer(1),
  [2] = getPlayer(2),
  [3] = getPlayer(3),
  [4] = getPlayer(4),
  [5] = getPlayer(5),
  [6] = getPlayer(6),
  [7] = getPlayer(7)
};

--these always have to be set on script load. (DISABLE!!)
spell_const[M_SPELL_GHOST_ARMY].Active = SPAC_OFF;
spell_const[M_SPELL_GHOST_ARMY].NetworkOnly = 1;
bldg_const[M_BUILDING_SPY_TRAIN].ToolTipStrId2 = 641;

--disable wins on this level
gns.GameParams.Flags2 = gns.GameParams.Flags2 | GPF2_GAME_NO_WIN;
gns.GameParams.Flags3 = gns.GameParams.Flags3 & ~GPF3_NO_GAME_OVER_PROCESS;

--main engine
local Engine = CSequence:createNew();

--variables local
local game_loaded = false;
local game_loaded_honour = false;

--defines
local ai_tribe_1 = TRIBE_BLUE;
local ai_tribe_2 = TRIBE_YELLOW;
local player_tribe = TRIBE_GREEN;
local player_ally_tribe = TRIBE_RED;
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
local honour_saved_once = false;
local current_game_difficulty = get_game_difficulty();
local prisons_on_level = {};
local torch_fire_process = {};

--prison yields info
local prison_info = {
    --MARKER, BRAVES, WARS, FWS, PRIESTS
    { 4, 0, 2, 2, 1 },
    { 5, 0, 0, 0, 4 },
    { 6, 5, 0, 0, 0 },
    { 7, 0, 2, 0, 0 },
    { 8, 0, 1, 0, 1 },
    { 9, 0, 1, 1, 1 },
    { 10, 2, 0, 2, 0},
    { 11, 0, 1, 1, 0},
    { 12, 5, 0, 0, 0},
    { 13, 0, 3, 0, 0},
    { 14, 0, 0, 3, 0},
    { 15, 2, 2, 2, 0},
    { 16, 0, 0, 4, 1},
    { 17, 2, 1, 0, 0}
}

local torch_positions = { 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34};

function OnSave(save_data)
  --globals save
  save_data:push_bool(init);
  save_data:push_int(current_game_difficulty);

  if (getTurn() >= 12*90 and current_game_difficulty == diff_honour) then
    honour_saved_once = true;
  end

  save_data:push_bool(honour_saved_once);

  log("[INFO] Globals saved.");

  --prisons save
  for i = #prisons_on_level, 1, -1 do
    prisons_on_level[i]:saveData(save_data);
  end

  save_data:push_int(#prisons_on_level);
  log("[INFO] Prisons saved.");

  for i = #torch_fire_process, 1, -1 do
    save_data:push_int(torch_fire_process[i].ThingNum);
  end

  save_data:push_int(#torch_fire_process);
  log("[INFO] Torches saved.");

  --Engine save
  Engine:saveData(save_data);
end

function OnLoad(load_data)
  --Engine
  Engine:loadData(load_data);

  --torch load
  local torch_count = load_data:pop_int();

  for i = 1, torch_count do
    table.insert(torch_fire_process, GetThing(load_data:pop_int()));
  end
  log("[INFO] Torches loaded.");

  --prison load
  local prison_count = load_data:pop_int();

  for i = 1, prison_count do
    local t_prison = CPrisonThing:createPrison();
    t_prison:loadData(load_data);
    table.insert(prisons_on_level, t_prison);
  end

  log("[INFO] Prisons loaded.");

  honour_saved_once = load_data:pop_bool();
  init = load_data:pop_bool();
  current_game_difficulty = load_data:pop_int();
  log("[INFO] Globals loaded.")

  game_loaded = true;

  if (current_game_difficulty == diff_honour) then
    game_loaded_honour = true;
  end
end

function OnTurn()
  if (init) then
    init = false

    set_players_allied(ai_tribe_1, ai_tribe_2);
    set_players_allied(ai_tribe_2, ai_tribe_1);

    set_players_allied(player_tribe, player_ally_tribe);
    set_players_allied(player_ally_tribe, player_tribe);

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
    p1.AngleXZ = 0;

    local p2 = createThing(T_SCENERY, M_SCENERY_TOP_LEVEL_SCENERY, TRIBE_HOSTBOT, marker_to_coord3d_centre(35), false, false);
    set_map_elem_object_shadow(world_coord2d_to_map_ptr(p2.Pos.D2), 8);
    set_square_map_params(world_coord2d_to_map_idx(p2.Pos.D2), 2, TRUE);
    p2.DrawInfo.DrawNum = 158;
    p2.DrawInfo.DrawTableIdx = 2;
    p2.DrawInfo.Flags = p2.DrawInfo.Flags | DF_POINTABLE;
    p2.AngleXZ = 1536;

    --spawn prisons.
    for i,data in ipairs(prison_info) do
      local pick_owner = {ai_tribe_1, ai_tribe_2};
      local bldg = CREATE_THING_WITH_PARAMS5(T_BUILDING, M_BUILDING_SPY_TRAIN, pick_owner[G_RANDOM(#pick_owner)+1], marker_to_coord3d(data[1]), G_RANDOM(4), 0, S_BUILDING_STAND, 160, 0);
      bldg.Flags2 = bldg.Flags2 | TF2_DONT_DRAW_IN_WORLD_VIEW;

      local prison_thing = CPrisonThing:createPrison();
      prison_thing:setYields(player_tribe, data[2], data[3], data[4], data[5]);
      prison_thing:setCoord(bldg.Pos.D3);
      prison_thing:setProxy(bldg.ThingNum);
      table.insert(prisons_on_level, prison_thing);
    end

    --spawn torches
    for i,marker in ipairs(torch_positions) do
      local torch = createThing(T_SCENERY, M_SCENERY_TOP_LEVEL_SCENERY, 8, marker_to_coord3d_centre(marker), false, false);
      createThing(T_GENERAL, M_GENERAL_LIGHT, 8, marker_to_coord3d_centre(marker), false, false);
      set_thing_draw_info(torch, TDI_OBJECT_GENERIC, 161);
      table.insert(torch_fire_process, torch);
    end

    set_player_reinc_site_off(pp[player_tribe]);
    mark_reincarnation_site_mes(gs.Players[player_tribe].ReincarnSiteCoord, OWNER_NONE, UNMARK);

    --CUTSCENE D: D: D:

    Engine:hidePanel();
    Engine:addCommand_CinemaRaise(0);
    Engine:addCommand_SpawnThings(1, 1, T_PERSON, M_PERSON_MEDICINE_MAN, player_tribe, marker_to_coord2d_centre(0), 1);
    Engine:addCommand_GotoPoint(1, marker_to_coord2d_centre(2), 24);
    Engine:addCommand_SpawnThing(3, T_PERSON, M_PERSON_WARRIOR, player_ally_tribe, marker_to_coord2d_centre(1), 1);
    Engine:addCommand_GotoPoint(3, marker_to_coord2d_centre(3), 1);
    Engine:addCommand_SpawnThings(2, 5, T_PERSON, M_PERSON_WARRIOR, player_tribe, marker_to_coord2d_centre(0), 1);
    Engine:addCommand_GotoPoint(2, marker_to_coord2d_centre(36), 24);
    Engine:addCommand_QueueMsg("Matak!", "Warrior", 12, false, 1774, 0, 245, 12);
    Engine:addCommand_QueueMsg("Your tribesmen are in trouble!", "Warrior", 36, false, 1774, 0, 245, 12*1);

    --while text is being print, let's patrol enemy stuff
    Engine:addCommand_AddThings(5, 3, T_PERSON, M_PERSON_WARRIOR, ai_tribe_1, marker_to_coord2d_centre(40), 1, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(38), marker_to_coord2d_centre(39), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 3, T_PERSON, M_PERSON_WARRIOR, ai_tribe_1, marker_to_coord2d_centre(43), 1, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(41), marker_to_coord2d_centre(42), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 3, T_PERSON, M_PERSON_RELIGIOUS, ai_tribe_1, marker_to_coord2d_centre(44), 1, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(45), marker_to_coord2d_centre(46), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 2, T_PERSON, M_PERSON_WARRIOR, ai_tribe_2, marker_to_coord2d_centre(47), 1, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(48), marker_to_coord2d_centre(49), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 2, T_PERSON, M_PERSON_WARRIOR, ai_tribe_2, marker_to_coord2d_centre(50), 1, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(48), marker_to_coord2d_centre(51), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 2, T_PERSON, M_PERSON_WARRIOR, ai_tribe_2, marker_to_coord2d_centre(52), 1, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(53), marker_to_coord2d_centre(49), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 3, T_PERSON, M_PERSON_RELIGIOUS, ai_tribe_2, marker_to_coord2d_centre(54), 1, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(55), marker_to_coord2d_centre(56), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 3, T_PERSON, M_PERSON_RELIGIOUS, ai_tribe_2, marker_to_coord2d_centre(72), 1, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(57), marker_to_coord2d_centre(58), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 3, T_PERSON, M_PERSON_WARRIOR, ai_tribe_2, marker_to_coord2d_centre(61), 1, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(59), marker_to_coord2d_centre(60), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 3, T_PERSON, M_PERSON_WARRIOR, ai_tribe_2, marker_to_coord2d_centre(62), 1, 0);
    Engine:addCommand_PatrolArea(5, marker_to_coord2d_centre(62), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 3, T_PERSON, M_PERSON_WARRIOR, ai_tribe_1, marker_to_coord2d_centre(63), 1, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(64), marker_to_coord2d_centre(65), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 3, T_PERSON, M_PERSON_WARRIOR, ai_tribe_1, marker_to_coord2d_centre(68), 1, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(67), marker_to_coord2d_centre(66), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 5, T_PERSON, M_PERSON_WARRIOR, ai_tribe_1, marker_to_coord2d_centre(69), 2, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(70), marker_to_coord2d_centre(71), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 3, T_PERSON, M_PERSON_WARRIOR, ai_tribe_2, marker_to_coord2d_centre(73), 2, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(74), marker_to_coord2d_centre(75), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 3, T_PERSON, M_PERSON_WARRIOR, ai_tribe_1, marker_to_coord2d_centre(44), 2, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(45), marker_to_coord2d_centre(46), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 3, T_PERSON, M_PERSON_RELIGIOUS, ai_tribe_1, marker_to_coord2d_centre(76), 2, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(77), marker_to_coord2d_centre(78), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 3, T_PERSON, M_PERSON_SUPER_WARRIOR, ai_tribe_1, marker_to_coord2d_centre(79), 2, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(80), marker_to_coord2d_centre(81), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);

    Engine:addCommand_AddThings(5, 3, T_PERSON, M_PERSON_RELIGIOUS, ai_tribe_1, marker_to_coord2d_centre(82), 2, 0);
    Engine:addCommand_Patrol2P(5, marker_to_coord2d_centre(83), marker_to_coord2d_centre(84), 4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);
    --end of patrolling

    Engine:addCommand_QueueMsg("What is this trouble?", "Matak", 36, false, 6943, 1, 229, 12*4);
    Engine:addCommand_QueueMsg("They... *inhales* ", "Warrior", 12, false, 1774, 0, 245, 12*2);
    Engine:addCommand_QueueMsg("They are holding them imprisoned!", "Warrior", 48, false, 1774, 0, 245, 12*6);
    Engine:addCommand_QueueMsg("Spread all around like an enslavement camp!", "Warrior", 48, false, 1774, 0, 245, 12*6);
    Engine:addCommand_QueueMsg("My people! This is unacceptable...", "Matak", 36, false, 6943, 1, 229, 12*4);
    Engine:addCommand_QueueMsg("Warrior, please, deliver my message to Tiyao, that i'm in a need of reinforcements. <br> We're going after Ikani's and Chumara's heads!", "Matak", 36, false, 6943, 1, 229, 12*7);
    Engine:addCommand_QueueMsg("I bow down before you, almighty Matak, and will promise to deliver the message to Tiyao! <br> If you allow me, i'll hurry right now!", "Warrior", 48, false, 1774, 0, 245, 12*15);

    Engine:addCommand_GotoPoint(3, marker_to_coord2d_centre(0), 12*8);

    Engine:addCommand_QueueMsg("Meanwhile, i'll rescue my tribesmen.", "Matak", 48, false, 6943, 1, 229, 12*5);

    Engine:addCommand_CinemaHide(15);
    Engine:addCommand_ShowPanel(12*2);

    Engine:addCommand_QueueMsg("Shaman. Destroy prisons which contain your followers, they'll be happy to take revenge on Ikani and Chumara. <br> Reach the portal on other side of world to advance. <br> Your shaman must stay alive.", "Objective", 256, true, 174, 0, 128, 0);

    --CUTSCENE :D :D :D

    --blue
    computer_init_player(pp[ai_tribe_1]);
    computer_dont_sort_people_into_sensible_houses(pp[ai_tribe_1]);
    STATE_SET(ai_tribe_1, FALSE, CP_AT_TYPE_CONSTRUCT_BUILDING);
    STATE_SET(ai_tribe_1, FALSE, CP_AT_TYPE_AUTO_ATTACK);
    STATE_SET(ai_tribe_1, FALSE, CP_AT_TYPE_TRAIN_PEOPLE);
    STATE_SET(ai_tribe_1, FALSE, CP_AT_TYPE_POPULATE_DRUM_TOWER);
    STATE_SET(ai_tribe_1, FALSE, CP_AT_TYPE_DEFEND);
    STATE_SET(ai_tribe_1, FALSE, CP_AT_TYPE_DEFEND_BASE);
    STATE_SET(ai_tribe_1, FALSE, CP_AT_TYPE_SUPER_DEFEND);
    STATE_SET(ai_tribe_1, FALSE, CP_AT_TYPE_HOUSE_A_PERSON);
    STATE_SET(ai_tribe_1, FALSE, CP_AT_TYPE_MED_MAN_GET_WILD_PEEPS);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_USE_PREACHER_FOR_DEFENCE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_BUILDINGS_ON_GO, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_HOUSE_PERCENTAGE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_TRAINS, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_SUPER_WARRIOR_TRAINS, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_TRAIN_AT_ONCE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_ATTACKS, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_ATTACK_PERCENTAGE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_DEFENSIVE_ACTIONS, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_RETREAT_VALUE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_BASE_UNDER_ATTACK_RETREAT, 0);

    --yellow
    computer_init_player(pp[ai_tribe_2]);
    computer_dont_sort_people_into_sensible_houses(pp[ai_tribe_2]);
    STATE_SET(ai_tribe_2, FALSE, CP_AT_TYPE_CONSTRUCT_BUILDING);
    STATE_SET(ai_tribe_2, FALSE, CP_AT_TYPE_AUTO_ATTACK);
    STATE_SET(ai_tribe_2, FALSE, CP_AT_TYPE_TRAIN_PEOPLE);
    STATE_SET(ai_tribe_2, FALSE, CP_AT_TYPE_POPULATE_DRUM_TOWER);
    STATE_SET(ai_tribe_2, FALSE, CP_AT_TYPE_DEFEND);
    STATE_SET(ai_tribe_2, FALSE, CP_AT_TYPE_DEFEND_BASE);
    STATE_SET(ai_tribe_2, FALSE, CP_AT_TYPE_SUPER_DEFEND);
    STATE_SET(ai_tribe_2, FALSE, CP_AT_TYPE_HOUSE_A_PERSON);
    STATE_SET(ai_tribe_2, FALSE, CP_AT_TYPE_MED_MAN_GET_WILD_PEEPS);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_USE_PREACHER_FOR_DEFENCE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_BUILDINGS_ON_GO, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_HOUSE_PERCENTAGE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_TRAINS, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_TRAINS, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_TRAIN_AT_ONCE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_ATTACKS, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_ATTACK_PERCENTAGE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_DEFENSIVE_ACTIONS, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_RETREAT_VALUE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_BASE_UNDER_ATTACK_RETREAT, 0);
  else
    Engine:process();

    --teleport red's warrior
    if (Engine:getVar(1) == 0) then
      local port_me = marker_to_elem_ptr(0);
      port_me.MapWhoList:processList(function(t)
        if (t.Type == T_PERSON and t.Owner == player_ally_tribe and (t.Flags2 & TF2_THING_IS_A_GHOST_PERSON) == 0) then
          if (t.Model == M_PERSON_WARRIOR) then
            Engine:setVar(1, 1);
            createThing(T_EFFECT, M_EFFECT_SPHERE_EXPLODE_1, 8, t.Pos.D3, false, false);
            delete_thing_type(t);
            return false;
          end
        end
        return true;
      end);
    end

    if (getShaman(player_tribe) ~= nil) then
      local s = getShaman(player_tribe);

      if (Engine:getVar(2) == 0) then
        if (get_world_dist_xyz(s.Pos.D3, marker_to_coord3d_centre(8)) < 512*5) then
          Engine:setVar(2, 1);
          Engine:addCommand_QueueMsg("Is this weird building... a prison?", "Matak", 24, false, 6943, 1, 229, 12);
        end
      end

      if (Engine:getVar(3) == 0) then
        if (get_world_dist_xyz(s.Pos.D3, marker_to_coord3d_centre(37)) < 512*5) then
          Engine:setVar(3, 1);
          Engine:addCommand_QueueMsg("I can sense my followers here! We're going to free you!", "Matak", 24, false, 6943, 1, 229, 12);
        end
      end

      if (Engine:getVar(4) == 0) then
        if (get_world_dist_xyz(s.Pos.D3, marker_to_coord3d_centre(85)) < 512*3) then
          Engine:setVar(4, 1);
          Engine:addCommand_QueueMsg("We've reached our destination. Tiyao, i'm counting on you.", "Matak", 24, false, 6943, 1, 229, 12);
        end
      end

      if (Engine:getVar(4) == 1) then
        --teleport matak's shaman
        if (Engine:getVar(5) == 0) then
          local port_me = marker_to_elem_ptr(35);
          port_me.MapWhoList:processList(function(t)
            if (t.Type == T_PERSON and t.Owner == player_tribe and (t.Flags2 & TF2_THING_IS_A_GHOST_PERSON) == 0) then
              if (t.Model == M_PERSON_MEDICINE_MAN) then
                Engine:setVar(5, 1);
                createThing(T_EFFECT, M_EFFECT_SPHERE_EXPLODE_1, 8, t.Pos.D3, false, false);
                Engine:addCommand_ClearThingBuf(1, 12*2)
                Engine:addCommand_QueueMsg("Well done shaman!", "Mission Complete", 512, true, nil, nil, 128, 0);
                Engine:addCommand_SetVar(6, 1, 0);
                delete_thing_type(t);
                return false;
              end
            end
            return true;
          end);
        end
      end

      if (Engine:getVar(6) == 1) then
        Engine:setVar(6, 2);
        bldg_const[M_BUILDING_SPY_TRAIN].ToolTipStrId2 = 944;
        gns.GameParams.Flags2 = gns.GameParams.Flags2 & ~GPF2_GAME_NO_WIN;
        gns.Flags = gns.Flags | GNS_LEVEL_COMPLETE;
      end
    end

    --animate torches
    for i,t_thing in ipairs(torch_fire_process) do
      t_thing.DrawInfo.FrameNum = t_thing.DrawInfo.FrameNum + 1;
      if (t_thing.DrawInfo.FrameNum >= 9) then
        t_thing.DrawInfo.FrameNum = 0;
      end
    end
    --process prisons
    for i,Prison in ipairs(prisons_on_level) do
      if (not Prison:process()) then
        table.remove(prisons_on_level, i);
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

        bldg_const[M_BUILDING_SPY_TRAIN].ToolTipStrId2 = 944;
        exit();
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
