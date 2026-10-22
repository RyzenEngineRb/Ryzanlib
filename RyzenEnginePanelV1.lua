--[[
	RyzenEnginePanelV1  -  UI library (Roblox / Luau)
	Темная черно-зеленая Halloween тема, плавающие огни, адаптация под телефоны.

	API:
		local Library = loadstring(readfile("RyzenEnginePanelV1.lua"))()
		local Window  = Library:CreateWindow({ Title = "RyzenEnginePanelV1" })
		local Tab     = Window:AddTab({ Name = "Main", Icon = "🎃" })
		local Section = Tab:AddSection("Combat")      -- секция (необязательно, Tab тоже умеет добавлять элементы)
		Section:AddToggle / AddSlider / AddButton / AddDropdown / AddTextBox
		        AddColorPicker / AddKeybind / AddLabel
		Library:Notify({ Title = "", Content = "", Duration = 4 })
]]

local Library = { Flags = {}, Version = "1.0.0" }

--------------------------------------------------------------------------------
-- Services
--------------------------------------------------------------------------------
local cloneref = cloneref or function(x) return x end
local function Service(name) return cloneref(game:GetService(name)) end

local TweenService = Service("TweenService")
local UIS          = Service("UserInputService")
local Players      = Service("Players")
local HttpService  = Service("HttpService")
local LocalPlayer  = Players.LocalPlayer

local IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled
local ROW_H     = IS_MOBILE and 40 or 36
local OPT_H     = IS_MOBILE and 34 or 30

--------------------------------------------------------------------------------
-- Theme
--------------------------------------------------------------------------------
local function DefaultTheme()
	return {
		Accent  = Color3.fromRGB(72, 255, 112),
		Orange  = Color3.fromRGB(255, 140, 32),
		Bg      = Color3.fromRGB(5, 10, 7),
		Panel   = Color3.fromRGB(9, 18, 12),
		Panel2  = Color3.fromRGB(12, 25, 16),
		Dark    = Color3.fromRGB(4, 8, 5),
		Line    = Color3.fromRGB(28, 70, 40),
		Text    = Color3.fromRGB(222, 247, 228),
		Dim     = Color3.fromRGB(120, 156, 130),
	}
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
local function New(class, props, kids)
	local o = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v else o[k] = v end
	end
	for _, c in ipairs(kids or {}) do c.Parent = o end
	if parent then o.Parent = parent end
	return o
end

local function Corner(r) return New("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function Stroke(color, th, tr)
	return New("UIStroke", { Color = color, Thickness = th or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function Pad(l, t, r, b)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
		PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b),
	})
end

