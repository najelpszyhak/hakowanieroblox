--[[
    ROBLOX KEY SYSTEM UI - ETAP 2
    Nowoczesny dark theme z weryfikacją przez backend API
    Features: HMAC signing, HWID auto-detection, local key storage, environment protection
]]--

-- ═══════════════════════════════════════════════════════════
-- KONFIGURACJA API
-- ═══════════════════════════════════════════════════════════

local API_CONFIG = {
    BASE_URL = "http://178.63.21.58:26386/api/v11", -- Zmień na swój URL
    HMAC_SECRET = "91417184107873775137110962339886", -- Taki sam jak w .env
    ENDPOINTS = {
        VERIFY = "/verify",
        HEALTH = "/health"
    }
}

-- ═══════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════

local function safeRequire(module)
    local success, result = pcall(require, module)
    return success and result or nil
end

-- Crypto library dla HMAC (musisz dołączyć bibliotekę crypto do executora)
-- Alternatywnie możesz użyć własnej implementacji HMAC-SHA256
local crypto = safeRequire("crypto") or {}

-- Funkcja generująca HMAC-SHA256
local function generateHMAC(data, secret)
    if crypto and crypto.hmac then
        return crypto.hmac(crypto.sha256, data, secret)
    else
        -- Fallback: Jeśli brak biblioteki crypto, zwróć placeholder
        -- W produkcji MUSISZ użyć prawdziwej biblioteki crypto!
        warn("UWAGA: Brak biblioteki crypto - HMAC nie działa!")
        return "PLACEHOLDER_HMAC_" .. tostring(os.time())
    end
end

-- Generuje losowy GUID dla GUI naming
local function generateGUID()
    local HttpService = game:GetService("HttpService")
    return HttpService:GenerateGUID(false)
end

-- Pobiera HWID użytkownika
local function getHWID()
    local hwid = nil

    -- Metoda 1: gethwid() (najpopularniejsza w executorach)
    if gethwid then
        local success, result = pcall(gethwid)
        if success and result then
            hwid = result
        end
    end

    -- Metoda 2: AnalyticsService:GetClientId() (backup)
    if not hwid then
        local AnalyticsService = game:GetService("AnalyticsService")
        local success, result = pcall(function()
            return AnalyticsService:GetClientId()
        end)
        if success and result then
            hwid = result
        end
    end

    -- Metoda 3: game:GetService("RbxAnalyticsService")
    if not hwid then
        local success, RbxAnalytics = pcall(function()
            return game:GetService("RbxAnalyticsService")
        end)
        if success and RbxAnalytics then
            local cidSuccess, clientId = pcall(function()
                return RbxAnalytics:GetClientId()
            end)
            if cidSuccess and clientId then
                hwid = clientId
            end
        end
    end

    return hwid or "UNKNOWN_HWID_" .. tostring(game.Players.LocalPlayer.UserId)
end

-- Zapisuje klucz lokalnie
local function saveKey(key)
    if writefile then
        local success, err = pcall(function()
            writefile("roblox_license_key.txt", key)
        end)
        if not success then
            warn("Nie udało się zapisać klucza:", err)
        end
    end
end

-- Odczytuje zapisany klucz
local function loadSavedKey()
    if readfile and isfile and isfile("roblox_license_key.txt") then
        local success, key = pcall(function()
            return readfile("roblox_license_key.txt")
        end)
        if success and key and key ~= "" then
            return key
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════
-- ENVIRONMENT INTEGRITY CHECKS
-- ═══════════════════════════════════════════════════════════

local function checkEnvironmentIntegrity()
    local checks = {
        http_service = game:GetService("HttpService").HttpEnabled,
        executor_detected = (gethwid ~= nil or getexecutorname ~= nil),
        core_functions = (writefile ~= nil and readfile ~= nil)
    }

    return checks.http_service and checks.executor_detected
end

-- ═══════════════════════════════════════════════════════════
-- API COMMUNICATION
-- ═══════════════════════════════════════════════════════════

