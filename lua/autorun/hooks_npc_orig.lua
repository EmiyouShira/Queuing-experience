      -- Metatable of the desc class. Global data
local mtDesk = {}
      -- Metatable method indexing
      mtDesk.__index = mtDesk
      -- Where to go after 16 seconds
      mtDesk.__out = Vector(646.266 ,-900,-143.719)
      -- Table of all the NPC
      mtDesk.__npc = {}
      -- NPC Move type
      mtDesk.__move = SCHED_FORCED_GO
      -- NPC Arrival Interval
      mtDesk.__pull = 16 -- in seconds
      -- Timer Interval
      mtDesk.__push = 4 -- in seconds
      -- Remove after the final destination
      mtDesk.__dstr = 1 -- in seconds
local function newDesk(pos, dir, dst, siz)      
  local mvPos = Vector(pos)
    if(mvPos:IsZero()) then return nil end
  local mvDir = Vector(dir); mvDir.z = 0
    if(mvDir:IsZero()) then return nil end
  local mnDst = (tonumber(dst) or 0)
    if(mnDst <= 0) then return nil end
  local miSiz = math.floor(tonumber(siz) or 0)
    if(miSiz <= 0) then return nil end
  local mtData = {Size = 0}
  local self = {}; setmetatable(self, mtDesk)
  -- Allocate positions list and fix internals
  mvDir:Normalize()
  for idx = 1, miSiz do
    local muo = ((idx - 1) * mnDst)
    self.Data[idx] = {Pos = Vector(), Ent = NULL}
    self.Data[idx].Pos:Set(mvPos + muo * mvDir)
  end
  -- Check whenever NPC exists
  function self:isHere(npc)
    if(not IsValid(npc)) then return end
    for iqu = 1, miSiz do
      local v = mtData[isr]
      if(IsValid(v.Ent) and v.Ent == npc) then
        return true
      end
    end; return false
  end
  -- Move NPC to desired position
  function self:npcMove(npc, pos)
    if(not IsValid(npc)) then return end
    npc:SetSaveValue("m_vecLastPosition", pos)
    npc:SetSchedule(SCHED_FORCED_GO)
  end
  -- Check when full
  function self:isFull()
    return (mtData.Size >= miSiz)
  end
  -- Check when slot used
  function self:npcUse(idx)
    local idx = (tonumber(idx) or 0)
          idx = (idx > 0) and math.floor(idx) or 0
          idx = (idx > 0) and idx or 0
    local pos = mtData[idx].Pos + Vector(0,0,15)
    local ent = ents.FindInSphere(pos, 5)
    return ent[1]
  end
  -- Push NPC at the end of the queue
  function self:npcPush(npc)
    if(self:isFull()) then return self end
    if(not IsValid(npc)) then return self end
    if(self:isHere(npc)) then return self end
    mtData.Size = mtData.Size + 1
    mtData[mtData.Size].Ent = npc
    return self
  end
  -- Pull NPC at the front of the queue
  function self:npcPull()
    local npc = mtData[1].Ent
    mtData.Size = mtData.Size - 1
    mtData[1].Ent = NULL
    return npc
  end
  -- Rearange NPC in the queue
  function self:npcWait()
    local ius, ifr = 0, 1
    for iqu = 1, miSiz do
      for isr = iqu, miSiz do
        if(IsValid(mtData[isr].Ent)) then
          ius = isr -- Save index of first valid
        else
          ius = 0 -- Could not find NPC
          mtData[isr].Ent = NULL
        end
      end -- When npc is found assign it to the empty slot
      if(ius ~= 0 and not IsValid(mtData[isr].Ent)) then
        mtData[isr].Ent = mtData[ius].Ent
      end
    end; return self
  end
  function self:npcStay()
    for iqu = 1, miSiz do
      local v = mtData[isr]
      if(IsValid(v.Ent)) then
        self:npcMove(v.Ent, v.Pos)
      end
    end; return self
  end
  return self
end

local oDesk = newDesk(Vector(646.266 ,-949.261,-143.719), Vector(1,0,0), 16, 20)

hook.Add("PlayerSpawnedNPC", "hook_npc_queue",
  function(ply, npc)
    if(not IsValid(npc)) then return end
    mtDesk.__npc[tostring(npc:EntIndex())] = npc
    oDesk:npcPush(npc)
  end)

-- Timer function to check availability and handle NPC arrivals
-- It will constantly try to pit NPCs at the queue desk
timer.Create("QueueTimerPush", mtDesk.__push, 0, function()
  for idx, npc in pairs(mtDesk.__npc) do
    oDesk:npcPush(npc):npcWait():npcStay()
  end
end)

-- Timer function to check when NPC leaves
local puNPC
timer.Create("QueueTimerPull", mtDesk.__pull, 0, function()
  if(IsValid(puNPC)) then
    if(not puNPC:IsCurrentSchedule(mtDesk.__move)) then
      timer.Simple(mtDesk.__dstr,
        function()
          SafeRemoveEntity(puNPC)
          puNPC = NULL
        end)
    end
  else
    local puNPC = oDesk:npcPull()
    if(IsValid(npc)) then
      oDesk:npcMove(npc, mtDesk.__out)
    else
      puNPC = NULL
    end
  end
end)