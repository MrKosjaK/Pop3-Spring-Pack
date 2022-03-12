import(Module_DataTypes)
import(Module_Globals)
import(Module_Players)
import(Module_Table)
import(Module_Level)
import(Module_System)
import(Module_Defines)
import(Module_PopScript)
import(Module_Game)
import(Module_Objects)
import(Module_Map)
import(Module_Math)
import(Module_MapWho)
import(Module_String)
import(Module_ImGui)
import(Module_Draw)
import(Module_System)
import(Module_Person)
import(Module_Sound)
import(Module_Commands)
local gs = gsi()
local gns = gnsi()
_gnsi = gnsi()
_gsi = gsi()
sti = spells_type_info()
--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
--pow 2 turn
function every2Pow(a)
  if (_gsi.Counts.GameTurn % 2^a == 0) then
    return true else return false
  end
end

--every x
function every(a)
  if (_gsi.Counts.GameTurn % a == 0) then
    return true else return false
  end
end

--every x seconds
function everySeconds(a)
  if (_gsi.Counts.GameTurn % (a*12) == 0) then
    return true else return false
  end
end

--return difficulty
function difficulty()
	return get_game_difficulty()
end

--get turn
function turn()
	return gs.Counts.ProcessThings
end

--get second
function seconds()
	return math.floor(gs.Counts.ProcessThings/12)
end

--get minute
function minutes()
	return math.floor(seconds()/60)
end

--random
function rnd()
	return math.random(100)
end
--------------------------------------------------------------------------------------------------------------------------------------------
--pop of a tribe
function GetPop(pn)
  return _gsi.Players[pn].NumPeople
end

--troops of a tribe
function GetTroops(pn)
	local sh = 0 if getShaman(0) ~= nil then sh = 1 end
	return (_gsi.Players[pn].NumPeople - _gsi.Players[pn].NumPeopleOfType[M_PERSON_BRAVE]) - sh
end

--who has most pop
function GetPopLeader()
	local highestPop = 0
	local tribeWinning = -1
	for i = 0,7 do
		local pop = _gsi.Players[i].NumPeople
		if pop > highestPop then
			highestPop = pop
			tribeWinning = i
		end
	end
	
	return tribeWinning
end

--copy c3d
function CopyC3d(c3d)
	local nc3d = Coord3D.new()
	nc3d.Xpos = c3d.Xpos
	nc3d.Ypos = c3d.Ypos
	nc3d.Zpos = c3d.Zpos
	return nc3d
end

--thing X coord
function ThingX(thing)
	if thing ~= nil then
		local pos = MapPosXZ.new() 
		pos.Pos = world_coord3d_to_map_idx(thing.Pos.D3)	
		return pos.XZ.X
	end
end
--thing Z coord
function ThingZ(thing)
	if thing ~= nil then
		local pos = MapPosXZ.new() 
		pos.Pos = world_coord3d_to_map_idx(thing.Pos.D3)	
		return pos.XZ.Z
	end
end

--zoom to thing
function ZoomThing(thing,angle)
	if thing ~= nil then
		local pos = MapPosXZ.new() 
		pos.Pos = world_coord3d_to_map_idx(thing.Pos.D3)	
		ZOOM_TO(pos.XZ.X,pos.XZ.Z,angle)
	end
end
--------------------------------------------------------------------------------------------------------------------------------------------
--read AI attacking troops (attr_away)
function ReadAIAttackers(pn)
	local b,w,r,fw,spy,sh = READ_CP_ATTRIB(pn,ATTR_AWAY_BRAVE),READ_CP_ATTRIB(pn,ATTR_AWAY_WARRIOR),READ_CP_ATTRIB(pn,ATTR_AWAY_RELIGIOUS),READ_CP_ATTRIB(pn,ATTR_AWAY_SUPER_WARRIOR),READ_CP_ATTRIB(pn,ATTR_AWAY_SPY),READ_CP_ATTRIB(pn,ATTR_AWAY_MEDICINE_MAN)
	log_msg(pn,"ATTACKERS:   br: " .. b .. ", wars: " .. w .. ", pr: " .. r .. ", fws: " .. fw .. ", spy: " .. spy .. ", shaman: " .. sh)
end

--read AI % troops to train (attr_pref)
function ReadAITroops(pn)
	local w,r,fw,spy = READ_CP_ATTRIB(pn,ATTR_PREF_WARRIOR_PEOPLE),READ_CP_ATTRIB(pn,ATTR_PREF_RELIGIOUS_PEOPLE),READ_CP_ATTRIB(pn,ATTR_PREF_SUPER_WARRIOR_PEOPLE),READ_CP_ATTRIB(pn,ATTR_PREF_SPY_PEOPLE)
	log_msg(pn,"% TROOPS:   wars: " .. w .. ", preachers: " .. r .. ", fws: " .. fw .. ", spy: " .. spy)
