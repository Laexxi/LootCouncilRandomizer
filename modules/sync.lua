local ADDON_NAME, ns = ...
local LootCouncilRandomizer = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)
local module = LootCouncilRandomizer:NewModule("Sync", "AceComm-3.0")
ns.sync = module
local AceComm = LibStub("AceComm-3.0")

local SYNC_PREFIX = "LCR_Sync"

local utility = ns.utility
local debug = ns.debug

local function CreatePopup(name, text, button1, button2, onAccept, onCancel)
    StaticPopupDialogs[name] = {
        text = text,
        button1 = button1,
        button2 = button2,
        OnAccept = onAccept,
        OnCancel = onCancel,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show(name)
end

-- Nachrichtentypen
local MESSAGE_TYPES = {
    SYNC_REQUEST = "SyncRequest",
    SYNC_ACK = "SyncAck",
    SYNC_NACK = "SyncNack",
    SYNC_DATA = "SyncData",
    SYNC_COMPLETE = "SyncComplete",
}

function module:OnInitialize()
    self:RegisterEvents()
end

function module:GetOptions()
    return {
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
                    syncSettingsPlayerName = {
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
                            module:InitiateSettingsSync()
                        end,
                        order = 5,
                        width = "normal",
                    },
                    testSyncButton = {
                        type = "execute",
                        name = "Test Sync Message",
                        desc = "Send a test sync message to yourself.",
                        func = function()
                            module:SendTestMessage()
                        end,
                        order = 6,
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
                            module:InitiateStatisticsSync()
                        end,
                        order = 6,
                        width = "normal",
                    },
                },
            },
        },
    }
end

function module:RegisterEvents()
    self:RegisterComm(SYNC_PREFIX, "OnCommReceived")
    print("Registered communication with prefix:", SYNC_PREFIX)
end

function module:InitiateSettingsSync()
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
    local serializedMessage = utility:SerializeData(message)
    if not serializedMessage then
        debug:DebugPrint("Sync", "Failed to serialize SyncRequest for Settings")
        return
    end

    self:SendCommMessage(SYNC_PREFIX, serializedMessage, "WHISPER", targetPlayer)
    print("Serialized message:", serializedMessage)
    debug:DebugPrint("Sync", "Sent SyncRequest to " .. targetPlayer)
end

function module:InitiateStatisticsSync()
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
    local serializedMessage = utility:SerializeData(message)

    if not serializedMessage then
        debug:DebugPrint("Sync", "Failed to serialize SyncRequest for Statistics")
        return
    end

    if targetPlayer then
        self:SendCommMessage(SYNC_PREFIX, serializedMessage, "WHISPER", targetPlayer)
        debug:DebugPrint("Sync", "Sent SyncRequest to " .. targetPlayer)
    elseif syncTo == "guild" then
        self:SendCommMessage(SYNC_PREFIX, serializedMessage, "GUILD")
        debug:DebugPrint("Sync", "Sent SyncRequest to GUILD")
    elseif syncTo == "raid" then
        self:SendCommMessage(SYNC_PREFIX, serializedMessage, "RAID")
        debug:DebugPrint("Sync", "Sent SyncRequest to RAID")
    end
end

function module:OnCommReceived(prefix, message, distribution, sender)
    debug:DebugPrint("Sync", "Received message from " .. sender .. " via " .. distribution)
    local success, receivedMessage = utility:DeserializeData(message)
    if not success then
        debug:DebugPrint("Sync", "Failed to deserialize message from " .. sender)
        return
    end

    if receivedMessage.type == "TestMessage" then
        utility:CreatePopup(
            "LCR_TEST_MESSAGE",
            "Test message received from " .. sender .. ": " .. (receivedMessage.content or ""),
            "Okay",
            nil,
            function() print("Test message acknowledged.") end
        )
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
        debug:DebugPrint("Sync", "Unknown message type from " .. sender)
    end
end

function module:HandleSyncRequest(sender, message)
    local dataType = message.dataType
    debug:DebugPrint("Sync", "Received SyncRequest from " .. sender .. " for " .. dataType)

    -- Prüfe, ob wir den Datentyp unterstützen
    if dataType ~= "Settings" and dataType ~= "Statistics" then
        -- Sende SyncNack
        local nackMessage = {
            type = MESSAGE_TYPES.SYNC_NACK,
            dataType = dataType,
            reason = "Unsupported data type",
        }
        local serializedNack = utility:SerializeData(nackMessage)
        if serializedNack then
            self:SendCommMessage(SYNC_PREFIX, serializedNack, "WHISPER", sender)
            debug:DebugPrint("Sync", "Sent SyncNack to " .. sender .. " for unsupported data type " .. dataType)
        else
            debug:DebugPrint("Sync", "Failed to serialize SyncNack for " .. sender)
        end
        return
    end

    -- Zeige Bestätigungspopup
    utility:CreatePopup(
        "LCR_SYNC_CONFIRMATION",
        sender .. " wants to sync " .. dataType .. " with you. Do you accept?",
        "Accept",
        "Decline",
        function()
            module:OnSyncAccept(sender, dataType)
        end,
        function()
            module:OnSyncDecline(sender, dataType)
        end
    )
