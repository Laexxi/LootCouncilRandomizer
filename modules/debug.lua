local ADDON_NAME, ns = ...
ns.debug = {}
local utility = ns.utility

local logBuffer = ""
function ns.debug:AddToLog(message)
    logBuffer = logBuffer .. message .. "\n"
    if self.editBox then
        self.editBox:SetText(logBuffer)
        self.editBox:HighlightText(0, 0)
        self.editBox:SetCursorPosition(self.editBox:GetNumLetters())
        self.editBox:ClearFocus()
    end
end

function ns.debug:ClearLog()
    logBuffer = ""
    if self.editBox then
        self.editBox:SetText("")
    end
end

function ns.debug:GetLog()
    return logBuffer
end

function ns.debug:DebugPrint(category, message)
    if LootCouncilRandomizer.db.profile.settings.debugMode then
        if not self.AddToLog then
            print("AddToLog function is missing!")
            return
        end
        self:AddToLog("[" .. category .. "] " .. message)
    end
end



function ns.debug:GetGuildRanks()
    local ranks = {}
    if IsInGuild() then
        for i = 1, GuildControlGetNumRanks() do
            local rankName = GuildControlGetRankName(i)
            if rankName and rankName ~= "" then
                ranks[i] = rankName
            end
        end
    end
    return ranks
end

function ns.debug:GetMembersByRank(rankIndex)
    local members = {}
    if IsInGuild() then
        for i = 1, GetNumGuildMembers() do
            local name, _, rankIndexMember = GetGuildRosterInfo(i)
            if rankIndexMember == rankIndex - 1 then
                local shortName = Ambiguate(name, "short")
                table.insert(members, shortName)
            end
        end
        table.sort(members)
    end
    return members
end

function ns.debug:GetOptions()
    local options = {
        name = "DEBUG",
        type = "group",
        childGroups = "tab",
        hidden = function()
            return not LootCouncilRandomizer.db.profile.settings.debugMode
        end,
        args = {
            guildRanks = {
                type = "group",
                name = "Guild Ranks Overview",
                order = 1,
                args = self:GetGuildRanksOptions(),
            },
            currentGroups = {
                type = "group",
                name = "Current Groups Overview",
                order = 2,
                args = self:GetCurrentGroupsOptions(),
            },
            logOutputTab = {
                type = "group",
                name = "Log Output",
                order = 3,
                args = self:GetLogOptions(),
            },
        },
    }

    return options
end

function ns.debug:GetGuildRanksOptions()
    local options = {}
    local selectedRanks = LootCouncilRandomizer.db.profile.settings.selectedRanks or {}
    local guildRanks = ns.debug:GetGuildRanks()

    for rankIndex, isSelected in pairs(selectedRanks) do
        if isSelected and guildRanks[rankIndex] then
            local rankName = guildRanks[rankIndex]
            options["rank" .. rankIndex] = {
                type = "group",
                name = rankName,
                inline = false,
                args = {},
            }

            local members = self:GetMembersByRank(rankIndex)
            if #members > 0 then
                for i, memberName in ipairs(members) do
                    options["rank" .. rankIndex].args["member" .. i] = {
                        type = "description",
                        name = memberName,
                        order = i,
                    }
                end
            else
                options["rank" .. rankIndex].args["noMembers"] = {
                    type = "description",
                    name = "No members in this rank.",
                    order = 1,
                }
            end
        end
    end

    return options
end

function ns.debug:GetCurrentGroupsOptions()
    local options = {}

    local groupMembers = ns.randomizer:GetCurrentEligibleMembers()
    local groupCount = LootCouncilRandomizer.db.profile.settings.councilPots or 1

    for i = 1, groupCount do
        local groupName = LootCouncilRandomizer.db.profile.settings["groupName" .. i] or "Group " .. i
        options["group" .. i] = {
            type = "group",
            name = groupName,
            inline = false,
            args = {},
        }

        local members = groupMembers[i] or {}
        if #members > 0 then
            for j, memberName in ipairs(members) do
                options["group" .. i].args["member" .. j] = {
                    type = "description",
                    name = memberName,
                    order = j,
                }
            end
        else
            options["group" .. i].args["noMembers"] = {
                type = "description",
                name = "No eligible members in this group.",
                order = 1,
            }
        end
    end

    return options
end

function ns.debug:ShowGroupMembers()
    local groupCount = LootCouncilRandomizer.db.profile.settings.councilPots or 1

    for i = 1, groupCount do
        local members = ns.debug:GetMembersByGroup(i)
        if #members > 0 then
            print("Group " .. i .. " members:", table.concat(members, ", "))
        else
            print("Group " .. i .. " has no members.")
        end
    end
end