local function Tw(o, props, t, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function Safe(fn, ...)
	if type(fn) ~= "function" then return end
	local ok, err = pcall(fn, ...)
	if not ok then warn("[RyzenEnginePanelV1] callback error: " .. tostring(err)) end
end

local function Round(n, inc) return math.floor(n / inc + 0.5) * inc end
local function Decimals(inc)
	local d = tostring(inc):match("%.(%d+)")
	return d and #d or 0
end

local function IsPointer(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function IsMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

-- универсальное перетаскивание (мышь + тач)
local function Drag(handle, onMove, onStart, onEnd, conns)
	local dragging = false
	local c1 = handle.InputBegan:Connect(function(i)
		if IsPointer(i) then
			dragging = true
			if onStart then onStart(i) end
			onMove(i)
			local c; c = i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then
					dragging = false
					c:Disconnect()
					if onEnd then onEnd() end
				end
			end)
		end
	end)
	local c2 = UIS.InputChanged:Connect(function(i)
		if dragging and IsMove(i) then onMove(i) end
	end)
	if conns then table.insert(conns, c1); table.insert(conns, c2) end
end

local function MakeGui()
	local gui = New("ScreenGui", {
		Name = "RyzenEnginePanelV1",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 1000,
	})
	local ok = pcall(function()
		gui.Parent = (gethui and gethui()) or Service("CoreGui")
	end)
	if not ok or not gui.Parent then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
	return gui
end

--------------------------------------------------------------------------------
-- Elements (toggle, slider, ...)
--------------------------------------------------------------------------------
local function Elements(W, container, scroll)
	local E, T, order = {}, W.Theme, 0

	local function Row(h)
		order = order + 1
		local r = New("Frame", {
			Size = UDim2.new(1, 0, 0, h or ROW_H),
			BackgroundColor3 = T.Panel2,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			LayoutOrder = order,
			Parent = container,
		}, { Corner(6), Stroke(T.Line, 1, 0.35) })
		W:Reg(r, 0.25)
		return r
	end

	local function Lbl(parent, text, props)
		local p = {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -24, 0, ROW_H),
			Font = Enum.Font.GothamMedium,
			Text = text or "",
			TextColor3 = T.Text,
			TextSize = IS_MOBILE and 14 or 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = parent,
		}
		for k, v in pairs(props or {}) do p[k] = v end
		return New("TextLabel", p)
	end

	local function Hit(parent, h)
		return New("TextButton", {
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, h or ROW_H), ZIndex = 5, Parent = parent,
		})
	end

	local function Commit(cfg, obj, silent)
		if cfg.Flag then Library.Flags[cfg.Flag] = obj.Value end
		if not silent then Safe(cfg.Callback, obj.Value) end
	end

	---------------------------------------------------------------- Label
	function E:AddLabel(text)
		local r = Row()
		local l = Lbl(r, text, { TextColor3 = T.Dim, TextWrapped = true })
		local obj = {}
		function obj:Set(t) l.Text = t end
		return obj
	end

	---------------------------------------------------------------- Button
	function E:AddButton(cfg)
		cfg = type(cfg) == "string" and { Name = cfg } or cfg
		local r = Row()
		local l = Lbl(r, cfg.Name, { TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, ROW_H) })
		local flash = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = W.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = r })
		W:BindAccent(function(c) flash.BackgroundColor3 = c end)
		local b = Hit(r)
		b.MouseButton1Click:Connect(function()
			flash.BackgroundTransparency = 0.6
			Tw(flash, { BackgroundTransparency = 1 }, 0.35)
			Safe(cfg.Callback)
		end)
		local obj = {}
		function obj:SetText(t) l.Text = t end
		return obj
	end

	---------------------------------------------------------------- Toggle
	function E:AddToggle(cfg)
		cfg = type(cfg) == "string" and { Name = cfg } or cfg
		local r = Row()
		Lbl(r, cfg.Name, { Size = UDim2.new(1, -56, 0, ROW_H) })
		local box = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0, ROW_H / 2),
			Size = UDim2.fromOffset(22, 22), BackgroundColor3 = T.Dark, BorderSizePixel = 0, Parent = r,
		}, { Corner(5) })
		local st = Stroke(W.Accent, 1.2, 0.2); st.Parent = box
		local check = New("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBlack,
			Text = "✓", TextSize = 16, TextColor3 = Color3.fromRGB(0, 0, 0), TextTransparency = 1, Parent = box,
		})
		local obj = { Value = false, Type = "Toggle" }
		local function render()
			Tw(box, { BackgroundColor3 = obj.Value and W.Accent or T.Dark }, 0.15)
			Tw(check, { TextTransparency = obj.Value and 0 or 1 }, 0.15)
			st.Color = W.Accent
		end
		function obj:Set(v, silent)
			obj.Value = v and true or false
			render()
			Commit(cfg, obj, silent)
		end
		function obj:Get() return obj.Value end
		W:BindAccent(render)
		Hit(r).MouseButton1Click:Connect(function() obj:Set(not obj.Value) end)
		obj:Set(cfg.Default or false, true)
		if cfg.Default then Commit(cfg, obj, false) end
		return obj
	end

	---------------------------------------------------------------- Slider
	function E:AddSlider(cfg)
		local min, max = cfg.Min or 0, cfg.Max or 100
		local inc = cfg.Increment or 1
		local dec = Decimals(inc)
		local r = Row(ROW_H + 18)
		Lbl(r, cfg.Name, { Size = UDim2.new(0.6, -12, 0, 26), Position = UDim2.fromOffset(12, 3) })
		local val = Lbl(r, "", { Size = UDim2.new(0.4, -12, 0, 26), Position = UDim2.new(0.6, 0, 0, 3), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = W.Accent })
		local bar = New("Frame", {
			Position = UDim2.new(0, 12, 0, ROW_H + 2), Size = UDim2.new(1, -24, 0, 6),
			BackgroundColor3 = T.Dark, BorderSizePixel = 0, Parent = r,
		}, { Corner(3) })
		local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = W.Accent, BorderSizePixel = 0, Parent = bar }, { Corner(3) })
		local knob = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Color3.fromRGB(235, 255, 240), BorderSizePixel = 0, ZIndex = 3, Parent = bar,
		}, { Corner(7), Stroke(W.Accent, 1.5, 0) })
		W:BindAccent(function(c) fill.BackgroundColor3 = c; val.TextColor3 = c; knob.UIStroke.Color = c end)

		local obj = { Value = min, Type = "Slider" }
		local function render()
			local a = (obj.Value - min) / (max - min)
			fill.Size = UDim2.fromScale(a, 1)
			knob.Position = UDim2.fromScale(a, 0.5)
			val.Text = string.format("%." .. dec .. "f", obj.Value) .. (cfg.Suffix or "")
		end
		function obj:Set(v, silent)
			obj.Value = math.clamp(Round(v, inc), min, max)
			render()
			Commit(cfg, obj, silent)
		end
		function obj:Get() return obj.Value end

		local hit = New("TextButton", {
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
			Position = UDim2.new(0, 0, 0, ROW_H - 8), Size = UDim2.new(1, 0, 0, 30), ZIndex = 4, Parent = r,
		})
		Drag(hit, function(i)
			local a = math.clamp((i.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
			obj:Set(min + (max - min) * a)
		end, function() if scroll then scroll.ScrollingEnabled = false end end,
		function() if scroll then scroll.ScrollingEnabled = true end end, W.Conns)

		obj:Set(cfg.Default or min, true)
		if cfg.Default then Commit(cfg, obj, false) end
		return obj
	end

	---------------------------------------------------------------- TextBox
	function E:AddTextBox(cfg)
		local r = Row()
		Lbl(r, cfg.Name, { Size = UDim2.new(0.5, -12, 0, ROW_H) })
		local tb = New("TextBox", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0, ROW_H / 2), Size = UDim2.new(0.5, -12, 0, ROW_H - 12),
			BackgroundColor3 = T.Dark, BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = T.Text,
			PlaceholderText = cfg.Placeholder or "...", PlaceholderColor3 = T.Dim, Text = cfg.Default or "",
			ClearTextOnFocus = false, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r,
		}, { Corner(5), Stroke(T.Line, 1, 0.2) })
		local obj = { Value = tb.Text, Type = "TextBox" }
		function obj:Set(t, silent) tb.Text = t; obj.Value = t; Commit(cfg, obj, silent) end
		function obj:Get() return obj.Value end
		tb.FocusLost:Connect(function() obj.Value = tb.Text; Commit(cfg, obj) end)
		tb.Focused:Connect(function() tb.UIStroke.Color = W.Accent end)
		tb.FocusLost:Connect(function() tb.UIStroke.Color = T.Line end)
		return obj
	end

	---------------------------------------------------------------- Dropdown
	function E:AddDropdown(cfg)
		local r = Row()
		Lbl(r, cfg.Name, { Size = UDim2.new(0.5, -12, 0, ROW_H) })
		local cur = Lbl(r, "", { Size = UDim2.new(0.5, -34, 0, ROW_H), Position = UDim2.new(0.5, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = W.Accent })
		local arrow = New("TextLabel", {
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0, ROW_H / 2),
			Size = UDim2.fromOffset(16, 16), Font = Enum.Font.GothamBold, Text = "▾", TextSize = 16, TextColor3 = T.Dim, Parent = r,
		})
		W:BindAccent(function(c) cur.TextColor3 = c end)
		local list = New("ScrollingFrame", {
			Position = UDim2.fromOffset(8, ROW_H + 2), Size = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1,
			BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = r,
		}, { New("UIListLayout", { Padding = UDim.new(0, 2) }) })

		local obj = { Options = cfg.Options or {}, Multi = cfg.Multi, Type = "Dropdown" }
		obj.Value = cfg.Multi and {} or nil
		local open, btns = false, {}

		local function selected(o)
			if obj.Multi then return obj.Value[o] == true end
			return obj.Value == o
		end
		local function render()
			if obj.Multi then
				local t = {}
				for _, o in ipairs(obj.Options) do if obj.Value[o] then t[#t + 1] = o end end
				cur.Text = #t > 0 and table.concat(t, ", ") or "None"
			else
				cur.Text = obj.Value ~= nil and tostring(obj.Value) or "None"
			end
			for o, b in pairs(btns) do
				local s = selected(o)
				Tw(b, { BackgroundTransparency = s and 0.55 or 1, TextColor3 = s and W.Accent or T.Text }, 0.12)
			end
		end
		local function resize()
			local h = math.min(#obj.Options, 5) * (OPT_H + 2)
			list.Size = UDim2.new(1, -16, 0, h)
			Tw(r, { Size = UDim2.new(1, 0, 0, open and (ROW_H + h + 8) or ROW_H) }, 0.18)
			Tw(arrow, { Rotation = open and 180 or 0 }, 0.18)
		end
		local function build()
			for _, b in pairs(btns) do b:Destroy() end
			btns = {}
			for idx, o in ipairs(obj.Options) do
				local b = New("TextButton", {
					Size = UDim2.new(1, -4, 0, OPT_H), BackgroundColor3 = W.Accent, BackgroundTransparency = 1, AutoButtonColor = false,
					Font = Enum.Font.Gotham, Text = tostring(o), TextSize = 13, TextColor3 = T.Text, LayoutOrder = idx, Parent = list,
				}, { Corner(5) })
				b.MouseButton1Click:Connect(function()
					if obj.Multi then obj.Value[o] = not obj.Value[o] or nil else obj.Value = o end
					render()
					Commit(cfg, obj)
					if not obj.Multi then open = false; resize() end
				end)
				btns[o] = b
			end
			render(); resize()
		end
		function obj:Set(v, silent)
			if obj.Multi then
				obj.Value = {}
				for _, o in ipairs(type(v) == "table" and v or {}) do obj.Value[o] = true end
			else obj.Value = v end
			render(); Commit(cfg, obj, silent)
		end
		function obj:SetOptions(opts) obj.Options = opts; build() end
		function obj:Get() return obj.Value end
		W:BindAccent(render)
		Hit(r).MouseButton1Click:Connect(function() open = not open; resize() end)
		build()
		if cfg.Default ~= nil then obj:Set(cfg.Default, true) end
		return obj
	end

	---------------------------------------------------------------- Color picker
	function E:AddColorPicker(cfg)
		local PH = 118
		local r = Row()
		Lbl(r, cfg.Name, { Size = UDim2.new(1, -70, 0, ROW_H) })
		local sw = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0, ROW_H / 2), Size = UDim2.fromOffset(38, 20),
			BackgroundColor3 = cfg.Default or Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = r,
		}, { Corner(5), Stroke(T.Text, 1, 0.5) })

		local sv = New("Frame", {
			Position = UDim2.fromOffset(12, ROW_H + 4), Size = UDim2.new(1, -56, 0, PH), BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(1, 0, 0), ClipsDescendants = true, Parent = r,
		}, { Corner(5) })
		New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = sv }, {
			New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }),
		})
		New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = sv }, {
			New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) }),
		})
		local cursor = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, ZIndex = 4, Parent = sv,
		}, { Corner(6), Stroke(Color3.new(1, 1, 1), 2, 0) })

		local hue = New("Frame", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, ROW_H + 4), Size = UDim2.fromOffset(24, PH),
			BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = r,
		}, {
			Corner(5),
			New("UIGradient", { Rotation = 90, Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0, 1, 1)), ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
				ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)), ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.5, 1, 1)),
				ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)), ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
				ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1, 1, 1)),
			}) }),
		})
		local hmark = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 4, 0, 4), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = hue,
		}, { Corner(2), Stroke(Color3.new(0, 0, 0), 1, 0.3) })

		local obj = { Value = cfg.Default or Color3.new(1, 1, 1), Type = "ColorPicker" }
		local h, s, v = obj.Value:ToHSV()
		local function render()
			obj.Value = Color3.fromHSV(h, s, v)
			sw.BackgroundColor3 = obj.Value
			sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			cursor.Position = UDim2.fromScale(s, 1 - v)
			hmark.Position = UDim2.fromScale(0.5, h)
		end
		function obj:Set(c, silent)
			h, s, v = c:ToHSV(); render(); Commit(cfg, obj, silent)
		end
		function obj:Get() return obj.Value end

		local function lock() if scroll then scroll.ScrollingEnabled = false end end
		local function unlock() if scroll then scroll.ScrollingEnabled = true end end
		Drag(sv, function(i)
			s = math.clamp((i.Position.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
			v = 1 - math.clamp((i.Position.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
			render(); Commit(cfg, obj)
		end, lock, unlock, W.Conns)
		Drag(hue, function(i)
			h = math.clamp((i.Position.Y - hue.AbsolutePosition.Y) / math.max(hue.AbsoluteSize.Y, 1), 0, 1)
			render(); Commit(cfg, obj)
		end, lock, unlock, W.Conns)

		local open = false
		Hit(r).MouseButton1Click:Connect(function()
			open = not open
			Tw(r, { Size = UDim2.new(1, 0, 0, open and (ROW_H + PH + 12) or ROW_H) }, 0.18)
		end)
		render()
		if cfg.Default then Commit(cfg, obj, false) end
		return obj
	end

	---------------------------------------------------------------- Keybind
	function E:AddKeybind(cfg)
		local r = Row()
		Lbl(r, cfg.Name, { Size = UDim2.new(1, -110, 0, ROW_H) })
		local btn = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0, ROW_H / 2), Size = UDim2.fromOffset(90, ROW_H - 12),
			BackgroundColor3 = T.Dark, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamMedium, TextSize = 12,
			TextColor3 = W.Accent, Text = "", ZIndex = 5, Parent = r,
		}, { Corner(5), Stroke(T.Line, 1, 0.2) })
		W:BindAccent(function(c) btn.TextColor3 = c end)
		local obj = { Value = cfg.Default or Enum.KeyCode.Unknown, Type = "Keybind" }
		local listening = false
		local function render() btn.Text = listening and "..." or (obj.Value == Enum.KeyCode.Unknown and "None" or obj.Value.Name) end
		function obj:Set(k, silent)
			obj.Value = k; listening = false; render()
			if cfg.Flag then Library.Flags[cfg.Flag] = k end
			if not silent then Safe(cfg.Changed, k) end
		end
		function obj:Get() return obj.Value end
		btn.MouseButton1Click:Connect(function() listening = true; render() end)
		table.insert(W.Conns, UIS.InputBegan:Connect(function(i, gp)
			if listening then
				if i.UserInputType == Enum.UserInputType.Keyboard then
					obj:Set(i.KeyCode == Enum.KeyCode.Escape and Enum.KeyCode.Unknown or i.KeyCode)
				end
			elseif not gp and i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == obj.Value and obj.Value ~= Enum.KeyCode.Unknown then
				Safe(cfg.Callback)
			end
		end))
		render()
		return obj
	end

	return E
end

--------------------------------------------------------------------------------
-- Notifications
--------------------------------------------------------------------------------
function Library:Notify(cfg)
	local W = self.Active
	if not W then return end
	local T = W.Theme
	local item = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Panel,
		BackgroundTransparency = 1, BorderSizePixel = 0, Parent = W.NotifyHolder,
	}, { Corner(8), Stroke(W.Accent, 1.2, 0.3), Pad(12, 8, 12, 10), New("UIListLayout", { Padding = UDim.new(0, 2) }) })
	local t1 = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = W.Accent,
		Text = "🎃 " .. (cfg.Title or "Notification"), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, Parent = item,
	})
	local t2 = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Font = Enum.Font.Gotham,
		TextSize = 13, TextColor3 = T.Text, TextWrapped = true, Text = cfg.Content or "", TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 1, LayoutOrder = 2, Parent = item,
	})
	Tw(item, { BackgroundTransparency = 0.1 }, 0.25)
	Tw(t1, { TextTransparency = 0 }, 0.25); Tw(t2, { TextTransparency = 0.1 }, 0.25)
	task.delay(cfg.Duration or 4, function()
		if not item.Parent then return end
		Tw(item, { BackgroundTransparency = 1 }, 0.3); Tw(t1, { TextTransparency = 1 }, 0.3); Tw(t2, { TextTransparency = 1 }, 0.3)
		task.wait(0.35)
		item:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local W = {
		Theme = DefaultTheme(), Conns = {}, AccentFns = {}, TransObjs = {}, Orbs = {},
		Trans = 0, UserScale = 1, Lights = IS_MOBILE and 14 or 22, FloatBtn = IS_MOBILE,
		ToggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift, Tabs = {},
	}
	W.Accent = W.Theme.Accent
	local T = W.Theme
	local SIZE = cfg.Size or Vector2.new(560, 340)
	local FOLDER = cfg.Folder or "RyzenEnginePanelV1"
	local FILE = FOLDER .. "/settings.json"

	function W:BindAccent(fn) table.insert(W.AccentFns, fn); fn(W.Accent) end
	function W:Reg(obj, base)
		table.insert(W.TransObjs, { obj, base })
		obj.BackgroundTransparency = base + (1 - base) * W.Trans
	end
	function W:SetTransparency(t)
		W.Trans = math.clamp(t, 0, 0.85)
		for _, e in ipairs(W.TransObjs) do
			if e[1].Parent then e[1].BackgroundTransparency = e[2] + (1 - e[2]) * W.Trans end
		end
	end
	function W:SetAccent(c)
		W.Accent = c
		for _, fn in ipairs(W.AccentFns) do pcall(fn, c) end
	end

	-- GUI ---------------------------------------------------------------------
	local gui = MakeGui()
	W.Gui = gui
	Library.Active = W

	local root = New("Frame", {
		Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(SIZE.X, SIZE.Y), BackgroundColor3 = T.Bg, BorderSizePixel = 0, ClipsDescendants = true, Parent = gui,
	}, {
		Corner(10),
		New("UIGradient", { Rotation = 135, Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(2, 6, 4)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 26, 14)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 8, 5)),
		}) }),
	})
	W.Root = root
	W:Reg(root, 0.02)
	local rootStroke = Stroke(W.Accent, 1.5, 0.35); rootStroke.Parent = root
	W:BindAccent(function(c) rootStroke.Color = c end)
	local uiscale = New("UIScale", { Parent = root })

	-- адаптация под экран
	local function ApplyScale()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local fit = math.min(1, (vp.X - 16) / SIZE.X, (vp.Y - 16) / SIZE.Y)
		uiscale.Scale = math.max(0.4, fit) * W.UserScale
	end
	function W:SetScale(s) W.UserScale = math.clamp(s, 0.5, 1.5); ApplyScale() end
	ApplyScale()
	if workspace.CurrentCamera then
		table.insert(W.Conns, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ApplyScale))
	end

	-- плавающие огни ----------------------------------------------------------
	local lights = New("Frame", { Name = "Lights", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1, ClipsDescendants = true, Parent = root })
	local function Recolor(c)
		for _, o in ipairs(W.Orbs) do
			if o.accent and o.f.Parent then o.f.BackgroundColor3 = c; o.g.BackgroundColor3 = c end
		end
	end
	W:BindAccent(Recolor)
	function W:SetLights(n)
		W.Lights = n
		for _, o in ipairs(W.Orbs) do o.f:Destroy() end
		W.Orbs = {}
		for i = 1, n do
			local size = math.random(5, IS_MOBILE and 14 or 20)
			local accent = math.random(1, 7) ~= 1
			local col = accent and W.Accent or T.Orange
			local f = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(math.random(), math.random()),
				Size = UDim2.fromOffset(size, size), BackgroundColor3 = col, BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 1, Parent = lights,
			}, { Corner(size) })
			local g = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(3.4, 3.4),
				BackgroundColor3 = col, BackgroundTransparency = 0.92, BorderSizePixel = 0, ZIndex = 1, Parent = f,
			}, { Corner(size * 2) })
			local orb = { f = f, g = g, accent = accent }
			table.insert(W.Orbs, orb)
			task.spawn(function()
				task.wait(math.random() * 2)
				while f.Parent and gui.Parent do
					local t = math.random(60, 150) / 10
					if root.Visible then
						Tw(f, {
							Position = UDim2.fromScale(math.random(), math.random()),
							BackgroundTransparency = math.random(55, 88) / 100,
						}, t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					end
					task.wait(t)
				end
			end)
		end
	end

	-- header ------------------------------------------------------------------
	local header = New("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = T.Panel, BorderSizePixel = 0, ZIndex = 3, Parent = root })
	W:Reg(header, 0.15)
	New("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.fromOffset(34, 48), Font = Enum.Font.GothamBold,
		Text = "🎃", TextSize = 24, ZIndex = 4, Parent = header,
	})
	New("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(46, 6), Size = UDim2.new(1, -120, 0, 14), Font = Enum.Font.GothamMedium,
		Text = string.upper(cfg.Subtitle or "Ryzen Engine • Halloween Edition"), TextSize = 10, TextColor3 = T.Dim,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = header,
	})
	local title = New("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(46, 20), Size = UDim2.new(1, -120, 0, 24), Font = Enum.Font.GothamBlack,
		Text = cfg.Title or "RyzenEnginePanelV1", TextSize = 19, TextColor3 = W.Accent, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = header,
	})
	W:BindAccent(function(c) title.TextColor3 = c end)
	local hline = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = W.Accent, BorderSizePixel = 0, ZIndex = 4, Parent = header }, {
		New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }),
	})
	W:BindAccent(function(c) hline.BackgroundColor3 = c end)

	local close = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(34, 30),
		BackgroundColor3 = T.Dark, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = "✕",
		TextSize = 15, TextColor3 = T.Text, ZIndex = 5, Parent = header,
	}, { Corner(6), Stroke(T.Line, 1, 0.2) })

	-- перетаскивание за шапку
	local sm, sp
	Drag(header, function(i)
		if not sm then return end
		local d = i.Position - sm
		root.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
	end, function(i) sm = i.Position; sp = root.Position end, function() sm = nil end, W.Conns)

	-- sidebar / content -------------------------------------------------------
	local SB = IS_MOBILE and 108 or 128
	local sidebar = New("Frame", { Name = "Sidebar", Position = UDim2.fromOffset(0, 48), Size = UDim2.new(0, SB, 1, -48), BackgroundColor3 = T.Panel, BorderSizePixel = 0, ZIndex = 2, Parent = root })
	W:Reg(sidebar, 0.3)
	local tabList = New("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 1, -56), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 3, Parent = sidebar,
	}, { New("UIListLayout", { Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center }) })
	local pinned = New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, ZIndex = 3, Parent = sidebar })
	New("Frame", { Size = UDim2.new(1, -16, 0, 1), Position = UDim2.fromOffset(8, 0), BackgroundColor3 = T.Line, BorderSizePixel = 0, Parent = pinned })
	New("Frame", { Position = UDim2.new(0, SB - 1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = T.Line, BorderSizePixel = 0, ZIndex = 3, Parent = sidebar })

	local content = New("Frame", { Name = "Content", Position = UDim2.fromOffset(SB, 48), Size = UDim2.new(1, -SB, 1, -48), BackgroundTransparency = 1, ZIndex = 2, Parent = root })

	-- декор: треугольники по углам
	local function Tri(txt, anchor, pos)
		local l = New("TextLabel", {
			AnchorPoint = anchor, Position = pos, Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
			Text = txt, TextSize = 22, TextColor3 = W.Accent, TextTransparency = 0.45, ZIndex = 6, Parent = root,
		})
		W:BindAccent(function(c) l.TextColor3 = c end)
	end
	Tri("◢", Vector2.new(1, 1), UDim2.new(1, -2, 1, 2))
	Tri("◣", Vector2.new(0, 1), UDim2.new(0, 2, 1, 2))

	-- уведомления
	W.NotifyHolder = New("Frame", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.new(0, 270, 1, -28), BackgroundTransparency = 1, Parent = gui,
	}, { New("UIListLayout", { Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder }) })

	-- show / hide --------------------------------------------------------------
	function W:SetVisible(v)
		root.Visible = v
	end
	function W:Toggle() W:SetVisible(not root.Visible) end
	close.MouseButton1Click:Connect(function()
		W:SetVisible(false)
		if not W.FloatBtn.Visible and not IS_MOBILE then
			Library:Notify({ Title = "Hidden", Content = "Press " .. W.ToggleKey.Name .. " to open the panel again.", Duration = 3 })
		end
	end)
	table.insert(W.Conns, UIS.InputBegan:Connect(function(i, gp)
		if not gp and i.KeyCode == W.ToggleKey then W:Toggle() end
	end))

	-- плавающая кнопка (для телефонов)
	local fb = New("TextButton", {
		Name = "FloatButton", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 36, 0.5, 0), Size = UDim2.fromOffset(46, 46),
		BackgroundColor3 = T.Panel, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = "🎃", TextSize = 24,
		Visible = W.FloatBtn, ZIndex = 50, Parent = gui,
	}, { Corner(23) })
	local fbs = Stroke(W.Accent, 2, 0.1); fbs.Parent = fb
	W:BindAccent(function(c) fbs.Color = c end)
	do
		local startPos, startUI, moved
		fb.InputBegan:Connect(function(i)
			if IsPointer(i) then
				startPos, startUI, moved = i.Position, fb.Position, false
				local c; c = i.Changed:Connect(function()
					if i.UserInputState == Enum.UserInputState.End then
						c:Disconnect()
						if not moved then W:Toggle() end
						startPos = nil
					end
				end)
			end
		end)
		table.insert(W.Conns, UIS.InputChanged:Connect(function(i)
			if startPos and IsMove(i) then
				local d = i.Position - startPos
				if d.Magnitude > 8 then moved = true end
				if moved then fb.Position = UDim2.new(startUI.X.Scale, startUI.X.Offset + d.X, startUI.Y.Scale, startUI.Y.Offset + d.Y) end
			end
		end))
	end
	W.FloatBtn = fb
	function W:SetFloatButton(v) fb.Visible = v end

	-- tabs ---------------------------------------------------------------------
	local function MakeTab(tcfg, isPinned)
		tcfg = type(tcfg) == "string" and { Name = tcfg } or tcfg
		local tab = {}
		local btn = New("TextButton", {
			Size = UDim2.new(1, -14, 0, IS_MOBILE and 36 or 32), Position = UDim2.fromOffset(7, 8), BackgroundColor3 = W.Accent, BackgroundTransparency = 1,
			BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.Dim,
			Text = (tcfg.Icon and (tcfg.Icon .. "  ") or "") .. tcfg.Name, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 4, Parent = isPinned and pinned or tabList,
		}, { Corner(6), Pad(10, 0, 4, 0) })
		local bar = New("Frame", { Size = UDim2.new(0, 3, 0.6, 0), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -6, 0.5, 0), BackgroundColor3 = W.Accent, BorderSizePixel = 0, Visible = false, Parent = btn }, { Corner(2) })
		W:BindAccent(function(c) bar.BackgroundColor3 = c; btn.BackgroundColor3 = c end)

		local page = New("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = W.Accent,
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 3, Parent = content,
		}, { Pad(10, 10, 10, 10), New("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }) })
		W:BindAccent(function(c) page.ScrollBarImageColor3 = c end)

		tab.Button, tab.Page = btn, page
		function tab:Select()
			for _, t in ipairs(W.Tabs) do
				local on = (t == tab)
				t.Page.Visible = on
				t.Bar.Visible = on
				Tw(t.Button, { BackgroundTransparency = on and 0.82 or 1, TextColor3 = on and W.Theme.Text or W.Theme.Dim }, 0.15)
			end
		end
		tab.Bar = bar
		btn.MouseButton1Click:Connect(function() tab:Select() end)
		table.insert(W.Tabs, tab)
		if not isPinned and not W.HasMain then W.HasMain = true; tab:Select() end

		local E = Elements(W, page, page)
		for k, f in pairs(E) do tab[k] = f end
		local so = 0
		function tab:AddSection(name)
			so = so + 1
			local sec = New("Frame", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Panel, BorderSizePixel = 0, LayoutOrder = 1000 + so, Parent = page,
			}, { Corner(8), Stroke(T.Line, 1, 0.3), Pad(8, 8, 8, 8), New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
			W:Reg(sec, 0.35)
			local hl = New("TextLabel", {
				Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "▸ " .. string.upper(name or "SECTION"),
				TextSize = 12, TextColor3 = W.Accent, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0, Parent = sec,
			})
			W:BindAccent(function(c) hl.TextColor3 = c end)
			return Elements(W, sec, page)
		end
		return tab
	end
	function W:AddTab(tcfg) return MakeTab(tcfg, false) end

	-- настройки (закреплены внизу) ---------------------------------------------
	local function Save()
		if not (writefile and isfolder) then return end
		pcall(function()
			if not isfolder(FOLDER) then makefolder(FOLDER) end
			writefile(FILE, HttpService:JSONEncode({
				Scale = W.UserScale, Trans = W.Trans, Lights = W.Lights, Float = W.FloatBtn.Visible,
				Accent = { W.Accent.R, W.Accent.G, W.Accent.B },
			}))
		end)
	end
	local saved = {}
	if readfile and isfile then
		pcall(function() if isfile(FILE) then saved = HttpService:JSONDecode(readfile(FILE)) end end)
	end

	if cfg.Settings ~= false then
		local st = MakeTab({ Name = "Settings", Icon = "⚙" }, true)
		st.Button.Position = UDim2.fromOffset(7, 8)

		local ui = st:AddSection("Interface")
		ui:AddSlider({ Name = "UI Scale", Min = 50, Max = 150, Increment = 5, Suffix = "%", Default = (saved.Scale or 1) * 100,
			Callback = function(v) W:SetScale(v / 100); Save() end })
		ui:AddSlider({ Name = "Transparency", Min = 0, Max = 80, Increment = 5, Suffix = "%", Default = (saved.Trans or 0) * 100,
			Callback = function(v) W:SetTransparency(v / 100); Save() end })
		local ac = saved.Accent and Color3.new(saved.Accent[1], saved.Accent[2], saved.Accent[3]) or W.Accent
		ui:AddColorPicker({ Name = "Accent color", Default = ac, Callback = function(c) W:SetAccent(c); Save() end })

		local fx = st:AddSection("Effects")
		fx:AddSlider({ Name = "Floating lights", Min = 0, Max = 40, Increment = 1, Default = saved.Lights or W.Lights,
			Callback = function(v) W:SetLights(v); Save() end })

		local ctl = st:AddSection("Controls")
		ctl:AddToggle({ Name = "Floating 🎃 button", Default = saved.Float == nil and IS_MOBILE or saved.Float,
			Callback = function(v) W:SetFloatButton(v); Save() end })
		ctl:AddKeybind({ Name = "Toggle key", Default = W.ToggleKey, Changed = function(k) if k ~= Enum.KeyCode.Unknown then W.ToggleKey = k end end })
		ctl:AddButton({ Name = "Reset window position", Callback = function() root.Position = UDim2.fromScale(0.5, 0.5) end })
		ctl:AddButton({ Name = "Unload panel", Callback = function() W:Destroy() end })
	else
		W:SetLights(W.Lights)
	end

	function W:Destroy()
		for _, c in ipairs(W.Conns) do pcall(function() c:Disconnect() end) end
		gui:Destroy()
		if Library.Active == W then Library.Active = nil end
	end
	function W:Notify(c) Library:Notify(c) end

	return W
end

return Library
