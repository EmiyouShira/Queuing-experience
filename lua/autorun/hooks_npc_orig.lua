      -- Metatable of the desc class. Global data
local mtQueue = {}
      -- Metatable method indexing
      mtQueue.__index = mtQueue
      -- Where to go after pulling
      mtQueue.__out = { ID = 0, -- Track the exit node
        Vector(3124.45,1278.14,16.2813),
        Vector(2787.98,1332.3,16.2813),
        Vector(2768.52,1426.19,16.2813),
        Vector(2701.32,1426.65,16.2813),
        Vector(2635.5,1241.34,16.2813)
      }
      -- Where to go after pulling
      mtQueue.__cout = Color(255,255,0,255)
      -- Table of all the NPC
      mtQueue.__npc = {}
      -- Caontains the NPC which exits
      mtQueue.__npx = nil
      -- Enable to act as a hive mind
      mtQueue.__hive = true
      -- NPC Move type
      mtQueue.__move = SCHED_FORCED_GO_RUN
      -- NPC Exit Interval
      mtQueue.__pull = 10 -- in seconds
      -- NPC Arrival Interval
      mtQueue.__push = 3 -- in seconds
      -- Check when shedule is finished
      mtQueue.__shed = 0.1 -- in seconds
      -- Remove after the final destination
      mtQueue.__dstr = 1 -- in seconds
      -- Amount of units to scan for NPC
      mtQueue.__tnpc = 100
      -- Color to pass for drawing
      mtQueue.__colr = Color(0,0,0,255)
      -- Function filter for NPC trace
      mtQueue.__trft = {
        start  = Vector(), -- Start position
        endpos = Vector(), -- End position
        ignoreworld = true, -- Ignore hitting world
        filter = function(ent) return ent:IsNPC() end
      }
