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
local player_tribe = TRIBE_RED;
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

--timers
local BlueAttack1 = CTimer:register();
local BlueAttack2 = CTimer:register();
local BlueAttack3 = CTimer:register();
local YellowAttack1 = CTimer:register();
local YellowAttack2 = CTimer:register();
local YellowAttack3 = CTimer:register();

function OnSave(save_data)
  --Globals save
  save_data:push_int(current_game_difficulty);
  save_data:push_int(death_stored_mana);
  save_data:push_int(death_counter);

  save_data:push_bool(init);
  save_data:push_bool(death_initiated);
  log("[INFO] Globals saved.")

  --Engine save
  Engine:saveData(save_data);

  --Timers
  BlueAttack1:saveData(save_data);
  BlueAttack2:saveData(save_data);
  BlueAttack3:saveData(save_data);
  YellowAttack1:saveData(save_data);
  YellowAttack2:saveData(save_data);
  YellowAttack3:saveData(save_data);
  log("[INFO] Timers saved.");

  if (current_game_difficulty == diff_honour) then
    --let's not warn player about playing on honour difficulty.
    log("WARNING! GAME WAS SAVED ON HONOUR DIFFICULTY, IF YOU'RE READING THIS, KEEP IN MIND, YOU'RE FRICKING DEAD!");
  end
end

