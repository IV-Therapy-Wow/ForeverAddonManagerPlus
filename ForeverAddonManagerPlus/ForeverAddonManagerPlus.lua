local ADDON_NAME = ...

local VERSION = "1.0.6"
local ADDON_FOLDER = ADDON_NAME or "ForeverAddonManagerPlus"

local LOCATION_TYPES = {
    { key = "world", label = "World" },
    { key = "city", label = "City" },
    { key = "instance", label = "Instance" },
    { key = "raid", label = "Raid" },
    { key = "battleground", label = "Battleground" },
    { key = "arena", label = "Arena" },
    { key = "tram", label = "Tram" },
    { key = "scenario", label = "Scenario" },
    { key = "other", label = "Other" },
}

local LOCATION_LABELS = {}
for _, item in ipairs(LOCATION_TYPES) do
    LOCATION_LABELS[item.key] = item.label
end

local ROLE_TYPES = {
    { key = "DPS", label = "DPS" },
    { key = "Healer", label = "Healer" },
    { key = "Tank", label = "Tank" },
    { key = "Support", label = "Support" },
}

local CITY_ZONES = {
    ["stormwind city"] = true,
    ["orgrimmar"] = true,
    ["ironforge"] = true,
    ["darnassus"] = true,
    ["undercity"] = true,
    ["thunder bluff"] = true,
    ["silvermoon city"] = true,
    ["the exodar"] = true,
    ["shattrath city"] = true,
    ["dalaran"] = true,
    ["valdrakken"] = true,
    ["dornogal"] = true,
}

-- The Tram has used more than one map ID across clients.
local TRAM_INSTANCE_ID = 369
local TRAM_UI_MAP_ID = 499

local DEFAULT_IDLE_ALPHA = 0.35
local MINIMAP_FADE_DELAY = 2.0
local MINIMAP_FADE_SPEED = 1.8
local MINIMAP_BUTTON_SIZE = 32
local MINIMAP_BUTTON_RADIUS_OFFSET = 5
local MINIMAP_ICON = "Interface\\AddOns\\ForeverAddonManagerPlus\\Textures\\ForeverAddonManagerPlusIcon"
local NEBULA_BACKGROUND = "Interface\\AddOns\\ForeverAddonManagerPlus\\Textures\\NebulaBackground"

local db
local panel
local minimapButton
local CreateMinimapButton
local TryCreateMinimapButton
local TryCreatePanel
local panelCreationError
local minimapRetryElapsed = 0
local minimapRetryErrorShown = false
local minimapPositionTicker
local activeLocation = "world"
local activePage = "world"
local currentLocation = nil
local currentLocationName = "Unknown"
local installedAddons = {}
local addonRows = {}
local draft = { addons = {}, settings = {} }
local pendingNavigation
local unsavedDialog
local deleteDialog
local reloadPromptOpen = false
local pendingApplication = false
local pendingReload = false
local pendingReloadReason = nil
local pendingRoleApplication = false
local roleApplyChoicePending = false
local pendingRoleApplyReason = nil
local internalHide = false
local preserveDraftOnShow = false
local uiReady = false
local roleDropdown
local RefreshRoleDropdown
local showMissingCheck
local profileDropdown
local profileNameBox
local listContent
local listScroll
local footerStatus
local currentLocationText
local activeRulesetIndicator
local currentProfileText
local saveButton
local discardButton
local reloadButton
local tabButtons = {}
local toggleAddonsButton
local manualAddonBox
local locationContent
local settingsContent
local showMinimapButtonCheck
local showTooltipAddonsCheck
local showTooltipRoleCheck
local showTooltipAddonsLabel
local showTooltipRoleLabel
local settingsHint
local RefreshSettingsPage

local ApplyLocationProfile
local IsDraftDirty
local RefreshAddonList
local RefreshLocationHeader
local RefreshProfileDropdown
local RefreshCopyProfileDropdown
local ShowSyncDialog
local CopySettingsFromTab
local SyncCurrentTabFromBlizzard
local SyncAllTabsFromBlizzard
local ShowSetupPrompt
local sessionHasSavedChange = false
local setupPromptShownThisSession = false
local copyProfileDropdown
local syncDialog
local syncConfirmDialog

