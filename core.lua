local AceAddon = LibStub("AceAddon-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local LibDataBroker = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")
local ADDON_NAME = "LootCouncilRandomizer"
local addon = AceAddon:NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")
local orderCounter = 0

-- Helper function to get the next order
local function nextOrder()
    orderCounter = orderCounter + 1
    return orderCounter
end

-- Function to retrieve guild ranks
function addon:GetGuildRanks()
    local ranks = {}
    if IsInGuild() then
        for i = 0, GuildControlGetNumRanks() - 1 do
            ranks[i+1] = GuildControlGetRankName(i)
        end
    end
    return ranks
end


-- Function to retrieve guild members by minimum rank
function addon:GetGuildMembersByMinRank()
    local membersByRank = {}
    if IsInGuild() then
        local minRankIndex = self.db.profile.selectedRankIndex or 0
        for i = 1, GetNumGuildMembers() do
            local name, rank, rankIndex = GetGuildRosterInfo(i)
            if rankIndex and rankIndex <= minRankIndex then -- Include members of selected rank and higher ranks
                name = name:match("([^%-]+)") -- Strip the server name from the player's name
                membersByRank[rank] = membersByRank[rank] or {}
                table.insert(membersByRank[rank], name)
            end
        end
    end
    return membersByRank
end

function addon:OnInitialize()
    -- Initial DB setup
    self.db = AceDB:New("LootCouncilRandomizerDB", { profile = {} })
    self:RegisterOptions()
end

function addon:RegisterOptions()
    local options = {
        name = ADDON_NAME,
        handler = addon,
        type = 'group',
        args = {
            guildroster = {
                type = "group",
                name = "Gildenübersicht",
                order = nextOrder(),
                args = self:UpdateGuildRosterOptions()
            },
            settings = {
                type = "group",
                name = "Settings",
                order = nextOrder(),
                args = {
                    desc = {
                        type = "description",
                        name = "Settings for the Loot Council Randomizer.",
                        order = nextOrder()
                    },
                    guildRank = {
                        type = "select",
                        name = "Mindestrang für das LootCouncil",
                        desc = "Wähle den minimalen Gildenrang, der teilnehmen darf.",
                        values = function() return self:GetGuildRanks() end,
                        order = nextOrder(),
                        get = function(info)
                            return self.db.profile.selectedRankIndex or 0
                        end,
                        set = function(info, value)
                            self.db.profile.selectedRankIndex = value - 1 -- Set index to match the game's zero-based index
                            self.db.profile.selectedRankName = GuildControlGetRankName(value - 1)
                        end,
                    },
                    councilSize = {
                        type = "range",
                        name = "Anzahl an Council-Mitgliedern",
                        desc = "Stelle die Anzahl der Council-Mitglieder ein.",
                        min = 1,
                        max = 30,
                        step = 1,
                        order = nextOrder(),
                        get = function(info)
                            return self.db.profile.councilSize or 5
                        end,
                        set = function(info, value)
                            self.db.profile.councilSize = value
                        end,
                    },
                    councilPots = {
                        type = "range",
                        name = "Anzahl an Lostöpfen",
                        desc = "Aus wie vielen Gruppen soll das LootCouncil bestehen.",
                        min = 1,
                        max = 30,
                        step = 1,
                        order = nextOrder(),
                        get = function(info)
                            return self.db.profile.councilPots or 1
                        end,
                        set = function(info, value)
                            if value <= self.db.profile.councilSize then
                                self.db.profile.councilPots = value
                            else
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
                        order = nextOrder(),
                    },
                },
            },
            about = {
                type = "group",
                name = "About",
                order = nextOrder(),
                args = {
                    desc = {
                        type = "description",
                        name = "Loot Council Randomizer Version 1.0\nAuthor: Laexxi",
                        order = nextOrder()
                    },
                },
            },
        },
    }

    AceConfig:RegisterOptionsTable(ADDON_NAME, options)
    self.configFrame = AceConfigDialog:AddToBlizOptions(ADDON_NAME, ADDON_NAME)
    AceConfigDialog:SetDefaultSize(ADDON_NAME, 600, 400)

    local ldb = LibDataBroker:NewDataObject(ADDON_NAME, {
        type = "launcher",
        text = ADDON_NAME,
        icon = "Interface\\Icons\\inv_misc_questionmark",
        OnClick = function(_, button)
            if button == "RightButton" then
                AceConfigDialog:Open(ADDON_NAME)
            elseif button == "LeftButton" then
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
    self:RegisterChatCommand("lcr", "ChatCommand")
end

function addon:ChatCommand()
    if AceConfigDialog.OpenFrames[ADDON_NAME] then
        AceConfigDialog:Close(ADDON_NAME)
    else
        AceConfigDialog:Open(ADDON_NAME)
    end
end

function addon:UpdateGuildRosterOptions()
    local membersByRank = self:GetGuildMembersByMinRank()
    local args = {}
    for rank, members in pairs(membersByRank) do
        args[rank] = {
            type = "group",
            name = rank,
            order = nextOrder(),
            args = {}
        }
        for i, name in ipairs(members) do
            args[rank].args[name] = {
                type = "description",
                name = name,
                desc = "Member of " .. rank,
                order = i
            }
        end
    end
    return args
end

function addon:OnEnable()
    self:RegisterEvent("GUILD_ROSTER_UPDATE", "HandleGuildRosterUpdate")
end

function addon:HandleGuildRosterUpdate()
    local rosterArgs = self:UpdateGuildRosterOptions()
    self.options.args.guildroster.args = rosterArgs
    AceConfigRegistry:NotifyChange(ADDON_NAME)
end
