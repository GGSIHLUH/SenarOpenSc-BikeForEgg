-- SENAR HUB | Bike for Egg (UI Senar + Zone Dropdown + 3 Metode)
-- SENAR HUB | Steal a Pet and Ride It (UI + Scanner + Steal System)
-- Tema: merah + balok atas/bawah + kilatan cahaya putih/hitam
-- Floating icon (Asset ID) untuk buka/tutup

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

-- ================= CONFIG =================
local ICON_ASSET_ID = 94315198453864

-- ================= CLEANUP =================
local env = (getgenv and getgenv()) or _G
if env.__SenarCleanup then pcall(env.__SenarCleanup) end

-- ================= API PUBLIK =================
local UI = {
	onToggle = function(name, state) end,
	onJoin = function(entry) end,
	onCopy = function(entry) end,
	onClear = function() end,
	onKeySubmit = function(text) end,
	addLog = function() end,
	clearLogs = function() end,
	setStatus = function() end,
	destroy = function() end,
}
env.SenarUI = UI

-- ================= WARNA =================
local C = {
	RED    = Color3.fromRGB(235, 35, 60),
	RED_DK = Color3.fromRGB(110, 12, 26),
	PINK   = Color3.fromRGB(255, 140, 190),
	BG     = Color3.fromRGB(13, 8, 10),
	SIDE   = Color3.fromRGB(8, 5, 6),
	PANEL  = Color3.fromRGB(26, 15, 18),
	HOVER  = Color3.fromRGB(44, 24, 29),
	STROKE = Color3.fromRGB(100, 52, 60),
	OFF    = Color3.fromRGB(55, 40, 44),
	GRAY   = Color3.fromRGB(150, 132, 137),
	WHITE  = Color3.fromRGB(255, 255, 255),
	BLACK  = Color3.fromRGB(0, 0, 0),
}

-- ================= HELPER =================
local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do obj[k] = v end
	obj.Parent = parent
	return obj
end

local function corner(o, r)
	return make("UICorner", { CornerRadius = UDim.new(0, r) }, o)
end

local function randName(n)
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local t = table.create(n)
	for i = 1, n do
		local k = math.random(1, #chars)
		t[i] = chars:sub(k, k)
	end
	return table.concat(t)
end

local tweens = {}
local sweepGradients = {}

local function sweepSeq(base, hi)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, base),
		ColorSequenceKeypoint.new(0.38, base),
		ColorSequenceKeypoint.new(0.50, hi),
		ColorSequenceKeypoint.new(0.62, base),
		ColorSequenceKeypoint.new(1, base),
	})
end

local function addSweep(inst, base, hi)
	local g = make("UIGradient", { Color = sweepSeq(base, hi), Offset = Vector2.new(-1, 0) }, inst)
	sweepGradients[g] = true
	return g
end

-- garis tepi dengan kilatan putih yang menyapu
local function glowStroke(obj, th, base)
	local s = make("UIStroke", {
		Color = C.WHITE, Thickness = th or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, obj)
	addSweep(s, base or C.STROKE, C.WHITE)
	return s
end

-- garis tepi berputar: hitam / putih / merah
local function spinStroke(parent, th)
	local st = make("UIStroke", {
		Color = C.WHITE, Thickness = th or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
	local g = make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, C.BLACK),
			ColorSequenceKeypoint.new(0.2, C.RED),
			ColorSequenceKeypoint.new(0.35, C.WHITE),
			ColorSequenceKeypoint.new(0.5, C.BLACK),
			ColorSequenceKeypoint.new(0.7, C.RED_DK),
			ColorSequenceKeypoint.new(0.85, C.WHITE),
			ColorSequenceKeypoint.new(1, C.BLACK),
		}),
	}, st)
	local tw = TweenService:Create(g,
		TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, false, 0),
		{ Rotation = 360 })
	tw:Play()
	table.insert(tweens, tw)
	return st
end

local function tween(obj, info, props)
	local tw = TweenService:Create(obj, info, props)
	tw:Play()
	return tw
end

-- ================= GUI =================
local gui = make("ScreenGui", {
	Name = randName(14), ResetOnSpawn = false, DisplayOrder = 999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

do
	local ok = pcall(function()
		gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not ok or not gui.Parent then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
end

local conns = {}
local myCleanup = function()
	if gui and gui.Parent then gui:Destroy() end
end
env.__SenarCleanup = myCleanup
UI.destroy = myCleanup

-- driver kilatan (satu tween untuk semua gradien)
local sweepVal = make("NumberValue", { Value = -1 }, gui)
table.insert(conns, sweepVal.Changed:Connect(function(v)
	local off = Vector2.new(v, 0)
	for g in pairs(sweepGradients) do
		if g.Parent then g.Offset = off else sweepGradients[g] = nil end
	end
end))
do
	local tw = TweenService:Create(sweepVal,
		TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 0),
		{ Value = 1 })
	tw:Play()
	table.insert(tweens, tw)
end

local W, H = 470, 300

-- holder (untuk posisi, drag, dan skala layar)
local holder = make("Frame", {
	Name = "Holder", AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H),
	BackgroundTransparency = 1,
}, gui)
local fitScale = make("UIScale", { Scale = 1 }, holder)

local function updateFit()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local vp = cam.ViewportSize
	fitScale.Scale = math.clamp(math.min(vp.X / (W + 30), vp.Y / (H + 30)), 0.45, 1)
end
updateFit()
if workspace.CurrentCamera then
	table.insert(conns, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateFit))
end

-- window utama
local main = make("Frame", {
	Name = "Main", Size = UDim2.fromScale(1, 1),
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = C.BG, BorderSizePixel = 0, ClipsDescendants = true,
}, holder)
corner(main, 12)
local popScale = make("UIScale", { Scale = 1 }, main)
spinStroke(main, 1.5)

-- ---------- Balok atas & bawah (background) ----------
local blocks = {}
do
	local BW, GAP = 16, 4
	local count = math.floor((W - 16) / (BW + GAP))
	local rng = Random.new(7)
	for i = 1, count do
		local x = 8 + (i - 1) * (BW + GAP)
		local col = C.RED_DK:Lerp(C.RED, rng:NextNumber())
		local hTop = rng:NextInteger(7, 18)
		local hBot = rng:NextInteger(7, 18)

		local top = make("Frame", {
			Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(BW, hTop),
			BackgroundColor3 = col, BackgroundTransparency = 0.35, BorderSizePixel = 0,
		}, main)
		local bot = make("Frame", {
			AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(x, H),
			Size = UDim2.fromOffset(BW, hBot),
			BackgroundColor3 = col, BackgroundTransparency = 0.35, BorderSizePixel = 0,
		}, main)
		table.insert(blocks, { frame = top, base = hTop, phase = rng:NextNumber() * 6.28 })
		table.insert(blocks, { frame = bot, base = hBot, phase = rng:NextNumber() * 6.28 })
	end
	blocks.width = BW
