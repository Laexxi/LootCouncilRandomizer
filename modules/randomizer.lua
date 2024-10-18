local ADDON_NAME, ns = ...
ns.randomizer = {}

function ns.randomizer:RandomizeCouncil()
    ns.guild:DebugPrint("Started council randomization")
    local councilMembers = {}
    local groupMembers = ns.randomizer:GetRaidMembersByGroup()
    local groupCount = LootCouncilRandomizer.db.profile.settings.councilPots or 1

    local debugMode = LootCouncilRandomizer.db.profile.settings.debugMode
    local ignoreMinMembers = LootCouncilRandomizer.db.profile.settings.ignoreMinMembers and debugMode

    for i = 1, groupCount do
        local groupName = LootCouncilRandomizer.db.profile.settings["groupName" .. i] or "Group " .. i
        local numToSelect = LootCouncilRandomizer.db.profile.settings["groupSelection" .. i] or 0

        if numToSelect > 0 then
            local members = groupMembers[i] or {}
            local eligibleMembers = ns.randomizer:FilterEligibleMembers(members, i)

            local numEligible = #eligibleMembers
            local numToSelectActual = numToSelect

            if numEligible < numToSelect then
                if ignoreMinMembers then
                    numToSelectActual = numEligible
                    ns.guild:DebugPrint("Not enough eligible members in " .. groupName .. ", but ignoring minimum members")
                else
                    ns.guild:DebugPrint("Not enough eligible members in " .. groupName)
                    print("Nicht genügend berechtigte Mitglieder in " .. groupName .. " um " .. numToSelect .. " Mitglieder auszuwählen.")
                    -- Überspringe diese Gruppe
                    numToSelectActual = 0
                end
            end

            if numToSelectActual > 0 then
                ns.guild:DebugPrint("Selecting " .. numToSelectActual .. " members from " .. groupName)
                local selectedMembers = ns.randomizer:SelectRandomMembers(eligibleMembers, numToSelectActual)
                for _, member in ipairs(selectedMembers) do
                    table.insert(councilMembers, member)
                    if not ignoreMinMembers then
                        ns.randomizer:UpdateSelectionHistory(member)
                    else
                        ns.guild:DebugPrint("Skipping statistics update for " .. member)
                    end
                end
            end
        end
    end

    ns.randomizer:AnnounceCouncil(councilMembers)
    ns.guild:DebugPrint("Council randomization complete")
end




function ns.randomizer:FilterEligibleMembers(members, groupIndex)
    local eligibleMembers = {}
    local currentTime = time()
    local reselectDuration = LootCouncilRandomizer.db.profile.settings["groupReselectDuration" .. groupIndex] or LootCouncilRandomizer.db.profile.settings.reselectDuration or 0
    for _, member in ipairs(members) do
        local isEligible = true
        if isEligible and reselectDuration > 0 then
            local lastSelectedTime = 0
            if LootCouncilRandomizer.db.profile.settings.selectStatisticsMode then
                lastSelectedTime = ns.randomizer:GetTimestampFromOfficerNote(member)
            else
                lastSelectedTime = LootCouncilRandomizer.db.profile.statistics[member] and LootCouncilRandomizer.db.profile.statistics[member].lastSelectedTime or 0
            end

            local daysSinceLastSelection = (currentTime - lastSelectedTime) / (24 * 60 * 60)
            if daysSinceLastSelection < reselectDuration then
                isEligible = false
                ns.guild:DebugPrint(member .. " was selected " .. string.format("%.2f", daysSinceLastSelection) .. " days ago, which is less than reselect duration of " .. reselectDuration)
            end
        end

        if isEligible then
            table.insert(eligibleMembers, member)
            ns.guild:DebugPrint(member .. " is eligible")
        else
            ns.guild:DebugPrint(member .. " is not eligible")
        end
    end

    return eligibleMembers
end



function ns.randomizer:UpdateSelectionHistory(member)
    ns.guild:AddToLog("Updating selection history for " .. member)
    LootCouncilRandomizer.db.profile.statistics[member] = LootCouncilRandomizer.db.profile.statistics[member] or {}
    LootCouncilRandomizer.db.profile.statistics[member].lastSelectedTime = time()
    LootCouncilRandomizer.db.profile.statistics[member].timesSelected = (LootCouncilRandomizer.db.profile.statistics[member].timesSelected or 0) + 1

    if LootCouncilRandomizer.db.profile.settings.selectStatisticsMode then
        ns.randomizer:UpdateOfficerNoteWithTimestamp(member)
    end
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

function ns.randomizer:UpdateOfficerNoteWithTimestamp(member)
    if not IsInGuild() then
        ns.guild:DebugPrint("Not in guild, cannot update officer note for " .. member)
        return
    end

    if not C_GuildInfo.CanEditOfficerNote() then
        ns.guild:DebugPrint("No permission to edit officer notes, cannot update officer note for " .. member)
        return
    end

    local guildMemberIndex = ns.guild:GetGuildMemberIndexByName(member)
    if not guildMemberIndex then
        ns.guild:DebugPrint("Member " .. member .. " not found in guild roster")
        return
    end
-- TODO: Für Manu -> Timestamp in [] nur inhalt von klammern ersetzen ansonsten ans ende setzen
    local timestamp = time()
    GuildRosterSetOfficerNote(guildMemberIndex, tostring(timestamp))
    ns.guild:DebugPrint("Updated officer note for " .. member .. " with timestamp " .. tostring(timestamp))
end

function ns.randomizer:GetTimestampFromOfficerNote(member)
    if not IsInGuild() then
        ns.guild:DebugPrint("Not in guild, cannot read officer note for " .. member)
        return 0
    end

    local guildMemberIndex = ns.guild:GetGuildMemberIndexByName(member)
    if not guildMemberIndex then
        ns.guild:DebugPrint("Member " .. member .. " not found in guild roster")
        return 0
    end

    local officerNote = select(8, GetGuildRosterInfo(guildMemberIndex))
    if officerNote then
        local timestamp = tonumber(officerNote)
        if timestamp then
            return timestamp
        else
            ns.guild:DebugPrint("Officer note for " .. member .. " does not contain a valid timestamp")
            return 0
        end
    else
        ns.guild:DebugPrint("No officer note for " .. member)
        return 0
    end
end
