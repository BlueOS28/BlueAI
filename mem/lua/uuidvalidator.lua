--[[
    Advanced UUID Validator for Standard Lua
    Supports:
    - RFC 4122 validation
    - Version checking (1-5)
    - Variant validation
    - Nil UUID detection
    - Detailed error reporting
]]

local UUID = {}

UUID.NULL = "00000000-0000-0000-0000-000000000000"

-- Hex lookup for speed
local function isHex(char)
    return char:match("[%da-fA-F]") ~= nil
end

-- Validate UUID structure manually (faster + stricter)
local function validateStructure(uuid)
    if type(uuid) ~= "string" then
        return false, "UUID must be a string"
    end

    if #uuid ~= 36 then
        return false, "UUID length must be 36 characters"
    end

    local dashPositions = {
        [9] = true,
        [14] = true,
        [19] = true,
        [24] = true
    }

    for i = 1, 36 do
        local c = uuid:sub(i, i)

        if dashPositions[i] then
            if c ~= "-" then
                return false, ("Missing dash at position %d"):format(i)
            end
        else
            if not isHex(c) then
                return false, ("Invalid hex character '%s' at position %d"):format(c, i)
            end
        end
    end

    return true
end

-- Extract UUID version
function UUID.getVersion(uuid)
    local versionChar = uuid:sub(15, 15)
    return tonumber(versionChar, 16)
end

-- Extract variant
function UUID.getVariant(uuid)
    local variantChar = uuid:sub(20, 20):lower()

    if variantChar:match("[89ab]") then
        return "RFC4122"
    elseif variantChar:match("[cd]") then
        return "Microsoft"
    elseif variantChar == "7" then
        return "Future"
    else
        return "Unknown"
    end
end

-- Check if UUID is nil UUID
function UUID.isNil(uuid)
    return uuid == UUID.NULL
end

-- Main validation function
function UUID.validate(uuid, options)
    options = options or {}

    local ok, err = validateStructure(uuid)
    if not ok then
        return false, err
    end

    local version = UUID.getVersion(uuid)

    -- RFC 4122 versions are 1-5
    if version < 1 or version > 5 then
        return false, ("Invalid UUID version: %d"):format(version)
    end

    local variant = UUID.getVariant(uuid)

    if variant ~= "RFC4122" then
        return false, ("Invalid UUID variant: %s"):format(variant)
    end

    -- Optional strict checks
    if options.disallowNil and UUID.isNil(uuid) then
        return false, "Nil UUID is not allowed"
    end

    if options.version and version ~= options.version then
        return false, ("Expected UUID version %d, got %d")
            :format(options.version, version)
    end

    return true, {
        version = version,
        variant = variant,
        isNil = UUID.isNil(uuid)
    }
end

-- Convenience function
function UUID.isValid(uuid)
    return UUID.validate(uuid)
end

-- Pretty print info
function UUID.inspect(uuid)
    local valid, info = UUID.validate(uuid)

    if not valid then
        print("Invalid UUID:", info)
        return
    end

    print("UUID:", uuid)
    print("Version:", info.version)
    print("Variant:", info.variant)
    print("Nil UUID:", info.isNil)
end

return UUID
