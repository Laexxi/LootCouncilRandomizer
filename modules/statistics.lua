--[[
statistics.lua
Handles the statistics tracking for the LootCouncilRandomizer addon.
Tracks the selection history and provides options to view and reset statistics.

Functions:
- GetOptions: Returns the configuration options for the statistics overview.
- RecordSelection: Records the selection of council members for tracking purposes.
- GetStatistics: Retrieves the selection statistics.
- ResetStatistics: Resets the selection statistics.
]]

local ADDON_NAME, ns = ...
ns.statistics = {}

function ns.statistics:GetOptions()
    return {
        name = "Statistics",
        type = "group",
        args = {
            resetStats = {
                type = "execute",
                name = "Reset Statistics",
                func = function()
                    LootCouncilRandomizer.db.profile.statistics = {}
                    print("Statistics reset.")
                end,
            },
            statsDescription = {
                type = "description",
                name = function()
                    local stats = LootCouncilRandomizer.db.profile.statistics or {}
                    local desc = "Statistics:\n"
                    for member, data in pairs(stats) do
                        desc = desc .. member .. ": " .. data.timesSelected .. " times, last selected " .. data.lastSelected .. "\n"
                    end
                    return desc
                end,
            },
        },
    }
end
