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

--these always have to be set on script load. (DISABLE!!)
spell_const[M_SPELL_GHOST_ARMY].Active = SPAC_OFF;
spell_const[M_SPELL_GHOST_ARMY].NetworkOnly = 1;

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
local prisons_on_level = {};

function OnSave(save_data)
  --Engine save
  Engine:saveData(save_data);
end

function OnLoad(load_data)
  --Engine
  Engine:loadData(load_data);

  game_loaded = true;
end

function OnTurn()
  if (init) then
    init = false

    set_correct_gui_menu();

    ProcessGlobalTypeList(T_BUILDING, function(t)
      if (t.Model == M_BUILDING_SPY_TRAIN) then
        if (t.Owner == ai_tribe_1 or t.Owner == ai_tribe_2) then
          local to_prison = CPrisonThing:createPrison();
          to_prison:setCoord(t.Pos.D3);
          to_prison:setYields(player_tribe, 1, 1, 1, 1);
          to_prison:setProxy(t.ThingNum);
          t.Move.BldgDrawNum = 160;
          t.DrawInfo.DrawNum = 160;
          t.Flags2 = t.Flags2 | TF2_DONT_DRAW_IN_WORLD_VIEW;
          table.insert(prisons_on_level, to_prison);
          return true;
        end
      end
      return true;
    end);
  else
    for i,Prison in ipairs(prisons_on_level) do
      if (not Prison:process()) then
        table.remove(prisons_on_level, i);
      end
    end
  end
end

function OnFrame()

end
