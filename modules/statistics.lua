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
                desc = "This will reset all statistics.",
                confirm = true,
                confirmText = "Are you sure you want to reset all statistics?",
                func = function()
                    LootCouncilRandomizer.db.profile.statistics = {}
                    print("Loot Council Randomizer: All statistics have been reset.")
                end,
                order = 1,
            },
            statsDescription = {
                type = "description",
                name = function()
                    local stats = LootCouncilRandomizer.db.profile.statistics or {}
                    local desc = "Council Member Statistics:\n\n"
                    
                    if next(stats) == nil then
                        return desc .. "No statistics available.\n"
                    end
            
                    local guildMembers = ns.statistics:GetGuildMemberList()
            
                    for member, data in pairs(stats) do
                        if guildMembers[member] then
                            local timesSelected = data.timesSelected or 0
                            local lastSelectedTime = data.lastSelectedTime
                            local lastSelected
                            if lastSelectedTime then
                                lastSelected = date("%Y-%m-%d %H:%M:%S", lastSelectedTime)
                            else
                                lastSelected = "Never"
                            end
                            desc = desc .. string.format("%s: Selected %d times, Last selected: %s\n", member, timesSelected, lastSelected)
                        end
                    end
                    return desc
                end,
                fontSize = "medium",
                order = 2,
            },
        },
    }
end

function ns.statistics:UpdateMemberStats(memberName)
    local guildMembers = ns.statistics:GetGuildMemberList()
    if not guildMembers[memberName] then
        print(memberName .. " is not a member of your guild. Skipping stat update.")
        return
    end

    if not LootCouncilRandomizer.db.profile.statistics[memberName] then
        LootCouncilRandomizer.db.profile.statistics[memberName] = { timesSelected = 0, lastSelected = "Never" }
    end

    LootCouncilRandomizer.db.profile.statistics[memberName].timesSelected = 
        (LootCouncilRandomizer.db.profile.statistics[memberName].timesSelected or 0) + 1

    LootCouncilRandomizer.db.profile.statistics[memberName].lastSelected = date("%Y-%m-%d %H:%M:%S")
end

function ns.statistics:GetGuildMemberList()
    local guildMembers = {}
    if IsInGuild() then
        for i = 1, GetNumGuildMembers() do
            local name = GetGuildRosterInfo(i)
            if name then
                local shortName = Ambiguate(name, "short")
                guildMembers[shortName] = true
            end
        end
    end
    return guildMembers
end
