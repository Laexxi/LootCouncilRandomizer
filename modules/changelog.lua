local ADDON_NAME, ns = ...
ns.changelog = {}

function ns.changelog:GetOptions()
    local options = {
        name = "Changelog",
        type = "group",
        args = {
            changelogContent = {
                type = "description",
                name = ns.changelog:GetChangelogText(),
                fontSize = "medium",
            },
        },
    }
    return options
end

function ns.changelog:GetChangelogText()
    local changelog = {
        "|cffffd700Version 1.4.2|r",
        "|cff00ff00- Prepare addition of Sync Settings.|r",
        "|cff00ff00- Prepare addition of Curated Mode and Show forced Players.|r",
        "",
        "|cffffd700Version 1.4.1|r",
        "|cff00ff00- Bugfixes.|r",
        "",
        "|cffffd700Version 1.4.0|r",
        "|cff00ff00- Add possibility to set Timestamp in Officer Note.|r",
        "|cff00ff00- Add possibility to Debug Council roll and ignote min Members.|r",
        "",
        "|cffffd700Version 1.3.1|r",
        "|cff00ff00- Bugfix: Statistics always showed 'never'.|r",
        "",
        "|cffffd700Version 1.3.0|r",
        "|cff00ff00- Added Logging.|r",
        "",
        "|cffffd700Version 1.2.0|r",
        "|cff00ff00- Added Sync Settings tab.|r",
        "|cff00ff00- Added Changelog.|r",
        "",
        "|cffffd700Version 1.1.0|r",
        "|cff00ff00- Added new features.|r",
        "|cff00ff00- Fixed bugs.|r",
        "",
        "|cffffd700Version 1.0.0|r",
        "|cff00ff00- Initial release.|r",
    }
    return table.concat(changelog, "\n")
end
