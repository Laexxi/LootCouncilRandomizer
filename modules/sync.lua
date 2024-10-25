local ADDON_NAME, ns = ...
ns.sync = {}

local SYNC_PREFIX = "LCR_Sync"

local AceSerializer = LibStub("AceSerializer-3.0")
local LibCompress = LibStub:GetLibrary("LibCompress")
local LibCompressEncoder = LibCompress:GetAddonEncodeTable()

-- Nachrichtentypen
local MESSAGE_TYPES = {
    SYNC_REQUEST = "SyncRequest",
    SYNC_ACK = "SyncAck",
    SYNC_NACK = "SyncNack",
    SYNC_DATA = "SyncData",
    SYNC_COMPLETE = "SyncComplete",
}

function ns.sync:OnInitialize()
    self:RegisterEvents()
end

function ns.sync:GetOptions()
    local options = {
        name = "Synchronization",
        type = "group",
        childGroups = "tab",
        args = {
            syncSettings = {
                type = "group",
                name = "Sync Settings",
                order = 1,
                args = {
                    syncToDescription = {
                        type = "description",
                        name = "Sync to:",
                        fontSize = "medium",
                        order = 1,
                    },
                    syncToPlayerName = {
                        type = "input",
                        name = "Player Name",
                        desc = "Enter the name of the player to sync with.",
                        get = function(info)
                            return LootCouncilRandomizer.db.profile.settings.syncSettingsPlayerName or ""
                        end,
                        set = function(info, value)
                            LootCouncilRandomizer.db.profile.settings.syncSettingsPlayerName = value
                        end,
                        order = 2,
                        width = "normal",
                    },
                    targetPlayerButton = {
                        type = "execute",
                        name = "Use Target",
                        desc = "Use the current target's name.",
                        func = function()
                            local targetName = UnitName("target")
                            if targetName then
                                LootCouncilRandomizer.db.profile.settings.syncSettingsPlayerName = targetName
                                LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
                            else
                                print("No target selected.")
                            end
                        end,
                        order = 3,
                        width = "normal",
                    },
                    syncSettingsSpacer = {
                        type = "description",
                        name = " ",
                        fontSize = "medium",
                        order = 4,
                        width = "full",
                    },
                    syncSettingsButton = {
                        type = "execute",
                        name = "Sync Settings",
                        desc = "Synchronize settings now.",
                        func = function()
                            self:InitiateSettingsSync()
                        end,
                        order = 5,
                        width = "normal",
                    },
                },
            },
            syncStatistics = {
                type = "group",
                name = "Sync Statistics",
                order = 2,
                args = {
                    syncToDescription = {
                        type = "description",
                        name = "Sync to:",
                        fontSize = "medium",
                        order = 1,
                    },
                    syncTo = {
                        type = "select",
                        name = "",
                        desc = "Select where to sync the data.",
                        values = {
                            guild = "Guild",
                            raid = "Raid",
                            player = "Player",
                        },
                        get = function(info)
                            return LootCouncilRandomizer.db.profile.settings.syncTo or "guild"
                        end,
                        set = function(info, value)
                            LootCouncilRandomizer.db.profile.settings.syncTo = value
                            if LootCouncilRandomizer.options then
                                LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
                            end
                        end,
                        order = 2,
                        width = "half",
                    },
                    syncToPlayerName = {
                        type = "input",
                        name = "Player Name",
                        desc = "Enter the name of the player to sync with.",
                        hidden = function()
                            return LootCouncilRandomizer.db.profile.settings.syncTo ~= "player"
                        end,
                        get = function(info)
                            return LootCouncilRandomizer.db.profile.settings.syncToPlayerName or ""
                        end,
                        set = function(info, value)
                            LootCouncilRandomizer.db.profile.settings.syncToPlayerName = value
                        end,
                        order = 3,
                        width = "normal",
                    },
                    targetPlayerButton = {
                        type = "execute",
                        name = "Use Target",
                        desc = "Use the current target's name.",
                        hidden = function()
                            return LootCouncilRandomizer.db.profile.settings.syncTo ~= "player"
                        end,
                        func = function()
                            local targetName = UnitName("target")
                            if targetName then
                                LootCouncilRandomizer.db.profile.settings.syncToPlayerName = targetName
                                LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
                            else
                                print("No target selected.")
                            end
                        end,
                        order = 4,
                        width = "normal",
                    },
                    syncWhenRolling = {
                        type = "toggle",
                        name = "Sync when rolling council",
                        desc = "Automatically sync statistics when rolling the council.",
                        get = function(info)
                            return LootCouncilRandomizer.db.profile.settings.syncWhenRolling or false
                        end,
                        set = function(info, value)
                            LootCouncilRandomizer.db.profile.settings.syncWhenRolling = value
                        end,
                        order = 5,
                        width = "full",
                    },
                    syncStatisticsButton = {
                        type = "execute",
                        name = "Sync Statistics",
                        desc = "Synchronize statistics now.",
                        func = function()
                            self:InitiateStatisticsSync()
                        end,
                        order = 6,
                        width = "normal",
                    },
                },
            },
        },
    }

    return options
