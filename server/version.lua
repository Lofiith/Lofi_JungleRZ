local currentVersion = "2.0.0" 
local resourceName = GetCurrentResourceName()
local githubRepo = "YourGitHubUsername/jungle-rz"

local function checkVersion()
    local versionCheckUrl = string.format("https://api.github.com/repos/%s/releases/latest", githubRepo)
    
    PerformHttpRequest(versionCheckUrl, function(statusCode, response, headers)
        if statusCode == 200 then
            local data = json.decode(response)
            if data and data.tag_name then
                local latestVersion = data.tag_name:gsub("^v", "")
                
                if currentVersion == latestVersion then
                    print("^2[" .. resourceName .. "]^7 is running the latest version (^2v" .. currentVersion .. "^7)")
                else
                    print("^1[" .. resourceName .. "]^7 is outdated! Current: ^1v" .. currentVersion .. "^7 | Latest: ^2v" .. latestVersion .. "^7")
                end
            end
        end
    end, "GET", "", {
        ["User-Agent"] = "FiveM-Script-Version-Checker"
    })
end

-- Check version on resource start
CreateThread(function()
    Wait(2000) 
    checkVersion()
end)
