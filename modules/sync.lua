-- sync.lua
local ADDON_NAME, ns = ...
ns.sync = {}

local SYNC_PREFIX = "LCR_Sync"

-- Register the addon message prefix
C_ChatInfo.RegisterAddonMessagePrefix(SYNC_PREFIX)

-- Function to initiate settings sync
function ns.sync:InitiateSettingsSync()
    local targetPlayer = LootCouncilRandomizer.db.profile.settings.syncSettingsPlayerName
    if not targetPlayer or targetPlayer == "" then
        print("Please specify a player name to sync settings with.")
        return
    end

    -- Prepare the settings data to sync
    local settingsData = LootCouncilRandomizer.db.profile.settings
    local dataToSend = {
        councilSize = settingsData.councilSize,
        councilPots = settingsData.councilPots,
        reselectDuration = settingsData.reselectDuration,
        selectCuratedMode = settingsData.selectCuratedMode,
        selectStatisticsMode = settingsData.selectStatisticsMode,
        -- Include group settings
        groupSettings = {},
    }

    for i = 1, settingsData.councilPots or 1 do
        dataToSend.groupSettings[i] = {
            groupName = settingsData["groupName" .. i],
            groupSelection = settingsData["groupSelection" .. i],
            groupReselectDuration = settingsData["groupReselectDuration" .. i],
            groupRanks = settingsData["groupRanks" .. i],
        }
    end

    local serializedSettings = ns.sync:SerializeData(dataToSend)

    -- Send sync request to the target player
    ns.sync:SendSyncRequest("Settings", serializedSettings, "WHISPER", targetPlayer)
end

-- Function to initiate statistics sync
function ns.sync:InitiateStatisticsSync()
    local syncTo = LootCouncilRandomizer.db.profile.settings.syncTo or "guild"
    local distribution, targetPlayer

    if syncTo == "guild" then
        distribution = "GUILD"
    elseif syncTo == "raid" then
        distribution = "RAID"
    elseif syncTo == "player" then
        distribution = "WHISPER"
        targetPlayer = LootCouncilRandomizer.db.profile.settings.syncToPlayerName
        if not targetPlayer or targetPlayer == "" then
            print("Please specify a player name to sync statistics with.")
            return
        end
    else
        print("Invalid sync target selected.")
        return
    end

    -- Serialize the statistics data
    local serializedStatistics = ns.sync:SerializeData(LootCouncilRandomizer.db.profile.statistics)

    -- Send sync request
    ns.sync:SendSyncRequest("Statistics", serializedStatistics, distribution, targetPlayer)
end

-- Function to send sync request
function ns.sync:SendSyncRequest(dataType, data, distribution, targetPlayer)
    local message = {
        type = "SyncRequest",
        dataType = dataType,
        data = data,
    }
    local serializedMessage = ns.sync:SerializeData(message)

    if distribution == "WHISPER" then
        C_ChatInfo.SendAddonMessage(SYNC_PREFIX, serializedMessage, distribution, targetPlayer)
        print("Sent sync request to " .. targetPlayer)
    else
        C_ChatInfo.SendAddonMessage(SYNC_PREFIX, serializedMessage, distribution)
        print("Sent sync request to " .. distribution)
    end
end

-- Function to handle incoming addon messages
function ns.sync:OnAddonMessage(prefix, message, distribution, sender)
    if prefix ~= SYNC_PREFIX then return end
    if sender == UnitName("player") then return end -- Ignore own messages

    local success, receivedMessage = ns.sync:DeserializeData(message)
    if not success then
        print("Failed to deserialize sync message from " .. sender)
        return
    end

    if receivedMessage.type == "SyncRequest" then
        ns.sync:HandleSyncRequest(sender, receivedMessage)
    elseif receivedMessage.type == "SyncResponse" then
        ns.sync:HandleSyncResponse(sender, receivedMessage)
    end
end

-- Function to handle sync requests
function ns.sync:HandleSyncRequest(sender, message)
    local dataType = message.dataType
    local data = message.data

    -- Show confirmation popup
    if dataType == "Settings" then
        ns.sync:ShowSyncConfirmationPopup(sender, dataType, data)
    elseif dataType == "Statistics" then
        -- Check if auto-accept is enabled
        if LootCouncilRandomizer.db.profile.settings.syncWhenRolling then
            ns.sync:AcceptSync(sender, dataType, data)
        else
            ns.sync:ShowSyncConfirmationPopup(sender, dataType, data)
        end
    end
end

-- Function to show confirmation popup with progress bar
function ns.sync:ShowSyncConfirmationPopup(sender, dataType, data)
    StaticPopupDialogs["LCR_SYNC_CONFIRMATION"] = {
        text = sender .. " wants to sync " .. dataType .. ". Do you accept?",
        button1 = "Accept",
        button2 = "Decline",
        OnAccept = function(self)
            ns.sync:AcceptSync(sender, dataType, data)
        end,
        OnCancel = function(_, reason)
            print("Sync declined.")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("LCR_SYNC_CONFIRMATION")
end

-- Function to accept sync
function ns.sync:AcceptSync(sender, dataType, data)
    -- Deserialize the data
    local success, deserializedData = ns.sync:DeserializeData(data)
    if not success then
        print("Failed to deserialize " .. dataType .. " data from " .. sender)
        return
    end

    if dataType == "Settings" then
        -- Update settings
        local settingsData = deserializedData
        -- Update each setting individually
        for key, value in pairs(settingsData) do
            if key == "groupSettings" then
                for i, groupData in pairs(value) do
                    LootCouncilRandomizer.db.profile.settings["groupName" .. i] = groupData.groupName
                    LootCouncilRandomizer.db.profile.settings["groupSelection" .. i] = groupData.groupSelection
                    LootCouncilRandomizer.db.profile.settings["groupReselectDuration" .. i] = groupData.groupReselectDuration
                    LootCouncilRandomizer.db.profile.settings["groupRanks" .. i] = groupData.groupRanks
                end
            else
                LootCouncilRandomizer.db.profile.settings[key] = value
            end
        end
        print("Settings synced with " .. sender)
        -- Refresh the configuration UI
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    elseif dataType == "Statistics" then
        -- Update statistics
        LootCouncilRandomizer.db.profile.statistics = deserializedData
        print("Statistics synced with " .. sender)
    end

    -- Send sync response back to sender
    local responseMessage = {
        type = "SyncResponse",
        dataType = dataType,
        status = "Accepted",
    }
    local serializedResponse = ns.sync:SerializeData(responseMessage)
    C_ChatInfo.SendAddonMessage(SYNC_PREFIX, serializedResponse, "WHISPER", sender)
end

-- Function to handle sync responses
function ns.sync:HandleSyncResponse(sender, message)
    if message.status == "Accepted" then
        print(sender .. " accepted the sync.")
    else
        print(sender .. " declined the sync.")
    end
end

-- Serialization function
function ns.sync:SerializeData(data)
    local serialized = LibStub("AceSerializer-3.0"):Serialize(data)
    return serialized
end

-- Deserialization function
function ns.sync:DeserializeData(data)
    local success, deserialized = LibStub("AceSerializer-3.0"):Deserialize(data)
    return success, deserialized
end

-- Register the event handler for addon messages
function ns.sync:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    eventFrame:SetScript("OnEvent", function(_, event, prefix, message, channel, sender)
        ns.sync:OnAddonMessage(prefix, message, channel, sender)
    end)
end

-- Initialize the sync module
ns.sync:RegisterEvents()