end

--write AI attacking troops(attr_away)
function WriteAiAttackers(pn,b,w,r,fw,spy,sh)
	WRITE_CP_ATTRIB(pn, ATTR_AWAY_BRAVE, b)
	WRITE_CP_ATTRIB(pn, ATTR_AWAY_WARRIOR, w)
	WRITE_CP_ATTRIB(pn, ATTR_AWAY_RELIGIOUS, r)
	WRITE_CP_ATTRIB(pn, ATTR_AWAY_SUPER_WARRIOR, fw)
	WRITE_CP_ATTRIB(pn, ATTR_AWAY_SPY, spy)
	WRITE_CP_ATTRIB(pn, ATTR_AWAY_MEDICINE_MAN, sh)
end

--write AI % train troops(attr_pref)
function WriteAiTrainTroops(pn,w,r,fw,spy)
	WRITE_CP_ATTRIB(pn, ATTR_PREF_WARRIOR_PEOPLE, w)
	WRITE_CP_ATTRIB(pn, ATTR_PREF_RELIGIOUS_PEOPLE, r)
	WRITE_CP_ATTRIB(pn, ATTR_PREF_SUPER_WARRIOR_PEOPLE, fw)
	WRITE_CP_ATTRIB(pn, ATTR_PREF_SPY_PEOPLE, spy)
end
--------------------------------------------------------------------------------------------------------------------------------------------
--flags
function EnableFlag(_f1, _f2)
    if (_f1 & _f2 == 0) then
        _f1 = _f1 | _f2
    end
    return _f1
end
function DisableFlag(_f1, _f2)
    if (_f1 & _f2 == _f2) then
        _f1 = _f1 ~ _f2
    end
    return _f1
end

--win/lose levels
function WIN()
	gns.GameParams.Flags2 = gns.GameParams.Flags2 & ~GPF2_GAME_NO_WIN
	gns.Flags = gns.Flags | GNS_LEVEL_COMPLETE
end
function LOSE()
	gns.GameParams.Flags2 = gns.GameParams.Flags2 & ~GPF2_GAME_NO_WIN
	gns.Flags = gns.Flags | GNS_LEVEL_FAILED
end
--------------------------------------------------------------------------------------------------------------------------------------------
PThing = {}
--set spell
PThing.SpellSet = function (player, spell, input, charge)
  if (input == 0) then
    _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailable = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailable ~ (1<<spell);
	else
		if (charge == 0) then
			_gsi.ThisLevelInfo.PlayerThings[player].SpellsNotCharging = _gsi.ThisLevelInfo.PlayerThings[player].SpellsNotCharging | (1<<spell-1);
		else
			_gsi.ThisLevelInfo.PlayerThings[player].SpellsNotCharging = _gsi.ThisLevelInfo.PlayerThings[player].SpellsNotCharging ~ (1<<spell-1);
		end
		_gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailable = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailable | (1<<spell);
	end
end

--set building
PThing.BldgSet = function (player, building, input)
  if (input == 0) then
		_gsi.ThisLevelInfo.PlayerThings[player].BuildingsAvailable = _gsi.ThisLevelInfo.PlayerThings[player].BuildingsAvailable ~ (1<<building);
	else
		_gsi.ThisLevelInfo.PlayerThings[player].BuildingsAvailable = _gsi.ThisLevelInfo.PlayerThings[player].BuildingsAvailable | (1<<building);
	end
end

--give shot
PThing.GiveShot = function (player, spell, amount)
  if (amount > sti[spell].OneOffMaximum) then
    _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[spell] = 4
  else
    _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[spell] = _gsi.ThisLevelInfo.PlayerThings[player].SpellsAvailableOnce[spell] + amount
  end
end
--------------------------------------------------------------------------------------------------------------------------------------------
--timer to h/m/s
function TurnsToClock(initialCountdown)
  local initialCountdown = tonumber(initialCountdown)
  if initialCountdown <= 0 then
    return "00:00:00";
  else
    hours = string.format("%02.f", math.floor(initialCountdown/3600));
    mins = string.format("%02.f", math.floor(initialCountdown/60 - (hours*60)));
    secs = string.format("%02.f", math.floor(initialCountdown - hours*3600 - mins *60));
    return hours..":"..mins..":"..secs
  end
end
--------------------------------------------------------------------------------------------------------------------------------------------
--debug
function LOG(msg)
	log_msg(8,"turn: " .. turn() .. "  : " .. tostring(msg))
end
