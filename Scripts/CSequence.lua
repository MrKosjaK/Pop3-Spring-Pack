include("CDialog.lua");
include("CCinematic.lua");
include("CMagicShield.lua");

CSeqCommand = {};
CSeqCommand.__index = CSeqCommand;

setmetatable(CSeqCommand, {
  __call = function(cls, ...)
    return cls.new(...);
  end,
});

function CSeqCommand:createCmd(_cmdType)
  local self = setmetatable({}, CSeqCommand);

  self.CmdType = _cmdType or nil;
  self.CmdWaitCount = 0;
  self.CmdTargetCoord = nil;
  self.CmdEndCoord = nil;
  self.CmdThingLinkIdx = nil;
  self.CmdThingAngle = nil;
  self.CmdMsg = nil;
  self.CmdSpawnThingType = nil;
  self.CmdSpawnThingModel = nil;
  self.CmdSpawnThingOwner = nil;
  self.CmdSpawnThingAmount = nil;
  self.CmdSpawnThingBufIdx = nil;
  self.CmdRadius = nil;

  return self;
end

CMD_TYPE = {
  ["MOVE_THING"] = 0,
  ["ANGLE_THING"] = 1,
  ["QUEUE_MSG"] = 2,
  ["CINEMA_START_RAISE"] = 3,
  ["CINEMA_START_HIDE"] = 4,
  ["HIDE_PANEL"] = 5,
  ["SHOW_PANEL"] = 6,
  ["SPAWN_THING"] = 7,
  ["DESPAWN_THING"] = 8,
  ["SPAWN_THINGS"] = 9,
  ["DESPAWN_THINGS"] = 10,
  ["CLEAR_THING_BUFFER"] = 11,
  ["PLACE_DOWN_SHAPE"] = 12,
  ["CMD_CHOP_TREE"] = 13,
  ["CMD_BUILD_BLDG"] = 14,
  ["CMD_PATROL"] = 15,
  ["SET_VARIABLE"] = 16,
  ["CMD_GOTO_CRD"] = 17,
  ["ADD_THINGS"] = 18,
  ["CMD_ATTACK_AREA"] = 19,
  ["BREAK_ALLY"] = 20,
  ["CAST_SPELL"] = 21,
  ["CMD_PATROL_2P"] = 22
};

CSequence = {};
CSequence.__index = CSequence;

setmetatable(CSequence, {
  __call = function(cls, ...)
    return cls.new(...);
  end,
});

function CSequence:createNew()
  local self = setmetatable({}, CSequence);

  self.GNS = gnsi();
  self.GS = gsi();

  self.DialogObj = CDialog:createDlg();
  self.CinemaObj = CCinematic:createC();
  self.Magic = CMagicalShield:register();
  self.ThingBuffers = {};
  self.Variables = {};
  self.PanelHidden = false;

  for i = 1, 64 do
    self.Variables[i] = 0;
  end

  for i = 1, 16 do
    self.ThingBuffers[i] = {};
  end

  self.Commands = {};
  self.WaitCount = 0;

  return self;
end

