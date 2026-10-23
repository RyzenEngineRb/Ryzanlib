local Library = { Flags = {}, Version = "3.0.0" }

local cloneref = cloneref or function(x) return x end
local function Service(n) return cloneref(game:GetService(n)) end

local TweenService = Service("TweenService")
local UIS = Service("UserInputService")
local Players = Service("Players")
local HttpService = Service("HttpService")
local RunService = Service("RunService")
local LocalPlayer = Players.LocalPlayer

local IS_MOBILE = (function()
	local p
	pcall(function() p = UIS:GetPlatform() end)
	if p == Enum.Platform.IOS or p == Enum.Platform.Android then return true end
	return UIS.TouchEnabled and not UIS.KeyboardEnabled
end)()

local ROW_H = IS_MOBILE and 36 or 26
local TXT = IS_MOBILE and 13 or 12
local OPT_H = IS_MOBILE and 34 or 28
local HAS_FS = (writefile and readfile and isfile and isfolder and makefolder and listfiles and delfile) and true or false

local Themes = {
	Halloween = {
		Accent = Color3.fromRGB(72, 255, 112),
		Orange = Color3.fromRGB(255, 140, 32),
		Bg = Color3.fromRGB(5, 10, 7),
		Panel = Color3.fromRGB(8, 16, 11),
		Handler = Color3.fromRGB(11, 23, 15),
		Field = Color3.fromRGB(14, 30, 19),
		Deep = Color3.fromRGB(4, 9, 6),
		Line = Color3.fromRGB(30, 72, 44),
		Text = Color3.fromRGB(235, 245, 238),
		Dim = Color3.fromRGB(130, 165, 140),
		Gradient = { Color3.fromRGB(2, 6, 4), Color3.fromRGB(8, 26, 14), Color3.fromRGB(3, 8, 5) },
		Lights = true,
	},
	NeverLose = {
		Accent = Color3.fromRGB(78, 127, 252),
		Orange = Color3.fromRGB(78, 127, 252),
		Bg = Color3.fromRGB(8, 8, 13),
		Panel = Color3.fromRGB(13, 17, 22),
		Handler = Color3.fromRGB(20, 22, 27),
		Field = Color3.fromRGB(26, 28, 36),
		Deep = Color3.fromRGB(10, 13, 21),
		Line = Color3.fromRGB(45, 48, 58),
		Text = Color3.fromRGB(240, 240, 240),
		Dim = Color3.fromRGB(150, 155, 165),
		Gradient = { Color3.fromRGB(8, 8, 13), Color3.fromRGB(8, 8, 13), Color3.fromRGB(8, 8, 13) },
		Lights = false,
	},
}

local StatusColors = {
	Green = Color3.fromRGB(135, 255, 143),
	Red = Color3.fromRGB(255, 102, 105),
	Yellow = Color3.fromRGB(255, 214, 90),
	Orange = Color3.fromRGB(255, 140, 32),
	White = Color3.fromRGB(235, 235, 235),
}

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

