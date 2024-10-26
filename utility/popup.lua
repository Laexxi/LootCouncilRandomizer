local ADDON_NAME, ns = ...
ns.utility = ns.utility or {}
local utility = ns.utility

-- Funktion zur Erstellung eines generischen Popup-Dialogs
function utility:CreatePopup(name, text, button1, button2, onAccept, onCancel, ...)
    if not StaticPopupDialogs[name] then
        StaticPopupDialogs[name] = {
            text = text,
            button1 = button1,
            button2 = button2,
            OnAccept = onAccept,
            OnCancel = onCancel,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            ... -- Zusätzliche Optionen können übergeben werden
        }
    end
    StaticPopup_Show(name)
end

return utility
