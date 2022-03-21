--spring level 1: Eastern Winds

import(Module_System)
import(Module_Globals)
import(Module_Players)
import(Module_DataTypes)
import(Module_Table)
import(Module_Level)
import(Module_Defines)
import(Module_PopScript)
import(Module_Game)
import(Module_Objects)
import(Module_Map)
import(Module_Math)
import(Module_String)
import(Module_MapWho)
import(Module_ImGui)
import(Module_Draw)
import(Module_Person)
import(Module_Sound)
import(Module_Commands)
import(Module_Spells)
import(Module_Building)
local gs = gsi()
local gns = gnsi()
_gnsi = gnsi()
_gsi = gsi()
sti = spells_type_info()
tmi = thing_move_info()
bti = building_type_info()
ency = encyclopedia_info()
ency[27].StrId = 690
ency[32].StrId = 691
ency[22].StrId = 692
include("assets.lua")
--------------------
sti[M_SPELL_INVISIBILITY].OneOffMaximum = 4
sti[M_SPELL_INVISIBILITY].WorldCoordRange = 4096
sti[M_SPELL_INVISIBILITY].CursorSpriteNum = 45
sti[M_SPELL_INVISIBILITY].ToolTipStrIdx = 818
sti[M_SPELL_INVISIBILITY].AvailableSpriteIdx = 359
sti[M_SPELL_INVISIBILITY].NotAvailableSpriteIdx = 377
sti[M_SPELL_INVISIBILITY].ClickedSpriteIdx = 395
sti[M_SPELL_SWAMP].OneOffMaximum = 3
sti[M_SPELL_SWAMP].WorldCoordRange = 4096
sti[M_SPELL_SWAMP].CursorSpriteNum = 53
sti[M_SPELL_SWAMP].ToolTipStrIdx = 823
sti[M_SPELL_SWAMP].AvailableSpriteIdx = 364
sti[M_SPELL_SWAMP].NotAvailableSpriteIdx = 382
sti[M_SPELL_SWAMP].ClickedSpriteIdx = 400
bti[M_BUILDING_SPY_TRAIN].ToolTipStrId2 = 641
--------------------
for i = 0,7 do
	plants = createThing(T_SCENERY,M_SCENERY_PLANT_2,8,marker_to_coord3d(i),false,false) centre_coord3d_on_block(plants.Pos.D3)
	plants.DrawInfo.DrawNum = 1791 plants.DrawInfo.Alpha = -16
	createThing(T_EFFECT,60,8,marker_to_coord3d(i),false,false) 
end

