local function Print(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cffd8a64bForeverAddonManagerPlus:|r " .. tostring(message))
    end
end

local function SafeCall(func, ...)
    if type(func) ~= "function" then
        return false, nil
    end
    local ok, a, b, c, d, e, f = pcall(func, ...)
    if not ok then
        return false, nil, a
    end
    return true, a, b, c, d, e, f
end

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = DeepCopy(item)
    end
    return result
end

local function Trim(value)
    value = tostring(value or "")
    return (value:gsub("^%s*(.-)%s*$", "%1"))
end

local function GetPlayerName()
    if type(UnitName) == "function" then
        local ok, name = pcall(UnitName, "player")
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end
    return nil
end

local function IsInCombatLockdownSafe()
    if type(InCombatLockdown) ~= "function" then
        return false
    end
    local ok, value = pcall(InCombatLockdown)
    return ok and value == true
end

local function GetTimeSafe()
    if type(GetTime) == "function" then
        local ok, value = pcall(GetTime)
        if ok and type(value) == "number" then
            return value
        end
    end
    return 0
end

local function GetAddonCount()
    if C_AddOns and type(C_AddOns.GetNumAddOns) == "function" then
        local ok, count = pcall(C_AddOns.GetNumAddOns)
        if ok and type(count) == "number" then
            return count
        end
    end
    if type(GetNumAddOns) == "function" then
        local ok, count = pcall(GetNumAddOns)
        if ok and type(count) == "number" then
            return count
        end
    end
    return 0
end

local function GetAddonFolderName(index)
    if C_AddOns and type(C_AddOns.GetAddOnName) == "function" then
        local ok, name = pcall(C_AddOns.GetAddOnName, index)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end
    if type(GetAddOnInfo) == "function" then
        local ok, name = pcall(GetAddOnInfo, index)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end
    return nil
end

local function GetAddonTitle(folderName, index)
    if C_AddOns and type(C_AddOns.GetAddOnTitle) == "function" then
        local ok, title = pcall(C_AddOns.GetAddOnTitle, folderName)
        if ok and type(title) == "string" and title ~= "" then
            return title
        end
    end
    if C_AddOns and type(C_AddOns.GetAddOnInfo) == "function" then
        local ok, _, title = pcall(C_AddOns.GetAddOnInfo, folderName)
        if ok and type(title) == "string" and title ~= "" then
            return title
        end
    end
    if type(GetAddOnInfo) == "function" and index then
        local ok, _, title = pcall(GetAddOnInfo, index)
        if ok and type(title) == "string" and title ~= "" then
            return title
        end
    end
    return folderName
end

local function GetAddonLookupIdentifier(folderName, addonIndex)
    if type(folderName) == "string" and folderName:lower():match("^blizzard_") then
        return folderName
    end
    if type(addonIndex) == "number" then
        return addonIndex
    end
    local installed = installedAddons[folderName]
    return installed and installed.index or folderName
end

local function GetAddonEnabled(folderName, addonIndex)
    local addon = GetAddonLookupIdentifier(folderName, addonIndex)
    local character = GetPlayerName()
    if not addon or not character then
        return nil
    end

    local allEnabledState = 2
    if Enum and Enum.AddOnEnableState and type(Enum.AddOnEnableState.All) == "number" then
        allEnabledState = Enum.AddOnEnableState.All
    end

    if C_AddOns and type(C_AddOns.GetAddOnEnableState) == "function" then
        local ok, state = pcall(C_AddOns.GetAddOnEnableState, addon, character)
        if ok and type(state) == "number" then
            -- Match Blizzard's checkbox for this character, not an enable setting shared with other characters.
            return state >= allEnabledState
        end
    end

    if type(GetAddOnEnableState) == "function" then
        local ok, state = pcall(GetAddOnEnableState, character, addon)
        if ok and type(state) == "number" then
            return state >= allEnabledState
        end
    end
    return nil
end

local function IsAddonLoaded(folderName)
    if C_AddOns and type(C_AddOns.IsAddOnLoaded) == "function" then
        local ok, loadedOrLoading, loaded = pcall(C_AddOns.IsAddOnLoaded, folderName)
        if ok then
            if type(loaded) == "boolean" then
                return loaded
            end
            if type(loadedOrLoading) == "boolean" then
                return loadedOrLoading
            end
        end
    end
    if type(IsAddOnLoaded) == "function" then
        local ok, loadedOrLoading, loaded = pcall(IsAddOnLoaded, folderName)
        if ok then
            if type(loaded) == "boolean" then
                return loaded
            end
            if type(loadedOrLoading) == "boolean" then
                return loadedOrLoading
            end
        end
    end
    return nil
end

local function GetAddonLoadability(folderName, addonIndex)
    if not C_AddOns or type(C_AddOns.IsAddOnLoadable) ~= "function" then
        return nil, nil
    end
    local addon = GetAddonLookupIdentifier(folderName, addonIndex)
    local character = GetPlayerName()
    if not addon or not character then
        return nil, nil
    end
    local ok, loadable, reason = pcall(C_AddOns.IsAddOnLoadable, addon, character)
    if ok and type(loadable) == "boolean" then
        return loadable, reason
    end
    return nil, nil
end

local function IsManagerAddon(folderName)
    return type(folderName) == "string" and folderName:lower() == tostring(ADDON_FOLDER):lower()
end

local function IsBlizzardAddon(folderName)
    return type(folderName) == "string" and folderName:lower():match("^blizzard_") ~= nil
end

local function IsLockedAddon(folderName)
    return IsManagerAddon(folderName) or IsBlizzardAddon(folderName)
end

local function SetAddonEnabled(folderName, enabled)
    local character = GetPlayerName()
    if not character then
        return false, "Could not identify the current character; no addon state was changed."
    end
    if IsManagerAddon(folderName) then
        return false, "The manager cannot disable itself."
    end
    if IsBlizzardAddon(folderName) and not enabled then
        return false, "Blizzard UI addons cannot be disabled here."
    end

    local func
    if enabled then
        func = C_AddOns and C_AddOns.EnableAddOn or _G.EnableAddOn
    else
        func = C_AddOns and C_AddOns.DisableAddOn or _G.DisableAddOn
    end
    if type(func) ~= "function" then
        return false, "The client does not expose the addon enable/disable API."
    end

    local ok, result = pcall(func, folderName, character)
    if not ok then
        return false, tostring(result)
    end
    if result == false then
        return false, "The client rejected the request."
    end

    local actual = GetAddonEnabled(folderName)
    if actual ~= nil and actual ~= enabled then
        return false, "The client did not accept the requested state."
    end
    return true
end

local function HasSavedProfileChoices()
    local function storeHasChoices(store)
        if type(store) ~= "table" then
            return false
        end
        for _, locationData in pairs(store) do
            local profiles = type(locationData) == "table" and locationData.profiles or nil
            if type(profiles) == "table" then
                for _, profile in pairs(profiles) do
                    local addons = type(profile) == "table" and profile.addons or nil
                    if type(addons) == "table" then
                        for _, enabled in pairs(addons) do
                            if type(enabled) == "boolean" then
                                return true
                            end
                        end
                    end
                end
            end
        end
        return false
    end

    if storeHasChoices(db and db.locations) then
        return true
    end
    for _, classProfiles in pairs(db and db.classRoleProfiles or {}) do
        if type(classProfiles) == "table" then
            for _, roleProfile in pairs(classProfiles) do
                if type(roleProfile) == "table" and storeHasChoices(roleProfile.locations) then
                    return true
                end
            end
        end
    end
    return false
end

local function EnsureDatabase()
    if type(ForeverAddonManagerPlusDB) ~= "table" then
        ForeverAddonManagerPlusDB = {}
    end
    db = ForeverAddonManagerPlusDB
    local previousSchemaVersion = tonumber(db.schemaVersion) or 0
    if type(db.hasSavedAddonSettings) ~= "boolean" then
        db.hasSavedAddonSettings = HasSavedProfileChoices()
    end

    if type(db.addonRegistry) ~= "table" then
        db.addonRegistry = {}
    end
    if type(db.locations) ~= "table" then
        db.locations = {}
    end
    if type(db.classRoleProfiles) ~= "table" then
        db.classRoleProfiles = {}
    end
    if type(db.activeRoleByClass) ~= "table" then
        db.activeRoleByClass = {}
    end
    if type(db.minimap) ~= "table" then
        db.minimap = {}
    end
    db.minimap.angle = tonumber(db.minimap.angle) or 225
    db.minimap.angle = db.minimap.angle % 360
    db.minimap.hidden = db.minimap.hidden == true
    if previousSchemaVersion < 3 or type(db.minimap.showTooltipAddons) ~= "boolean" then
        db.minimap.showTooltipAddons = false
    end
    db.minimap.showTooltipRole = db.minimap.showTooltipRole ~= false
    db.minimap.idleAlpha = tonumber(db.minimap.idleAlpha) or DEFAULT_IDLE_ALPHA
    if db.minimap.idleAlpha < 0.15 then
        db.minimap.idleAlpha = 0.15
    elseif db.minimap.idleAlpha > 0.8 then
        db.minimap.idleAlpha = 0.8
    end
    db.schemaVersion = 4

    -- An addon may be reinstalled later, so keep its saved choices while it is missing.
    for _, location in ipairs(LOCATION_TYPES) do
        local key = location.key
        local locationData = db.locations[key]
        if type(locationData) ~= "table" then
            locationData = {}
            db.locations[key] = locationData
        end
        if type(locationData.profiles) ~= "table" then
            locationData.profiles = {}
        end
        if type(locationData.profiles.Default) ~= "table" then
            locationData.profiles.Default = { addons = {} }
        end
        if type(locationData.profiles.Default.addons) ~= "table" then
            locationData.profiles.Default.addons = {}
        end
        if type(locationData.activeProfile) ~= "string"
            or type(locationData.profiles[locationData.activeProfile]) ~= "table" then
            locationData.activeProfile = "Default"
        end
    end
end

local function ScanInstalledAddons()
    if not db then
        return
    end

    local seen = {}
    installedAddons = {}
    local count = GetAddonCount()
    for index = 1, count do
        local folderName = GetAddonFolderName(index)
        if folderName and not IsManagerAddon(folderName) then
            seen[folderName] = true
            local title = GetAddonTitle(folderName, index)
            local enabled = GetAddonEnabled(folderName, index)
            local registryEntry = db.addonRegistry[folderName]
            if type(registryEntry) ~= "table" then
                registryEntry = {}
                db.addonRegistry[folderName] = registryEntry
            end
            registryEntry.title = title or registryEntry.title or folderName
            registryEntry.folder = folderName
            registryEntry.installed = true
            registryEntry.lastSeen = date and date("%Y-%m-%d") or tostring(GetTimeSafe())
            registryEntry.blizzard = IsBlizzardAddon(folderName)

            local loaded = IsAddonLoaded(folderName)
            local loadable, loadReason = GetAddonLoadability(folderName, index)
            installedAddons[folderName] = {
                name = folderName,
                title = registryEntry.title,
                enabled = enabled,
                loaded = loaded,
                loadable = loadable,
                loadReason = loadReason,
                locked = IsLockedAddon(folderName),
                index = index,
            }

            -- Fill only empty profile entries: the first scan starts from Blizzard's settings, and later scans add new addons without replacing saved choices.
            if enabled ~= nil then
                local profileStores = { db.locations }
                for _, classProfiles in pairs(db.classRoleProfiles) do
                    if type(classProfiles) == "table" then
                        for _, roleProfile in pairs(classProfiles) do
                            if type(roleProfile) == "table" and type(roleProfile.locations) == "table" then
                                profileStores[#profileStores + 1] = roleProfile.locations
                            end
                        end
                    end
                end

                for _, store in ipairs(profileStores) do
                    for _, location in ipairs(LOCATION_TYPES) do
                        local locationData = store[location.key]
                        if type(locationData) == "table" and type(locationData.profiles) == "table" then
                            for profileName, profile in pairs(locationData.profiles) do
                                if type(profile) ~= "table" then
                                    profile = { addons = {} }
                                    locationData.profiles[profileName] = profile
                                end
                                if type(profile.addons) ~= "table" then
                                    profile.addons = {}
                                end
                                if profile.addons[folderName] == nil then
                                    profile.addons[folderName] = enabled
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for folderName, registryEntry in pairs(db.addonRegistry) do
        if type(registryEntry) == "table" then
            registryEntry.installed = seen[folderName] == true
            if not seen[folderName] then
                registryEntry.title = registryEntry.title or folderName
            end
        end
    end
end

local function EnsureProfileShape(profile)
    if type(profile) ~= "table" then
        profile = {}
    end
    if type(profile.addons) ~= "table" then
        profile.addons = {}
    end
    return profile
end

local function GetPlayerClass()
    if type(UnitClass) == "function" then
        local ok, localized, token = pcall(UnitClass, "player")
        if ok then
            return token or "UNKNOWN", localized or token or "Unknown class"
        end
    end
    return "UNKNOWN", "Unknown class"
end

local function GetActiveRole()
    if not db then
        return nil, "UNKNOWN", "Unknown class"
    end
    local classToken, className = GetPlayerClass()
    local role = db.activeRoleByClass[classToken]
    for _, item in ipairs(ROLE_TYPES) do
        if item.key == role then
            return role, classToken, className
        end
    end
    return nil, classToken, className
end

local function EnsureClassRoleProfile(role)
    local classToken = GetPlayerClass()
    if type(db.classRoleProfiles[classToken]) ~= "table" then
        db.classRoleProfiles[classToken] = {}
    end
    local profile = db.classRoleProfiles[classToken][role]
    if type(profile) ~= "table" then
        profile = { locations = DeepCopy(db.locations) }
        db.classRoleProfiles[classToken][role] = profile
    end
    if type(profile.locations) ~= "table" then
        profile.locations = DeepCopy(db.locations)
    end
    for _, location in ipairs(LOCATION_TYPES) do
        local locationData = profile.locations[location.key]
        if type(locationData) ~= "table" then
            local base = db.locations[location.key]
            locationData = DeepCopy(base or {})
            profile.locations[location.key] = locationData
        end
        if type(locationData.profiles) ~= "table" then
            locationData.profiles = {}
        end
        if type(locationData.profiles.Default) ~= "table" then
            locationData.profiles.Default = { addons = {} }
        end
        if type(locationData.profiles.Default.addons) ~= "table" then
            locationData.profiles.Default.addons = {}
        end
        if type(locationData.activeProfile) ~= "string"
            or type(locationData.profiles[locationData.activeProfile]) ~= "table" then
            locationData.activeProfile = "Default"
        end
    end
    return profile
end

local function GetLocationData(locationKey)
    if not db then
        return nil
    end
    local role, classToken = GetActiveRole()
    if role then
        local classProfiles = db.classRoleProfiles[classToken]
        local roleProfile = type(classProfiles) == "table" and classProfiles[role] or nil
        local roleLocations = type(roleProfile) == "table" and roleProfile.locations or nil
        local roleData = type(roleLocations) == "table" and roleLocations[locationKey] or nil
        if type(roleData) == "table" then
            return roleData
        end
    end
    local data = db.locations[locationKey]
    if type(data) ~= "table" then
        return nil
    end
    return data
end

local function GetActiveProfile(locationKey)
    local data = GetLocationData(locationKey)
    if not data then
        return nil
    end
    local name = data.activeProfile or "Default"
    local profile = data.profiles and data.profiles[name]
    if type(profile) ~= "table" then
        name = "Default"
        data.activeProfile = name
        profile = data.profiles[name]
    end
    if type(profile) ~= "table" then
        profile = { addons = {} }
        data.profiles[name] = profile
    end
    if type(profile.addons) ~= "table" then
        profile.addons = {}
    end
    return profile, name
end

local function GetZoneName()
    local candidates = { "GetRealZoneText", "GetZoneText", "GetSubZoneText" }
    for _, globalName in ipairs(candidates) do
        local func = _G[globalName]
        if type(func) == "function" then
            local ok, value = pcall(func)
            if ok and type(value) == "string" and value ~= "" then
                return value
            end
        end
    end
    return "Unknown area"
end

local function GetPlayerMapID()
    if C_Map and type(C_Map.GetBestMapForUnit) == "function" then
        local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
        if ok and type(mapID) == "number" then
            return mapID
        end
    end
    return nil
end

local function IsCityMap(mapID)
    if not mapID or not C_Map then
        return false
    end

    local current = mapID
    for _ = 1, 8 do
        if type(C_Map.IsCityMap) == "function" then
            local ok, value = pcall(C_Map.IsCityMap, current)
            if ok and value == true then
                return true
            end
        end

        if type(C_Map.GetMapInfo) ~= "function" then
            break
        end
        local ok, info = pcall(C_Map.GetMapInfo, current)
        if not ok or type(info) ~= "table" or type(info.parentMapID) ~= "number"
            or info.parentMapID <= 0 or info.parentMapID == current then
            break
        end
        current = info.parentMapID
    end
    return false
end

local function IsRestingSafe()
    if type(IsResting) ~= "function" then
        return false
    end
    local ok, value = pcall(IsResting)
    return ok and value == true
end

local function ContainsTramName(text)
    return type(text) == "string" and text:lower():find("tram", 1, true) ~= nil
end

local function DetectLocation()
    local zoneName = GetZoneName()
    local mapID = GetPlayerMapID()
    local instanceName, instanceType, difficultyID, difficultyName, maxPlayers,
        dynamicDifficulty, isDynamic, instanceID

    if type(GetInstanceInfo) == "function" then
        local ok
        ok, instanceName, instanceType, difficultyID, difficultyName, maxPlayers,
            dynamicDifficulty, isDynamic, instanceID = pcall(GetInstanceInfo)
        if not ok then
            instanceName, instanceType, instanceID = nil, nil, nil
        end
    end
    if not instanceType and type(IsInInstance) == "function" then
        local ok, inside, detectedType = pcall(IsInInstance)
        if ok and inside and type(detectedType) == "string" then
            instanceType = detectedType
        end
    end

    local zoneLower = tostring(zoneName or ""):lower()
    local instanceLower = tostring(instanceName or ""):lower()

    -- Check the Tram before dungeons; the client can report it as a dungeon.
    if instanceID == TRAM_INSTANCE_ID or mapID == TRAM_UI_MAP_ID
        or ContainsTramName(zoneName) or ContainsTramName(instanceName) then
        return "tram", zoneName, instanceName, mapID, instanceID, instanceType
    end

    if instanceType == "party" then
        return "instance", zoneName, instanceName, mapID, instanceID, instanceType
    elseif instanceType == "raid" then
        return "raid", zoneName, instanceName, mapID, instanceID, instanceType
    elseif instanceType == "pvp" then
        return "battleground", zoneName, instanceName, mapID, instanceID, instanceType
    elseif instanceType == "arena" then
        return "arena", zoneName, instanceName, mapID, instanceID, instanceType
    elseif instanceType == "scenario" then
        return "scenario", zoneName, instanceName, mapID, instanceID, instanceType
    elseif instanceType and instanceType ~= "" and instanceType ~= "none" then
        return "other", zoneName, instanceName, mapID, instanceID, instanceType
    end

    if CITY_ZONES[zoneLower] or CITY_ZONES[instanceLower] or IsCityMap(mapID) or IsRestingSafe() then
        return "city", zoneName, instanceName, mapID, instanceID, instanceType
    end

    return "world", zoneName, instanceName, mapID, instanceID, instanceType
end

local function RefreshFooter()
    if not footerStatus then
        return
    end

    local dirty = IsDraftDirty()
    if dirty then
        footerStatus:SetText("|cffffcc66Changes not saved|r")
    elseif pendingReload then
        footerStatus:SetText("|cff80ff80All changes saved|r  |cffffcc66(reload required)|r")
    elseif pendingApplication then
        footerStatus:SetText("|cffffcc66Waiting for combat to end before applying profile|r")
    elseif roleApplyChoicePending then
        footerStatus:SetText("|cffffcc66Choose when to apply the selected role profile|r")
    elseif pendingRoleApplication then
        footerStatus:SetText("|cffffcc66Role profile will apply when settings close|r")
    elseif sessionHasSavedChange then
        footerStatus:SetText("|cff80ff80All changes saved|r")
    else
        footerStatus:SetText("")
    end

    if saveButton then
        saveButton:SetEnabled(dirty or (activePage ~= "settings" and db.hasSavedAddonSettings ~= true))
    end
    if discardButton then
        discardButton:SetEnabled(dirty)
    end
    if reloadButton then
        if pendingReload then
            reloadButton:Show()
        else
            reloadButton:Hide()
        end
    end
end

IsDraftDirty = function()
    if not uiReady then
        return false
    end
    if activePage == "settings" then
        local settings = draft.settings or {}
        return settings.minimapEnabled ~= (db.minimap.hidden ~= true)
            or settings.tooltipShowAddons ~= (db.minimap.showTooltipAddons == true)
            or settings.tooltipShowRole ~= (db.minimap.showTooltipRole ~= false)
    end
    local savedProfile = GetActiveProfile(activeLocation)
    local saved = savedProfile and savedProfile.addons or {}
    for name, value in pairs(saved) do
        if draft.addons[name] ~= value then
            return true
        end
    end
    for name, value in pairs(draft.addons) do
        if saved[name] ~= value then
            return true
        end
    end
    return false
end

local function LoadDraft()
    if activePage == "settings" then
        draft = {
            addons = {},
            settings = {
                minimapEnabled = db.minimap.hidden ~= true,
                tooltipShowAddons = db.minimap.showTooltipAddons == true,
                tooltipShowRole = db.minimap.showTooltipRole ~= false,
            },
        }
        if RefreshSettingsPage then
            RefreshSettingsPage()
        end
        return
    end
    local profile = GetActiveProfile(activeLocation)
    draft = { addons = DeepCopy(profile and profile.addons or {}), settings = {} }
end

local function SaveDraft(suppressApply)
    local wasDirty = IsDraftDirty()
    if activePage == "settings" then
        local settings = draft.settings or {}
        db.minimap.hidden = settings.minimapEnabled ~= true
        db.minimap.showTooltipAddons = settings.tooltipShowAddons == true
        db.minimap.showTooltipRole = settings.tooltipShowRole ~= false
        if minimapButton then
            if db.minimap.hidden then
                minimapButton:Hide()
            else
                minimapButton:Show()
                minimapButton:SetAlpha(1)
                minimapButton.lastHoverTime = GetTimeSafe()
            end
        end
        if wasDirty then
            sessionHasSavedChange = true
        end
        if RefreshSettingsPage then
            RefreshSettingsPage()
        end
        RefreshFooter()
        return true
    end

    local profile = GetActiveProfile(activeLocation)
    if not profile then
        return false
    end
    profile.addons = DeepCopy(draft.addons or {})
    db.hasSavedAddonSettings = true
    if wasDirty then
        sessionHasSavedChange = true
    end
    RefreshFooter()
    if not suppressApply and currentLocation == activeLocation then
        ApplyLocationProfile("saved profile")
    end
    return true
end

local function DiscardDraft()
    LoadDraft()
    if activePage == "settings" then
        if RefreshSettingsPage then
            RefreshSettingsPage()
        end
    else
        RefreshAddonList()
    end
    RefreshFooter()
end

local function ApplyDeferredRoleProfile()
    if not pendingRoleApplication then
        return
    end
    local reason = pendingRoleApplyReason or "role profile selected for settings close"
    pendingRoleApplication = false
    pendingRoleApplyReason = nil
    ApplyLocationProfile(reason, true)
end

local function ClosePanelNow()
    if not panel then
        return
    end
    ApplyDeferredRoleProfile()
    internalHide = true
    panel:Hide()
    internalHide = false
end

ShowSetupPrompt = function()
    if not db or db.hasSavedAddonSettings == true or setupPromptShownThisSession then
        return
    end
    setupPromptShownThisSession = true
    if type(StaticPopupDialogs) ~= "table" or type(StaticPopup_Show) ~= "function" then
        Print("Forever Addon Manager Plus+ is not yet configured. Save your settings to stop this message from appearing in the future.")
        return
    end
    StaticPopupDialogs["FAMP_SETUP_REQUIRED"] = {
        text = "Forever Addon Manager Plus+ is not yet configured.\n\nSave your settings to stop this dialog from loading in the future.",
        button1 = "Got It",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("FAMP_SETUP_REQUIRED")
end

local function CreateUnsavedDialog()
    if unsavedDialog then
        return
    end

    unsavedDialog = CreateFrame("Frame", "ForeverAddonManagerPlusUnsavedDialog", UIParent, "UIPanelDialogTemplate")
    unsavedDialog:SetSize(470, 170)
    unsavedDialog:SetPoint("CENTER")
    unsavedDialog:SetFrameStrata("DIALOG")
    unsavedDialog:SetFrameLevel(200)
    unsavedDialog:EnableMouse(true)
    unsavedDialog:Hide()

    unsavedDialog:SetScript("OnHide", function()
        if pendingNavigation then
            pendingNavigation = nil
        end
    end)

    local text = unsavedDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", unsavedDialog, "TOPLEFT", 24, -34)
    text:SetPoint("TOPRIGHT", unsavedDialog, "TOPRIGHT", -24, -34)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetText("You have unsaved changes on this page.\n\nIf you leave without saving, these addon selections will be lost. Save this page before continuing, discard its changes, or stay here to keep editing.")

    local save = CreateFrame("Button", nil, unsavedDialog, "UIPanelButtonTemplate")
    save:SetSize(138, 26)
    save:SetPoint("BOTTOMLEFT", unsavedDialog, "BOTTOMLEFT", 18, 18)
    save:SetText("Save Page & Continue")
    save:SetScript("OnClick", function()
        local action = pendingNavigation
        pendingNavigation = nil
        unsavedDialog:Hide()
        -- This route saves the page only; the caller decides when to apply its addon changes.
        SaveDraft(true)
        if action then
            action()
        end
    end)

    local discard = CreateFrame("Button", nil, unsavedDialog, "UIPanelButtonTemplate")
    discard:SetSize(138, 26)
    discard:SetPoint("LEFT", save, "RIGHT", 8, 0)
    discard:SetText("Discard & Continue")
    discard:SetScript("OnClick", function()
        local action = pendingNavigation
        pendingNavigation = nil
        unsavedDialog:Hide()
        DiscardDraft()
        if action then
            action()
        end
    end)

    local stay = CreateFrame("Button", nil, unsavedDialog, "UIPanelButtonTemplate")
    stay:SetSize(138, 26)
    stay:SetPoint("LEFT", discard, "RIGHT", 8, 0)
    stay:SetText("Stay Here")
    stay:SetScript("OnClick", function()
        pendingNavigation = nil
        unsavedDialog:Hide()
    end)
end

local function RequestNavigation(action)
    if not IsDraftDirty() then
        if action then
            action()
        end
        return
    end

    CreateUnsavedDialog()
    pendingNavigation = action
    unsavedDialog:Show()
end

local function ShowReloadPrompt()
    if reloadPromptOpen or not pendingReload then
        return
    end
    if IsInCombatLockdownSafe() then
        return
    end
    if type(StaticPopupDialogs) ~= "table" or type(StaticPopup_Show) ~= "function" then
        Print("Addon states have changed. Use the Reload UI button to finish applying them.")
        return
    end

    StaticPopupDialogs["FAMP_RELOAD_REQUIRED"] = {
        text = "ForeverAddonManagerPlus has changed addon enable states for the current location.\n\nA UI reload is required before those addons start or stop running.\n\nReload now?",
        button1 = "Reload Now",
        button2 = "Later",
        OnAccept = function()
            reloadPromptOpen = false
            if IsInCombatLockdownSafe() then
                Print("Reload is waiting for combat to end. Use the Reload UI button afterwards.")
                return
            end
            if type(ReloadUI) == "function" then
                ReloadUI()
            end
        end,
        OnCancel = function()
            reloadPromptOpen = false
            RefreshFooter()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    local shown = StaticPopup_Show("FAMP_RELOAD_REQUIRED")
    reloadPromptOpen = shown ~= nil
    RefreshFooter()
end

local function ShowRoleApplyPrompt(selectionLabel)
    pendingRoleApplication = false
    pendingRoleApplyReason = "class/role profile selected: " .. tostring(selectionLabel)
    roleApplyChoicePending = true

    if type(StaticPopupDialogs) ~= "table" or type(StaticPopup_Show) ~= "function" then
        roleApplyChoicePending = false
        pendingRoleApplication = true
        Print("Selected " .. tostring(selectionLabel) .. ". Its addon profile will be applied when you close the settings window.")
        RefreshFooter()
        return
    end

    StaticPopupDialogs["FAMP_ROLE_APPLY"] = {
        text = "You selected " .. tostring(selectionLabel) .. ".\n\nWould you like to apply this role's addon profile now, or wait until you close the addon settings?",
        button1 = "Apply Now",
        button2 = "When Closing",
        OnAccept = function()
            roleApplyChoicePending = false
            pendingRoleApplication = false
            local reason = pendingRoleApplyReason or "class/role profile selection"
            pendingRoleApplyReason = nil
            ApplyLocationProfile(reason, true)
        end,
        OnCancel = function()
            roleApplyChoicePending = false
            pendingRoleApplication = true
            Print("The selected role profile will be applied when you close the addon settings.")
            RefreshFooter()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = false,
        preferredIndex = 3,
    }

    local shown = StaticPopup_Show("FAMP_ROLE_APPLY")
    if not shown then
        roleApplyChoicePending = false
        pendingRoleApplication = true
        Print("Selected " .. tostring(selectionLabel) .. ". Its addon profile will be applied when you close the settings window.")
    end
    RefreshFooter()
end

ApplyLocationProfile = function(reason, force)
    if not db or not currentLocation then
        return
    end
    if not force and (roleApplyChoicePending or pendingRoleApplication) then
        pendingRoleApplyReason = pendingRoleApplyReason or reason or "role profile selection"
        RefreshFooter()
        return
    end
    if IsInCombatLockdownSafe() then
        pendingApplication = true
        pendingReloadReason = reason or "location change"
        RefreshFooter()
        return
    end

    pendingApplication = false
    local profile, profileName = GetActiveProfile(currentLocation)
    if not profile then
        return
    end

    local changedCount = 0
    local failures = {}
    for folderName, desired in pairs(profile.addons) do
        if type(desired) == "boolean" and installedAddons[folderName] and not IsLockedAddon(folderName) then
            local current = GetAddonEnabled(folderName)
            if current ~= nil and current ~= desired then
                local ok, err = SetAddonEnabled(folderName, desired)
                if ok then
                    changedCount = changedCount + 1
                    if installedAddons[folderName] then
                        installedAddons[folderName].enabled = desired
                    end
                else
                    failures[#failures + 1] = folderName .. ": " .. tostring(err)
                end
            end
        end
    end

    if C_AddOns and type(C_AddOns.SaveAddOns) == "function" then
        pcall(C_AddOns.SaveAddOns)
    end

    if changedCount > 0 then
        pendingReload = true
        pendingReloadReason = LOCATION_LABELS[currentLocation] .. " / " .. tostring(profileName)
        Print(tostring(changedCount) .. " addon state(s) staged for " .. pendingReloadReason .. ". A reload is required.")
        ShowReloadPrompt()
    end

    if #failures > 0 then
        Print(tostring(#failures) .. " addon state(s) could not be changed:")
        for index = 1, math.min(#failures, 8) do
            Print("  " .. failures[index])
        end
        if #failures > 8 then
            Print("  and " .. tostring(#failures - 8) .. " more.")
        end
    end

    if RefreshAddonList then
        RefreshAddonList()
    end
    RefreshFooter()
end

local function CheckLocation()
    if not db then
        return
    end

    local key, zoneName, instanceName = DetectLocation()
    currentLocationName = zoneName or instanceName or "Unknown area"

    if key ~= currentLocation then
        local previous = currentLocation
        currentLocation = key
        Print("Location type: " .. LOCATION_LABELS[key] .. " (" .. tostring(currentLocationName) .. ").")
        ApplyLocationProfile(previous and "location change" or "initial location")
        RefreshLocationHeader()
    elseif pendingApplication and not IsInCombatLockdownSafe() then
        ApplyLocationProfile(pendingReloadReason or "deferred location change")
    else
        RefreshLocationHeader()
    end
end

local function MakeButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 100, height or 24)
    button:SetText(text or "")
    return button
end

local function MakeLabel(parent, text, template)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    label:SetText(text or "")
    return label
end

local function AddonSort(a, b)
    local aTitle = (a.title or a.name):lower()
    local bTitle = (b.title or b.name):lower()
    if aTitle == bTitle then
        return a.name:lower() < b.name:lower()
    end
    return aTitle < bTitle
end

local function GetAddonRuntimePresentation(item)
    if not item.installed then
        return "Not installed • saved settings retained", 0.62, 0.66, 0.74
    end
    if item.loaded == true then
        if item.currentEnabled == false then
            return "Running • disabled for next load", 0.28, 1.0, 0.42
        end
        return "Running", 0.28, 1.0, 0.42
    end
    if item.loaded == false then
        if item.loadReason == "DEP_DISABLED" then
            return "Not running • dependency disabled", 1.0, 0.36, 0.36
        end
        return "Not running", 1.0, 0.36, 0.36
    end
    return "Current state unavailable", 0.68, 0.70, 0.76
end

RefreshAddonList = function()
    if not listContent or not db then
        return
    end

    local items = {}
    for folderName, registryEntry in pairs(db.addonRegistry) do
        if type(registryEntry) == "table" then
            local installed = installedAddons[folderName]
            local item = {
                name = folderName,
                title = (installed and installed.title) or registryEntry.title or folderName,
                installed = installed ~= nil,
                loaded = installed and installed.loaded or nil,
                loadable = installed and installed.loadable or nil,
                loadReason = installed and installed.loadReason or nil,
                locked = installed and installed.locked or IsLockedAddon(folderName),
            }
            if installed then
                local currentEnabled = GetAddonEnabled(folderName, installed.index)
                if currentEnabled ~= nil then
                    installed.enabled = currentEnabled
                end
                installed.loaded = IsAddonLoaded(folderName)
                installed.loadable, installed.loadReason = GetAddonLoadability(folderName, installed.index)
                item.loaded = installed.loaded
                item.loadable = installed.loadable
                item.loadReason = installed.loadReason
                item.currentEnabled = installed.enabled
            end
            items[#items + 1] = item
        end
    end
    table.sort(items, AddonSort)

    local includeMissing = not showMissingCheck or showMissingCheck:GetChecked()
    local visible = {}
    for _, item in ipairs(items) do
        if item.installed or includeMissing then
            visible[#visible + 1] = item
        end
    end

    local rowHeight = 38
    local width = listScroll and math.max(400, listScroll:GetWidth() - 24) or 900
    listContent:SetWidth(width)
    listContent:SetHeight(math.max(1, #visible * rowHeight))

    for _, row in ipairs(addonRows) do
        row:Hide()
    end

    for index, item in ipairs(visible) do
        local row = addonRows[index]
        if not row then
            row = CreateFrame("Frame", nil, listContent)
            row:SetHeight(rowHeight)
            local background = row:CreateTexture(nil, "BACKGROUND")
            background:SetAllPoints(row)
            row.background = background

            local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            check:SetPoint("LEFT", row, "LEFT", 4, 0)
            row.check = check

            local title = MakeLabel(row, "", "GameFontNormal")
            title:SetPoint("LEFT", check, "RIGHT", 4, 0)
            title:SetWidth(490)
            title:SetJustifyH("LEFT")
            row.title = title

            local state = MakeLabel(row, "", "GameFontHighlightSmall")
            state:SetPoint("RIGHT", row, "RIGHT", -12, 0)
            state:SetWidth(245)
            state:SetJustifyH("RIGHT")
            row.state = state

            addonRows[index] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", listContent, "TOPLEFT", 0, -((index - 1) * rowHeight))
        row:SetPoint("TOPRIGHT", listContent, "TOPRIGHT", 0, -((index - 1) * rowHeight))
        row.background:SetColorTexture(index % 2 == 0 and 0.08 or 0.11, 0.09, 0.12, 0.9)

        local profileValue = draft.addons[item.name]
        row.check:SetChecked(profileValue == true)
        row.check:SetEnabled(not item.locked)
        row.check:SetScript("OnClick", function(self)
            draft.addons[item.name] = self:GetChecked() and true or false
            RefreshFooter()
        end)

        local statusText, red, green, blue = GetAddonRuntimePresentation(item)
        local statusIcon = string.format("|cff%02x%02x%02x●|r ",
            math.floor(red * 255 + 0.5), math.floor(green * 255 + 0.5), math.floor(blue * 255 + 0.5))
        row.title:SetText(statusIcon .. item.title .. " (" .. item.name .. ")")
        row.state:SetText(statusText)
        row.state:SetTextColor(red, green, blue)
        row:Show()
    end

    for index = #visible + 1, #addonRows do
        addonRows[index]:Hide()
    end


    if type(listScroll.UpdateScrollChildRect) == "function" then
        listScroll:UpdateScrollChildRect()
    end
end


RefreshLocationHeader = function()
    if currentLocationText then
        currentLocationText:SetText("Current location: " .. tostring(LOCATION_LABELS[currentLocation] or "Detecting")
            .. "  —  " .. tostring(currentLocationName or "Unknown area"))
        currentLocationText:SetTextColor(0.76, 0.79, 0.85)
    end

    -- Only mark the ruleset when its matching location tab is open.
    local viewingActiveRuleset = activePage ~= "settings" and currentLocation ~= nil
        and activePage == currentLocation
    if activeRulesetIndicator then
        if viewingActiveRuleset then
            activeRulesetIndicator:Show()
        else
            activeRulesetIndicator:Hide()
        end
    end

    if currentProfileText then
        currentProfileText:SetText("Profile:")
    end

    if RefreshRoleDropdown then
        RefreshRoleDropdown()
    end

    for key, button in pairs(tabButtons) do
        local label = LOCATION_LABELS[key] or "Settings"
        if viewingActiveRuleset and key == currentLocation then
            button:SetText("|cff4dff70●|r |cffdfe6f5" .. label .. "|r")
        else
            button:SetText("|cff9a9a9a" .. label .. "|r")
        end
    end
end

RefreshProfileDropdown = function()
    if not profileDropdown or not UIDropDownMenu_Initialize then
        return
    end
    local locationData = GetLocationData(activeLocation)
    local profileName = locationData and locationData.activeProfile or "Default"
    UIDropDownMenu_SetText(profileDropdown, profileName)
    UIDropDownMenu_Initialize(profileDropdown, function(self, level)
        local names = {}
        for name in pairs(locationData.profiles) do
            names[#names + 1] = name
        end
        table.sort(names)
        for _, name in ipairs(names) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = name
            info.value = name
            info.checked = name == profileName
            info.func = function()
                if name ~= profileName then
                    RequestNavigation(function()
                        locationData.activeProfile = name
                        LoadDraft()
                        RefreshProfileDropdown()
                        RefreshLocationHeader()
                        RefreshAddonList()
                        RefreshFooter()
                        if activeLocation == currentLocation then
                            ApplyLocationProfile("profile selection")
                        end
                    end)
                end
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
end

RefreshRoleDropdown = function()
    if not roleDropdown or not UIDropDownMenu_Initialize or not db then
        return
    end
    local role, classToken, className = GetActiveRole()
    UIDropDownMenu_SetText(roleDropdown, role and (className .. " - " .. role) or "Standard")
    UIDropDownMenu_Initialize(roleDropdown, function(self, level)
        local standard = UIDropDownMenu_CreateInfo()
        standard.text = "Standard location profiles"
        standard.value = "__STANDARD__"
        standard.checked = role == nil
        standard.func = function()
            if role ~= nil then
                RequestNavigation(function()
                    db.activeRoleByClass[classToken] = nil
                    LoadDraft()
                    RefreshRoleDropdown()
                    RefreshProfileDropdown()
                    RefreshCopyProfileDropdown()
                    RefreshLocationHeader()
                    RefreshAddonList()
                    RefreshFooter()
                    ShowRoleApplyPrompt("Standard location profiles")
                end)
            end
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(standard, level)

        for _, item in ipairs(ROLE_TYPES) do
            local selectedRole = item.key
            local selectedLabel = item.label
            local info = UIDropDownMenu_CreateInfo()
            info.text = className .. " - " .. selectedLabel
            info.value = selectedRole
            info.checked = role == selectedRole
            info.func = function()
                if role ~= selectedRole then
                    RequestNavigation(function()
                        EnsureClassRoleProfile(selectedRole)
                        db.activeRoleByClass[classToken] = selectedRole
                        LoadDraft()
                        RefreshRoleDropdown()
                        RefreshProfileDropdown()
                        RefreshCopyProfileDropdown()
                        RefreshLocationHeader()
                        RefreshAddonList()
                        RefreshFooter()
                        ShowRoleApplyPrompt(className .. " - " .. selectedLabel)
                    end)
                end
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
end

local function UpdatePageVisibility()
    if not locationContent or not settingsContent then
        return
    end
    if activePage == "settings" then
        locationContent:Hide()
        settingsContent:Show()
        if RefreshSettingsPage then RefreshSettingsPage() end
    else
        settingsContent:Hide()
        locationContent:Show()
    end
end

local function SwitchLocation(key)
    if not LOCATION_LABELS[key] or key == activePage then
        return
    end
    RequestNavigation(function()
        activeLocation = key
        activePage = key
        LoadDraft()
        UpdatePageVisibility()
        RefreshLocationHeader()
        RefreshProfileDropdown()
        RefreshCopyProfileDropdown()
        RefreshRoleDropdown()
        RefreshAddonList()
        RefreshFooter()
    end)
end

local function SwitchToSettings()
    if activePage == "settings" then
        return
    end
    RequestNavigation(function()
        activePage = "settings"
        LoadDraft()
        UpdatePageVisibility()
        RefreshLocationHeader()
        RefreshFooter()
    end)
end

local function CreateProfileCopy()
    local name = Trim(profileNameBox and profileNameBox:GetText() or "")
    if name == "" then
        Print("Enter a name for the new profile.")
        return
    end
    if #name > 32 then
        Print("Profile names must be 32 characters or fewer.")
        return
    end
    local locationData = GetLocationData(activeLocation)
    if locationData.profiles[name] then
        Print("A profile with that name already exists.")
        return
    end

    RequestNavigation(function()
        local source = GetActiveProfile(activeLocation)
        locationData.profiles[name] = DeepCopy(source or { addons = {} })
        locationData.profiles[name] = EnsureProfileShape(locationData.profiles[name])
        locationData.activeProfile = name
        db.hasSavedAddonSettings = true
        sessionHasSavedChange = true
        if profileNameBox then
            profileNameBox:SetText("")
        end
        LoadDraft()
        RefreshProfileDropdown()
        RefreshCopyProfileDropdown()
        RefreshLocationHeader()
        RefreshAddonList()
        RefreshFooter()
        if activeLocation == currentLocation then
            ApplyLocationProfile("profile created")
        end
        Print("Created profile '" .. name .. "' for " .. LOCATION_LABELS[activeLocation] .. ".")
    end)
end

local function DeleteActiveProfile()
    local locationData = GetLocationData(activeLocation)
    local name = locationData and locationData.activeProfile
    if not name or name == "Default" then
        Print("The Default profile cannot be deleted.")
        return
    end
    RequestNavigation(function()
        StaticPopupDialogs["FAMP_DELETE_PROFILE"] = {
            text = "Delete the '" .. name .. "' profile for " .. LOCATION_LABELS[activeLocation] .. "?\n\nThis only deletes this location type's profile. Other location profiles and missing-addon registry entries are preserved.",
            button1 = "Delete Profile",
            button2 = "Cancel",
            OnAccept = function()
                if locationData.profiles[name] then
                    locationData.profiles[name] = nil
                end
                locationData.activeProfile = "Default"
                sessionHasSavedChange = true
                LoadDraft()
                RefreshProfileDropdown()
                RefreshLocationHeader()
                RefreshAddonList()
                RefreshFooter()
                if activeLocation == currentLocation then
                    ApplyLocationProfile("profile deleted")
                end
                Print("Deleted profile '" .. name .. "'.")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("FAMP_DELETE_PROFILE")
    end)
end

local function TrackMissingAddon()
    local folderName = Trim(manualAddonBox and manualAddonBox:GetText() or "")
    if folderName == "" then
        return
    end
    if folderName == ADDON_FOLDER then
        Print("The manager itself does not need a registry entry.")
        return
    end
    RequestNavigation(function()
        if not db.addonRegistry[folderName] then
            db.addonRegistry[folderName] = {
                folder = folderName,
                title = folderName,
                installed = false,
                manuallyTracked = true,
            }
        end
        if manualAddonBox then
            manualAddonBox:SetText("")
        end
        RefreshAddonList()
        Print("Tracking '" .. folderName .. "'. Its profile settings will be retained until it is installed.")
    end)
end

local function RefreshInstalledList()
    RequestNavigation(function()
        ScanInstalledAddons()
        LoadDraft()
        RefreshAddonList()
        RefreshFooter()
        Print("Installed addon list refreshed. Missing addons and their saved profiles were retained.")
    end)
end

local function OpenBlizzardAddonList()
    if IsInCombatLockdownSafe() then
        Print("The Blizzard addon list cannot be opened safely during combat.")
        return
    end

    ClosePanelNow()

    if not AddonList and C_AddOns and type(C_AddOns.LoadAddOn) == "function" then
        pcall(C_AddOns.LoadAddOn, "Blizzard_AddOnManager")
    end

    if AddonList then
        if type(ShowUIPanel) == "function" then
            ShowUIPanel(AddonList)
        else
            AddonList:Show()
        end
    else
        Print("The Blizzard AddOns list frame (AddonList) is not available on this client.")
    end
end

local PANEL_BASE_WIDTH = 1030
local PANEL_BASE_HEIGHT = 680
local PANEL_SCREEN_FILL = 0.92

local function GetExpandedPanelScale()
    if not UIParent or type(UIParent.GetWidth) ~= "function" or type(UIParent.GetHeight) ~= "function" then
        return 1.0
    end

    local okWidth, parentWidth = pcall(UIParent.GetWidth, UIParent)
    local okHeight, parentHeight = pcall(UIParent.GetHeight, UIParent)
    if not okWidth or not okHeight or type(parentWidth) ~= "number" or type(parentHeight) ~= "number"
        or parentWidth <= 0 or parentHeight <= 0 then
        return 1.0
    end

    return math.max(0.85, math.min(
        (parentWidth * PANEL_SCREEN_FILL) / PANEL_BASE_WIDTH,
        (parentHeight * PANEL_SCREEN_FILL) / PANEL_BASE_HEIGHT
    ))
end

local function UpdatePanelScale()
    if panel and type(panel.SetScale) == "function" then
        local scale = GetExpandedPanelScale()
        local currentScale = type(panel.GetScale) == "function" and panel:GetScale() or nil
        if currentScale ~= scale then
            panel:SetScale(scale)
            panel:ClearAllPoints()
            panel:SetPoint("CENTER")
        end
    end
end

local function CreatePanelShell()
    panel = CreateFrame("Frame", "ForeverAddonManagerPlusPanel", UIParent)
    panel:SetSize(PANEL_BASE_WIDTH, PANEL_BASE_HEIGHT)
    panel:SetScale(GetExpandedPanelScale())
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetFrameLevel(40)
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetClampedToScreen(true)
    panel:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    local nebulaBackground = panel:CreateTexture(nil, "BACKGROUND", nil, -2)
    nebulaBackground:SetAllPoints(panel)
    nebulaBackground:SetTexture(NEBULA_BACKGROUND)
    nebulaBackground:SetTexCoord(0, 1, 0.17, 0.83)
    nebulaBackground:SetAlpha(0.88)

    local background = panel:CreateTexture(nil, "BACKGROUND", nil, -1)
    background:SetAllPoints(panel)
    background:SetColorTexture(0.008, 0.012, 0.028, 0.58)

    local borderOK = pcall(function()
        local borderFrame = CreateFrame("Frame", nil, panel, "BackdropTemplate")
        borderFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", -2, 2)
        borderFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 2, -2)
        borderFrame:SetFrameStrata(panel:GetFrameStrata())
        borderFrame:SetFrameLevel(panel:GetFrameLevel() + 1)
        borderFrame:EnableMouse(false)
        borderFrame:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        borderFrame:SetBackdropBorderColor(0.58, 0.62, 0.70, 0.92)
    end)
    if not borderOK then
        local borderColor = { 0.58, 0.62, 0.70, 0.92 }
        local top = panel:CreateTexture(nil, "OVERLAY")
        top:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -1)
        top:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -1)
        top:SetHeight(1.5)
        top:SetColorTexture(unpack(borderColor))
        local bottom = panel:CreateTexture(nil, "OVERLAY")
        bottom:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 8, 1)
        bottom:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 1)
        bottom:SetHeight(1.5)
        bottom:SetColorTexture(unpack(borderColor))
        local left = panel:CreateTexture(nil, "OVERLAY")
        left:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -8)
        left:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 1, 8)
        left:SetWidth(1.5)
        left:SetColorTexture(unpack(borderColor))
        local right = panel:CreateTexture(nil, "OVERLAY")
        right:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -1, -8)
        right:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -1, 8)
        right:SetWidth(1.5)
        right:SetColorTexture(unpack(borderColor))
    end

    local title = MakeLabel(panel, "ForeverAddonManagerPlus  |cffaaaaaa" .. VERSION .. "|r", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 22, -18)

    local subtitle = MakeLabel(panel, "Manage addon setups by location and class/role. Changes take effect after a UI reload.", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -43)

    local close = MakeButton(panel, "X", 28, 24)
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -12)
    close:SetScript("OnClick", function()
        RequestNavigation(ClosePanelNow)
    end)
end


local function CopyProfileFromLocation(sourceKey)
    if not LOCATION_LABELS[sourceKey] or sourceKey == activeLocation then
        return
    end
    local sourceProfile = GetActiveProfile(sourceKey)
    if not sourceProfile then
        Print("There is no saved profile to copy from that tab.")
        return
    end
    draft.addons = DeepCopy(sourceProfile.addons or {})
    if RefreshCopyProfileDropdown then
        RefreshCopyProfileDropdown()
    end
    RefreshAddonList()
    RefreshFooter()
    Print("Copied " .. LOCATION_LABELS[sourceKey] .. " settings to " .. LOCATION_LABELS[activeLocation]
        .. ". Save this page to keep the copied settings.")
end

CopySettingsFromTab = function(sourceKey)
    if IsDraftDirty() then
        StaticPopupDialogs["FAMP_COPY_TAB_CONFIRM"] = {
            text = "Copy settings from " .. tostring(LOCATION_LABELS[sourceKey])
                .. "? This will replace the unsaved changes on the current tab.",
            button1 = "Copy Settings",
            button2 = "Cancel",
            OnAccept = function()
                CopyProfileFromLocation(sourceKey)
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("FAMP_COPY_TAB_CONFIRM")
    else
        CopyProfileFromLocation(sourceKey)
    end
end

RefreshCopyProfileDropdown = function()
    if not copyProfileDropdown or not UIDropDownMenu_Initialize then
        return
    end
    UIDropDownMenu_SetText(copyProfileDropdown, "Choose tab")
    UIDropDownMenu_Initialize(copyProfileDropdown, function(self, level)
        for _, location in ipairs(LOCATION_TYPES) do
            if location.key ~= activeLocation then
                local info = UIDropDownMenu_CreateInfo()
                info.text = location.label
                info.value = location.key
                info.func = function()
                    CopySettingsFromTab(location.key)
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)
end

local function CaptureBlizzardAddonSettings()
    ScanInstalledAddons()
    local snapshot = {}
    for folderName, addon in pairs(installedAddons) do
        local enabled = GetAddonEnabled(folderName, addon.index)
        if type(enabled) == "boolean" then
            snapshot[folderName] = enabled
        end
    end
    return snapshot
end

SyncCurrentTabFromBlizzard = function()
    local snapshot = CaptureBlizzardAddonSettings()
    for folderName, enabled in pairs(snapshot) do
        draft.addons[folderName] = enabled
    end
    RefreshAddonList()
    RefreshFooter()
    Print("Blizzard's AddOns settings were copied to the " .. LOCATION_LABELS[activeLocation]
        .. " tab. Save Page to keep them.")
end

local function GetCurrentProfileSetLabel()
    local role, _, className = GetActiveRole()
    if role then
        return tostring(className) .. " - " .. tostring(role)
    end
    return "Standard profiles"
end

SyncAllTabsFromBlizzard = function()
    local snapshot = CaptureBlizzardAddonSettings()
    local role = GetActiveRole()
    if role then
        EnsureClassRoleProfile(role)
    end

    local changed = false
    for _, location in ipairs(LOCATION_TYPES) do
        local profile = GetActiveProfile(location.key)
        if profile then
            for folderName, enabled in pairs(snapshot) do
                if profile.addons[folderName] ~= enabled then
                    changed = true
                end
                profile.addons[folderName] = enabled
            end
        end
    end

    db.hasSavedAddonSettings = true
    if changed then
        sessionHasSavedChange = true
    end
    LoadDraft()
    RefreshAddonList()
    RefreshFooter()
    Print("Blizzard's AddOns settings were copied to the active profile on every location tab in "
        .. GetCurrentProfileSetLabel() .. ". Other named profile copies and other class/role sets were left alone.")
end

local function CreateSyncDialogs()
    if not syncDialog then
        syncDialog = CreateFrame("Frame", "ForeverAddonManagerPlusSyncDialog", UIParent, "UIPanelDialogTemplate")
        syncDialog:SetSize(540, 220)
        syncDialog:SetPoint("CENTER")
        syncDialog:SetFrameStrata("DIALOG")
        syncDialog:SetFrameLevel(210)
        syncDialog:EnableMouse(true)
        syncDialog:Hide()

        local title = MakeLabel(syncDialog, "Synchronize from Blizzard Settings", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", syncDialog, "TOPLEFT", 24, -22)
        local text = MakeLabel(syncDialog,
            "Copy the enabled/disabled settings from Blizzard's AddOns window.\n\nUpdate This Tab replaces the selected profile on the current tab, including any unsaved edits. Afterward, click Save Page to keep it. Update All Tabs replaces the active profile on every location tab in the current profile set. This only copies settings; it does not change addon states in the game.",
            "GameFontHighlight")
        text:SetPoint("TOPLEFT", syncDialog, "TOPLEFT", 24, -54)
        text:SetPoint("TOPRIGHT", syncDialog, "TOPRIGHT", -24, -54)
        text:SetJustifyH("LEFT")
        text:SetJustifyV("TOP")

        local updateTab = MakeButton(syncDialog, "Update This Tab", 145, 26)
        updateTab:SetPoint("BOTTOMLEFT", syncDialog, "BOTTOMLEFT", 30, 18)
        updateTab:SetScript("OnClick", function()
            syncDialog:Hide()
            SyncCurrentTabFromBlizzard()
        end)

        local updateAll = MakeButton(syncDialog, "Update All Tabs", 145, 26)
        updateAll:SetPoint("LEFT", updateTab, "RIGHT", 8, 0)
        updateAll:SetScript("OnClick", function()
            syncDialog:Hide()
            if syncConfirmDialog then
                syncConfirmDialog.confirmText:SetText(
                    "This will replace the active profile on all nine location tabs in " .. GetCurrentProfileSetLabel()
                    .. " with your current Blizzard AddOns settings. Other named profile copies and other class/role sets will not change. Any unsaved edits on this tab will be replaced.\n\nThis is a bigger change. Are you sure you want to continue?")
                syncConfirmDialog:Show()
            end
        end)

        local cancel = MakeButton(syncDialog, "Cancel", 90, 26)
        cancel:SetPoint("LEFT", updateAll, "RIGHT", 8, 0)
        cancel:SetScript("OnClick", function()
            syncDialog:Hide()
        end)
    end

    if not syncConfirmDialog then
        syncConfirmDialog = CreateFrame("Frame", "ForeverAddonManagerPlusSyncConfirmDialog", UIParent, "UIPanelDialogTemplate")
        syncConfirmDialog:SetSize(520, 225)
        syncConfirmDialog:SetPoint("CENTER")
        syncConfirmDialog:SetFrameStrata("DIALOG")
        syncConfirmDialog:SetFrameLevel(211)
        syncConfirmDialog:EnableMouse(true)
        syncConfirmDialog:Hide()

        local title = MakeLabel(syncConfirmDialog, "Confirm Update All Tabs", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", syncConfirmDialog, "TOPLEFT", 24, -22)
        local confirmText = MakeLabel(syncConfirmDialog, "", "GameFontHighlight")
        confirmText:SetPoint("TOPLEFT", syncConfirmDialog, "TOPLEFT", 24, -54)
        confirmText:SetPoint("TOPRIGHT", syncConfirmDialog, "TOPRIGHT", -24, -54)
        confirmText:SetJustifyH("LEFT")
        confirmText:SetJustifyV("TOP")
        syncConfirmDialog.confirmText = confirmText

        local confirm = MakeButton(syncConfirmDialog, "Yes, Update All Tabs", 180, 26)
        confirm:SetPoint("BOTTOMLEFT", syncConfirmDialog, "BOTTOMLEFT", 90, 18)
        confirm:SetScript("OnClick", function()
            syncConfirmDialog:Hide()
            SyncAllTabsFromBlizzard()
        end)
        local cancel = MakeButton(syncConfirmDialog, "Cancel", 100, 26)
        cancel:SetPoint("LEFT", confirm, "RIGHT", 10, 0)
        cancel:SetScript("OnClick", function()
            syncConfirmDialog:Hide()
        end)
    end
end

ShowSyncDialog = function()
    CreateSyncDialogs()
    if syncDialog then
        syncDialog:Show()
    end
end

local function CreatePanelTabsAndPages()
    local tabX = 18
    local tabY = -76
    local tabWidth = 94
    local tabGap = 3
    for _, location in ipairs(LOCATION_TYPES) do
        local button = CreateFrame("Button", "ForeverAddonManagerPlusTab_" .. location.key, panel, "UIPanelButtonTemplate")
        button:SetSize(tabWidth, 28)
        button:SetText(location.label)
        button:SetPoint("TOPLEFT", panel, "TOPLEFT", tabX, tabY)
        button:SetScript("OnClick", function()
            SwitchLocation(location.key)
        end)
        tabButtons[location.key] = button
        tabX = tabX + tabWidth + tabGap
    end

    local settingsTab = CreateFrame("Button", "ForeverAddonManagerPlusSettingsTab", panel, "UIPanelButtonTemplate")
    settingsTab:SetSize(tabWidth, 28)
    settingsTab:SetText("Settings")
    settingsTab:SetPoint("TOPLEFT", panel, "TOPLEFT", tabX, tabY)
    settingsTab:SetScript("OnClick", function()
        SwitchToSettings()
    end)
    tabButtons.settings = settingsTab

    locationContent = CreateFrame("Frame", "ForeverAddonManagerPlusLocationContent", panel)
    locationContent:SetAllPoints(panel)
    settingsContent = CreateFrame("Frame", "ForeverAddonManagerPlusSettingsContent", panel)
    settingsContent:SetAllPoints(panel)
    settingsContent:Hide()
end

local function CreatePanelLocationControls()
    currentLocationText = MakeLabel(locationContent, "", "GameFontHighlightSmall")
    currentLocationText:SetPoint("TOPLEFT", panel, "TOPLEFT", 22, -116)

    activeRulesetIndicator = MakeLabel(locationContent, "|cff4dff70● THIS RULESET IS ACTIVE|r", "GameFontHighlightSmall")
    activeRulesetIndicator:SetPoint("TOPLEFT", panel, "TOPLEFT", 380, -116)
    activeRulesetIndicator:Hide()

    currentProfileText = MakeLabel(locationContent, "Profile:", "GameFontNormal")
    currentProfileText:SetPoint("TOPLEFT", panel, "TOPLEFT", 22, -140)

    profileDropdown = CreateFrame("Frame", "ForeverAddonManagerPlusProfileDropdown", locationContent, "UIDropDownMenuTemplate")
    profileDropdown:SetPoint("LEFT", currentProfileText, "RIGHT", 4, 0)
    UIDropDownMenu_SetWidth(profileDropdown, 120)

    local profileNameLabel = MakeLabel(locationContent, "Create profile copy:", "GameFontHighlightSmall")
    profileNameLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 285, -143)

    profileNameBox = CreateFrame("EditBox", nil, locationContent, "InputBoxTemplate")
    profileNameBox:SetSize(105, 24)
    profileNameBox:SetPoint("LEFT", profileNameLabel, "RIGHT", 6, 0)
    profileNameBox:SetAutoFocus(false)
    profileNameBox:SetMaxLetters(32)

    local createProfileButton = MakeButton(locationContent, "Create Copy", 84, 24)
    createProfileButton:SetPoint("LEFT", profileNameBox, "RIGHT", 6, 0)
    createProfileButton:SetScript("OnClick", CreateProfileCopy)

    local deleteProfileButton = MakeButton(locationContent, "Delete", 78, 24)
    deleteProfileButton:SetPoint("LEFT", createProfileButton, "RIGHT", 6, 0)
    deleteProfileButton:SetScript("OnClick", DeleteActiveProfile)

    local roleLabel = MakeLabel(locationContent, "Class + Role:", "GameFontHighlightSmall")
    roleLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 755, -143)
    roleDropdown = CreateFrame("Frame", "ForeverAddonManagerPlusRoleDropdown", locationContent, "UIDropDownMenuTemplate")
    roleDropdown:SetPoint("LEFT", roleLabel, "RIGHT", 6, 0)
    UIDropDownMenu_SetWidth(roleDropdown, 150)

    local copySettingsLabel = MakeLabel(locationContent, "Copy settings from:", "GameFontHighlightSmall")
    copySettingsLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 22, -181)

    copyProfileDropdown = CreateFrame("Frame", "ForeverAddonManagerPlusCopySettingsDropdown", locationContent, "UIDropDownMenuTemplate")
    copyProfileDropdown:SetPoint("LEFT", copySettingsLabel, "RIGHT", 4, 0)
    UIDropDownMenu_SetWidth(copyProfileDropdown, 135)

    local syncButton = MakeButton(locationContent, "Synchronize from Blizzard Settings", 220, 24)
    syncButton:SetPoint("LEFT", copyProfileDropdown, "RIGHT", 22, 0)
    syncButton:SetScript("OnClick", ShowSyncDialog)

    showMissingCheck = CreateFrame("CheckButton", nil, locationContent, "UICheckButtonTemplate")
    showMissingCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 22, -216)
    showMissingCheck:SetChecked(true)
    local missingLabel = MakeLabel(locationContent, "Show missing addons", "GameFontHighlightSmall")
    missingLabel:SetPoint("LEFT", showMissingCheck, "RIGHT", 2, 0)
    showMissingCheck:SetScript("OnClick", function()
        RefreshAddonList()
    end)

    local refreshButton = MakeButton(locationContent, "Refresh Addon List", 140, 24)
    refreshButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -22, -213)
    refreshButton:SetScript("OnClick", RefreshInstalledList)

    local missingPrompt = MakeLabel(locationContent, "Track a missing/future addon by folder name:", "GameFontHighlightSmall")
    missingPrompt:SetPoint("TOPLEFT", panel, "TOPLEFT", 22, -244)

    manualAddonBox = CreateFrame("EditBox", nil, locationContent, "InputBoxTemplate")
    manualAddonBox:SetSize(230, 24)
    manualAddonBox:SetPoint("LEFT", missingPrompt, "RIGHT", 8, 0)
    manualAddonBox:SetAutoFocus(false)
    manualAddonBox:SetMaxLetters(100)

    local trackButton = MakeButton(locationContent, "Track Addon", 100, 24)
    trackButton:SetPoint("LEFT", manualAddonBox, "RIGHT", 8, 0)
    trackButton:SetScript("OnClick", TrackMissingAddon)

    listScroll = CreateFrame("ScrollFrame", "ForeverAddonManagerPlusAddonScroll", locationContent, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 22, -273)
    listScroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -42, 72)
    listScroll:SetClipsChildren(true)

    listContent = CreateFrame("Frame", nil, listScroll)
    listContent:SetSize(940, 1)
    listScroll:SetScrollChild(listContent)
    RefreshCopyProfileDropdown()
end

local function CreatePanelSettingsControls()
    local settingsTitle = MakeLabel(settingsContent, "Minimap Button", "GameFontNormalLarge")
    settingsTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 26, -132)
    local settingsDescription = MakeLabel(settingsContent,
        "Choose whether the minimap button is visible and what information appears when you hover over it.",
        "GameFontHighlightSmall")
    settingsDescription:SetPoint("TOPLEFT", panel, "TOPLEFT", 26, -158)

    showMinimapButtonCheck = CreateFrame("CheckButton", "ForeverAddonManagerPlusShowMinimapButton", settingsContent, "UICheckButtonTemplate")
    showMinimapButtonCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -188)
    local showMinimapButtonLabel = MakeLabel(settingsContent, "Show minimap button", "GameFontNormal")
    showMinimapButtonLabel:SetPoint("LEFT", showMinimapButtonCheck, "RIGHT", 4, 0)
    showMinimapButtonCheck:SetScript("OnClick", function(self)
        draft.settings.minimapEnabled = self:GetChecked() == true
        if RefreshSettingsPage then RefreshSettingsPage() end
        RefreshFooter()
    end)

    showTooltipAddonsCheck = CreateFrame("CheckButton", "ForeverAddonManagerPlusTooltipShowAddons", settingsContent, "UICheckButtonTemplate")
    showTooltipAddonsCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 48, -230)
    showTooltipAddonsLabel = MakeLabel(settingsContent, "Show enabled/disabled addon list in tooltip", "GameFontHighlight")
    showTooltipAddonsLabel:SetPoint("LEFT", showTooltipAddonsCheck, "RIGHT", 4, 0)

    local tooltipStatusHelp = CreateFrame("Button", nil, settingsContent)
    tooltipStatusHelp:SetSize(16, 16)
    tooltipStatusHelp:SetPoint("LEFT", showTooltipAddonsLabel, "RIGHT", 6, 0)
    local tooltipStatusHelpText = tooltipStatusHelp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tooltipStatusHelpText:SetPoint("CENTER")
    tooltipStatusHelpText:SetText("?")
    tooltipStatusHelpText:SetTextColor(0.55, 0.75, 1.0)
    tooltipStatusHelp:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Addon status colors", 1, 1, 1)
        GameTooltip:AddLine("Green: Loaded in this game session. Disabling it takes effect after a reload.", 0.28, 1.0, 0.42, true)
        GameTooltip:AddLine("Red: Not currently loaded, even if enabled in the selected profile.", 1.0, 0.36, 0.36, true)
        GameTooltip:AddLine("Grey: Not installed; saved profile settings are retained.", 0.62, 0.66, 0.74, true)
        GameTooltip:Show()
    end)
    tooltipStatusHelp:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    showTooltipAddonsCheck:SetScript("OnClick", function(self)
        draft.settings.tooltipShowAddons = self:GetChecked() == true
        RefreshFooter()
    end)

    showTooltipRoleCheck = CreateFrame("CheckButton", "ForeverAddonManagerPlusTooltipShowRole", settingsContent, "UICheckButtonTemplate")
    showTooltipRoleCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 48, -270)
    showTooltipRoleLabel = MakeLabel(settingsContent, "Show selected class/role and Blizzard role icon", "GameFontHighlight")
    showTooltipRoleLabel:SetPoint("LEFT", showTooltipRoleCheck, "RIGHT", 4, 0)
    showTooltipRoleCheck:SetScript("OnClick", function(self)
        draft.settings.tooltipShowRole = self:GetChecked() == true
        RefreshFooter()
    end)

    settingsHint = MakeLabel(settingsContent,
        "The current location type is always shown in the tooltip. Tooltip options are available while the minimap button is enabled.",
        "GameFontDisableSmall")
    settingsHint:SetPoint("TOPLEFT", panel, "TOPLEFT", 52, -310)

    RefreshSettingsPage = function()
        if not draft.settings then return end
        local enabled = draft.settings.minimapEnabled == true
        showMinimapButtonCheck:SetChecked(enabled)
        showTooltipAddonsCheck:SetChecked(draft.settings.tooltipShowAddons == true)
        showTooltipRoleCheck:SetChecked(draft.settings.tooltipShowRole ~= false)
        if enabled then
            showTooltipAddonsCheck:Show()
            showTooltipAddonsLabel:Show()
            tooltipStatusHelp:Show()
            showTooltipRoleCheck:Show()
            showTooltipRoleLabel:Show()
            settingsHint:Show()
        else
            showTooltipAddonsCheck:Hide()
            showTooltipAddonsLabel:Hide()
            tooltipStatusHelp:Hide()
            showTooltipRoleCheck:Hide()
            showTooltipRoleLabel:Hide()
            settingsHint:Hide()
        end
    end
