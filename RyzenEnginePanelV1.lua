--[[
    RyzenEnginePanelV1
    Лёгкая, но нарядная UI-библиотека для Roblox (Luau).

    Тема: чёрный / тёмно-зелёный, с лёгкими "хэллоуинскими" нотками —
    по фону панели плавают тусклые зелёные огоньки (частицы).

    Возможности:
      • перетаскиваемая панель с угловатым, слегка вытянутым силуэтом
        (срезанные / скошенные уголки вместо простого прямоугольника)
      • вкладки (Tabs)
      • элементы: Label, Button, Toggle, Slider, Dropdown, ColorPicker
      • встроенная вкладка "Settings" — размер панели и прозрачность
      • простое API, без внешних зависимостей

    Использование:

        local Ryzen = loadstring(readfile("RyzenEnginePanelV1.lua"))()
        -- или require(script.RyzenEnginePanelV1), если положить как ModuleScript

        local Window = Ryzen:CreateWindow({
            Title    = "RyzenEnginePanelV1",
            SubTitle = "control surface",
        })

        local MainTab = Window:AddTab("Main")

        MainTab:AddLabel("Добро пожаловать")

        MainTab:AddButton({
            Text = "Сделать дело",
            Callback = function()
                print("клик")
            end,
        })

        MainTab:AddToggle({
            Text = "Автозапуск",
            Default = false,
            Callback = function(state)
                print("toggle:", state)
            end,
        })

        MainTab:AddSlider({
            Text = "Громкость",
            Min = 0, Max = 100, Default = 50,
            Callback = function(value)
                print("slider:", value)
            end,
        })

        MainTab:AddColorPicker({
            Text = "Цвет акцента",
            Default = Color3.fromRGB(60, 200, 110),
            Callback = function(color)
                print("color:", color)
            end,
        })

        -- вкладка Settings (размер/прозрачность) добавляется автоматически
]]

local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local Players         = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

--------------------------------------------------------------------
-- THEME
--------------------------------------------------------------------

local Theme = {
    Background   = Color3.fromRGB(10, 12, 10),
    Panel        = Color3.fromRGB(15, 18, 15),
    PanelAlt     = Color3.fromRGB(20, 24, 20),
    Border       = Color3.fromRGB(35, 90, 45),
    Accent       = Color3.fromRGB(60, 200, 110),
    AccentDim    = Color3.fromRGB(35, 120, 65),
    Text         = Color3.fromRGB(225, 235, 225),
    SubText      = Color3.fromRGB(140, 160, 140),
    Danger       = Color3.fromRGB(200, 70, 70),
    Font         = Enum.Font.GothamSemibold,
    FontBody     = Enum.Font.Gotham,
}

--------------------------------------------------------------------
-- UTILITIES
--------------------------------------------------------------------

local function new(class, props, children)
    local inst = Instance.new(class)
    for prop, value in pairs(props or {}) do
        inst[prop] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function tween(inst, info, props)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local QUICK  = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MEDIUM = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function makeDraggable(handle, target)
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = target.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- angular "cut corner" look: a rectangle with two opposite corners
-- clipped diagonally, built from a frame + two triangular masks that
-- match the background colour behind the panel.
local function cutCorners(frame, cutSize, bgColor)
    local function triangle(corner)
        local holder = new("Frame", {
            Name = "CornerCut",
            BackgroundTransparency = 1,
            Size = UDim2.new(0, cutSize, 0, cutSize),
            AnchorPoint = corner.anchor,
            Position = corner.position,
            ZIndex = (frame.ZIndex or 1) + 5,
        })
        local tri = new("ImageLabel", {
            Image = "rbxassetid://12266946128", -- generic white triangle
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ImageColor3 = bgColor,
            Rotation = corner.rotation,
            ZIndex = holder.ZIndex,
        })
        tri.Parent = holder
        holder.Parent = frame
    end

    triangle({ anchor = Vector2.new(0, 0), position = UDim2.new(0, 0, 0, 0), rotation = 0 })
    triangle({ anchor = Vector2.new(1, 1), position = UDim2.new(1, 0, 1, 0), rotation = 180 })
end

--------------------------------------------------------------------
-- LIBRARY
--------------------------------------------------------------------

local Library = {}
Library.__index = Library

