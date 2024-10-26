local ADDON_NAME, ns = ...
ns.utility = ns.utility or {}
local utility = ns.utility
local debug = ns.debug

function utility:UpdateOfficerNote(member)
    if not IsInGuild() then
        debug:DebugPrint("Timestamp", "Not in guild, cannot update officer note for " .. member)
        return
    end

    if not C_GuildInfo.CanEditOfficerNote() then
        debug:DebugPrint("Timestamp", "No permission to edit officer notes for " .. member)
        return
    end

    local guildMemberIndex = debug:GetGuildMemberIndexByName(member)
    if not guildMemberIndex then
        debug:DebugPrint("Timestamp", "Member " .. member .. " not found in guild roster")
        return
    end

    local timestamp = time()
    -- TODO: Für Manu -> Timestamp in [] nur Inhalt von Klammern ersetzen ansonsten ans Ende setzen
    GuildRosterSetOfficerNote(guildMemberIndex, tostring(timestamp))
    debug:DebugPrint("Timestamp", "Updated officer note for " .. member .. " with timestamp " .. tostring(timestamp))
end

function utility:GetTimestampFromOfficerNote(member)
    if not IsInGuild() then
        debug:DebugPrint("Timestamp", "Not in guild, cannot read officer note for " .. member)
        return 0
    end

    local guildMemberIndex = debug:GetGuildMemberIndexByName(member)
    if not guildMemberIndex then
        debug:DebugPrint("Timestamp", "Member " .. member .. " not found in guild roster")
        return 0
    end

    local officerNote = select(8, GetGuildRosterInfo(guildMemberIndex))
    if officerNote then
        local timestamp = tonumber(officerNote)
        if timestamp then
            return timestamp
        else
            debug:DebugPrint("Timestamp", "Officer note for " .. member .. " does not contain a valid timestamp")
            return 0
        end
    else
        debug:DebugPrint("Timestamp", "No officer note for " .. member)
        return 0
    end
end

return utility
