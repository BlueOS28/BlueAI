local memory = {}

-- 1. CUSTOM JSON ENGINE
local function customJSONEncode(tbl)
    local t = type(tbl)
    if t == "table" then
        local isArray = (#tbl > 0)
        local parts = {}
        if isArray then
            for _, v in ipairs(tbl) do table.insert(parts, customJSONEncode(v)) end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, v in pairs(tbl) do table.insert(parts, string.format('"%s":%s', tostring(k), customJSONEncode(v))) end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    elseif t == "string" then return string.format('"%s"', tbl:gsub('"', '\\"'))
    elseif t == "number" or t == "boolean" then return tostring(tbl)
    else return "null" end
end

-- 2. CUSTOM HTTP ENGINE (Uses native system cURL)
local function customFirebaseRequest(url, method, data)
    local command
    if data then
        local jsonString = customJSONEncode(data)
        -- Protect quotes for system command execution
        local escapedData = jsonString:gsub('"', '\\"')
        command = string.format('curl -s -X %s -H "Content-Type: application/json" -d "%s" "%s"', method, escapedData, url)
    else
        command = string.format('curl -s -X %s "%s"', method, url)
    end
    
    local handle = io.popen(command)
    if not handle then return false, "cURL Execution Error" end
    local result = handle:read("*a")
    handle:close()
    return true, result
end

local function findInTable(tbl, target)
    for index, value in ipairs(tbl) do
        if value == target then return index end
    end
    return nil
end

-- 3. CORE SAVE INSTANCE
function memory.saveInstance(fb, thing, json, user)
    if type(json) ~= "table" or type(user) ~= "string" then
        print("WARNING: Invalid arguments passed.")
        return false
    end
    
    local userIndex = findInTable(json, user)
    if userIndex then
        local userName = json[userIndex]
        print(userName .. " saving via custom engine...")
        
        local url = fb .. "Player_Backups/" .. userName .. ".json"
        local success, response = customFirebaseRequest(url, "PUT", thing)
        
        if success then
            print("Successfully saved custom instance for " .. userName)
            return true
        else
            print("WARNING: Custom save failed -> " .. tostring(response))
        end
    else
        print("WARNING: User unauthorized.")
    end
    return false
end

return memory
