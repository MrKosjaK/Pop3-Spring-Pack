CMagicalShield = {};
CMagicalShield.__index = CMagicalShield;

setmetatable(CMagicalShield, {
  __call = function(cls, ...)
    return cls.new(...);
  end,
});

function CMagicalShield:register();
  local self = setmetatable({}, CMagicalShield);

  self.MaxCharges = 0;
  self.Charges = 0;
  self.ManaReq = 0;
  self.StoredMana = 0;
  self.ShamanIdx = ObjectProxy.new();

  return self;
end

function CMagicalShield:saveData(sd)
  local thing_saved = false;
  if (not self.ShamanIdx:isNull()) then
    thing_saved = true;
    sd:push_int(self.ShamanIdx:getThingNum());
  end

  sd:push_bool(thing_saved);
  sd:push_int(self.MaxCharges);
  sd:push_int(self.ManaReq);
  sd:push_int(self.Charges);
  sd:push_int(self.StoredMana);
end

function CMagicalShield:loadData(ld)
  self.StoredMana = ld:pop_int();
  self.Charges = ld:pop_int();
  self.ManaReq = ld:pop_int();
  self.MaxCharges = ld:pop_int();

  local thing_load = ld:pop_bool();
  if (thing_load) then
    local t_num = ld:pop_int();
    self.ShamanIdx:set(t_num);
  end
end

function CMagicalShield:bindShaman(_playerNum)
  local s = getShaman(_playerNum);
  if (s ~= nil) then
    self.ShamanIdx:set(s.ThingNum);
  end
end

function CMagicalShield:setCost(_cost)
  self.ManaReq = _cost or 0;
end

function CMagicalShield:setShots(_shots)
  self.MaxCharges = _shots or 0;
end

function CMagicalShield:process(_difficulty)
  if (self.Charges < self.MaxCharges) then
    if (not self.ShamanIdx:isNull()) then
      local p = getPlayer(self.ShamanIdx:get().Owner);
      local mana_generation = p.LastManaIncr;
      local multiplier = _difficulty; if (multiplier > 2) then multiplier = 2; end
      mana_generation = (mana_generation) >> multiplier;

      if (mana_generation + self.StoredMana >= self.ManaReq) then
        self.StoredMana = 0;
        self.Charges = self.Charges + 1;
      else
        self.StoredMana = self.StoredMana + mana_generation;
      end
    end
  end
end

function CMagicalShield:render()
  local gui_width = GFGetGuiWidth();
  local rect = TbRect.new();
  local rect2 = TbRect.new();

  local spr = get_sprite(0, 414);

  rect.Left = gui_width + 24;
  rect.Right = rect.Left + 64;
  rect.Top = ScreenHeight() >> 5;
  rect.Bottom = rect.Top + 17;

  LbDraw_Rectangle(rect, 184);

  rect2.Left = rect.Left + 4;
  --rect2.Right = rect2.Left + 252;
  rect2.Right = (rect2.Left) + math.floor(((rect.Right - rect2.Left - 3) * self.StoredMana) / self.ManaReq);
  rect2.Top = rect.Top + 4;
  rect2.Bottom = rect.Bottom - 4;


  local border = BorderLayout.new();
  border.TopLeft = 821;
  border.TopRight = border.TopLeft + 1;
  border.BottomLeft = border.TopRight + 1;
  border.BottomRight = border.BottomLeft + 1;
  border.Top = border.BottomRight + 1;
  border.Bottom = border.Top + 1;
  border.Left = border.Bottom + 1;
  border.Right = border.Left + 1;
  border.Centre = border.Right + 1;
  DrawStretchyButtonBox(rect, border);
  LbDraw_Rectangle(rect2, 221);
  LbDraw_Sprite(rect.Left - (spr.Width >> 1) - 8, rect.Top - 4, spr);

  for i = 1, self.MaxCharges do
    LbDraw_Sprite(rect.Left + 1 + (i * 4), rect.Bottom - 3, get_sprite(0, 55));
    if (i <= self.Charges) then
      LbDraw_Sprite(rect.Left + 1 + (i * 4), rect.Bottom - 3, get_sprite(0, 54));
    end
  end
end