local function NewQueue(pos)
  local mvPos, miSiz = Vector(pos), 1
  local mtData = {Size = 0}
        mtData[1] = {Pos = Vector(mvPos), Ent = nil}
  local self = {}; setmetatable(self, mtQueue)
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
  function self:GetIndex(idx)
    local idx = (tonumber(idx) or 0)
          idx = math.floor(idx)
    if(idx < 1) then return nil end
    if(idx > miSiz) then return nil end
    return idx -- Actual index
  end
  -- Updates queue node
  function self:SetNode(idx, pos)
    local idx = self:GetIndex(idx)
    if(not idx) then return self end
    mtData[idx].Pos:Set(pos)
    return self
  end
  -- Reads queue node
  function self:GetNode(idx)
    local idx = self:GetIndex(idx)
    if(not idx) then return Vector() end
    return Vector(mtData[idx].Pos)
  end
  -- Reads queue NPC
  function self:SetEntity(idx, ent)
    local idx = self:GetIndex(idx)
    if(not idx) then return self end
    if(not IsValid(ent)) then return self end
    mtData[idx].Ent = ent; return self
  end
  -- Reads queue NPC
  function self:GetEntity(idx)
    local idx = self:GetIndex(idx)
    if(not idx) then return nil end
    return mtData[idx].Ent
  end
  -- Check for valid entity under index
  function self:IsEntity(idx)
    local idx = self:GetIndex(idx)
    if(not idx) then return false end
    return IsValid(mtData[idx].Ent)
  end
  -- Check whenever NPC exists
  function self:IsHere(npc)
    if(not IsValid(npc)) then return false end
    for idx = 1, miSiz do
      local v = mtData[idx]
      if(IsValid(v.Ent) and v.Ent == npc) then
        return true
      end
    end; return false
  end
  -- Move NPC to desired position
  function self:Move(npc, pos)
    if(not IsValid(npc)) then return self end
    npc:SetLastPosition(pos)
    npc:SetSchedule(mtQueue.__move)
    return self
  end
  -- Is the NPC still moving
  function self:IsMove(npc, pos)
    if(not IsValid(npc)) then return false end
    if(npc:IsCurrentSchedule(mtQueue.__move)) then return true end
    if(pos and npc:GetPos():DistToSqr(pos) > 10) then return true end
    return false -- NPC has finished moving
  end
  -- Check when full
  function self:IsFull()
    return (mtData.Size >= miSiz)
  end
  -- Check when slot used
  function self:GetTrace(idx)
    local idx = self:GetIndex(idx)
    if(not idx) then return nil end
    local mar = Vector(0,0,mtQueue.__tnpc)
    local pos = mtData[idx].Pos
    local dat = mtQueue.__trft
          dat.start:Set(pos); dat.start:Add(mar)
          mar.z = -mar.z -- We need for top to bottom
          dat.endpos:Set(pos); dat.endpos:Add(mar)
    return util.TraceLine(mtQueue.__trft)
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
    local siz = 0
    for crr = 1, miSiz do
      local cv = mtData[crr]
      if(IsValid(cv.Ent)) then
        siz = siz + 1 -- Regster populated node
        if(not mtQueue.__hive) then
          local pi = self:GetIndex(crr - 1)
          if(pi) then
            local pv = mtData[pi]
            local tr = self:GetTrace(pi)
            local mv = self:IsMove(cv.Ent)
            if((tr and not tr.Hit) and not mv and not pv.Ent) then
              pv.Ent = cv.Ent -- Move NPC to current pointer
              cv.Ent = nil    -- Remove the NPC from the slot
            end
          end
        end
      else -- Fill it from the next set
        if(mtQueue.__hive) then
          local idx = 0 -- Assume valid NPC is not found
          for src = (crr + 1), miSiz do
            local sv = mtData[src]
            if(IsValid(sv.Ent)) then
              idx = src; break
            else -- Save index of first valid
              sv.Ent = nil
            end
          end -- When npc is found assign it to the empty slot
          if(idx ~= 0 and not IsValid(cv.Ent)) then
            local iv = mtData[idx]
            cv.Ent = iv.Ent -- Move NPC to current pointer
            iv.Ent = nil    -- Remove the NPC from the slot
            siz = siz + 1   -- Increment NPC count
          end
        end
      end
    end -- Assign the new NPC count
    if(siz > 0) then mtData.Size = siz end; return self
  end
  function self:Relocate()
    for idx = 1, miSiz do
      local v = mtData[idx]
      if(IsValid(v.Ent)) then
        if(mtQueue.__hive) then
          self:Move(v.Ent, v.Pos)
        else
          local mv = self:IsMove(v.Ent)
          local tr = self:GetTrace(idx)
          if((tr and not tr.Hit) and not mv) then
            self:Move(v.Ent, v.Pos)
          end
        end
      end
    end; return self
  end
  -- Apply perspective radius
  function self:GetRadius(org, mar)
    local pos = LocalPlayer():GetPos()
    return (mar * 200) / org:Distance(pos)
  end
  -- Calculate colors
  function self:GetColor(idx)
    local co = mtQueue.__colr
    local idx = self:GetIndex(idx)
    if(not idx) then return co end
    local hit = self:GetTrace(idx).Hit
    co.r = (hit and 0 or 255)
    co.g = (hit and 255 or 0)
    return co
  end
  --Draw debig information
  function self:Draw()
    local str = mtData[1].Pos
    local cor = self:GetColor(1)
    local xy = str:ToScreen()
    surface.SetDrawColor(cor)
    surface.DrawCircle(xy.x, xy.y, self:GetRadius(str, 10), cor)
    for cnt = 2, miSiz do
      local poc = mtData[cnt].Pos
      local pop = mtData[cnt-1].Pos
      local xyc = poc:ToScreen()
      local xyp = pop:ToScreen()
      local ccr = self:GetColor(cnt)
      surface.SetDrawColor(ccr)
      surface.DrawLine(xyp.x, xyp.y, xyc.x, xyc.y)
      surface.DrawCircle(xyc.x, xyc.y, self:GetRadius(poc, 10), ccr)
    end
    local poo = mtQueue.__out
    local xyo = poo[1]:ToScreen()
    surface.SetDrawColor(mtQueue.__cout)
    surface.DrawLine(xy.x, xy.y, xyo.x, xyo.y)
    surface.DrawCircle(xyo.x, xyo.y, self:GetRadius(poo[1], 20), mtQueue.__cout)
    for out = 2, #poo do
      local xyo = poo[out]:ToScreen()
      local xyn = poo[out-1]:ToScreen()
      surface.SetDrawColor(mtQueue.__cout)
      surface.DrawLine(xyn.x, xyn.y, xyo.x, xyo.y)
      surface.DrawCircle(xyo.x, xyo.y, self:GetRadius(poo[out], 20), mtQueue.__cout)
    end
    return self
  end
  return self
end

--[[ E2 code gor generating vector locations
  print(entity():pos())
  selfDestruct()
]]

local oQ = NewQueue(Vector(3362.8,1268.72,16.2813))
      oQ:Extend(Vector(1,0,0), 60, 1)
      oQ:SetNode(2, Vector(3397.98,1317.09,16.2813))
      oQ:Extend(Vector(1,0,0), 60, 1)
      oQ:SetNode(3, Vector(3403.37,1374.76,16.2813))
      oQ:Extend(Vector(1,0,0), 60, 1)
      oQ:SetNode(4, Vector(3397.85,1433.04,16.2813))
      oQ:Extend(Vector(1,0,0), 60, 1)
      oQ:SetNode(5, Vector(3374.88,1486.17,16.2812))
      oQ:Extend(Vector(-1,0,0), 60, 6)
      oQ:Extend(Vector(0,-1,0), 60, 2)
      oQ:Extend(Vector(-1,0,0), 60, 1)
      oQ:Extend(Vector(0,1,0), 60, 2)
      oQ:Extend(Vector(-1,0,0), 60, 1)
      oQ:Extend(Vector(0,-1,0), 60, 2)
      oQ:Extend(Vector(-1,0,0), 60, 1)
      oQ:Extend(Vector(0,1,0), 60, 2)

