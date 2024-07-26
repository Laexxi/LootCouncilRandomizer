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
                    -- Logic to reset statistics
                    print("Statistics reset.")
                end,
            },
            statsDescription = {
                type = "description",
                name = "Statistics will be displayed here.",
            },
        },
    }
end
