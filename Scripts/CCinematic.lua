CCinematic = {};
CCinematic.__index = CCinematic;

setmetatable(CCinematic, {
  __call = function(cls, ...)
    return cls.new(...);
  end,
});

function CCinematic:createC()
  local self = setmetatable({}, CCinematic);

  self.CRaiseAmt = 0;
  self.CColor = 172; --default
  self.CRaise = false;

  return self;
end

function CCinematic:saveData(sd)
  sd:push_bool(self.CRaise);
  sd:push_int(self.CRaiseAmt);
  sd:push_int(self.CColor);
end

function CCinematic:loadData(ld)
  self.CColor = ld:pop_int();
  self.CRaiseAmt = ld:pop_int();
  self.CRaise = ld:pop_bool();
end

function CCinematic:setColor(_clr)
  self.CColor = _clr & 255;
end

function CCinematic:raise()
  self.CRaise = true;
end

function CCinematic:raiseInstantly()
  self.CRaiseAmt = ScreenHeight() >> 3;
  self.CRaise = true;
end

function CCinematic:hide()
  self.CRaise = false;
end

function CCinematic:hideInstantly()
  self.CRaiseAmt = 0;
  self.CRaise = false;
end

function CCinematic:renderView()
  local rectTop = TbRect.new();
  local rectBottom = TbRect.new();

  if (self.CRaise) then
    if (self.CRaiseAmt < (ScreenHeight() >> 3)) then
      self.CRaiseAmt = self.CRaiseAmt + 1;
    end
  else
    if (self.CRaiseAmt > 0) then
      self.CRaiseAmt = self.CRaiseAmt - 1;
    end
  end

  rectTop.Left = 0;
  rectTop.Right = ScreenWidth();
  rectTop.Bottom = 0 + self.CRaiseAmt;
  rectTop.Top = 0;

  rectBottom.Left = 0;
  rectBottom.Right = ScreenWidth();
  rectBottom.Bottom = ScreenHeight();
  rectBottom.Top = ScreenHeight() - self.CRaiseAmt;

  LbDraw_Rectangle(rectTop, self.CColor);
  LbDraw_Rectangle(rectBottom, self.CColor);
end
