local ADDON_NAME, ns = ...
ns.guild = {}

function ns.guild:GetGuildRanks()
    local ranks = {}
    if IsInGuild() then
        for i = 1, GuildControlGetNumRanks() do
            ranks[i] = GuildControlGetRankName(i - 1) -- Adjusting index to match in-game rank index
        end
    end
    return ranks
end

function ns.guild:GetGuildMembersByMinRank()
    local membersByRank = {}
    if IsInGuild() then
        local minRankIndex = (LootCouncilRandomizer.db.profile.selectedRankIndex or 1) - 1 -- Adjust for zero-based index from WoW API
        for i = 1, GetNumGuildMembers() do
            local name, rank, rankIndex = GetGuildRosterInfo(i)
            name = name:match("([^%-]+)") -- Remove server name from player name
            if rankIndex and rankIndex <= minRankIndex then
                membersByRank[rank] = membersByRank[rank] or {}
                table.insert(membersByRank[rank], name)
            end
        end
    end
    return membersByRank
end

function ns.guild:GetOptions()
    return {
        name = "Guild Overview",
        type = "group",
        args = ns.guild:UpdateGuildRosterOptions()
    }
end

function ns.guild:UpdateGuildRosterOptions()
    local membersByRank = ns.guild:GetGuildMembersByMinRank()
    local args = {}
    for rank, members in pairs(membersByRank) do
        args[rank] = {
            type = "group",
            name = rank,
            args = {}
        }
        for i, name in ipairs(members) do
            args[rank].args[name] = {
                type = "description",
                name = name,
                desc = "Member of " .. rank,
            }
        end
    end
    return args
end

function ns.guild:UpdateGuildRoster()
    local rosterArgs = ns.guild:UpdateGuildRosterOptions()
    LootCouncilRandomizer.options.args.guildroster.args = rosterArgs
    LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
end
