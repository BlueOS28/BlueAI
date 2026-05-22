--[[
    Advanced UUID Validator for Standard Lua
    Supports:
    - RFC 4122 validation
    - Version checking (1-5)
    - Variant validation
    - Nil UUID detection
    - Detailed error reporting
    
    Usage:
    local UUID = require("uuidvalidator")
    
    local valid, info = UUID.validate("550e8400-e29b-41d4-a716-446655440000")
    if valid then
        print("Valid UUID v" .. info.version)
    end
    
    -- With options
    local valid = UUID.validate(uuid, {version = 4, disallowNil = true})
]]

local UUID = {}

UUID.NULL = "00000000-0000-0000-0000-000000000000"

-- Pre-computed hex character lookup table (much faster than regex matching)
local hexChars = {
    ['0']=true, ['1']=true, ['2']=true, ['3']=true, ['4']=true,
    ['5']=true, ['6']=true, ['7']=true, ['8']=true, ['9']=true,
    ['a']=true, ['b']=true, ['c']=true, ['d']=true, ['e']=true, ['f']=true,
    ['A']=true, ['B']=true, ['C']=true, ['D']=true, ['E']=true, ['F']=true,
}

-- Hex validation with O(1) lookup instead of regex
local function isHex(char)
    return hexChars[char] ~= nil
end

-- Validate UUID structure manually (faster + stricter)
local function validateStructure(uuid)
    if type(uuid) ~= "string" then
        return false, "UUID must be a string"
    end

    if #uuid ~= 36 then
        return false, "UUID length must be 36 characters"
    end

    -- Dash positions in standard UUID format: 8-4-4-4-12
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

-- Extract UUID version (more defensive)
function UUID.getVersion(uuid)
    if type(uuid) ~= "string" or #uuid < 15 then
        return nil
    end
    local versionChar = uuid:sub(15, 15)
    local version = tonumber(versionChar, 16)
    return version
end

-- Extract variant (more defensive)
function UUID.getVariant(uuid)
    if type(uuid) ~= "string" or #uuid < 20 then
        return "Unknown"
    end
    
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

-- Main validation function with comprehensive error handling
function UUID.validate(uuid, options)
    options = options or {}

    local ok, err = validateStructure(uuid)
    if not ok then
        return false, err
    end

    local version = UUID.getVersion(uuid)

    -- RFC 4122 versions are 1-5
    if not version or version < 1 or version > 5 then
        return false, ("Invalid UUID version: %s"):format(version or "nil")
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
        return false, ("Expected UUID version %d, got %d"):format(options.version, version)
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

-- Pretty print info (improved with better formatting and return value)
function UUID.inspect(uuid)
    local valid, info = UUID.validate(uuid)

    if not valid then
        print("Invalid UUID: " .. info)
        return false
    end

    print("UUID: " .. uuid)
    print("Version: " .. info.version)
    print("Variant: " .. info.variant)
    print("Nil UUID: " .. tostring(info.isNil))
    return true
end

-- Test suite for validation
function UUID.runTests()
    local tests = {
        {uuid = "550e8400-e29b-41d4-a716-446655440000", valid = true, desc = "Valid UUID v4"},
        {uuid = "00000000-0000-0000-0000-000000000000", valid = true, desc = "Nil UUID"},
        {uuid = "invalid-uuid-format", valid = false, desc = "Invalid format"},
        {uuid = "550e8400-e29b-61d4-a716-446655440000", valid = false, desc = "Wrong variant"},
        {uuid = "550e8400-e29b-41d4-z716-446655440000", valid = false, desc = "Invalid hex char"},
        {uuid = "550e8400-e29b-41d4-a71-446655440000", valid = false, desc = "Too short"},
        {uuid = 12345, valid = false, desc = "Not a string"},
    }
    
    local passed = 0
    local failed = 0
    
    for _, test in ipairs(tests) do
        local valid = UUID.isValid(test.uuid)
        if valid == test.valid then
            passed = passed + 1
            print("✓ PASS: " .. test.desc)
        else
            failed = failed + 1
            print("✗ FAIL: " .. test.desc .. " (expected " .. tostring(test.valid) .. ", got " .. tostring(valid) .. ")")
        end
    end
    
    print(("\nTests: %d passed, %d failed"):format(passed, failed))
    return failed == 0
end

return UUID