function OnLoad(load_data)
  --Timers
  YellowAttack3:loadData(load_data);
  YellowAttack2:loadData(load_data);
  YellowAttack1:loadData(load_data);
  BlueAttack3:loadData(load_data);
  BlueAttack2:loadData(load_data);
  BlueAttack1:loadData(load_data);
  log("[INFO] Timers loaded.");

  --Engine
  Engine:loadData(load_data);

  --Globals load
  death_counter = load_data:pop_int();
  death_stored_mana = load_data:pop_int();
  current_game_difficulty = load_data:pop_int();

  death_initiated = load_data:pop_bool();
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

    --fix wildies
    FIX_WILD_IN_AREA(156, 78, 11);
    FIX_WILD_IN_AREA(182, 110, 11);

    --delete initial brave lol
    ProcessGlobalSpecialList(player_tribe, PEOPLELIST, function(t)
      delete_thing_type(t);
      return true;
    end)

    --portals (decor)
    local p2 = createThing(T_SCENERY, M_SCENERY_TOP_LEVEL_SCENERY, TRIBE_HOSTBOT, marker_to_coord3d_centre(0), false, false);
    set_map_elem_object_shadow(world_coord2d_to_map_ptr(p2.Pos.D2), 8);
    set_square_map_params(world_coord2d_to_map_idx(p2.Pos.D2), 2, TRUE);
    p2.DrawInfo.DrawNum = 158;
    p2.DrawInfo.DrawTableIdx = 2;
    p2.DrawInfo.Flags = p2.DrawInfo.Flags | DF_POINTABLE;
    p2.AngleXZ = 1536 - 128;

    --setup alliances
    set_players_allied(player_tribe, player_ally_tribe);
    set_players_allied(player_ally_tribe, player_tribe);

    set_players_allied(ai_tribe_2, ai_tribe_1);
    set_players_allied(ai_tribe_1, ai_tribe_2);

    set_players_allied(player_ally_tribe, ai_tribe_1); -- fws shot shamans in cutscene oh boi
    set_players_allied(player_ally_tribe, ai_tribe_2);

    --disable red's CoR
    set_player_reinc_site_off(pp[player_tribe]);
    mark_reincarnation_site_mes(gs.Players[player_tribe].ReincarnSiteCoord, OWNER_NONE, UNMARK);

    --disable cyan's CoR
    set_player_reinc_site_off(pp[TRIBE_CYAN]);
    mark_reincarnation_site_mes(gs.Players[TRIBE_CYAN].ReincarnSiteCoord, OWNER_NONE, UNMARK);

    --give player ghost army
    set_player_can_cast(M_SPELL_GHOST_ARMY, player_tribe);
    set_correct_gui_menu();

    -- CUTSCENE PART --
    --Engine:addCommand_CinemaRaise(0);

    --Move 10 braves
    Engine:hidePanel();
    Engine:addCommand_CinemaRaise(0);
    Engine:addCommand_SpawnThings(1, 2, T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(0), 2);
    Engine:addCommand_GotoPoint(1, marker_to_coord2d_centre(13), 1);
    Engine:addCommand_ClearThingBuf(1, 0);
    Engine:addCommand_SpawnThings(1, 2, T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(0), 2);
    Engine:addCommand_GotoPoint(1, marker_to_coord2d_centre(13), 1);
    Engine:addCommand_ClearThingBuf(1, 0);
    Engine:addCommand_SpawnThings(1, 2, T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(0), 2);
    Engine:addCommand_GotoPoint(1, marker_to_coord2d_centre(13), 1);
    Engine:addCommand_ClearThingBuf(1, 0);
    Engine:addCommand_SpawnThings(1, 2, T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(0), 2);
    Engine:addCommand_GotoPoint(1, marker_to_coord2d_centre(13), 1);
    Engine:addCommand_ClearThingBuf(1, 0);
    Engine:addCommand_SpawnThings(1, 2, T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(0), 2);
    Engine:addCommand_GotoPoint(1, marker_to_coord2d_centre(13), 1);
    Engine:addCommand_ClearThingBuf(1, 0);

    --Move 10 warriors and 10 firewarriors
    Engine:addCommand_SpawnThings(1, 5, T_PERSON, M_PERSON_WARRIOR, player_tribe, marker_to_coord2d_centre(0), 2);
    Engine:addCommand_GotoPoint(1, marker_to_coord2d_centre(11), 1);
    Engine:addCommand_ClearThingBuf(1, 0);
    Engine:addCommand_SpawnThings(1, 5, T_PERSON, M_PERSON_SUPER_WARRIOR, player_tribe, marker_to_coord2d_centre(0), 2);
    Engine:addCommand_GotoPoint(1, marker_to_coord2d_centre(11), 1);
    Engine:addCommand_ClearThingBuf(1, 0);
    Engine:addCommand_SpawnThings(1, 5, T_PERSON, M_PERSON_WARRIOR, player_tribe, marker_to_coord2d_centre(0), 2);
    Engine:addCommand_GotoPoint(1, marker_to_coord2d_centre(11), 1);
    Engine:addCommand_ClearThingBuf(1, 0);
    Engine:addCommand_SpawnThings(1, 5, T_PERSON, M_PERSON_SUPER_WARRIOR, player_tribe, marker_to_coord2d_centre(0), 2);
    Engine:addCommand_GotoPoint(1, marker_to_coord2d_centre(11), 1);
    Engine:addCommand_ClearThingBuf(1, 0);

    --cyan troops bind EARLIER.
    Engine:addCommand_AddThings(6, 9, T_PERSON, M_PERSON_WARRIOR, player_ally_tribe, marker_to_coord2d_centre(35), 1, 0);
    Engine:addCommand_PatrolArea(6, marker_to_coord2d_centre(35), 4, 0);
    Engine:addCommand_AddThings(7, 9, T_PERSON, M_PERSON_WARRIOR, player_ally_tribe, marker_to_coord2d_centre(36), 1, 0);
    Engine:addCommand_PatrolArea(7, marker_to_coord2d_centre(36), 4, 0);

    --Move shaman
    Engine:addCommand_SpawnThing(2, T_PERSON, M_PERSON_MEDICINE_MAN, player_tribe, marker_to_coord2d_centre(0), 2);
    Engine:addCommand_GotoPoint(2, marker_to_coord2d_centre(12), 12*14);

    --Messages part
    Engine:addCommand_QueueMsg("Gods were on our side, Ikani's and Chumara's settlements have been destroyed.", "Dakini", 48, false, 6903, 1, 245, 12*2);

    --Cyan shaman faces red's shaman
    Engine:addCommand_AngleThing(getShaman(player_ally_tribe).ThingNum, 1024, 12);

    --Tiyao saying something
    Engine:addCommand_QueueMsg("That is indeed a great news! I'm glad you've arrived safe and alive!", "Tiyao", 48, false, 6883, 2, 146, 12*12);
    Engine:addCommand_QueueMsg("But still, it's not an end of our hassle. My tribe is being attacked periodically by Ikani and Chumara once again, and i cannot counter them alone. But since you're here, together we should give them a fight back!", "Tiyao", 48, false, 6883, 2, 146, 12*12);

    --Dakini speech
    Engine:addCommand_QueueMsg("I've brought my own followers to help you assist against enemy forces.", "Dakini", 48, false, 6903, 1, 245, 12*18);

    --Tiyao senses something sus and walks at front
    Engine:addCommand_MoveThing(getShaman(ai_tribe_1).ThingNum, marker_to_coord2d_centre(28), 0);
    Engine:addCommand_QueueMsg("!", "Tiyao", 48, false, 6883, 2, 146, 12);
    Engine:addCommand_AngleThing(getShaman(player_ally_tribe).ThingNum, 0, 12);
    Engine:addCommand_MoveThing(getShaman(player_ally_tribe).ThingNum, marker_to_coord2d_centre(24), 12);

    local multiplier = current_game_difficulty; if (multiplier > 2) then multiplier = 2; end
    local difficulty_scaling = 3 + multiplier;
    --Ikani's troops moving out
    Engine:addCommand_SpawnThings(1, difficulty_scaling, T_PERSON, M_PERSON_WARRIOR, ai_tribe_1, marker_to_coord2d_centre(33), 0);
    Engine:addCommand_PatrolArea(1, marker_to_coord2d_centre(25), 5, 12);
    Engine:addCommand_ClearThingBuf(1, 0);

    Engine:addCommand_SpawnThings(1, difficulty_scaling, T_PERSON, M_PERSON_SUPER_WARRIOR, ai_tribe_1, marker_to_coord2d_centre(33), 0);
    Engine:addCommand_PatrolArea(1, marker_to_coord2d_centre(26), 5, 12);
    Engine:addCommand_ClearThingBuf(1, 0);

    Engine:addCommand_SpawnThings(1, difficulty_scaling, T_PERSON, M_PERSON_WARRIOR, ai_tribe_1, marker_to_coord2d_centre(33), 0);
    Engine:addCommand_PatrolArea(1, marker_to_coord2d_centre(27), 5, 12);
    Engine:addCommand_ClearThingBuf(1, 0);

    --Chumara's troops moving out
    Engine:addCommand_MoveThing(getShaman(ai_tribe_2).ThingNum, marker_to_coord2d_centre(32), 0);

    Engine:addCommand_SpawnThings(1, difficulty_scaling, T_PERSON, M_PERSON_WARRIOR, ai_tribe_2, marker_to_coord2d_centre(34), 0);
    Engine:addCommand_PatrolArea(1, marker_to_coord2d_centre(29), 5, 12);
    Engine:addCommand_ClearThingBuf(1, 0);

    Engine:addCommand_SpawnThings(1, difficulty_scaling, T_PERSON, M_PERSON_SUPER_WARRIOR, ai_tribe_2, marker_to_coord2d_centre(34), 0);
    Engine:addCommand_PatrolArea(1, marker_to_coord2d_centre(30), 5, 12);
    Engine:addCommand_ClearThingBuf(1, 0);

    Engine:addCommand_SpawnThings(1, difficulty_scaling, T_PERSON, M_PERSON_WARRIOR, ai_tribe_2, marker_to_coord2d_centre(34), 0);
    Engine:addCommand_PatrolArea(1, marker_to_coord2d_centre(31), 5, 12);
    Engine:addCommand_ClearThingBuf(1, 12*20);

    --face shamans
    Engine:addCommand_AngleThing(getShaman(ai_tribe_1).ThingNum, 512 + 256, 0);
    Engine:addCommand_AngleThing(getShaman(ai_tribe_2).ThingNum, 1024 + 256, 0);
    Engine:addCommand_GotoPoint(2, marker_to_coord2d_centre(37), 1);

    --Chumara's speech
    Engine:addCommand_QueueMsg("Tiyao! <br> We're giving you a last chance to surrender and give us your knowledge of magical shield, none of your followers will be harmed.", "Chumara", 48, false, 6923, 1, 238, 12*12);

    --Ikani's speech
    Engine:addCommand_QueueMsg("Stay back Dakini, it is none of your business. We have no intention to fight with you.", "Ikani", 48, false, 6883, 1, 222, 12*10);

    --Tiyao's speech
    Engine:addCommand_AngleThing(getShaman(player_ally_tribe).ThingNum, 1024, 6);
    Engine:addCommand_QueueMsg("Don't listen to them.", "Tiyao", 48, false, 6883, 2, 146, 12*4);
    Engine:addCommand_AngleThing(getShaman(player_ally_tribe).ThingNum, 180, 2);
    --Engine:addCommand_AngleThing(getShaman(player_tribe).ThingNum, 0, 2);
    Engine:addCommand_QueueMsg("I'm sorry to disappoint you, but i'm not giving you anything for free. If we're trading then you should be giving something in exchange.", "Tiyao", 48, false, 6883, 2, 146, 12*7);

    --Ikani's speech
    Engine:addCommand_QueueMsg("You fool, who are you trying to talk with? Is your mind fogged?", "Ikani", 48, false, 6883, 1, 222, 12*14);

    --Chumara's speech
    Engine:addCommand_AngleThing(getShaman(ai_tribe_2).ThingNum, 1536, 2);
    Engine:addCommand_QueueMsg("Shush Ikani.", "Chumara", 48, false, 6923, 1, 238, 12*6); --yeah stfu you stupid nobody cares
    Engine:addCommand_AngleThing(getShaman(ai_tribe_2).ThingNum, 1024 + 256, 2);
    Engine:addCommand_QueueMsg("It seems that you've chosen your destiny. I'm afraid, i can't help but make sure to exterminate your tribe.", "Chumara", 48, false, 6923, 1, 238, 12*11);
    Engine:addCommand_QueueMsg("Prepare for battle!", "Chumara", 48, false, 6923, 1, 238, 6);
    Engine:addCommand_MoveThing(getShaman(ai_tribe_1).ThingNum, marker_to_coord2d_centre(38), 1);
    Engine:addCommand_MoveThing(getShaman(ai_tribe_2).ThingNum, marker_to_coord2d_centre(39), 12*1);
    Engine:addCommand_MoveThing(getShaman(player_ally_tribe).ThingNum, marker_to_coord2d_centre(13), 2);
    Engine:addCommand_GotoPoint(2, marker_to_coord2d_centre(11), 1);
    Engine:addCommand_ClearThingBuf(2, 0);

    --Tiyao casts magical shield on units
    Engine:addCommand_CastSpellAt(player_ally_tribe, M_SPELL_SHIELD, marker_to_coord2d_centre(35), 12);
    Engine:addCommand_CastSpellAt(player_ally_tribe, M_SPELL_SHIELD, marker_to_coord2d_centre(36), 12);

    --epic battle part
    --blue troops bind
    Engine:addCommand_AddThings(3, 16, T_PERSON, M_PERSON_WARRIOR, ai_tribe_1, marker_to_coord2d_centre(25), 1, 1);
    Engine:addCommand_AddThings(3, 16, T_PERSON, M_PERSON_SUPER_WARRIOR, ai_tribe_1, marker_to_coord2d_centre(26), 1, 1);
    Engine:addCommand_AddThings(3, 16, T_PERSON, M_PERSON_WARRIOR, ai_tribe_1, marker_to_coord2d_centre(27), 1, 1);

    --yellow troops bind
    Engine:addCommand_AddThings(4, 16, T_PERSON, M_PERSON_WARRIOR, ai_tribe_2, marker_to_coord2d_centre(29), 1, 1);
    Engine:addCommand_AddThings(4, 16, T_PERSON, M_PERSON_SUPER_WARRIOR, ai_tribe_2, marker_to_coord2d_centre(30), 1, 1);
    Engine:addCommand_AddThings(4, 16, T_PERSON, M_PERSON_WARRIOR, ai_tribe_2, marker_to_coord2d_centre(31), 1, 0);

    --red troops bind
    Engine:addCommand_AddThings(5, 10, T_PERSON, M_PERSON_WARRIOR, player_tribe, marker_to_coord2d_centre(11), 1, 0);
    Engine:addCommand_AddThings(5, 10, T_PERSON, M_PERSON_SUPER_WARRIOR, player_tribe, marker_to_coord2d_centre(11), 1, 0);
    Engine:addCommand_BreakAlliance(player_ally_tribe, ai_tribe_1, 0);
    Engine:addCommand_BreakAlliance(player_ally_tribe, ai_tribe_2, 0);

    --command troops!
    Engine:addCommand_AttackPos(5, marker_to_coord2d_centre(32), 8, 12);
    Engine:addCommand_AttackPos(7, marker_to_coord2d_centre(28), 8, 2);
    Engine:addCommand_AttackPos(6, marker_to_coord2d_centre(28), 8, 2);
    Engine:addCommand_AttackPos(3, marker_to_coord2d_centre(24), 0);
    Engine:addCommand_AttackPos(4, marker_to_coord2d_centre(37), 0);

    --while they're fighting let's build some stuff!!!!
    Engine:addCommand_PlacePlan(M_BUILDING_DRUM_TOWER, G_RANDOM(4), player_tribe, marker_to_coord2d_centre(14), 2);
    Engine:addCommand_AddThings(1, 2, T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(13), 1, 2);
    Engine:addCommand_ChopTree(1, marker_to_coord2d_centre(15), 1, marker_to_coord2d_centre(14), 2);
    Engine:addCommand_ClearThingBuf(1, 18);

    Engine:addCommand_PlacePlan(1, G_RANDOM(4), player_tribe, marker_to_coord2d_centre(17), 2);
    Engine:addCommand_AddThings(1, 2, T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(13), 1, 2);
    Engine:addCommand_ChopTree(1, marker_to_coord2d_centre(16), 1, marker_to_coord2d_centre(17), 2);
    Engine:addCommand_ClearThingBuf(1, 18);

    Engine:addCommand_PlacePlan(1, G_RANDOM(4), player_tribe, marker_to_coord2d_centre(18), 2);
    Engine:addCommand_AddThings(1, 2, T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(13), 1, 2);
    Engine:addCommand_ChopTree(1, marker_to_coord2d_centre(21), 1, marker_to_coord2d_centre(18), 2);
    Engine:addCommand_ClearThingBuf(1, 18);

    Engine:addCommand_PlacePlan(1, G_RANDOM(4), player_tribe, marker_to_coord2d_centre(19), 2);
    Engine:addCommand_AddThings(1, 2, T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(13), 1, 2);
    Engine:addCommand_ChopTree(1, marker_to_coord2d_centre(22), 1, marker_to_coord2d_centre(19), 2);
    Engine:addCommand_ClearThingBuf(1, 18);

    Engine:addCommand_PlacePlan(1, G_RANDOM(4), player_tribe, marker_to_coord2d_centre(20), 2);
    Engine:addCommand_AddThings(1, 2, T_PERSON, M_PERSON_BRAVE, player_tribe, marker_to_coord2d_centre(13), 1, 2);
    Engine:addCommand_ChopTree(1, marker_to_coord2d_centre(23), 1, marker_to_coord2d_centre(20), 2);
    Engine:addCommand_ClearThingBuf(1, (12*22)-129);
    --finish building :o!!!

    Engine:addCommand_SetVar(1, 1, 9);
    Engine:addCommand_CinemaHide(15);
    Engine:addCommand_ShowPanel(12*2);

    --Tiyao's speech
    Engine:addCommand_QueueMsg("We were victorious! And that is what i call a splendid team work!", "Tiyao", 48, false, 6883, 2, 146, 12*4);
    Engine:addCommand_GotoPoint(5, marker_to_coord2d_centre(12), 2);
    Engine:addCommand_GotoPoint(6, marker_to_coord2d_centre(12), 2);
    Engine:addCommand_GotoPoint(7, marker_to_coord2d_centre(12), 2);
    Engine:addCommand_ClearThingBuf(1, 0);
    Engine:addCommand_ClearThingBuf(2, 0);
    Engine:addCommand_ClearThingBuf(3, 0);
    Engine:addCommand_ClearThingBuf(4, 0);
    Engine:addCommand_ClearThingBuf(5, 0);
    Engine:addCommand_ClearThingBuf(6, 0);
    Engine:addCommand_ClearThingBuf(7, 0);
    Engine:addCommand_QueueMsg("I'm actually impressed you posses such powerful magic! Where did one find it?", "Dakini", 48, false, 6903, 1, 245, 12*5);
    Engine:addCommand_QueueMsg("Her almighty Matak has granted me the knowledge.", "Tiyao", 48, false, 6883, 2, 146, 12*4);
    Engine:addCommand_QueueMsg("Alright, we should focus on our foes first. If you need your followers to be magical shielded, bring at least 6 of them near me.", "Tiyao", 48, false, 6883, 2, 146, 12*4);
    Engine:addCommand_QueueMsg("And note, it takes a while for me to actually accumulate enough mana to use one.", "Tiyao", 48, false, 6883, 2, 146, 12*4);
    Engine:addCommand_QueueMsg("Understood.", "Dakini", 48, false, 6903, 1, 245, 12*4);
    Engine:addCommand_QueueMsg("Shaman. <bp> Tiyao will be willing to help your followers by magical shielding them. <bp> Group at least 6 units near her and she'll cast spell on them. <br> Defeat your foes while keeping shamans alive.", "Objective", 256, true, 174, 0, 128, 0);
    Engine:addCommand_SetVar(2, 1, 0);
    -- CUTSCENE PART --

    --FLYBY Part, i love procrastinating sometimes (all the time)
    FLYBY_CREATE_NEW();
    FLYBY_ALLOW_INTERRUPT(FALSE);


    FLYBY_SET_EVENT_POS(138, 138, 12, 122); --MOVE TO TIYAO
    FLYBY_SET_EVENT_POS(142, 162, 12*58, 12*7); --MOVE TO FRONT
    FLYBY_SET_EVENT_POS(130, 184, 12*60, 12*7); --MOVE TO BLUE's FRONT
    FLYBY_SET_EVENT_POS(156, 184, 12*66, 12*7); --MOVE TO YELLOW's FRONT
    FLYBY_SET_EVENT_POS(142, 162, 12*72, 12*7); --MOVE TO CYAN's FRONT
    FLYBY_SET_EVENT_POS(138, 138, (12*156), 96); --MOVE TO CYAN's BASE

    FLYBY_SET_EVENT_ANGLE(2047, 11, 96); --MOVE TO TIYAO
    FLYBY_SET_EVENT_ANGLE(256, 103, 96);
    FLYBY_SET_EVENT_ANGLE(0, (12*58) - 4, 96); --MOVE TO FRONT
    FLYBY_SET_EVENT_ANGLE(1800, (12*60) - 4, 96); --MOVE TO BLUE's FRONT
    FLYBY_SET_EVENT_ANGLE(256, (12*66) - 4, 96); --MOVE TO YELLOW's FRONT
    FLYBY_SET_EVENT_ANGLE(1536, (12*72) - 4, 96); --MOVE TO CYAN's FRONT
    FLYBY_SET_EVENT_ANGLE(644, (12*82) - 4, 96);
    FLYBY_SET_EVENT_ANGLE(211, (12*92) - 4, 96);
    FLYBY_SET_EVENT_ANGLE(0, (12*102) - 4, 96);
    FLYBY_SET_EVENT_ANGLE(1725, (12*112) - 4, 96);
    FLYBY_SET_EVENT_ANGLE(1325, (12*122) - 4, 96);
    FLYBY_SET_EVENT_ANGLE(925, (12*132) - 4, 96);
    FLYBY_SET_EVENT_ANGLE(525, (12*142) - 4, 96);
    FLYBY_SET_EVENT_ANGLE(125, (12*152) - 4, 96);
    FLYBY_SET_EVENT_ANGLE(1024, (12*156) - 4, 96);--MOVE TO CYAN's BASE

    FLYBY_START();

    --BLUE TRIBE
    set_player_can_build(M_BUILDING_TEPEE, ai_tribe_1);
    set_player_can_build(M_BUILDING_DRUM_TOWER, ai_tribe_1);
    set_player_can_build(M_BUILDING_WARRIOR_TRAIN, ai_tribe_1)
    set_player_can_build(M_BUILDING_SUPER_TRAIN, ai_tribe_1);
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
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_HOUSE_PERCENTAGE, 48);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_TRAINS, 1);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_SUPER_WARRIOR_TRAINS, 1);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_TRAIN_AT_ONCE, 4);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_ATTACKS, 3);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_ATTACK_PERCENTAGE, 100);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_DEFENSIVE_ACTIONS, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_RETREAT_VALUE, 0);
    WRITE_CP_ATTRIB(ai_tribe_1, ATTR_BASE_UNDER_ATTACK_RETREAT, 0);

    SET_DRUM_TOWER_POS(ai_tribe_1, 74, 214);
    SET_DEFENCE_RADIUS(ai_tribe_1, 5);

    SET_MARKER_ENTRY(ai_tribe_1, 0, 40, -1, 0, 2, 0, 0);
    SET_MARKER_ENTRY(ai_tribe_1, 1, 41, -1, 0, 2, 0, 0);
    SET_MARKER_ENTRY(ai_tribe_1, 2, 42, 43, 0, 0, 2, 0);
    SET_MARKER_ENTRY(ai_tribe_1, 3, 44, 45, 0, 0, 2, 0);
    MARKER_ENTRIES(ai_tribe_1, 0, 1, 2, -1);
    MARKER_ENTRIES(ai_tribe_1, 3, -1, -1, -1);

    --YELLOW TRIBE
    set_player_can_build(M_BUILDING_TEPEE, ai_tribe_2);
    set_player_can_build(M_BUILDING_DRUM_TOWER, ai_tribe_2);
    set_player_can_build(M_BUILDING_WARRIOR_TRAIN, ai_tribe_2)
    set_player_can_build(M_BUILDING_SUPER_TRAIN, ai_tribe_2);
    set_player_can_cast(M_SPELL_BLAST, ai_tribe_2);
    set_player_can_cast(M_SPELL_INSECT_PLAGUE, ai_tribe_2);
    set_player_can_cast(M_SPELL_CONVERT_WILD, ai_tribe_2);
    set_player_can_cast(M_SPELL_HYPNOTISM, ai_tribe_2);

    computer_init_player(pp[ai_tribe_2]);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_CONSTRUCT_BUILDING);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_AUTO_ATTACK);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_TRAIN_PEOPLE);
    STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_POPULATE_DRUM_TOWER);
    SET_ATTACK_VARIABLE(ai_tribe_2, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_BUILDINGS_ON_GO, 3);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_HOUSE_PERCENTAGE, 42);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_TRAINS, 1);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_TRAINS, 1);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_TRAIN_AT_ONCE, 4);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_ATTACKS, 3);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_ATTACK_PERCENTAGE, 100);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_DEFENSIVE_ACTIONS, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_RETREAT_VALUE, 0);
    WRITE_CP_ATTRIB(ai_tribe_2, ATTR_BASE_UNDER_ATTACK_RETREAT, 0);

    SET_DRUM_TOWER_POS(ai_tribe_2, 202, 200);
    SET_DEFENCE_RADIUS(ai_tribe_2, 5);

    SET_MARKER_ENTRY(ai_tribe_2, 0, 46, -1, 0, 0, 2, 0);
    SET_MARKER_ENTRY(ai_tribe_2, 1, 47, -1, 0, 0, 2, 0);
    SET_MARKER_ENTRY(ai_tribe_2, 2, 48, 49, 0, 0, 3, 0);
    SET_MARKER_ENTRY(ai_tribe_2, 3, 50, 51, 0, 0, 2, 0);
    MARKER_ENTRIES(ai_tribe_2, 0, 1, 2, -1);
    MARKER_ENTRIES(ai_tribe_2, 3, -1, -1, -1);

    --CYAN TRIBE
    set_player_can_build(M_BUILDING_TEPEE, player_ally_tribe);
    set_player_can_build(M_BUILDING_DRUM_TOWER, player_ally_tribe);
    set_player_can_build(M_BUILDING_WARRIOR_TRAIN, player_ally_tribe)
    set_player_can_build(M_BUILDING_SUPER_TRAIN, player_ally_tribe);
    set_player_can_cast(M_SPELL_BLAST, player_ally_tribe);
    set_player_can_cast(M_SPELL_INSECT_PLAGUE, player_ally_tribe);
    set_player_can_cast(M_SPELL_CONVERT_WILD, player_ally_tribe);

    computer_init_player(pp[player_ally_tribe]);
    STATE_SET(player_ally_tribe, TRUE, CP_AT_TYPE_CONSTRUCT_BUILDING);
    STATE_SET(player_ally_tribe, TRUE, CP_AT_TYPE_AUTO_ATTACK);
    STATE_SET(player_ally_tribe, TRUE, CP_AT_TYPE_TRAIN_PEOPLE);
    STATE_SET(player_ally_tribe, TRUE, CP_AT_TYPE_POPULATE_DRUM_TOWER);
    SET_ATTACK_VARIABLE(player_ally_tribe, 0);
    WRITE_CP_ATTRIB(player_ally_tribe, ATTR_MAX_BUILDINGS_ON_GO, 2);
    WRITE_CP_ATTRIB(player_ally_tribe, ATTR_HOUSE_PERCENTAGE, 12);
    WRITE_CP_ATTRIB(player_ally_tribe, ATTR_PREF_WARRIOR_TRAINS, 1);
    WRITE_CP_ATTRIB(player_ally_tribe, ATTR_PREF_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(player_ally_tribe, ATTR_PREF_SUPER_WARRIOR_TRAINS, 1);
    WRITE_CP_ATTRIB(player_ally_tribe, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 0);
    WRITE_CP_ATTRIB(player_ally_tribe, ATTR_MAX_TRAIN_AT_ONCE, 4);
    WRITE_CP_ATTRIB(player_ally_tribe, ATTR_MAX_ATTACKS, 3);
    WRITE_CP_ATTRIB(player_ally_tribe, ATTR_ATTACK_PERCENTAGE, 100);
    WRITE_CP_ATTRIB(player_ally_tribe, ATTR_MAX_DEFENSIVE_ACTIONS, 0);
    WRITE_CP_ATTRIB(player_ally_tribe, ATTR_RETREAT_VALUE, 0);
    WRITE_CP_ATTRIB(player_ally_tribe, ATTR_BASE_UNDER_ATTACK_RETREAT, 0);

    SET_DRUM_TOWER_POS(player_ally_tribe, 148, 120);
    SET_DEFENCE_RADIUS(player_ally_tribe, 5);

    SET_MARKER_ENTRY(player_ally_tribe, 0, 2, 3, 0, 7, 0, 0);
    SET_MARKER_ENTRY(player_ally_tribe, 1, 4, 5, 0, 0, 2, 0);
    SET_MARKER_ENTRY(player_ally_tribe, 2, 6, 7, 0, 0, 2, 0);
    MARKER_ENTRIES(player_ally_tribe, 0, 1, 2, -1);

    Engine:setupMagicalShield(player_ally_tribe, SPELL_COST(M_SPELL_SHIELD) - ((SPELL_COST(M_SPELL_SHIELD) >> 1) >> multiplier), 5- multiplier);
  else
    Engine:process();

    if ((getTurn() & (1 << 5)-1) == 0 and Engine:getVar(2) == 1 and Engine.Magic.Charges > 0) then
      local s = getShaman(player_ally_tribe);
      if (s ~= nil) then
        local break_now = false;
        SearchMapCells(SQUARE, 0, 0, 1, world_coord2d_to_map_idx(s.Pos.D2), function(me)
          if (not me.MapWhoList:isEmpty()) then
            if (not break_now) then
              me.MapWhoList:processList(function(t)
                if (t.Type == T_PERSON) then
                  if (t.Owner == player_tribe and (t.Flags3 & TF3_SHIELD_ACTIVE) == 0 and (t.Flags2 & TF2_THING_IS_A_GHOST_PERSON) == 0) then
                    Engine.Magic.Charges = Engine.Magic.Charges - 1;
                    createThing(T_SPELL, M_SPELL_SHIELD, player_ally_tribe, t.Pos.D3, false, false);
                    break_now = true;
                    return false;
                  end
                end
                if (break_now) then return false; else return true; end
              end);
            end
          end
          if (break_now) then return false; else return true; end
        end);
      end
    end

    if ((getTurn() & (1 << 2)-1) == 0 and Engine:getVar(2) == 1) then
      Engine.Magic:process(current_game_difficulty);
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

    if (Engine:getVar(1) == 1) then --post init?
      Engine:setVar(1, 2);
      SHAMAN_DEFEND(player_ally_tribe, 148, 120, TRUE);
      SHAMAN_DEFEND(ai_tribe_1, 74, 214, TRUE);
      SHAMAN_DEFEND(ai_tribe_2, 202, 200, TRUE);
      STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_DEFEND);
      STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_DEFEND_BASE);
      STATE_SET(ai_tribe_1, TRUE, CP_AT_TYPE_SUPER_DEFEND);
      WRITE_CP_ATTRIB(ai_tribe_1, ATTR_USE_PREACHER_FOR_DEFENCE, 1);
      STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_DEFEND);
      STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_DEFEND_BASE);
      STATE_SET(ai_tribe_2, TRUE, CP_AT_TYPE_SUPER_DEFEND);
      WRITE_CP_ATTRIB(ai_tribe_2, ATTR_USE_PREACHER_FOR_DEFENCE, 1);
      STATE_SET(player_ally_tribe, TRUE, CP_AT_TYPE_DEFEND);
      STATE_SET(player_ally_tribe, TRUE, CP_AT_TYPE_DEFEND_BASE);
      STATE_SET(player_ally_tribe, TRUE, CP_AT_TYPE_SUPER_DEFEND);
      WRITE_CP_ATTRIB(player_ally_tribe, ATTR_USE_PREACHER_FOR_DEFENCE, 1);

      BlueAttack1:setTime(2040, 1024);
      BlueAttack2:setTime(2040, 1024);
      BlueAttack3:setTime(2200, 1024);
      YellowAttack1:setTime(1984, 1024);
      YellowAttack2:setTime(2100, 1024);
      YellowAttack3:setTime(2200, 1024);

      if (current_game_difficulty < diff_experienced) then
        SET_SPELL_ENTRY(player_ally_tribe, 0, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> 4, 128, 2, 1);
        SET_SPELL_ENTRY(player_ally_tribe, 1, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> 4, 128, 2, 0);

        WRITE_CP_ATTRIB(player_ally_tribe, ATTR_SHAMEN_BLAST, 8);

        SET_BUCKET_USAGE(player_ally_tribe, TRUE);
        SET_BUCKET_COUNT_FOR_SPELL(player_ally_tribe, M_SPELL_CONVERT_WILD, 1);
        SET_BUCKET_COUNT_FOR_SPELL(player_ally_tribe, M_SPELL_BLAST, 1);
        SET_BUCKET_COUNT_FOR_SPELL(player_ally_tribe, M_SPELL_INSECT_PLAGUE, 8);
      end

      if (current_game_difficulty >= diff_experienced) then
        SET_SPELL_ENTRY(ai_tribe_1, 0, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> 4, 128, 2, 1);
        SET_SPELL_ENTRY(ai_tribe_1, 1, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> 4, 128, 2, 0);
        SET_SPELL_ENTRY(ai_tribe_2, 0, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> 4, 128, 2, 1);
        SET_SPELL_ENTRY(ai_tribe_2, 1, M_SPELL_INSECT_PLAGUE, SPELL_COST(M_SPELL_INSECT_PLAGUE) >> 4, 128, 2, 0);

        WRITE_CP_ATTRIB(ai_tribe_1, ATTR_MAX_TRAIN_AT_ONCE, 5 + current_game_difficulty);
        WRITE_CP_ATTRIB(ai_tribe_2, ATTR_MAX_TRAIN_AT_ONCE, 5 + current_game_difficulty);

        SET_BUCKET_USAGE(ai_tribe_1, TRUE);
        SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_1, M_SPELL_CONVERT_WILD, 1);
        SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_1, M_SPELL_BLAST, 1);
        SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_1, M_SPELL_INSECT_PLAGUE, 8);

        SET_BUCKET_USAGE(ai_tribe_2, TRUE);
        SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_2, M_SPELL_CONVERT_WILD, 1);
        SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_2, M_SPELL_BLAST, 1);
        SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_2, M_SPELL_INSECT_PLAGUE, 8);

        WRITE_CP_ATTRIB(ai_tribe_1, ATTR_SHAMEN_BLAST, 16);
        WRITE_CP_ATTRIB(ai_tribe_2, ATTR_SHAMEN_BLAST, 16);

        if (current_game_difficulty >= diff_veteran) then
          SET_SPELL_ENTRY(ai_tribe_1, 2, M_SPELL_HYPNOTISM, SPELL_COST(M_SPELL_HYPNOTISM) >> 4, 128, 5, 1);
          SET_SPELL_ENTRY(ai_tribe_1, 3, M_SPELL_HYPNOTISM, SPELL_COST(M_SPELL_HYPNOTISM) >> 4, 128, 5, 0);
          SET_SPELL_ENTRY(ai_tribe_2, 2, M_SPELL_HYPNOTISM, SPELL_COST(M_SPELL_HYPNOTISM) >> 4, 128, 5, 1);
          SET_SPELL_ENTRY(ai_tribe_2, 3, M_SPELL_HYPNOTISM, SPELL_COST(M_SPELL_HYPNOTISM) >> 4, 128, 5, 0);

          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_SHAMEN_BLAST, 8);
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_SHAMEN_BLAST, 8);

          TARGET_S_WARRIORS(ai_tribe_1);
          TARGET_S_WARRIORS(ai_tribe_2);

          SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_2, M_SPELL_HYPNOTISM, 10);
          SET_BUCKET_COUNT_FOR_SPELL(ai_tribe_1, M_SPELL_HYPNOTISM, 10);

          SET_MARKER_ENTRY(ai_tribe_1, 4, 54, 55, 0, 6, 6, 0);
          SET_MARKER_ENTRY(ai_tribe_2, 4, 52, 53, 0, 6, 6, 0);
        end
      end
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

    if (Engine:getVar(3) == 1 and Engine:getVar(4) == 1 and Engine:getVar(5) == 0 and Engine:getVar(6) == 0) then
      Engine:setVar(6, 1);

      Engine:addCommand_QueueMsg("Foes once again have been defeated... But... Their magic..? What is that?", "Dakini", 48, false, 6903, 1, 245, 12*4);
      Engine:addCommand_QueueMsg("Ah of course, their manipulative possesion of spell - hypnotism!", "Tiyao", 48, false, 6883, 2, 146, 12*4);
      Engine:addCommand_QueueMsg("This is an absurd...", "Dakini", 48, false, 6903, 1, 245, 12*4);
      Engine:addCommand_QueueMsg("Hmm... Well, do not boil mind with that, instead, i'll share knowledge of magical shield. <bp> This shouldn't take a lot of time for you to fully understand it. <bp> We're moving on.", "Tiyao", 48, false, 6883, 2, 146, 12*40);
      Engine:addCommand_SetVar(7, 1, 0);
    elseif (Engine:getVar(7) == 1) then
      Engine:setVar(7, 2);
      Engine:addCommand_QueueMsg("Well done shaman!", "Mission Complete", 512, true, nil, nil, 128, 0);

      gns.GameParams.Flags2 = gns.GameParams.Flags2 & ~GPF2_GAME_NO_WIN;
    end

    --global checking if cyan is being pressured on or not.
    if (getTurn() % 1440 == 0) then --expensive shit should just make something better in future
      if (pp[player_ally_tribe].NumPeople > 0 or pp[player_tribe].NumPeople > 0) then
        local r1 = count_people_of_type_in_area(126, 144, -1, player_tribe, 7);
        local c1 = count_people_of_type_in_area(126, 144, -1, player_ally_tribe, 7);
        local r2 = count_people_of_type_in_area(156, 144, -1, player_tribe, 7);
        local c2 = count_people_of_type_in_area(156, 144, -1, player_ally_tribe, 7);
        local tower_exists = IS_BUILDING_NEAR(player_ally_tribe, M_BUILDING_DRUM_TOWER, 126, 144, 7);
        if (tower_exists == 0) then
          tower_exists = IS_BUILDING_NEAR(player_tribe, M_BUILDING_DRUM_TOWER, 126, 144, 7);

          if (tower_exists == 0) then
            tower_exists = IS_BUILDING_NEAR(player_ally_tribe, M_BUILDING_DRUM_TOWER, 156, 144, 7);

            if (tower_exists == 0) then
              tower_exists = IS_BUILDING_NEAR(player_tribe, M_BUILDING_DRUM_TOWER, 156, 144, 7);
            end
          end
        end

        local total_peeps = r1 + c1 + r2 + c2;
        setPSVar(ai_tribe_1, 1, 0);
        setPSVar(ai_tribe_2, 1, 0);
        if (total_peeps < 4 and tower_exists == 0) then
          SET_MARKER_ENTRY(ai_tribe_2, 0, 6, 7, 0, 2, 2, 0);
          SET_MARKER_ENTRY(ai_tribe_2, 1, 4, 5, 0, 2, 2, 0);
          SET_MARKER_ENTRY(ai_tribe_2, 2, 2, 3, 0, 2, 2, 0);
          SET_MARKER_ENTRY(ai_tribe_2, 3, 36, 35, 0, 3, 3, 0);
          SET_MARKER_ENTRY(ai_tribe_1, 0, 6, 7, 0, 2, 2, 0);
          SET_MARKER_ENTRY(ai_tribe_1, 1, 4, 5, 0, 2, 2, 0);
          SET_MARKER_ENTRY(ai_tribe_1, 2, 2, 3, 0, 2, 2, 0);
          SET_MARKER_ENTRY(ai_tribe_1, 3, 36, 35, 0, 3, 3, 0);

          setPSVar(ai_tribe_1, 1, 1);
          setPSVar(ai_tribe_2, 1, 1);
        else
          SET_MARKER_ENTRY(ai_tribe_2, 0, 46, -1, 0, 0, 2, 0);
          SET_MARKER_ENTRY(ai_tribe_2, 1, 47, -1, 0, 0, 2, 0);
          SET_MARKER_ENTRY(ai_tribe_2, 2, 48, 49, 0, 0, 3, 0);
          SET_MARKER_ENTRY(ai_tribe_2, 3, 50, 51, 0, 0, 2, 0);
          SET_MARKER_ENTRY(ai_tribe_1, 0, 40, -1, 0, 2, 0, 0);
          SET_MARKER_ENTRY(ai_tribe_1, 1, 41, -1, 0, 2, 0, 0);
          SET_MARKER_ENTRY(ai_tribe_1, 2, 42, 43, 0, 0, 2, 0);
          SET_MARKER_ENTRY(ai_tribe_1, 3, 44, 45, 0, 0, 2, 0);
        end
      else
        SET_MARKER_ENTRY(ai_tribe_2, 0, 46, -1, 0, 0, 2, 0);
        SET_MARKER_ENTRY(ai_tribe_2, 1, 47, -1, 0, 0, 2, 0);
        SET_MARKER_ENTRY(ai_tribe_2, 2, 48, 49, 0, 0, 3, 0);
        SET_MARKER_ENTRY(ai_tribe_2, 3, 50, 51, 0, 0, 2, 0);
        SET_MARKER_ENTRY(ai_tribe_1, 0, 40, -1, 0, 2, 0, 0);
        SET_MARKER_ENTRY(ai_tribe_1, 1, 41, -1, 0, 2, 0, 0);
        SET_MARKER_ENTRY(ai_tribe_1, 2, 42, 43, 0, 0, 2, 0);
        SET_MARKER_ENTRY(ai_tribe_1, 3, 44, 45, 0, 0, 2, 0);
      end
    end

    --CYAN CODE
    if (pp[player_ally_tribe].NumPeople > 0) then
      --patrolling
      if ((getTurn() % 722) == 0 and Engine:getVar(1) == 2) then
        if (pp[player_ally_tribe].NumPeopleOfType[M_PERSON_WARRIOR] > 3) then
          MARKER_ENTRIES(player_ally_tribe, 0, 1, 2, -1);
        end
      end

      if ((getTurn() % 362) == 0) then
        if (pp[player_ally_tribe].NumPeopleOfType[M_PERSON_BRAVE] > 15) then
          WRITE_CP_ATTRIB(player_ally_tribe, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 15);
          WRITE_CP_ATTRIB(player_ally_tribe, ATTR_PREF_WARRIOR_PEOPLE, 15);
        else
          WRITE_CP_ATTRIB(player_ally_tribe, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 0);
          WRITE_CP_ATTRIB(player_ally_tribe, ATTR_PREF_WARRIOR_PEOPLE, 0);
        end
      end
    end

    --BLUE CODE
    if (pp[ai_tribe_1].NumPeople > 0) then
      --patrolling
      if ((getTurn() % 720) == 0 and Engine:getVar(1) == 2) then
        local enemies = count_people_of_type_in_area(124, 190, -1, player_tribe, 9);
        log(" " .. enemies);
        if (enemies <= 5 or current_game_difficulty < diff_veteran) then
          if (pp[ai_tribe_1].NumPeopleOfType[M_PERSON_SUPER_WARRIOR] > 3) then
            CLEAR_GUARDING_FROM(ai_tribe_1, 4, -1, -1, -1);
            MARKER_ENTRIES(ai_tribe_1, 0, 1, 2, -1);
            MARKER_ENTRIES(ai_tribe_1, 3, -1, -1, -1);
          end
        elseif (current_game_difficulty >= diff_veteran) then
          CLEAR_GUARDING_FROM(ai_tribe_1, 0, 1, 2, -1);
          CLEAR_GUARDING_FROM(ai_tribe_1, 3, -1, -1, -1);
          MARKER_ENTRIES(ai_tribe_1, 4, -1, -1, -1);
        end
      end

      if ((getTurn() % 360) == 0) then
        if (pp[ai_tribe_1].NumPeopleOfType[M_PERSON_BRAVE] > 31 and current_game_difficulty >= diff_experienced) then
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 40);
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_PEOPLE, 40);
        elseif (pp[ai_tribe_1].NumPeopleOfType[M_PERSON_BRAVE] > 20) then
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 20);
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_PEOPLE, 25);
        else
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 0);
          WRITE_CP_ATTRIB(ai_tribe_1, ATTR_PREF_WARRIOR_PEOPLE, 0);
        end
      end

      --ATTACKING!!!!!!!!!!!
      if (pp[player_tribe].NumPeople > 0 or pp[player_ally_tribe].NumPeople > 0) then
        local target = player_ally_tribe;
        local mk = 8;
        local rmk = 2;

        if (getPSVar(ai_tribe_1, 1) == 1) then
          mk = 1
          rmk = 1;
        end

        if (pp[target].NumPeople == 0) then
          target = player_tribe;
          mk = 17;
          rmk = 3;
        end

        if (Engine:getVar(1) == 2) then
          if (BlueAttack2:process() and current_game_difficulty >= diff_experienced) then
            if (getShaman(ai_tribe_1) ~= nil and pp[ai_tribe_1].NumPeopleOfType[M_PERSON_WARRIOR] > 3) then
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, 10 + G_RANDOM(50));
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_MEDICINE_MAN, 1);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, 10 + G_RANDOM(50));
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_DONT_GROUP_AT_DT, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_GROUP_OPTION, 2);
              ATTACK(ai_tribe_1, target, 4 + G_RANDOM(5 + current_game_difficulty), ATTACK_MARKER, mk + G_RANDOM(rmk), 50 + (50*current_game_difficulty), M_SPELL_HYPNOTISM, M_SPELL_HYPNOTISM, M_SPELL_HYPNOTISM, ATTACK_NORMAL, 0, 25 + G_RANDOM(3), -1, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, 10);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, 20);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, 10);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_MEDICINE_MAN, 0);
            end
          elseif (BlueAttack3:process()) then
            if (pp[ai_tribe_1].NumPeopleOfType[M_PERSON_WARRIOR] > 3 or pp[ai_tribe_1].NumPeopleOfType[M_PERSON_SUPER_WARRIOR] > 3) then
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, 10 + G_RANDOM(50));
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_MEDICINE_MAN, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, 10 + G_RANDOM(50));
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_DONT_GROUP_AT_DT, 1);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_GROUP_OPTION, 3);
              ATTACK(ai_tribe_1, target, 3 + G_RANDOM(5 + current_game_difficulty), ATTACK_MARKER, mk + G_RANDOM(rmk), 50 + (50*current_game_difficulty), 0, 0, 0, ATTACK_NORMAL, 0, -1, -1, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, 10);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, 20);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, 10);
            end
          elseif (BlueAttack1:process()) then
            if (pp[ai_tribe_1].NumPeopleOfType[M_PERSON_WARRIOR] > 2) then
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, 100);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_MEDICINE_MAN, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_DONT_GROUP_AT_DT, 1);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_GROUP_OPTION, 3);
              ATTACK(ai_tribe_1, target, 2 + current_game_difficulty, ATTACK_MARKER, mk + G_RANDOM(rmk), 50 + (50*current_game_difficulty), 0, 0, 0, ATTACK_NORMAL, 0, -1, -1, 0);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_WARRIOR, 10);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_BRAVE, 20);
              WRITE_CP_ATTRIB(ai_tribe_1, ATTR_AWAY_SUPER_WARRIOR, 10);
            end
          end
        end
      end
    end

    --YELLOW CODE
    if (pp[ai_tribe_2].NumPeople > 0) then
      --patrolling
      if ((getTurn() % 722) == 0 and Engine:getVar(1) == 2) then
        local enemies = count_people_of_type_in_area(124, 190, -1, player_tribe, 9);
        log(" " .. enemies);
        if (enemies <= 5 or current_game_difficulty < diff_veteran) then
          if (pp[ai_tribe_2].NumPeopleOfType[M_PERSON_SUPER_WARRIOR] > 3) then
            CLEAR_GUARDING_FROM(ai_tribe_2, 4, -1, -1, -1);
            MARKER_ENTRIES(ai_tribe_2, 0, 1, 2, -1);
            MARKER_ENTRIES(ai_tribe_2, 3, -1, -1, -1);
          end
        elseif (current_game_difficulty >= diff_veteran) then
          CLEAR_GUARDING_FROM(ai_tribe_2, 0, 1, 2, -1);
          CLEAR_GUARDING_FROM(ai_tribe_2, 3, -1, -1, -1);
          MARKER_ENTRIES(ai_tribe_2, 4, -1, -1, -1);
        end
      end

      if ((getTurn() % 361) == 0) then
        if (pp[ai_tribe_2].NumPeopleOfType[M_PERSON_BRAVE] > 35 and current_game_difficulty >= diff_experienced) then
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 40);
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_PEOPLE, 40);
        elseif (pp[ai_tribe_2].NumPeopleOfType[M_PERSON_BRAVE] > 17) then
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 25);
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_PEOPLE, 20);
        else
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_SUPER_WARRIOR_PEOPLE, 0);
          WRITE_CP_ATTRIB(ai_tribe_2, ATTR_PREF_WARRIOR_PEOPLE, 0);
        end
      end

      --ATTACKING!!!!!!!!!!!
      if (pp[player_tribe].NumPeople > 0 or pp[player_ally_tribe].NumPeople > 0) then
        local target = player_ally_tribe;
        local mk = 8;
        local rmk = 2;

        if (getPSVar(ai_tribe_1, 1) == 1) then
          mk = 1
          rmk = 1;
        end

        if (pp[target].NumPeople == 0) then
          target = player_tribe;
          mk = 17;
          rmk = 3;
        end

        if (Engine:getVar(1) == 2) then
          if (YellowAttack1:process()) then
            if (pp[ai_tribe_2].NumPeopleOfType[M_PERSON_WARRIOR] > 2) then
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 40);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_MEDICINE_MAN, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 60);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_DONT_GROUP_AT_DT, 1);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_GROUP_OPTION, 3);
              ATTACK(ai_tribe_2, target, 3 + current_game_difficulty, ATTACK_MARKER, mk + G_RANDOM(rmk), 50 + (50*current_game_difficulty), 0, 0, 0, ATTACK_NORMAL, 0, -1, -1, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 10);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 20);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 10);
            end
          elseif (YellowAttack2:process() and current_game_difficulty >= diff_experienced) then
            if (pp[ai_tribe_2].NumPeopleOfType[M_PERSON_WARRIOR] > 5) then
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 50);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_MEDICINE_MAN, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 50);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_DONT_GROUP_AT_DT, 1);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_GROUP_OPTION, 3);
              ATTACK(ai_tribe_2, target, 8 + current_game_difficulty, ATTACK_MARKER, mk + G_RANDOM(rmk), 50 + (50*current_game_difficulty), 0, 0, 0, ATTACK_NORMAL, 0, -1, -1, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 10);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 20);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 10);
            end
          elseif (YellowAttack3:process() and current_game_difficulty >= diff_experienced) then
            if (getShaman(ai_tribe_2) ~= nil) then
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 0 + (current_game_difficulty * 10));
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_MEDICINE_MAN, 1);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 0 + (current_game_difficulty * 10));
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_DONT_GROUP_AT_DT, 1);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_GROUP_OPTION, 2);
              ATTACK(ai_tribe_2, target, 0 + (current_game_difficulty * 2), ATTACK_MARKER, mk + G_RANDOM(rmk), 50 + (50*current_game_difficulty), M_SPELL_INSECT_PLAGUE, M_SPELL_INSECT_PLAGUE, M_SPELL_INSECT_PLAGUE, ATTACK_NORMAL, 0, 29 + G_RANDOM(3), -1, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_WARRIOR, 10);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_MEDICINE_MAN, 0);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_BRAVE, 20);
              WRITE_CP_ATTRIB(ai_tribe_2, ATTR_AWAY_SUPER_WARRIOR, 10);
            end
          end
        end
      end
    end

    --handle any post-loading stuff
    if (game_loaded) then
      Engine:postLoadItems();

      game_loaded = false;

      --yep.
      if (game_loaded_honour) then
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
    if (math.random(0, 1) == 0) then
      Engine.DialogObj:queueMessage("Dakini?", "Tiyao", 6, false, 6883, 2, 146);
      Engine.DialogObj:queueMessage("Dakini, what's wrong?", "Tiyao", 6, false, 6883, 2, 146);
    end
    Engine.DialogObj:queueMessage("Dakini!!!", "Tiyao", 48, false, 6883, 2, 146);

    if (current_game_difficulty == diff_honour) then
      Engine.DialogObj:queueMessage("You're not ready for the challenge yet.", "Mission Failed", 512, true, nil, nil, 128);
    else
      Engine.DialogObj:queueMessage("You have been defeated.", "Mission Failed", 512, true, nil, nil, 128);
    end
  end

  if (pn == player_ally_tribe) then
    Engine:setVar(5, 1);
    Engine.DialogObj:queueMessage("Dakini...", "Tiyao", 48, false, 7809, 2, 146);
    Engine.DialogObj:queueMessage("May her soul rest in peace. Surrender now Dakini.", "Chumara", 48, false, 6923, 1, 238);
    Engine.DialogObj:queueMessage("Hahahaha!!! YOU FOOOOLS!!!!", "Ikani", 48, false, 6883, 1, 222);
    if (current_game_difficulty == diff_honour) then
      Engine.DialogObj:queueMessage("You're not ready for the challenge yet.", "Mission Failed", 512, true, nil, nil, 128);
    else
      Engine.DialogObj:queueMessage("Your ally has fallen.", "Mission Failed", 512, true, nil, nil, 128);
    end
    gns.GameParams.Flags2 = gns.GameParams.Flags2 & ~GPF2_GAME_NO_WIN;
    gns.Flags = gns.Flags | GNS_LEVEL_FAILED;
  end

  if (pn == ai_tribe_1) then
    Engine:setVar(3, 1);
    Engine.DialogObj:queueMessage("CHUMARA!!! WHAT ARE YOU ON EARTH DOING?!", "Ikani", 48, false, 7809, 1, 222);
    if (getShaman(player_ally_tribe) ~= nil) then
      Engine.DialogObj:queueMessage("Well done Dakini!", "Tiyao", 48, false, 6883, 2, 146);
    end
  end

  if (pn == ai_tribe_2) then
    Engine:setVar(4, 1);
    Engine.DialogObj:queueMessage("Who did I ally... I'm clearly not the brightest mind in this world...", "Chumara", 48, false, 7869, 1, 238);
    if (getShaman(player_ally_tribe) ~= nil) then
      Engine.DialogObj:queueMessage("Well done Dakini!", "Tiyao", 48, false, 6883, 2, 146);
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
    if (t_thing.Type == T_EFFECT) then
      if (t_thing.Model == M_EFFECT_SHIELD) then
        if (t_thing.Owner == player_ally_tribe) then
          createThing(T_EFFECT, M_EFFECT_SHIELD, player_tribe, t_thing.Pos.D3, false, false);
        end
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

    if (Engine:getVar(2) == 1 and getShaman(player_ally_tribe) ~= nil) then
      Engine.Magic:render();
    end
  end
end