end

function module:OnSyncAccept(sender, dataType)
    debug:DebugPrint("Sync", "Accepted sync request from " .. sender .. " for " .. dataType)

    -- Sende SyncAck
    local ackMessage = {
        type = MESSAGE_TYPES.SYNC_ACK,
        dataType = dataType,
    }
    local serializedAck = utility:SerializeData(ackMessage)
    if serializedAck then
        self:SendCommMessage(SYNC_PREFIX, serializedAck, "WHISPER", sender)
        debug:DebugPrint("Sync", "Sent SyncAck to " .. sender)
    else
        debug:DebugPrint("Sync", "Failed to serialize SyncAck for " .. sender)
    end
end

function module:OnSyncDecline(sender, dataType)
    debug:DebugPrint("Sync", "Declined sync request from " .. sender .. " for " .. dataType)

    -- Sende SyncNack
    local nackMessage = {
        type = MESSAGE_TYPES.SYNC_NACK,
        dataType = dataType,
        reason = "User declined",
    }
    local serializedNack = utility:SerializeData(nackMessage)
    if serializedNack then
        self:SendCommMessage(SYNC_PREFIX, serializedNack, "WHISPER", sender)
        debug:DebugPrint("Sync", "Sent SyncNack to " .. sender .. " for user declined")
    else
        debug:DebugPrint("Sync", "Failed to serialize SyncNack for " .. sender)
    end
end

function module:HandleSyncAck(sender, message)
    local dataType = message.dataType
    debug:DebugPrint("Sync", "Received SyncAck from " .. sender .. " for " .. dataType)

    if not self.pendingSyncs then
        debug:DebugPrint("Sync", "No pending syncs exist.")
        return
    end

    -- Hole die zu sendenden Daten
    local syncInfo = self.pendingSyncs[sender] or self.pendingSyncs[LootCouncilRandomizer.db.profile.settings.syncTo]
    if not syncInfo or syncInfo.dataType ~= dataType then
        debug:DebugPrint("Sync", "No pending sync data for " .. sender)
        return
    end

    -- Sende SyncData
    local dataMessage = {
        type = MESSAGE_TYPES.SYNC_DATA,
        dataType = dataType,
        data = syncInfo.data,
    }

    if not AceComm or not AceComm.SendCommMessage then
        print("AceComm or SendCommMessage is not available.")
        return
    end
    
    print("Sending message:", SYNC_PREFIX, serializedData, "WHISPER", sender)
    local serializedData = utility:SerializeData(dataMessage)
    if serializedData then
        AceComm:SendCommMessage(SYNC_PREFIX, serializedData, "WHISPER", sender)
        debug:DebugPrint("Sync", "Sent SyncData to " .. sender)
    else
        debug:DebugPrint("Sync", "Failed to serialize SyncData for " .. sender)
    end
end

function module:HandleSyncData(sender, message)
    local dataType = message.dataType
    local data = message.data
    debug:DebugPrint("Sync", "Received SyncData from " .. sender .. " for " .. dataType)

    -- Verarbeite die empfangenen Daten
    if dataType == "Settings" then
        -- Überschreibe die aktuellen Einstellungen mit den empfangenen
        LootCouncilRandomizer.db.profile.settings = data
        debug:DebugPrint("Sync", "Settings updated from sync with " .. sender)
        -- Aktualisiere ggf. die Optionsoberfläche
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    elseif dataType == "Statistics" then
        -- Aktualisiere die Statistiken
        LootCouncilRandomizer.db.profile.statistics = data
        debug:DebugPrint("Sync", "Statistics updated from sync with " .. sender)
    end

    -- Sende SyncComplete
    local completeMessage = {
        type = MESSAGE_TYPES.SYNC_COMPLETE,
        dataType = dataType,
    }
    local serializedComplete = utility:SerializeData(completeMessage)
    if serializedComplete then
        self:SendCommMessage(SYNC_PREFIX, serializedComplete, "WHISPER", sender)
        debug:DebugPrint("Sync", "Sent SyncComplete to " .. sender)
    else
        debug:DebugPrint("Sync", "Failed to serialize SyncComplete for " .. sender)
    end
end

function module:HandleSyncComplete(sender, message)
    local dataType = message.dataType
    debug:DebugPrint("Sync", "Received SyncComplete from " .. sender .. " for " .. dataType)

    -- Entferne die pendingSync
    if self.pendingSyncs then
        self.pendingSyncs[sender] = nil
    end

    LootCouncilRandomizer:AddToLog("Synchronization with " .. sender .. " completed.")
end

function module:SendTestMessage()
    local playerName = UnitName("player") -- Hole den eigenen Spielernamen

    local message = {
        type = "TestMessage",
        content = "This is a test sync message.",
    }

    local serializedMessage = utility:SerializeData(message)

    if not serializedMessage then
        debug:DebugPrint("Sync", "Failed to serialize test message")
        return
    end

    AceComm:SendCommMessage(SYNC_PREFIX, serializedMessage, "WHISPER", playerName)
    debug:DebugPrint("Sync", "Sent test message to " .. playerName)
end

return ns.sync