end

-- ---------- Sidebar ----------
local side = make("Frame", {
	Position = UDim2.fromOffset(8, 24), Size = UDim2.fromOffset(124, 252),
	BackgroundColor3 = C.SIDE, BackgroundTransparency = 0.12, BorderSizePixel = 0,
}, main)
corner(side, 10)
glowStroke(side, 1)

-- judul: Senar (Se merah, nar merah muda) + Hub (rainbow)
local titleRow = make("Frame", {
	Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(108, 24),
	BackgroundTransparency = 1,
}, side)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center,
}, titleRow)

local senar = make("TextLabel", {
	Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1, Text = "Senar", TextColor3 = C.WHITE,
	Font = Enum.Font.GothamBlack, TextSize = 18, LayoutOrder = 1,
}, titleRow)
make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.RED),
		ColorSequenceKeypoint.new(0.40, C.RED),
		ColorSequenceKeypoint.new(0.44, C.PINK),
		ColorSequenceKeypoint.new(1, C.PINK),
	}),
}, senar)

local hub = make("TextLabel", {
	Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1, Text = "Hub", TextColor3 = C.WHITE,
	Font = Enum.Font.GothamBlack, TextSize = 18, LayoutOrder = 2,
}, titleRow)
local hubGrad = make("UIGradient", {}, hub)

local function rainbowSeq(t)
	local kps = {}
	for i = 0, 6 do
		kps[#kps + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((t * 0.25 + i / 6) % 1, 0.85, 1))
	end
	return ColorSequence.new(kps)
end
hubGrad.Color = rainbowSeq(0)

-- status
local dot = make("Frame", {
	Position = UDim2.fromOffset(12, 40), Size = UDim2.fromOffset(6, 6),
	BackgroundColor3 = C.WHITE, BorderSizePixel = 0,
}, side)
corner(dot, 3)
local statusLbl = make("TextLabel", {
	Position = UDim2.fromOffset(24, 34), Size = UDim2.new(1, -30, 0, 18),
	BackgroundTransparency = 1, Text = "Connected", TextColor3 = C.GRAY,
	Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, side)
UI.setStatus = function(t)
	statusLbl.Text = tostring(t)
end

-- ---------- Area konten & halaman ----------
local content = make("Frame", {
	Position = UDim2.fromOffset(140, 24), Size = UDim2.fromOffset(322, 252),
	BackgroundTransparency = 1,
}, main)

local pages, tabBtns = {}, {}
local tabNames = { "Main", "Setting" }

for _, name in ipairs(tabNames) do
	pages[name] = make("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false,
	}, content)
end

local function selectTab(name)
	for n, p in pairs(pages) do p.Visible = (n == name) end
	for n, t in pairs(tabBtns) do
		local on = (n == name)
		t.btn.BackgroundTransparency = on and 0.15 or 1
		t.btn.TextColor3 = on and C.WHITE or C.GRAY
		t.stroke.Enabled = on
	end
end

for i, name in ipairs(tabNames) do
	local b = make("TextButton", {
		Position = UDim2.fromOffset(8, 60 + (i - 1) * 36), Size = UDim2.fromOffset(108, 30),
		BackgroundColor3 = C.HOVER, BackgroundTransparency = 1, BorderSizePixel = 0,
		Text = name, TextColor3 = C.GRAY, Font = Enum.Font.GothamBold, TextSize = 12,
		AutoButtonColor = false,
	}, side)
	corner(b, 8)
	local st = glowStroke(b, 1)
	st.Enabled = false
	tabBtns[name] = { btn = b, stroke = st }
	b.Activated:Connect(function() selectTab(name) end)
end

-- tombol Hide
local hideBtn = make("TextButton", {
	AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.fromOffset(108, 28),
	BackgroundColor3 = C.PANEL, BorderSizePixel = 0, Text = "Hide", TextColor3 = C.WHITE,
	Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false,
}, side)
corner(hideBtn, 8)
glowStroke(hideBtn, 1)

-- ---------- Komponen: switch card ----------
local function makeSwitchCard(parent, name, size, pos, order)
	local card = make("Frame", {
		Size = size, Position = pos or UDim2.new(), LayoutOrder = order or 0,
		BackgroundColor3 = C.PANEL, BorderSizePixel = 0,
	}, parent)
	corner(card, 8)
	glowStroke(card, 1)

	make("TextLabel", {
		Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -64, 1, 0),
		BackgroundTransparency = 1, Text = name, TextColor3 = C.WHITE,
		Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	local track = make("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(38, 20), BackgroundColor3 = C.OFF, BorderSizePixel = 0,
	}, card)
	corner(track, 10)
	local knob = make("Frame", {
		Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = C.WHITE, BorderSizePixel = 0,
	}, track)
	corner(knob, 7)

	local overlay = make("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5,
	}, card)

	local on = false
	overlay.Activated:Connect(function()
		on = not on
		local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad)
		tween(knob, info, { Position = on and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3) })
		tween(track, info, { BackgroundColor3 = on and C.RED or C.OFF })
		local okc, err = pcall(UI.onToggle, name, on)
		if not okc then warn("[Senar Hub] onToggle: " .. tostring(err)) end
	end)
	return card
end

-- ---------- Komponen: list ----------
local function makeList(parent, size, pos)
	local s = make("ScrollingFrame", {
		Size = size, Position = pos or UDim2.new(),
		BackgroundColor3 = C.SIDE, BackgroundTransparency = 0.25, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = C.RED,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
	}, parent)
	corner(s, 8)
	glowStroke(s, 1)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, s)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 8),
	}, s)
	return s
end

local function smallButton(parent, text, pos, dim)
	local b = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = pos, Size = UDim2.fromOffset(48, 24),
		BackgroundColor3 = dim and C.HOVER or C.PANEL, BorderSizePixel = 0,
		Text = text, TextColor3 = dim and C.GRAY or C.WHITE,
		Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false,
	}, parent)
	corner(b, 6)
	glowStroke(b, 1)
	return b
end

selectTab("Main")