function ns.debug:GetMembersByGroup(groupIndex)
    local groupRanks = LootCouncilRandomizer.db.profile.settings["groupRanks" .. groupIndex]
    local members = {}
    local raidMembers = ns.debug:GetRaidMembers()

    if IsInGuild() and IsInRaid() then
        for i = 1, GetNumGuildMembers() do
            local name, _, rankIndexMember = GetGuildRosterInfo(i)
            rankIndexMember = rankIndexMember + 1

            local shortName = Ambiguate(name, "short")
            if groupRanks and groupRanks[rankIndexMember] and raidMembers[shortName] then
                table.insert(members, shortName)
            end
        end
    end

    return members
end

function ns.debug:GetRaidMembers()
    local raidMembers = {}
    local numRaidMembers = GetNumGroupMembers()

    if numRaidMembers > 0 and IsInRaid() then
        for i = 1, numRaidMembers do
            local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
            if name and online then 
                name = Ambiguate(name, "short")
                raidMembers[name] = true
            end
        end
    end
    return raidMembers
end

function ns.debug:GetRaidMembersWithRanks()
    local raidMembers = {}
    local numRaidMembers = GetNumGroupMembers()

    if numRaidMembers > 0 and IsInRaid() then
        for i = 1, numRaidMembers do
            local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
            if name and online then 
                name = Ambiguate(name, "short")
                local guildIndex = ns.debug:GetGuildMemberIndexByName(name)
                if guildIndex then
                    local _, _, rankIndex = GetGuildRosterInfo(guildIndex)
                    rankIndex = rankIndex + 1
                    raidMembers[name] = rankIndex
                end
            end
        end
    end

    return raidMembers
end

function ns.debug:GetGuildMemberIndexByName(name)
    if IsInGuild() then
        for i = 1, GetNumGuildMembers() do
            local guildName = GetGuildRosterInfo(i)
            guildName = Ambiguate(guildName, "short")
            if guildName == name then
                return i
            end
        end
    end
    return nil
end

function ns.debug:GetGuildMembersWithRanks()
    local guildMembers = {}
    if IsInGuild() then
        for i = 1, GetNumGuildMembers() do
            local name, _, rankIndex = GetGuildRosterInfo(i)
            if name then
                name = Ambiguate(name, "short")
                rankIndex = rankIndex + 1 -- Lua indiziert ab 1
                guildMembers[name] = rankIndex
            end
        end
    end
    return guildMembers
end

function ns.debug:CreateLogFrame()
    if self.logFrame then return end

    -- Nutzung der generischen Fenster-Erstellungsfunktion
    self.logFrame = utility:CreateBasicWindow("LootCouncilRandomizerLogFrame", "LootCouncilRandomizer Log", 500, 400)

    -- ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", "LootCouncilRandomizerLogScrollFrame", self.logFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", self.logFrame, "TOPLEFT", 15, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", self.logFrame, "BOTTOMRIGHT", -30, 45)

    -- EditBox
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(false)

    scrollFrame:SetScrollChild(editBox)

    -- Clear-Button
    local clearButton = CreateFrame("Button", nil, self.logFrame, "UIPanelButtonTemplate")
    clearButton:SetSize(80, 22)
    clearButton:SetPoint("BOTTOMLEFT", self.logFrame, "BOTTOMLEFT", 15, 15)
    clearButton:SetText("Clear")
    clearButton:SetScript("OnClick", function()
        ns.debug:ClearLog()
        editBox:SetText("")
    end)

    self.editBox = editBox
end

function ns.debug:ShowLogFrame()
    if not self.logFrame then
        self:CreateLogFrame()
    end
    self.logFrame:Show()
    -- Aktualisiere den Inhalt der EditBox
    if self.editBox then
        self.editBox:SetText(logBuffer)
        self.editBox:HighlightText(0, 0)
        self.editBox:SetCursorPosition(self.editBox:GetNumLetters())
        self.editBox:ClearFocus()
    end
end

function ns.debug:HideLogFrame()
    if self.logFrame then
        self.logFrame:Hide()
    end
end

function ns.debug:ToggleLogFrame()
    if self.logFrame and self.logFrame:IsShown() then
        self:HideLogFrame()
    else
        self:ShowLogFrame()
    end
end

function ns.debug:GetLogOptions()
    local options = {
        openLogWindowButton = {
            type = "execute",
            name = "Open Log Window",
            desc = "Opens the log output window.",
            func = function()
                ns.debug:ShowLogFrame()
            end,
            order = 1,
        },
        clearLogButton = {
            type = "execute",
            name = "Clear Log",
            desc = "Clear the current log output.",
            func = function()
                ns.debug:ClearLog()
            end,
            order = 2,
        },
    }

    return options
end