end

local function CreatePanelFooterControls()
    toggleAddonsButton = MakeButton(panel, "Toggle Addons", 140, 28)
    toggleAddonsButton:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 22, 22)
    toggleAddonsButton:SetScript("OnClick", function()
        RequestNavigation(OpenBlizzardAddonList)
    end)

    saveButton = CreateFrame("Button", "ForeverAddonManagerPlusSavePageButton", panel, "UIPanelButtonTemplate")
    saveButton:SetSize(120, 28)
    saveButton:SetText("Save Page")
    saveButton:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -182, 22)
    saveButton:SetScript("OnClick", function()
        if SaveDraft(false) then
            if activePage == "settings" then
                Print("Saved manager settings.")
            else
                Print("Saved the " .. LOCATION_LABELS[activeLocation] .. " page profile.")
                RefreshAddonList()
            end
        end
    end)

    discardButton = MakeButton(panel, "Discard Changes", 130, 28)
    discardButton:SetPoint("RIGHT", saveButton, "LEFT", -8, 0)
    discardButton:SetScript("OnClick", function()
        if IsDraftDirty() then
            DiscardDraft()
            Print("Unsaved changes discarded.")
        end
    end)

    reloadButton = MakeButton(panel, "Reload UI", 105, 28)
    reloadButton:SetPoint("RIGHT", discardButton, "LEFT", -8, 0)
    reloadButton:SetScript("OnClick", function()
        if IsInCombatLockdownSafe() then
            Print("Reload is unavailable during combat.")
            return
        end
        if pendingReload and type(ReloadUI) == "function" then
            ReloadUI()
        end
    end)
    reloadButton:Hide()

    footerStatus = MakeLabel(panel, "", "GameFontHighlightSmall")
    footerStatus:SetPoint("LEFT", toggleAddonsButton, "RIGHT", 14, 0)
    footerStatus:SetPoint("RIGHT", reloadButton, "LEFT", -12, 0)
    footerStatus:SetJustifyH("LEFT")
