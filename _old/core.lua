local ADDON_NAME = "LootCouncilRandomizer"
local ADDON_VERSION = "1.0"

AceGUI = LibStub("AceGUI-3.0")
LootCouncilRandomizer = LootCouncilRandomizer or {}
LootCouncilRandomizer.AceGUI = AceGUI
LibDataBroker = LibStub("LibDataBroker-1.1")
LibDBIcon = LibStub("LibDBIcon-1.0")
local mainContent

local addon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")

-- DataBroker for Minimap
local function CreateMinimapDataBroker()
    -- DataBroker for Minimap creation
    local LCR_LDB = LibDataBroker:NewDataObject("LootCouncilRandomizer", {
        type = "data source",
        text = "LootCouncilRandomizer",
        label = "LootCouncilRandomizer",
        icon = "Interface\\Icons\\inv_misc_questionmark",
        OnClick = function(_, button)
            if button == "LeftButton" then
                -- Toggle visibility of the main content frame
                if mainContent and mainContent:IsShown() then
                    mainContent:Hide()
                else
                    mainContent:Show()
                end
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine("LootCouncilRandomizer")
            tt:AddLine("Click to toggle main window")
        end
    })

    -- Register Minimap icon
    if addon.db and addon.db.profile then
        LibDBIcon:Register("LootCouncilRandomizer", LCR_LDB, addon.db.profile.minimap)
    end
end

function addon:HandleGuildRosterUpdate()
    LootCouncilRandomizerGuildDB = {} -- Clear the old data
    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
        local name, rank, rankIndex = GetGuildRosterInfo(i)
        LootCouncilRandomizerGuildDB[i] = {
            name = name,
            rank = rank,
            rankIndex = rankIndex
        }
    end
end

function addon:InitializeAddon()
    local navGroup = self:CreateMainFrame()

    -- Register Chat command
    self:RegisterChatCommand()
end

function addon:OnInitialize()
    LootCouncilRandomizerDB = LootCouncilRandomizerDB or {
        selectedRankIndex = 1,
        councilSize = 5
    }
    LootCouncilRandomizerGuildDB = LootCouncilRandomizerGuildDB or {}
    self:RegisterEvent("GUILD_ROSTER_UPDATE", "HandleGuildRosterUpdate")
    C_GuildInfo.GuildRoster()  -- Use modern API call
    self.DB = LootCouncilRandomizerDB
    self.GuildDB = LootCouncilRandomizerGuildDB
    self:InitializeAddon()
    self:RegisterChatCommand()
    self:CreateMainFrame()

    -- Create Minimap Button
    CreateMinimapDataBroker()
end


function addon:OnEnable()
    -- Initial data fetch
    C_GuildInfo.GuildRoster()  -- Use modern API call
end

function addon:CreateMainFrame()
    local LCRframe = AceGUI:Create("Frame")
    LCRframe:SetTitle(ADDON_NAME)
    LCRframe:SetStatusText("Version " .. ADDON_VERSION)
    LCRframe:SetLayout("Flow")
    LCRframe:SetWidth(800)
    LCRframe:SetHeight(600)

    local layoutContainer = AceGUI:Create("SimpleGroup")
    layoutContainer:SetFullWidth(true)
    layoutContainer:SetFullHeight(true)
    layoutContainer:SetLayout("Flow") 
    LCRframe:AddChild(layoutContainer)

    local navGroup = AceGUI:Create("SimpleGroup")
    navGroup:SetWidth(150)
    navGroup:SetHeight(550)
    navGroup:SetLayout("List")
    layoutContainer:AddChild(navGroup)

    local divider = AceGUI:Create("Label")
    divider:SetText("")
    divider:SetWidth(3)
    layoutContainer:AddChild(divider)

    mainContent = AceGUI:Create("SimpleGroup")
    mainContent:SetWidth(600)
    mainContent:SetHeight(550)
    mainContent:SetLayout("Fill")
    layoutContainer:AddChild(mainContent)

    -- Buttons to the navigation bar
    local guildMembersBtn = AceGUI:Create("Button")
    guildMembersBtn:SetText("Guild Members")
    guildMembersBtn:SetFullWidth(true)
    guildMembersBtn:SetCallback("OnClick", function()
        LootCouncilRandomizer.GuildMembersCallback(mainContent)
    end)
    navGroup:AddChild(guildMembersBtn)

    local settingsBtn = AceGUI:Create("Button")
    settingsBtn:SetText("Settings")
    settingsBtn:SetFullWidth(true)
    settingsBtn:SetCallback("OnClick", function() 
        LootCouncilRandomizer.SettingsCallback(mainContent)
    end)
    navGroup:AddChild(settingsBtn)

    -- Add separator
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    navGroup:AddChild(spacer)

    return LCRframe
end

function addon:RegisterChatCommand()
    SLASH_LOOTCOUNCILRANDOMIZER1 = "/lcr"
    SlashCmdList["LOOTCOUNCILRANDOMIZER"] = function()
        self:ShowMainFrame()
    end
end

function addon:ShowMainFrame()
    if mainContent then
        if mainContent:IsShown() then
            mainContent:Hide()
        else
            mainContent:Show()
        end
    else
        print("Main content frame is not initialized.")
    end
end

