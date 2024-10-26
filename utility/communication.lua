local ADDON_NAME, ns = ...
ns.utility = ns.utility or {}
local utility = ns.utility
local debug = ns.debug

local AceSerializer = LibStub("AceSerializer-3.0")
local LibCompress = LibStub:GetLibrary("LibCompress")
local LibCompressEncoder = LibCompress:GetAddonEncodeTable()

-- Funktion zur Serialisierung von Daten
function utility:SerializeData(data)
    local serialized, err = AceSerializer:Serialize(data)
    if not serialized then
        debug:DebugPrint("Communication", "Serialization failed: " .. tostring(err))
        return nil
    end
    local compressed = LibCompress:Compress(serialized)
    local encoded = LibCompressEncoder:Encode(compressed)
    return encoded
end

-- Funktion zur Deserialisierung von Daten
function utility:DeserializeData(data)
    local decoded = LibCompressEncoder:Decode(data)
    if not decoded then
        debug:DebugPrint("Communication", "Decoding failed")
        return false, "Decoding failed"
    end
    local decompressed, decompressedMessage = LibCompress:Decompress(decoded)
    if not decompressed then
        debug:DebugPrint("Communication", "Decompression failed: " .. tostring(decompressedMessage))
        return false, "Decompression failed: " .. tostring(decompressedMessage)
    end
    local success, deserialized = AceSerializer:Deserialize(decompressed)
    if not success then
        debug:DebugPrint("Communication", "Deserialization failed")
        return false, "Deserialization failed"
    end
    return true, deserialized
end

return utility