end

local function ConfigurePanelScripts()
    panel:SetScript("OnShow", function()
        UpdatePanelScale()
        if preserveDraftOnShow then
            return
        end
        uiReady = true
        LoadDraft()
        UpdatePageVisibility()
        RefreshLocationHeader()
        RefreshProfileDropdown()
        RefreshAddonList()
        RefreshFooter()
        ShowSetupPrompt()
    end)

    panel:SetScript("OnHide", function(self)
        if internalHide or not uiReady then
            return
        end
        if IsDraftDirty() then
            preserveDraftOnShow = true
            self:Show()
            preserveDraftOnShow = false
            RequestNavigation(ClosePanelNow)
        else
            ApplyDeferredRoleProfile()
        end
    end)

    panel:Hide()

    if type(UISpecialFrames) == "table" then
        local found = false
        for _, name in ipairs(UISpecialFrames) do
            if name == "ForeverAddonManagerPlusPanel" then
                found = true
                break
            end
        end
        if not found then
            table.insert(UISpecialFrames, "ForeverAddonManagerPlusPanel")
        end
    end
end

local function CreatePanel()
    if panel then
        return
    end

    CreatePanelShell()
    CreatePanelTabsAndPages()
    CreatePanelLocationControls()
    CreatePanelSettingsControls()
    CreatePanelFooterControls()
    ConfigurePanelScripts()
