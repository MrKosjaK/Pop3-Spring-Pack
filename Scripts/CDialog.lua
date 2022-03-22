CDialog = {};
CDialog.__index = CDialog;

setmetatable(CDialog, {
  __call = function(cls, ...)
    return cls.new(...);
  end,
});

CMsg = {};
CMsg.__index = CMsg;

setmetatable(CMsg, {
  __call = function(cls, ...)
    return cls.new(...);
  end,
});

function CMsg:createMsg()
  local self = setmetatable({}, CMsg);

  self.MsgString = nil;
  self.MsgTitle = nil;
  self.MsgIcon = nil;
  self.MsgBank = nil;
  self.MsgColor = 0;
  self.MsgInstant = false;
  self.DelayNext = 0;

  return self;
end

function CDialog:createDlg()
  local self = setmetatable({}, CDialog);

  self.DialogMsgQueue = {};
  self.MsgCache = nil;
  self.ScreenPosX = 0;
  self.ScreenPosY = 0;
  self.DialogWidth = 0;
  self.DialogHeight = 0;
  self.DialogTicker = 0;

  --NEW
  self.DlgLines = {};
  self.DlgFinished = false;
  self.DlgWait = 0;
  self.DlgTitle = nil;
  self.DlgFont = 4;

  self.DlgCurrLine = 0;
  self.DlgCurrChar = 0;
  self.DlgDraw = false;
  self.DlgDrawIcon = nil;
  self.DlgDrawBank = nil;
  self.DlgDrawSprIdx = nil;
  self.DlgDrawBoxClr = 0;

  return self;
end

function CDialog:setDimensions(_width, _height)
  self.DialogWidth = _width;
  self.DialogHeight = _height;
end

function CDialog:setPosition(_x, _y)
  self.ScreenPosX = _x;
  self.ScreenPosY = _y;
end

function CDialog:setTitle(_str)
  self.DlgTitle = _str;
end

function CDialog:setBackgroundColor(_clr)
  self.DlgDrawBoxClr = _clr & 255;
end

function CDialog:setFont(_font)
  self.DlgFont = _font;
end

function CDialog:setIcon(_spriteIdx, _bank);
  self.DlgDrawIcon = get_sprite(_bank, _spriteIdx);
  self.DlgDrawBank = _bank;
  self.DlgDrawSprIdx = _spriteIdx;
end

function CDialog:clearDrawItems()
  self.DlgDrawIcon = nil;
  self.DlgDrawBank = nil;
  self.DlgDrawSprIdx = nil;
  self.DlgDrawBoxClr = 0;
end

function CDialog:setWaitCount(_count)
  self.DlgWait = _count or 0;
end

