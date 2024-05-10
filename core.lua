local AceAddon = LibStub("AceAddon-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local LibDataBroker = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")
local ADDON_NAME = "LootCouncilRandomizer"
local addon = AceAddon:NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")


function addon:OnInitialize()
    -- Database setup
    self.db = AceDB:New("LootCouncilRandomizerDB", { profile = {} })

    local function getGuildRanks()
        local ranks = {}
        if IsInGuild() then
            for i = 1, GuildControlGetNumRanks() do
                ranks[i] = GuildControlGetRankName(i)
            end
        end
        return ranks
    end

    -- Define the structure of your configuration options
    local options = {
        name = ADDON_NAME,
        handler = addon,
        type = 'group',
        args = {
            guildroster = {
                type = "group",
                name = "Gildenübersicht",
                order = 1,
                args = {
                    desc = {
                        type = "description",
                        name = "Gildenübersicht",
                        order = 1
                    },
                },
            },
            settings = {
                type = "group",
                name = "Settings",
                order = 2,
                args = {
                    desc = {
                        type = "description",
                        name = "Settings for the Loot Council Randomizer.",
                        order = 1
                    },
                    emptyLine = {
                        type = "description",
                        name = "",
                        order = 1.5,
                        width = "full"
                    },
                    emptyLine = {
                        type = "description",
                        name = "",
                        order = 1.5,
                        width = "full"
                    },
                    guildRank = {
                        type = "select",
                        name = "Mindestrang für das LootCouncil",
                        desc = "Wähle den minimalen Gildenrang, der teilnehmen darf.",
                        values = getGuildRanks(),
                        order = 2,
                        get = function(info)
                            return addon.db.profile.selectedRankIndex or 1
                        end,
                        set = function(info, value)
                            addon.db.profile.selectedRankIndex = value
                            addon.db.profile.selectedRankName = GuildControlGetRankName(value)
                        end,
                    },
                    councilSize = {
                        type = "range",
                        name = "Anzahl an Council-Mitgliedern",
                        desc = "Stelle die Anzahl der Council-Mitglieder ein.",
                        min = 1,
                        max = 30,
                        step = 1,
                        order = 3,
                        get = function(info)
                            return addon.db.profile.councilSize or 5
                        end,
                        set = function(info, value)
                            addon.db.profile.councilSize = value
                        end,
                    },
                    councilPots = {
                        type = "range",
                        name = "Anzahl an Lostöpfen",
                        desc = "Aus wie vielen Gruppen soll das LootCouncil bestehen.\n Bps: 4 Gesamt, 2 Offiziere, 2 Raider",
                        min = 1,
                        max = 30, -- adjust this to match practical limits
                        step = 1,
                        order = 4,
                        get = function(info)
                            return addon.db.profile.councilPots or 1
                        end,
                        set = function(info, value)
                            if value <= addon.db.profile.councilSize then
                                addon.db.profile.councilPots = value
                            else
                                -- Add logic to handle error or inform the user
                                print("Anzahl der Lostöpfe kann nicht größer als die Anzahl der Council-Mitglieder sein.")
                            end
                        end,
                    },
                    saveSettings = {
                        type = "execute",
                        name = "Speichern",
                        desc = "Speichere die aktuellen Einstellungen.",
                        func = function()
                            print("Einstellungen gespeichert.")
                        end,
                        order = 5,
                    },
                },
            },
            about = {
                type = "group",
                name = "About",
                order = 5,
                args = {
                    desc = {
                        type = "description",
                        name = "Loot Council Randomizer Version 1.0\nAuthor: Laexxi",
                        order = 1
                    },
                },
            },
        },
    }

    -- Register options table and create standalone window
    AceConfig:RegisterOptionsTable(ADDON_NAME, options)
    self.configFrame = AceConfigDialog:AddToBlizOptions(ADDON_NAME, ADDON_NAME)
    AceConfigDialog:SetDefaultSize(ADDON_NAME, 600, 400)

    -- Minimap button setup
    local ldb = LibDataBroker:NewDataObject(ADDON_NAME, {
        type = "launcher",
        text = ADDON_NAME,
        icon = "Interface\\Icons\\inv_misc_questionmark",
        OnClick = function(_, button)
            if button == "RightButton" then
                AceConfigDialog:Open(ADDON_NAME)
            elseif button == "LeftButton" then
                -- Reserved for future functionality
                print("Left click action will be added here.")
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine(ADDON_NAME)
            tt:AddLine("Right-click to open the configuration.")
            tt:AddLine("Left-click for future functionality.")
        end,
    })

    LibDBIcon:Register(ADDON_NAME, ldb, self.db.profile.minimap)

    -- Register chat command
    self:RegisterChatCommand("lcr", "ChatCommand")
end

function addon:ChatCommand()
    -- This function toggles the configuration panel
    if AceConfigDialog.OpenFrames[ADDON_NAME] then
        AceConfigDialog:Close(ADDON_NAME)
    else
        AceConfigDialog:Open(ADDON_NAME)
    end
end
