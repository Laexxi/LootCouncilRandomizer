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

-- Colours:

-- |cffffd700 : Gold -> Titel and versionnumber
-- |cff00ff00 : Green -> New Features
-- |cffff0000 : Red -> Bugfixes
-- |cff00bfff : Blue -> Changes, Redesign
-- |cffa020f0 : Violett -> NOT USED YET

function ns.changelog:GetChangelogText()
    local changelog = {
        "|cffffd700Version 1.6.1|r",
        "|cffff0000- Sync should work now. If you try to sync settings and statistics right after, you need to reload you UI.|r",
        "|cff00bfff- Added the Version in the title.|r",
        "",
        "|cffffd700Version 1.6.0|r",
        "|cff00bfff- Code Refactoring and Cleanup.|r",
        "|cff00ff00- Trying to add Sync, but still bugged and does not work.|r",
        "",
        "|cffffd700Version 1.5.2|r",
        "|cff00bfff- Redesign of Statistics window.|r",
        "|cff00bfff- Redesign of Sync window.|r",
        "|cff00ff00- Added safety checks before resetting Statistics.|r",
        "|cffff0000- Small Bugfixes and Typos.|r",
        "",
        "|cffffd700Version 1.5.1|r",
        "|cff00ff00- Added possibility to simulate council roll without raid (Debugging).|r",
        "|cffff0000- Bugfixes.|r",
        "",
        "|cffffd700Version 1.5.0|r",
        "|cff00bfff- Removed the functionality to force players in the council.|r",
        "|cff00bfff- Removed the functionality to exclude players from the council.|r",
        "|cff00bfff- Both functionalities are removed because of ethical issues I do have with the possible misuse of these possibilities.|r",
        "",
        "|cffffd700Version 1.4.3|r",
        "|cff00ff00- Added the possibility to show forced players.|r",
        "|cffff0000- Fixed a bug that forced players are not chosen at the council.|r",
        "|cff00bfff- Redesign of the changelog.|r",
        "",
        "|cffffd700Version 1.4.2|r",
        "|cff00ff00- Prepared addition of Sync Settings.|r",
        "|cff00ff00- Prepared addition of Curated Mode and Show forced Players.|r",
        "",
        "|cffffd700Version 1.4.1|r",
        "|cffff0000- Bugfixes.|r",
        "",
        "|cffffd700Version 1.4.0|r",
        "|cff00ff00- Added possibility to set Timestamp in Officer Note.|r",
        "|cff00ff00- Added possibility to Debug Council roll and ignore min Members.|r",
        "",
        "|cffffd700Version 1.3.1|r",
        "|cffff0000- Bugfix: Statistics always showed 'never'.|r",
        "",
        "|cffffd700Version 1.3.0|r",
        "|cff00bfff- Added Logging.|r",
        "",
        "|cffffd700Version 1.2.0|r",
        "|cff00ff00- Added Sync Settings tab.|r",
        "|cff00bfff- Added Changelog.|r",
        "",
        "|cffffd700Version 1.1.0|r",
        "|cff00ff00- Added new features.|r",
        "|cffff0000- Fixed bugs.|r",
        "",
        "|cffffd700Version 1.0.0|r",
        "|cff00ff00- Initial release.|r",
    }
    return table.concat(changelog, "\n")
end