local function Stroke(c, th, tr)
	return New("UIStroke", { Color = c, Thickness = th or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function Pad(l, t, r, b)
	return New("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b) })
end

local function List(pad, props)
	local p = { Padding = UDim.new(0, pad or 0), SortOrder = Enum.SortOrder.LayoutOrder }
	for k, v in pairs(props or {}) do p[k] = v end
	return New("UIListLayout", p)
end

local function Tw(o, props, t, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function Safe(fn, ...)
	if type(fn) ~= "function" then return end
	local ok, err = pcall(fn, ...)
	if not ok then warn("[RyzenEnginePanelV1] " .. tostring(err)) end
end

local function Round(n, inc) return math.floor(n / inc + 0.5) * inc end
local function Decimals(inc) local d = tostring(inc):match("%.(%d+)"); return d and #d or 0 end
local function IsPointer(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function IsMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end

local function Drag(handle, onMove, onStart, onEnd, conns)
	local dragging = false
	local c1 = handle.InputBegan:Connect(function(i)
		if IsPointer(i) then
			dragging = true
			if onStart then onStart(i) end
			onMove(i)
			local c
			c = i.Changed:Connect(function()
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
	if conns then
		table.insert(conns, c1)
		table.insert(conns, c2)
	end
end

local function MakeGui()
	local gui = New("ScreenGui", {
		Name = "RyzenEnginePanelV1",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 1000,
	})
	local ok = pcall(function() gui.Parent = (gethui and gethui()) or Service("CoreGui") end)
	if not ok or not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
	return gui
end

local function DrawSearch(parent, color, z)
	local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(18, 18), ZIndex = z, Parent = parent })
	New("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(10, 10), ZIndex = z, Parent = holder,
	}, { New("UICorner", { CornerRadius = UDim.new(1, 0) }), Stroke(color, 1.6, 0) })
	New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(13, 13), Size = UDim2.fromOffset(7, 2), Rotation = 45,
		BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z, Parent = holder,
	})
	return holder
end

local function DrawDisk(parent, color, z)
	local holder = New("Frame", {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(14, 14), ZIndex = z, Parent = parent,
	}, { Corner(2), Stroke(color, 1.5, 0) })
	New("Frame", { Position = UDim2.fromOffset(3, 0), Size = UDim2.fromOffset(6, 4), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z, Parent = holder })
	New("Frame", { Position = UDim2.fromOffset(3, 8), Size = UDim2.fromOffset(6, 4), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = z, Parent = holder }, { Stroke(color, 1, 0) })
	return holder
end

local function Elements(W, handler, secInfo)
	local E, T, order = {}, W.Theme, 0

	local function lock(v)
		for _, s in ipairs(W.CurrentScrolls or {}) do s.ScrollingEnabled = v end
	end

	local function Row(name, h)
		order = order + 1
		local r = New("Frame", {
			Size = UDim2.new(1, 0, 0, h or ROW_H), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = order, Parent = handler,
		})
		table.insert(W.Search, { row = r, name = string.lower(name or "") })
		if secInfo then table.insert(secInfo.rows, r) end
		return r
	end

	local function Lbl(parent, text, props)
		local p = {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, -60, 0, ROW_H), Font = Enum.Font.GothamMedium,
			Text = text or "", TextColor3 = T.Text, TextTransparency = 0.15, TextSize = TXT, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, Parent = parent,
		}
		for k, v in pairs(props or {}) do p[k] = v end
		return New("TextLabel", p)
	end

	local function Hit(parent, h)
		return New("TextButton", {
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, h or ROW_H), ZIndex = 5, Parent = parent,
		})
	end

	local function Field(parent, w, props)
		local p = {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0, ROW_H / 2), Size = UDim2.fromOffset(w, ROW_H - 6),
			BackgroundColor3 = T.Field, BorderSizePixel = 0, Parent = parent,
		}
		for k, v in pairs(props or {}) do p[k] = v end
		return New("Frame", p, { Corner(5) })
	end

	local function Register(cfg, obj)
		if cfg.Flag then
			W.FlagObjs[cfg.Flag] = obj
			Library.Flags[cfg.Flag] = obj.Value
		end
	end

	local function Commit(cfg, obj, silent)
		if cfg.Flag then Library.Flags[cfg.Flag] = obj.Value end
		if not silent then Safe(cfg.Callback, obj.Value) end
	end

	function E:AddLabel(text)
		local r = Row(text)
		local l = Lbl(r, text, { Size = UDim2.new(1, 0, 0, ROW_H), TextColor3 = T.Dim, TextWrapped = true })
		local obj = {}
		function obj:Set(t) l.Text = t end
		return obj
	end

	function E:AddButton(cfg)
		cfg = type(cfg) == "string" and { Name = cfg } or cfg
		local r = Row(cfg.Name)
		local box = New("Frame", {
			Size = UDim2.new(1, 0, 0, ROW_H - 2), Position = UDim2.fromOffset(0, 1), BackgroundColor3 = T.Field, BorderSizePixel = 0, Parent = r,
		}, { Corner(5), Stroke(T.Line, 1, 0.45) })
		local l = Lbl(box, cfg.Name, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
		local flash = New("Frame", {
			Size = UDim2.fromScale(1, 1), BackgroundColor3 = W.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = box,
		}, { Corner(5) })
		W:BindAccent(function(c) flash.BackgroundColor3 = c end)
		Hit(r, ROW_H).MouseButton1Click:Connect(function()
			flash.BackgroundTransparency = 0.55
			Tw(flash, { BackgroundTransparency = 1 }, 0.35)
			Safe(cfg.Callback)
		end)
		local obj = {}
		function obj:SetText(t) l.Text = t end
		return obj
	end

	function E:AddToggle(cfg)
		cfg = type(cfg) == "string" and { Name = cfg } or cfg
		local TW, TH = IS_MOBILE and 40 or 30, IS_MOBILE and 24 or 18
		local r = Row(cfg.Name)
		Lbl(r, cfg.Name, { Size = UDim2.new(1, -(TW + 8), 0, ROW_H) })
		local pill = Field(r, TW, { Size = UDim2.fromOffset(TW, TH), BackgroundColor3 = T.Deep, ClipsDescendants = true })
		pill.UICorner.CornerRadius = UDim.new(1, 0)
		local circle = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.3, 0, 0.5, 0), Size = UDim2.fromOffset(TH - 2, TH - 2),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, Parent = pill,
		}, { Corner(TH) })
		local obj = { Value = false, Type = "Toggle" }
		local function render()
			Tw(pill, { BackgroundColor3 = obj.Value and W.Accent or T.Deep }, 0.15)
			Tw(circle, { Position = UDim2.new(obj.Value and 0.7 or 0.3, 0, 0.5, 0) }, 0.15)
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
		Register(cfg, obj)
		if cfg.Default then Commit(cfg, obj, false) end
		return obj
	end

	function E:AddSlider(cfg)
		local min, max = cfg.Min or 0, cfg.Max or 100
		local inc = cfg.Increment or (cfg.Rounding and (1 / 10 ^ cfg.Rounding)) or 1
		local dec = Decimals(inc)
		local stacked = W.Compact
		local VW = 44
		local BW = cfg.Size or 100
		local RH = stacked and (ROW_H + (IS_MOBILE and 22 or 16)) or ROW_H
		local r = Row(cfg.Name, RH)
		Lbl(r, cfg.Name, { Size = stacked and UDim2.new(1, -(VW + 8), 0, ROW_H) or UDim2.new(1, -(BW + VW + 18), 0, ROW_H) })
		local vf = Field(r, VW, { Size = UDim2.fromOffset(VW, ROW_H - 8) })
		local val = Lbl(vf, "", { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextSize = TXT - 1, TextColor3 = T.Text })
		local bar
		if stacked then
			bar = New("Frame", {
				Position = UDim2.new(0, 0, 0, ROW_H + 2), Size = UDim2.new(1, -6, 0, 5), BackgroundColor3 = T.Deep, BorderSizePixel = 0, Parent = r,
			}, { Corner(3) })
		else
			bar = New("Frame", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(VW + 12), 0, ROW_H / 2), Size = UDim2.fromOffset(BW, 5),
				BackgroundColor3 = T.Deep, BorderSizePixel = 0, Parent = r,
			}, { Corner(3) })
		end
		local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = W.Accent, BorderSizePixel = 0, Parent = bar }, { Corner(3) })
		local knob = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(IS_MOBILE and 14 or 10, IS_MOBILE and 14 or 10),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, ZIndex = 3, Parent = bar,
		}, { Corner(8) })
		W:BindAccent(function(c) fill.BackgroundColor3 = c end)
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
		local hit
		if stacked then
			hit = New("TextButton", {
				BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Position = UDim2.new(0, -4, 0, ROW_H - 6),
				Size = UDim2.new(1, 2, 0, IS_MOBILE and 32 or 22), ZIndex = 4, Parent = r,
			})
		else
			hit = New("TextButton", {
				BackgroundTransparency = 1, Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -(VW + 8), 0, ROW_H / 2), Size = UDim2.fromOffset(BW + 12, ROW_H), ZIndex = 4, Parent = r,
			})
		end
		Drag(hit, function(i)
			obj:Set(min + (max - min) * math.clamp((i.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1))
		end, function() lock(false) end, function() lock(true) end, W.Conns)
		obj:Set(cfg.Default or min, true)
		Register(cfg, obj)
		if cfg.Default then Commit(cfg, obj, false) end
		return obj
	end

	function E:AddTextBox(cfg)
		local BW = IS_MOBILE and 120 or 125
		local r = Row(cfg.Name)
		Lbl(r, cfg.Name, { Size = UDim2.new(1, -(BW + 8), 0, ROW_H) })
		local f = Field(r, BW)
		local st = Stroke(T.Line, 1, 0.5)
		st.Parent = f
		local tb = New("TextBox", {
			BackgroundTransparency = 1, Size = UDim2.new(1, -10, 1, 0), Position = UDim2.fromOffset(5, 0), Font = Enum.Font.Gotham, TextSize = TXT - 1,
			TextColor3 = T.Text, PlaceholderText = cfg.Placeholder or "...", PlaceholderColor3 = T.Dim, Text = cfg.Default or "", ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = f,
		})
		local obj = { Value = tb.Text, Type = "TextBox" }
		function obj:Set(t, silent)
			tb.Text = tostring(t)
			obj.Value = tb.Text
			Commit(cfg, obj, silent)
		end
		function obj:Get() return obj.Value end
		tb.Focused:Connect(function()
			st.Color = W.Accent
			st.Transparency = 0.1
		end)
		tb.FocusLost:Connect(function()
			st.Color = T.Line
			st.Transparency = 0.5
			obj.Value = tb.Text
			Commit(cfg, obj)
		end)
		Register(cfg, obj)
		return obj
	end

	function E:AddDropdown(cfg)
		local BW = IS_MOBILE and 120 or 125
		local r = Row(cfg.Name)
		Lbl(r, cfg.Name, { Size = UDim2.new(1, -(BW + 8), 0, ROW_H) })
		local f = Field(r, BW)
		local cur = Lbl(f, "", { Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -22, 1, 0), TextSize = TXT - 1, TextColor3 = T.Text })
		local arrow = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -7, 0.5, 0), Size = UDim2.fromOffset(6, 6), BackgroundTransparency = 1, Rotation = 45, Parent = f,
		}, { New("UIStroke", { Color = T.Dim, Thickness = 1.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) })
		local list = New("ScrollingFrame", {
			Position = UDim2.fromOffset(0, ROW_H + 3), Size = UDim2.new(1, -6, 0, 0), BackgroundColor3 = T.Deep, BackgroundTransparency = 0.3, BorderSizePixel = 0,
			ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = r,
		}, { Corner(5), List(2), Pad(3, 3, 3, 3) })
		local obj = { Options = cfg.Options or {}, Multi = cfg.Multi, Type = "Dropdown" }
		obj.Value = cfg.Multi and {} or nil
		local open, btns = false, {}
		local function sel(o)
			if obj.Multi then return obj.Value[o] == true end
			return obj.Value == o
		end
		local function render()
			if obj.Multi then
				local t = {}
				for _, o in ipairs(obj.Options) do
					if obj.Value[o] then t[#t + 1] = tostring(o) end
				end
				cur.Text = #t > 0 and table.concat(t, ", ") or "None"
			else
				cur.Text = obj.Value ~= nil and tostring(obj.Value) or "None"
			end
			for o, b in pairs(btns) do
				local s = sel(o)
				Tw(b, { BackgroundTransparency = s and 0.7 or 1, TextColor3 = s and W.Accent or T.Text }, 0.12)
			end
		end
		local function resize()
			local h = math.min(#obj.Options, 5) * OPT_H + 8
			list.Size = UDim2.new(1, -6, 0, h)
			Tw(r, { Size = UDim2.new(1, 0, 0, open and (ROW_H + h + 6) or ROW_H) }, 0.18)
			Tw(arrow, { Rotation = open and 225 or 45 }, 0.18)
		end
		local function build()
			for _, b in pairs(btns) do b:Destroy() end
			btns = {}
			for idx, o in ipairs(obj.Options) do
				local b = New("TextButton", {
					Size = UDim2.new(1, 0, 0, OPT_H - 2), BackgroundColor3 = W.Accent, BackgroundTransparency = 1, AutoButtonColor = false,
					Font = Enum.Font.Gotham, Text = tostring(o), TextSize = TXT - 1, TextColor3 = T.Text, LayoutOrder = idx, Parent = list,
				}, { Corner(4) })
				b.MouseButton1Click:Connect(function()
					if obj.Multi then
						obj.Value[o] = (not obj.Value[o]) or nil
					else
						obj.Value = o
					end
					render()
					Commit(cfg, obj)
					if not obj.Multi then
						open = false
						resize()
					end
				end)
				btns[o] = b
			end
			render()
			resize()
		end
		function obj:Set(v, silent)
			if obj.Multi then
				obj.Value = {}
				for _, o in ipairs(type(v) == "table" and v or {}) do obj.Value[o] = true end
			else
				obj.Value = v
			end
			render()
			Commit(cfg, obj, silent)
		end
		function obj:SetOptions(opts)
			obj.Options = opts
			build()
		end
		function obj:Get() return obj.Value end
		W:BindAccent(render)
		Hit(r).MouseButton1Click:Connect(function()
			open = not open
			resize()
		end)
		build()
		if cfg.Default ~= nil then obj:Set(cfg.Default, true) end
		Register(cfg, obj)
		return obj
	end

	function E:AddColorPicker(cfg)
		local PH = IS_MOBILE and 110 or 100
		local r = Row(cfg.Name)
		Lbl(r, cfg.Name, { Size = UDim2.new(1, -50, 0, ROW_H) })
		local sw = Field(r, 34, { Size = UDim2.fromOffset(34, ROW_H - 8), BackgroundColor3 = cfg.Default or Color3.new(1, 1, 1) })
		local sv = New("Frame", {
			Position = UDim2.fromOffset(0, ROW_H + 4), Size = UDim2.new(1, -40, 0, PH), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 0, 0),
			ClipsDescendants = true, Parent = r,
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
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, ROW_H + 4), Size = UDim2.fromOffset(26, PH),
			BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = r,
		}, {
			Corner(5),
			New("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
					ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
					ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
					ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
					ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
					ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
				}),
			}),
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
			h, s, v = c:ToHSV()
			render()
			Commit(cfg, obj, silent)
		end
		function obj:Get() return obj.Value end
		Drag(sv, function(i)
			s = math.clamp((i.Position.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
			v = 1 - math.clamp((i.Position.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
			render()
			Commit(cfg, obj)
		end, function() lock(false) end, function() lock(true) end, W.Conns)
		Drag(hue, function(i)
			h = math.clamp((i.Position.Y - hue.AbsolutePosition.Y) / math.max(hue.AbsoluteSize.Y, 1), 0, 1)
			render()
			Commit(cfg, obj)
		end, function() lock(false) end, function() lock(true) end, W.Conns)
		local open = false
		Hit(r).MouseButton1Click:Connect(function()
			open = not open
			Tw(r, { Size = UDim2.new(1, 0, 0, open and (ROW_H + PH + 10) or ROW_H) }, 0.18)
		end)
		render()
		Register(cfg, obj)
		if cfg.Default then Commit(cfg, obj, false) end
		return obj
	end

	function E:AddKeybind(cfg)
		local r = Row(cfg.Name)
		Lbl(r, cfg.Name, { Size = UDim2.new(1, -90, 0, ROW_H) })
		local f = Field(r, 76)
		local btn = New("TextButton", {
			BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), AutoButtonColor = false, Font = Enum.Font.GothamMedium, TextSize = TXT - 1,
			TextColor3 = W.Accent, Text = "", ZIndex = 5, Parent = f,
		})
		W:BindAccent(function(c) btn.TextColor3 = c end)
		local obj = { Value = cfg.Default or Enum.KeyCode.Unknown, Type = "Keybind" }
		local listening = false
		local function render()
			btn.Text = listening and "..." or (obj.Value == Enum.KeyCode.Unknown and "None" or obj.Value.Name)
		end
		function obj:Set(k, silent)
			obj.Value = k
			listening = false
			render()
			if cfg.Flag then Library.Flags[cfg.Flag] = k end
			if not silent then Safe(cfg.Changed, k) end
		end
		function obj:Get() return obj.Value end
		btn.MouseButton1Click:Connect(function()
			listening = true
			render()
		end)
		table.insert(W.Conns, UIS.InputBegan:Connect(function(i, gp)
			if listening then
				if i.UserInputType == Enum.UserInputType.Keyboard then
					obj:Set(i.KeyCode == Enum.KeyCode.Escape and Enum.KeyCode.Unknown or i.KeyCode)
				end
			elseif not gp and i.UserInputType == Enum.UserInputType.Keyboard and obj.Value ~= Enum.KeyCode.Unknown and i.KeyCode == obj.Value then
				Safe(cfg.Callback)
			end
		end))
		render()
		Register(cfg, obj)
		return obj
	end

	return E
end

function Library:Notify(cfg)
	local W = self.Active
	if not W then return end
	local T = W.Theme
	local item = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Panel, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = W.NotifyHolder,
	}, { Corner(8), Stroke(W.Accent, 1.2, 0.3), Pad(12, 8, 12, 10), List(2) })
	local t1 = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = W.Accent,
		Text = cfg.Title or "Notification", TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, Parent = item,
	})
	local t2 = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13,
		TextColor3 = T.Text, TextWrapped = true, Text = cfg.Content or "", TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, LayoutOrder = 2, Parent = item,
	})
	Tw(item, { BackgroundTransparency = 0.1 }, 0.25)
	Tw(t1, { TextTransparency = 0 }, 0.25)
	Tw(t2, { TextTransparency = 0.1 }, 0.25)
	task.delay(cfg.Duration or 4, function()
		if not item.Parent then return end
		Tw(item, { BackgroundTransparency = 1 }, 0.3)
		Tw(t1, { TextTransparency = 1 }, 0.3)
		Tw(t2, { TextTransparency = 1 }, 0.3)
		task.wait(0.35)
		item:Destroy()
	end)