end

local minimapShapeQuadrants = {
    ["ROUND"] = { true, true, true, true },
    ["SQUARE"] = { false, false, false, false },
    ["CORNER-TOPLEFT"] = { true, false, false, false },
    ["CORNER-TOPRIGHT"] = { false, false, true, false },
    ["CORNER-BOTTOMLEFT"] = { false, true, false, false },
    ["CORNER-BOTTOMRIGHT"] = { false, false, false, true },
    ["SIDE-LEFT"] = { true, true, false, false },
    ["SIDE-RIGHT"] = { false, false, true, true },
    ["SIDE-TOP"] = { true, false, true, false },
    ["SIDE-BOTTOM"] = { false, true, false, true },
    ["TRICORNER-TOPLEFT"] = { true, true, true, false },
    ["TRICORNER-TOPRIGHT"] = { true, false, true, true },
    ["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
    ["TRICORNER-BOTTOMRIGHT"] = { false, true, true, true },
}

local function GetCurrentMinimapShape()
    local shapeGetter = _G and _G.GetMinimapShape
    if type(shapeGetter) == "function" then
        local ok, shape = pcall(shapeGetter)
        if ok and type(shape) == "string" then
            shape = shape:upper()
            if minimapShapeQuadrants[shape] then
                return shape
            end
        end
    end
    return "ROUND"
end

local function GetMinimapQuadrant(x, y)
    local quadrant = 1
    if x < 0 then
        quadrant = quadrant + 1
    end
    if y > 0 then
        quadrant = quadrant + 2
    end
    return quadrant
end

local function GetMinimapButtonOffsets(angle, shape, width, height)
    local radians = math.rad(angle)
    local directionX = math.cos(radians)
    local directionY = math.sin(radians)
    local quadrant = GetMinimapQuadrant(directionX, directionY)
    local roundedQuadrants = minimapShapeQuadrants[shape] or minimapShapeQuadrants.ROUND
    local halfWidth = (width / 2) + MINIMAP_BUTTON_RADIUS_OFFSET
    local halfHeight = (height / 2) + MINIMAP_BUTTON_RADIUS_OFFSET

    if roundedQuadrants[quadrant] then
        return directionX * halfWidth, directionY * halfHeight
    end

    local scaleX = math.huge
    local scaleY = math.huge
    if math.abs(directionX) > 0.000001 then
        scaleX = halfWidth / math.abs(directionX)
    end
    if math.abs(directionY) > 0.000001 then
        scaleY = halfHeight / math.abs(directionY)
    end
    local distance = math.min(scaleX, scaleY)
    return directionX * distance, directionY * distance
end

local function UpdateMinimapButtonPosition(force)
    if not minimapButton or not Minimap or not db or type(db.minimap) ~= "table" then
        return
    end
    local width = Minimap.GetWidth and Minimap:GetWidth() or 140
    local height = Minimap.GetHeight and Minimap:GetHeight() or width
    if type(width) ~= "number" or width <= 0 then
        width = 140
    end
    if type(height) ~= "number" or height <= 0 then
        height = width
    end

    local angle = tonumber(db.minimap.angle) or 225
    angle = angle % 360
    local shape = GetCurrentMinimapShape()
    local offsetX, offsetY = GetMinimapButtonOffsets(angle, shape, width, height)

    if not force
        and minimapButton.lastPositionShape == shape
        and minimapButton.lastPositionWidth == width
        and minimapButton.lastPositionHeight == height
        and minimapButton.lastPositionAngle == angle then
        return
    end

    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", offsetX, offsetY)
    minimapButton.lastPositionShape = shape
    minimapButton.lastPositionWidth = width
    minimapButton.lastPositionHeight = height
    minimapButton.lastPositionAngle = angle
end

local function ToggleMinimapButton()
    if not db then
        Print("The saved settings are not ready yet. Try again shortly.")
        return
    end

    if not minimapButton then
        minimapRetryErrorShown = false
        if not Minimap then
            db.minimap.hidden = false
            Print("The minimap is not ready yet. The button will appear when the minimap loads.")
            return
        end
        if not TryCreateMinimapButton() then
            Print("The minimap button could not be created. Use /famp status for details.")
            return
        end
        if not db.minimap.hidden then
            minimapButton:Show()
            minimapButton:SetAlpha(1)
            UpdateMinimapButtonPosition(true)
            Print("Minimap button is enabled.")
            return
        end
    end

    db.minimap.hidden = not db.minimap.hidden
    if db.minimap.hidden then
        minimapButton:Hide()
        Print("Minimap button hidden.")
    else
        minimapButton:Show()
        minimapButton:SetAlpha(1)
        UpdateMinimapButtonPosition(true)
        Print("Minimap button shown.")
    end
end

CreateMinimapButton = function()
    if minimapButton or not Minimap then
        return
    end

    local button = CreateFrame("Button", nil, UIParent)
    button:SetSize(MINIMAP_BUTTON_SIZE, MINIMAP_BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    if type(button.SetFrameLevel) == "function" and Minimap.GetFrameLevel then
        button:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 8)
    end
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    if type(button.SetClampedToScreen) == "function" then
        button:SetClampedToScreen(true)
    end

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(MINIMAP_ICON)
    icon:SetSize(24, 24)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0, 1, 0, 1)
    button.icon = icon

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetAllPoints(icon)
    if highlight.SetBlendMode then
        highlight:SetBlendMode("ADD")
    end

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

    button:SetScript("OnEnter", function(self)
        self.lastHoverTime = GetTimeSafe()
        self:SetAlpha(1)
        self.tooltipLineSpacingSet = false
        self.tooltipPreviousLineSpacing = nil
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_NONE")
            GameTooltip:ClearAllPoints()
            local cursorX, cursorY
            if type(GetCursorPosition) == "function" then
                cursorX, cursorY = GetCursorPosition()
            end
            local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
            if cursorX and cursorY and scale and scale > 0 then
                GameTooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cursorX / scale, cursorY / scale)
            else
                GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 0)
            end

            GameTooltip:SetText("ForeverAddonManagerPlus", 1, 1, 1)
            if db.minimap.showTooltipRole ~= false then
                local role, _, className = GetActiveRole()
                local roleLabel = role and (className .. " - " .. role) or "Standard location profiles"
                local roleIcon = ""
                if role == "DPS" then
                    roleIcon = "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:256:64:64:128:0:64|t "
                elseif role == "Healer" then
                    roleIcon = "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:256:64:192:256:0:64|t "
                elseif role == "Tank" then
                    roleIcon = "|TInterface\\LFGFrame\\UI-LFG-ICON-ROLES:16:16:0:0:256:64:128:192:0:64|t "
                elseif role == "Support" then
                    roleIcon = "|TInterface\\Icons\\INV_Misc_QuestionMark:16:16|t "
                end
                GameTooltip:AddLine("Role: " .. roleIcon .. roleLabel, 0.95, 0.88, 0.62, true)
            end
            GameTooltip:AddLine("Location type: " .. tostring(LOCATION_LABELS[currentLocation] or "Detecting"), 0.55, 0.85, 1, true)

            if db.minimap.showTooltipAddons == true then
                if type(GameTooltip.SetCustomLineSpacing) == "function" then
                    if type(GameTooltip.GetCustomLineSpacing) == "function" then
                        local spacingOK, previousSpacing = pcall(GameTooltip.GetCustomLineSpacing, GameTooltip)
                        if spacingOK and type(previousSpacing) == "number" then
                            self.tooltipPreviousLineSpacing = previousSpacing
                        end
                    end
                    self.tooltipLineSpacingSet = pcall(GameTooltip.SetCustomLineSpacing, GameTooltip, 2)
                end
                local addons = {}
                for folderName, addon in pairs(installedAddons) do
                    local enabled = GetAddonEnabled(folderName, addon.index)
                    local loaded = IsAddonLoaded(folderName)
                    local loadable, loadReason = GetAddonLoadability(folderName, addon.index)
                    addons[#addons + 1] = {
                        name = folderName,
                        title = addon.title or folderName,
                        installed = true,
                        currentEnabled = enabled,
                        loaded = loaded,
                        loadable = loadable,
                        loadReason = loadReason,
                        locked = addon.locked,
                    }
                end
                table.sort(addons, function(a, b)
                    local aTitle = tostring(a.title):lower()
                    local bTitle = tostring(b.title):lower()
                    if aTitle == bTitle then
                        return a.name:lower() < b.name:lower()
                    end
                    return aTitle < bTitle
                end)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Addons", 1, 0.82, 0.25)
                if #addons == 0 then
                    GameTooltip:AddLine("No installed addons found", 0.7, 0.7, 0.7)
                else
                    for _, addon in ipairs(addons) do
                        local _, red, green, blue = GetAddonRuntimePresentation(addon)
                        GameTooltip:AddLine(addon.title, red, green, blue, true)
                    end
                end
            end
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function(self)
        self.lastHoverTime = GetTimeSafe()
        if GameTooltip then
            GameTooltip:Hide()
            if self.tooltipLineSpacingSet and type(GameTooltip.SetCustomLineSpacing) == "function" then
                pcall(GameTooltip.SetCustomLineSpacing, GameTooltip, self.tooltipPreviousLineSpacing or 0)
            end
        end
        self.tooltipLineSpacingSet = false
        self.tooltipPreviousLineSpacing = nil
    end)

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton ~= "LeftButton" then
            return
        end
        if self.lastDragStop and GetTimeSafe() - self.lastDragStop < 0.25 then
            return
        end
        if not TryCreatePanel() then
            return
        end
        if panel:IsShown() then
            RequestNavigation(ClosePanelNow)
        else
            panel:Show()
        end
    end)

    button:SetScript("OnDragStart", function(self)
        self.dragging = true
        self.lastHoverTime = GetTimeSafe()
    end)

    button:SetScript("OnDragStop", function(self)
        self.dragging = false
        self.lastDragStop = GetTimeSafe()
        self.lastHoverTime = self.lastDragStop
        UpdateMinimapButtonPosition(true)
    end)

    button:SetScript("OnUpdate", function(self, elapsed)
        if self.dragging and Minimap and type(GetCursorPosition) == "function" then
            local cursorX, cursorY = GetCursorPosition()
            local centerX, centerY = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            if cursorX and cursorY and centerX and centerY and scale and scale ~= 0 then
                cursorX = cursorX / scale
                cursorY = cursorY / scale
                local deltaX = cursorX - centerX
                local deltaY = cursorY - centerY
                local angle
                if math.atan2 then
                    angle = math.atan2(deltaY, deltaX)
                else
                    angle = math.atan(deltaY / (deltaX == 0 and 0.000001 or deltaX))
                    if deltaX < 0 then
                        angle = angle + math.pi
                    end
                end
                db.minimap.angle = math.deg(angle) % 360
                UpdateMinimapButtonPosition()
            end
        end

        local overMinimap = Minimap and Minimap.IsMouseOver and Minimap:IsMouseOver()
        local overButton = self.IsMouseOver and self:IsMouseOver()
        local now = GetTimeSafe()
        if overMinimap or overButton or self.dragging then
            self.lastHoverTime = now
            self:SetAlpha(1)
        else
            local lastHover = self.lastHoverTime or now
            if now - lastHover >= MINIMAP_FADE_DELAY then
                local idleAlpha = db and db.minimap and tonumber(db.minimap.idleAlpha) or DEFAULT_IDLE_ALPHA
                local alpha = self:GetAlpha() or 1
                alpha = math.max(idleAlpha, alpha - (elapsed * MINIMAP_FADE_SPEED))
                self:SetAlpha(alpha)
            else
                self:SetAlpha(1)
            end
        end
    end)

    button.lastHoverTime = GetTimeSafe()
    minimapButton = button
    UpdateMinimapButtonPosition(true)

    -- Some UI layouts create the minimap after the addon loads, so retry its placement.
    if C_Timer and type(C_Timer.NewTicker) == "function" and not minimapPositionTicker then
        minimapPositionTicker = C_Timer.NewTicker(1, function()
            UpdateMinimapButtonPosition(false)
        end)
    end

    if db.minimap.hidden then
        button:Hide()
    else
        button:Show()
    end
