CTimer = {};
CTimer.__index = CTimer;

setmetatable(CTimer, {
  __call = function(cls, ...)
    return cls.new(...);
  end,
});

function CTimer:register()
  local self = setmetatable({}, CTimer);

  self.Active = false;
  self.BaseTime = 0;
  self.CurrentTime = 0;
  self.RandomFactor = 0;

  return self;
end

function CTimer:saveData(sd)
  sd:push_int(self.BaseTime);
  sd:push_int(self.CurrentTime);
  sd:push_int(self.RandomFactor);
  sd:push_bool(self.Active);
end

function CTimer:loadData(ld)
  self.RandomFactor = ld:pop_int();
  self.CurrentTime = ld:pop_int();
  self.BaseTime = ld:pop_int();
  self.Active = ld:pop_bool();
end

function CTimer:setTime(time, randomness)
  self.BaseTime = time;
  self.RandomFactor = randomness;
  self.CurrentTime = math.random(time, time + math.random(0, randomness));
  self.Active = true;
end

function CTimer:process()
  if (self.Active) then
    if (self.CurrentTime > 0) then
      self.CurrentTime = self.CurrentTime - 1;

      if (self.CurrentTime == 0) then
        self.CurrentTime = math.random(self.BaseTime, self.BaseTime + math.random(0, self.RandomFactor));
        return true;
      end
    end
  end

  return false;
end
