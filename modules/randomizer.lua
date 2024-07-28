local ADDON_NAME, ns = ...
ns.randomizer = {}

-- Function to randomize the council
function ns.randomizer:RandomizeCouncil()
    local raidMembers = self:GetRaidMembers()
    local groupMembers = self:GetGroupMembersInRaid(raidMembers)

    local selectedCouncil = {}
    for i = 1, (LootCouncilRandomizer.db.char.councilPots or 1) do
        local groupSize = LootCouncilRandomizer.db.char["groupSelection" .. i] or 0
        local groupName = LootCouncilRandomizer.db.char["groupName" .. i] or "Group " .. i
        if groupSize > 0 and groupMembers[groupName] then
            local selected = self:SelectRandomMembers(groupMembers[groupName], groupSize)
            for _, member in ipairs(selected) do
                table.insert(selectedCouncil, member)
            end
        end
    end

    self:AnnounceCouncil(selectedCouncil)
end

-- Function to get the raid members
function ns.randomizer:GetRaidMembers()
    local raidMembers = {}
    for i = 1, GetNumGroupMembers() do
        local name, _, _, _, _, _, _, _, _, _, _, _, _, _ = GetRaidRosterInfo(i)
        if name then
            table.insert(raidMembers, name)
        end
    end
    return raidMembers
end

-- Function to get group members currently in the raid
function ns.randomizer:GetGroupMembersInRaid(raidMembers)
    local groupMembers = {}
    for _, member in ipairs(raidMembers) do
        local group = ns.randomizer:GetMemberGroup(member)
        if group then
            groupMembers[group] = groupMembers[group] or {}
            table.insert(groupMembers[group], member)
        end
    end
    return groupMembers
end

-- Function to get the group of a member
function ns.randomizer:GetMemberGroup(member)
    return LootCouncilRandomizer.db.char["memberGroup_" .. member] or LootCouncilRandomizer.db.char["rankGroup_" .. ns.randomizer:GetMemberRank(member)]
end

-- Function to get the rank of a member
function ns.randomizer:GetMemberRank(member)
    for i = 1, GetNumGuildMembers() do
        local name, rank = GetGuildRosterInfo(i)
        if name and name:match("([^%-]+)") == member then
            return rank
        end
    end
end

-- Function to select random members from a group
function ns.randomizer:SelectRandomMembers(group, count)
    local selected = {}
    while #selected < count and #group > 0 do
        local index = math.random(1, #group)
        table.insert(selected, table.remove(group, index))
    end
    return selected
end

-- Function to announce the selected council
function ns.randomizer:AnnounceCouncil(council)
    SendChatMessage("Selected Loot Council Members:", "RAID")
    for _, member in ipairs(council) do
        SendChatMessage(member, "RAID")
    end
end