end

function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local W = {
		Theme = Themes[cfg.Theme or "Halloween"] or Themes.Halloween,
		Conns = {}, AccentFns = {}, TransObjs = {}, Orbs = {}, Tabs = {}, MainTabs = {}, Search = {}, Sections = {}, FlagObjs = {}, MemCfg = {},
		Trans = 0, UserScale = 1, CurrentConfig = "Default", ToggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift,
	}
	local T = W.Theme
	W.Accent = T.Accent
	W.Lights = T.Lights and (IS_MOBILE and 12 or 20) or 0
	W.FloatBtn = IS_MOBILE

	local NAME = cfg.Name or cfg.Title or "RyzenEnginePanelV1"
	local CONTENT = cfg.Content or cfg.Subtitle or "Halloween Edition"
	local FOLDER = cfg.ConfigFolder or cfg.Folder or "RyzenEnginePanelV1"
	local CFGDIR = FOLDER .. "/configs"
	local SETFILE = FOLDER .. "/settings.json"
	local vp0 = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
	W.Compact = IS_MOBILE or vp0.X < 760
	local SIZE = cfg.Size or (IS_MOBILE and Vector2.new(540, 380) or Vector2.new(640, 480))
	local LEFT = W.Compact and 150 or 175

	function W:BindAccent(fn)
		table.insert(W.AccentFns, fn)
		fn(W.Accent)
	end

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

	local gui = MakeGui()
	W.Gui = gui
	Library.Active = W

	local root = New("Frame", {
		Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(SIZE.X, SIZE.Y),
		BackgroundColor3 = T.Bg, BorderSizePixel = 0, ClipsDescendants = true, Active = true, Parent = gui,
	}, {
		Corner(10),
		New("UIGradient", {
			Rotation = 135,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, T.Gradient[1]),
				ColorSequenceKeypoint.new(0.5, T.Gradient[2]),
				ColorSequenceKeypoint.new(1, T.Gradient[3]),
			}),
		}),
	})
	W.Root = root
	W:Reg(root, 0.03)
	local rootStroke = Stroke(W.Accent, 1.5, 0.4)
	rootStroke.Parent = root
	W:BindAccent(function(c) rootStroke.Color = c end)
	local uiscale = New("UIScale", { Parent = root })

	local function ApplyScale()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		uiscale.Scale = math.max(0.4, math.min(1, (vp.X - 16) / SIZE.X, (vp.Y - 16) / SIZE.Y)) * W.UserScale
	end

	function W:SetScale(s)
		W.UserScale = math.clamp(s, 0.5, 1.5)
		ApplyScale()
	end

	ApplyScale()
	if workspace.CurrentCamera then
		table.insert(W.Conns, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ApplyScale))
	end

	local lights = New("Frame", {
		Name = "Lights", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1, ClipsDescendants = true, Parent = root,
	})
	W:BindAccent(function(c)
		for _, o in ipairs(W.Orbs) do
			if o.accent and o.f.Parent then
				o.f.BackgroundColor3 = c
				o.g.BackgroundColor3 = c
			end
		end
	end)

	function W:SetLights(n)
		W.Lights = n
		for _, o in ipairs(W.Orbs) do o.f:Destroy() end
		W.Orbs = {}
		for i = 1, n do
			local size = math.random(5, IS_MOBILE and 14 or 20)
			local accent = math.random(1, 7) ~= 1
			local col = accent and W.Accent or T.Orange
			local f = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(math.random(), math.random()), Size = UDim2.fromOffset(size, size),
				BackgroundColor3 = col, BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 1, Parent = lights,
			}, { Corner(size) })
			local g = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(3.4, 3.4),
				BackgroundColor3 = col, BackgroundTransparency = 0.92, BorderSizePixel = 0, ZIndex = 1, Parent = f,
			}, { Corner(size * 2) })
			table.insert(W.Orbs, { f = f, g = g, accent = accent })
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

	local leftMenu = New("Frame", { Name = "LeftMenu", Size = UDim2.new(0, LEFT, 1, 0), BackgroundTransparency = 1, ZIndex = 2, Parent = root })
	local head = New("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Active = true, ZIndex = 3, Parent = leftMenu })
	local logo = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(35, 35), BackgroundColor3 = T.Handler,
		BorderSizePixel = 0, ZIndex = 4, Parent = head,
	}, { Corner(9), Stroke(W.Accent, 1.5, 0.2) })
	W:BindAccent(function(c) logo.UIStroke.Color = c end)
	local logoText = New("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBlack, Text = string.upper(string.sub(NAME, 1, 1)),
		TextSize = 20, TextColor3 = W.Accent, ZIndex = 5, Parent = logo,
	})
	W:BindAccent(function(c) logoText.TextColor3 = c end)
	local nameLbl = New("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(55, 4), Size = UDim2.new(1, -59, 0, 22), Font = Enum.Font.GothamBlack, Text = NAME,
		TextScaled = true, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = head,
	}, { New("UITextSizeConstraint", { MaxTextSize = 18, MinTextSize = 8 }) })
	New("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(55, 26), Size = UDim2.new(1, -59, 0, 15), Font = Enum.Font.GothamMedium, Text = CONTENT,
		TextSize = 9, TextColor3 = T.Dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = head,
	})
	New("Frame", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.new(1, -10, 0, 1), BackgroundColor3 = T.Line,
		BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 4, Parent = head,
	})

	local tabScroll = New("ScrollingFrame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 60), Size = UDim2.new(1, -10, 1, -115), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 3, Parent = leftMenu,
	}, { List(5) })

	local bottom = New("TextButton", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Text = "",
		AutoButtonColor = false, ZIndex = 3, Parent = leftMenu,
	})
	New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(1, -10, 0, 1), BackgroundColor3 = T.Line,
		BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 4, Parent = bottom,
	})
	local avatar = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(35, 35), BackgroundColor3 = T.Field,
		BorderSizePixel = 0, ZIndex = 4, Parent = bottom,
	}, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok and avatar.Parent then avatar.Image = img end
	end)
	New("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(55, 5), Size = UDim2.new(1, -85, 0, 25), Font = Enum.Font.GothamBold, Text = LocalPlayer.DisplayName,
		TextSize = 14, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4, Parent = bottom,
	})
	New("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(55, 25), Size = UDim2.new(1, -85, 0, 15), Font = Enum.Font.Gotham, Text = cfg.Expires or "lifetime",
		TextSize = 10, TextColor3 = T.Dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = bottom,
	})
	local chev = New("TextLabel", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -7, 0.5, 0), Size = UDim2.fromOffset(25, 25),
		Font = Enum.Font.GothamBlack, Text = ">", TextSize = 16, TextColor3 = T.Dim, ZIndex = 4, Parent = bottom,
	})
	W:BindAccent(function(c) chev.TextColor3 = c end)

	local right = New("Frame", {
		Name = "RightMenu", Position = UDim2.fromOffset(LEFT + 1, 0), Size = UDim2.new(1, -(LEFT + 1), 1, 0), BackgroundColor3 = T.Bg,
		BorderSizePixel = 0, ZIndex = 2, Parent = root,
	}, { Corner(10), Stroke(T.Line, 1, 0.5) })
	W:Reg(right, 0.6)
	local rHead = New("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Active = true, ZIndex = 3, Parent = right })
	New("Frame", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.new(1, -10, 0, 1), BackgroundColor3 = T.Line,
		BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 4, Parent = rHead,
	})

	local cfgFrame = New("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(W.Compact and 96 or 115, 30),
		BackgroundColor3 = T.Handler, BackgroundTransparency = 0.5, AutoButtonColor = false, BorderSizePixel = 0, Text = "", ZIndex = 4, Parent = rHead,
	}, { Corner(6), Stroke(T.Line, 1, 0.5) })
	local disk = DrawDisk(cfgFrame, T.Text, 5)
	disk.Position = UDim2.new(0, 8, 0.5, -7)
	local cfgName = New("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -34, 1, 0), Font = Enum.Font.GothamMedium, Text = W.CurrentConfig,
		TextSize = 12, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 5, Parent = cfgFrame,
	})

	local close = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = T.Handler,
		BackgroundTransparency = 0.5, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = "X", TextSize = 13,
		TextColor3 = T.Text, ZIndex = 5, Parent = rHead,
	}, { Corner(6), Stroke(T.Line, 1, 0.5) })

	local search = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -48, 0.5, 0), Size = UDim2.new(0, W.Compact and 110 or 150, 0, 30),
		BackgroundColor3 = T.Handler, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 4, Parent = rHead,
	}, { Corner(6), Stroke(T.Line, 1, 0.5) })
	local mag = DrawSearch(search, T.Dim, 5)
	mag.Position = UDim2.new(0, 7, 0.5, -9)
	local sbox = New("TextBox", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -32, 1, 0), Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = T.Text, PlaceholderText = "Search...", PlaceholderColor3 = T.Dim, Text = "", ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5, Parent = search,
	})

	function W:Filter(q)
		q = string.lower(q or "")
		for _, e in ipairs(W.Search) do
			e.row.Visible = (q == "" or string.find(e.name, q, 1, true) ~= nil)
		end
		for _, s in ipairs(W.Sections) do
			local any = false
			for _, r in ipairs(s.rows) do
				if r.Visible then
					any = true
					break
				end
			end
			s.frame.Visible = any or q == ""
		end
	end

	sbox:GetPropertyChangedSignal("Text"):Connect(function() W:Filter(sbox.Text) end)

	local tabHolder = New("Frame", { Position = UDim2.fromOffset(0, 54), Size = UDim2.new(1, 0, 1, -54), BackgroundTransparency = 1, ZIndex = 3, Parent = right })

	local function Tri(txt, anchor, pos)
		local l = New("TextLabel", {
			AnchorPoint = anchor, Position = pos, Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = txt,
			TextSize = 20, TextColor3 = W.Accent, TextTransparency = 0.5, ZIndex = 8, Parent = root,
		})
		W:BindAccent(function(c) l.TextColor3 = c end)
	end
	Tri("◢", Vector2.new(1, 1), UDim2.new(1, -2, 1, 2))
	Tri("◣", Vector2.new(0, 1), UDim2.new(0, 2, 1, 2))

	local sm, sp
	local function StartDrag(i)
		sm = i.Position
		sp = root.Position
	end
	local function MoveDrag(i)
		if not sm then return end
		local d = i.Position - sm
		root.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
	end
	Drag(head, MoveDrag, StartDrag, function() sm = nil end, W.Conns)
	Drag(rHead, MoveDrag, StartDrag, function() sm = nil end, W.Conns)

	W.NotifyHolder = New("Frame", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.new(0, 270, 1, -28), BackgroundTransparency = 1, Parent = gui,
	}, { List(6, { VerticalAlignment = Enum.VerticalAlignment.Bottom }) })

	function W:SetVisible(v) root.Visible = v end
	function W:Toggle() W:SetVisible(not root.Visible) end

	close.MouseButton1Click:Connect(function()
		W:SetVisible(false)
		if not W.FloatBtn.Visible then
			Library:Notify({ Title = "Hidden", Content = "Press " .. W.ToggleKey.Name .. " to open the panel again.", Duration = 3 })
		end
	end)

	table.insert(W.Conns, UIS.InputBegan:Connect(function(i, gp)
		if not gp and i.KeyCode == W.ToggleKey then W:Toggle() end
	end))

	local fbSize = IS_MOBILE and 46 or 42
	local fb = New("TextButton", {
		Name = "FloatButton", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 36, 0.5, 0), Size = UDim2.fromOffset(fbSize, fbSize),
		BackgroundColor3 = T.Panel, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBlack, Text = string.upper(string.sub(NAME, 1, 1)),
		TextSize = 22, TextColor3 = W.Accent, Visible = W.FloatBtn, ZIndex = 50, Parent = gui,
	}, { Corner(fbSize) })
	local fbs = Stroke(W.Accent, 2, 0.1)
	fbs.Parent = fb
	W:BindAccent(function(c)
		fbs.Color = c
		fb.TextColor3 = c
	end)
	do
		local startPos, startUI, moved
		fb.InputBegan:Connect(function(i)
			if IsPointer(i) then
				startPos, startUI, moved = i.Position, fb.Position, false
				local c
				c = i.Changed:Connect(function()
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
				if moved then
					fb.Position = UDim2.new(startUI.X.Scale, startUI.X.Offset + d.X, startUI.Y.Scale, startUI.Y.Offset + d.Y)
				end
			end
		end))
	end
	W.FloatBtn = fb

	function W:SetFloatButton(v) fb.Visible = v end

	local function MakeTab(tcfg, hidden)
		tcfg = type(tcfg) == "string" and { Name = tcfg } or tcfg
		local tab = { Hidden = hidden }
		if not hidden then
			local th = IS_MOBILE and 36 or 30
			local btn = New("TextButton", {
				Size = UDim2.new(1, -1, 0, th), BackgroundColor3 = T.Field, BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false,
				Text = "", ZIndex = 4, Parent = tabScroll,
			}, { Corner(6) })
			local icon = New("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(2, 0), Size = UDim2.fromOffset(25, th), Font = Enum.Font.GothamBlack,
				Text = tcfg.Icon or string.upper(string.sub(tcfg.Name, 1, 1)), TextSize = 15, TextColor3 = W.Accent, ZIndex = 5, Parent = btn,
			})
			local lbl = New("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -34, 1, 0), Font = Enum.Font.GothamMedium, Text = tcfg.Name,
				TextSize = 12, TextColor3 = T.Dim, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 5, Parent = btn,
			})
			local bar = New("Frame", {
				AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 3, 0.6, 0), BackgroundColor3 = W.Accent,
				BorderSizePixel = 0, Visible = false, ZIndex = 6, Parent = btn,
			}, { Corner(2) })
			W:BindAccent(function(c)
				icon.TextColor3 = c
				bar.BackgroundColor3 = c
			end)
			tab.Button, tab.Label, tab.Bar = btn, lbl, bar
			table.insert(W.MainTabs, tab)
		end

		local page = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 3, Parent = tabHolder })
		local function Scroll(pos, size)
			return New("ScrollingFrame", {
				Position = pos, Size = size, BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = W.Accent,
				CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 3, Parent = page,
			}, { List(5), Pad(8, 2, 8, 8) })
		end
		local leftS, rightS
		if W.Compact then
			leftS = Scroll(UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
		else
			leftS = Scroll(UDim2.fromScale(0, 0), UDim2.new(0.5, 0, 1, 0))
			rightS = Scroll(UDim2.fromScale(0.5, 0), UDim2.new(0.5, 0, 1, 0))
		end
		W:BindAccent(function(c)
			leftS.ScrollBarImageColor3 = c
			if rightS then rightS.ScrollBarImageColor3 = c end
		end)
		tab.Page, tab.Scrolls = page, { leftS, rightS }
		table.insert(W.Tabs, tab)

		function tab:Select()
			for _, t in ipairs(W.Tabs) do
				local on = (t == tab)
				t.Page.Visible = on
				if t.Button then
					t.Bar.Visible = on
					Tw(t.Button, { BackgroundTransparency = on and 0.5 or 1 }, 0.15)
					Tw(t.Label, { TextColor3 = on and W.Theme.Text or W.Theme.Dim }, 0.15)
				end
			end
			W.CurrentScrolls = tab.Scrolls
			W.CurrentTab = tab
		end

		if tab.Button then tab.Button.MouseButton1Click:Connect(function() tab:Select() end) end
		if not hidden and not W.HasMain then
			W.HasMain = true
			tab:Select()
		end

		local sorder, default = 0, nil
		function tab:AddSection(scfg)
			scfg = type(scfg) == "string" and { Name = scfg } or (scfg or {})
			sorder = sorder + 1
			local isRight = (not W.Compact) and string.lower(tostring(scfg.Position or "left")) == "right"
			local parent = isRight and rightS or leftS
			local sec = New("Frame", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = sorder, Parent = parent,
			}, { List(3) })
			New("TextLabel", {
				Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = scfg.Name or "Section", TextSize = 11,
				TextColor3 = T.Text, TextTransparency = 0.5, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0, Parent = sec,
			}, { Pad(4, 0, 0, 0) })
			local hnd = New("Frame", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Handler, BorderSizePixel = 0, LayoutOrder = 1, Parent = sec,
			}, { Corner(6), Stroke(T.Line, 1, 0.5), Pad(8, 7, 8, 7), List(5) })
			W:Reg(hnd, 0.5)
			local info = { rows = {}, frame = sec }
			table.insert(W.Sections, info)
			return Elements(W, hnd, info)
		end

		for _, m in ipairs({ "AddLabel", "AddButton", "AddToggle", "AddSlider", "AddTextBox", "AddDropdown", "AddColorPicker", "AddKeybind" }) do
			tab[m] = function(_, ...)
				default = default or tab:AddSection("General")
				return default[m](default, ...)
			end
		end
		return tab
	end

	function W:AddTab(tcfg) return MakeTab(tcfg, false) end

	local function Serialize(obj)
		local t, v = obj.Type, obj.Value
		if t == "ColorPicker" then
			return { v.R, v.G, v.B }
		elseif t == "Keybind" then
			return v.Name
		elseif t == "Dropdown" and obj.Multi then
			local a = {}
			for k, on in pairs(v) do
				if on then a[#a + 1] = k end
			end
			return a
		end
		return v
	end

	local function Apply(obj, val)
		local t = obj.Type
		if t == "ColorPicker" then
			obj:Set(Color3.new(val[1], val[2], val[3]))
		elseif t == "Keybind" then
			obj:Set(Enum.KeyCode[val] or Enum.KeyCode.Unknown)
		else
			obj:Set(val)
		end
	end

	function W:GetConfigData()
		local d = {}
		for flag, obj in pairs(W.FlagObjs) do d[flag] = Serialize(obj) end
		return d
	end

	function W:LoadConfigData(d)
		for flag, val in pairs(d or {}) do
			local obj = W.FlagObjs[flag]
			if obj then pcall(Apply, obj, val) end
		end
	end

	local function CfgList()
		local names = {}
		if HAS_FS then
			pcall(function()
				if not isfolder(CFGDIR) then return end
				for _, p in ipairs(listfiles(CFGDIR)) do
					local n = tostring(p):match("([^/\\]+)%.json$")
					if n then names[#names + 1] = n end
				end
			end)
		else
			for n in pairs(W.MemCfg) do names[#names + 1] = n end
		end
		table.sort(names)
		return names
	end

	function W:SaveConfig(name)
		name = (name or ""):gsub("[^%w _%-]", "")
		if name == "" then return false end
		local json = HttpService:JSONEncode(W:GetConfigData())
		if HAS_FS then
			pcall(function()
				if not isfolder(FOLDER) then makefolder(FOLDER) end
				if not isfolder(CFGDIR) then makefolder(CFGDIR) end
				writefile(CFGDIR .. "/" .. name .. ".json", json)
			end)
		else
			W.MemCfg[name] = json
		end
		return true
	end

	function W:LoadConfig(name)
		local json
		if HAS_FS then
			pcall(function() json = readfile(CFGDIR .. "/" .. name .. ".json") end)
		else
			json = W.MemCfg[name]
		end
		if not json then return false end
		local ok, d = pcall(function() return HttpService:JSONDecode(json) end)
		if not ok then return false end
		W:LoadConfigData(d)
		W.CurrentConfig = name
		cfgName.Text = name
		return true
	end

	function W:DeleteConfig(name)
		if HAS_FS then
			pcall(function() delfile(CFGDIR .. "/" .. name .. ".json") end)
		else
			W.MemCfg[name] = nil
		end
	end

	local menu = New("Frame", {
		Position = UDim2.fromOffset(LEFT + 10, 54), Size = UDim2.fromOffset(W.Compact and 210 or 220, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = T.Panel, BorderSizePixel = 0, Visible = false, ZIndex = 30, Parent = root,
	}, { Corner(8), Stroke(W.Accent, 1.2, 0.35), Pad(8, 8, 8, 8), List(6) })
	New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "Config", TextSize = 11, TextColor3 = T.Dim,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 31, LayoutOrder = 0, Parent = menu,
	})
	local inRow = New("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, ZIndex = 31, LayoutOrder = 1, Parent = menu })
	local nameBox = New("TextBox", {
		Size = UDim2.new(1, -34, 1, 0), BackgroundColor3 = T.Field, BorderSizePixel = 0, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.Text,
		PlaceholderText = "Config Name ...", PlaceholderColor3 = T.Dim, Text = "", ClearTextOnFocus = false, ZIndex = 32, Parent = inRow,
	}, { Corner(5), Pad(6, 0, 6, 0) })
	local plus = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = W.Accent, BorderSizePixel = 0,
		AutoButtonColor = false, Font = Enum.Font.GothamBlack, Text = "+", TextSize = 18, TextColor3 = Color3.new(0, 0, 0), ZIndex = 32, Parent = inRow,
	}, { Corner(5) })
	W:BindAccent(function(c) plus.BackgroundColor3 = c end)
	local cfgList = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 120), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 31, LayoutOrder = 2, Parent = menu,
	}, { List(3) })

	local function RefreshConfigs()
		for _, c in ipairs(cfgList:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
		for idx, n in ipairs(CfgList()) do
			local row = New("Frame", {
				Size = UDim2.new(1, -4, 0, IS_MOBILE and 34 or 26), BackgroundColor3 = T.Field, BackgroundTransparency = 0.3, BorderSizePixel = 0,
				LayoutOrder = idx, ZIndex = 32, Parent = cfgList,
			}, { Corner(5) })
			New("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -70, 1, 0), Font = Enum.Font.GothamMedium, Text = n,
				TextSize = 12, TextColor3 = (n == W.CurrentConfig) and W.Accent or T.Text, TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 33, Parent = row,
			})
			local del = New("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(26, 22), BackgroundTransparency = 1,
				Text = "X", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = StatusColors.Red, ZIndex = 34, Parent = row,
			})
			local load = New("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -32, 0.5, 0), Size = UDim2.fromOffset(26, 22), BackgroundTransparency = 1,
				Text = ">", Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = W.Accent, ZIndex = 34, Parent = row,
			})
			del.MouseButton1Click:Connect(function()
				W:DeleteConfig(n)
				RefreshConfigs()
			end)
			load.MouseButton1Click:Connect(function()
				if W:LoadConfig(n) then
					Library:Notify({ Title = "Config", Content = "Loaded: " .. n, Duration = 2.5 })
					RefreshConfigs()
				end
			end)
		end
	end

	plus.MouseButton1Click:Connect(function()
		if W:SaveConfig(nameBox.Text) then
			Library:Notify({ Title = "Config", Content = "Saved: " .. nameBox.Text, Duration = 2.5 })
			W.CurrentConfig = nameBox.Text
			cfgName.Text = nameBox.Text
			nameBox.Text = ""
			RefreshConfigs()
		end
	end)

	cfgFrame.MouseButton1Click:Connect(function()
		menu.Visible = not menu.Visible
		if menu.Visible then RefreshConfigs() end
	end)

	function W:Watermark()
		if W.WM then return W.WM end
		local wm = { Blocks = {} }
		local frame = New("Frame", {
			Name = "Watermark", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.new(0, 0, 0, 30),
			AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Panel, BackgroundTransparency = 0.3, BorderSizePixel = 0, Active = true, ZIndex = 40, Parent = gui,
		}, { Corner(7), Stroke(W.Accent, 1.2, 0.5) })
		wm.Root = frame
		local wmStroke = frame.UIStroke
		local line = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(1, -14, 0, 2), BackgroundColor3 = W.Accent,
			BorderSizePixel = 0, ZIndex = 43, Parent = frame,
		}, { New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }) })
		W:BindAccent(function(c)
			line.BackgroundColor3 = c
			wmStroke.Color = c
		end)
		local inner = New("Frame", {
			Size = UDim2.new(0, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 41, Parent = frame,
		}, { List(0, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center }) })

		function wm:AddBlock(icon, text)
			local b = {}
			local f = New("Frame", {
				Size = UDim2.new(0, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 41, LayoutOrder = #wm.Blocks + 1, Parent = inner,
			}, { List(5, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center }), Pad(10, 0, 10, 0) })
			if icon and icon ~= "" then
				local ic = New("TextLabel", {
					Size = UDim2.new(0, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = icon,
					TextSize = 14, TextColor3 = W.Accent, ZIndex = 42, LayoutOrder = 1, Parent = f,
				})
				W:BindAccent(function(c) ic.TextColor3 = c end)
			end
			local lb = New("TextLabel", {
				Size = UDim2.new(0, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = text or "",
				TextSize = 13, TextColor3 = T.Text, TextTransparency = 0.1, ZIndex = 42, LayoutOrder = 2, Parent = f,
			})
			function b:SetText(t) lb.Text = t end
			function b:SetVisible(v) f.Visible = v end
			table.insert(wm.Blocks, b)
			return b
		end

		function wm:SetVisible(v) frame.Visible = v end

		local s0, p0
		Drag(frame, function(i)
			if not s0 then return end
			local d = i.Position - s0
			frame.Position = UDim2.new(p0.X.Scale, p0.X.Offset + d.X, p0.Y.Scale, p0.Y.Offset + d.Y)
		end, function(i)
			s0 = i.Position
			p0 = frame.Position
		end, function() s0 = nil end, W.Conns)

		wm:AddBlock("", NAME)
		local fps = wm:AddBlock("", "0 fps")
		local ping = wm:AddBlock("", "0 ms")
		local clock = wm:AddBlock("", os.date("%H:%M:%S"))
		local frames, last = 0, os.clock()
		table.insert(W.Conns, RunService.RenderStepped:Connect(function()
			frames = frames + 1
			local now = os.clock()
			if now - last >= 0.5 then
				fps:SetText(math.floor(frames / (now - last)) .. " fps")
				frames, last = 0, now
				local ok, p = pcall(function() return Service("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
				ping:SetText((ok and math.floor(p) or 0) .. " ms")
				clock:SetText(os.date("%H:%M:%S"))
			end
		end))
		W.WM = wm
		return wm
	end

	function W:CreateIndicator(icfg)
		icfg = type(icfg) == "string" and { Name = icfg } or (icfg or {})
		if not W.IndicatorHolder then
			W.IndicatorHolder = New("Frame", {
				AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.new(0, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1, ZIndex = 30, Parent = gui,
			}, { List(6) })
		end
		local ind = { Visible = icfg.Visible ~= false }
		local color = icfg.Color or "Green"
		local function resolve(c)
			if typeof(c) == "Color3" then return c end
			return StatusColors[c] or StatusColors.Green
		end
		local h = IS_MOBILE and 34 or 38
		local item = New("Frame", {
			Size = UDim2.new(0, 0, 0, h), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Panel, BackgroundTransparency = 0.2, BorderSizePixel = 0,
			Visible = ind.Visible, LayoutOrder = (#W.IndicatorHolder:GetChildren()), ZIndex = 31, Parent = W.IndicatorHolder,
		}, { Corner(6) })
		local bar = New("Frame", {
			Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = resolve(color), BorderSizePixel = 0, ZIndex = 33, Parent = item,
		}, { Corner(2) })
		local inner = New("Frame", {
			Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 32, Parent = item,
		}, { Pad(14, 0, 14, 0), List(0, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center }) })
		local label = New("TextLabel", {
			Size = UDim2.new(0, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = icfg.Name or "",
			TextSize = IS_MOBILE and 14 or 15, TextColor3 = resolve(color), ZIndex = 33, Parent = inner,
		})
		function ind:SetText(t) label.Text = t end
		function ind:SetColor(c)
			bar.BackgroundColor3 = resolve(c)
			label.TextColor3 = resolve(c)
		end
		function ind:SetVisible(v)
			ind.Visible = v
			item.Visible = v
		end
		function ind:Destroy() item:Destroy() end
		return ind
	end

	function W:CreateLogger()
		if W.Logger then return W.Logger end
		local lg = { Items = {} }
		local holder = New("Frame", {
			AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12), Size = UDim2.fromOffset(IS_MOBILE and 240 or 290, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, ZIndex = 30, Parent = gui,
		}, { List(4, { VerticalAlignment = Enum.VerticalAlignment.Bottom }) })
		local kinds = { info = StatusColors.White, success = StatusColors.Green, warning = StatusColors.Yellow, error = StatusColors.Red }
		local counter = 0
		function lg:Log(text, kind)
			kind = kinds[kind] and kind or "info"
			counter = counter + 1
			local item = New("Frame", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Panel, BackgroundTransparency = 1, BorderSizePixel = 0,
				LayoutOrder = counter, ZIndex = 31, Parent = holder,
			}, { Corner(6), Pad(12, 6, 8, 6) })
			local bar = New("Frame", {
				Position = UDim2.new(0, -12, 0, -6), Size = UDim2.new(0, 3, 1, 12), BackgroundColor3 = kinds[kind], BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 33, Parent = item,
			}, { Corner(2) })
			local msg = New("TextLabel", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
				Text = "[" .. os.date("%H:%M:%S") .. "] " .. tostring(text), TextSize = 12, TextColor3 = kinds[kind], TextWrapped = true, TextTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 33, Parent = item,
			})
			table.insert(lg.Items, item)
			if #lg.Items > 8 then
				local old = table.remove(lg.Items, 1)
				if old then old:Destroy() end
			end
			Tw(item, { BackgroundTransparency = 0.2 }, 0.25)
			Tw(bar, { BackgroundTransparency = 0 }, 0.25)
			Tw(msg, { TextTransparency = 0 }, 0.25)
			task.delay(6, function()
				if not item.Parent then return end
				Tw(item, { BackgroundTransparency = 1 }, 0.3)
				Tw(bar, { BackgroundTransparency = 1 }, 0.3)
				Tw(msg, { TextTransparency = 1 }, 0.3)
				task.wait(0.35)
				item:Destroy()
			end)
		end
		function lg:Clear()
			for _, i in ipairs(lg.Items) do i:Destroy() end
			lg.Items = {}
		end
		W.Logger = lg
		return lg
	end

	local saved = {}
	if HAS_FS then
		pcall(function()
			if isfile(SETFILE) then saved = HttpService:JSONDecode(readfile(SETFILE)) end
		end)
	end

	local function SaveSettings()
		if not HAS_FS then return end
		pcall(function()
			if not isfolder(FOLDER) then makefolder(FOLDER) end
			writefile(SETFILE, HttpService:JSONEncode({
				Scale = W.UserScale, Trans = W.Trans, Lights = W.Lights, Float = W.FloatBtn.Visible, WM = W.WM and W.WM.Root.Visible,
				Accent = { W.Accent.R, W.Accent.G, W.Accent.B },
			}))
		end)
	end

	local st = MakeTab({ Name = "Settings" }, true)
	local ui = st:AddSection({ Name = "Interface", Position = "left" })
	ui:AddSlider({
		Name = "UI Scale", Min = 50, Max = 150, Increment = 5, Suffix = "%", Default = (saved.Scale or 1) * 100,
		Callback = function(v)
			W:SetScale(v / 100)
			SaveSettings()
		end,
	})
	ui:AddSlider({
		Name = "Transparency", Min = 0, Max = 80, Increment = 5, Suffix = "%", Default = (saved.Trans or 0) * 100,
		Callback = function(v)
			W:SetTransparency(v / 100)
			SaveSettings()
		end,
	})
	local ac = saved.Accent and Color3.new(saved.Accent[1], saved.Accent[2], saved.Accent[3]) or W.Accent
	ui:AddColorPicker({
		Name = "Accent color", Default = ac,
		Callback = function(c)
			W:SetAccent(c)
			SaveSettings()
		end,
	})
	local fx = st:AddSection({ Name = "Effects", Position = "right" })
	fx:AddSlider({
		Name = "Floating lights", Min = 0, Max = 40, Increment = 1, Default = saved.Lights or W.Lights,
		Callback = function(v)
			W:SetLights(v)
			SaveSettings()
		end,
	})
	fx:AddToggle({
		Name = "Watermark", Default = (saved.WM ~= false) and (cfg.Watermark ~= false),
		Callback = function(v)
			W:Watermark():SetVisible(v)
			SaveSettings()
		end,
	})
	local ctl = st:AddSection({ Name = "Controls", Position = "right" })
	ctl:AddToggle({
		Name = "Floating button", Default = (saved.Float == nil) and IS_MOBILE or saved.Float,
		Callback = function(v)
			W:SetFloatButton(v)
			SaveSettings()
		end,
	})
	ctl:AddKeybind({
		Name = "Toggle key", Default = W.ToggleKey,
		Changed = function(k)
			if k ~= Enum.KeyCode.Unknown then W.ToggleKey = k end
		end,
	})
	ctl:AddButton({ Name = "Reset window position", Callback = function() root.Position = UDim2.fromScale(0.5, 0.5) end })
	ctl:AddButton({ Name = "Unload panel", Callback = function() W:Destroy() end })

	bottom.MouseButton1Click:Connect(function()
		if W.CurrentTab == st then
			(W.MainTabs[1] or st):Select()
		else
			st:Select()
		end
	end)

	function W:Destroy()
		for _, c in ipairs(W.Conns) do pcall(function() c:Disconnect() end) end
		gui:Destroy()
		if Library.Active == W then Library.Active = nil end
	end

	function W:Notify(c) Library:Notify(c) end

	return W
end

return Library