-- ---------- Kilatan cahaya (garis putih + hitam menyapu) ----------
do
	local streak = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(-60, H / 2),
		Size = UDim2.fromOffset(14, H + 120), Rotation = 18,
		BackgroundTransparency = 1, ZIndex = 50,
	}, main)
	make("Frame", {
		Position = UDim2.fromOffset(2, 0), Size = UDim2.fromOffset(3, H + 120),
		BackgroundColor3 = C.WHITE, BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 50,
	}, streak)
	make("Frame", {
		Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(5, H + 120),
		BackgroundColor3 = C.BLACK, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 50,
	}, streak)

	local tw = TweenService:Create(streak,
		TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 2.5),
		{ Position = UDim2.fromOffset(W + 60, H / 2) })
	tw:Play()
	table.insert(tweens, tw)
end

-- ---------- Buka / tutup ----------
local opened = true
local function setOpen(state)
	opened = state
	if state then
		holder.Visible = true
		popScale.Scale = 0.85
		tween(popScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
	else
		tween(popScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.85 })
		task.delay(0.18, function()
			if not opened and holder.Parent then holder.Visible = false end
		end)
	end
end
hideBtn.Activated:Connect(function() setOpen(false) end)

-- ---------- Drag window (strip atas + area judul) ----------
local function attachDrag(dragFrame)
	local dragging, startMouse, startPos
	table.insert(conns, dragFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging, startMouse, startPos = true, input.Position, holder.Position
		end
	end))
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = (input.Position - startMouse) / fitScale.Scale
			holder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

attachDrag(make("Frame", {
	Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Active = true, ZIndex = 40,
}, main))
attachDrag(make("Frame", {
	Position = UDim2.fromOffset(8, 24), Size = UDim2.fromOffset(124, 30),
	BackgroundTransparency = 1, Active = true, ZIndex = 40,
}, main))

-- ---------- Floating icon ----------
local iconBtn = make("TextButton", {
	Name = "FloatingIcon", Position = UDim2.new(0, 16, 0.5, -26), Size = UDim2.fromOffset(52, 52),
	BackgroundColor3 = C.BG, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 60,
}, gui)
corner(iconBtn, 26)
spinStroke(iconBtn, 2)

local iconFallback = make("TextLabel", {
	Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "S",
	TextColor3 = C.RED, Font = Enum.Font.GothamBlack, TextSize = 24, ZIndex = 61,
}, iconBtn)

do
	local img = make("ImageLabel", {
		Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -10, 1, -10),
		BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit,
		Image = "rbxassetid://" .. tostring(ICON_ASSET_ID), Visible = false, ZIndex = 62,
	}, iconBtn)
	corner(img, 21)
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({ img }, function(_, status)
				if status == Enum.AssetFetchStatus.Success and img.Parent then
					img.Visible = true
					iconFallback.Text = ""
				end
			end)
		end)
	end)
end

-- icon bisa digeser; tap (tanpa geser) = buka/tutup
do
	local dragging, moved, startMouse, startPos
	table.insert(conns, iconBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging, moved, startMouse, startPos = true, false, input.Position, iconBtn.Position
		end
	end))
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - startMouse
			if d.Magnitude > 6 then moved = true end
			if moved then
				iconBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			if not moved then setOpen(not opened) end
		end
	end))
end

-- ---------- Animasi: balok bergerak + Hub rainbow ----------
do
	local t0 = os.clock()
	local acc = 0
	table.insert(conns, RunService.Heartbeat:Connect(function(dt)
		if not holder.Visible then return end
		local t = os.clock() - t0
		local bw = blocks.width
		for _, b in ipairs(blocks) do
			b.frame.Size = UDim2.fromOffset(bw, b.base + math.sin(t * 2 + b.phase) * 3)
		end
		acc += dt
		if acc >= 0.05 then
			acc = 0
			hubGrad.Color = rainbowSeq(t)
		end
	end))
end

-- ---------- Cleanup ----------
gui.Destroying:Connect(function()
	if env.__SenarCleanup == myCleanup then env.__SenarCleanup = nil end
	if env.SenarUI == UI then env.SenarUI = nil end
	table.clear(sweepGradients)
	for _, c in ipairs(conns) do c:Disconnect() end
	for _, t in ipairs(tweens) do pcall(function() t:Cancel() end) end
end)