if(not oQ) then error("Failed allocating desk object!") end

if(CLIENT) then
  hook.Remove("PreDrawHUD", "hook_npc_queue_cl")
  hook.Add("PreDrawHUD", "hook_npc_queue_cl",
    function()
      cam.Start2D()
        oQ:Draw()
      cam.End2D()
    end)
  hook.Remove("OnPlayerChat", "hook_npc_queue_cmd")
  hook.Add("OnPlayerChat", "hook_npc_queue_cmd",
    function(ply, txt, tem, xxx)
      --if(not ply:IsAdmin()) then return end
      net.Start("hook_npc_queue_msg")
        net.WriteEntity(ply)
        net.WriteString(txt)
      net.SendToServer()
    end)
else
  -- Allocate user message
  util.AddNetworkString("hook_npc_queue_msg")
  -- Server notification function
  local fmtNot = "notification.AddLegacy(\"%s\", NOTIFY_UNDO, 6)"
  local fmtPly = "surface.PlaySound(\"ambient/water/drip%d.wav\")"
  local function notifyPlayer(ply, txt)
    ply:SendLua(fmtNot:format("["..ply:Nick().."]: <"..tostring(txt)..">"))
    ply:SendLua(fmtPly:format(math.random(1, 4)))
  end
  -- Message reciever function
  local function recieveQueueConfigNPC()
    local ply, txt = net.ReadEntity(), net.ReadString()
    if(not IsValid(ply)) then return end
    local cut = ":";
    local txt = txt:gsub("%s+", cut)
    local dat = cut:Explode(txt)
    local key = "__"..dat[1]
    local mva = mtQueue[key]
    if(not mva) then return end
    local typ = type(mva)
    if(typ == "string") then
      mtQueue[key] = tostring(dat[2] or "")
    elseif(typ == "number") then
      mtQueue[key] = (tonumber(dat[2]) or 0)
    elseif(typ == "boolean") then
      mtQueue[key] = tobool(dat[2])
    else
      notifyPlayer(ply, typ..":"..tostring(dat[2] or ""))
    end
    notifyPlayer(ply, mtQueue[key])
  end
  net.Receive("hook_npc_queue_msg", recieveQueueConfigNPC)
  -- Do the locic with timers
  hook.Remove("PlayerSpawnedNPC", "hook_npc_queue")
  hook.Add("PlayerSpawnedNPC", "hook_npc_queue",
    function(ply, npc)
      if(not IsValid(npc)) then return end
      mtQueue.__npc[tostring(npc:EntIndex())] = npc
      oQ:Push(npc)
    end)
  -- Timer function to check availability and handle NPC arrivals
  -- It will constantly try to pit NPCs at the queue desk
  timer.Remove("hook_npc_queue_push")
  timer.Create("hook_npc_queue_push", mtQueue.__push, 0,
    function()
      for idx, npc in pairs(mtQueue.__npc) do
        oQ:Push(npc)
      end
      oQ:Arrange():Relocate()
    end)

  -- Timer function to check when NPC leaves
  timer.Remove("hook_npc_queue_pull")
  timer.Create("hook_npc_queue_pull", mtQueue.__pull, 0,
    function()
      if(IsValid(mtQueue.__npx)) then return end
      local ent = oQ:GetEntity(1)
      if(IsValid(ent) and oQ:IsMove(ent)) then return end
      mtQueue.__npx = oQ:Pull()
      if(IsValid(mtQueue.__npx)) then
        local out = mtQueue.__out
        out.ID = out.ID + 1
        oQ:Move(mtQueue.__npx, out[out.ID])
        mtQueue.__npc[tostring(mtQueue.__npx:EntIndex())] = nil
      end
      oQ:Arrange():Relocate()
    end)

  timer.Remove("hook_npc_queue_ched")
  timer.Create("hook_npc_queue_ched", mtQueue.__shed, 0,
    function()
      if(not IsValid(mtQueue.__npx)) then return end
      local out = mtQueue.__out
      if(oQ:IsMove(mtQueue.__npx, out[out.ID])) then return end
      out.ID = out.ID + 1
      if(out[out.ID]) then
        oQ:Move(mtQueue.__npx, out[out.ID])
      else
        if(oQ:IsMove(mtQueue.__npx, out[out.ID])) then return end
        timer.Simple(mtQueue.__dstr,
          function()
            SafeRemoveEntity(mtQueue.__npx)
            mtQueue.__npx = nil
            mtQueue.__out.ID = 0
          end)
      end
    end)
end
