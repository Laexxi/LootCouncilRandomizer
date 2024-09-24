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
                    councilSize = {
                        type = "range",
                        name = "Number of Council Members",
                        desc = "Set the number of council members.",
                        min = 1,
                        max = 30,
                        step = 1,
                        get = function(info)
                            return LootCouncilRandomizer.db.profile.settings.councilSize or 5
                        end,
                        set = function(info, value)
                            LootCouncilRandomizer.db.profile.settings.councilSize = value
                            ns.config:ClampGroupSelections(value)
                        end,
                        order = 2,
                    },
                    councilPots = {
                        type = "range",
                        name = "Number of Groups",
                        desc = "Set the number of groups for the loot council.",
                        min = 1,
                        max = 10,
                        step = 1,
                        get = function(info)
                            return LootCouncilRandomizer.db.profile.settings.councilPots or 1
                        end,
                        set = function(info, value)
                            LootCouncilRandomizer.db.profile.settings.councilPots = value
                            ns.config:UpdateGroupNames(value)
                        end,
                        order = 3,
                    },
                    reselectDuration = {
                        type = "range",
                        name = "Reselect Prevention",
                        desc = "How many days to prevent reselection for the same person in the LootCouncil.",
                        min = 0,
                        max = 7,
                        step = 1,
                        get = function(info)
                            return LootCouncilRandomizer.db.profile.settings.reselectDuration or 0
                        end,
                        set = function(info, value)
                            LootCouncilRandomizer.db.profile.settings.reselectDuration = value
                        end,
                        order = 4,
                    },
                    selectStatisticsMode = {
                        type = "toggle",
                        name = "(TODO) Use Officer Notes",
                        desc = "When selected the info, when the member was last selected, will be stored in the Officers note.",
                        order = 98,
                    },
                    selectDebugMode = {
                        type = "toggle",
                        name = "Debug Settings",
                        desc = "Show the Debug Settings to help to find bugs of the addon.",
                        get = function(info)
                            return LootCouncilRandomizer.db.profile.settings.debugMode or false
                        end,
                        set = function(info, value)
                            LootCouncilRandomizer.db.profile.settings.debugMode = value
                            if LootCouncilRandomizer.options and LootCouncilRandomizer.options.args.settings then
                                LootCouncilRandomizer.options.args.settings.args.debugSettings.hidden = not value
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("LootCouncilRandomizer")
                            end
                        end,
                        order = 99,
                    },
                },
            },
            groups = {
                type = "group",
                name = "Groups",
                order = 2,
                args = ns.config:GetGroupOptions(),
            },
            forcedPlayers = {
                type = "group",
                name = "Forced/Excluded Players",
                order = 3,
                args = {
                    forcedList = {
                        type = "input",
                        name = "Forced Players",
                        desc = "Enter player names separated by commas.",
                        get = function(info)
                            return LootCouncilRandomizer.db.profile.settings.forcedPlayers or ""
                        end,
                        set = function(info, value)
                            LootCouncilRandomizer.db.profile.settings.forcedPlayers = value
                        end,
                        order = 1,
                    },
                    excludedList = {
                        type = "input",
                        name = "Excluded Players",
                        desc = "Enter player names separated by commas.",
                        get = function(info)
                            return LootCouncilRandomizer.db.profile.settings.excludedPlayers or ""
                        end,
                        set = function(info, value)
                            LootCouncilRandomizer.db.profile.settings.excludedPlayers = value
                        end,
                        order = 2,
                    },
                },
            },
            
            syncSettings = {
                type = "group",
                name = "Sync Settings",
                order = 4,
                args = {syncToDescription = {
                    type = "description",
                    name = "Sync to:",
                    fontSize = "medium",
                    order = 1,
                },
                syncTo = {
                    type = "select",
                    name = "",
                    desc = "Select where to sync the data.",
                    values = {
                        guild = "Guild",
                        raid = "Raid",
                        player = "Player",
                    },
                    get = function(info)
                        return LootCouncilRandomizer.db.profile.settings.syncTo or "guild"
                    end,
                    set = function(info, value)
                        LootCouncilRandomizer.db.profile.settings.syncTo = value
                        -- Aktualisiere die Anzeige, wenn "Player" ausgewählt wird
                        if LootCouncilRandomizer.options then
                            LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
                        end
                    end,
                    order = 2,
                },
                syncToPlayerName = {
                    type = "input",
                    name = "Player Name",
                    desc = "Enter the name of the player to sync with.",
                    hidden = function()
                        return LootCouncilRandomizer.db.profile.settings.syncTo ~= "player"
                    end,
                    get = function(info)
                        return LootCouncilRandomizer.db.profile.settings.syncToPlayerName or ""
                    end,
                    set = function(info, value)
                        LootCouncilRandomizer.db.profile.settings.syncToPlayerName = value
                    end,
                    order = 3,
                },
                syncWhenRolling = {
                    type = "toggle",
                    name = "Sync when rolling council",
                    desc = "Automatically sync settings when rolling the council.",
                    get = function(info)
                        return LootCouncilRandomizer.db.profile.settings.syncWhenRolling or false
                    end,
                    set = function(info, value)
                        LootCouncilRandomizer.db.profile.settings.syncWhenRolling = value
                    end,
                    order = 4,
                },
                spacer = {
                    type = "header",
                    name = "",
                    order = 5,
                },
                syncSettingsButton = {
                    type = "execute",
                    name = "Sync Settings",
                    desc = "Synchronize settings now.",
                    func = function()
                        -- Hier kannst du später die Synchronisationsfunktion hinzufügen
                        print("Sync Settings button clicked.")
                    end,
                    order = 6,
                },
                syncStatisticsButton = {
                    type = "execute",
                    name = "Sync Statistics",
                    desc = "Synchronize statistics now.",
                    func = function()
                        -- Hier kannst du später die Synchronisationsfunktion hinzufügen
                        print("Sync Statistics button clicked.")
                    end,
                    order = 7,
                },
                    
                },
            },
            debugSettings = {
                type = "group",
                name = "Debug Settings",
                order = 5,
                hidden = function()
                    return not LootCouncilRandomizer.db.profile.settings.debugMode
                end,
                args = {
                    importRanks = {
                        type = "execute",
                        name = "Import All Ranks",
                        desc = "Import all guild ranks.",
                        func = function()
                            ns.config:ImportAllRanks()
                        end,
                        order = 1,
                    },
                    rankSelection = {
                        type = "multiselect",
                        name = "Select Ranks",
                        desc = "Select the ranks to include.",
                        values = function()
                            return ns.guild:GetGuildRanks()
                        end,
                        get = function(info, key)
                            return LootCouncilRandomizer.db.profile.settings.selectedRanks[key] or false
                        end,
                        set = function(info, key, value)
                            LootCouncilRandomizer.db.profile.settings.selectedRanks[key] = value
                            if LootCouncilRandomizer.options and LootCouncilRandomizer.options.args.guildOverview then
                                LootCouncilRandomizer.options.args.guildOverview = ns.guild:GetOptions()
                                LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
                            end
                        end,
                        order = 2,
                    },
                    debugMode = {
                        type = "toggle",
                        name = "(TODO)Ignore minimum Members",
                        desc = "Enable the possibility to roll the council with less members as required.",
                        order = 3,
                        get = function(info)
                            return LootCouncilRandomizer.db.profile.settings.ignoreMinMembers or false
                        end,
                        set = function(info, value)
                            LootCouncilRandomizer.db.profile.settings.ignoreMinMembers = value
                        end,
                    },
                    enableLogging = {
                        type = "toggle",
                        name = "(TODO) Enable Logging",
                        desc = "Enable the logging of the addon.",
                        order = 4,
                    },
                },
            },
            saveSettings = {
                type = "execute",
                name = "Save Settings",
                func = function()
                    print("LCR: Settings saved.")
                end,
                order = 6,
            },
        },
    }

    return options
