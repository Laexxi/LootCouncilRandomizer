local ADDON_NAME = "LootCouncilRandomizer"
local AceGUI = LibStub("AceGUI-3.0")
local LibDataBroker = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")
local addon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")

-- This will hold the main frame of our addon
local mainContent

-- Function to create the main frame
function addon:CreateMainFrame()
    if not mainContent then
        mainContent = AceGUI:Create("Frame")
        mainContent:SetTitle("Loot Council Randomizer")
        mainContent:SetCallback("OnClose", function(widget)
            AceGUI:Release(widget)
            mainContent = nil
        end)
        mainContent:SetLayout("Flow")
        mainContent:SetWidth(400)
        mainContent:SetHeight(300)
    else
        mainContent:Show()
    end
end

-- Minimap DataBroker creation
local function CreateMinimapDataBroker()
    local LCR_LDB = LibDataBroker:NewDataObject(ADDON_NAME, {
        type = "data source",
        text = ADDON_NAME,
        icon = "Interface\\Icons\\inv_misc_questionmark",
        OnClick = function(_, button)
            if button == "LeftButton" then
                if mainContent and mainContent:IsShown() then
                    mainContent:Hide()
                else
                    addon:CreateMainFrame()
                end
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine(ADDON_NAME)
            tt:AddLine("Click to toggle the main window.")
        end
    })
    LibDBIcon:Register(ADDON_NAME, LCR_LDB, {})
end

-- Initialize the addon
function addon:OnInitialize()
    self:RegisterChatCommand("lcr", "ChatCommand")
    CreateMinimapDataBroker()
end

-- Function to handle chat command
function addon:ChatCommand(input)
    if not mainContent or not mainContent:IsShown() then
        self:CreateMainFrame()
    else
        mainContent:Hide()
    end
end

-- Function called when addon is enabled
function addon:OnEnable()
    -- Any specific actions when addon is enabled
end

-- Function called when addon is disabled
function addon:OnDisable()
    -- Any cleanup when addon is disabled
end
