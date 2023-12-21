      -- Metatable of the desc class. Global data
local mtQueue = {}
      -- Metatable method indexing
      mtQueue.__index = mtQueue
      -- Where to go after pulling
      mtQueue.__out = {
        ID = 0, -- Track the exit node
        Vector(3124.45,1278.14,16.2813),
        Vector(2787.98,1332.3,16.2813),
        Vector(2768.52,1426.19,16.2813),
        Vector(2701.32,1426.65,16.2813),
        Vector(2635.5,1241.34,16.2813)
      }
      -- Color for out trajectory debug
      mtQueue.__cout = Color(255,255,0,255)
      -- Table of all the NPC
      mtQueue.__npc = {}
      -- Contains the NPC which exits
      mtQueue.__npx = nil
      -- Contains the NPC pulled from sequential
      mtQueue.__nps = nil
      -- Enable to act as a hive mind
      mtQueue.__hvmd = false
      -- NPC Move type
      mtQueue.__move = SCHED_FORCED_GO_RUN
      -- NPC Exit Interval
      mtQueue.__pull = 4 -- in seconds
      -- NPC Arrival Interval
      mtQueue.__push = 1 -- in seconds
      -- Check when shedule is finished
      mtQueue.__shed = 0.1 -- in seconds
      -- Remove after the final destination
      mtQueue.__dstr = 1 -- in seconds
      -- Amount of units to scan for NPC
      mtQueue.__tnpc = 100
      -- Remove radius for NPC
      mtQueue.__rrnp = 50
      -- Color for debgging remove radius
      mtQueue.__conp = Color(200,150,50,100)
      -- Turn on/ off the draw method
      mtQueue.__draw = true
      -- Turn on/ off the remove debug
      mtQueue.__drrm = false
      -- Color to pass for drawing
      mtQueue.__colr = Color(0,0,0,255)
      -- Function filter for NPC trace
      mtQueue.__trft = {
        start  = Vector(), -- Start position
        endpos = Vector(), -- End position
        ignoreworld = true, -- Ignore hitting world
        filter = function(ent) return ent:IsNPC() end
      }
      mtQueue.__tostring = function(o)
        local a, c = o:GetSize()
        return "[npc_queue]["..a..":"..c.."]"
      end
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
    end; miSiz = miSiz + iSiz; return self
  end
  -- Clear queue state
  function self:Clear()
    for idx = 1, miSiz do
      local cv = mtData[idx]
      local tr = self:GetTrace(idx)
      SafeRemoveEntity(cv.Ent)
      SafeRemoveEntity(tr.Ent)
      cv.Ent = nil
    end; mtData.Size = 0
    return self
  end
  -- Update count of valid slots
  function self:Count()
    local siz = 0
    for idx = 1, miSiz do local cv = mtData[idx]
      if(IsValid(cv.Ent)) then siz = siz + 1 end
    end; mtData.Size = siz
    return self
  end
  -- Read queue size
  function self:GetSize()
    local siz = 0
    for idx = 1, miSiz do
      local cv = mtData[idx]
      if(IsValid(cv.Ent)) then siz = siz + 1 end
    end; return miSiz, siz, mtData.Size
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
  function self:InTrace(pos)
    local mar = Vector(0,0,mtQueue.__tnpc)
    local dat = mtQueue.__trft
          dat.start:Set(pos); dat.start:Add(mar)
          dat.endpos:Set(pos); dat.endpos:Sub(mar)
    return util.TraceLine(mtQueue.__trft)
  end
  -- Check when slot used
  function self:GetTrace(idx)
    local idx = self:GetIndex(idx)
    if(not idx) then return nil end
    return self:InTrace(mtData[idx].Pos)
  end
  -- Read the last empty index
  function self:GetRecent()
    local idx = 0 -- Start at zero
    for crr = miSiz, 1, -1 do -- Loop
      local cv = mtData[crr] -- Data row
      if(IsValid(cv.Ent)) then -- Valid NPC
        idx = crr; break -- Register current
      end -- Break the loop and return index
    end; return idx -- Empty slot index
  end
  -- Push NPC at the end of the queue
  function self:Push(npc)
    if(not IsValid(npc)) then return false end
    if(self:IsHere(npc)) then return false end
    local idx = self:GetIndex(self:GetRecent() + 1)
    if(not idx) then return false end
    mtData[idx].Ent = npc; return true
  end
  -- Pull NPC at the front of the queue
  function self:Pull()
    local npc = mtData[1].Ent
    mtData[1].Ent = nil; return npc
  end
  -- Check whenever the node is empty
  function self:IsEmpty(idx)
    local idx = self:GetIndex(idx)
    if(not idx) then return nil end
    local tr = self:GetTrace(idx)
    if(tr and tr.Hit) then return false end
    local ent = mtData[idx].Ent
    if(IsValid(ent)) then return false end
    return true
  end
  -- Initialize when hot reloading
  function self:Init()
    if(CLIENT) then return self end
    local rad = mtQueue.__rrnp
    local out = mtQueue.__out
    local vup = Vector(0,0,rad/2)
    for idx = 1, miSiz do
      local tr = self:GetTrace(idx)
      if(tr and tr.Hit) then
        mtData[idx].Ent = tr.Entity
      end
      if(idx > 1) then
        local crr = self:GetNode(idx); crr:Add(vup)
        local prv = self:GetNode(idx - 1); prv:Add(vup)
        local dir = (crr - prv)
        local len = dir:Length()
        local mar = (rad * 0.85)
        local mur = len - 2 * mar
        if(mur > 0) then
          dir:Normalize(); dir:Mul(mar)
          crr:Sub(dir); prv:Add(dir)
          local ent = ents.FindAlongRay(prv, crr)
          for cnt = 1, #ent do SafeRemoveEntity(ent[cnt]) end
        end
      end
      local ent = ents.FindInSphere(self:GetNode(idx), rad)
      for cnt = 1, #ent do
        if(ent[cnt] ~= tr.Entity) then SafeRemoveEntity(ent[cnt]) end
      end
    end
    for idx = 1, #out do
      if(idx > 1) then
        local ent = ents.FindAlongRay(out[idx-1] + vup, out[idx] + vup)
        for cnt = 1, #ent do SafeRemoveEntity(ent[cnt]) end
      end
      local ent = ents.FindInSphere(out[idx], rad)
      for cnt = 1, #ent do SafeRemoveEntity(ent[cnt]) end
    end; return self
  end
  -- Jump the queue when some nodes are empty
  function self:Jump(idx)
    if(idx == 1) then return self end
    local cv = mtData[idx]
    if(not IsValid(cv.Ent)) then return self end
    local prv = self:GetIndex(idx - 1)
    if(not prv) then return self end
    local ent = self:GetEntity(prv)
    if(IsValid(ent)) then return self end
    while(prv and not IsValid(ent)) do
      prv = self:GetIndex(prv - 1)
      if(not prv) then prv = 0; break end
      ent = self:GetEntity(prv)
    end; prv = (prv + 1)
    local pv = mtData[prv]
    if(self:IsEmpty(prv) and not self:IsMove(cv.Ent)) then
      pv.Ent = cv.Ent -- Move NPC to current pointer
      cv.Ent = nil    -- Remove the NPC from the slot
    end; return self
  end
  -- Rearange NPC in the queue
  function self:Arrange()
    for crr = 1, miSiz do
      local cv = mtData[crr]
      if(IsValid(cv.Ent)) then
        if(not mtQueue.__hvmd) then
          self:Jump(crr)
        end
      else -- Fill it from the next set
        if(mtQueue.__hvmd) then
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
          end
        else
          self:Jump(crr)
        end
      end
    end -- Assign the new NPC count
    return self
  end
  function self:Relocate()
    for idx = 1, miSiz do
      local v = mtData[idx]
      if(IsValid(v.Ent)) then
        if(mtQueue.__hvmd) then
          self:Move(v.Ent, v.Pos)
        else
          local tr = self:GetTrace(idx)
          local mv = self:IsMove(v.Ent)
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
    local cot = mtQueue.__cout
    cot.r, cot.g, cot.b = 255, 255, 0
    local poo = mtQueue.__out
    local xyo, npo = poo[1]:ToScreen(), #poo
    surface.SetDrawColor(cot)
    surface.DrawLine(xy.x, xy.y, xyo.x, xyo.y)
    surface.DrawCircle(xyo.x, xyo.y, self:GetRadius(poo[1], 20), cot)
    for out = 2, npo do
      local xyo = poo[out]:ToScreen()
      local xyn = poo[out-1]:ToScreen()
      surface.SetDrawColor(cot)
      surface.DrawLine(xyn.x, xyn.y, xyo.x, xyo.y)
      if(out == npo) then
        cot.r, cot.g, cot.b = 0, 0, 255
        surface.DrawCircle(xyo.x, xyo.y, self:GetRadius(poo[out], 20), cot)
      else
        cot.r, cot.g, cot.b = 255, 255, 0
        surface.DrawCircle(xyo.x, xyo.y, self:GetRadius(poo[out], 20), cot)
      end
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
      oQ:Extend(Vector(0,1,0), 60, 2):Init()

