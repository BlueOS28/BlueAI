local HttpService = game:GetService("HttpService")

-- CONFIGURATION


local memory = {}




function memory.saveInstance(fb, thing, json, user)
  local FIREBASE_URL = fb
  -- FUNCTION: Save Data to Firebase
local function saveToFirebase(path, data)
	local url = FIREBASE_URL .. path .. ".json"
	local success, jsonString = pcall(function() return HttpService:JSONEncode(data) end)
	if not success then return false end
	
	local httpSuccess, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "PUT",
			Headers = { ["Content-Type"] = "application/json" },
			Body = jsonString
		})
	end)
	return httpSuccess and response.StatusCode == 200
end

	-- Check if 'json' is a table list, and 'user' is a string name/ID
	if type(json) == "table" and type(user) == "string" then
		
		-- Look for the user inside the json allowed list
		local userIndex = table.find(json, user)
		
		if userIndex then
			-- json[userIndex] gives us the actual name string (e.g., "User_99999")
			local userName = json[userIndex] 
			print(userName .. " runned this instance and saving data")
			
			-- Construct the dynamic saving path for Firebase
			-- Example Path: "Player_Backups/User_99999"
			local ip = "Player_Backups/" .. userName
			
			-- Execute the save to the server
			if ip then
				local saveSuccess = saveToFirebase(ip, thing)
				
				if saveSuccess then
					print("Successfully backed up data for " .. userName)
				else
					warn("Failed to save data to Firebase server.")
				end
			end
		else
			warn("User '" .. tostring(user) .. "' was not found in the allowed json table.")
		end
	else
		warn("Invalid arguments passed to saveInstance. Expected (table, table, string)")
	end
end

return memory