end


TryCreatePanel = function()
    if panelCreationError then
        Print("The settings window could not be created: " .. panelCreationError)
        return false
    end
    if panel then
        return true
    end

    local ok, err = pcall(CreatePanel)
    if not ok then
        panelCreationError = tostring(err)
        Print("Could not create the settings window: " .. panelCreationError)
        return false
    end
    return panel ~= nil
end

TryCreateMinimapButton = function()
    if minimapButton then
        return true
    end
    if not db or not Minimap then
        return false
    end

    local ok, err = pcall(CreateMinimapButton)
    if not ok then
        minimapRetryErrorShown = true
        Print("Could not create the minimap button: " .. tostring(err))
        return false
    end
    return minimapButton ~= nil
end

local function RunStartupStep(label, callback)
    local ok, err = pcall(callback)
    if not ok then
        Print("Startup issue while " .. label .. ": " .. tostring(err))
        return false
    end
    return true
end

local function CreateSlashCommands()
    if type(_G.SlashCmdList) ~= "table" then
        _G.SlashCmdList = {}
    end

    _G.SLASH_FOREVERADDONMANAGERPLUS1 = "/famp"
    _G.SLASH_FOREVERADDONMANAGERPLUS2 = "/foreveraddonsplus"
    _G.SlashCmdList.FOREVERADDONMANAGERPLUS = function(message)
        local ok, err = pcall(function()
            local command = Trim(message):lower()
            if command == "scan" or command == "refresh" then
                RefreshInstalledList()
            elseif command == "minimap" then
                ToggleMinimapButton()
            elseif command == "location" then
                local key, zone = DetectLocation()
                Print("Detected " .. tostring(LOCATION_LABELS[key] or key) .. " in " .. tostring(zone) .. ".")
            elseif command == "reload" then
                if pendingReload and not IsInCombatLockdownSafe() and type(ReloadUI) == "function" then
                    ReloadUI()
                else
                    Print("No reload is pending, or a reload is unavailable during combat.")
                end
            elseif command == "status" then
                Print("Settings: " .. (db and "ready" or "not initialized") .. "; window: " .. (panelCreationError and "error" or (panel and "created" or "not created")) .. "; minimap: " .. (minimapButton and (db and db.minimap.hidden and "hidden" or "created") or (Minimap and "waiting for creation" or "waiting for minimap")) .. ".")
                if panelCreationError then
                    Print("Window error: " .. panelCreationError)
                end
                if minimapRetryErrorShown then
                    Print("Minimap creation reported an error. Try /famp minimap to retry.")
                end
            elseif command == "help" then
                Print("/famp — open settings; /famp scan — refresh installed addons; /famp minimap — show/hide minimap button; /famp location — report detected location type; /famp reload — reload if addon changes are pending; /famp status — report startup status.")
            else
                if not TryCreatePanel() then
                    return
                end
                if panel:IsShown() then
                    RequestNavigation(ClosePanelNow)
                else
                    panel:Show()
                end
            end
        end)
        if not ok then
            Print("Command failed: " .. tostring(err))
        end
    end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("ZONE_CHANGED")