end

function ns.sync:InitiateStatisticsSync()
    local syncTo = LootCouncilRandomizer.db.profile.settings.syncTo
    local targetPlayer

    if syncTo == "player" then
        targetPlayer = LootCouncilRandomizer.db.profile.settings.syncToPlayerName
        if not targetPlayer or targetPlayer == "" then
            print("Please specify a player name to sync statistics with.")
            return
        end
    elseif syncTo == "guild" then
        -- Für Gilde synchronisieren
        targetPlayer = nil
    elseif syncTo == "raid" then
        -- Für Raid synchronisieren
        targetPlayer = nil
    else
        print("Invalid sync target.")
        return
    end

    -- Bereite die zu synchronisierenden Statistiken vor
    local dataToSend = LootCouncilRandomizer.db.profile.statistics

    -- Speichere die Daten in einer Tabelle, um später darauf zugreifen zu können
    self.pendingSyncs = self.pendingSyncs or {}
    local syncKey = targetPlayer or syncTo
    self.pendingSyncs[syncKey] = {
        dataType = "Statistics",
        data = dataToSend,
    }

    -- Sende SyncRequest
    local message = {
        type = MESSAGE_TYPES.SYNC_REQUEST,
        dataType = "Statistics",
    }
    local serializedMessage = self:SerializeData(message)

    if targetPlayer then
        self:SendCommMessage(SYNC_PREFIX, serializedMessage, "WHISPER", targetPlayer)
        ns.guild:DebugPrint("Sent SyncRequest to " .. targetPlayer)
    elseif syncTo == "guild" then
        self:SendCommMessage(SYNC_PREFIX, serializedMessage, "GUILD")
        ns.guild:DebugPrint("Sent SyncRequest to GUILD")
    elseif syncTo == "raid" then
        self:SendCommMessage(SYNC_PREFIX, serializedMessage, "RAID")
        ns.guild:DebugPrint("Sent SyncRequest to RAID")
    end
end


function ns.sync:InitiateSettingsSync()
    local targetPlayer = LootCouncilRandomizer.db.profile.settings.syncSettingsPlayerName
    if not targetPlayer or targetPlayer == "" then
        print("Please specify a player name to sync settings with.")
        return
    end

    -- Bereite die zu synchronisierenden Einstellungen vor
    local dataToSend = LootCouncilRandomizer.db.profile.settings

    -- Speichere die Daten in einer Tabelle, um später darauf zugreifen zu können
    self.pendingSyncs = self.pendingSyncs or {}
    self.pendingSyncs[targetPlayer] = {
        dataType = "Settings",
        data = dataToSend,
    }

    -- Sende SyncRequest
    local message = {
        type = MESSAGE_TYPES.SYNC_REQUEST,
        dataType = "Settings",
    }
    local serializedMessage = self:SerializeData(message)
    self:SendCommMessage(SYNC_PREFIX, serializedMessage, "WHISPER", targetPlayer)
    ns.guild:DebugPrint("Sent SyncRequest to " .. targetPlayer)
end


function ns.sync:OnCommReceived(prefix, message, distribution, sender)
    ns.guild:DebugPrint("Received message from " .. sender .. " via " .. distribution)
    local success, receivedMessage = self:DeserializeData(message)
    if not success then
        ns.guild:DebugPrint("Failed to deserialize message from " .. sender)
        return
    end

    if receivedMessage.type == MESSAGE_TYPES.SYNC_REQUEST then
        self:HandleSyncRequest(sender, receivedMessage)
    elseif receivedMessage.type == MESSAGE_TYPES.SYNC_ACK then
        self:HandleSyncAck(sender, receivedMessage)
    elseif receivedMessage.type == MESSAGE_TYPES.SYNC_NACK then
        self:HandleSyncNack(sender, receivedMessage)
    elseif receivedMessage.type == MESSAGE_TYPES.SYNC_DATA then
        self:HandleSyncData(sender, receivedMessage)
    elseif receivedMessage.type == MESSAGE_TYPES.SYNC_COMPLETE then
        self:HandleSyncComplete(sender, receivedMessage)
    else
        ns.guild:DebugPrint("Unknown message type from " .. sender)
    end
end


function ns.sync:HandleSyncRequest(sender, message)
    local dataType = message.dataType
    ns.guild:DebugPrint("Received SyncRequest from " .. sender .. " for " .. dataType)

    -- Prüfe, ob wir den Datentyp unterstützen
    if dataType ~= "Settings" and dataType ~= "Statistics" then
        -- Sende SyncNack
        local nackMessage = {
            type = MESSAGE_TYPES.SYNC_NACK,
            dataType = dataType,
            reason = "Unsupported data type",
        }
        local serializedNack = self:SerializeData(nackMessage)
        AceComm:SendCommMessage(SYNC_PREFIX, serializedNack, "WHISPER", sender)
        return
    end

    -- Zeige Bestätigungspopup
    self:ShowSyncConfirmationPopup(sender, dataType)
