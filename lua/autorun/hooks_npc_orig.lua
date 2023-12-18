      -- Metatable of the desc class. Global data
local mtDesk = {}
      -- Metatable method indexing
      mtDesk.__index = mtDesk
      -- Where to go after pulling
      mtDesk.__out = Vector(800, -400,-143.719)
      -- Table of all the NPC
      mtDesk.__npc = {}
      -- Caontains the NPC which exits
      mtDesk.__npx = nil
      -- NPC Move type
      mtDesk.__move = SCHED_FORCED_GO_RUN
      -- NPC Exit Interval
      mtDesk.__pull = 16 -- in seconds
      -- NPC Arrival Interval
      mtDesk.__push = 2 -- in seconds
      -- Check when shedule is finished
      mtDesk.__shed = 0.1 -- in seconds
      -- Remove after the final destination
      mtDesk.__dstr = 1 -- in seconds
      -- Amount of units to scan for NPC
      mtDesk.__tnpc = 100
      -- Function filter for NPC trace
      mtDesk.__trft = {
        start  = Vector(), -- Start position
        endpos = Vector(), -- End position
        ignoreworld = true, -- Ignore hitting world
        filter = function(ent) return ent:IsNPC() end
      }
local function newDesk(pos)
  local mvPos, miSiz = Vector(pos), 1
  local mtData = {Size = 0}
        mtData[1] = {Pos = Vector(mvPos), Ent = nil}
  local self = {}; setmetatable(self, mtDesk)
  -- Extend the desk queue
  function self:Extend(dir, dst, siz)
    local vDir = Vector(dir); vDir:Normalize()
      if(vDir:IsZero()) then return nil end
    local nDst = (tonumber(dst) or 0)
      if(nDst <= 0) then return nil end
    local iSiz = math.floor(tonumber(siz) or 0)
      if(iSiz <= 0) then return nil end
    local vTop = mtData[miSiz].Pos
    local vPos =  Vector((miSiz == 1) and mvPos or vTop)
    for idx = 1, iSiz do
      local muo = (idx * nDst)
      mtData[miSiz + idx] = {Pos = Vector(), Ent = nil}
      mtData[miSiz + idx].Pos:Set(vPos + muo * vDir)
    end; miSiz = miSiz + iSiz;return self
  end
  -- Check when slot used
  function self:IsIndex(idx)
    local idx = (tonumber(idx) or 0)
          idx = math.floor(idx)
    if(idx < 1) then return nil end
    if(idx > miSiz) then return nil end
    return idx -- Actual index
  end
  -- Updates queue node
  function self:SetNode(idx, pos)
    local idx = self:IsIndex(idx)
    if(not idx) then return self end
    mtData[idx].Pos:Set(pos)
    return self
  end
  -- Reads queue node
  function self:GetNode(idx)
    local idx = self:IsIndex(idx)
    if(not idx) then return Vector() end
    return Vector(mtData[idx].Pos)
  end
  -- Reads queue NPC
  function self:SetEntity(idx, ent)
    local idx = self:IsIndex(idx)
    if(not idx) then return self end
    if(not IsValid(ent)) then return self end
    mtData[idx].Ent = ent; return self
  end
  -- Reads queue NPC
  function self:GetEntity(idx)
    local idx = self:IsIndex(idx)
    if(not idx) then return nil end
    return mtData[idx].Ent
  end
  -- Check for valid entity under index
  function self:IsEntity(idx)
    local idx = self:IsIndex(idx)
    if(not idx) then return false end
    return IsValid(mtData[idx].Ent)
  end
  -- Check whenever NPC exists
  function self:IsHere(npc)
    if(not IsValid(npc)) then return end
    for idx = 1, miSiz do
      local v = mtData[idx]
      if(IsValid(v.Ent) and v.Ent == npc) then
        return true
      end
    end; return false
  end
  -- Move NPC to desired position
  function self:Move(npc, pos)
    if(not IsValid(npc)) then return end
    npc:SetLastPosition(pos)
    npc:SetSchedule(mtDesk.__move)
  end
  -- Check when full
  function self:IsFull()
    return (mtData.Size >= miSiz)
  end
  -- Check when slot used
  function self:GetTrace(idx)
    local idx = self:IsIndex(idx)
    if(not idx) then return nil end
    local mar = Vector(0,0,mtDesk.__tnpc)
    local pos = mtData[idx].Pos
    local dat = mtDesk.__trft
          dat.start:Set(pos); dat.start:Add(mar)
          mar.z = -mar.z -- We need for top to bottom
          dat.endpos:Set(pos); dat.endpos:Add(mar)
    local trn = util.TraceLine(mtDesk.__trft)
    return trn.Hit -- NPC has been hit
  end
  -- Push NPC at the end of the queue
  function self:Push(npc)
    if(self:IsFull()) then return self end
    if(not IsValid(npc)) then return self end
    if(self:IsHere(npc)) then return self end
    mtData.Size = mtData.Size + 1
    mtData[mtData.Size].Ent = npc
    return self
  end
  -- Pull NPC at the front of the queue
  function self:Pull()
    if(mtData.Size == 0) then return nil end
    local npc = mtData[1].Ent
    if(not IsValid(npc)) then return nil end
    mtData.Size = mtData.Size - 1
    mtData[1].Ent = nil
    return npc
  end
  -- Rearange NPC in the queue
  function self:Arrange()
    local idx = 0
    for crr = 1, miSiz do
      if(IsValid(mtData[crr].Ent)) then
      else
        for src = (crr + 1), miSiz do
          if(IsValid(mtData[src].Ent)) then
            idx = src -- Save index of first valid
          else
            idx = 0 -- Could not find NPC
            mtData[src].Ent = nil
          end
          if(idx ~= 0 and not IsValid(mtData[crr].Ent)) then
            mtData[crr].Ent = mtData[idx].Ent
            mtData[idx].Ent = nil
          end
        end -- When npc is found assign it to the empty slot
      end
    end; return self
  end
  function self:Stay()
    for idx = 1, miSiz do
      local v = mtData[idx]
      if(IsValid(v.Ent)) then
        self:Move(v.Ent, v.Pos)
      end
    end; return self
  end
  function self:GerRadius(org, mar)
    local pos = LocalPlayer():GetPos()
    return (mar * 200) / org:Distance(pos)
  end
  function self:Draw()
    cam.Start2D()
      local str, ben = mtData[1].Pos, self:GetTrace(1)
      local xy = str:ToScreen()
      local cr, cg = (ben and 0 or 255), (ben and 255 or 0)
      surface.SetDrawColor(cr, cg, 0)
      surface.DrawCircle(xy.x, xy.y, self:GerRadius(str, 10), cr, cg, 0)
      for cnt = 2, miSiz do
        local poc = mtData[cnt].Pos
        local pop = mtData[cnt-1].Pos
        local xyc = poc:ToScreen()
        local xyp = pop:ToScreen()
        ben = self:GetTrace(cnt)
        cr = (ben and 0 or 255)
        cg = (ben and 255 or 0)
        surface.SetDrawColor(cr, cg, 0)
        surface.DrawLine(xyp.x, xyp.y, xyc.x, xyc.y)
        surface.DrawCircle(xyc.x, xyc.y, self:GerRadius(poc, 10), cr, cg, 0)
      end
      local poo = mtDesk.__out
      local xyo = poo:ToScreen()
      surface.SetDrawColor(255, 255, 0)
      surface.DrawLine(xy.x, xy.y, xyo.x, xyo.y)
      surface.DrawCircle(xyo.x, xyo.y, self:GerRadius(poo, 20), 255, 255, 0)
    cam.End2D()
    return self
  end
  return self
