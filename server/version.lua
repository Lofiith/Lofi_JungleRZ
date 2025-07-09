local currentVersion = "2.0.1"
local resourceName = GetCurrentResourceName()
local versionCheckUrl = "https://raw.githubusercontent.com/Lofiith/Lofi_VersionCheck/main/JungleRZ.txt"

local function checkVersion()
    PerformHttpRequest(versionCheckUrl, function(statusCode, response, headers)
        if statusCode == 200 and response then
            local latestVersion = response:match("([^\r\n]+)") -- grab first line from the response

            if currentVersion == latestVersion then
                print("^2[" .. resourceName .. "]^7 is running the latest version (^2v" .. currentVersion .. "^7)")
            else
                print("^1[" .. resourceName .. "]^7 is outdated! Current: ^1v" .. currentVersion .. "^7 | Latest: ^2v" .. latestVersion .. "^7")
            end
        else
            print("^1[" .. resourceName .. "]^7 Failed to check version. HTTP status: " .. tostring(statusCode))
        end
    end, "GET", "", {
        ["User-Agent"] = "FiveM-Script-Version-Checker"
    })
end

CreateThread(function()
    Wait(2000)
    checkVersion()
end)
