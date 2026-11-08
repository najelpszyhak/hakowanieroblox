--[[
    MAIN SCRIPT - ROBLOX EXECUTOR
    Główny skrypt funkcyjny łączący wszystkie moduły
    - Integracja z UI Library (Rayfield)
    - ESP, Combat, Movement modules
    - Anti-detection system
    - Complete cleanup on exit
]]--

print([[
═══════════════════════════════════════════════════
    ROBLOX MAIN SCRIPT v1.0
    Loaded successfully
═══════════════════════════════════════════════════
]])

-- ═══════════════════════════════════════════════════════════
-- LOAD MODULES
-- ═══════════════════════════════════════════════════════════

-- UWAGA: Zmień URL na swoje hosty lub użyj loadstring z lokalnych plików
local MODULES_BASE_URL = "https://raw.githubusercontent.com/your-repo/main/modules/"

local function loadModule(name)
    local success, module = pcall(function()
        return loadstring(game:HttpGet(MODULES_BASE_URL .. name .. ".lua"))()
    end)

    if success then
        print("[Main] Loaded module:", name)
        return module
    else
        warn("[Main] Failed to load module:", name, module)
        return nil
    end
end

-- Load modules
local AntiDetect = loadModule("anti-detect")
local ESP = loadModule("esp")
local Combat = loadModule("combat")
local Movement = loadModule("movement")

if not AntiDetect or not ESP or not Combat or not Movement then
    error("[Main] Critical modules failed to load - aborting")
end

-- ═══════════════════════════════════════════════════════════
-- ENVIRONMENT CHECK
-- ═══════════════════════════════════════════════════════════

local envCheck = AntiDetect.checkEnvironmentIntegrity()

print("\n[Environment Check]")
print("  Drawing API:", envCheck.drawing_api and "✓" or "✗")
print("  Metatable Access:", envCheck.metatable_access and "✓" or "✗")
print("  Hooking Available:", envCheck.hooking_available and "✓" or "✗")
print("  Caller Check:", envCheck.caller_check and "✓" or "✗")
print()

-- ═══════════════════════════════════════════════════════════
-- UI LIBRARY (RAYFIELD)
-- ═══════════════════════════════════════════════════════════

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🔐 Roblox Script Hub",
    LoadingTitle = "Loading Script...",
    LoadingSubtitle = "by YourName",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "RobloxScriptConfig",
        FileName = "config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

-- ═══════════════════════════════════════════════════════════
-- ESP TAB
-- ═══════════════════════════════════════════════════════════

local ESPTab = Window:CreateTab("👁️ ESP", nil)
local ESPSection = ESPTab:CreateSection("Visual ESP")

-- ESP Master Toggle
local ESPToggle = ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(Value)
        ESP.Settings.Enabled = Value
        if Value then
            ESP.Enable()
        else
            ESP.Disable()
        end
    end
})

-- Box ESP
ESPTab:CreateToggle({
    Name = "Box ESP",
    CurrentValue = true,
    Flag = "BoxESP",
    Callback = function(Value)
        ESP.Settings.BoxEnabled = Value
    end
})

-- Skeleton ESP
ESPTab:CreateToggle({
    Name = "Skeleton ESP",
    CurrentValue = true,
    Flag = "SkeletonESP",
    Callback = function(Value)
        ESP.Settings.SkeletonEnabled = Value
    end
})

-- Tracers
ESPTab:CreateToggle({
    Name = "Tracers",
    CurrentValue = true,
    Flag = "Tracers",
    Callback = function(Value)
        ESP.Settings.TracersEnabled = Value
    end
})

-- Name ESP
ESPTab:CreateToggle({
    Name = "Name ESP",
    CurrentValue = true,
    Flag = "NameESP",
    Callback = function(Value)
        ESP.Settings.NameEnabled = Value
    end
})

-- Health Bar
ESPTab:CreateToggle({
    Name = "Health Bar",
    CurrentValue = true,
    Flag = "HealthBar",
    Callback = function(Value)
        ESP.Settings.HealthBarEnabled = Value
    end
})

-- Distance ESP
ESPTab:CreateToggle({
    Name = "Distance",
    CurrentValue = true,
    Flag = "Distance",
    Callback = function(Value)
        ESP.Settings.DistanceEnabled = Value
    end
})

ESPSection = ESPTab:CreateSection("Settings")

-- Team Check
ESPTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "TeamCheck",
    Callback = function(Value)
        ESP.Settings.TeamCheck = Value
    end
})

-- Max Distance
ESPTab:CreateSlider({
    Name = "Max Distance",
    Range = {100, 5000},
    Increment = 50,
    CurrentValue = 1000,
    Flag = "MaxDistance",
    Callback = function(Value)
        ESP.Settings.MaxDistance = Value
    end
})

-- ESP Color Picker
ESPTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "ESPColor",
    Callback = function(Value)
        ESP.Settings.BoxColor = Value
        ESP.Settings.SkeletonColor = Value
        ESP.Settings.TracersColor = Value
        ESP.Settings.NameColor = Value
    end
})

-- ═══════════════════════════════════════════════════════════
-- COMBAT TAB
-- ═══════════════════════════════════════════════════════════

local CombatTab = Window:CreateTab("🎯 Combat", nil)
local AimbotSection = CombatTab:CreateSection("Aimbot")

-- Aimbot Toggle
CombatTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "AimbotEnabled",
    Callback = function(Value)
        Combat.Settings.AimbotEnabled = Value
    end
})

