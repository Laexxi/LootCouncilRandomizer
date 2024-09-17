local ADDON_NAME, ns = ...
ns.guild = {}

function ns.guild:GetGuildRanks()
    local ranks = {}
    if IsInGuild() then
        for i = 1, GuildControlGetNumRanks() do
            local rankName = GuildControlGetRankName(i)
            if rankName and rankName ~= "" then
                ranks[i] = rankName
            end
        end
    end
    return ranks
end

function ns.guild:GetMembersByRank(rankIndex)
    local members = {}
    if IsInGuild() then
        for i = 1, GetNumGuildMembers() do
            local name, _, rankIndexMember = GetGuildRosterInfo(i)
            if rankIndexMember == rankIndex - 1 then
                local shortName = Ambiguate(name, "short")
                table.insert(members, shortName)
            end
        end
        table.sort(members)
    end
    return members
end

function ns.guild:GetOptions()
    local options = {
        name = "Guild Overview",
        type = "group",
        args = {},
    }

    local selectedRanks = LootCouncilRandomizer.db.profile.settings.selectedRanks or {}
    local guildRanks = ns.guild:GetGuildRanks()

    for rankIndex, isSelected in pairs(selectedRanks) do
        if isSelected and guildRanks[rankIndex] then
            local rankName = guildRanks[rankIndex]
            options.args["rank" .. rankIndex] = {
                type = "group",
                name = rankName,
                inline = false,
                args = {},
            }

            local members = ns.guild:GetMembersByRank(rankIndex)
            if #members > 0 then
                for i, memberName in ipairs(members) do
                    options.args["rank" .. rankIndex].args["member" .. i] = {
                        type = "description",
                        name = memberName,
                        order = i,
                    }
                end
            else
                options.args["rank" .. rankIndex].args["noMembers"] = {
                    type = "description",
                    name = "No members in this rank.",
                    order = 1,
                }
            end
        end
    end

    return options
end

function ns.guild:ShowGroupMembers()
    local groupCount = LootCouncilRandomizer.db.profile.settings.councilPots or 1

    for i = 1, groupCount do
        local members = ns.guild:GetMembersByGroup(i)
        if #members > 0 then
            print("Group " .. i .. " members:", table.concat(members, ", "))
        else
            print("Group " .. i .. " has no members.")
        end
    end
end

function ns.guild:GetMembersByGroup(groupIndex)
    local groupRanks = LootCouncilRandomizer.db.profile.settings["groupRanks" .. groupIndex]
    local members = {}
    local raidMembers = ns.guild:GetRaidMembers()

    if IsInGuild() and IsInRaid() then
        for i = 1, GetNumGuildMembers() do
            local name, _, rankIndexMember = GetGuildRosterInfo(i)
            rankIndexMember = rankIndexMember + 1

            local shortName = Ambiguate(name, "short")
            if groupRanks and groupRanks[rankIndexMember] and raidMembers[shortName] then
                table.insert(members, shortName)
            end
        end
    end

    return members
end

function ns.guild:GetRaidMembers()
    local raidMembers = {}
    local numRaidMembers = GetNumGroupMembers()

    if numRaidMembers > 0 and IsInRaid() then
        for i = 1, numRaidMembers do
            local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
            if name and online then 
                name = Ambiguate(name, "short")
                raidMembers[name] = true
            end
        end
    end
    return raidMembers
end

function ns.guild:GetRaidMembersWithRanks()
    local raidMembers = {}
    local numRaidMembers = GetNumGroupMembers()

    if numRaidMembers > 0 and IsInRaid() then
        for i = 1, numRaidMembers do
            local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
            if name and online then 
                name = Ambiguate(name, "short")
                local guildIndex = ns.guild:GetGuildMemberIndexByName(name)
                if guildIndex then
                    local _, _, rankIndex = GetGuildRosterInfo(guildIndex)
                    rankIndex = rankIndex + 1
                    raidMembers[name] = rankIndex
                end
            end
        end
    end

    return raidMembers
end

function ns.guild:GetGuildMemberIndexByName(name)
    if IsInGuild() then
        for i = 1, GetNumGuildMembers() do
            local guildName = GetGuildRosterInfo(i)
            guildName = Ambiguate(guildName, "short")
            if guildName == name then
                return i
            end
        end
    end
    return nil
end