local function verifyKeyWithAPI(keyCode, hwid, callback)
    local HttpService = game:GetService("HttpService")

    local timestamp = tostring(os.time() * 1000)
    local body = HttpService:JSONEncode({
        key_code = keyCode,
        hwid = hwid
    })

    -- Generuj HMAC signature
    local data = timestamp .. body
    local signature = generateHMAC(data, API_CONFIG.HMAC_SECRET)

    local url = API_CONFIG.BASE_URL .. API_CONFIG.ENDPOINTS.VERIFY

    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["X-Signature"] = signature,
                ["X-Request-Timestamp"] = timestamp
            },
            Body = body
        })
    end)

    if success then
        local responseData = HttpService:JSONDecode(response.Body)
        callback(responseData.success, responseData)
    else
        callback(false, {
            error = "CONNECTION_FAILED",
            message = "Nie można połączyć się z API: " .. tostring(response)
        })
    end
end

-- ═══════════════════════════════════════════════════════════
-- GUI CREATION
-- ═══════════════════════════════════════════════════════════

local function createKeySystemUI()
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    -- Losowa nazwa GUI (anty-detekcja)
    local guiName = generateGUID()

    -- Główny ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = guiName
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui

    -- Main Frame (container)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 450, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    -- Drop shadow effect
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 10, 10)
    shadow.ZIndex = 0
    shadow.Parent = mainFrame

    -- Header bar
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    header.BorderSizePixel = 0
    header.Parent = mainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header

    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔐 License Verification"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    -- Status indicator (colored dot)
    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.new(0, 10, 0, 10)
    statusDot.Position = UDim2.new(1, -25, 0.5, -5)
    statusDot.BackgroundColor3 = Color3.fromRGB(255, 170, 0) -- Orange (loading)
    statusDot.BorderSizePixel = 0
    statusDot.Parent = header

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = statusDot

    -- Content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -40, 1, -80)
    content.Position = UDim2.new(0, 20, 0, 70)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame

    -- Key input label
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Name = "KeyLabel"
    keyLabel.Size = UDim2.new(1, 0, 0, 20)
    keyLabel.Position = UDim2.new(0, 0, 0, 0)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Text = "License Key"
    keyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    keyLabel.TextSize = 14
    keyLabel.Font = Enum.Font.Gotham
    keyLabel.TextXAlignment = Enum.TextXAlignment.Left
    keyLabel.Parent = content

    -- Key input box
    local keyInput = Instance.new("TextBox")
    keyInput.Name = "KeyInput"
    keyInput.Size = UDim2.new(1, 0, 0, 45)
    keyInput.Position = UDim2.new(0, 0, 0, 25)
    keyInput.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    keyInput.BorderSizePixel = 0
    keyInput.Text = ""
    keyInput.PlaceholderText = "XXXX-XXXX-XXXX-XXXX"
    keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
    keyInput.TextSize = 16
    keyInput.Font = Enum.Font.GothamMedium
    keyInput.ClearTextOnFocus = false
    keyInput.Parent = content

    local keyInputCorner = Instance.new("UICorner")
    keyInputCorner.CornerRadius = UDim.new(0, 8)
    keyInputCorner.Parent = keyInput

    local keyInputPadding = Instance.new("UIPadding")
    keyInputPadding.PaddingLeft = UDim.new(0, 15)
    keyInputPadding.PaddingRight = UDim.new(0, 15)
    keyInputPadding.Parent = keyInput

    -- Buttons container
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Name = "ButtonsFrame"
    buttonsFrame.Size = UDim2.new(1, 0, 0, 45)
    buttonsFrame.Position = UDim2.new(0, 0, 0, 85)
    buttonsFrame.BackgroundTransparency = 1
    buttonsFrame.Parent = content

    -- Login button
    local loginButton = Instance.new("TextButton")
    loginButton.Name = "LoginButton"
    loginButton.Size = UDim2.new(0.65, -5, 1, 0)
    loginButton.Position = UDim2.new(0, 0, 0, 0)
    loginButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242) -- Discord blurple
    loginButton.BorderSizePixel = 0
    loginButton.Text = "Zaloguj"
    loginButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    loginButton.TextSize = 16
    loginButton.Font = Enum.Font.GothamBold
    loginButton.AutoButtonColor = false
    loginButton.Parent = buttonsFrame

    local loginCorner = Instance.new("UICorner")
    loginCorner.CornerRadius = UDim.new(0, 8)
    loginCorner.Parent = loginButton

    -- Copy HWID button
    local copyButton = Instance.new("TextButton")
    copyButton.Name = "CopyButton"
    copyButton.Size = UDim2.new(0.35, -5, 1, 0)
    copyButton.Position = UDim2.new(0.65, 5, 0, 0)
    copyButton.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    copyButton.BorderSizePixel = 0
    copyButton.Text = "Kopiuj HWID"
    copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyButton.TextSize = 14
    copyButton.Font = Enum.Font.GothamMedium
    copyButton.AutoButtonColor = false
    copyButton.Parent = buttonsFrame

    local copyCorner = Instance.new("UICorner")
    copyCorner.CornerRadius = UDim.new(0, 8)
    copyCorner.Parent = copyButton

    -- Status text
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, 0, 0, 50)
    statusText.Position = UDim2.new(0, 0, 0, 145)
    statusText.BackgroundTransparency = 1
    statusText.Text = ""
    statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusText.TextSize = 13
    statusText.Font = Enum.Font.Gotham
    statusText.TextWrapped = true
    statusText.TextYAlignment = Enum.TextYAlignment.Top
    statusText.Parent = content

    -- Loading spinner (hidden by default)
    local spinner = Instance.new("ImageLabel")
    spinner.Name = "Spinner"
    spinner.Size = UDim2.new(0, 20, 0, 20)
    spinner.Position = UDim2.new(0.5, -10, 0, 150)
    spinner.BackgroundTransparency = 1
    spinner.Image = "rbxassetid://4846392843" -- Loading circle
    spinner.ImageColor3 = Color3.fromRGB(88, 101, 242)
    spinner.Visible = false
    spinner.Parent = content

    -- ═══════════════════════════════════════════════════════════
    -- ANIMATIONS & INTERACTIONS
    -- ═══════════════════════════════════════════════════════════

    -- Spinner rotation animation
    local spinnerTween = TweenService:Create(
        spinner,
        TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        {Rotation = 360}
    )

    -- Button hover effects
    local function setupButtonHover(button, hoverColor, normalColor)
        button.MouseEnter:Connect(function()
            TweenService:Create(
                button,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = hoverColor}
            ):Play()
        end)

        button.MouseLeave:Connect(function()
            TweenService:Create(
                button,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = normalColor}
            ):Play()
        end)
    end

    setupButtonHover(loginButton, Color3.fromRGB(98, 111, 252), Color3.fromRGB(88, 101, 242))
    setupButtonHover(copyButton, Color3.fromRGB(55, 55, 70), Color3.fromRGB(45, 45, 60))

    -- ═══════════════════════════════════════════════════════════
    -- FUNCTIONALITY
    -- ═══════════════════════════════════════════════════════════

    local isVerifying = false
    local currentHWID = getHWID()

    -- Funkcja zmiany statusu
    local function setStatus(message, color, showSpinner)
        statusText.Text = message
        statusText.TextColor3 = color or Color3.fromRGB(200, 200, 200)
        spinner.Visible = showSpinner or false

        if showSpinner then
            spinnerTween:Play()
        else
            spinnerTween:Cancel()
            spinner.Rotation = 0
        end
    end

    -- Funkcja zmiany koloru kropki statusu
    local function setStatusDot(color)
        TweenService:Create(
            statusDot,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad),
            {BackgroundColor3 = color}
        ):Play()
    end

    -- Kopiowanie HWID do schowka
    copyButton.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(currentHWID)
            setStatus("✓ HWID skopiowany do schowka", Color3.fromRGB(100, 255, 100), false)
            task.wait(2)
            setStatus("", Color3.fromRGB(200, 200, 200), false)
        else
            setStatus("✗ Brak funkcji setclipboard w executorze", Color3.fromRGB(255, 100, 100), false)
        end
    end)

    -- Weryfikacja klucza
    local function attemptLogin()
        if isVerifying then return end

        local key = keyInput.Text:gsub("%s+", "") -- Usuń białe znaki

        if key == "" then
            setStatus("✗ Wprowadź klucz licencji", Color3.fromRGB(255, 170, 0), false)
            return
        end

        isVerifying = true
        loginButton.Text = "Weryfikacja..."
        setStatus("⟳ Łączenie z serwerem...", Color3.fromRGB(200, 200, 200), true)
        setStatusDot(Color3.fromRGB(255, 170, 0)) -- Orange

        verifyKeyWithAPI(key, currentHWID, function(success, data)
            isVerifying = false
            loginButton.Text = "Zaloguj"
            spinnerTween:Cancel()
            spinner.Visible = false

            if success then
                setStatus("✓ " .. data.message, Color3.fromRGB(100, 255, 100), false)
                setStatusDot(Color3.fromRGB(100, 255, 100)) -- Green

                -- Zapisz klucz lokalnie
                saveKey(key)

                -- Animacja fade out
                TweenService:Create(
                    mainFrame,
                    TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {BackgroundTransparency = 1}
                ):Play()

                for _, child in ipairs(mainFrame:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                        TweenService:Create(
                            child,
                            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {TextTransparency = 1}
                        ):Play()
                    end
                    if child:IsA("Frame") or child:IsA("ImageLabel") then
                        TweenService:Create(
                            child,
                            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {BackgroundTransparency = 1, ImageTransparency = 1}
                        ):Play()
                    end
                end

                task.wait(1)

                -- Usuń GUI
                screenGui:Destroy()

                -- TUTAJ ZAŁADUJ GŁÓWNY SKRYPT (ETAP 3)
                -- loadstring(game:HttpGet("URL_DO_GŁÓWNEGO_SKRYPTU"))()
                print("✓ Weryfikacja pomyślna - gotowy do załadowania głównego skryptu")

            else
                setStatus("✗ " .. (data.message or "Błąd weryfikacji"), Color3.fromRGB(255, 100, 100), false)
                setStatusDot(Color3.fromRGB(255, 100, 100)) -- Red
            end
        end)
    end

    loginButton.MouseButton1Click:Connect(attemptLogin)

    -- Enter key support
    keyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            attemptLogin()
        end
    end)

    -- ═══════════════════════════════════════════════════════════
    -- AUTO-LOGIN (jeśli klucz zapisany)
    -- ═══════════════════════════════════════════════════════════

    local savedKey = loadSavedKey()
    if savedKey then
        keyInput.Text = savedKey
        setStatus("Znaleziono zapisany klucz - kliknij Zaloguj", Color3.fromRGB(200, 200, 255), false)
        setStatusDot(Color3.fromRGB(100, 150, 255)) -- Blue
    end

    -- Sprawdź integrity środowiska
    if not checkEnvironmentIntegrity() then
        setStatus("⚠ Wykryto problemy ze środowiskiem", Color3.fromRGB(255, 170, 0), false)
        setStatusDot(Color3.fromRGB(255, 170, 0))
    else
        setStatusDot(Color3.fromRGB(100, 255, 100)) -- Green = ready
    end

    -- Wyświetl HWID w konsoli dla debug
    print("═══════════════════════════════════════════")
    print("Roblox License System - Key System UI")
    print("═══════════════════════════════════════════")
    print("HWID:", currentHWID)
    print("API URL:", API_CONFIG.BASE_URL)
    print("═══════════════════════════════════════════")
end

-- ═══════════════════════════════════════════════════════════
-- MAIN EXECUTION
-- ═══════════════════════════════════════════════════════════

-- Sprawdź czy HttpService jest włączony
local HttpService = game:GetService("HttpService")
if not HttpService.HttpEnabled then
    warn("HttpService nie jest włączony! Weryfikacja nie zadziała.")
end

-- Utwórz UI
createKeySystemUI()

