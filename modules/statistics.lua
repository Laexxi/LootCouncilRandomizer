
local ADDON_NAME, ns = ...
ns.statistics = {}

function ns.statistics:GetOptions()
    return {
        name = "(TODO) Statistics",
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
