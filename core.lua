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
                debugMode = false,
                ignoreMinMembers = false,
                debugTestMode = false,
                syncWhenRolling = false,
            },
            statistics = {},
        }
    }, true)

    ns.guild:AddToLog("Addon initialized with settings: Council Size = " .. tostring(self.db.profile.settings.councilSize))
    self:SetupOptions()
    self:SetupMinimapButton()
    -- ns.sync:RegisterEvents()
    ns.config:UpdateGroupNames(self.db.profile.settings.councilPots or 1)
end

function LootCouncilRandomizer:OnEnable()
    ns.guild:AddToLog("Addon enabled")
    self:RegisterEvent("GUILD_ROSTER_UPDATE","UpdateGuildOverview")
    self:RegisterEvent("PLAYER_GUILD_UPDATE", "UpdateGuildOverview")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateGuildOverview")
    self:RegisterChatCommand("lcr", "ChatCommand")
end

function LootCouncilRandomizer:SetupOptions()
    ns.guild:AddToLog("Setting up options")
    local options = {
        name = ADDON_NAME,
        handler = LootCouncilRandomizer,
        type = 'group',
        childGroups = 'tab',
        args = {
            guildOverview = ns.guild:GetOptions(),
            settings = ns.config:GetOptions(),
            sync = ns.sync:GetOptions(),
            history = ns.statistics:GetOptions(),
            changelog = ns.changelog:GetOptions(),
        },
    }

    options.args.settings.order = 1
    options.args.sync.order = 2
    options.args.history.order = 3
    options.args.changelog.order = 4
    options.args.guildOverview.order = 5

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
    local cmd = input:trim()
    if cmd == "" or cmd == "open" then
        LibStub("AceConfigDialog-3.0"):Open(ADDON_NAME)
    elseif cmd == "roll" then
        ns.randomizer:RandomizeCouncil()
    elseif cmd == "log" then
        ns.guild:ToggleLogFrame()
    else
        print("Usage:")
        print("/lcr open - Opens the configuration window.")
        print("/lcr roll - Randomizes the council.")
        print("/lcr log - Opens or closes the log window.")
    end
end


function LootCouncilRandomizer:UpdateGuildOverview()
    if self.options and self.options.args.guildOverview then
        self.options.args.guildOverview = ns.guild:GetOptions()
        LibStub("AceConfigRegistry-3.0"):NotifyChange(ADDON_NAME)
    end
end
