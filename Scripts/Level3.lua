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
local ency = encyclopedia_info()

--these always have to be set on script load. (DISABLE GHOSTS!)
spell_const[M_SPELL_GHOST_ARMY].Active = SPAC_OFF;
spell_const[M_SPELL_GHOST_ARMY].NetworkOnly = 1;
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
ency[22].StrId = 689;
ency[27].StrId = 690;
ency[32].StrId = 691;

--enable wins
gns.GameParams.Flags2 = gns.GameParams.Flags2 & ~GPF2_GAME_NO_WIN;
gns.GameParams.Flags3 = gns.GameParams.Flags3 & ~GPF3_NO_GAME_OVER_PROCESS;

--features
enable_feature(F_SUPER_WARRIOR_NO_AMENDMENT); --fix fws not shooting
enable_feature(F_MINIMAP_ENEMIES); --who the hell plays with minimap off?
enable_feature(F_WILD_NO_RESPAWN); --disable wild respawning, oh boy.

--popscript indexes
local POPSCRIPT_USER_DIFFICULTY_INDEX = 1;

--engine
local Engine = CSequence:createNew();

--for saving
local current_game_difficulty = get_game_difficulty();
local honour_saved_once = false;
local init = true;

--variables local
local game_loaded = false;
local game_loaded_honour = false;

--defines
local diff_beginner = 0;
local diff_experienced = 1;
local diff_veteran = 2;
local diff_honour = 3;

--for scaling purposes
local user_scr_height = ScreenHeight();
local user_scr_width = ScreenWidth();

if (user_scr_height > 600) then
  Engine.DialogObj:setFont(3);
end

function OnSave(save_data)
  --globals save
  save_data:push_int(current_game_difficulty);

  if (getTurn() >= 12*30 and current_game_difficulty == diff_honour) then
    honour_saved_once = true;
  end

  save_data:push_bool(init);
  save_data:push_bool(honour_saved_once);
  log("[INFO] Globals saved.");

  --engine save
  Engine:saveData(save_data);
end

function OnLoad(load_data)
  --engine load
  Engine:loadData(load_data);

  --globals load
  current_game_difficulty = load_data:pop_int();

  honour_saved_once = load_data:pop_bool();
  init = load_data:pop_bool();
  log("[INFO] Globals loaded.");

  game_loaded = true;

  if (current_game_difficulty == diff_honour) then
    game_loaded_honour = true;
  end
end

function OnTurn()
  if (init) then
    init = false;

    SET_USER_VARIABLE_VALUE(TRIBE_RED, POPSCRIPT_USER_DIFFICULTY_INDEX, current_game_difficulty);
    SET_USER_VARIABLE_VALUE(TRIBE_GREEN, POPSCRIPT_USER_DIFFICULTY_INDEX, current_game_difficulty);

    --take player's ghost army
    set_player_cannot_cast(M_SPELL_GHOST_ARMY, TRIBE_BLUE);
    set_correct_gui_menu();

    if (current_game_difficulty == diff_honour) then
      Engine:addCommand_SetVar(1, 0, 4);
      Engine:addCommand_QueueMsg("Warning! You've chosen hardest difficulty possibly available which is Honour. You won't be allowed to save or load a little after initial intro in this mode. Enemies will have no mercy on you and Finish you in worst and saddest possible way. Are you brave enough for this suffering? You've been warned.", "Honour Mode", 256, true, 176, 0, 245, 0);
    end
  else
    Engine:process();

    --handle any post-loading stuff
    if (game_loaded) then
      Engine:postLoadItems();

      game_loaded = false;

      --yep.
      if (game_loaded_honour and honour_saved_once) then
        game_loaded_honour = false;
        ProcessGlobalSpecialList(TRIBE_BLUE, PEOPLELIST, function(t)
          damage_person(t, 8, 65535, TRUE);
          return true;
        end);

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