-- ====== FITUR BIKE FOR EGG ======
local okBike, errBike = pcall(function()
	local VirtualUser = game:GetService("VirtualUser")

	-- ================= CONFIG =================
	local CFG = {
		SAFE = Vector3.new(542.15, 70.57, -364.79),
		ZONES = {
			Vector3.new(598.33, 70.57, -323.28),
			Vector3.new(742.09, 70.57, -411.35),
			Vector3.new(950.07, 70.57, -324.19),
			Vector3.new(1189.92, 70.57, -410.02),
			Vector3.new(1491.03, 70.57, -315.72),
			Vector3.new(1879.13, 70.57, -396.25),
			Vector3.new(2279.83, 70.57, -328.63),
			Vector3.new(2812.01, 70.57, -398.60),
			Vector3.new(3391.65, 70.57, -324.71),
		},
		TP_STEP = 16, TP_DELAY = 0.05,
		WALK_TIMEOUT = 120,
		SAFE_RADIUS = 45,   -- prompt dalam radius ini dari safe zone = milik base
		ZONE_RADIUS = 90,   -- radius cari egg di sekitar koordinat zone
		FIND_TIMEOUT = 4,   -- detik menunggu egg muncul setelah tiba di zone

		-- kata kunci (huruf kecil, cocok sebagian)
		TAKE_WORDS    = { "steal", "curi", "grab", "take", "pick", "ambil", "collect", "egg" },
		PLACE_WORDS   = { "place", "put", "drop", "taruh", "deposit", "insert" },
		CARRY_WORDS   = { "egg", "telur" },
		NOT_CARRY     = { "bat", "trap", "net" },
		TREADMILL     = { "treadmill" },
		TREADMILL_USE = { "treadmill", "run", "start", "use" },
		UPGRADE_WORDS = { "upgrade", "level up", "boost" },
		BUYBIKE_WORDS = { "buy", "purchase", "beli" },
		BIKE_WORDS    = { "bike", "sepeda" },
		OPEN_WORDS    = { "open", "hatch", "buka" },
		EGG_WORDS     = { "egg", "telur" },
		SELL_WORDS    = { "sell all", "sellall", "sell", "jual" },
		TREADMILL_POS = nil, -- isi Vector3 kalau treadmill tidak terdeteksi
	}

	local ICON_MAIN, ICON_SETTING = 13060262529, 9405931578

	-- ================= STATE =================
	local S = { alive = true, busy = false, noclip = false, floatOn = false }
	local settings = {
		autosteal = false, autotreadmill = false, autoupgrade = false, autobuybike = false,
		autobring = false, autoopenegg = false, autosellall = false,
		zone = 0, method = 1, forcespeed = 100, tweenspeed = 120,
	}
	local binders = {}
	local function setSetting(k, v)
		settings[k] = v
		if binders[k] then binders[k](v) end
	end
	local setStatus = function(t) UI.setStatus(t) end
	local floatPart

	-- ================= UTIL =================
	local function any(s, words)
		for _, w in ipairs(words) do if s:find(w, 1, true) then return true end end
		return false
	end
	local function jitter(t) return t * (0.9 + math.random() * 0.2) end
	local function hrp() local c = LocalPlayer.Character return c and c:FindFirstChild("HumanoidRootPart") end
	local function hum() local c = LocalPlayer.Character return c and c:FindFirstChildOfClass("Humanoid") end
	local function setPos(h, pos)
		if not h then return end
		h.CFrame = CFrame.new(pos) * (h.CFrame - h.CFrame.Position)
		h.AssemblyLinearVelocity = Vector3.zero
	end
	local function stopAnims()
		local h = hum()
		local a = h and h:FindFirstChildOfClass("Animator")
		if a then for _, t in ipairs(a:GetPlayingAnimationTracks()) do t:Stop() end end
	end

	table.insert(conns, RunService.Heartbeat:Connect(function()
		local h = hrp()
		if S.floatOn and h then
			if not floatPart or not floatPart.Parent then
				floatPart = make("Part", {
					Name = randName(8), Size = Vector3.new(14, 1, 14), Anchored = true, CanCollide = true,
					Transparency = 1, CanQuery = false, CanTouch = false,
				}, workspace)
			end
			floatPart.CFrame = CFrame.new(h.Position - Vector3.new(0, 3.5, 0))
		elseif floatPart then
			floatPart:Destroy()
			floatPart = nil
		end
	end))
	table.insert(conns, RunService.Stepped:Connect(function()
		if not S.noclip then return end
		local c = LocalPlayer.Character
		if not c then return end
		for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
	end))
	table.insert(conns, LocalPlayer.Idled:Connect(function()
		pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end)
	end))

	-- ================= PROMPT / CLICK REGISTRY =================
	local prompts, clickers = {}, {}
	local function reg(d)
		if d:IsA("ProximityPrompt") then prompts[d] = true
		elseif d:IsA("ClickDetector") then clickers[d] = true end
	end
	table.insert(conns, workspace.DescendantAdded:Connect(reg))
	table.insert(conns, workspace.DescendantRemoving:Connect(function(d) prompts[d] = nil clickers[d] = nil end))
	task.spawn(function()
		local n = 0
		for _, d in ipairs(workspace:GetDescendants()) do
			reg(d)
			n += 1
			if n % 3000 == 0 then task.wait() end
		end
	end)

	local function partPos(par)
		if not par then return nil end
		if par:IsA("BasePart") then return par.Position end
		if par:IsA("Attachment") then return par.WorldPosition end
		if par:IsA("Model") then return par:GetPivot().Position end
		return nil
	end
	local function promptPos(p) return partPos(p.Parent) end
	local function ptext(p)
		local par = p.Parent
		return (p.ActionText .. " " .. p.ObjectText .. " " .. p.Name .. " " .. (par and par.Name or "")):lower()
	end
	local function fire(p)
		pcall(function()
			p.HoldDuration = 0
			p.RequiresLineOfSight = false
			if p.MaxActivationDistance < 40 then p.MaxActivationDistance = 40 end
		end)
		if fireproximityprompt then pcall(fireproximityprompt, p)
		else pcall(function() p:InputHoldBegin() p:InputHoldEnd() end) end
	end
	local function isTake(p)
		local t = ptext(p)
		return any(t, CFG.TAKE_WORDS) and not any(t, CFG.PLACE_WORDS)
	end
	local function isPlace(p) return any(ptext(p), CFG.PLACE_WORDS) end
	local function isOther(p) -- prompt apa saja yang bukan place/sell/open (cadangan)
		local t = ptext(p)
		return not any(t, CFG.PLACE_WORDS) and not any(t, CFG.SELL_WORDS) and not any(t, CFG.OPEN_WORDS)
	end

	local function nearestPrompt(center, radius, matcher, minFromSafe)
		local best, bpos, bd = nil, nil, radius
		local mychar = LocalPlayer.Character
		for p in pairs(prompts) do
			if p.Parent and p.Enabled and not (mychar and p:IsDescendantOf(mychar)) and matcher(p) then
				local pos = promptPos(p)
				if pos and (not minFromSafe or (pos - CFG.SAFE).Magnitude > minFromSafe) then
					local d = (pos - center).Magnitude
					if d <= bd then best, bpos, bd = p, pos, d end
				end
			end
		end
		return best, bpos
	end

	-- ================= TOOL / EGG =================
	local function carryScore()
		local n = 0
		local c = LocalPlayer.Character
		if c then
			for _, d in ipairs(c:GetChildren()) do
				if d:IsA("Tool") or any(d.Name:lower(), CFG.CARRY_WORDS) then n += 1 end
			end
		end
		local bp = LocalPlayer:FindFirstChild("Backpack")
		if bp then
			for _, d in ipairs(bp:GetChildren()) do
				if d:IsA("Tool") or any(d.Name:lower(), CFG.CARRY_WORDS) then n += 1 end
			end
		end
		return n
	end
	local function findCarryTool()
		local function pick(root)
			if not root then return nil end
			local fb
			for _, t in ipairs(root:GetChildren()) do
				if t:IsA("Tool") then
					local n = t.Name:lower()
					if any(n, CFG.CARRY_WORDS) then return t end
					if not any(n, CFG.NOT_CARRY) then fb = fb or t end
				end
			end
			return fb
		end
		return pick(LocalPlayer.Character) or pick(LocalPlayer:FindFirstChild("Backpack"))
	end
	local function equipCarry()
		local t = findCarryTool()
		if not t then return nil end
		local hm = hum()
		if hm and t.Parent ~= LocalPlayer.Character then
			pcall(function() hm:EquipTool(t) end)
			task.wait(0.15)
		end
		return t
	end

	-- ================= GERAK =================
	-- Metode 1: TP bertahap
	local function tpMove(target, stop, cond)
		S.floatOn = true
		stopAnims()
		local t0 = os.clock()
		while cond() and os.clock() - t0 < CFG.WALK_TIMEOUT do
			local h = hrp()
			if not h then return false end
			local diff = target - h.Position
			local d = diff.Magnitude
			if d <= stop then return true end
			setPos(h, h.Position + diff.Unit * math.min(CFG.TP_STEP, d))
			task.wait(jitter(CFG.TP_DELAY))
		end
		return false
	end

	-- Metode 2: Gerak paksa (velocity + noclip)
	local function forceMove(target, stop, cond)
		S.floatOn, S.noclip = true, true
		stopAnims()
		local t0 = os.clock()
		local reached = false
		while cond() and os.clock() - t0 < CFG.WALK_TIMEOUT do
			local h = hrp()
			if not h then break end
			local d = target - h.Position
			if d.Magnitude <= stop then reached = true break end
			h.AssemblyLinearVelocity = d.Unit * settings.forcespeed
			RunService.Heartbeat:Wait()
		end
		local h = hrp()
		if h then h.AssemblyLinearVelocity = Vector3.zero end
		S.noclip = false
		return reached
	end

	-- Tween (treadmill)
	local function tweenMove(target, stop, cond)
		local h = hrp()
		if not h then return false end
		local dist = (target - h.Position).Magnitude
		if dist <= stop then return true end
		S.floatOn, S.noclip = true, true
		local tw = TweenService:Create(h,
			TweenInfo.new(dist / math.max(settings.tweenspeed, 1), Enum.EasingStyle.Linear),
			{ CFrame = CFrame.new(target) })
		tw:Play()
		local t0 = os.clock()
		while tw.PlaybackState == Enum.PlaybackState.Playing and os.clock() - t0 < CFG.WALK_TIMEOUT do
			if not cond() then tw:Cancel() break end
			task.wait(0.1)
		end
		S.noclip = false
		local hh = hrp()
		if hh then hh.AssemblyLinearVelocity = Vector3.zero end
		return hh and (hh.Position - target).Magnitude <= stop + 3 or false
	end

	-- metode 1 = TP, 2 = gerak paksa (metode 3 memakai TP langsung / instant)
	local function moveTo(target, stop, cond)
		if settings.method == 2 then return forceMove(target, stop, cond) end
		return tpMove(target, stop, cond)
	end

	-- ================= KLON (metode 3) =================
	local function createClone()
		local c = LocalPlayer.Character
		local h = hrp()
		if not c or not h then return nil, nil end
		c.Archivable = true
		local clone = c:Clone()
		for _, d in ipairs(clone:GetDescendants()) do
			if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
		end
		clone.Name = "SenarClone"
		local crp = clone:FindFirstChild("HumanoidRootPart")
		local chm = clone:FindFirstChildOfClass("Humanoid")
		if crp and chm then
			chm.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			crp.Anchored = true
			crp.CFrame = h.CFrame
			clone.Parent = workspace
		end
		return clone, chm
	end

	local function placeEgg()
		local tool = equipCarry()
		local pp = nearestPrompt(CFG.SAFE, CFG.SAFE_RADIUS, isPlace)
		if pp then
			local pos = promptPos(pp)
			local h = hrp()
			if h and pos and (pos - h.Position).Magnitude > 8 then
				setPos(h, pos + Vector3.new(0, 3, 0))
				task.wait(0.1)
			end
			fire(pp)
			return true
		end
		if tool then pcall(function() tool:Activate() end) return true end
		return false
	end

	local function waitEggNear(center, timeout, cond)
		local t0 = os.clock()
		repeat
			local p, pos = nearestPrompt(center, CFG.ZONE_RADIUS, isTake, CFG.SAFE_RADIUS)
			if p then return p, pos end
			task.wait(0.25)
		until os.clock() - t0 >= timeout or not cond()
		-- cadangan: prompt apa saja di sekitar zone
		return nearestPrompt(center, CFG.ZONE_RADIUS, isOther, CFG.SAFE_RADIUS)
	end

	-- ================= STEAL: pergi ke zone -> ambil -> safe zone =================
	-- return true kalau ada egg & berhasil
	local function zoneSteal(zi, cond)
		local zpos = CFG.ZONES[zi]
		if not zpos then return false end
		local camera = workspace.CurrentCamera
		local clone
		local result = false

		local function finish()
			S.floatOn, S.noclip = false, false
			local hm = hum()
			if camera and hm then camera.CameraSubject = hm end
			if clone then clone:Destroy() clone = nil end
		end

		local ok, err = pcall(function()
			local h = hrp()
			if not h then return end
			local method = settings.method

			if method == 3 then
				local chm
				clone, chm = createClone()
				if chm and camera then camera.CameraSubject = chm end
				setStatus(string.format("[3] instant ke zone %d", zi))
				setPos(h, zpos + Vector3.new(0, 3, 0))
				task.wait(0.15)
			else
				setStatus(string.format("[%d] menuju zone %d", method, zi))
				if not moveTo(zpos, 4, cond) then setStatus("gagal sampai zone " .. zi) return end
			end

			local p, ppos = waitEggNear(zpos, CFG.FIND_TIMEOUT, cond)
			if not p then setStatus("tidak ada egg di zone " .. zi) finish() return end
			result = true

			-- dekati egg
			h = hrp()
			if h and (ppos - h.Position).Magnitude > 8 then
				if method == 3 then
					setPos(h, ppos + Vector3.new(0, 3, 0))
					task.wait(0.1)
				else
					moveTo(ppos, 7, cond)
				end
			end

			setStatus("ambil egg zone " .. zi)
			local before = carryScore()
			local got = false
			for _ = 1, 8 do
				if not (p.Parent and p.Enabled) or not cond() then break end
				fire(p)
				task.wait(0.06)
				if carryScore() > before then got = true break end
			end
			if not got then got = carryScore() > before or not (p.Parent and p.Enabled) end
			if not got then setStatus("gagal ambil egg") result = false return end

			-- ke safe zone
			setStatus("bawa ke safe zone")
			if method == 3 then
				setPos(hrp(), CFG.SAFE + Vector3.new(0, 3, 0))
				task.wait(0.15)
			else
				moveTo(CFG.SAFE, 4, cond)
			end
			placeEgg()
			task.wait(0.3)
			setStatus(string.format("selesai zone %d", zi))
		end)
		if not ok then warn("[Senar Hub] zoneSteal: " .. tostring(err)) end
		finish()
		return result
	end

	local stealing = false
	local function runSteal(cond)
		if S.busy or stealing then return end
		S.busy, stealing = true, true
		local z = settings.zone
		if z >= 1 and z <= #CFG.ZONES then
			zoneSteal(z, cond)
		else
			-- Auto: coba tiap zone sampai ada egg
			for i = 1, #CFG.ZONES do
				if not cond() then break end
				if zoneSteal(i, cond) then break end
			end
		end
		S.busy, stealing = false, false
	end

	task.spawn(function()
		while S.alive do
			if settings.autosteal and not S.busy and hrp() then
				runSteal(function() return S.alive and settings.autosteal end)
				task.wait(1.5)
			else
				task.wait(0.4)
			end
		end
	end)

	-- ================= AUTO BRING EGG =================
	task.spawn(function()
		local cd = {}
		while S.alive do
			if settings.autobring and not S.busy and hrp() then
				local h = hrp()
				local p = nearestPrompt(h.Position, 20, isTake, CFG.SAFE_RADIUS)
				if p and (cd[p] or 0) < os.clock() then
					cd[p] = os.clock() + 2
					fire(p)
					task.wait(0.3)
				end
				h = hrp()
				if h and carryScore() > 0 and (h.Position - CFG.SAFE).Magnitude > CFG.SAFE_RADIUS then
					S.busy = true
					local cond = function() return S.alive and settings.autobring end
					setStatus("bring egg ke safe zone")
					if settings.method == 3 then
						setPos(hrp(), CFG.SAFE + Vector3.new(0, 3, 0))
						task.wait(0.15)
					else
						moveTo(CFG.SAFE, 4, cond)
					end
					placeEgg()
					S.floatOn, S.noclip, S.busy = false, false, false
				end
			end
			task.wait(0.3)
		end
	end)

	-- ================= TREADMILL =================
	local treadCache, treadAt = nil, 0
	local function isMine(inst)
		local me = LocalPlayer
		local function matchVal(v)
			local s = tostring(v)
			return s == me.Name or s == me.DisplayName or s == tostring(me.UserId)
		end
		local node = inst
		for _ = 1, 6 do
			if not node or node == workspace then break end
			if node.Name == me.Name then return true end
			for _, v in pairs(node:GetAttributes()) do if matchVal(v) then return true end end
			for _, c in ipairs(node:GetChildren()) do
				if (c:IsA("StringValue") or c:IsA("IntValue") or c:IsA("NumberValue")) and matchVal(c.Value) then return true end
				if c:IsA("ObjectValue") and c.Value == me then return true end
			end
			node = node.Parent
		end
		return false
	end
	local function findTreadmill()
		if CFG.TREADMILL_POS then return CFG.TREADMILL_POS end
		if treadCache and treadCache.Parent and os.clock() - treadAt < 10 then return partPos(treadCache) end
		local best, bd, mine = nil, math.huge, nil
		for _, d in ipairs(workspace:GetDescendants()) do
			if (d:IsA("Model") or d:IsA("BasePart")) and any(d.Name:lower(), CFG.TREADMILL) then
				local pos = partPos(d)
				if pos then
					if isMine(d) then mine = d break end
					local dist = (pos - CFG.SAFE).Magnitude
					if dist < bd then best, bd = d, dist end
				end
			end
		end
		treadCache = mine or best
		treadAt = os.clock()
		return treadCache and partPos(treadCache) or nil
	end

	task.spawn(function()
		while S.alive do
			if settings.autotreadmill and not S.busy and hrp() then
				local pos = findTreadmill()
				if pos then
					local h = hrp()
					if (h.Position - pos).Magnitude > 7 then
						setStatus("tween ke treadmill")
						S.busy = true
						tweenMove(pos + Vector3.new(0, 3, 0), 4, function() return S.alive and settings.autotreadmill end)
						S.floatOn, S.noclip, S.busy = false, false, false
					end
					h = hrp()
					local p = h and nearestPrompt(h.Position, 25, function(x) return any(ptext(x), CFG.TREADMILL_USE) end)
					if p then fire(p) end
					setStatus("di treadmill")
				else
					setStatus("treadmill tidak ketemu")
				end
			end
			task.wait(1)
		end
	end)

	-- ================= UPGRADE / BUY BIKE / OPEN EGG / SELL ALL =================
	local function activateGui(b)
		pcall(function()
			if firesignal then
				firesignal(b.MouseButton1Click)
				firesignal(b.Activated)
			elseif getconnections then
				for _, c in ipairs(getconnections(b.MouseButton1Click)) do c:Fire() end
				for _, c in ipairs(getconnections(b.Activated)) do c:Fire() end
			end
		end)
	end

	local function pressKeywords(words, extra)
		local did = false
		for p in pairs(prompts) do
			if p.Parent and p.Enabled then
				local t = ptext(p)
				if any(t, words) and (not extra or any(t, extra)) then fire(p) did = true end
			end
		end
		for d in pairs(clickers) do
			if d.Parent then
				local t = (d.Name .. " " .. d.Parent.Name):lower()
				if any(t, words) and (not extra or any(t, extra)) and fireclickdetector then
					pcall(fireclickdetector, d)
					did = true
				end
			end
		end
		local pg = LocalPlayer:FindFirstChild("PlayerGui")
		if pg then
			for _, b in ipairs(pg:GetDescendants()) do
				if (b:IsA("TextButton") or b:IsA("ImageButton")) and b.Visible and not b:IsDescendantOf(gui) then
					local t = (b.Name .. " " .. (b:IsA("TextButton") and b.Text or "")):lower()
					if any(t, words) and (not extra or any(t, extra)) then activateGui(b) did = true end
				end
			end
		end
		return did
	end

	local function loopPress(flag, words, extra, fallbackWords, delay)
		task.spawn(function()
			while S.alive do
				if settings[flag] then
					local ok, did = pcall(pressKeywords, words, extra)
					if fallbackWords and not (ok and did) then pcall(pressKeywords, fallbackWords) end
				end
				task.wait(delay)
			end
		end)
	end
	loopPress("autoupgrade", CFG.UPGRADE_WORDS, CFG.TREADMILL, CFG.UPGRADE_WORDS, 2)
	loopPress("autobuybike", CFG.BUYBIKE_WORDS, CFG.BIKE_WORDS, nil, 2)
	loopPress("autoopenegg", CFG.OPEN_WORDS, CFG.EGG_WORDS, CFG.OPEN_WORDS, 2)
	loopPress("autosellall", CFG.SELL_WORDS, nil, nil, 3)

	-- ================= CONFIG =================
	local FOLDER = "SenarBike"
	local hasFS = (writefile and readfile and isfile and makefolder and listfiles and isfolder) and true or false
	local memCfg, cfgNames, curCfg = {}, {}, "Default"
	local KEYS = { "autosteal", "autotreadmill", "autoupgrade", "autobuybike", "autobring", "autoopenegg",
		"autosellall", "zone", "method", "forcespeed", "tweenspeed" }

	local function serialize()
		local lines = {}
		for _, k in ipairs(KEYS) do lines[#lines + 1] = "Senarcfg:" .. k .. ":" .. tostring(settings[k]) end
		return table.concat(lines, "\n")
	end
	local function applyText(text)
		local n = 0
		for line in tostring(text):gmatch("[^\r\n]+") do
			local k, v = line:match("^%s*Senarcfg:([%w_]+):(.-)%s*$")
			k = k and k:lower()
			if k and settings[k] ~= nil then
				local val
				if v == "true" then val = true elseif v == "false" then val = false else val = tonumber(v) end
				if val ~= nil and type(val) == type(settings[k]) then
					if k == "method" then val = math.clamp(math.floor(val), 1, 3) end
					if k == "zone" then val = math.clamp(math.floor(val), 0, #CFG.ZONES) end
					setSetting(k, val)
					n += 1
				end
			end
		end
		return n
	end
	local function cfgPath(name) return FOLDER .. "/" .. name .. ".cfg" end
	local function writeCfg(name, text)
		if hasFS then
			if not isfolder(FOLDER) then makefolder(FOLDER) end
			writefile(cfgPath(name), text)
		else
			memCfg[name] = text
		end
	end
	local function readCfg(name)
		if hasFS then return isfile(cfgPath(name)) and readfile(cfgPath(name)) or nil end
		return memCfg[name]
	end
	local function refreshNames()
		table.clear(cfgNames)
		if hasFS then
			if isfolder(FOLDER) then
				for _, f in ipairs(listfiles(FOLDER)) do
					local n = tostring(f):match("([^/\\]+)%.cfg$")
					if n then cfgNames[#cfgNames + 1] = n end
				end
			end
		else
			for n in pairs(memCfg) do cfgNames[#cfgNames + 1] = n end
		end
		table.sort(cfgNames)
		if #cfgNames == 0 then cfgNames[1] = "Default" end
	end
	if not readCfg("Default") then writeCfg("Default", serialize()) end
	refreshNames()

	-- ================= KOMPONEN UI (gaya Senar) =================
	local pMain = makeList(pages.Main, UDim2.fromScale(1, 1))
	local pSet = makeList(pages.Setting, UDim2.fromScale(1, 1))
	local order = 0

	local function row(page, text, h)
		order += 1
		local r = make("Frame", {
			Size = UDim2.new(1, 0, 0, h or 36), BackgroundColor3 = C.PANEL, BorderSizePixel = 0, LayoutOrder = order,
		}, page)
		corner(r, 8)
		glowStroke(r, 1)
		if text then
			make("TextLabel", {
				Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -112, 1, 0), BackgroundTransparency = 1,
				Text = text, TextColor3 = C.WHITE, Font = Enum.Font.GothamBold, TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			}, r)
		end
		return r
	end

	local function addSwitch(page, text, key)
		local r = row(page, text)
		local track = make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(38, 20), BackgroundColor3 = C.OFF, BorderSizePixel = 0,
		}, r)
		corner(track, 10)
		local knob = make("Frame", {
			Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = C.WHITE, BorderSizePixel = 0,
		}, track)
		corner(knob, 7)
		binders[key] = function(v)
			tween(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Position = v and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3) })
			tween(track, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundColor3 = v and C.RED or C.OFF })
		end
		binders[key](settings[key])
		local btn = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5 }, r)
		btn.Activated:Connect(function() setSetting(key, not settings[key]) end)
	end

	local function addInput(page, text, key, lo, hi)
		local r = row(page, text)
		local box = make("TextBox", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(78, 24),
			BackgroundColor3 = C.BG, Text = tostring(settings[key]), TextColor3 = C.WHITE, Font = Enum.Font.GothamBold,
			TextSize = 11, ClearTextOnFocus = false,
		}, r)
		corner(box, 6)
		glowStroke(box, 1)
		binders[key] = function(v) box.Text = tostring(v) end
		box.FocusLost:Connect(function()
			local n = tonumber(box.Text)
			if n then setSetting(key, math.clamp(n, lo, hi)) end
			box.Text = tostring(settings[key])
		end)
	end

	local function addButton(page, text, btnText, cb, w)
		local r = row(page, text)
		local b = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(w or 84, 24),
			BackgroundColor3 = C.RED_DK, BorderSizePixel = 0, Text = btnText, TextColor3 = C.WHITE,
			Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false,
		}, r)
		corner(b, 6)
		glowStroke(b, 1, C.RED)
		b.Activated:Connect(function()
			local ok, err = pcall(cb, b)
			if not ok then warn("[Senar Hub] " .. tostring(err)) end
		end)
		return b
	end

	local function addTextBox(page, placeholder, h)
		local r = row(page, nil, h or 36)
		local multi = (h or 36) > 40
		local box = make("TextBox", {
			Position = UDim2.fromOffset(6, 5), Size = UDim2.new(1, -12, 1, -10), BackgroundColor3 = C.BG, Text = "",
			PlaceholderText = placeholder, PlaceholderColor3 = C.GRAY, TextColor3 = C.WHITE, Font = Enum.Font.Gotham,
			TextSize = 11, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top, MultiLine = multi, TextWrapped = multi, ClipsDescendants = true,
		}, r)
		corner(box, 6)
		make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 4) }, box)
		return box
	end

	-- Dropdown pilih zone
	local function zoneLabel(v) return v == 0 and "Auto (semua)" or ("Zone " .. v) end
	local function addZoneDropdown(page)
		local r = row(page, "Pilih Zone")
		local btn = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(104, 24),
			BackgroundColor3 = C.RED_DK, BorderSizePixel = 0, Text = zoneLabel(settings.zone) .. " ▾",
			TextColor3 = C.WHITE, Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false,
		}, r)
		corner(btn, 6)
		glowStroke(btn, 1, C.RED)

		order += 1
		local drop = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.SIDE,
			BorderSizePixel = 0, LayoutOrder = order, Visible = false,
		}, page)
		corner(drop, 8)
		glowStroke(drop, 1)
		make("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, drop)
		make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, drop)

		for i = 0, #CFG.ZONES do
			local o = make("TextButton", {
				Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C.PANEL, BorderSizePixel = 0, LayoutOrder = i,
				Text = zoneLabel(i), TextColor3 = C.WHITE, Font = Enum.Font.GothamBold, TextSize = 11, AutoButtonColor = false,
			}, drop)
			corner(o, 6)
			o.Activated:Connect(function()
				setSetting("zone", i)
				drop.Visible = false
			end)
		end
		btn.Activated:Connect(function() drop.Visible = not drop.Visible end)
		binders.zone = function(v) btn.Text = zoneLabel(v) .. " ▾" end
	end

	-- ================= ISI TAB MAIN =================
	addZoneDropdown(pMain)
	addButton(pMain, "Steal zone terpilih sekarang", "Steal", function()
		if S.busy then setStatus("masih sibuk") return end
		task.spawn(function()
			runSteal(function() return S.alive end)
		end)
	end)
	addSwitch(pMain, "Auto Steal", "autosteal")
	addSwitch(pMain, "Auto Treadmill (Tween ke treadmill-ku)", "autotreadmill")
	addSwitch(pMain, "Auto Upgrade Treadmill", "autoupgrade")
	addSwitch(pMain, "Auto Buy Bike", "autobuybike")
	addSwitch(pMain, "Auto Bring Egg (grab egg)", "autobring")
	addSwitch(pMain, "Auto Open Egg", "autoopenegg")
	addSwitch(pMain, "Auto Sell All", "autosellall")

	-- ================= ISI TAB SETTING =================
	local methodBtn
	methodBtn = addButton(pSet, "Auto Farming Method (1-3)", "", function()
		setSetting("method", settings.method % 3 + 1)
	end, 112)
	binders.method = function(v)
		methodBtn.Text = ({ "1: TP", "2: Gerak Paksa", "3: Instant Steal" })[v] or tostring(v)
	end
	binders.method(settings.method)

	addInput(pSet, "Set Speed Gerak Paksa", "forcespeed", 10, 500)
	addInput(pSet, "Set Tween Speed", "tweenspeed", 10, 500)

	order += 1
	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = order, Text = "CONFIG",
		TextColor3 = C.GRAY, Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
	}, pSet)

	local selBtn
	selBtn = addButton(pSet, "Config:", curCfg, function()
		refreshNames()
		local idx = table.find(cfgNames, curCfg) or 0
		curCfg = cfgNames[idx % #cfgNames + 1]
		selBtn.Text = curCfg
	end, 112)

	local nameBox = addTextBox(pSet, "Name: (nama config baru)")
	addButton(pSet, "Create Config", "Create", function()
		local n = nameBox.Text:gsub("[^%w_%-]", "")
		if n == "" then setStatus("isi Name dulu") return end
		writeCfg(n, serialize())
		refreshNames()
		curCfg = n
		selBtn.Text = n
		nameBox.Text = ""
		setStatus("config dibuat: " .. n)
	end)
	addButton(pSet, "Delete Config", "Delete", function()
		if curCfg == "Default" then setStatus("Default tidak bisa dihapus") return end
		if hasFS then pcall(delfile, cfgPath(curCfg)) else memCfg[curCfg] = nil end
		setStatus("config dihapus: " .. curCfg)
		curCfg = "Default"
		selBtn.Text = curCfg
		refreshNames()
	end)
	addButton(pSet, "Save Config", "Save", function()
		writeCfg(curCfg, serialize())
		setStatus("config disimpan: " .. curCfg)
	end)
	addButton(pSet, "Set Config (pakai)", "Set", function()
		local t = readCfg(curCfg)
		if not t then setStatus("config tidak ada") return end
		setStatus(string.format("config %s dimuat (%d nilai)", curCfg, applyText(t)))
	end)
	local viewBox = addTextBox(pSet, "isi config tampil di sini", 90)
	addButton(pSet, "Open Config", "Open", function()
		local t = readCfg(curCfg) or "(kosong)"
		viewBox.Text = t
		if setclipboard then pcall(setclipboard, t) end
		setStatus("config dibuka + disalin")
	end)
	local upBox = addTextBox(pSet, "tempel config (Senarcfg:autosteal:true ...)", 90)
	addButton(pSet, "Upload Config", "Upload", function()
		local n = applyText(upBox.Text)
		if n > 0 then writeCfg(curCfg, serialize()) end
		setStatus(string.format("upload: %d nilai ke %s", n, curCfg))
	end)
	addButton(pSet, "Salin teks prompt (debug)", "Dump", function()
		local h = hrp()
		local lines = {}
		for p in pairs(prompts) do
			if p.Parent and p.Enabled then
				local pos = promptPos(p)
				lines[#lines + 1] = string.format("%s | %d stud", ptext(p),
					(h and pos) and math.floor((pos - h.Position).Magnitude) or -1)
			end
			if #lines >= 50 then break end
		end
		local s = #lines > 0 and table.concat(lines, "\n") or "(tidak ada prompt)"
		if setclipboard then pcall(setclipboard, s) end
		print(s)
		setStatus("dump disalin")
	end)

	-- ikon tab
	for name, id in pairs({ Main = ICON_MAIN, Setting = ICON_SETTING }) do
		local t = tabBtns[name]
		if t then
			make("ImageLabel", {
				Position = UDim2.fromOffset(8, 5), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1,
				Image = "rbxassetid://" .. id, ScaleType = Enum.ScaleType.Fit, ZIndex = 3,
			}, t.btn)
			t.btn.TextXAlignment = Enum.TextXAlignment.Left
			make("UIPadding", { PaddingLeft = UDim.new(0, 36) }, t.btn)
		end
	end

	-- muat config Default saat start
	local t = readCfg("Default")
	if t then applyText(t) end
	setStatus("Siap | metode " .. settings.method)

	gui.Destroying:Connect(function()
		S.alive = false
		if floatPart then pcall(function() floatPart:Destroy() end) end
	end)
end)
if not okBike then
	warn("[Senar Hub] ERROR: " .. tostring(errBike))
	UI.setStatus("ERR: " .. tostring(errBike):sub(1, 60))
end