function CDialog:queueMessage(_string, _title, _delay, _instant, _icon, _bank, _color)
  local msg = CMsg:createMsg();

  msg.MsgString = _string or nil;
  msg.MsgTitle = _title or nil;
  msg.MsgIcon = _icon or nil;
  msg.MsgColor = _color or 0;
  msg.MsgBank = _bank or 0;
  msg.DelayNext = _delay or 0;
  msg.MsgInstant = _instant or false;

  if (#self.DialogMsgQueue == 0 and (not self.DlgFinished)) then
    if (self.DlgWait == 0) then
      self.DlgFinished = true;
    end
  end

  table.insert(self.DialogMsgQueue, msg);
end

function CDialog:processQueue()
  if (self.DlgWait > 0 and self.DlgFinished) then
    self.DlgWait = self.DlgWait - 1;
    do return end;
  else
    if (self.DlgFinished) then
      if (#self.DialogMsgQueue > 0) then
        local m = self.DialogMsgQueue[1];

        self:clearDrawItems();

        self:formatString(m.MsgString);
        self:setBackgroundColor(m.MsgColor);

        self.DlgCurrChar = 0;
        self.DlgCurrLine = 0;
        self.DlgTitle = nil;

        if (m.MsgInstant) then
          self.DlgCurrLine = #self.DlgLines;
        end

        if (m.MsgTitle ~= nil) then
          self:setTitle(m.MsgTitle);
        end

        if (m.MsgIcon ~= nil) then
          self:setIcon(m.MsgIcon, m.MsgBank or 0);
        end

        self.DlgWait = m.DelayNext;
        self.DlgFinished = false;

        self.DlgDraw = true;
        table.remove(self.DialogMsgQueue, 1);
      else
        self.DlgDraw = false;
        self.MsgCache = nil;
        self.DlgCurrChar = 0;
        self.DlgCurrLine = 0;
        self.DlgTitle = nil;
        self.DlgLines = {};
        self.DlgFinished = false;
      end
    end
  end
end

function CDialog:renderDialog()
  if (self.DlgDraw) then
    self.DialogTicker = self.DialogTicker + 1;

    local rect = TbRect.new();
    rect.Left = self.ScreenPosX - 16;
    rect.Right = rect.Left + self.DialogWidth + 16;
    rect.Top = self.ScreenPosY - 16;
    rect.Bottom = rect.Top + self.DialogHeight + 24;
    SetDrawFlagOn(8);
    LbDraw_Rectangle(rect, self.DlgDrawBoxClr);
    SetDrawFlagOff(8);

    if (self.DialogTicker >= 60) then
      self.DialogTicker = 0;
    end
    if (self.DlgDrawSprIdx ~= nil and self.DlgDrawIcon ~= nil) then
      LbDraw_Sprite(rect.Left - (self.DlgDrawIcon.Width >> 1), self.ScreenPosY + (self.DialogHeight >> 2) - (self.DlgDrawIcon.Height >> 1), self.DlgDrawIcon);
    end
    if (self.DlgTitle ~= nil) then
      PopSetFont(9);
      LbDraw_Text(self.ScreenPosX + 24, self.ScreenPosY - CharHeight2(), self.DlgTitle, 0);
    end
    PopSetFont(self.DlgFont);
    for i=0,#self.DlgLines-1 do
      if (i == self.DlgCurrLine) then
        LbDraw_Text(self.ScreenPosX, self.ScreenPosY + (CharHeight2() * i), string.sub(self.DlgLines[i+1], 0, self.DlgCurrChar), 0);
        if (self.DlgCurrChar >= string.len(self.DlgLines[i+1])) then
          if (self.DlgCurrLine <= #self.DlgLines) then
            self.DlgCurrLine = self.DlgCurrLine + 1;
            self.DlgCurrChar = 0;
          end
        end
        --speed of printing here
        if (self.DialogTicker % 4 == 0) then
          if (self.DlgCurrChar < string.len(self.DlgLines[i+1])) then
            queue_sound_event(nil, SND_EVENT_CONFIRM, (1<<0))
            self.DlgCurrChar = self.DlgCurrChar+1;
          end
        end
      elseif (i < self.DlgCurrLine) then
        LbDraw_Text(self.ScreenPosX, self.ScreenPosY + (CharHeight2() * i), self.DlgLines[i+1], 0);
      end
    end

    if (self.DlgCurrLine >= #self.DlgLines and (not self.DlgFinished)) then
      self.DlgFinished = true;
    end
  end
end

function CDialog:loadData(ld)
  local num_msg_lines = ld:pop_int();

  for i = 1, num_msg_lines do
    table.insert(self.DlgLines, ld:pop_string());
  end

  self.DialogTicker = ld:pop_int();
  self.DialogHeight = ld:pop_int();
  self.DlgDraw = ld:pop_bool();
  self.DlgFinished = ld:pop_bool();
  self.DlgDrawBoxClr = ld:pop_int();
  self.DlgCurrLine = ld:pop_int();
  self.DlgCurrChar = ld:pop_int();
  self.DlgWait = ld:pop_int();
  local DLG_BITS = ld:pop_int();

  if (DLG_BITS & (1 << 3) ~= 0) then
    self.DlgDrawSprIdx = ld:pop_int();
  end

  if (DLG_BITS & (1 << 2) ~= 0) then
    self.DlgDrawBank = ld:pop_int();
  end

  if (DLG_BITS & (1 << 1) ~= 0) then
    self.DlgTitle = ld:pop_string();
  end

  if (DLG_BITS & (1 << 0) ~= 0) then
    self.MsgCache = ld:pop_string();
  end

  if (self.DlgDrawSprIdx and self.DlgDrawBank) then
    self:setIcon(self.DlgDrawSprIdx, self.DlgDrawBank or 0);
  end

  local num_msgs = ld:pop_int();

  for i = 1, num_msgs do
    local MSG_BITS = ld:pop_int();

    local msg = CMsg:createMsg();

    msg.MsgInstant = ld:pop_bool();
    msg.DelayNext = ld:pop_int();
    msg.MsgColor = ld:pop_int();

    if (MSG_BITS & (1 << 3) ~= 0) then
      msg.MsgBank = ld:pop_int();
    end

    if (MSG_BITS & (1 << 2) ~= 0) then
      msg.MsgIcon = ld:pop_int();
    end

    if (MSG_BITS & (1 << 1) ~= 0) then
      msg.MsgTitle = ld:pop_string();
    end

    if (MSG_BITS & (1 << 0) ~= 0) then
      msg.MsgString = ld:pop_string();
    end

    table.insert(self.DialogMsgQueue, msg);
  end
end

function CDialog:saveData(sd)
  for i = #self.DialogMsgQueue, 1, -1 do
    --have to do MSG_BITS as well
    local MSG_BITS = 0;

    if (self.DialogMsgQueue[i].MsgString ~= nil) then
      MSG_BITS = MSG_BITS | (1 << 0);
      sd:push_string(self.DialogMsgQueue[i].MsgString);
    end

    if (self.DialogMsgQueue[i].MsgTitle ~= nil) then
      MSG_BITS = MSG_BITS | (1 << 1);
      sd:push_string(self.DialogMsgQueue[i].MsgTitle);
    end

    if (self.DialogMsgQueue[i].MsgIcon ~= nil) then
      MSG_BITS = MSG_BITS | (1 << 2);
      sd:push_int(self.DialogMsgQueue[i].MsgIcon);
    end

    if (self.DialogMsgQueue[i].MsgBank ~= nil) then
      MSG_BITS = MSG_BITS | (1 << 3);
      sd:push_int(self.DialogMsgQueue[i].MsgBank);
    end

    sd:push_int(self.DialogMsgQueue[i].MsgColor);
    sd:push_int(self.DialogMsgQueue[i].DelayNext);
    sd:push_bool(self.DialogMsgQueue[i].MsgInstant);
    sd:push_int(MSG_BITS);
  end

  sd:push_int(#self.DialogMsgQueue);

  local DLG_BITS = 0;

  if (self.MsgCache ~= nil) then
    DLG_BITS = DLG_BITS | (1 << 0);
    sd:push_string(self.MsgCache);
  end

  if (self.DlgTitle ~= nil) then
    DLG_BITS = DLG_BITS | (1 << 1);
    sd:push_string(self.DlgTitle);
  end

  if (self.DlgDrawBank ~= nil) then
    DLG_BITS = DLG_BITS | (1 << 2);
    sd:push_int(self.DlgDrawBank);
  end

  if (self.DlgDrawSprIdx ~= nil) then
    DLG_BITS = DLG_BITS | (1 << 3);
    sd:push_int(self.DlgDrawSprIdx);
  end

  sd:push_int(DLG_BITS);
  sd:push_int(self.DlgWait);
  sd:push_int(self.DlgCurrChar);
  sd:push_int(self.DlgCurrLine);
  sd:push_int(self.DlgDrawBoxClr);
  sd:push_bool(self.DlgFinished);
  sd:push_bool(self.DlgDraw);
  sd:push_int(self.DialogHeight);
  sd:push_int(self.DialogTicker);


  for i = #self.DlgLines, 1, -1 do
    sd:push_string(self.DlgLines[i]);
  end

  sd:push_int(#self.DlgLines);
end

function CDialog:formatString(_str)
  self.MsgCache = _str;
  self.DlgLines = {};

  PopSetFont(self.DlgFont);
  local str_width = string_width(_str);

  if (str_width < self.DialogWidth) then
    -- ok we want to scan for tags again...
    local new_line_str = "";
    local new_line_str_width = 0;
    for w in _str:gmatch("%S+") do
      if (w == "<br>") then
        if (string.len(new_line_str) > 0) then
          table.insert(self.DlgLines, new_line_str);
          new_line_str = "";
        end
        table.insert(self.DlgLines, " ");
        new_line_str_width = 0;
      elseif (w == "<bp>") then
        if (string.len(new_line_str) > 0) then
          table.insert(self.DlgLines, new_line_str);
          new_line_str = "";
        end
        new_line_str_width = 0;
      else
        new_line_str_width = string_width(new_line_str) + string_width(w);

        if (new_line_str_width < self.DialogWidth) then
          new_line_str = new_line_str .. w .. " ";
        else
          table.insert(self.DlgLines, new_line_str);
          new_line_str = w .. " ";
          new_line_str_width = 0;
        end
      end
    end

    table.insert(self.DlgLines, new_line_str);

    -- ok figure out required height for dialog box
    local height = 0;
    for i=1,#self.DlgLines do
      height = height + CharHeight2();
    end

    self.DialogHeight = height;
  else
    local new_line_str = "";
    local new_line_str_width = 0;
    for w in _str:gmatch("%S+") do
      if (w == "<br>") then
        if (string.len(new_line_str) > 0) then
          table.insert(self.DlgLines, new_line_str);
          new_line_str = "";
        end
        table.insert(self.DlgLines, " ");
        new_line_str_width = 0;
      elseif (w == "<bp>") then
        if (string.len(new_line_str) > 0) then
          table.insert(self.DlgLines, new_line_str);
          new_line_str = "";
        end
        new_line_str_width = 0;
      else
        new_line_str_width = string_width(new_line_str) + string_width(w);

        if (new_line_str_width < self.DialogWidth) then
          new_line_str = new_line_str .. w .. " ";
        else
          table.insert(self.DlgLines, new_line_str);
          new_line_str = w .. " ";
          new_line_str_width = 0;
        end
      end
    end

    if (string.len(new_line_str) > 0) then
      table.insert(self.DlgLines, new_line_str);
    end

    -- ok figure out required height for dialog box
    local height = 0;
    for i=1,#self.DlgLines do
      height = height + CharHeight2();
    end

    self.DialogHeight = height;
  end
end
