--[[
guild.lua
Handles guild-related data and options for the LootCouncilRandomizer addon.
Provides functions to retrieve guild ranks and members, and updates the guild roster.

Functions:
- NormalizeRankIndex: Normalizes guild rank indices to handle the Guildmaster rank.
- GetGuildRanks: Retrieves the guild ranks and normalizes their indices.
- GetGuildMembersByMinRank: Retrieves guild members based on the minimum rank allowed to participate.
- GetOptions: Returns the configuration options for the guild roster.
- UpdateGuildRosterOptions: Updates the guild roster options with current guild members and their assigned groups.
- UpdateGuildRoster: Updates the guild roster data when called.
]]
local ADDON_NAME, ns = ...
ns.guild = {}

-- Function to normalize rank indices; Different WoW APIs return different indices. Eg. Guildmaster could be 0 or 1. Maybe not needed anymore but its working ;)
function ns.guild:NormalizeRankIndex(rankIndex)
    -- Return 0 for the Guildmaster rank
    if rankIndex == 0 then
        return 0
    -- Return 1 for the next rank
    elseif rankIndex == 1 then
        return 1
    else
        return rankIndex
    end
end

-- Function to retrieve all the guild ranks
function ns.guild:GetGuildRanks()
    local ranks = {}
    if IsInGuild() then
        -- Iterate over the guild ranks
        for i = 1, GuildControlGetNumRanks() do
            -- Normalize the rank index
            local normalizedIndex = self:NormalizeRankIndex(i - 1)
            -- Add the rank to the list
            ranks[normalizedIndex] = GuildControlGetRankName(i - 1)
        end
    end
    return ranks
end

-- Function to retrieve guild members by minimum rank
function ns.guild:GetGuildMembersByMinRank()
    local membersByRank = {}
    -- Check if the player is in a guild
    if IsInGuild() then
        -- Get the minimum rank index
        local minRankIndex = LootCouncilRandomizer.db.char.selectedRankIndex or 1
        minRankIndex = minRankIndex - 1 -- Adjust for zero-based index from WoW API
        for i = 1, GetNumGuildMembers() do
            local name, rank, rankIndex = GetGuildRosterInfo(i)
            name = name:match("([^%-]+)") -- Remove server name from player name
            -- add the player to the list if the rank index is greater than or equal to the minimum rank index
            if rankIndex <= minRankIndex then
                membersByRank[rank] = membersByRank[rank] or {}
                table.insert(membersByRank[rank], {name = name, rankIndex = rankIndex})
            end
        end
    end
    return membersByRank
end

-- Function to update the options for the guild roster
function ns.guild:GetOptions()
    return {
        name = "Guild Overview",
        type = "group",
        args = ns.guild:UpdateGuildRosterOptions()
    }
end

-- Function to update the options for the guild roster
function ns.guild:UpdateGuildRosterOptions()
    local membersByRank = ns.guild:GetGuildMembersByMinRank()
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

    -- Sort the ranks by their rank index
    for rank, members in pairs(membersByRank) do
        table.insert(sortedRanks, {rank = rank, rankIndex = members[1].rankIndex})
    end

    table.sort(sortedRanks, function(a, b) return a.rankIndex < b.rankIndex end)

    -- create options for each rank and member
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

-- Function to update the guild roster
function ns.guild:UpdateGuildRoster()
    local rosterArgs = ns.guild:UpdateGuildRosterOptions()
    if LootCouncilRandomizer.options then
        LootCouncilRandomizer.options.args.guildroster.args = rosterArgs
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    end
end
