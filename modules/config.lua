--[[
config.lua
Handles the configuration and settings for the LootCouncilRandomizer addon.
Provides options for general settings and groups.

Functions:
- GetOptions: Returns the configuration options for the addon.
- GetGroupOptions: Returns the options for naming the groups and selecting the number of members per group.
- UpdateGroupNames: Updates group names and their selection options based on the number of groups.
- ImportAllRanks: Imports all guild ranks and updates the rank selection.
- AdjustGroupSelection: Adjusts group selection numbers to ensure the total does not exceed the maximum council size.
- ClampGroupSelections: Ensures group selections are within the bounds of the council size.
]]

local ADDON_NAME, ns = ...
ns.config = {}

function ns.config:GetOptions()
    local options = {
        name = "Settings",
        type = "group",
        childGroups = "tab",
        args = {
            general = {
                type = "group",
                name = "General Settings",
                order = 1,
                args = {
                    desc = {
                        type = "description",
                        name = "Settings for the Loot Council Randomizer.",
                        order = 1,
                    },
                    importRanks = {
                        type = "execute",
                        name = "Import All Ranks",
                        desc = "Import all guild ranks.",
                        func = function()
                            ns.config:ImportAllRanks()
                        end,
                        order = 2,
                    },
                    rankSelection = {
                        type = "multiselect",
                        name = "Select Ranks",
                        desc = "Select the ranks to include.",
                        values = function()
                            return ns.guild:GetGuildRanks()
                        end,
                        get = function(info, key)
                            return LootCouncilRandomizer.db.char.selectedRanks[key] or false
                        end,
                        set = function(info, key, value)
                            LootCouncilRandomizer.db.char.selectedRanks[key] = value
                        end,
                        order = 3,
                    },
                    councilSize = {
                        type = "range",
                        name = "Number of Council Members",
                        desc = "Set the number of council members.",
                        min = 1,
                        max = 30,
                        step = 1,
                        get = function(info)
                            return LootCouncilRandomizer.db.char.councilSize or 5
                        end,
                        set = function(info, value)
                            LootCouncilRandomizer.db.char.councilSize = value
                            ns.config:ClampGroupSelections(value)
                        end,
                        order = 4,
                    },
                    councilPots = {
                        type = "range",
                        name = "Number of Groups",
                        desc = "Set the number of groups for the loot council.",
                        min = 1,
                        max = 10,
                        step = 1,
                        get = function(info)
                            return LootCouncilRandomizer.db.char.councilPots or 1
                        end,
                        set = function(info, value)
                            LootCouncilRandomizer.db.char.councilPots = value
                            ns.config:UpdateGroupNames(value)
                        end,
                        order = 5,
                    },
                },
            },
            groups = {
                type = "group",
                name = "Groups",
                order = 2,
                args = ns.config:GetGroupOptions(),
            },
            saveSettings = {
                type = "execute",
                name = "Save Settings",
                func = function()
                    print("Settings saved.")
                end,
                order = 3,
            },
        },
    }

    return options
end

function ns.config:GetGroupOptions()
    local groupOptions = {}
    local groupCount = LootCouncilRandomizer.db.char.councilPots or 1
    local councilSize = LootCouncilRandomizer.db.char.councilSize or 5

    for i = 1, groupCount do
        groupOptions["group" .. i] = {
            type = "input",
            name = "Group " .. i .. " Name",
            desc = "Name of group " .. i,
            get = function(info)
                return LootCouncilRandomizer.db.char["groupName" .. i] or "Group " .. i
            end,
            set = function(info, value)
                LootCouncilRandomizer.db.char["groupName" .. i] = value
            end,
            order = i * 2 - 1,
        }
        groupOptions["groupSelection" .. i] = {
            type = "range",
            name = "Number of members selected from " .. (LootCouncilRandomizer.db.char["groupName" .. i] or "Group " .. i),
            desc = "Set the number of members selected from " .. (LootCouncilRandomizer.db.char["groupName" .. i] or "Group " .. i),
            min = 0,
            max = councilSize, -- Clamp to council size
            step = 1,
            get = function(info)
                return LootCouncilRandomizer.db.char["groupSelection" .. i] or 0
            end,
            set = function(info, value)
                LootCouncilRandomizer.db.char["groupSelection" .. i] = value
                ns.config:AdjustGroupSelection(i, value)
            end,
            order = i * 2,
        }
    end

    return groupOptions
end

function ns.config:UpdateGroupNames(count)
    for i = 1, count do
        if not LootCouncilRandomizer.db.char["groupName" .. i] then
            LootCouncilRandomizer.db.char["groupName" .. i] = "Group " .. i
        end
    end

    for i = count + 1, 10 do
        LootCouncilRandomizer.db.char["groupName" .. i] = nil
        LootCouncilRandomizer.db.char["groupSelection" .. i] = nil
    end

    if LootCouncilRandomizer.options and LootCouncilRandomizer.options.args.groups then
        LootCouncilRandomizer.options.args.groups.args = ns.config:GetGroupOptions()
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    end
end

function ns.config:ClampGroupSelections(maxValue)
    local total = 0
    local groupCount = LootCouncilRandomizer.db.char.councilPots or 1

    for i = 1, groupCount do
        local selection = LootCouncilRandomizer.db.char["groupSelection" .. i] or 0
        if selection > maxValue then
            selection = maxValue
        end
        total = total + selection
    end

    if total > maxValue then
        ns.config:AdjustGroupSelection(1, maxValue) -- Start adjustment from the first group
    end

    if LootCouncilRandomizer.options and LootCouncilRandomizer.options.args.groups then
        LootCouncilRandomizer.options.args.groups.args = ns.config:GetGroupOptions()
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    end
end

function ns.config:AdjustGroupSelection(changedGroup, newValue)
    local maxCouncilSize = LootCouncilRandomizer.db.char.councilSize
    local total = 0
    local groupCount = LootCouncilRandomizer.db.char.councilPots or 1

    for i = 1, groupCount do
        if i ~= changedGroup then
            total = total + (LootCouncilRandomizer.db.char["groupSelection" .. i] or 0)
        end
    end

    total = total + newValue
    if total > maxCouncilSize then
        local excess = total - maxCouncilSize
        for i = 1, groupCount do
            if i ~= changedGroup and excess > 0 then
                local currentSelection = LootCouncilRandomizer.db.char["groupSelection" .. i] or 0
                if currentSelection > 0 then
                    local reduction = math.min(currentSelection, excess)
                    LootCouncilRandomizer.db.char["groupSelection" .. i] = currentSelection - reduction
                    excess = excess - reduction
                end
            end
        end
    end

    if LootCouncilRandomizer.options and LootCouncilRandomizer.options.args.groups then
        LootCouncilRandomizer.options.args.groups.args = ns.config:GetGroupOptions()
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    end
end

function ns.config:ImportAllRanks()
    local ranks = ns.guild:GetGuildRanks()
    for key, _ in pairs(ranks) do
        LootCouncilRandomizer.db.char.selectedRanks[key] = true
    end
    ns.config:UpdateRankSelection()
end

function ns.config:UpdateRankSelection()
    if LootCouncilRandomizer.options then
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    end
end