-- Aimbot Smoothness
CombatTab:CreateSlider({
    Name = "Smoothness",
    Range = {0, 1},
    Increment = 0.01,
    CurrentValue = 0.1,
    Flag = "AimbotSmoothness",
    Callback = function(Value)
        Combat.Settings.AimbotSmoothness = Value
    end
})

-- Aimbot Target Part
CombatTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso"},
    CurrentOption = "Head",
    Flag = "AimbotTargetPart",
    Callback = function(Option)
        Combat.Settings.AimbotTargetPart = Option
    end
})

-- Aimbot Prediction
CombatTab:CreateToggle({
    Name = "Prediction",
    CurrentValue = true,
    Flag = "AimbotPrediction",
    Callback = function(Value)
        Combat.Settings.AimbotPrediction = Value
    end
})

local SilentAimSection = CombatTab:CreateSection("Silent Aim")

-- Silent Aim Toggle
CombatTab:CreateToggle({
    Name = "Enable Silent Aim",
    CurrentValue = false,
    Flag = "SilentAimEnabled",
    Callback = function(Value)
        Combat.Settings.SilentAimEnabled = Value
    end
})

-- Silent Aim Target Part
CombatTab:CreateDropdown({
    Name = "Silent Target Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso"},
    CurrentOption = "HumanoidRootPart",
    Flag = "SilentTargetPart",
    Callback = function(Option)
        Combat.Settings.SilentAimTargetPart = Option
    end
})

local FOVSection = CombatTab:CreateSection("FOV Circle")

-- FOV Circle Toggle
CombatTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,
    Flag = "FOVCircle",
    Callback = function(Value)
        Combat.Settings.FOVCircleEnabled = Value
    end
})

-- FOV Radius
CombatTab:CreateSlider({
    Name = "FOV Radius",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 150,
    Flag = "FOVRadius",
    Callback = function(Value)
        Combat.Settings.FOVRadius = Value
    end
})

-- FOV Color
CombatTab:CreateColorPicker({
    Name = "FOV Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "FOVColor",
    Callback = function(Value)
        Combat.Settings.FOVColor = Value
    end
})

local TargetingSection = CombatTab:CreateSection("Targeting")

-- Team Check
CombatTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "CombatTeamCheck",
    Callback = function(Value)
        Combat.Settings.TeamCheck = Value
    end
})

-- Visibility Check
CombatTab:CreateToggle({
    Name = "Visibility Check",
    CurrentValue = true,
    Flag = "VisibilityCheck",
    Callback = function(Value)
        Combat.Settings.VisibilityCheck = Value
    end
})

-- ═══════════════════════════════════════════════════════════
-- MOVEMENT TAB
-- ═══════════════════════════════════════════════════════════

local MovementTab = Window:CreateTab("🚀 Movement", nil)
local FlySection = MovementTab:CreateSection("Fly")

-- Fly Toggle
MovementTab:CreateToggle({
    Name = "Enable Fly",
    CurrentValue = false,
    Flag = "FlyEnabled",
    Callback = function(Value)
        if Value then
            Movement.StartFly()
        else
            Movement.StopFly()
        end
    end
})

-- Fly Speed
MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(Value)
        Movement.SetFlySpeed(Value)
    end
})

-- Fly Keybind
MovementTab:CreateKeybind({
    Name = "Fly Keybind",
    CurrentKeybind = "E",
    HoldToInteract = false,
    Flag = "FlyKeybind",
    Callback = function(Keybind)
        -- Keybind jest już obsługiwany w module Movement
    end
})

local NoclipSection = MovementTab:CreateSection("Noclip")

-- Noclip Toggle
MovementTab:CreateToggle({
    Name = "Enable Noclip",
    CurrentValue = false,
    Flag = "NoclipEnabled",
    Callback = function(Value)
        if Value then
            Movement.StartNoclip()
        else
            Movement.StopNoclip()
        end
    end
})

-- Noclip Keybind
MovementTab:CreateKeybind({
    Name = "Noclip Keybind",
    CurrentKeybind = "N",
    HoldToInteract = false,
    Flag = "NoclipKeybind",
    Callback = function(Keybind)
        -- Keybind jest już obsługiwany w module Movement
    end
})

-- ═══════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════════════════════

local SettingsTab = Window:CreateTab("⚙️ Settings", nil)
local GeneralSection = SettingsTab:CreateSection("General")

-- Unload Script Button
SettingsTab:CreateButton({
    Name = "Unload Script",
    Callback = function()
        print("[Main] Unloading script...")

        -- Cleanup wszystkich modułów
        ESP.Disable()
        Combat.Cleanup()
        Movement.Cleanup()
        AntiDetect.cleanup()

        -- Zamknij UI
        Rayfield:Destroy()

        print("[Main] Script unloaded successfully")
    end
})

-- Anti-Detection Info
SettingsTab:CreateLabel("Anti-Detection Status")
SettingsTab:CreateLabel(envCheck.drawing_api and "✓ Drawing API" or "✗ Drawing API")
SettingsTab:CreateLabel(envCheck.hooking_available and "✓ Hooking" or "✗ Hooking")
SettingsTab:CreateLabel(envCheck.caller_check and "✓ Caller Check" or "✗ Caller Check")

-- ═══════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════

-- Enable Combat (for FOV circle and hooks)
Combat.Enable()

print("\n[Main] Script fully loaded!")
print("[Main] Press RightShift to toggle UI")
print("═══════════════════════════════════════════════════\n")