function Library:CreateWindow(config)
    config = config or {}
    local title    = config.Title or "RyzenEnginePanelV1"
    local subTitle = config.SubTitle or "panel"

    --------------------------------------------------------------
    -- root
    --------------------------------------------------------------
    local ScreenGui = new("ScreenGui", {
        Name = "RyzenEnginePanelV1",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    })
    ScreenGui.Parent = PlayerGui

    local PANEL_W, PANEL_H = 560, 360 -- slightly long / rectangular-leaning

    local Main = new("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(PANEL_W, PANEL_H),
        Position = UDim2.new(0.5, -PANEL_W / 2, 0.5, -PANEL_H / 2),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        ClipsDescendants = false,
    })
    Main.Parent = ScreenGui

    new("UICorner", { CornerRadius = UDim.new(0, 6) }).Parent = Main
    new("UIStroke", {
        Color = Theme.Border,
        Thickness = 1.5,
        Transparency = 0.2,
    }).Parent = Main

    cutCorners(Main, 18, Theme.Background)

    --------------------------------------------------------------
    -- floating "halloween" ember particles (plain Frames, no assets)
    --------------------------------------------------------------
    local EmberLayer = new("Frame", {
        Name = "Embers",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 1,
    })
    EmberLayer.Parent = Main

    local function spawnEmber()
        local size = math.random(2, 4)
        local startX = math.random(0, PANEL_W)
        local ember = new("Frame", {
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(size, size),
            Position = UDim2.fromOffset(startX, PANEL_H + 10),
            ZIndex = 1,
        })
        new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = ember
        ember.Parent = EmberLayer

        local drift = math.random(-30, 30)
        local duration = math.random(5, 9)

        tween(ember, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            Position = UDim2.fromOffset(startX + drift, -10),
            BackgroundTransparency = 1,
        })

        task.delay(duration, function()
            ember:Destroy()
        end)
    end

    task.spawn(function()
        while Main.Parent do
            spawnEmber()
            task.wait(math.random(4, 9) / 10)
        end
    end)

    --------------------------------------------------------------
    -- header / title bar
    --------------------------------------------------------------
    local Header = new("Frame", {
        Name = "Header",
        BackgroundColor3 = Theme.PanelAlt,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 52),
        ZIndex = 2,
    })
    Header.Parent = Main
    new("UICorner", { CornerRadius = UDim.new(0, 6) }).Parent = Header

    -- square off the bottom corners of the header so it reads as a bar
    new("Frame", {
        BackgroundColor3 = Theme.PanelAlt,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        ZIndex = 2,
    }).Parent = Header

    new("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, 0),
        ZIndex = 3,
    }).Parent = Header

    new("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 6),
        Size = UDim2.new(1, -32, 0, 22),
        Font = Theme.Font,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
    }).Parent = Header

    new("TextLabel", {
        Name = "SubTitle",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 17, 0, 27),
        Size = UDim2.new(1, -32, 0, 16),
        Font = Theme.FontBody,
        Text = subTitle,
        TextColor3 = Theme.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
    }).Parent = Header

    local CloseBtn = new("TextButton", {
        Name = "Close",
        BackgroundColor3 = Theme.PanelAlt,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.new(1, -36, 0, 13),
        Font = Theme.Font,
        Text = "×",
        TextColor3 = Theme.SubText,
        TextSize = 18,
        ZIndex = 3,
        AutoButtonColor = false,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = CloseBtn
    CloseBtn.Parent = Header

    CloseBtn.MouseEnter:Connect(function()
        tween(CloseBtn, QUICK, { TextColor3 = Theme.Danger })
    end)
    CloseBtn.MouseLeave:Connect(function()
        tween(CloseBtn, QUICK, { TextColor3 = Theme.SubText })
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        tween(Main, MEDIUM, { Size = UDim2.fromOffset(0, 0) })
        task.delay(0.35, function()
            ScreenGui:Destroy()
        end)
    end)

    makeDraggable(Header, Main)

    --------------------------------------------------------------
    -- tab bar (left) + content (right)
    --------------------------------------------------------------
    local TabBar = new("Frame", {
        Name = "TabBar",
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 52),
        Size = UDim2.new(0, 140, 1, -52),
        ZIndex = 2,
    })
    TabBar.Parent = Main

    new("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }).Parent = TabBar
    new("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }).Parent = TabBar

    local ContentArea = new("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 140, 0, 52),
        Size = UDim2.new(1, -140, 1, -52),
        ZIndex = 2,
    })
    ContentArea.Parent = Main

    local Window = setmetatable({
        ScreenGui = ScreenGui,
        Main = Main,
        TabBar = TabBar,
        ContentArea = ContentArea,
        Tabs = {},
        _panelSize = { PANEL_W, PANEL_H },
    }, { __index = {} })

    --------------------------------------------------------------
    -- Tab object
    --------------------------------------------------------------
    local function buildTab(name)
        local TabButton = new("TextButton", {
            Name = name,
            BackgroundColor3 = Theme.PanelAlt,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 32),
            Font = Theme.FontBody,
            Text = "  " .. name,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Theme.SubText,
            TextSize = 14,
            AutoButtonColor = false,
        })
        new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = TabButton
        TabButton.Parent = TabBar

        local Indicator = new("Frame", {
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 3, 0.6, 0),
            Position = UDim2.new(0, 0, 0.2, 0),
            Visible = false,
        })
        new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = Indicator
        Indicator.Parent = TabButton

        local Page = new("ScrollingFrame", {
            Name = name .. "Page",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.AccentDim,
            Visible = false,
            ZIndex = 2,
        })
        new("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }).Parent = Page
        new("UIPadding", {
            PaddingTop = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14),
            PaddingBottom = UDim.new(0, 14),
        }).Parent = Page
        Page.Parent = ContentArea

        local Tab = {}

        local function select()
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                t.Indicator.Visible = false
                tween(t.Button, QUICK, { TextColor3 = Theme.SubText })
            end
            Page.Visible = true
            Indicator.Visible = true
            tween(TabButton, QUICK, { TextColor3 = Theme.Text })
        end

        TabButton.MouseButton1Click:Connect(select)
        TabButton.MouseEnter:Connect(function()
            if not Page.Visible then
                tween(TabButton, QUICK, { BackgroundColor3 = Theme.Panel })
            end
        end)
        TabButton.MouseLeave:Connect(function()
            tween(TabButton, QUICK, { BackgroundColor3 = Theme.PanelAlt })
        end)

        Tab.Button = TabButton
        Tab.Indicator = Indicator
        Tab.Page = Page
        Tab.Select = select

        ----------------------------------------------------------
        -- element builders
        ----------------------------------------------------------
        local function baseRow(height)
            local Row = new("Frame", {
                BackgroundColor3 = Theme.PanelAlt,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, height),
            })
            new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = Row
            new("UIStroke", {
                Color = Theme.Border,
                Thickness = 1,
                Transparency = 0.5,
            }).Parent = Row
            Row.Parent = Page
            return Row
        end

        function Tab:AddLabel(text)
            local Row = baseRow(28)
            Row.BackgroundTransparency = 1
            Row:FindFirstChildOfClass("UIStroke"):Destroy()
            new("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Font = Theme.FontBody,
                Text = text,
                TextColor3 = Theme.SubText,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
            }).Parent = Row
            return Row
        end

        function Tab:AddButton(opts)
            opts = opts or {}
            local Row = baseRow(36)
            local Btn = new("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Font = Theme.Font,
                Text = opts.Text or "Button",
                TextColor3 = Theme.Text,
                TextSize = 14,
                AutoButtonColor = false,
            })
            Btn.Parent = Row

            Btn.MouseEnter:Connect(function()
                tween(Row, QUICK, { BackgroundColor3 = Theme.AccentDim })
            end)
            Btn.MouseLeave:Connect(function()
                tween(Row, QUICK, { BackgroundColor3 = Theme.PanelAlt })
            end)
            Btn.MouseButton1Click:Connect(function()
                if opts.Callback then
                    task.spawn(opts.Callback)
                end
            end)
            return Row
        end

        function Tab:AddToggle(opts)
            opts = opts or {}
            local state = opts.Default or false
            local Row = baseRow(36)

            new("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                Font = Theme.FontBody,
                Text = opts.Text or "Toggle",
                TextColor3 = Theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            }).Parent = Row

            local Switch = new("Frame", {
                BackgroundColor3 = state and Theme.Accent or Theme.Background,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(38, 20),
                Position = UDim2.new(1, -48, 0.5, -10),
            })
            new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = Switch
            Switch.Parent = Row

            local Knob = new("Frame", {
                BackgroundColor3 = Theme.Text,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(16, 16),
                Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            })
            new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = Knob
            Knob.Parent = Switch

            local Click = new("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
            })
            Click.Parent = Row

            local function set(newState, fire)
                state = newState
                tween(Switch, QUICK, { BackgroundColor3 = state and Theme.Accent or Theme.Background })
                tween(Knob, QUICK, { Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) })
                if fire and opts.Callback then
                    task.spawn(opts.Callback, state)
                end
            end

            Click.MouseButton1Click:Connect(function()
                set(not state, true)
            end)

            if state and opts.Callback then
                task.spawn(opts.Callback, state)
            end

            return { Row = Row, Set = function(v) set(v, true) end, Get = function() return state end }
        end

        function Tab:AddSlider(opts)
            opts = opts or {}
            local min, max = opts.Min or 0, opts.Max or 100
            local value = math.clamp(opts.Default or min, min, max)
            local suffix = opts.Suffix or ""

            local Row = baseRow(46)

            new("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 4),
                Size = UDim2.new(1, -20, 0, 16),
                Font = Theme.FontBody,
                Text = opts.Text or "Slider",
                TextColor3 = Theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
            }).Parent = Row

            local ValueLabel = new("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -70, 0, 4),
                Size = UDim2.new(0, 60, 0, 16),
                Font = Theme.FontBody,
                Text = tostring(value) .. suffix,
                TextColor3 = Theme.SubText,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
            })
            ValueLabel.Parent = Row

            local Track = new("Frame", {
                BackgroundColor3 = Theme.Background,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 10, 1, -14),
                Size = UDim2.new(1, -20, 0, 6),
            })
            new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = Track
            Track.Parent = Row

            local Fill = new("Frame", {
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
            })
            new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = Fill
            Fill.Parent = Track

            local dragging = false

            local function update(input)
                local relX = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * relX + 0.5)
                Fill.Size = UDim2.new(relX, 0, 1, 0)
                ValueLabel.Text = tostring(value) .. suffix
                if opts.Callback then
                    task.spawn(opts.Callback, value)
                end
            end

            Track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    update(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input)
                end
            end)

            return {
                Row = Row,
                Set = function(v)
                    value = math.clamp(v, min, max)
                    local relX = (value - min) / (max - min)
                    Fill.Size = UDim2.new(relX, 0, 1, 0)
                    ValueLabel.Text = tostring(value) .. suffix
                end,
                Get = function() return value end,
            }
        end

        function Tab:AddDropdown(opts)
            opts = opts or {}
            local options = opts.Options or {}
            local selected = opts.Default or options[1]
            local open = false

            local Row = baseRow(36)
            Row.ClipsDescendants = false

            new("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -40, 1, 0),
                Font = Theme.FontBody,
                Text = opts.Text or "Dropdown",
                TextColor3 = Theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            }).Parent = Row

            local SelectedLabel = new("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -140, 0, 0),
                Size = UDim2.new(0, 110, 1, 0),
                Font = Theme.FontBody,
                Text = tostring(selected or ""),
                TextColor3 = Theme.SubText,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
            })
            SelectedLabel.Parent = Row

            local Click = new("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                ZIndex = 5,
            })
            Click.Parent = Row

            local ListHolder = new("Frame", {
                BackgroundColor3 = Theme.PanelAlt,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, 4),
                Size = UDim2.new(1, 0, 0, #options * 26),
                Visible = false,
                ZIndex = 10,
                ClipsDescendants = true,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = ListHolder
            new("UIStroke", { Color = Theme.Border, Thickness = 1 }).Parent = ListHolder
            new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }).Parent = ListHolder
            ListHolder.Parent = Row

            for _, optionValue in ipairs(options) do
                local OptBtn = new("TextButton", {
                    BackgroundColor3 = Theme.PanelAlt,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 26),
                    Font = Theme.FontBody,
                    Text = tostring(optionValue),
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    AutoButtonColor = false,
                    ZIndex = 11,
                })
                OptBtn.Parent = ListHolder
                OptBtn.MouseEnter:Connect(function()
                    tween(OptBtn, QUICK, { BackgroundColor3 = Theme.AccentDim })
                end)
                OptBtn.MouseLeave:Connect(function()
                    tween(OptBtn, QUICK, { BackgroundColor3 = Theme.PanelAlt })
                end)
                OptBtn.MouseButton1Click:Connect(function()
                    selected = optionValue
                    SelectedLabel.Text = tostring(optionValue)
                    ListHolder.Visible = false
                    open = false
                    if opts.Callback then
                        task.spawn(opts.Callback, optionValue)
                    end
                end)
            end

            Click.MouseButton1Click:Connect(function()
                open = not open
                ListHolder.Visible = open
            end)

            return {
                Row = Row,
                Get = function() return selected end,
            }
        end

        function Tab:AddColorPicker(opts)
            opts = opts or {}
            local color = opts.Default or Theme.Accent
            local open = false

            local Row = baseRow(36)
            Row.ClipsDescendants = false

            new("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                Font = Theme.FontBody,
                Text = opts.Text or "Color",
                TextColor3 = Theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            }).Parent = Row

            local Swatch = new("TextButton", {
                BackgroundColor3 = color,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(28, 20),
                Position = UDim2.new(1, -38, 0.5, -10),
                Text = "",
                AutoButtonColor = false,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = Swatch
            new("UIStroke", { Color = Theme.Border, Thickness = 1 }).Parent = Swatch
            Swatch.Parent = Row

            local Picker = new("Frame", {
                BackgroundColor3 = Theme.PanelAlt,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, 4),
                Size = UDim2.new(1, 0, 0, 110),
                Visible = false,
                ZIndex = 10,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = Picker
            new("UIStroke", { Color = Theme.Border, Thickness = 1 }).Parent = Picker
            new("UIPadding", {
                PaddingTop = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
            }).Parent = Picker
            Picker.Parent = Row

            local h, s, v = color:ToHSV()

            local function makeChannel(labelText, order, initial, onChange)
                local ChannelRow = new("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 26),
                    LayoutOrder = order,
                })
                new("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(16, 26),
                    Font = Theme.FontBody,
                    Text = labelText,
                    TextColor3 = Theme.SubText,
                    TextSize = 12,
                }).Parent = ChannelRow

                local CTrack = new("Frame", {
                    BackgroundColor3 = Theme.Background,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 22, 0.5, -3),
                    Size = UDim2.new(1, -22, 0, 6),
                    ZIndex = 11,
                })
                new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = CTrack
                CTrack.Parent = ChannelRow

                local CFill = new("Frame", {
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new(initial, 0, 1, 0),
                    ZIndex = 11,
                })
                new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = CFill
                CFill.Parent = CTrack

                local dragging = false
                local function update(input)
                    local rel = math.clamp((input.Position.X - CTrack.AbsolutePosition.X) / CTrack.AbsoluteSize.X, 0, 1)
                    CFill.Size = UDim2.new(rel, 0, 1, 0)
                    onChange(rel)
                end
                CTrack.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        update(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch) then
                        update(input)
                    end
                end)
                ChannelRow.Parent = Picker
                return ChannelRow
            end

            new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }).Parent = Picker

            local function apply()
                color = Color3.fromHSV(h, s, v)
                Swatch.BackgroundColor3 = color
                if opts.Callback then
                    task.spawn(opts.Callback, color)
                end
            end

            makeChannel("H", 1, h, function(rel) h = rel; apply() end)
            makeChannel("S", 2, s, function(rel) s = rel; apply() end)
            makeChannel("V", 3, v, function(rel) v = rel; apply() end)

            Swatch.MouseButton1Click:Connect(function()
                open = not open
                Picker.Visible = open
            end)

            return {
                Row = Row,
                Get = function() return color end,
            }
        end

        Window.Tabs[name] = Tab

        -- first tab added gets auto-selected
        if not Window._selected then
            Window._selected = true
            select()
        end

        return Tab
    end

    function Window:AddTab(name)
        return buildTab(name)
    end

    --------------------------------------------------------------
    -- built-in Settings tab — panel size & transparency
    --------------------------------------------------------------
    local SettingsTab = Window:AddTab("Settings")

    SettingsTab:AddLabel("Panel")

    SettingsTab:AddSlider({
        Text = "Width",
        Min = 420, Max = 900, Default = PANEL_W,
        Suffix = "px",
        Callback = function(value)
            Window._panelSize[1] = value
            tween(Main, QUICK, { Size = UDim2.fromOffset(Window._panelSize[1], Window._panelSize[2]) })
        end,
    })

    SettingsTab:AddSlider({
        Text = "Height",
        Min = 260, Max = 640, Default = PANEL_H,
        Suffix = "px",
        Callback = function(value)
            Window._panelSize[2] = value
            tween(Main, QUICK, { Size = UDim2.fromOffset(Window._panelSize[1], Window._panelSize[2]) })
        end,
    })

    SettingsTab:AddSlider({
        Text = "Transparency",
        Min = 0, Max = 90, Default = 0,
        Suffix = "%",
        Callback = function(value)
            local t = value / 100
            tween(Main, QUICK, { BackgroundTransparency = t })
            tween(Header, QUICK, { BackgroundTransparency = t })
            tween(TabBar, QUICK, { BackgroundTransparency = t })
        end,
    })

    SettingsTab:AddToggle({
        Text = "Ember particles",
        Default = true,
        Callback = function(state)
            EmberLayer.Visible = state
        end,
    })

    SettingsTab.Select()

    return Window
end

return Library