driver:RegisterEvent("ZONE_CHANGED_INDOORS")
driver:RegisterEvent("ZONE_CHANGED_NEW_AREA")
driver:RegisterEvent("UPDATE_INSTANCE_INFO")
driver:RegisterEvent("PLAYER_UPDATE_RESTING")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")
driver:RegisterEvent("DISPLAY_SIZE_CHANGED")
driver:RegisterEvent("UI_SCALE_CHANGED")

local initialized = false
driver:SetScript("OnUpdate", function(_, elapsed)
    if not initialized or minimapButton or minimapRetryErrorShown then
        return
    end
    minimapRetryElapsed = minimapRetryElapsed + (elapsed or 0)
    if minimapRetryElapsed < 1 then
        return
    end
    minimapRetryElapsed = 0
    TryCreateMinimapButton()
end)

driver:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_FOLDER then
            RunStartupStep("registering slash commands", CreateSlashCommands)
            RunStartupStep("initializing saved settings", EnsureDatabase)
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        if initialized then
            return
        end

        RunStartupStep("registering slash commands", CreateSlashCommands)
        local databaseReady = RunStartupStep("initializing saved settings", EnsureDatabase)
        if not databaseReady then
            Print("The manager could not initialize its saved settings. Slash commands are available for diagnosis.")
            return
        end

        initialized = true
        RunStartupStep("scanning installed addons", ScanInstalledAddons)
        local panelReady = TryCreatePanel()
        if not panelReady then
            Print("The manager loaded, but its settings window needs attention. Type /famp status for details.")
        end
        TryCreateMinimapButton()
        RunStartupStep("detecting the current location", CheckLocation)
        Print("Loaded. Type /famp to manage addon profiles by location and class/role.")
        Print("Your registry and profiles retain missing addons; the installed-addon scan never deletes saved entries.")
        return
    end

    if not initialized then
        return
    end

    if event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then
        UpdatePanelScale()
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if pendingApplication then
            CheckLocation()
        end
        if pendingReload then
            ShowReloadPrompt()
        end
        return
    end

    if event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED"
        or event == "ZONE_CHANGED_INDOORS"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "UPDATE_INSTANCE_INFO"
        or event == "PLAYER_UPDATE_RESTING" then
        TryCreateMinimapButton()
        if C_Timer and type(C_Timer.After) == "function" then
            C_Timer.After(0.25, CheckLocation)
        else
            CheckLocation()
        end
    end
end)
