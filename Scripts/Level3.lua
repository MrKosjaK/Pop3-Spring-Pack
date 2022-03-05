import(Module_Game);
import(Module_System);
import(Module_PopScript);
import(Module_Defines);

local POPSCRIPT_USER_DIFFICULTY_INDEX = 1;
local current_game_difficulty = get_game_difficulty();

function OnSave(save_data)
  --todoa
end

function OnLoad(load_data)
  --todo
end

function OnTurn()
  SET_USER_VARIABLE_VALUE(TRIBE_RED, POPSCRIPT_USER_DIFFICULTY_INDEX, current_game_difficulty);
  SET_USER_VARIABLE_VALUE(TRIBE_GREEN, POPSCRIPT_USER_DIFFICULTY_INDEX, current_game_difficulty);
end
