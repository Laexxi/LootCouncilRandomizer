local ADDON_NAME, ns = ...
ns.guild = {}

function ns.guild:GetGuildRanks()
    local ranks = {}
    if IsInGuild() then
        for i = 1, GuildControlGetNumRanks() do
            local rankName = GuildControlGetRankName(i - 1)
            if rankName and rankName ~= "" then
                ranks[i] = rankName -- Store ranks starting from index 1
            end
        end
    end
    return ranks
end

function ns.guild:GetGuildMembersBySelectedRanks()
    local membersByRank = {}
    if IsInGuild() then
        for i = 1, GetNumGuildMembers() do
            local name, rank, rankIndex = GetGuildRosterInfo(i)
            if name and rank and rankIndex then
                name = name:match("([^%-]+)") -- Remove server name from player name
                rankIndex = rankIndex + 1 -- Adjust rankIndex for the shift to start from 1

                if LootCouncilRandomizer.db.char.selectedRanks[rankIndex] then
                    membersByRank[rank] = membersByRank[rank] or {}
                    table.insert(membersByRank[rank], {name = name, rankIndex = rankIndex})
                end
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
    local membersByRank = ns.guild:GetGuildMembersBySelectedRanks()
    local args = {
        updateButton = {
            type = "execute",
            name = "Update",
            func = function()
                ns.guild:UpdateGuildRoster()
            end,
            order = 0,
        }
    }
    local orderCounter = 1
    local sortedRanks = {}

    for rank, members in pairs(membersByRank) do
        table.insert(sortedRanks, {rank = rank, rankIndex = members[1].rankIndex})
    end

    table.sort(sortedRanks, function(a, b) return a.rankIndex < b.rankIndex end)

    for _, rankInfo in ipairs(sortedRanks) do
        local rank = rankInfo.rank
        args["header_" .. rank] = {
            type = "header",
            name = rank,
            order = orderCounter,
        }
        orderCounter = orderCounter + 1

        args["group_" .. rank] = {
            type = "select",
            name = "Set group for " .. rank,
            desc = "Assign a group to the entire rank of " .. rank,
            values = function()
                local groups = {}
                for i = 1, (LootCouncilRandomizer.db.char.councilPots or 1) do
                    groups[i] = LootCouncilRandomizer.db.char["groupName" .. i] or "Group " .. i
                end
                groups[0] = "None" -- Option to remove group
                return groups
            end,
            get = function(info)
                return LootCouncilRandomizer.db.char["rankGroup_" .. rank] or 0
            end,
            set = function(info, value)
                if value == 0 then
                    LootCouncilRandomizer.db.char["rankGroup_" .. rank] = nil
                else
                    LootCouncilRandomizer.db.char["rankGroup_" .. rank] = value
                end
                ns.guild:UpdateGuildRoster() -- Update the roster when the group is changed
            end,
            order = orderCounter,
            width = "full", -- Make it take the full width
        }
        orderCounter = orderCounter + 1

        for i, member in ipairs(membersByRank[rank]) do
            args[member.name] = {
                type = "select",
                name = member.name,
                desc = "Assign a group to " .. member.name,
                values = function()
                    local groups = {}
                    for i = 1, (LootCouncilRandomizer.db.char.councilPots or 1) do
                        groups[i] = LootCouncilRandomizer.db.char["groupName" .. i] or "Group " .. i
                    end
                    groups[0] = "None" -- Option to remove group
                    return groups
                end,
                get = function(info)
                    return LootCouncilRandomizer.db.char["memberGroup_" .. member.name] or 0
                end,
                set = function(info, value)
                    if value == 0 then
                        LootCouncilRandomizer.db.char["memberGroup_" .. member.name] = nil
                    else
                        LootCouncilRandomizer.db.char["memberGroup_" .. member.name] = value
                    end
                end,
                order = orderCounter,
            }
            orderCounter = orderCounter + 1
        end
    end

    return args
end

function ns.guild:UpdateGuildRoster()
    local rosterArgs = ns.guild:UpdateGuildRosterOptions()
    if LootCouncilRandomizer.options then
        LootCouncilRandomizer.options.args.guildroster.args = rosterArgs
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    end
end
