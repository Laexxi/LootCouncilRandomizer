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
                    guildRank = {
                        type = "select",
                        name = "Minimum Rank for Loot Council",
                        desc = "Select the minimum guild rank allowed to participate.",
                        values = function() return ns.guild:GetGuildRanks() end,
                        get = function(info)
                            return LootCouncilRandomizer.db.char.selectedRankIndex or 1
                        end,
                        set = function(info, value)
                            LootCouncilRandomizer.db.char.selectedRankIndex = value
                            LootCouncilRandomizer.db.char.selectedRankName = GuildControlGetRankName(value - 1)
                        end,
                        order = 2,
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
                        end,
                        order = 3,
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
                        order = 4,
                    },
                },
            },
            groups = {
                type = "group",
                name = "Groups",
                order = 2,
                args = ns.config:GetGroupOptions(),
            },
            groupSelection = {
                type = "group",
                name = "Group Selection",
                order = 3,
                args = ns.config:GetGroupSelectionOptions(),
            },
            saveSettings = {
                type = "execute",
                name = "Save Settings",
                func = function()
                    print("Settings saved.")
                end,
                order = 4,
            },
        },
    }

    return options
end

function ns.config:GetGroupOptions()
    local groupOptions = {}
    local groupCount = LootCouncilRandomizer.db.char.councilPots or 1

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
            order = i,
        }
    end

    return groupOptions
end

function ns.config:GetGroupSelectionOptions()
    local groupSelectionOptions = {}
    local groupCount = LootCouncilRandomizer.db.char.councilPots or 1

    for i = 1, groupCount do
        groupSelectionOptions["groupSelection" .. i] = {
            type = "range",
            name = "Number of " .. (LootCouncilRandomizer.db.char["groupName" .. i] or "Group " .. i),
            desc = "Set the number of members selected from " .. (LootCouncilRandomizer.db.char["groupName" .. i] or "Group " .. i),
            min = 0,
            max = 30,
            step = 1,
            get = function(info)
                return LootCouncilRandomizer.db.char["groupSelection" .. i] or 0
            end,
            set = function(info, value)
                LootCouncilRandomizer.db.char["groupSelection" .. i] = value
            end,
            order = i,
        }
    end

    return groupSelectionOptions
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

    if LootCouncilRandomizer.options then
        LootCouncilRandomizer.options.args.groups.args = ns.config:GetGroupOptions()
        LootCouncilRandomizer.options.args.groupSelection.args = ns.config:GetGroupSelectionOptions()
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    end
end