if(not oQ) then error("Failed allocating desk object!") end

-- Server notification function
local fmtNot = "notification.AddLegacy(\"%s\", NOTIFY_UNDO, 6)"
local fmtPly = "surface.PlaySound(\"ambient/water/drip%d.wav\")"
local function notifyPlayer(ply, txt)
  local idx = math.random(1, 4)
  local msg = "["..ply:Nick().."]: <"..tostring(txt)..">"
  if(SERVER) then
    ply:SendLua(fmtNot:format(msg))
    ply:SendLua(fmtPly:format(idx))
  end
end

local function queueConfigNPC(ply, txt)
  if(not IsValid(ply)) then return end
  if(not ply:IsAdmin()) then return end
  local cut, pss = ":", false
  local txt = txt:gsub("%s+", cut)
  local dat = cut:Explode(txt)
  local cmd = tostring(dat[1] or "")
  local key = "__"..cmd
  local mva = mtQueue[key]
  if(mva ~= nil) then
    local typ = type(mva)
    if(typ == "string") then pss = true
      mtQueue[key] = tostring(dat[2] or "")
    elseif(typ == "number") then pss = true
      mtQueue[key] = (tonumber(dat[2]) or 0)
    elseif(typ == "boolean") then pss = true
      mtQueue[key] = tobool(dat[2])
    end
    if(pss) then
      notifyPlayer(ply, typ.."|"..cmd.."|"..tostring(dat[2] or ""))
    else
      notifyPlayer(ply, "TYPE:"..typ..":"..tostring(dat[2] or ""))
    end
  else
    if(cmd == "@clear") then
      pss = true; oQ:Clear()
    elseif(cmd == "@init") then
      pss = true; oQ:Init()
    elseif(cmd == "@arrange") then
      pss = true; oQ:Arrange()
    elseif(cmd == "@relocate") then
      pss = true; oQ:Relocate()
    elseif(cmd == "@count") then
      pss = true; oQ:Count()
    elseif(cmd == "#string") then
      pss = true; print(tostring(oQ))
    end
    if(pss) then
      notifyPlayer(ply, cmd.."|"..tostring(dat[2] or ""))
    else
      notifyPlayer(ply, "CMD:"..cmd..":"..tostring(dat[2] or ""))
    end
  end
