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
include("assets.lua")

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
local player = TRIBE_BLUE;

-------------------------------------------------------------------------------------------------------------------------------------------------
include("CSequence.lua");
local Engine = CSequence:createNew();
local dialog_msgs = {
	[0] = {"The Matak are here, and I can sense their anger. It clouds my mind and causes me to forget that which I once knew. I will have to study the vaults carefully and prepare for war.","Ikani", 6879, 1, 219},
	[1] = {"Let us see how you fare with your powers stripped down to the core, Ikani, this is war in its purest form and I shall destroy you.","Matak",7023,1,227},
	[2] = {"Retrieve the knowledge of the vaults and use their combined powers to defeat the Matak","Objective",174, 0, 128}
}
--for scaling purposes
local user_scr_height = ScreenHeight();
local user_scr_width = ScreenWidth();
if (user_scr_height > 600) then
  Engine.DialogObj:setFont(3);
end
-------------------------------------------------------------------------------------------------------------------------------------------------

function OnSave(save_data)
  --globals save
  save_data:push_int(current_game_difficulty);

  if (getTurn() >= 12*20 + 600 and current_game_difficulty == diff_honour) then
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
    
    SET_USER_VARIABLE_VALUE(TRIBE_GREEN, POPSCRIPT_USER_DIFFICULTY_INDEX, current_game_difficulty);

    --take player's ghost army
    set_player_cannot_cast(M_SPELL_GHOST_ARMY, TRIBE_BLUE);
    set_correct_gui_menu();

  else
    Engine:process();

    --handle any post-loading stuff
    if (game_loaded) then
      Engine:postLoadItems();

      game_loaded = false;

      --yep.
      if (game_loaded_honour and honour_saved_once) and turn() > 600+12*20 then
        game_loaded_honour = false;
        ProcessGlobalSpecialList(TRIBE_BLUE, PEOPLELIST, function(t)
          damage_person(t, 8, 65535, TRUE);
          return true;
        end);
		TRIGGER_LEVEL_LOST() ; SET_NO_REINC(player)
		log_msg(8,"WARNING:  You have loaded the game while playing in \"honour\" mode.")

        exit();
      end
    end
  end
	if turn() == 600 then
		if difficulty() == 3 then
			Engine:addCommand_SetVar(1, 0, 4);
			Engine:addCommand_QueueMsg("Warning! You've chosen hardest difficulty possibly available which is Honour. You now have 20 seconds to save (to avoid rewatching the intro). Enemies will have no mercy on you and Finish you in worst and saddest possible way. Are you brave enough for this suffering? You've been warned.", "Honour Mode", 256, true, 176, 0, 245, 0);
		end
	elseif turn() == 12 then
		FLYBY_CREATE_NEW()
		FLYBY_ALLOW_INTERRUPT(FALSE)
	
		FLYBY_SET_EVENT_ZOOM (-30,1,40)
		FLYBY_SET_EVENT_POS(152, 178, 1, 40)
		FLYBY_SET_EVENT_ANGLE(250, 1, 40)
		
		FLYBY_SET_EVENT_ZOOM (-60,60,50)
		FLYBY_SET_EVENT_POS(170, 146, 50, 50)
		FLYBY_SET_EVENT_ANGLE(math.random(0,1999), 50, 50)
		
		FLYBY_SET_EVENT_ZOOM (-40,120,60)
		FLYBY_SET_EVENT_POS(138, 52, 120, 60)
		FLYBY_SET_EVENT_ANGLE(0, 120, 60)
		
		FLYBY_SET_EVENT_ZOOM (-20,200,50)
		FLYBY_SET_EVENT_POS(74, 110, 200, 50)
		FLYBY_SET_EVENT_ANGLE(500, 200, 50)
		
		FLYBY_SET_EVENT_ZOOM (0,260,40)
		FLYBY_SET_EVENT_POS(154, 178, 260, 40)
		FLYBY_SET_EVENT_ANGLE(250, 260, 40)
		
		FLYBY_START()
	elseif turn() == 24 then
		Engine:hidePanel()
		Engine:addCommand_CinemaRaise(34)
		Engine:addCommand_MoveThing(getShaman(player).ThingNum, marker_to_coord2d_centre(7), 2);
		Engine:addCommand_QueueMsg(dialog_msgs[0][1], dialog_msgs[0][2], 8, false, dialog_msgs[0][3], dialog_msgs[0][4], dialog_msgs[0][5], 12*10);
		Engine:addCommand_QueueMsg(dialog_msgs[1][1], dialog_msgs[1][2], 36, false, dialog_msgs[1][3], dialog_msgs[1][4], dialog_msgs[1][5], 12*15);
		Engine:addCommand_MoveThing(getShaman(player).ThingNum, marker_to_coord2d_centre(8), 1);
		Engine:addCommand_CinemaHide(8);
		Engine:addCommand_ShowPanel(60);
		Engine:addCommand_QueueMsg(dialog_msgs[2][1], dialog_msgs[2][2], 60, false, dialog_msgs[2][3], dialog_msgs[2][4], dialog_msgs[2][5], 12*1);
	end
end

function OnPlayerDeath(pn)
	if pn == player then
		if (difficulty() == 3) then
			Engine.DialogObj:queueMessage("You're not ready for the challenge yet.", "Mission Failed", 512, true, nil, nil, 128);
		else
			Engine.DialogObj:queueMessage("You have been defeated.", "Mission Failed", 512, true, nil, nil, 128);
		end
	else
		Engine.DialogObj:queueMessage("This was war... beautiful and consuming... I die content...", "Matak", 36, false, 7568,1,227);
		Engine.DialogObj:queueMessage("I have bested the Matak, but feel uneasy. Something seemed off about her, I must find the answers.", "Ikani", 36, false, 6879, 1, 219);
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
