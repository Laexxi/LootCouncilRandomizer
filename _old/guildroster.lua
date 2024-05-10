function LootCouncilRandomizer.GuildMembersCallback(container)
    container:ReleaseChildren() 
    local guildFrame = AceGUI:Create("SimpleGroup")
    guildFrame:SetFullWidth(true)
    guildFrame:SetFullHeight(true)
    guildFrame:SetLayout("Flow")

    local guildMembers = LootCouncilRandomizerGuildDB

    for _, memberData in ipairs(guildMembers) do
        local rank = memberData.rank
        local name = memberData.name
        local rankIndex = memberData.rankIndex

        local memberLabel = AceGUI:Create("Label")
        memberLabel:SetText(rank .. " | " .. name)
        guildFrame:AddChild(memberLabel)
    end

    container:AddChild(guildFrame)
end