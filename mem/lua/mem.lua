-- Dependencies (Ensure you ran: luarocks install luasec dkjson)
local https = require("ssl.https")
local jsonLib = require("dkjson")
local ltn12 = require("ltn12")

local memory = {}

-- ==========================================
-- INTERNAL HELPER: HTTP REQUEST HANDLER
-- ==========================================
local function firebaseRequest(url, method, data)
    local response_body = {}
    local headers = {
        ["Content-Type"] = "application/json"
    }
    
    local source = nil
    if data ~= nil then
        local success, jsonString = pcall(function() return jsonLib.encode(data) end)
        if not success then 
            return false, "JSON Encoding Failed" 
        end
        source = ltn12.source.string(jsonString)
        headers["Content-Length"] = tostring(#jsonString)
    end

    local success_req, status_code, _, _ = https.request({
        url = url,
        method = method,
        headers = headers,
        source = source,
        sink = ltn12.sink.table(response_body)
    })
    
    local response_text = table.concat(response_body)
    
    if success_req and (status_code == 200 or status_code == 204) then
        return true, response_text
    else
        return false, "HTTP Error " .. tostring(status_code) .. ": " .. response_text
    end
end

-- ==========================================
-- INTERNAL HELPER: TABLE.FIND FOR STANDARD LUA
-- ==========================================
local function findInTable(tbl, target)
    for index, value in ipairs(tbl) do
        if value == target then
            return index
        end
    end
    return nil
end

-- ==========================================
-- PUBLIC METHODS
-- ==========================================

-- 1. SAVE/UPDATE DATA (PUT)
function memory.saveInstance(fb, thing, json, user)
    if type(json) ~= "table" or type(user) ~= "string" then
        print("WARNING: Invalid arguments passed to saveInstance.")
        return false
    end
    
    local userIndex = findInTable(json, user)
    if userIndex then
        local userName = json[userIndex]
        print(userName .. " initiated save instance...")
        
        local url = fb .. "Player_Backups/" .. userName .. ".json"
        local success, err = firebaseRequest(url, "PUT", thing)
        
        if success then
            print("Successfully backed up data for " .. userName)
            return true
        else
            print("WARNING: Save failed -> " .. err)
        end
    else
        print("WARNING: User '" .. user .. "' is unauthorized.")
    end
    return false
end

-- 2. LOAD/FETCH DATA (GET)
function memory.loadInstance(fb, json, user)
    if type(json) ~= "table" or type(user) ~= "string" then
        print("WARNING: Invalid arguments passed to loadInstance.")
        return nil
    end

    local userIndex = findInTable(json, user)
    if userIndex then
        local userName = json[userIndex]
        local url = fb .. "Player_Backups/" .. userName .. ".json"
        
        local success, response_text = firebaseRequest(url, "GET", nil)
        
        if success then
            if response_text == "null" or response_text == "" then
                print("No data found for " .. userName)
                return nil
            end
            
            local decodeSuccess, decodedData = pcall(function() return jsonLib.decode(response_text) end)
            if decodeSuccess then
                return decodedData
            else
                print("WARNING: Failed to decode retrieved data.")
            end
        else
            print("WARNING: Load failed -> " .. response_text)
        end
    else
        print("WARNING: User '" .. user .. "' is unauthorized to load data.")
    end
    return nil
end

-- 3. DELETE DATA (DELETE)
function memory.deleteInstance(fb, json, user)
    if type(json) ~= "table" or type(user) ~= "string" then
        print("WARNING: Invalid arguments passed to deleteInstance.")
        return false
    end

    local userIndex = findInTable(json, user)
    if userIndex then
        local userName = json[userIndex]
        local url = fb .. "Player_Backups/" .. userName .. ".json"
        
        local success, err = firebaseRequest(url, "DELETE", nil)
        if success then
            print("Successfully deleted data for " .. userName)
            return true
        else
            print("WARNING: Delete failed -> " .. err)
        end
    end
    return false
end

return memory
