local ADDON_NAME, ns = ...
ns.randomizer = {}

-- Function to randomize the council
function ns.randomizer:RandomizeCouncil()
    local raidMembers = self:GetRaidMembers()
    print("Raid Members Found:", #raidMembers)
    local groupMembers = self:GetGroupMembersInRaid(raidMembers)

    local selectedCouncil = {}
    for i = 1, (LootCouncilRandomizer.db.char.councilPots or 1) do
        local groupSize = LootCouncilRandomizer.db.char["groupSelection" .. i] or 0
        local groupName = LootCouncilRandomizer.db.char["groupName" .. i] or "Group " .. i
        print("Processing group:", groupName, "with size:", groupSize)
        if groupSize > 0 and groupMembers[groupName] then
            print("Group members for", groupName, ":", #groupMembers[groupName])
            local selected = self:SelectRandomMembers(groupMembers[groupName], groupSize)
            for _, member in ipairs(selected) do
                table.insert(selectedCouncil, member)
            end
        else
            print("No members in group", groupName)
        end
    end

    self:AnnounceCouncil(selectedCouncil)
end

-- Function to get the raid members
function ns.randomizer:GetRaidMembers()
    local raidMembers = {}
    for i = 1, GetNumGroupMembers() do
        local name, rank, subgroup, level, class, classFileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
        if name then
            print("Raid Member:", name, "Role:", role, "Class:", class, "Rank:", rank)
            table.insert(raidMembers, {name = name, class = class, role = role, subgroup = subgroup})
        end
    end
    return raidMembers
end

-- Function to get group members currently in the raid
function ns.randomizer:GetGroupMembersInRaid(raidMembers)
    local groupMembers = {}
    for _, memberInfo in ipairs(raidMembers) do
        local group = ns.randomizer:GetMemberGroup(memberInfo.name)
        if group then
            local groupName = LootCouncilRandomizer.db.char["groupName" .. group] or "Group " .. group
            groupMembers[groupName] = groupMembers[groupName] or {}
            table.insert(groupMembers[groupName], memberInfo)
            print("Member added to group:", memberInfo.name, "Group:", groupName)
        else
            print("Member has no group:", memberInfo.name)
        end
    end
    return groupMembers
end

-- Function to get the group of a member
function ns.randomizer:GetMemberGroup(member)
    local memberGroup = LootCouncilRandomizer.db.char["memberGroup_" .. member]
    local memberRankGroup = LootCouncilRandomizer.db.char["rankGroup_" .. ns.randomizer:GetMemberRank(member)]
    print("Member:", member, "Member Group:", memberGroup, "Member Rank Group:", memberRankGroup)
    return memberGroup or memberRankGroup
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
        local member = table.remove(group, index)
        print("Selected member:", member.name, "from group:", group)
        table.insert(selected, member)
    end
    return selected
end

-- Function to announce the selected council
function ns.randomizer:AnnounceCouncil(council)
    if #council > 0 then
        SendChatMessage("Selected Loot Council Members:", "RAID")
        for _, memberInfo in ipairs(council) do
            SendChatMessage(memberInfo.name, "RAID")
            print("Selected Member:", memberInfo.name)
        end
    else
        print("No members selected for the Loot Council.")
    end
end
