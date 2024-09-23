local ADDON_NAME, ns = ...
LootCouncilRandomizer = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")

function LootCouncilRandomizer:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("LootCouncilRandomizerDB", {
        profile = {
            settings = {
                language = GetLocale(),    
                minimap = { hide = false },
                selectedRanks = {},
                councilSize = 5,
                councilPots = 2,
                reselectDuration = 0,
                forcedPlayers = "",
                excludedPlayers = "",
                debugMode = false,
            },
            statistics = {},
        }
    }, true)

    self:SetupOptions()
    self:SetupMinimapButton()
    ns.config:UpdateGroupNames(self.db.profile.settings.councilPots or 1)
end

function LootCouncilRandomizer:OnEnable()
    self:RegisterEvent("GUILD_ROSTER_UPDATE","UpdateGuildOverview")
    self:RegisterEvent("PLAYER_GUILD_UPDATE", "UpdateGuildOverview")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateGuildOverview")
    self:RegisterChatCommand("lcr", "ChatCommand")
end

function LootCouncilRandomizer:SetupOptions()
    local options = {
        name = ADDON_NAME,
        handler = LootCouncilRandomizer,
        type = 'group',
        childGroups = 'tab',
        args = {
            guildOverview = ns.guild:GetOptions(),
            settings = ns.config:GetOptions(),
            history = ns.statistics:GetOptions(),
        },
    }
    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, options)
    self.options = options
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, ADDON_NAME)
    ns.config:UpdateGroupNames(self.db.profile.settings.councilPots or 1) 
end

function LootCouncilRandomizer:SetupMinimapButton()
    local ldb = LibStub("LibDataBroker-1.1"):NewDataObject(ADDON_NAME, {
        type = "launcher",
        text = ADDON_NAME,
        icon = "Interface\\AddOns\\LootCouncilRandomizer\\icon.tga",
        OnClick = function(_, button)
            if button == "RightButton" then
                LibStub("AceConfigDialog-3.0"):Open(ADDON_NAME)
            elseif button == "LeftButton" then
                ns.randomizer:RandomizeCouncil()
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine(ADDON_NAME)
            tt:AddLine("Right-click to open the configuration.")
            tt:AddLine("Left-click to randomize council.")
        end,
    })
    LibStub("LibDBIcon-1.0"):Register(ADDON_NAME, ldb, self.db.profile.settings.minimap)
end

function LootCouncilRandomizer:ChatCommand(input)
    if not input or input:trim() == "" or input:trim() == "open" then
        LibStub("AceConfigDialog-3.0"):Open(ADDON_NAME)
    elseif input:trim() == "roll" then
        ns.randomizer:RandomizeCouncil()
    elseif input:trim() == "groups" then
        ns.guild:ShowGroupMembers()
    else
        print("Usage:")
        print("/lcr open - Opens the configuration window.")
        print("/lcr roll - Randomizes the council.")
        print("/lcr groups - DEBUG: Shows members of the defined groups.")
    end
end

function LootCouncilRandomizer:UpdateGuildOverview()
    if self.options and self.options.args.guildOverview then
        self.options.args.guildOverview = ns.guild:GetOptions()
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    end
end