function CSequence:saveData(sd)
  --Magic save
  self.Magic:saveData(sd);
  log("[INFO] Magical shield saved.");

  --Dialog save
  self.DialogObj:saveData(sd);
  log("[INFO] Dialog saved.");

  --Cinematic save
  self.CinemaObj:saveData(sd);
  log("[INFO] Cinematic saved.")

  for i = #self.Commands, 1, -1 do
    --since im using NILs for some values it's better if i make a variable to tell if those were used or not.
    local BITS = 0;

    if (self.Commands[i].CmdType ~= nil) then
      BITS = BITS | (1 << 0);
      sd:push_int(self.Commands[i].CmdType);
    end

    if (self.Commands[i].CmdTargetCoord ~= nil) then
      BITS = BITS | (1 << 1);
      sd:push_int(self.Commands[i].CmdTargetCoord.Xpos);
      sd:push_int(self.Commands[i].CmdTargetCoord.Zpos);
    end

    if (self.Commands[i].CmdThingLinkIdx ~= nil) then
      BITS = BITS | (1 << 2);
      sd:push_int(self.Commands[i].CmdThingLinkIdx:getThingNum());
    end

    if (self.Commands[i].CmdThingAngle ~= nil) then
      BITS = BITS | (1 << 3);
      sd:push_int(self.Commands[i].CmdThingAngle);
    end

    if (self.Commands[i].CmdMsg ~= nil) then
      BITS = BITS | (1 << 4);

      --have to do MSG_BITS as well
      local MSG_BITS = 0;

      if (self.Commands[i].CmdMsg.MsgString ~= nil) then
        MSG_BITS = MSG_BITS | (1 << 0);
        sd:push_string(self.Commands[i].CmdMsg.MsgString);
      end

      if (self.Commands[i].CmdMsg.MsgTitle ~= nil) then
        MSG_BITS = MSG_BITS | (1 << 1);
        sd:push_string(self.Commands[i].CmdMsg.MsgTitle);
      end

      if (self.Commands[i].CmdMsg.MsgIcon ~= nil) then
        MSG_BITS = MSG_BITS | (1 << 2);
        sd:push_int(self.Commands[i].CmdMsg.MsgIcon);
      end

      if (self.Commands[i].CmdMsg.MsgBank ~= nil) then
        MSG_BITS = MSG_BITS | (1 << 3);
        sd:push_int(self.Commands[i].CmdMsg.MsgBank);
      end

      sd:push_int(self.Commands[i].CmdMsg.MsgColor);
      sd:push_int(self.Commands[i].CmdMsg.DelayNext);
      sd:push_bool(self.Commands[i].CmdMsg.MsgInstant);
      sd:push_int(MSG_BITS);
    end

    if (self.Commands[i].CmdEndCoord ~= nil) then
      BITS = BITS | (1 << 5);
      sd:push_int(self.Commands[i].CmdEndCoord.Xpos);
      sd:push_int(self.Commands[i].CmdEndCoord.Zpos);
    end

    if (self.Commands[i].CmdRadius ~= nil) then
      BITS = BITS | (1 << 6);
      sd:push_int(self.Commands[i].CmdRadius);
    end

    if (self.Commands[i].CmdSpawnThingType ~= nil) then
      BITS = BITS | (1 << 7);
      sd:push_int(self.Commands[i].CmdSpawnThingType);
    end

    if (self.Commands[i].CmdSpawnThingModel ~= nil) then
      BITS = BITS | (1 << 8);
      sd:push_int(self.Commands[i].CmdSpawnThingModel);
    end

    if (self.Commands[i].CmdSpawnThingOwner ~= nil) then
      BITS = BITS | (1 << 9);
      sd:push_int(self.Commands[i].CmdSpawnThingOwner);
    end

    if (self.Commands[i].CmdSpawnThingAmount ~= nil) then
      BITS = BITS | (1 << 10);
      sd:push_int(self.Commands[i].CmdSpawnThingAmount);
    end

    if (self.Commands[i].CmdSpawnThingBufIdx ~= nil) then
      BITS = BITS | (1 << 11);
      sd:push_int(self.Commands[i].CmdSpawnThingBufIdx);
    end

    sd:push_int(self.Commands[i].CmdWaitCount);
    sd:push_int(BITS);
  end

  sd:push_int(#self.Commands);
  sd:push_int(self.WaitCount);

  --Thing buffers save
  for i = #self.ThingBuffers, 1, -1 do
    for j = #self.ThingBuffers[i], 1, -1 do
      sd:push_int(self.ThingBuffers[i][j]);
    end

    sd:push_int(#self.ThingBuffers[i]);
  end

  sd:push_int(#self.ThingBuffers);

  for i = #self.Variables, 1, -1 do
    sd:push_int(self.Variables[i]);
  end

  sd:push_int(#self.Variables);
  sd:push_bool(self.PanelHidden);
  log("[INFO] Command system saved.");
end

function CSequence:loadData(ld)
  self.PanelHidden = ld:pop_bool();

  local num_variables = ld:pop_int();

  for i = 1, num_variables do
    self.Variables[i] = ld:pop_int();
  end

  local num_thing_buffers = ld:pop_int();

  for i = 1, num_thing_buffers do
    local num_thing_idxs = ld:pop_int();

    for j = 1, num_thing_idxs do
      table.insert(self.ThingBuffers[i], ld:pop_int());
    end
  end

  self.WaitCount = ld:pop_int();
  local num_cmds = ld:pop_int();

  for i = 1, num_cmds do
    local BITS = ld:pop_int();

    local cmd = CSeqCommand:createCmd();
    cmd.CmdWaitCount = ld:pop_int();

    if (BITS & (1 << 11) ~= 0) then
      cmd.CmdSpawnThingBufIdx = ld:pop_int();
    end

    if (BITS & (1 << 10) ~= 0) then
      cmd.CmdSpawnThingAmount = ld:pop_int();
    end

    if (BITS & (1 << 9) ~= 0) then
      cmd.CmdSpawnThingOwner = ld:pop_int();
    end

    if (BITS & (1 << 8) ~= 0) then
      cmd.CmdSpawnThingModel = ld:pop_int();
    end

    if (BITS & (1 << 7) ~= 0) then
      cmd.CmdSpawnThingType = ld:pop_int();
    end

    if (BITS & (1 << 6) ~= 0) then
      cmd.CmdRadius = ld:pop_int();
    end

    if (BITS & (1 << 5) ~= 0) then
      cmd.CmdEndCoord = Coord2D.new();
      cmd.CmdEndCoord.Zpos = ld:pop_int();
      cmd.CmdEndCoord.Xpos = ld:pop_int();
    end

    if (BITS & (1 << 4) ~= 0) then
      local MSG_BITS = ld:pop_int();

      cmd.CmdMsg = CMsg:createMsg();
      cmd.CmdMsg.MsgInstant = ld:pop_bool();
      cmd.CmdMsg.DelayNext = ld:pop_int();
      cmd.CmdMsg.MsgColor = ld:pop_int();

      if (MSG_BITS & (1 << 3) ~= 0) then
        cmd.CmdMsg.MsgBank = ld:pop_int();
      end

      if (MSG_BITS & (1 << 2) ~= 0) then
        cmd.CmdMsg.MsgIcon = ld:pop_int();
      end

      if (MSG_BITS & (1 << 1) ~= 0) then
        cmd.CmdMsg.MsgTitle = ld:pop_string();
      end

      if (MSG_BITS & (1 << 0) ~= 0) then
        cmd.CmdMsg.MsgString = ld:pop_string();
      end
    end

    if (BITS & (1 << 3) ~= 0) then
      cmd.CmdThingAngle = ld:pop_int();
    end

    if (BITS & (1 << 2) ~= 0) then
      cmd.CmdThingLinkIdx = ObjectProxy.new();
      cmd.CmdThingLinkIdx:set(ld:pop_int());
    end

    if (BITS & (1 << 1) ~= 0) then
      cmd.CmdTargetCoord = Coord2D.new();
      cmd.CmdTargetCoord.Zpos = ld:pop_int();
      cmd.CmdTargetCoord.Xpos = ld:pop_int();
    end

    if (BITS & (1 << 0) ~= 0) then
      cmd.CmdType = ld:pop_int();
    end

    table.insert(self.Commands, cmd);
  end
  log("[INFO] Command system loaded");

  --Cinematic load
  self.CinemaObj:loadData(ld);
  log("[INFO] Cinematic loaded.")

  --Dialog load
  self.DialogObj:loadData(ld);
  log("[INFO] Dialog loaded.");

  --Magic load
  self.Magic:loadData(ld);
  log("[INFO] Magical shield loaded.");
end

function CSequence:process()
  self.DialogObj:processQueue();
  self:processCmd();
end

function CSequence:processCmd()
  if (self.WaitCount > 0) then
    self.WaitCount = self.WaitCount - 1;
    do return end;
  end

  if (#self.Commands > 0) then
    local cmd = self.Commands[1];
    if (cmd.CmdType == CMD_TYPE["MOVE_THING"]) then
      local cti = CmdTargetInfo.new();
      cti.TargetCoord.Xpos = cmd.CmdTargetCoord.Xpos;
      cti.TargetCoord.Zpos = cmd.CmdTargetCoord.Zpos;

      local command = Commands.new();

      update_cmd_list_entry(command, CMD_GOTO_POINT, cti, 0);

      local t = cmd.CmdThingLinkIdx:get();
      t.Flags = t.Flags | (1<<4);
      remove_all_persons_commands(t);
      add_persons_command(t, command, 0);

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["ANGLE_THING"]) then
      local t = cmd.CmdThingLinkIdx:get();

      t.Flags = t.Flags | (1 << 7);
      t.Flags = t.Flags | (1 << 12);
      t.Move.CurrDest.AngleXZ = cmd.CmdThingAngle;

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["QUEUE_MSG"]) then
      self.DialogObj:queueMessage(cmd.CmdMsg.MsgString, cmd.CmdMsg.MsgTitle, cmd.CmdMsg.DelayNext, cmd.CmdMsg.MsgInstant, cmd.CmdMsg.MsgIcon, cmd.CmdMsg.MsgBank, cmd.CmdMsg.MsgColor);

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["CINEMA_START_RAISE"]) then
      self.CinemaObj:raise();

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["CINEMA_START_HIDE"]) then
      self.CinemaObj:hide();

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["HIDE_PANEL"]) then
      process_options(OPT_TOGGLE_PANEL, 0, 0);
      self.PanelHidden = true;

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["SHOW_PANEL"]) then
      process_options(OPT_TOGGLE_PANEL, 1, 0);
      self.PanelHidden = false;

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["SPAWN_THING"]) then
      if (cmd.CmdSpawnThingType ~= nil) then
        if (cmd.CmdSpawnThingModel ~= nil and cmd.CmdSpawnThingOwner ~= nil) then
          local c3d = Coord3D.new();
          coord2D_to_coord3D(cmd.CmdTargetCoord, c3d);
          local t_thing = createThing(cmd.CmdSpawnThingType, cmd.CmdSpawnThingModel, cmd.CmdSpawnThingOwner, c3d, false, false);

          if (cmd.CmdSpawnThingType == T_PERSON) then
            createThing(T_EFFECT, M_EFFECT_SPHERE_EXPLODE_1, 8, c3d, false, false);
          end

          if (cmd.CmdSpawnThingBufIdx ~= nil) then
            table.insert(self.ThingBuffers[cmd.CmdSpawnThingBufIdx], t_thing.ThingNum);
          end
        end
      end

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["SPAWN_THINGS"]) then
      if (cmd.CmdSpawnThingType ~= nil) then
        if (cmd.CmdSpawnThingModel ~= nil and cmd.CmdSpawnThingOwner ~= nil) then
          local c3d = Coord3D.new();
          coord2D_to_coord3D(cmd.CmdTargetCoord, c3d);

          if (cmd.CmdSpawnThingAmount ~= nil) then
            for i = 1, cmd.CmdSpawnThingAmount do
              local t_thing = createThing(cmd.CmdSpawnThingType, cmd.CmdSpawnThingModel, cmd.CmdSpawnThingOwner, c3d, false, false);

              if (cmd.CmdSpawnThingBufIdx ~= nil) then
                table.insert(self.ThingBuffers[cmd.CmdSpawnThingBufIdx], t_thing.ThingNum);
              end
            end

            if (cmd.CmdSpawnThingType == T_PERSON) then
              createThing(T_EFFECT, M_EFFECT_SPHERE_EXPLODE_1, 8, c3d, false, false);
            end
          end
        end
      end

      self.WaitCount = cmd.CmdWaitCount;

      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["CLEAR_THING_BUFFER"]) then
      if (cmd.CmdSpawnThingBufIdx ~= nil) then
        self.ThingBuffers[cmd.CmdSpawnThingBufIdx] = {};
      end

      self.WaitCount = cmd.CmdWaitCount;

      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["PLACE_DOWN_SHAPE"]) then
      if (cmd.CmdSpawnThingModel ~= nil) then
        local mapIdx = world_coord2d_to_map_idx(cmd.CmdTargetCoord);

        process_shape_map_elements(mapIdx, cmd.CmdSpawnThingModel, cmd.CmdRadius, cmd.CmdSpawnThingOwner, SHME_MODE_SET_PERM);
      end

      self.WaitCount = cmd.CmdWaitCount;

      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["CMD_PATROL"]) then
      if (cmd.CmdTargetCoord ~= nil) then
        local cmd_1 = Commands.new();
        local cti = CmdTargetInfo.new();

        cti.TIdxSize.MapIdx = world_coord2d_to_map_idx(cmd.CmdTargetCoord);
        cti.TIdxSize.CellsX = cmd.CmdRadius;
        cti.TIdxSize.CellsZ = cmd.CmdRadius;

        update_cmd_list_entry(cmd_1, CMD_GUARD_AREA, cti, 0);

        for j,tidx in ipairs(self.ThingBuffers[cmd.CmdSpawnThingBufIdx]) do
          local t = GetThing(tidx);

          if (t ~= nil) then
            if (t.Type == T_PERSON) then
              t.Flags = t.Flags | TF_RESET_STATE;
              remove_all_persons_commands(t);

              if (cmd_1.CommandType ~= CMD_NONE) then
                add_persons_command(t, cmd_1, 0);
              end
            end
          end
        end
      end

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["CMD_PATROL_2P"]) then
      if (cmd.CmdTargetCoord ~= nil and cmd.CmdEndCoord ~= nil) then
        local cmd_1 = Commands.new();
        local cmd_2 = Commands.new();
        local cti = CmdTargetInfo.new();

        cti.TIdxSize.MapIdx = world_coord2d_to_map_idx(cmd.CmdTargetCoord);
        cti.TargetCoord = cmd.CmdTargetCoord;
        cti.TIdxSize.CellsX = cmd.CmdRadius;
        cti.TIdxSize.CellsZ = cmd.CmdRadius;
        local flags = 0;
        flags = flags | CMD_FLAG_CONTINUE_CMD;
        update_cmd_list_entry(cmd_1, CMD_GUARD_AREA_PATROL, cti, flags);

        cti.TIdxSize.MapIdx = world_coord2d_to_map_idx(cmd.CmdEndCoord);
        cti.TargetCoord = cmd.CmdEndCoord;
        cti.TIdxSize.CellsX = 0;
        cti.TIdxSize.CellsZ = 0;

        update_cmd_list_entry(cmd_2, CMD_GUARD_AREA_PATROL, cti, flags);

        for j,tidx in ipairs(self.ThingBuffers[cmd.CmdSpawnThingBufIdx]) do
          local t = GetThing(tidx);

          if (t ~= nil) then
            if (t.Type == T_PERSON) then
              t.Flags = t.Flags | TF_RESET_STATE;
              remove_all_persons_commands(t);

              if (cmd_1.CommandType ~= CMD_NONE) then
                add_persons_command(t, cmd_1, 0);
              end

              if (cmd_2.CommandType ~= CMD_NONE) then
                add_persons_command(t, cmd_2, 1);
              end
            end
          end
        end
      end

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["CMD_BUILD_BLDG"]) then
      if (cmd.CmdTargetCoord ~= nil) then
        local me_ec = world_coord2d_to_map_ptr(cmd.CmdTargetCoord);
        local cmd_1 = Commands.new();
        local cti = CmdTargetInfo.new();

        if (not me_ec.ShapeOrBldgIdx:isNull()) then
          cti.TMIdxs.TargetIdx = me_ec.ShapeOrBldgIdx;
          cti.TMIdxs.MapIdx = world_coord2d_to_map_idx(me_ec.ShapeOrBldgIdx:get().Pos.D2);

          update_cmd_list_entry(cmd_1, CMD_BUILD_BUILDING, cti, CMD_FLAG_AUTO_CMD);
        end

        for j,tidx in ipairs(self.ThingBuffers[cmd.CmdSpawnThingBufIdx]) do
          local t = GetThing(tidx);

          if (t ~= nil) then
            if (t.Type == T_PERSON) then
              t.Flags = t.Flags | TF_RESET_STATE;
              remove_all_persons_commands(t);

              if (cmd_1.CommandType ~= CMD_NONE) then
                add_persons_command(t, cmd_1, 0);
              end
            end
          end
        end
      end

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["CMD_CHOP_TREE"]) then
      local t_tree = nil;
      if (cmd.CmdTargetCoord ~= nil) then
        local stop_process = false;
        SearchMapCells(SQUARE, 0, 0, cmd.CmdRadius, world_coord2d_to_map_idx(cmd.CmdTargetCoord), function(me)
          me.MapWhoList:processList(function(t)
            if (t.Type == T_SCENERY) then
              if (t.Model <= 6) then
                t_tree = t;
                stop_process = true;
                return false;
              end
            end
            return true;
          end);

          if (stop_process) then
            return false;
          end

          return true;
        end);

        if (t_tree ~= nil) then
          local cmd_1 = Commands.new();
          local cmd_2 = Commands.new();

          local cti = CmdTargetInfo.new();

          cti.TargetCoord.Xpos = t_tree.Pos.D2.Xpos;
          cti.TargetCoord.Zpos = t_tree.Pos.D2.Zpos;

          update_cmd_list_entry(cmd_1, CMD_GET_WOOD, cti, CMD_FLAG_AUTO_CMD);

          if (cmd.CmdEndCoord ~= nil) then
            --let's check if end coord has any shape or bldg
            local me_ec = world_coord2d_to_map_ptr(cmd.CmdEndCoord);

            if (not me_ec.ShapeOrBldgIdx:isNull()) then
              cti.TMIdxs.TargetIdx = me_ec.ShapeOrBldgIdx;
              cti.TMIdxs.MapIdx = world_coord2d_to_map_idx(me_ec.ShapeOrBldgIdx:get().Pos.D2);

              update_cmd_list_entry(cmd_2, CMD_BUILD_BUILDING, cti, CMD_FLAG_AUTO_CMD);
            end
          end

          for j,tidx in ipairs(self.ThingBuffers[cmd.CmdSpawnThingBufIdx]) do
            local t = GetThing(tidx);

            if (t ~= nil) then
              if (t.Type == T_PERSON) then
                t.Flags = t.Flags | TF_RESET_STATE;
                remove_all_persons_commands(t);

                if (cmd_1.CommandType ~= CMD_NONE) then
                  add_persons_command(t, cmd_1, 0);
                end

                if (cmd_2.CommandType ~= CMD_NONE) then
                  add_persons_command(t, cmd_2, 1);
                end
              end
            end
          end
        end
      end

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["SET_VARIABLE"]) then
      self.Variables[cmd.CmdSpawnThingBufIdx] = cmd.CmdRadius;

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["CMD_GOTO_CRD"]) then
      local cti = CmdTargetInfo.new();
      cti.TargetCoord.Xpos = cmd.CmdTargetCoord.Xpos;
      cti.TargetCoord.Zpos = cmd.CmdTargetCoord.Zpos;

      local cmd_1 = Commands.new();

      update_cmd_list_entry(cmd_1, CMD_GOTO_POINT, cti, 0);

      for j,tidx in ipairs(self.ThingBuffers[cmd.CmdSpawnThingBufIdx]) do
        local t = GetThing(tidx);

        if (t ~= nil) then
          if (t.Type == T_PERSON) then
            t.Flags = t.Flags | TF_RESET_STATE;
            remove_all_persons_commands(t);

            if (cmd_1.CommandType ~= CMD_NONE) then
              add_persons_command(t, cmd_1, 0);
            end
          end
        end
      end

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["ADD_THINGS"]) then
      if (cmd.CmdTargetCoord ~= nil) then
        local count = cmd.CmdSpawnThingAmount;
        local break_now = false;
        SearchMapCells(SQUARE, 0, 0, cmd.CmdRadius, world_coord2d_to_map_idx(cmd.CmdTargetCoord), function(me)
          if (not me.MapWhoList:isEmpty() and count > 0) then
            me.MapWhoList:processList(function(t)
              if (t.Type == cmd.CmdSpawnThingType or cmd.CmdSpawnThingType == -1) then
                if (t.Model == cmd.CmdSpawnThingModel or cmd.CmdSpawnThingModel == -1) then
                  if (t.Owner == cmd.CmdSpawnThingOwner or cmd.CmdSpawnThingOwner == -1) then
                    count = count - 1;
                    table.insert(self.ThingBuffers[cmd.CmdSpawnThingBufIdx], t.ThingNum);
                    if (count > 0) then return true; else break_now = true; return false; end
                  end
                end
              end

              if (count > 0) then return true; else break_now = true; return false; end
            end);
          end

          if (break_now) then return false; end
          return true;
        end);
      end

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["CMD_ATTACK_AREA"]) then
      local cmd_1 = Commands.new();
      local cti = CmdTargetInfo.new();

      cti.TIdxSize.MapIdx = world_coord2d_to_map_idx(cmd.CmdTargetCoord);
      cti.TIdxSize.CellsX = 4;
      cti.TIdxSize.CellsZ = 4;

      update_cmd_list_entry(cmd_1, CMD_ATTACK_AREA_2, cti, 0);

      for j,tidx in ipairs(self.ThingBuffers[cmd.CmdSpawnThingBufIdx]) do
        local t = GetThing(tidx);

        if (t ~= nil) then
          t.Flags = t.Flags | TF_RESET_STATE;
          remove_all_persons_commands(t);

          if (cmd_1.CommandType ~= CMD_NONE) then
            add_persons_command(t, cmd_1, 0);
          end
        end
      end

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["BREAK_ALLY"]) then
      set_players_enemies(cmd.CmdSpawnThingOwner, cmd.CmdSpawnThingAmount);
      set_players_enemies(cmd.CmdSpawnThingAmount, cmd.CmdSpawnThingOwner);

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    elseif (cmd.CmdType == CMD_TYPE["CAST_SPELL"]) then
      local s = getShaman(cmd.CmdSpawnThingOwner);
      if (s ~= nil) then
        local c3d = Coord3D.new();
        coord2D_to_coord3D(cmd.CmdTargetCoord, c3d);
        createThing(T_SPELL, cmd.CmdSpawnThingModel, cmd.CmdSpawnThingOwner, c3d, false, false);
      end

      self.WaitCount = cmd.CmdWaitCount;
      table.remove(self.Commands, 1);
    end
  end
