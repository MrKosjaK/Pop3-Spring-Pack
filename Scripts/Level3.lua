import(Module_Game);
import(Module_System);
import(Module_PopScript);
import(Module_Defines);
import(Module_Objects);
import(Module_Person);
import(Module_Features);

--features
enable_feature(F_SUPER_WARRIOR_NO_AMENDMENT); --fix fws not shooting
enable_feature(F_MINIMAP_ENEMIES); --who the hell plays with minimap off?
enable_feature(F_WILD_NO_RESPAWN); --disable wild respawning, oh boy.

local POPSCRIPT_USER_DIFFICULTY_INDEX = 1;

--for saving
local current_game_difficulty = get_game_difficulty();

--variables local
local game_loaded = false;
local game_loaded_honour = false;

--defines
local diff_beginner = 0;
local diff_experienced = 1;
local diff_veteran = 2;
local diff_honour = 3;

function OnSave(save_data)
  save_data:push_int(current_game_difficulty);
  log("[INFO] Globals saved.");

  if (current_game_difficulty == diff_honour) then
    --let's not warn player about playing on honour difficulty.
    log("WARNING! GAME WAS SAVED ON HONOUR DIFFICULTY, IF YOU'RE READING THIS, KEEP IN MIND, YOU'RE FRICKING DEAD!");
  end
end

function OnLoad(load_data)
  current_game_difficulty = load_data:pop_int();
  log("[INFO] Globals loaded.");

  game_loaded = true;

  if (current_game_difficulty == diff_honour) then
    --this is honour difficulty, play like a man or die.
    log("WARNING! GAME WAS LOADED IN HONOUR DIFFICULTY! PROCEED TO EXECUTE CHEATER.");
    game_loaded_honour = true;
  end
end

function OnTurn()
  SET_USER_VARIABLE_VALUE(TRIBE_RED, POPSCRIPT_USER_DIFFICULTY_INDEX, current_game_difficulty);
  SET_USER_VARIABLE_VALUE(TRIBE_GREEN, POPSCRIPT_USER_DIFFICULTY_INDEX, current_game_difficulty);

  --handle any post-loading stuff
  if (game_loaded) then

    game_loaded = false;

    --yep.
    if (game_loaded_honour) then
      game_loaded_honour = false;
      ProcessGlobalSpecialList(TRIBE_BLUE, PEOPLELIST, function(t)
        damage_person(t, 8, 65535, TRUE);
        return true;
      end);

      exit();
    end
  end
end