end

local oDesk = newDesk(Vector(646.266 ,-949.261,-143.719))
      oDesk:Extend(Vector(-1,0,0), 100, 5)
      oDesk:Extend(Vector(0,1,0), 100, 1)
      oDesk:Extend(Vector(1,0,0), 100, 4)
      oDesk:Extend(Vector(0,1,0), 100, 1)
      oDesk:Extend(Vector(-1,0,0), 100, 4)
local vNod = oDesk:GetNode(10); vNod.z = vNod.z + 40
      oDesk:SetNode(10, vNod)

if(not oDesk) then error("Could not allocate desk object!") end

if(CLIENT) then
  hook.Remove("PreDrawHUD", "hook_npc_queue_cl")
  hook.Add("PreDrawHUD", "hook_npc_queue_cl",
    function()
      oDesk:Draw()
    end)
else
  hook.Remove("PlayerSpawnedNPC", "hook_npc_queue")
  hook.Add("PlayerSpawnedNPC", "hook_npc_queue",
    function(ply, npc)
      if(not IsValid(npc)) then return end
      mtDesk.__npc[tostring(npc:EntIndex())] = npc
      oDesk:Push(npc)
    end)

  -- Timer function to check availability and handle NPC arrivals
  -- It will constantly try to pit NPCs at the queue desk
  timer.Remove("hook_npc_queue_push")
  timer.Create("hook_npc_queue_push", mtDesk.__push, 0,
    function()
      for idx, npc in pairs(mtDesk.__npc) do
        oDesk:Push(npc):Arrange():Stay()
      end
    end)

  -- Timer function to check when NPC leaves
  timer.Remove("hook_npc_queue_pull")
  timer.Create("hook_npc_queue_pull", mtDesk.__pull, 0,
    function()
      if(IsValid(mtDesk.__npx)) then return end
      mtDesk.__npx = oDesk:Pull()
      if(IsValid(mtDesk.__npx)) then
        oDesk:Move(mtDesk.__npx, mtDesk.__out)
        mtDesk.__npc[tostring(mtDesk.__npx:EntIndex())] = nil
      end
      oDesk:Arrange():Stay()
    end)

  timer.Remove("hook_npc_queue_ched")
  timer.Create("hook_npc_queue_ched", mtDesk.__shed, 0,
    function()
      if(not IsValid(mtDesk.__npx)) then return end
      if(mtDesk.__npx:IsCurrentSchedule(mtDesk.__move)) then return end
      if(mtDesk.__npx:GetPos():DistToSqr(mtDesk.__out) > 10) then return end
      timer.Simple(mtDesk.__dstr,
        function()
          SafeRemoveEntity(mtDesk.__npx)
          mtDesk.__npx = nil
        end)
    end)
end
