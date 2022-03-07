CPrisonThing = {};
CPrisonThing.__index = CPrisonThing;

setmetatable(CPrisonThing, {
  __call = function(cls, ...)
    return cls.new(...);
  end,
});

function CPrisonThing:createPrison()
  local self = setmetatable({}, CPrisonThing);

  self.ThingProxy = ObjectProxy.new();
  self.YieldBraves = 0;
  self.YieldWars = 0;
  self.YieldPriests = 0;
  self.YieldFws = 0;
  self.YieldOwner = 0;
  self.YieldGiven = false;
  self.C3D = Coord3D.new();

  return self;
end

function CPrisonThing:saveData(sd)
  sd:push_int(self.YieldBraves);
  sd:push_int(self.YieldWars);
  sd:push_int(self.YieldPriests);
  sd:push_int(self.YieldFws);
  sd:push_int(self.YieldOwner);
  sd:push_bool(self.YieldGiven);

  sd:push_int(self.C3D.Xpos);
  sd:push_int(self.C3D.Zpos);
  sd:push_int(self.C3D.Ypos);

  local proxy_saved = false;
  if (not self.ThingProxy:isNull()) then
    proxy_saved = true;

    sd:push_int(self.ThingProxy:getThingNum());
  end

  sd:push_bool(proxy_saved);
end

function CPrisonThing:loadData(ld)
  local proxy_load = ld:pop_bool();

  if (proxy_load) then
    local thing_num = ld:pop_int();

    self.ThingProxy:set(thing_num);
  end

  self.C3D.Ypos = ld:pop_int();
  self.C3D.Zpos = ld:pop_int();
  self.C3D.Xpos = ld:pop_int();

  self.YieldGiven = ld:pop_bool();
  self.YieldOwner = ld:pop_int();
  self.YieldFws = ld:pop_int();
  self.YieldPriests = ld:pop_int();
  self.YieldWars = ld:pop_int();
  self.YieldBraves = ld:pop_int();
end

function CPrisonThing:setYields(_owner, _braves, _wars, _fws, _priests)
  self.YieldOwner = _owner or 0;
  self.YieldBraves = _braves or 0;
  self.YieldWars = _wars or 0;
  self.YieldFws = _fws or 0;
  self.YieldPriests = _priests or 0;
end

function CPrisonThing:setCoord(_c3d)
  self.C3D.Xpos = _c3d.Xpos;
  self.C3D.Zpos = _c3d.Zpos;
  self.C3D.Ypos = _c3d.Ypos;
end

function CPrisonThing:setProxy(_thingNum)
  self.ThingProxy:set(_thingNum);
end

function CPrisonThing:process()
  if (not self.ThingProxy:isNull()) then
    -- local t = self.ThingProxy:get();
    --
    -- if (t ~= nil) then
    --   t.DrawInfo.DrawNum = 160;
    -- end

    return true;
  else
    --prison was destroyed, spawn braves!
    if (not self.YieldGiven) then
      for i = 1, self.YieldBraves do
        createThing(T_PERSON, M_PERSON_BRAVE, self.YieldOwner, self.C3D, false, false);
      end

      for i = 1, self.YieldWars do
        createThing(T_PERSON, M_PERSON_WARRIOR, self.YieldOwner, self.C3D, false, false);
      end

      for i = 1, self.YieldFws do
        createThing(T_PERSON, M_PERSON_SUPER_WARRIOR, self.YieldOwner, self.C3D, false, false);
      end

      for i = 1, self.YieldPriests do
        createThing(T_PERSON, M_PERSON_RELIGIOUS, self.YieldOwner, self.C3D, false, false);
      end

      return false;
    end
    return false;
  end
end
