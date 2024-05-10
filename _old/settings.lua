function LootCouncilRandomizer.SettingsCallback(container)
    container:ReleaseChildren() 
    local settingsFrame = AceGUI:Create("SimpleGroup")
    settingsFrame:SetFullWidth(true)
    settingsFrame:SetFullHeight(true)
    settingsFrame:SetLayout("Flow")

    -- import of guildranks
    local function getGuildRanks()
        local ranks = {}
        for i = 1, GuildControlGetNumRanks() do
            local rankName = GuildControlGetRankName(i)
            ranks[i] = rankName
        end
        return ranks
    end

    local guildRanks = getGuildRanks()
    local rankDropdown = AceGUI:Create("Dropdown")
    rankDropdown:SetLabel("Mindestrang für Gildenmitglieder")
    rankDropdown:SetList(guildRanks)

    -- check correct guild rank index
    local defaultRankIndex = LootCouncilRandomizerDB.selectedRankIndex and LootCouncilRandomizerDB.selectedRankIndex <= #guildRanks and LootCouncilRandomizerDB.selectedRankIndex or 1
    rankDropdown:SetValue(defaultRankIndex)

    settingsFrame:AddChild(rankDropdown)

    -- editbox council size
    local councilSizeEditBox = AceGUI:Create("EditBox")
    councilSizeEditBox:SetLabel("Anzahl an Council-Mitgliedern")
    councilSizeEditBox:SetWidth(100)

    councilSizeEditBox:SetCallback("OnEnterPressed", function(widget, event, text)
        local num = tonumber(text)
        widget:SetText(num and num >= 1 and num <= 30 and tostring(num) or "5")
    end)
    councilSizeEditBox:SetText(LootCouncilRandomizerDB.councilSize or "5")
    settingsFrame:AddChild(councilSizeEditBox)

    -- editbox council pots
    local councilPotsEditBox = AceGUI:Create("EditBox")
    councilPotsEditBox:SetLabel("Anzahl an Lostöpfen")
    councilPotsEditBox:SetWidth(100)
    councilSizeEditBox:SetCallback("OnEnterPressed", function(widget, event, text)
        local num = tonumber(text)
        widget:SetText(num and num >= 1 and num <= LootCouncilRandomizerDB.councilSize and tostring(num) or "1")
    end)
    councilPotsEditBox:SetText(LootCouncilRandomizerDB.councilPots or "1")
    settingsFrame:AddChild(councilPotsEditBox)

    --  save button
    local saveBtn = AceGUI:Create("Button")
    saveBtn:SetText("Speichern")
    saveBtn:SetCallback("OnClick", function()
        local selectedRankIndex = rankDropdown:GetValue()
        local selectedRankName = guildRanks[selectedRankIndex]
        local councilSize = tonumber(councilSizeEditBox:GetText())
        LootCouncilRandomizerDB.selectedRankIndex = selectedRankIndex 
        LootCouncilRandomizerDB.selectedRankName = selectedRankName 
        LootCouncilRandomizerDB.councilSize = councilSize
        LootCouncilRandomizerDB.councilPots = tonumber(councilPotsEditBox:GetText())
        print("Einstellungen gespeichert: Council-Größe: " .. councilSize .. ", Lostöpfen: " .. councilPots .. ", Rang: " .. selectedRankName)

    end)
    settingsFrame:AddChild(saveBtn)

    container:AddChild(settingsFrame)
end
