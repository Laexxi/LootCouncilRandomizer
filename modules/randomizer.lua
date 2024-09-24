local ADDON_NAME, ns = ...
ns.randomizer = {}

function ns.randomizer:RandomizeCouncil()
    ns.guild:AddToLog("Started council randomization")
    local councilMembers = {}
    local groupMembers = ns.randomizer:GetRaidMembersByGroup()
    local groupCount = LootCouncilRandomizer.db.profile.settings.councilPots or 1

    for i = 1, groupCount do
        local groupName = LootCouncilRandomizer.db.profile.settings["groupName" .. i] or "Group " .. i
        local numToSelect = LootCouncilRandomizer.db.profile.settings["groupSelection" .. i] or 0

        if numToSelect > 0 then
            local members = groupMembers[i] or {}
            local eligibleMembers = ns.randomizer:FilterEligibleMembers(members, i)

            if #eligibleMembers >= numToSelect then
                ns.guild:AddToLog("Selecting " .. numToSelect .. " members from " .. groupName)
                local selectedMembers = ns.randomizer:SelectRandomMembers(eligibleMembers, numToSelect)
                for _, member in ipairs(selectedMembers) do
                    table.insert(councilMembers, member)
                    ns.randomizer:UpdateSelectionHistory(member)
                end
            else
                ns.guild:AddToLog("Not enough eligible members in " .. groupName)
                print("Not enough eligible members in " .. groupName .. " to select " .. numToSelect .. " members.")
            end
        end
    end

    ns.randomizer:AnnounceCouncil(councilMembers)
    ns.guild:AddToLog("Council randomization complete")
end


-- TODO Forced und Excluded did not work as expected.

function ns.randomizer:FilterEligibleMembers(members, groupIndex)
    local filteredMembers = {}
    local reselectDuration = LootCouncilRandomizer.db.profile.settings["groupReselectDuration" .. groupIndex] or LootCouncilRandomizer.db.profile.settings.reselectDuration or 0

    local forcedPlayersInput = LootCouncilRandomizer.db.profile.settings.forcedPlayers or ""
    local excludedPlayersInput = LootCouncilRandomizer.db.profile.settings.excludedPlayers or ""
    local forcedPlayers = ns.randomizer:ParseCommaSeparatedList(forcedPlayersInput)
    local excludedPlayers = ns.randomizer:ParseCommaSeparatedList(excludedPlayersInput)

    local currentTime = time()

    for _, member in ipairs(members) do
        local isEligible = true

        local lastSelectedTime = LootCouncilRandomizer.db.profile.statistics[member] and LootCouncilRandomizer.db.profile.statistics[member].lastSelectedTime or 0
        local daysSinceLastSelection = (currentTime - lastSelectedTime) / (24 * 60 * 60)

        if daysSinceLastSelection < reselectDuration then
            isEligible = false
        end

        if forcedPlayers[member] then
            isEligible = true
        end

        if excludedPlayers[member] then
            isEligible = false
        end

        if isEligible then
            table.insert(filteredMembers, member)
        end
    end

    return filteredMembers
end

function ns.randomizer:UpdateSelectionHistory(member)
    ns.guild:AddToLog("Updating selection history for " .. member)
    LootCouncilRandomizer.db.profile.statistics[member] = LootCouncilRandomizer.db.profile.statistics[member] or {}
    LootCouncilRandomizer.db.profile.statistics[member].lastSelectedTime = time()
    LootCouncilRandomizer.db.profile.statistics[member].timesSelected = (LootCouncilRandomizer.db.profile.statistics[member].timesSelected or 0) + 1
end

function ns.randomizer:SelectRandomMembers(group, count)
    local selected = {}
    local pool = { unpack(group) }

    for i = 1, count do
        if #pool == 0 then break end
        local index = math.random(1, #pool)
        local member = table.remove(pool, index)
        table.insert(selected, member)
    end
    return selected
end

function ns.randomizer:AnnounceCouncil(council)
    if #council > 0 then
        ns.guild:AddToLog("Announcing council members to RAID")
        SendChatMessage("Selected Loot Council Members:", "RAID")
        for _, member in ipairs(council) do
            SendChatMessage(member, "RAID")
            ns.guild:AddToLog("Announced member: " .. member)
        end
    else
        ns.guild:AddToLog("No members selected for council")
        print("No members selected for the Loot Council.")
    end
end

function ns.randomizer:GetRaidMembersByGroup()
    local raidMembers = ns.guild:GetRaidMembersWithRanks()
    local groupMembers = {}
    local groupCount = LootCouncilRandomizer.db.profile.settings.councilPots or 1

    for i = 1, groupCount do
        groupMembers[i] = {}
    end

    for name, rankIndex in pairs(raidMembers) do
        for i = 1, groupCount do
            local groupRanks = LootCouncilRandomizer.db.profile.settings["groupRanks" .. i] or {}
            if groupRanks[rankIndex] then
                table.insert(groupMembers[i], name)
                break
            end
        end
    end
    return groupMembers
end

function ns.randomizer:ParseCommaSeparatedList(inputString)
    local list = {}
    for name in string.gmatch(inputString, '([^,]+)') do
        name = strtrim(name)
        if name ~= "" then
            name = Ambiguate(name, "short")
            list[name] = true
        end
    end
    return list
end

function ns.randomizer:GetCurrentEligibleMembers()
    local groupMembers = self:GetRaidMembersByGroup()
    local eligibleGroupMembers = {}
    local groupCount = LootCouncilRandomizer.db.profile.settings.councilPots or 1

    for i = 1, groupCount do
        local members = groupMembers[i] or {}
        local eligibleMembers = self:FilterEligibleMembers(members, i)
        eligibleGroupMembers[i] = eligibleMembers
    end

    return eligibleGroupMembers
end
