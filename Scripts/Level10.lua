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
bldg_const[M_BUILDING_SPY_TRAIN].ToolTipStrId2 = 641;

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

    if (current_game_difficulty == diff_honour) then
      Engine:addCommand_QueueMsg("Warning! You've chosen hardest difficulty possibly available which is Honour. You won't be allowed to save or load a little after initial intro in this mode. Enemies will have no mercy on you and Finish you in worst and saddest possible way. Are you brave enough for this suffering? You've been warned.", "Honour Mode", 256, true, 176, 0, 245, 0);
    end

    -- A LITTLE LORE NOW, A LOTTA TALE LATER

    --SCP FLYBY INITIATE.
    FLYBY_CREATE_NEW();
    FLYBY_ALLOW_INTERRUPT(TRUE);

    --FLYBY_SET_EVENT_POS(200, 234, 12, 96); -- MOVE TO FRONT
    --FLYBY_SET_EVENT_POS(196, 234, 108, 96); -- MOVE TO WARRIOR
    --FLYBY_SET_EVENT_POS(214, 222, 12*47, 96); -- MOVE TO PORTAL
    --FLYBY_SET_EVENT_POS(200, 234, 12*54, 96); -- MOVE TO PORTAL

    --FLYBY_SET_EVENT_ANGLE(222, 24, 96);
    --FLYBY_SET_EVENT_ANGLE(611, 136, 128);
    --FLYBY_SET_EVENT_ANGLE(1051, (12*47)+12, 96);
    --FLYBY_SET_EVENT_ANGLE(1531, (12*54)+12, 96);

    --FLYBY_START();
    --SCP FLYBY TERMINATE.
  else

    Engine:process();

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
