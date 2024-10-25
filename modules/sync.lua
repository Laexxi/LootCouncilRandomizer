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
                            ns.sync:InitiateSettingsSync()
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
                            ns.sync:InitiateStatisticsSync()
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

function ns.sync:InitiateSettingsSync()
    -- ... (Überprüfungen)

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
    local serializedMessage = ns.sync:SerializeData(message)
    AceComm:SendCommMessage(SYNC_PREFIX, serializedMessage, "WHISPER", targetPlayer)
    ns.guild:DebugPrint("Sent SyncRequest to " .. targetPlayer)
end

function ns.sync:OnCommReceived(prefix, message, distribution, sender)
    -- ... (Deserialisierung)

    if receivedMessage.type == MESSAGE_TYPES.SYNC_REQUEST then
        ns.sync:HandleSyncRequest(sender, receivedMessage)
    elseif receivedMessage.type == MESSAGE_TYPES.SYNC_ACK then
        ns.sync:HandleSyncAck(sender, receivedMessage)
    elseif receivedMessage.type == MESSAGE_TYPES.SYNC_NACK then
        ns.sync:HandleSyncNack(sender, receivedMessage)
    elseif receivedMessage.type == MESSAGE_TYPES.SYNC_DATA then
        ns.sync:HandleSyncData(sender, receivedMessage)
    elseif receivedMessage.type == MESSAGE_TYPES.SYNC_COMPLETE then
        ns.sync:HandleSyncComplete(sender, receivedMessage)
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
        local serializedNack = ns.sync:SerializeData(nackMessage)
        AceComm:SendCommMessage(SYNC_PREFIX, serializedNack, "WHISPER", sender)
        return
    end

    -- Zeige Bestätigungspopup
    ns.sync:ShowSyncConfirmationPopup(sender, dataType)
end

function ns.sync:OnSyncAccept(sender, dataType)
    ns.guild:DebugPrint("Accepted sync request from " .. sender .. " for " .. dataType)

    -- Sende SyncAck
    local ackMessage = {
        type = MESSAGE_TYPES.SYNC_ACK,
        dataType = dataType,
    }
    local serializedAck = ns.sync:SerializeData(ackMessage)
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
    local serializedNack = ns.sync:SerializeData(nackMessage)
    AceComm:SendCommMessage(SYNC_PREFIX, serializedNack, "WHISPER", sender)
end

function ns.sync:HandleSyncAck(sender, message)
    local dataType = message.dataType
    ns.guild:DebugPrint("Received SyncAck from " .. sender .. " for " .. dataType)

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
    local serializedData = ns.sync:SerializeData(dataMessage)
    AceComm:SendCommMessage(SYNC_PREFIX, serializedData, "WHISPER", sender)
    ns.guild:DebugPrint("Sent SyncData to " .. sender)
end

function ns.sync:HandleSyncData(sender, message)
    local dataType = message.dataType
    local data = message.data
    ns.guild:DebugPrint("Received SyncData from " .. sender .. " for " .. dataType)

    -- Verarbeite die empfangenen Daten
    if dataType == "Settings" then
        -- Aktualisiere die Einstellungen
        -- (Dein Code zum Aktualisieren der Einstellungen)
    elseif dataType == "Statistics" then
        -- Aktualisiere die Statistiken
        -- (Dein Code zum Aktualisieren der Statistiken)
    end

    -- Sende SyncComplete
    local completeMessage = {
        type = MESSAGE_TYPES.SYNC_COMPLETE,
        dataType = dataType,
    }
    local serializedComplete = ns.sync:SerializeData(completeMessage)
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
