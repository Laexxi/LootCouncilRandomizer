local ADDON_NAME, ns = ...
ns.config = {}

function ns.config:GetOptions()
    return {
        name = "Settings",
        type = "group",
        args = {
            desc = {
                type = "description",
                name = "Settings for the Loot Council Randomizer.",
            },
            guildRank = {
                type = "select",
                name = "Minimum Rank for Loot Council",
                desc = "Select the minimum guild rank allowed to participate.",
                values = function() return ns.guild:GetGuildRanks() end,
                get = function(info)
                    return LootCouncilRandomizer.db.profile.selectedRankIndex or 1
                end,
                set = function(info, value)
                    LootCouncilRandomizer.db.profile.selectedRankIndex = value
                    LootCouncilRandomizer.db.profile.selectedRankName = GuildControlGetRankName(value - 1)
                end,
            },
            councilSize = {
                type = "range",
                name = "Number of Council Members",
                desc = "Set the number of council members.",
                min = 1,
                max = 30,
                step = 1,
                get = function(info)
                    return LootCouncilRandomizer.db.profile.councilSize or 5
                end,
                set = function(info, value)
                    LootCouncilRandomizer.db.profile.councilSize = value
                end,
            },
            councilPots = {
                type = "range",
                name = "Number of Groups",
                desc = "Set the number of groups for the loot council.",
                min = 1,
                max = 30,
                step = 1,
                get = function(info)
                    return LootCouncilRandomizer.db.profile.councilPots or 1
                end,
                set = function(info, value)
                    if value <= LootCouncilRandomizer.db.profile.councilSize then
                        LootCouncilRandomizer.db.profile.councilPots = value
                    else
                        print("Number of groups cannot be greater than the number of council members.")
                    end
                end,
            },
            saveSettings = {
                type = "execute",
                name = "Save Settings",
                func = function()
                    print("Settings saved.")
                end,
            },
        },
    }
end
