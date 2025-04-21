local ADDON_NAME, ns = ...
ns.randomizer = {}
local module = ns.randomizer
local debug = ns.debug
local utility = ns.utility

local time = time
local math_random = math.random
local table_insert = table.insert
local table_remove = table.remove

local AceGUI = LibStub("AceGUI-3.0")

function module:RandomizeCouncil()
    debug:DebugPrint("Randomizer", "Started council randomization")

    if LootCouncilRandomizer.db.profile.settings.syncWhenRolling then
                ns.sync:InitiateStatisticsSync()
            end

    local originalEntries, eligibleLists = module:PrepareCouncil()
    if LootCouncilRandomizer.db.profile.settings.advancedMode then
        module:ShowRerollPopup(originalEntries, eligibleLists)
    else
        module:FinalizeCouncil(originalEntries, eligibleLists)
    end
end

function module:PrepareCouncil()
    local groupMembers = {}
    local entries = {}
    local eligibleLists = {}
    local debugMode = LootCouncilRandomizer.db.profile.settings.debugMode
    local ignoreMinMembers = LootCouncilRandomizer.db.profile.settings.ignoreMinMembers and debugMode
    local debugTestMode = LootCouncilRandomizer.db.profile.settings.debugTestMode and debugMode
    local groupCount = LootCouncilRandomizer.db.profile.settings.councilPots or 1

    if debugTestMode then
        debug:DebugPrint("Randomizer", "Debug Test Mode is enabled. Getting members from guild.")
        groupMembers = module:GetGuildMembersByGroup()
    else
        groupMembers = module:GetRaidMembersByGroup()
    end

    for i = 1, groupCount do
        local groupName = LootCouncilRandomizer.db.profile.settings["groupName"..i] or ("Group "..i)
        local numToSelect = LootCouncilRandomizer.db.profile.settings["groupSelection"..i] or 0
        local members = groupMembers[i] or {}
        local eligible = module:FilterEligibleMembers(members, i)

        eligibleLists[i] = eligible

        local numEligible = #eligible
        local numToSelectActual = numToSelect

        if numEligible < numToSelect then
            if ignoreMinMembers then
                debug:DebugPrint("Randomizer", "Not enough eligible members in " .. groupName .. ", but ignoring minimum members")
                numToSelectActual = numEligible
            else
                debug:DebugPrint("Randomizer", "Not enough eligible members in " .. groupName)
                print("Not enough eligible members in " .. groupName .. " to select " .. numToSelect .. " members.")
                numToSelectActual = 0
            end
        end

        for j = 1, numToSelectActual do
            if #eligible > 0 then
                local idx = math_random(1, #eligible)
                local member = table_remove(eligible, idx)
                table_insert(entries, { name = member, group = i })
            end
        end
    end

    return entries, eligibleLists
end

function module:ShowRerollPopup(entries, eligibleLists)
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("LootCouncil Preview")
    frame:SetLayout("Flow")
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    self.rerollFrame = frame

    local current = {}
    for i, e in ipairs(entries) do
        current[i] = e.name 
    end
    -- für jeden Slot ein InlineGroup
    for i, e in ipairs(entries) do
        local group = AceGUI:Create("InlineGroup")
        group:SetFullWidth(false)
        group:SetLayout("List")
        group:SetWidth(150)
        group:SetTitle("Slot "..i)
        frame:AddChild(group)

        -- Label mit ursprünglichem Namen
        local lbl = AceGUI:Create("Label")
        lbl:SetText(e.name)
        group:AddChild(lbl)

        -- Dropdown mit allen eligible aus der Gruppe
        local dd = AceGUI:Create("Dropdown")
        local list = {}
        for _, name in ipairs(eligibleLists[e.group]) do
            list[name] = name
        end
        dd:SetList(list)
        dd:SetValue(e.name)
        dd:SetFullWidth(true)
        dd:SetCallback("OnValueChanged", function(_, _, value)
            current[i] = value
        end)
        group:AddChild(dd)

        -- Würfel‑Button (Icon-only)
        local btn = AceGUI:Create("Icon")
        btn:SetImageSize(18,18)
        btn:SetImage("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
        btn:SetCallback("OnClick", function()
            local pool = eligibleLists[e.group]
            if #pool > 0 then
                local rnd = pool[ math_random(1, #pool) ]
                dd:SetValue(rnd)
                current[i] = rnd
            end
        end)
        group:AddChild(btn)
    end

    -- Accept‑Button
    local accept = AceGUI:Create("Button")
    accept:SetText("Accept")
    accept:SetFullWidth(true)
    accept:SetCallback("OnClick", function()
        frame:Hide()
        module:FinalizeCouncil(entries, current)
    end)
    frame:AddChild(accept)
end

function module:FinalizeCouncil(entries, current)
    local announceChanges = LootCouncilRandomizer.db.profile.settings.advancedAnnounceChanges
    if announceChanges then
        for i, e in ipairs(entries) do
            if e.name ~= current[i] then
                SendChatMessage(
                    string.format("%s should have been in the Council, but was replaced with %s", e.name, current[i]),
                    "RAID"
                )
            end
        end
    end

    for _, name in ipairs(current) do
        module:UpdateSelectionHistory(name)
    end

    if #current > 0 then
        SendChatMessage("Selected Loot Council Members:", "RAID")
        for _, name in ipairs(current) do
            SendChatMessage(name, "RAID")
        end
    else
        print("No members selected for the Loot Council.")
    end
    debug:DebugPrint("Randomizer", "Council finalization complete")
end

function module:FilterEligibleMembers(members, groupIndex)
    local eligibleMembers = {}
    local currentTime = time()
    local reselectDuration = LootCouncilRandomizer.db.profile.settings["groupReselectDuration" .. groupIndex] or LootCouncilRandomizer.db.profile.settings.reselectDuration or 0
    local debugTestMode = LootCouncilRandomizer.db.profile.settings.debugTestMode and LootCouncilRandomizer.db.profile.settings.debugMode

    for _, member in ipairs(members) do
        local isEligible = true

        if reselectDuration > 0 and not debugTestMode then
            local lastSelectedTime = 0
            if LootCouncilRandomizer.db.profile.settings.selectStatisticsMode then
                lastSelectedTime = module:GetTimestampFromOfficerNote(member)
            else
                lastSelectedTime = LootCouncilRandomizer.db.profile.statistics[member] and LootCouncilRandomizer.db.profile.statistics[member].lastSelectedTime or 0
            end

            local daysSinceLastSelection = (currentTime - lastSelectedTime) / (24 * 60 * 60)
            if daysSinceLastSelection < reselectDuration then
                isEligible = false
                debug:DebugPrint("Randomizer", string.format("%s was selected %.2f days ago, which is less than reselect duration of %d", member, daysSinceLastSelection, reselectDuration))
            end
        end

        if isEligible then
            table_insert(eligibleMembers, member)
            debug:DebugPrint("Randomizer", member .. " is eligible")
        else
            debug:DebugPrint("Randomizer", member .. " is not eligible")
        end
    end

    return eligibleMembers
end

function module:UpdateSelectionHistory(member)
    ns.debug:AddToLog("Randomizer", "Updating selection history for " .. member)
    LootCouncilRandomizer.db.profile.statistics[member] = LootCouncilRandomizer.db.profile.statistics[member] or {}
    LootCouncilRandomizer.db.profile.statistics[member].lastSelectedTime = time()
    LootCouncilRandomizer.db.profile.statistics[member].timesSelected = (LootCouncilRandomizer.db.profile.statistics[member].timesSelected or 0) + 1

    if LootCouncilRandomizer.db.profile.settings.selectStatisticsMode then
        utility:UpdateOfficerNote(member)
    end
end

function module:SelectRandomMembers(group, count)
    local selected = {}
    local pool = { unpack(group) }

    for i = 1, count do
        if #pool == 0 then break end
        local index = math_random(1, #pool)
        local member = table_remove(pool, index)
        table_insert(selected, member)
    end
    return selected
end

function module:AnnounceCouncil(council)
    local debugTestMode = LootCouncilRandomizer.db.profile.settings.debugTestMode and LootCouncilRandomizer.db.profile.settings.debugMode

    if #council > 0 then
        if debugTestMode then
            debug:AddToLog("Randomizer", "Announcing council members in test mode")
            print("Selected Loot Council Members:")
            for _, member in ipairs(council) do
                print(member)
                debug:AddToLog("Randomizer", "Test Mode - Announced member: " .. member)
            end
        else
            debug:AddToLog("Randomizer", "Announcing council members")
            SendChatMessage("Selected Loot Council Members:", "RAID")
            for _, member in ipairs(council) do
                SendChatMessage(member, "RAID")
                debug:AddToLog("Randomizer", "Announced member: " .. member)
            end
        end
    else
        debug:AddToLog("Randomizer", "No members selected for council")
        print("No members selected for the Loot Council.")
    end
end

function module:GetRaidMembersByGroup()
    local raidMembers = debug:GetRaidMembersWithRanks()
    local groupMembers = {}
    local groupCount = LootCouncilRandomizer.db.profile.settings.councilPots or 1

    for i = 1, groupCount do
        groupMembers[i] = {}
    end

    for name, rankIndex in pairs(raidMembers) do
        for i = 1, groupCount do
            local groupRanks = LootCouncilRandomizer.db.profile.settings["groupRanks" .. i] or {}
            if groupRanks[rankIndex] then
                table_insert(groupMembers[i], name)
                break
            end
        end
    end
    return groupMembers
end

function module:ParseCommaSeparatedList(inputString)
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

function module:GetCurrentEligibleMembers()
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

function module:UpdateOfficerNoteWithTimestamp(member)
    if not IsInGuild() then
        debug:DebugPrint("Randomizer", "Not in guild, cannot update officer note for " .. member)
        return
    end

    if not C_GuildInfo.CanEditOfficerNote() then
        debug:DebugPrint("Randomizer", "No permission to edit officer notes, cannot update officer note for " .. member)
        return
    end

    local guildMemberIndex = debug:GetGuildMemberIndexByName(member)
    if not guildMemberIndex then
        debug:DebugPrint("Randomizer", "Member " .. member .. " not found in guild roster")
        return
    end
-- TODO: Für Manu -> Timestamp in [] nur inhalt von klammern ersetzen ansonsten ans ende setzen
    local timestamp = time()
    GuildRosterSetOfficerNote(guildMemberIndex, tostring(timestamp))
    debug:DebugPrint("Randomizer", "Updated officer note for " .. member .. " with timestamp " .. tostring(timestamp))
end

function module:GetTimestampFromOfficerNote(member)
    return utility:GetTimestampFromOfficerNote(member)
end

function module:GetGuildMembersByGroup()
    local guildMembers = debug:GetGuildMembersWithRanks()
    local groupMembers = {}
    local groupCount = LootCouncilRandomizer.db.profile.settings.councilPots or 1

    for i = 1, groupCount do
        groupMembers[i] = {}
    end

    for name, rankIndex in pairs(guildMembers) do
        for i = 1, groupCount do
            local groupRanks = LootCouncilRandomizer.db.profile.settings["groupRanks" .. i] or {}
            if groupRanks[rankIndex] then
                table_insert(groupMembers[i], name)
                break
            end
        end
    end
    return groupMembers
end