end

function ns.config:GetGroupOptions()
    local groupOptions = {}
    local groupCount = LootCouncilRandomizer.db.profile.settings.councilPots or 1
    local councilSize = LootCouncilRandomizer.db.profile.settings.councilSize or 5

    for i = 1, groupCount do
        groupOptions["group" .. i] = {
            type = "group",
            name = LootCouncilRandomizer.db.profile.settings["groupName" .. i] or "Group " .. i,
            inline = false,
            order = i,
            args = {
                groupName = {
                    type = "input",
                    name = "Group Name",
                    desc = "Name of the group.",
                    get = function(info)
                        return LootCouncilRandomizer.db.profile.settings["groupName" .. i] or "Group " .. i
                    end,
                    set = function(info, value)
                        LootCouncilRandomizer.db.profile.settings["groupName" .. i] = value
                        if LootCouncilRandomizer.options and LootCouncilRandomizer.options.args.groups.args["group" .. i] then
                            LootCouncilRandomizer.options.args.groups.args["group" .. i].name = value
                            LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
                        end
                    end,
                    order = 1,
                },
                groupSelection = {
                    type = "range",
                    name = "Number of members selected from this group",
                    desc = "Set the number of members selected from this group.",
                    min = 0,
                    max = councilSize,
                    step = 1,
                    get = function(info)
                        return LootCouncilRandomizer.db.profile.settings["groupSelection" .. i] or 0
                    end,
                    set = function(info, value)
                        LootCouncilRandomizer.db.profile.settings["groupSelection" .. i] = value
                        ns.config:AdjustGroupSelection(i, value)
                    end,
                    order = 2,
                },
                groupReselectDuration = {
                    type = "range",
                    name = "Reselect Prevention Duration",
                    desc = "Number of days to prevent reselection for this group.",
                    min = 0,
                    max = 7,
                    step = 1,
                    get = function(info)
                        return LootCouncilRandomizer.db.profile.settings["groupReselectDuration" .. i] or LootCouncilRandomizer.db.profile.settings.reselectDuration or 0
                    end,
                    set = function(info, value)
                        LootCouncilRandomizer.db.profile.settings["groupReselectDuration" .. i] = value
                    end,
                    order = 3,
                },
                groupRanks = {
                    type = "multiselect",
                    name = "Assign Ranks to this group",
                    desc = "Select the guild ranks to assign to this group.",
                    values = function()
                        return ns.guild:GetGuildRanks()
                    end,
                    get = function(info, key)
                        local groupRanks = LootCouncilRandomizer.db.profile.settings["groupRanks" .. i] or {}
                        return groupRanks[key] or false
                    end,
                    set = function(info, key, value)
                        LootCouncilRandomizer.db.profile.settings["groupRanks" .. i] = LootCouncilRandomizer.db.profile.settings["groupRanks" .. i] or {}
                        LootCouncilRandomizer.db.profile.settings["groupRanks" .. i][key] = value
                    end,
                    order = 4,
                },
            },
        }
    end

    return groupOptions
