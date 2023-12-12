-- Function to check if there's someone in front of the NPC in the line
local function isSomeoneInFront(npc, nodPos)
    local npcPos = npc:GetPos()
    local frontPos = npcPos - nodPos + Vector(0, 0, 72) -- Adjust for NPC height

    local entitiesInFront = ents.FindInSphere(frontPos, 5)

    for _, entity in pairs(entitiesInFront) do
        if entity:IsPlayer() or (entity:IsNPC() and entity ~= npc) then
            return true
        end
    end

    return false
end

-- NPC Names and Entity IDs
local npcEntities = {
    {name = "npc_mossman", id = 257},
    {name = "npc_breen", id = 873},
    {name = "npc_gman", id = 874},
    {name = "npc_eli", id = 875},
    {name = "npc_alyx", id = 876},
    -- Add more NPCs as needed
}

-- Nod Position (Queue Position)
local nodPosition = Vector(3395.75, 1261.25, 80.03) -- Replace with your desired position

-- NPC Arrival Interval
local arrivalInterval = 16 -- in seconds

-- Timer Interval
local timerInterval = 4 -- in seconds

-- Create a table to store the arrival time for each NPC
local npcArrivalTimes = {}

-- Create a table to store the previous position of each NPC
local npcPreviousPositions = {}

-- Timer function to check availability and handle NPC arrivals
timer.Create("QueueTimer", timerInterval, 0, function()
    print("QueueTimer triggered")
    for _, npcInfo in ipairs(npcEntities) do
        local npc = Entity(npcInfo.id)
        print("Checking NPC: " .. npcInfo.name)

        -- Check if NPC is valid
        if not IsValid(npc) then
            print("NPC is not valid: " .. npcInfo.name)
        else
            print("NPC is valid: " .. npcInfo.name)

            -- Check if NPC is moving by comparing previous and current positions
            local currentPos = npc:GetPos()
            local previousPos = npcPreviousPositions[npcInfo.name] or Vector(0, 0, 0)
            npcPreviousPositions[npcInfo.name] = currentPos

            local isMoving = currentPos:Distance(previousPos) > 1 -- Adjust the distance threshold as needed

            if isMoving then
                print("NPC is moving: " .. npcInfo.name)
            end

            -- Check if someone is in front of the NPC
            if isSomeoneInFront(npc, nodPosition) then
                print("Someone is in front of NPC: " .. npcInfo.name)
            end

            -- Rest of the script...

            if not npcArrivalTimes[npcInfo.name] then
                -- NPC hasn't arrived yet, check if the nod position is available
                if not isMoving and not isSomeoneInFront(npc, nodPosition) then
                    print("Moving NPC: " .. npcInfo.name)
                    npc:SetPos(nodPosition)
                    npcArrivalTimes[npcInfo.name] = CurTime() + arrivalInterval -- Set arrival time
                end
            else
                -- NPC has arrived, check if it's time to move to the next step
                local currentTime = CurTime()
                if currentTime >= npcArrivalTimes[npcInfo.name] then
                    -- Move the NPC to the next destination (replace with your logic)
                    print("Moving NPC to the next destination: " .. npcInfo.name)
                    npc:SetPos(Vector(3100.36, 1596.41, 80.03))
                    npcArrivalTimes[npcInfo.name] = nil -- Reset arrival time for the next cycle
                end
            end
        end
    end
end)