end

if(CLIENT) then
  hook.Remove("PreDrawHUD", "hook_npc_queue_cl")
  hook.Add("PreDrawHUD", "hook_npc_queue_cl",
    function()
      if(mtQueue.__draw) then
        cam.Start2D()
          oQ:Draw()
        cam.End2D()
        if(mtQueue.__drrm) then
          cam.Start3D()
            local out = mtQueue.__out
            local cor = mtQueue.__conp
            local rad = mtQueue.__rrnp
            render.SetColorMaterial()
            local siz = oQ:GetSize()
            for idx = 1, siz do
              render.DrawSphere(oQ:GetNode(idx), rad, 16, 16, cor)
            end
            for idx = 1, #out do
              render.DrawSphere(out[idx], rad, 16, 16, cor)
            end
          cam.End3D()
        end
      end
    end)
  hook.Remove("OnPlayerChat", "hook_npc_queue_cmd")
  hook.Add("OnPlayerChat", "hook_npc_queue_cmd",
    function(ply, txt, tem, xxx)
      if(not ply:IsAdmin()) then return end
      queueConfigNPC(ply, txt)
      net.Start("hook_npc_queue_msg")
        net.WriteEntity(ply)
        net.WriteString(txt)
      net.SendToServer()
    end)
else
  -- Allocate user message
  util.AddNetworkString("hook_npc_queue_msg")
  -- Message reciever function
  net.Receive("hook_npc_queue_msg",
    function()
      local ply, txt = net.ReadEntity(), net.ReadString()
      queueConfigNPC(ply, txt)
    end)

  -- Do the locic with timers
  hook.Remove("PlayerSpawnedNPC", "hook_npc_queue")
  hook.Add("PlayerSpawnedNPC", "hook_npc_queue",
    function(ply, npc)
      if(not IsValid(npc)) then return end
      table.insert(mtQueue.__npc, npc)
    end)

  -- Timer function to check availability and handle NPC arrivals
  -- It will constantly try to pit NPCs at the queue desk
  timer.Remove("hook_npc_queue_push")
  timer.Create("hook_npc_queue_push", mtQueue.__push, 0,
    function()
      local npc = mtQueue.__nps
      if(IsValid(npc)) then
        if(oQ:Push(npc)) then
          oQ:Arrange():Relocate()
          mtQueue.__nps = nil
        end
      else
        npc = table.remove(mtQueue.__npc, 1)
        if(IsValid(npc)) then
          if(oQ:Push(npc)) then
            oQ:Arrange():Relocate()
            mtQueue.__nps = nil
          end
        else
          mtQueue.__nps = nil
        end
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
        oQ:Arrange():Relocate()
      end
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
        timer.Simple(mtQueue.__dstr,
          function()
            SafeRemoveEntity(mtQueue.__npx)
            mtQueue.__npx = nil
            mtQueue.__out.ID = 0
          end)
      end
    end)
end