end

function ns.config:UpdateGroupNames(count)
    for i = 1, count do
        if not LootCouncilRandomizer.db.profile.settings["groupName" .. i] then
            LootCouncilRandomizer.db.profile.settings["groupName" .. i] = "Group " .. i
        end
    end

    for i = count + 1, 10 do
        LootCouncilRandomizer.db.profile.settings["groupName" .. i] = nil
        LootCouncilRandomizer.db.profile.settings["groupSelection" .. i] = nil
        LootCouncilRandomizer.db.profile.settings["groupReselectDuration" .. i] = nil
    end

    if LootCouncilRandomizer.options and LootCouncilRandomizer.options.args.groups then
        LootCouncilRandomizer.options.args.groups.args = ns.config:GetGroupOptions()
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    end
end

function ns.config:ClampGroupSelections(maxValue)
    local total = 0
    local groupCount = LootCouncilRandomizer.db.profile.settings.councilPots or 1

    for i = 1, groupCount do
        local selection = LootCouncilRandomizer.db.profile.settings["groupSelection" .. i] or 0
        if selection > maxValue then
            selection = maxValue
        end
        total = total + selection
    end

    if total > maxValue then
        ns.config:AdjustGroupSelection(1, maxValue)
    end

    if LootCouncilRandomizer.options and LootCouncilRandomizer.options.args.groups then
        LootCouncilRandomizer.options.args.groups.args = ns.config:GetGroupOptions()
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    end
end

function ns.config:AdjustGroupSelection(changedGroup, newValue)
    local maxCouncilSize = LootCouncilRandomizer.db.profile.settings.councilSize
    local total = 0
    local groupCount = LootCouncilRandomizer.db.profile.settings.councilPots or 1

    for i = 1, groupCount do
        if i ~= changedGroup then
            total = total + (LootCouncilRandomizer.db.profile.settings["groupSelection" .. i] or 0)
        end
    end

    total = total + newValue
    if total > maxCouncilSize then
        local excess = total - maxCouncilSize
        for i = 1, groupCount do
            if i ~= changedGroup and excess > 0 then
                local currentSelection = LootCouncilRandomizer.db.profile.settings["groupSelection" .. i] or 0
                if currentSelection > 0 then
                    local reduction = math.min(currentSelection, excess)
                    LootCouncilRandomizer.db.profile.settings["groupSelection" .. i] = currentSelection - reduction
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
        LootCouncilRandomizer.db.profile.settings.selectedRanks[key] = true
    end
    ns.config:UpdateRankSelection()
end

function ns.config:UpdateRankSelection()
    if LootCouncilRandomizer.options then
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    end
end
