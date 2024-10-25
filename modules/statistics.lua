local ADDON_NAME, ns = ...
ns.statistics = {}

function ns.statistics:GetOptions()
    return {
        name = "Statistics",
        type = "group",
        args = {
            resetStats = {
                type = "execute",
                name = "Reset Statistics",
                desc = "This will reset all statistics.",
                confirm = true,
                confirmText = "Are you sure you want to reset all statistics?",
                func = function()
                    -- Sicherheitsabfrage einbauen
                    StaticPopupDialogs["CONFIRM_RESET_STATS"] = {
                        text = "Are you sure you want to reset all statistics? This action cannot be undone.",
                        button1 = "Yes",
                        button2 = "No",
                        OnAccept = function()
                            LootCouncilRandomizer.db.profile.statistics = {}
                            print("Loot Council Randomizer: All statistics have been reset.")
                        end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        preferredIndex = 3,
                    }
                    StaticPopup_Show("CONFIRM_RESET_STATS")
                end,
                order = 1,
            },
            viewStats = {
                type = "execute",
                name = "View Statistics",
                desc = "View detailed statistics in a separate window.",
                func = function()
                    ns.statistics:ShowStatisticsWindow()
                end,
                order = 2,
            },
        },
    }
end

function ns.statistics:ShowStatisticsWindow()
    if self.statsWindow then
        self.statsWindow:Show()
        return
    end

    local stats = LootCouncilRandomizer.db.profile.statistics or {}

    -- Sammle die Statistiken der Mitglieder aus den gespeicherten Variablen
    local memberStats = {}

    for member, data in pairs(stats) do
        local timesSelected = data.timesSelected or 0
        local lastSelectedTime = data.lastSelectedTime
        local lastSelected
        if lastSelectedTime then
            lastSelected = date("%d.%m.%Y", lastSelectedTime) -- Nur Datum anzeigen
        else
            lastSelected = "-"
        end
        table.insert(memberStats, {
            member = member,
            timesSelected = timesSelected,
            lastSelected = lastSelected
        })
    end

    -- Sortiere die Mitglieder nach Anzahl der Auswahlen (absteigend)
    table.sort(memberStats, function(a, b)
        return a.timesSelected > b.timesSelected
    end)

    -- Erstelle das Fenster
    local frame = CreateFrame("Frame", "LootCouncilRandomizerStatsWindow", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(450, 400)
    frame:SetPoint("CENTER")

    -- Stelle sicher, dass das Fenster über anderen Fenstern erscheint
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(frame:GetFrameLevel() + 10)

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlightLarge")
    frame.title:SetPoint("TOP", frame.TitleBg, "TOP", 0, -5)
    frame.title:SetText("Loot Council Randomizer Statistics")

    -- ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)

    -- Inhalt des ScrollFrames
    local contentHeight = 20 * (#memberStats + 1)
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(400, contentHeight)
    scrollFrame:SetScrollChild(content)

    -- Erstelle die Überschriften
    local header = CreateFrame("Frame", nil, content)
    header:SetSize(400, 20)
    header:SetPoint("TOPLEFT", content, "TOPLEFT")

    local font = "Fonts\\ARIALN.TTF" -- Monospace-Schriftart

    local headerMember = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerMember:SetFont(font, 13)
    headerMember:SetPoint("LEFT", header, "LEFT")
    headerMember:SetWidth(120)
    headerMember:SetJustifyH("LEFT")
    headerMember:SetText("Member")

    local headerTimes = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerTimes:SetFont(font, 13)
    headerTimes:SetPoint("LEFT", headerMember, "RIGHT", 10, 0)
    headerTimes:SetWidth(100)
    headerTimes:SetJustifyH("LEFT")
    headerTimes:SetText("Times Selected")

    local headerLast = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerLast:SetFont(font, 13)
    headerLast:SetPoint("LEFT", headerTimes, "RIGHT", 10, 0)
    headerLast:SetWidth(170)
    headerLast:SetJustifyH("LEFT")
    headerLast:SetText("Last Selected")

    -- Füge die Daten hinzu
    for i, data in ipairs(memberStats) do
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(400, 20)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -20 * i)

        local memberText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        memberText:SetFont(font, 12)
        memberText:SetPoint("LEFT", row, "LEFT")
        memberText:SetWidth(120)
        memberText:SetJustifyH("LEFT")
        memberText:SetText(data.member)

        local timesText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        timesText:SetFont(font, 12)
        timesText:SetPoint("LEFT", memberText, "RIGHT", 10, 0)
        timesText:SetWidth(100)
        timesText:SetJustifyH("LEFT")
        timesText:SetText(tostring(data.timesSelected))

        local lastText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lastText:SetFont(font, 12)
        lastText:SetPoint("LEFT", timesText, "RIGHT", 10, 0)
        lastText:SetWidth(170)
        lastText:SetJustifyH("LEFT")
        lastText:SetText(data.lastSelected)
    end

    self.statsWindow = frame
end

function ns.statistics:UpdateMemberStats(memberName)
    if not LootCouncilRandomizer.db.profile.statistics[memberName] then
        LootCouncilRandomizer.db.profile.statistics[memberName] = { timesSelected = 0, lastSelectedTime = 0 }
    end

    LootCouncilRandomizer.db.profile.statistics[memberName].timesSelected = 
        (LootCouncilRandomizer.db.profile.statistics[memberName].timesSelected or 0) + 1

    LootCouncilRandomizer.db.profile.statistics[memberName].lastSelectedTime = time()
end
