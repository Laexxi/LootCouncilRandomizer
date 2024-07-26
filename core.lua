local ADDON_NAME, ns = ...
LootCouncilRandomizer = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")

function LootCouncilRandomizer:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("LootCouncilRandomizerDB", { profile = {} })
    self:SetupOptions()
    self:SetupMinimapButton()
end

function LootCouncilRandomizer:OnEnable()
    self:RegisterEvent("GUILD_ROSTER_UPDATE", "UpdateGuildRoster")
end

function LootCouncilRandomizer:SetupOptions()
    local options = {
        name = ADDON_NAME,
        handler = LootCouncilRandomizer,
        type = 'group',
        args = {
            guildroster = ns.guild:GetOptions(),
            settings = ns.config:GetOptions(),
            statistics = ns.statistics:GetOptions(),
        },
    }
    LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME, ADDON_NAME)
end

function LootCouncilRandomizer:SetupMinimapButton()
    local ldb = LibStub("LibDataBroker-1.1"):NewDataObject(ADDON_NAME, {
        type = "launcher",
        text = ADDON_NAME,
        icon = "Interface\\Icons\\inv_misc_questionmark",
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
    LibStub("LibDBIcon-1.0"):Register(ADDON_NAME, ldb, self.db.profile.minimap)
end

function LootCouncilRandomizer:UpdateGuildRoster()
    ns.guild:UpdateGuildRoster()
end
