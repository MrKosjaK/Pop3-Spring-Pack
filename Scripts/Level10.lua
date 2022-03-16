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
spell_const[M_SPELL_SWAMP].OneOffMaximum = 4
spell_const[M_SPELL_SWAMP].WorldCoordRange = 4096
spell_const[M_SPELL_SWAMP].CursorSpriteNum = 53
spell_const[M_SPELL_SWAMP].ToolTipStrIdx = 823
spell_const[M_SPELL_SWAMP].AvailableSpriteIdx = 364
spell_const[M_SPELL_SWAMP].NotAvailableSpriteIdx = 382
spell_const[M_SPELL_SWAMP].ClickedSpriteIdx = 400
bldg_const[M_BUILDING_SPY_TRAIN].ToolTipStrId2 = 641;
ency[27].StrId = 690;
ency[32].StrId = 691;
ency[22].StrId = 692;

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

function OnSave(save_data)
  --Globals save
  save_data:push_int(current_game_difficulty);
  save_data:push_int(death_stored_mana);
  save_data:push_int(death_counter);

  save_data:push_bool(init);
  save_data:push_bool(death_initiated);

  if (getTurn() >= 12*240 and current_game_difficulty == diff_honour) then
    honour_saved_once = true;
  end

  save_data:push_bool(honour_saved_once);
  log("[INFO] Globals saved.")

  --Engine save
  Engine:saveData(save_data);
end

function OnLoad(load_data)
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

function OnTurn()
  if (init) then
    init = false;

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
    p1.AngleXZ = 512;

    set_player_reinc_site_off(pp[player_tribe]);
    mark_reincarnation_site_mes(gs.Players[player_tribe].ReincarnSiteCoord, OWNER_NONE, UNMARK);

    -- ITS TALE TIME

    Engine:hidePanel();
    Engine:addCommand_CinemaRaise(0);

    Engine:addCommand_SpawnThings(1, 1, T_PERSON, M_PERSON_MEDICINE_MAN, player_tribe, marker_to_coord2d_centre(0), 1);
    Engine:addCommand_GotoPoint(1, marker_to_coord2d_centre(1), 12);
    Engine:addCommand_SpawnThings(2, 10, T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(0), 1);
    Engine:addCommand_GotoPoint(2, marker_to_coord2d_centre(2), 8);
    Engine:addCommand_SpawnThings(3, 4, T_PERSON, M_PERSON_WARRIOR, player_tribe, marker_to_coord2d_centre(0), 1);
    Engine:addCommand_GotoPoint(3, marker_to_coord2d_centre(3), 8);
    Engine:addCommand_SpawnThings(3, 4, T_PERSON, M_PERSON_SUPER_WARRIOR, player_tribe, marker_to_coord2d_centre(0), 1);
    Engine:addCommand_GotoPoint(3, marker_to_coord2d_centre(3), 8);
    Engine:addCommand_SpawnThings(3, 4, T_PERSON, M_PERSON_RELIGIOUS, player_tribe, marker_to_coord2d_centre(0), 1);
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

    Engine:addCommand_QueueMsg("Maybe we can setup a temporary base here?", "Matak", 36, false, 6943, 1, 229, 12*4);

    Engine:addCommand_CinemaHide(15);
    Engine:addCommand_ShowPanel(12*2);

    Engine:addCommand_QueueMsg("Shaman. Build a base before exploring area around. You never know if there's enemy hiding in fog. <br> Build at least 5 huts. <br> Build at least 3 towers. <br> Build at least one of any training schools.", "Objective", 256, true, 174, 0, 128, 0);

    if (current_game_difficulty == diff_honour) then
      Engine:addCommand_QueueMsg("Warning! You've chosen hardest difficulty possibly available which is Honour. You won't be allowed to save or load a little after initial intro in this mode. Enemies will have no mercy on you and Finish you in worst and saddest possible way. Are you brave enough for this suffering? You've been warned.", "Honour Mode", 256, true, 176, 0, 245, 0);
    end

    -- A LITTLE LORE NOW, A LOTTA TALE LATER

    --SCP FLYBY INITIATE.
    FLYBY_CREATE_NEW();
    FLYBY_ALLOW_INTERRUPT(TRUE);

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
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_ATTACKS, 1);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_ATTACK_PERCENTAGE, 100);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_DEFENSIVE_ACTIONS, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_RETREAT_VALUE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_BASE_UNDER_ATTACK_RETREAT, 0);

    SET_DRUM_TOWER_POS(ai_tribe_1, 30, 182);
    SET_DEFENCE_RADIUS(ai_tribe_1, 5);

    SET_MARKER_ENTRY(ai_tribe_1, 0, 16, -1, 0, 2, 0, 0);
    SET_MARKER_ENTRY(ai_tribe_1, 1, 10, -1, 0, 2, 0, 0);
    SET_MARKER_ENTRY(ai_tribe_1, 2, 14, 15, 0, 5, 0, 0);
    MARKER_ENTRIES(ai_tribe_1, 0, 1, 2, -1);
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
          Engine:addCommand_QueueMsg("Shaman, we've finished building training school!", "Worker", 36, false, 1784, 0, 229, 12*4);
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
            Engine:addCommand_QueueMsg("Ikani have been spotted!", "", 36, false, 1785, 0, 229, 12*4);
          end
        end
      end

      if (getTurn() % (1<<4) == 0) then
        if (Engine:getVar(6) == 0) then
          if (process_area(134, 84) or process_area(142, 66)) then
            Engine:setVar(6, 1);
            Engine:addCommand_QueueMsg("Chumara have been spotted!", "", 36, false, 1785, 0, 229, 12*4);
          end
        end
      end

      if (Engine:getVar(5) == 1 and Engine:getVar(6) == 1) then
        Engine:addCommand_QueueMsg("We're not alone here, as i thought. Tiyao should arrive soon or late to help us.", "Matak", 36, false, 6943, 1, 229, 12*4);
        Engine:setVar(7, 1);
        Engine:setVar(1, 2);
      end
    end

    if (getTurn() >= 720*8 and Engine:getVar(7) == 0) then
      Engine:setVar(7, 1); --if player doesn't explore around just activate attacking phase.
      Engine:setVar(1, 2);
    end

    if (Engine:getVar(7) == 1) then

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