end

function ns.sync:OnSyncAccept(sender, dataType)
    ns.guild:DebugPrint("Accepted sync request from " .. sender .. " for " .. dataType)

    -- Sende SyncAck
    local ackMessage = {
        type = MESSAGE_TYPES.SYNC_ACK,
        dataType = dataType,
    }
    local serializedAck = self:SerializeData(ackMessage)
    AceComm:SendCommMessage(SYNC_PREFIX, serializedAck, "WHISPER", sender)
end

function ns.sync:OnSyncDecline(sender, dataType)
    ns.guild:DebugPrint("Declined sync request from " .. sender .. " for " .. dataType)

    -- Sende SyncNack
    local nackMessage = {
        type = MESSAGE_TYPES.SYNC_NACK,
        dataType = dataType,
        reason = "User declined",
    }
    local serializedNack = self:SerializeData(nackMessage)
    AceComm:SendCommMessage(SYNC_PREFIX, serializedNack, "WHISPER", sender)
end

function ns.sync:HandleSyncAck(sender, message)
    local dataType = message.dataType
    ns.guild:DebugPrint("Received SyncAck from " .. sender .. " for " .. dataType)

    if not self.pendingSyncs then
        ns.guild:DebugPrint("No pending syncs exist.")
        return
    end

    -- Hole die zu sendenden Daten
    local syncInfo = self.pendingSyncs and self.pendingSyncs[sender]
    if not syncInfo or syncInfo.dataType ~= dataType then
        ns.guild:DebugPrint("No pending sync data for " .. sender)
        return
    end

    -- Sende SyncData
    local dataMessage = {
        type = MESSAGE_TYPES.SYNC_DATA,
        dataType = dataType,
        data = syncInfo.data,
    }
    local serializedData = self:SerializeData(dataMessage)
    AceComm:SendCommMessage(SYNC_PREFIX, serializedData, "WHISPER", sender)
    ns.guild:DebugPrint("Sent SyncData to " .. sender)
end

function ns.sync:HandleSyncData(sender, message)
    local dataType = message.dataType
    local data = message.data
    ns.guild:DebugPrint("Received SyncData from " .. sender .. " for " .. dataType)

    -- Verarbeite die empfangenen Daten
    if dataType == "Settings" then
        -- Überschreibe die aktuellen Einstellungen mit den empfangenen
        LootCouncilRandomizer.db.profile.settings = data
        ns.guild:DebugPrint("Settings updated from sync with " .. sender)
        -- Aktualisiere ggf. die Optionsoberfläche
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    
    elseif dataType == "Statistics" then
        -- Aktualisiere die Statistiken
        LootCouncilRandomizer.db.profile.statistics = data
        ns.guild:DebugPrint("Statistics updated from sync with " .. sender)
    end
    

    -- Sende SyncComplete
    local completeMessage = {
        type = MESSAGE_TYPES.SYNC_COMPLETE,
        dataType = dataType,
    }
    local serializedComplete = self:SerializeData(completeMessage)
    AceComm:SendCommMessage(SYNC_PREFIX, serializedComplete, "WHISPER", sender)
    ns.guild:DebugPrint("Sent SyncComplete to " .. sender)
end

function ns.sync:HandleSyncComplete(sender, message)
    local dataType = message.dataType
    ns.guild:DebugPrint("Received SyncComplete from " .. sender .. " for " .. dataType)

    -- Entferne die pendingSync
    if self.pendingSyncs then
        self.pendingSyncs[sender] = nil
    end

    ns.guild:AddToLog("Synchronization with " .. sender .. " completed.")
end

function ns.sync:SerializeData(data)
    local serialized = AceSerializer:Serialize(data)
    local compressed = LibCompress:Compress(serialized)
    local encoded = LibCompressEncoder:Encode(compressed)
    return encoded
end

function ns.sync:DeserializeData(data)
    local decoded = LibCompressEncoder:Decode(data)
    if not decoded then return false, "Decoding failed" end
    local decompressed, decompressedMessage = LibCompress:Decompress(decoded)
    if not decompressed then return false, "Decompression failed: " .. decompressedMessage end
    local success, deserialized = AceSerializer:Deserialize(decompressed)
    if not success then return false, "Deserialization failed" end
    return true, deserialized
end

function ns.sync:RegisterEvents()
    self:RegisterComm(SYNC_PREFIX, "OnCommReceived")
end

function ns.sync:ShowSyncConfirmationPopup(sender, dataType)
    StaticPopupDialogs["LCR_SYNC_CONFIRMATION"] = {
        text = sender .. " wants to sync " .. dataType .. " with you. Do you accept?",
        button1 = "Accept",
        button2 = "Decline",
        OnAccept = function()
            self:OnSyncAccept(sender, dataType)
        end,
        OnCancel = function()
            self:OnSyncDecline(sender, dataType)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show("LCR_SYNC_CONFIRMATION")
end