end

function CSequence:addCommand_MoveThing(_thingIdx, _c2d, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["MOVE_THING"]);

  cmd.CmdTargetCoord = Coord2D.new();
  cmd.CmdTargetCoord.Xpos = _c2d.Xpos;
  cmd.CmdTargetCoord.Zpos = _c2d.Zpos;

  cmd.CmdThingLinkIdx = ObjectProxy.new();
  cmd.CmdThingLinkIdx:set(_thingIdx);
  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_AngleThing(_thingIdx, _angle, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["ANGLE_THING"]);

  cmd.CmdThingLinkIdx = ObjectProxy.new();
  cmd.CmdThingAngle = _angle;
  cmd.CmdThingLinkIdx:set(_thingIdx);
  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_QueueMsg(_string, _title, _delay, _instant, _icon, _bank, _color, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["QUEUE_MSG"]);

  cmd.CmdMsg = CMsg:createMsg();
  cmd.CmdWaitCount = _waitCount or 0;
  cmd.CmdMsg.MsgString = _string or nil;
  cmd.CmdMsg.MsgTitle = _title or nil;
  cmd.CmdMsg.MsgIcon = _icon or nil;
  cmd.CmdMsg.MsgBank = _bank or 0;
  cmd.CmdMsg.MsgColor = _color or 0;
  cmd.CmdMsg.DelayNext = _delay or 0;
  cmd.CmdMsg.MsgInstant = _instant or false;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_CinemaRaise(_waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["CINEMA_START_RAISE"]);

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_CinemaHide(_waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["CINEMA_START_HIDE"]);

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_HidePanel(_waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["HIDE_PANEL"]);

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_ShowPanel(_waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["SHOW_PANEL"]);

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_SpawnThing(_thingBufferIdx, _thingType, _thingModel, _playerNum, _coord2D, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["SPAWN_THING"]);

  cmd.CmdTargetCoord = Coord2D.new();
  cmd.CmdTargetCoord.Xpos = _coord2D.Xpos;
  cmd.CmdTargetCoord.Zpos = _coord2D.Zpos;

  cmd.CmdSpawnThingType = _thingType or nil;
  cmd.CmdSpawnThingModel = _thingModel or nil;
  cmd.CmdSpawnThingOwner = _playerNum or nil;
  cmd.CmdSpawnThingBufIdx = _thingBufferIdx or nil;

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_SpawnThings(_thingBufferIdx, _amount, _thingType, _thingModel, _playerNum, _coord2D, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["SPAWN_THINGS"]);

  cmd.CmdTargetCoord = Coord2D.new();
  cmd.CmdTargetCoord.Xpos = _coord2D.Xpos;
  cmd.CmdTargetCoord.Zpos = _coord2D.Zpos;

  cmd.CmdSpawnThingType = _thingType or nil;
  cmd.CmdSpawnThingModel = _thingModel or nil;
  cmd.CmdSpawnThingOwner = _playerNum or nil;
  cmd.CmdSpawnThingBufIdx = _thingBufferIdx or nil;
  cmd.CmdSpawnThingAmount = _amount or nil;

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_ClearThingBuf(_thingBufferIdx, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["CLEAR_THING_BUFFER"]);

  cmd.CmdSpawnThingBufIdx = _thingBufferIdx or nil;

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_PlacePlan(_bldgModel, _orient, _playerNum, _coord2D, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["PLACE_DOWN_SHAPE"]);

  cmd.CmdTargetCoord = Coord2D.new();
  cmd.CmdTargetCoord.Xpos = _coord2D.Xpos;
  cmd.CmdTargetCoord.Zpos = _coord2D.Zpos;

  cmd.CmdSpawnThingModel = _bldgModel or nil;
  cmd.CmdSpawnThingOwner = _playerNum or nil;
  cmd.CmdRadius = _orient or 0;

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_ChopTree(_thingBufferIdx, _targetCoord, _radius, _endCoord, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["CMD_CHOP_TREE"]);

  cmd.CmdTargetCoord = Coord2D.new();
  cmd.CmdTargetCoord.Xpos = _targetCoord.Xpos;
  cmd.CmdTargetCoord.Zpos = _targetCoord.Zpos;

  cmd.CmdEndCoord = Coord2D.new();
  cmd.CmdEndCoord.Xpos = _endCoord.Xpos;
  cmd.CmdEndCoord.Zpos = _endCoord.Zpos;

  cmd.CmdSpawnThingBufIdx = _thingBufferIdx or nil;
  cmd.CmdRadius = _radius or 0;

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_BuildBldg(_thingBufferIdx, _targetCoord, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["CMD_BUILD_BLDG"]);

  cmd.CmdTargetCoord = Coord2D.new();
  cmd.CmdTargetCoord.Xpos = _targetCoord.Xpos;
  cmd.CmdTargetCoord.Zpos = _targetCoord.Zpos;

  cmd.CmdSpawnThingBufIdx = _thingBufferIdx or nil;

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_PatrolArea(_thingBufferIdx, _targetCoord, _radius, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["CMD_PATROL"]);

  cmd.CmdTargetCoord = Coord2D.new();
  cmd.CmdTargetCoord.Xpos = _targetCoord.Xpos;
  cmd.CmdTargetCoord.Zpos = _targetCoord.Zpos;

  cmd.CmdSpawnThingBufIdx = _thingBufferIdx or nil;
  cmd.CmdRadius = _radius or 0;

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_Patrol2P(_thingBufferIdx, _c2d_1, _c2d_2, _radius, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["CMD_PATROL_2P"]);

  cmd.CmdTargetCoord = Coord2D.new();
  cmd.CmdTargetCoord.Xpos = _c2d_1.Xpos;
  cmd.CmdTargetCoord.Zpos = _c2d_1.Zpos;

  cmd.CmdEndCoord = Coord2D.new();
  cmd.CmdEndCoord.Xpos = _c2d_2.Xpos;
  cmd.CmdEndCoord.Zpos = _c2d_2.Zpos;

  cmd.CmdSpawnThingBufIdx = _thingBufferIdx or nil;
  cmd.CmdRadius = _radius or 0;

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_SetVar(_variableIdx, _value, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["SET_VARIABLE"]);

  cmd.CmdSpawnThingBufIdx = _variableIdx or nil;
  cmd.CmdRadius = _value or 0;

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_GotoPoint(_thingBufferIdx, _targetCoord, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["CMD_GOTO_CRD"]);

  cmd.CmdTargetCoord = Coord2D.new();
  cmd.CmdTargetCoord.Xpos = _targetCoord.Xpos;
  cmd.CmdTargetCoord.Zpos = _targetCoord.Zpos;

  cmd.CmdSpawnThingBufIdx = _thingBufferIdx;

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_AddThings(_thingBufferIdx, _amount, _thingType, _thingModel, _playerNum, _targetCoord, _radius, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["ADD_THINGS"]);

  cmd.CmdTargetCoord = Coord2D.new();
  cmd.CmdTargetCoord.Xpos = _targetCoord.Xpos;
  cmd.CmdTargetCoord.Zpos = _targetCoord.Zpos;

  cmd.CmdRadius = _radius or 0;
  cmd.CmdSpawnThingType = _thingType or -1;
  cmd.CmdSpawnThingModel = _thingModel or -1;
  cmd.CmdSpawnThingOwner = _playerNum or -1;
  cmd.CmdSpawnThingAmount = _amount or 0;
  cmd.CmdSpawnThingBufIdx = _thingBufferIdx or nil;

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_AttackPos(_thingBufferIdx, _targetCoord, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["CMD_ATTACK_AREA"]);

  cmd.CmdTargetCoord = Coord2D.new();
  cmd.CmdTargetCoord.Xpos = _targetCoord.Xpos;
  cmd.CmdTargetCoord.Zpos = _targetCoord.Zpos;

  cmd.CmdSpawnThingBufIdx = _thingBufferIdx or nil;

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_BreakAlliance(_pn1, _pn2, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["BREAK_ALLY"]);

  cmd.CmdSpawnThingOwner = _pn1 or 0;
  cmd.CmdSpawnThingAmount = _pn2 or 0;

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:addCommand_CastSpellAt(_playerNum, _spellModel, _targetCoord, _waitCount)
  local cmd = CSeqCommand:createCmd(CMD_TYPE["CAST_SPELL"]);

  cmd.CmdTargetCoord = Coord2D.new();
  cmd.CmdTargetCoord.Xpos = _targetCoord.Xpos;
  cmd.CmdTargetCoord.Zpos = _targetCoord.Zpos;

  cmd.CmdSpawnThingOwner = _playerNum or 0;
  cmd.CmdSpawnThingModel = _spellModel or 0;

  cmd.CmdWaitCount = _waitCount or 0;

  table.insert(self.Commands, cmd);
end

function CSequence:postLoadItems()
  if (self.PanelHidden) then
    process_options(OPT_TOGGLE_PANEL, 0, 0);
  end
end

function CSequence:setupMagicalShield(_pn, _manareq, _maxshots)
  self.Magic:setShots(_maxshots);
  self.Magic:setCost(_manareq);
  self.Magic:bindShaman(_pn);
end

function CSequence:hidePanel()
  process_options(OPT_TOGGLE_PANEL, 0, 0);
  self.PanelHidden = true;
end

function CSequence:showPanel()
  process_options(OPT_TOGGLE_PANEL, 1, 0);
  self.PanelHidden = false;
end

function CSequence:getVar(_varIdx)
  return self.Variables[_varIdx];
end

function CSequence:setVar(_varIdx, _value)
  self.Variables[_varIdx] = _value;
end
