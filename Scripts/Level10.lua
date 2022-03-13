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
