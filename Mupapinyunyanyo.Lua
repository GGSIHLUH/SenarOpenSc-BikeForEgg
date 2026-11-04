-- SENAR HUB | UI v2 + Bike for Egg
-- + System Key WAJIB dulu (Main / Finder / Config terkunci sebelum key valid)
-- + Tab Finder (egg acak + income acak per rentang)
-- + Resize, 23 Tema, Mode Kaitun, Super Modern Mode
--
-- Hook (taruh kodemu di paling bawah kalau perlu):
--   local UI = getgenv().SenarUI
--   UI.onToggle / onJoin / onCopy / onClear / onKeySubmit / onKeyResult
--   UI.onKaitun / onTheme / onFind(entry)
--   UI.eggs  -> tabel daftar egg Finder: { "Nama", minM, maxM }
--   UI.addLog(name, income, info)  UI.clearLogs()  UI.setStatus("...")  UI.setTheme("Dracula")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

-- ================= CONFIG =================
local ICON_ASSET_ID   = 94315198453864
local KAITUN_ASSET_ID = 4548250991
local DISCORD_LINK    = "https://discord.gg/6VeEjrRYy"
local DISCORD_CODE    = "6VeEjrRYy"
local PREMIUM_KEYS    = { ["SENAR-PREMIUM-KEY"] = true }
local KEY_WAIT        = 300 -- detik (5 menit)
local KEY_FILE        = "SenarHub_Key.txt"

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
	onKeyResult = function(valid, tier) end,
	onKaitun = function(state) end,
	onTheme = function(name) end,
	onFind = function(entry) end,
	addLog = function() end,
	clearLogs = function() end,
	setStatus = function() end,
	setTheme = function() end,
	destroy = function() end,
}
env.SenarUI = UI

-- ================= TEMA =================
local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)

local function c(t) return Color3.fromRGB(t[1], t[2], t[3]) end

local function mk(bg, panel, text, accent, accent2, light)
	local BG, PANEL, TEXT, ACC = c(bg), c(panel), c(text), c(accent)
	local ACC2 = c(accent2 or accent)
	local lum = ACC.R * 0.299 + ACC.G * 0.587 + ACC.B * 0.114
	return {
		BG = BG, PANEL = PANEL, TEXT = TEXT, ACCENT = ACC, ACCENT2 = ACC2,
		SIDE = BG:Lerp(BLACK, light and 0.05 or 0.4),
		HOVER = PANEL:Lerp(ACC, 0.2),
		STROKE = PANEL:Lerp(ACC, 0.4),
		OFF = PANEL:Lerp(TEXT, 0.2),
		GRAY = BG:Lerp(TEXT, 0.6),
		ACCENT_DK = ACC:Lerp(BG, 0.65),
		FLASH = light and ACC or WHITE,
		ONACC = (lum > 0.6) and BLACK or WHITE,
	}
end

local THEMES = {
	{ "Senar",             mk({13,8,10},    {26,15,18},   {255,255,255}, {235,35,60},   {255,140,190}) },
	{ "Dark",              mk({18,18,20},   {30,30,34},   {235,235,240}, {90,140,255},  {140,180,255}) },
	{ "Midnight",          mk({8,10,24},    {18,22,46},   {220,226,255}, {110,120,255}, {160,170,255}) },
	{ "Charcoal",          mk({28,29,31},   {42,44,47},   {230,230,230}, {150,160,170}, {200,205,210}) },
	{ "Tokyo Night",       mk({26,27,38},   {36,40,59},   {192,202,245}, {122,162,247}, {187,154,247}) },
	{ "Rose Pine",         mk({25,23,36},   {38,35,58},   {224,222,244}, {235,111,146}, {196,167,231}) },
	{ "Catppuccin Mocha",  mk({30,30,46},   {49,50,68},   {205,214,244}, {203,166,247}, {245,194,231}) },
	{ "Catppuccin Macchiato", mk({36,39,58},{54,58,79},   {202,211,245}, {198,160,246}, {245,189,230}) },
	{ "Catppuccin Frappe", mk({48,52,70},   {65,69,89},   {198,208,245}, {202,158,230}, {244,184,228}) },
	{ "Dracula",           mk({40,42,54},   {68,71,90},   {248,248,242}, {189,147,249}, {255,121,198}) },
	{ "Nord",              mk({46,52,64},   {59,66,82},   {236,239,244}, {136,192,208}, {129,161,193}) },
	{ "Gruvbox Dark",      mk({40,40,40},   {60,56,54},   {235,219,178}, {250,189,47},  {254,128,25}) },
	{ "One Dark",          mk({40,44,52},   {53,59,69},   {171,178,191}, {97,175,239},  {198,120,221}) },
	{ "Kuro",              mk({0,0,0},      {14,14,14},   {240,240,240}, {255,255,255}, {160,160,160}) },
	{ "Light",             mk({245,246,248},{255,255,255},{30,32,36},    {50,110,235},  {120,160,255}, true) },
	{ "Catppuccin Latte",  mk({239,241,245},{230,233,239},{76,79,105},   {136,57,239},  {234,118,203}, true) },
	{ "Rose Pine Dawn",    mk({250,244,237},{255,250,243},{87,82,121},   {215,130,126}, {144,122,169}, true) },
	{ "Gruvbox Light",     mk({251,241,199},{242,229,188},{60,56,54},    {215,153,33},  {175,58,3},    true) },
	{ "Emerald",           mk({6,22,16},    {12,42,30},   {220,255,240}, {16,210,130},  {110,240,190}) },
	{ "Ocean",             mk({6,18,32},    {12,36,60},   {214,236,255}, {30,150,255},  {80,210,230}) },
	{ "Sunset",            mk({28,12,18},   {52,22,30},   {255,232,220}, {255,120,60},  {255,70,120}) },
	{ "Cyberpunk",         mk({10,6,24},    {24,12,48},   {240,235,255}, {255,40,160},  {0,235,255}) },
	{ "Monokai",           mk({39,40,34},   {62,61,50},   {248,248,242}, {166,226,46},  {249,38,114}) },
	{ "Aura",              mk({21,20,27},   {33,32,44},   {237,236,244}, {162,119,255}, {97,255,202}) },
}

local T = THEMES[1][2]
local currentTheme = THEMES[1][1]
local binds, hooks = {}, {}

local function th(key) return { t = key } end

local function onTheme(fn)
	pcall(fn)
	hooks[#hooks + 1] = fn
end

local function applyTheme(name)
	local found
	for _, e in ipairs(THEMES) do
		if e[1] == name then found = e break end
	end
	if not found then return end
	T = found[2]
	currentTheme = name
	local alive = {}
	for _, b in ipairs(binds) do
		if b[1].Parent then
			b[1][b[2]] = T[b[3]]
			alive[#alive + 1] = b
		end
	end
	binds = alive
	for _, fn in ipairs(hooks) do pcall(fn) end
end
UI.setTheme = applyTheme

-- ================= HELPER =================
local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do
		if type(v) == "table" and v.t then
			obj[k] = T[v.t]
			binds[#binds + 1] = { obj, k, v.t }
		else
			obj[k] = v
		end
	end
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

local function tween(obj, info, props)
	local tw = TweenService:Create(obj, info, props)
	tw:Play()
	return tw
end

local tweens = {}
local sweepGradients = {}
local spinGrads = {}
local modern = false

-- animasi tombol: hover / tekan (lebih besar saat Super Modern)
local function fx(hit, target, amp)
	target = target or hit
	amp = amp or 0.06
	local s = make("UIScale", { Scale = 1 }, target)
	local function isPress(i)
		return i.UserInputType == Enum.UserInputType.MouseButton1
			or i.UserInputType == Enum.UserInputType.Touch
	end
	hit.MouseEnter:Connect(function()
		tween(s, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Scale = 1 + (modern and amp or amp * 0.3) })
	end)
	hit.MouseLeave:Connect(function()
		tween(s, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Scale = 1 })
	end)
	hit.InputBegan:Connect(function(i)
		if isPress(i) then
			tween(s, TweenInfo.new(0.09, Enum.EasingStyle.Quad), { Scale = 1 - (modern and amp * 1.6 or amp * 0.6) })
		end
	end)
	hit.InputEnded:Connect(function(i)
		if isPress(i) then
			tween(s, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		end
	end)
end

local function sweepSeq(base, hi)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, base),
		ColorSequenceKeypoint.new(0.38, base),
		ColorSequenceKeypoint.new(0.50, hi),
		ColorSequenceKeypoint.new(0.62, base),
		ColorSequenceKeypoint.new(1, base),
	})
end

local function addSweep(inst, baseKey, hiKey)
	local g = make("UIGradient", { Offset = Vector2.new(-1, 0) }, inst)
	local function paint() g.Color = sweepSeq(T[baseKey], T[hiKey]) end
	paint()
	sweepGradients[g] = paint
	return g
end

local function glowStroke(obj, thick, baseKey)
	local s = make("UIStroke", {
		Color = WHITE, Thickness = thick or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, obj)
	addSweep(s, baseKey or "STROKE", "FLASH")
	return s
end

local function spinSeq()
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, BLACK),
		ColorSequenceKeypoint.new(0.2, T.ACCENT),
		ColorSequenceKeypoint.new(0.35, T.FLASH),
		ColorSequenceKeypoint.new(0.5, BLACK),
		ColorSequenceKeypoint.new(0.7, T.ACCENT_DK),
		ColorSequenceKeypoint.new(0.85, T.FLASH),
		ColorSequenceKeypoint.new(1, BLACK),
	})
end

local function spinStroke(parent, thick)
	local st = make("UIStroke", {
		Color = WHITE, Thickness = thick or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
	local g = make("UIGradient", { Color = spinSeq() }, st)
	spinGrads[g] = true
	local tw = TweenService:Create(g,
		TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, false, 0),
		{ Rotation = 360 })
	tw:Play()
	table.insert(tweens, tw)
	return st
end

onTheme(function()
	for g, paint in pairs(sweepGradients) do
		if g.Parent then paint() else sweepGradients[g] = nil end
	end
	for g in pairs(spinGrads) do
		if g.Parent then g.Color = spinSeq() else spinGrads[g] = nil end
	end
end)

-- ================= GUI =================
local gui = make("ScreenGui", {
	Name = randName(14), ResetOnSpawn = false, DisplayOrder = 999,
	IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
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
local kaitun = false
local restoreRender
local myCleanup = function()
	if gui and gui.Parent then gui:Destroy() end
end
env.__SenarCleanup = myCleanup
UI.destroy = myCleanup

-- driver kilatan
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

-- overlay Kaitun (di belakang window)
local kOverlay = make("Frame", {
	Name = "K", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK,
	BorderSizePixel = 0, Active = true, Visible = false, ZIndex = 0,
}, gui)
make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.44),
	Size = UDim2.fromOffset(300, 30), BackgroundTransparency = 1, Text = "KAITUN MODE",
	TextColor3 = th("ACCENT"), Font = Enum.Font.GothamBlack, TextSize = 24,
}, kOverlay)
local kSub = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52),
	Size = UDim2.fromOffset(300, 20), BackgroundTransparency = 1, Text = "Uptime 00:00:00",
	TextColor3 = th("GRAY"), Font = Enum.Font.GothamBold, TextSize = 13,
}, kOverlay)
make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.58),
	Size = UDim2.fromOffset(340, 18), BackgroundTransparency = 1,
	Text = "Buka UI lalu tekan ikon Kaitun untuk keluar",
	TextColor3 = th("GRAY"), Font = Enum.Font.Gotham, TextSize = 11,
}, kOverlay)

-- holder (posisi, drag, skala)
local holder = make("Frame", {
	Name = "Holder", AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H),
	BackgroundTransparency = 1, ZIndex = 1,
}, gui)
local fitScale = make("UIScale", { Scale = 1 }, holder)

local fitMul, userMul = 1, 1
local function maxTotal()
	local cam = workspace.CurrentCamera
	if not cam then return 1.5 end
	local vp = cam.ViewportSize
	return math.min(vp.X / (W + 10), vp.Y / (H + 10), 1.8)
end
local function applyScale()
	fitScale.Scale = math.clamp(fitMul * userMul, 0.4, math.max(0.4, maxTotal()))
end
local function updateFit()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local vp = cam.ViewportSize
	fitMul = math.clamp(math.min(vp.X / (W + 30), vp.Y / (H + 30)), 0.45, 1)
	applyScale()
end
updateFit()
if workspace.CurrentCamera then
	table.insert(conns, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateFit))
end

-- glow thruster (mobil terbang) di bawah window
local thr = make("Frame", {
	Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 0,
}, holder)
local glow1 = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(W / 2, H - 2),
	Size = UDim2.fromOffset(W * 0.8, 26), BackgroundColor3 = th("ACCENT"),
	BackgroundTransparency = 0.75, BorderSizePixel = 0,
}, thr)
corner(glow1, 13)
make("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1),
	}),
}, glow1)
local glow2 = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(W / 2, H + 2),
	Size = UDim2.fromOffset(W * 0.5, 4), BackgroundColor3 = th("ACCENT2"),
	BackgroundTransparency = 0.15, BorderSizePixel = 0,
}, thr)
corner(glow2, 2)
make("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1),
	}),
}, glow2)
local jets = {}
for i, x in ipairs({ W * 0.22, W * 0.78 }) do
	local j = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(x, H - 2),
		Size = UDim2.fromOffset(10, 26), BackgroundColor3 = th("ACCENT2"), BorderSizePixel = 0,
	}, thr)
	corner(j, 5)
	make("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, j)
	jets[i] = { frame = j, ph = i * 1.7 }
end

-- window utama
local main = make("Frame", {
	Name = "Main", Size = UDim2.fromScale(1, 1),
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = th("BG"), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 1,
}, holder)
corner(main, 12)
local popScale = make("UIScale", { Scale = 1 }, main)
local mainStroke = spinStroke(main, 1.5)

-- ---------- Balok atas & bawah ----------
local blocks = {}
do
	local BW, GAP = 16, 4
	local count = math.floor((W - 16) / (BW + GAP))
	local rng = Random.new(7)
	for i = 1, count do
		local x = 8 + (i - 1) * (BW + GAP)
		local r = rng:NextNumber()
		local hTop = rng:NextInteger(7, 18)
		local hBot = rng:NextInteger(7, 18)
		local top = make("Frame", {
			Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(BW, hTop),
			BackgroundTransparency = 0.35, BorderSizePixel = 0,
		}, main)
		local bot = make("Frame", {
			AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(x, H),
			Size = UDim2.fromOffset(BW, hBot),
			BackgroundTransparency = 0.35, BorderSizePixel = 0,
		}, main)
		table.insert(blocks, { frame = top, base = hTop, phase = rng:NextNumber() * 6.28, r = r })
		table.insert(blocks, { frame = bot, base = hBot, phase = rng:NextNumber() * 6.28, r = r })
	end
	blocks.width = BW
end
onTheme(function()
	for _, b in ipairs(blocks) do
		b.frame.BackgroundColor3 = T.ACCENT_DK:Lerp(T.ACCENT, b.r)
	end
end)

-- ---------- Speed lines (Super Modern) ----------
local speedLines = {}
do
	local rng = Random.new(21)
	for i = 1, 8 do
		local w = rng:NextInteger(40, 120)
		local f = make("Frame", {
			Size = UDim2.fromOffset(w, 1), BackgroundColor3 = th("ACCENT2"),
			BackgroundTransparency = 0.7, BorderSizePixel = 0, Visible = false, ZIndex = 0,
		}, main)
		table.insert(speedLines, {
			frame = f, w = w, x = rng:NextInteger(0, W),
			y = rng:NextInteger(30, H - 30), v = rng:NextInteger(260, 620),
		})
	end
end

-- ---------- Toast ----------
local toastLbl = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(W / 2 + 66, H + 30),
	Size = UDim2.fromOffset(250, 24), BackgroundColor3 = th("PANEL"), BorderSizePixel = 0,
	Text = "", TextColor3 = th("TEXT"), Font = Enum.Font.GothamBold, TextSize = 11,
	Visible = false, ZIndex = 70,
}, main)
corner(toastLbl, 8)
make("UIStroke", { Color = th("ACCENT"), Thickness = 1 }, toastLbl)
local toastId = 0
local function toast(text)
	toastId += 1
	local id = toastId
	toastLbl.Text = text
	toastLbl.Position = UDim2.fromOffset(W / 2 + 66, H + 30)
	toastLbl.Visible = true
	tween(toastLbl, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.fromOffset(W / 2 + 66, H - 8) })
	task.delay(2.4, function()
		if id ~= toastId or not toastLbl.Parent then return end
		tween(toastLbl, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Position = UDim2.fromOffset(W / 2 + 66, H + 30) })
		task.delay(0.28, function()
			if id == toastId and toastLbl.Parent then toastLbl.Visible = false end
		end)
	end)
end

-- ---------- Gate System Key ----------
local Gate = { unlocked = false, tier = nil, subs = {} }
local function onUnlock(fn)
	Gate.subs[#Gate.subs + 1] = fn
	pcall(fn, Gate.unlocked, Gate.tier)
end
local function setUnlocked(on, tier)
	local changed = (Gate.unlocked ~= on)
	Gate.unlocked, Gate.tier = on, tier
	if changed then
		for _, fn in ipairs(Gate.subs) do pcall(fn, on, tier) end
	end
end

-- ---------- Super Modern toggle ----------
local function setModern(on)
	modern = on
	thr.Visible = on
	for _, l in ipairs(speedLines) do l.frame.Visible = on end
	if not on then
		main.Position = UDim2.fromScale(0.5, 0.5)
		mainStroke.Thickness = 1.5
	else
		popScale.Scale = 0.9
		tween(popScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
	end
	toast(on and "Super Modern Mode ON" or "Super Modern Mode OFF")
end

-- ---------- Sidebar ----------
local side = make("Frame", {
	Position = UDim2.fromOffset(8, 24), Size = UDim2.fromOffset(124, 252),
	BackgroundColor3 = th("SIDE"), BackgroundTransparency = 0.12, BorderSizePixel = 0,
}, main)
corner(side, 10)
glowStroke(side, 1)

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
	BackgroundTransparency = 1, Text = "Senar", TextColor3 = WHITE,
	Font = Enum.Font.GothamBlack, TextSize = 18, LayoutOrder = 1,
}, titleRow)
local senarGrad = make("UIGradient", {}, senar)
onTheme(function()
	senarGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, T.ACCENT),
		ColorSequenceKeypoint.new(0.40, T.ACCENT),
		ColorSequenceKeypoint.new(0.44, T.ACCENT2),
		ColorSequenceKeypoint.new(1, T.ACCENT2),
	})
end)

local hub = make("TextLabel", {
	Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1, Text = "Hub", TextColor3 = WHITE,
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

local dot = make("Frame", {
	Position = UDim2.fromOffset(12, 40), Size = UDim2.fromOffset(6, 6),
	BackgroundColor3 = th("ACCENT"), BorderSizePixel = 0,
}, side)
corner(dot, 3)
local statusLbl = make("TextLabel", {
	Position = UDim2.fromOffset(24, 34), Size = UDim2.new(1, -30, 0, 18),
	BackgroundTransparency = 1, Text = "Terkunci: butuh key", TextColor3 = th("GRAY"),
	Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, side)
UI.setStatus = function(t)
	statusLbl.Text = tostring(t)
end

-- ---------- Konten & halaman ----------
local content = make("Frame", {
	Position = UDim2.fromOffset(140, 24), Size = UDim2.fromOffset(322, 252),
	BackgroundTransparency = 1,
}, main)

local pages, tabBtns = {}, {}
local tabNames = { "Main", "Finder", "Config", "Settings", "System Key" }
local currentTab

for _, name in ipairs(tabNames) do
	pages[name] = make("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false,
	}, content)
end

local function refreshTabs()
	for n, t in pairs(tabBtns) do
		local on = (n == currentTab)
		t.btn.BackgroundColor3 = T.HOVER
		t.btn.BackgroundTransparency = on and 0.15 or 1
		t.btn.TextColor3 = on and T.TEXT or T.GRAY
		t.stroke.Enabled = on
	end
end

local function selectTab(name)
	currentTab = name
	for n, p in pairs(pages) do
		if n == name then
			if not p.Visible then
				p.Visible = true
				p.Position = UDim2.fromOffset(modern and 26 or 12, 0)
				tween(p, TweenInfo.new(modern and 0.4 or 0.2,
					modern and Enum.EasingStyle.Back or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Position = UDim2.fromOffset(0, 0) })
			end
		else
			p.Visible = false
		end
	end
	refreshTabs()
end

for i, name in ipairs(tabNames) do
	local b = make("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(62, 70 + (i - 1) * 30), Size = UDim2.fromOffset(108, 26),
		BackgroundColor3 = th("HOVER"), BackgroundTransparency = 1, BorderSizePixel = 0,
		Text = name, TextColor3 = th("GRAY"), Font = Enum.Font.GothamBold, TextSize = 12,
		AutoButtonColor = false,
	}, side)
	corner(b, 8)
	local st = glowStroke(b, 1)
	st.Enabled = false
	tabBtns[name] = { btn = b, stroke = st }
	fx(b, b, 0.05)
	b.Activated:Connect(function() selectTab(name) end)
end
onTheme(refreshTabs)

local hideBtn = make("TextButton", {
	AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.fromOffset(108, 30),
	BackgroundColor3 = th("PANEL"), BorderSizePixel = 0, Text = "Hide", TextColor3 = th("TEXT"),
	Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false,
}, side)
corner(hideBtn, 8)
glowStroke(hideBtn, 1)
fx(hideBtn, hideBtn, 0.05)

-- ---------- Kunci halaman sebelum key valid ----------
local function lockPage(name)
	local ov = make("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = th("BG"), BackgroundTransparency = 0.05,
		BorderSizePixel = 0, Active = true, ZIndex = 30,
	}, pages[name])
	corner(ov, 8)
	glowStroke(ov, 1)
	make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38),
		Size = UDim2.fromOffset(260, 26), BackgroundTransparency = 1, Text = "TERKUNCI",
		TextColor3 = th("ACCENT"), Font = Enum.Font.GothamBlack, TextSize = 20, ZIndex = 31,
	}, ov)
	make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.50),
		Size = UDim2.fromOffset(280, 32), BackgroundTransparency = 1, TextWrapped = true,
		Text = "Verifikasi System Key dulu untuk memakai fitur ini",
		TextColor3 = th("GRAY"), Font = Enum.Font.Gotham, TextSize = 11, ZIndex = 31,
	}, ov)
	local go = make("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.66),
		Size = UDim2.fromOffset(150, 30), BackgroundColor3 = th("ACCENT"), BorderSizePixel = 0,
		Text = "BUKA SYSTEM KEY", TextColor3 = th("ONACC"), Font = Enum.Font.GothamBold,
		TextSize = 11, AutoButtonColor = false, ZIndex = 32,
	}, ov)
	corner(go, 8)
	fx(go, go, 0.05)
	go.Activated:Connect(function() selectTab("System Key") end)
	onUnlock(function(on) ov.Visible = not on end)
end
lockPage("Main")
lockPage("Finder")
lockPage("Config")

-- ---------- Kaitun ----------
local activeFeatures = {}
local kStart = os.clock()

local kBtn = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(W - 8, 2), Size = UDim2.fromOffset(22, 22),
	BackgroundColor3 = th("PANEL"), BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 55,
}, main)
corner(kBtn, 6)
glowStroke(kBtn, 1)
local kImg = make("ImageLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1,
	Image = "rbxassetid://" .. tostring(KAITUN_ASSET_ID), ZIndex = 56,
}, kBtn)
local kLbl = make("TextLabel", {
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(W - 36, 5), Size = UDim2.fromOffset(80, 16),
	BackgroundTransparency = 1, Text = "KAITUN ON", TextColor3 = th("ACCENT"),
	Font = Enum.Font.GothamBold, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Right,
	Visible = false, ZIndex = 55,
}, main)
fx(kBtn, kBtn, 0.12)

local function kaitunUnlocked() return next(activeFeatures) ~= nil end

local function paintKaitun()
	local unlocked = kaitunUnlocked()
	kImg.ImageTransparency = (unlocked or kaitun) and 0 or 0.6
	kBtn.BackgroundColor3 = kaitun and T.ACCENT or T.PANEL
	kLbl.Visible = kaitun
end
onTheme(paintKaitun)

restoreRender = function()
	pcall(function() RunService:Set3dRenderingEnabled(true) end)
	if setfpscap then pcall(setfpscap, 0) end
end

local function setKaitun(state)
	if state and not kaitunUnlocked() then
		toast("Hidupkan 1 fitur dulu untuk unlock Kaitun")
		return
	end
	if kaitun == state then return end
	kaitun = state
	kOverlay.Visible = state
	if state then
		kStart = os.clock()
		pcall(function() RunService:Set3dRenderingEnabled(false) end)
		if setfpscap then pcall(setfpscap, 20) end
	else
		restoreRender()
	end
	paintKaitun()
	local okc, err = pcall(UI.onKaitun, state)
	if not okc then warn("[Senar Hub] onKaitun: " .. tostring(err)) end
	toast(state and "Kaitun Mode ON" or "Kaitun Mode OFF")
end

local function refreshKaitun()
	if kaitun and not kaitunUnlocked() then
		setKaitun(false)
	end
	paintKaitun()
end

kBtn.Activated:Connect(function() setKaitun(not kaitun) end)

-- ---------- Komponen: switch card ----------
local function makeSwitchCard(parent, name, size, pos, order, isFeature, internal)
	local card = make("Frame", {
		Size = size, Position = pos or UDim2.new(), LayoutOrder = order or 0,
		BackgroundColor3 = th("PANEL"), BorderSizePixel = 0,
	}, parent)
	corner(card, 8)
	glowStroke(card, 1)

	make("TextLabel", {
		Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -64, 1, 0),
		BackgroundTransparency = 1, Text = name, TextColor3 = th("TEXT"),
		Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	local track = make("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(38, 20), BorderSizePixel = 0,
	}, card)
	corner(track, 10)
	local knob = make("Frame", {
		Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0,
	}, track)
	corner(knob, 7)

	local overlay = make("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5,
	}, card)

	local on = false
	local function paint(animate)
		local pos2 = on and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
		local kc = on and T.ONACC or T.TEXT
		local tc = on and T.ACCENT or T.OFF
		if animate then
			local info = TweenInfo.new(modern and 0.3 or 0.18,
				modern and Enum.EasingStyle.Back or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			tween(knob, info, { Position = pos2, BackgroundColor3 = kc })
			tween(track, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundColor3 = tc })
		else
			knob.Position = pos2
			knob.BackgroundColor3 = kc
			track.BackgroundColor3 = tc
		end
	end
	onTheme(function() paint(false) end)
	fx(overlay, card, 0.025)

	overlay.Activated:Connect(function()
		on = not on
		paint(true)
		if isFeature then
			activeFeatures[name] = on or nil
			refreshKaitun()
		end
		if internal then pcall(internal, on) end
		local okc, err = pcall(UI.onToggle, name, on)
		if not okc then warn("[Senar Hub] onToggle: " .. tostring(err)) end
	end)
	return card
end

-- ---------- Komponen: list ----------
local function makeList(parent, size, pos)
	local s = make("ScrollingFrame", {
		Size = size, Position = pos or UDim2.new(),
		BackgroundColor3 = th("SIDE"), BackgroundTransparency = 0.25, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = th("ACCENT"),
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
		BackgroundColor3 = dim and th("HOVER") or th("PANEL"), BorderSizePixel = 0,
		Text = text, TextColor3 = dim and th("GRAY") or th("TEXT"),
		Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false,
	}, parent)
	corner(b, 6)
	glowStroke(b, 1)
	fx(b, b, 0.08)
	return b
end

local function sectionLabel(parent, text, props)
	local p = {
		Position = UDim2.fromOffset(2, 0), Size = UDim2.fromOffset(120, 14),
		BackgroundTransparency = 1, Text = text, TextColor3 = th("GRAY"),
		Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
	}
	if props then for k, v in pairs(props) do p[k] = v end end
	return make("TextLabel", p, parent)
end

---------------------------------------------------------------------
-- HALAMAN: FINDER (egg acak + income acak per rentang)
---------------------------------------------------------------------
do
	local p = pages.Finder

	-- { "Nama Egg", minM, maxM }  (income dalam juta / M per detik)
	-- Tambah egg Bike for Egg lain di sini, atau lewat UI.eggs dari luar.
	local EGGS = {
		{ "King Snake", 10, 500 },
		{ "Dragon Ice", 80, 800 },
	}
	UI.eggs = EGGS

	local finderOn = false
	makeSwitchCard(p, "Finder (Random)", UDim2.new(1, 0, 0, 38), UDim2.new(0, 0, 0, 0), 0, true,
		function(on) finderOn = on end)

	sectionLabel(p, "LIVE FEED", { Position = UDim2.fromOffset(2, 46), Size = UDim2.fromOffset(100, 14) })
	local clearBtn = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, 44), Size = UDim2.fromOffset(44, 16),
		BackgroundTransparency = 1, Text = "Clear", TextColor3 = th("TEXT"),
		Font = Enum.Font.GothamBold, TextSize = 10,
	}, p)

	local list = makeList(p, UDim2.new(1, 0, 1, -64), UDim2.fromOffset(0, 64))

	local counter, cards = 0, {}
	local MAX_CARDS = 30

	local function fmtIncome(m)
		if m >= 1000 then return string.format("$%.2fB/s", m / 1000) end
		return string.format("$%dM/s", m)
	end

	UI.addLog = function(name, income, info)
		counter += 1
		local entry = {
			name = tostring(name or "Egg"),
			income = tostring(income or "$0M/s"),
			info = tostring(info or ""),
		}

		local card = make("Frame", {
			LayoutOrder = -counter, Size = UDim2.new(1, 0, 0, 52),
			BackgroundColor3 = th("PANEL"), BorderSizePixel = 0,
		}, list)
		corner(card, 8)
		glowStroke(card, 1)

		make("Frame", {
			Position = UDim2.fromOffset(8, 9), Size = UDim2.fromOffset(3, 34),
			BackgroundColor3 = th("ACCENT"), BorderSizePixel = 0,
		}, card)

		local icon = make("Frame", {
			Position = UDim2.fromOffset(18, 11), Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = th("OFF"), BorderSizePixel = 0,
		}, card)
		corner(icon, 15)
		make("TextLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "E",
			TextColor3 = th("ACCENT"), Font = Enum.Font.GothamBlack, TextSize = 14,
		}, icon)

		make("TextLabel", {
			Position = UDim2.fromOffset(56, 8), Size = UDim2.new(1, -172, 0, 18),
			BackgroundTransparency = 1, Text = string.format("%s [ %s ]", entry.name, entry.income),
			TextColor3 = th("TEXT"), Font = Enum.Font.GothamBold, TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		}, card)
		make("TextLabel", {
			Position = UDim2.fromOffset(56, 28), Size = UDim2.new(1, -172, 0, 14),
			BackgroundTransparency = 1, Text = entry.info, TextColor3 = th("GRAY"),
			Font = Enum.Font.Gotham, TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		}, card)

		local joinBtn = smallButton(card, "JOIN", UDim2.new(1, -62, 0.5, 0), false)
		local copyBtn = smallButton(card, "COPY", UDim2.new(1, -8, 0.5, 0), true)
		joinBtn.Activated:Connect(function()
			toast("JOIN: " .. entry.name)
			local okc, err = pcall(UI.onJoin, entry)
			if not okc then warn("[Senar Hub] onJoin: " .. tostring(err)) end
		end)
		copyBtn.Activated:Connect(function()
			local txt = entry.name .. " " .. entry.income
			if setclipboard then pcall(setclipboard, txt) end
			toast("Disalin: " .. txt)
			local okc, err = pcall(UI.onCopy, entry)
			if not okc then warn("[Senar Hub] onCopy: " .. tostring(err)) end
		end)

		cards[#cards + 1] = card
		if #cards > MAX_CARDS then
			local old = table.remove(cards, 1)
			if old then old:Destroy() end
		end
		return card
	end

	UI.clearLogs = function()
		for _, cd in ipairs(cards) do
			if cd then cd:Destroy() end
		end
		table.clear(cards)
	end

	clearBtn.Activated:Connect(function()
		UI.clearLogs()
		local okc, err = pcall(UI.onClear)
		if not okc then warn("[Senar Hub] onClear: " .. tostring(err)) end
	end)

	local rng = Random.new()
	local function findOne()
		local pool = UI.eggs
		if type(pool) ~= "table" or #pool == 0 then return end
		local e = pool[rng:NextInteger(1, #pool)]
		local name, lo, hi = e[1], e[2], e[3]
		if hi < lo then lo, hi = hi, lo end
		local m = rng:NextInteger(lo, hi)
		local entry = {
			name = name, income = fmtIncome(m), incomeM = m,
			info = string.format("Range %d-%dM · %s", lo, hi, os.date("%H:%M:%S")),
		}
		UI.addLog(entry.name, entry.income, entry.info)
		local okc, err = pcall(UI.onFind, entry)
		if not okc then warn("[Senar Hub] onFind: " .. tostring(err)) end
	end

	task.spawn(function()
		while gui.Parent do
			if finderOn and Gate.unlocked then
				findOne()
				task.wait(rng:NextNumber(3, 9))
			else
				task.wait(0.5)
			end
		end
	end)
end

---------------------------------------------------------------------
-- HALAMAN: SETTINGS (Super Modern + Tema)
---------------------------------------------------------------------
do
	local p = pages.Settings
	sectionLabel(p, "SETTINGS", { Size = UDim2.fromOffset(100, 14) })
	local list = makeList(p, UDim2.new(1, 0, 1, -20), UDim2.fromOffset(0, 20))

	makeSwitchCard(list, "Super Modern Mode", UDim2.new(1, 0, 0, 38), nil, 1, false, setModern)

	sectionLabel(list, "THEME", { Position = UDim2.new(), Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 10 })

	local themeBtns = {}
	for i, e in ipairs(THEMES) do
		local name, tm = e[1], e[2]
		local b = make("TextButton", {
			LayoutOrder = 10 + i, Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = th("PANEL"), BorderSizePixel = 0, Text = "", AutoButtonColor = false,
		}, list)
		corner(b, 8)
		local st = make("UIStroke", {
			Color = T.STROKE, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, b)

		local sw1 = make("Frame", {
			Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = tm.BG, BorderSizePixel = 0,
		}, b)
		corner(sw1, 4)
		make("UIStroke", { Color = Color3.fromRGB(128, 128, 128), Thickness = 1 }, sw1)
		local sw2 = make("Frame", {
			Position = UDim2.fromOffset(24, 9), Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = tm.ACCENT, BorderSizePixel = 0,
		}, b)
		corner(sw2, 4)

		make("TextLabel", {
			Position = UDim2.fromOffset(48, 0), Size = UDim2.new(1, -74, 1, 0),
			BackgroundTransparency = 1, Text = name, TextColor3 = th("TEXT"),
			Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, b)
		local sel = make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(8, 8), BackgroundColor3 = th("ACCENT"),
			BorderSizePixel = 0, Visible = false,
		}, b)
		corner(sel, 4)

		themeBtns[name] = { stroke = st, dot = sel }
		fx(b, b, 0.025)
		b.Activated:Connect(function()
			applyTheme(name)
			local okc, err = pcall(UI.onTheme, name)
			if not okc then warn("[Senar Hub] onTheme: " .. tostring(err)) end
		end)
	end

	onTheme(function()
		for n, e in pairs(themeBtns) do
			local on = (n == currentTheme)
			e.stroke.Color = on and T.ACCENT or T.STROKE
			e.stroke.Thickness = on and 1.5 or 1
			e.dot.Visible = on
		end
	end)
end

---------------------------------------------------------------------
-- HALAMAN: SYSTEM KEY
---------------------------------------------------------------------
do
	local p = pages["System Key"]
	sectionLabel(p, "SYSTEM KEY", { Size = UDim2.fromOffset(100, 14) })

	local box = make("TextBox", {
		Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = th("PANEL"), BorderSizePixel = 0, Text = "",
		PlaceholderText = "Masukkan key...", PlaceholderColor3 = th("GRAY"),
		TextColor3 = th("TEXT"), Font = Enum.Font.Gotham, TextSize = 12,
		ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
	}, p)
	corner(box, 8)
	glowStroke(box, 1)
	make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, box)

	local checkBtn = make("TextButton", {
		Position = UDim2.fromOffset(0, 64), Size = UDim2.new(0.5, -4, 0, 32),
		BackgroundColor3 = th("ACCENT"), BorderSizePixel = 0, Text = "CHECK KEY",
		TextColor3 = th("ONACC"), Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false,
	}, p)
	corner(checkBtn, 8)
	glowStroke(checkBtn, 1, "ACCENT_DK")
	fx(checkBtn, checkBtn, 0.04)

	local getBtn = make("TextButton", {
		Position = UDim2.new(0.5, 4, 0, 64), Size = UDim2.new(0.5, -4, 0, 32),
		BackgroundColor3 = th("PANEL"), BorderSizePixel = 0, Text = "GET KEY",
		TextColor3 = th("TEXT"), Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false,
	}, p)
	corner(getBtn, 8)
	glowStroke(getBtn, 1)
	fx(getBtn, getBtn, 0.04)

	local premBtn = make("TextButton", {
		Position = UDim2.fromOffset(0, 104), Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Color3.fromRGB(88, 101, 242), BorderSizePixel = 0, Text = "PREMIUM KEY",
		TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false,
	}, p)
	corner(premBtn, 8)
	fx(premBtn, premBtn, 0.03)

	-- progress bar
	local track = make("Frame", {
		Position = UDim2.fromOffset(0, 148), Size = UDim2.new(1, 0, 0, 12),
		BackgroundColor3 = th("PANEL"), BorderSizePixel = 0, ClipsDescendants = true,
	}, p)
	corner(track, 6)
	glowStroke(track, 1)
	local fill = make("Frame", {
		Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0,
	}, track)
	corner(fill, 6)
	addSweep(fill, "ACCENT", "FLASH")

	local timeLbl = make("TextLabel", {
		Position = UDim2.fromOffset(2, 164), Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1, Text = "Tekan GET KEY (tunggu 5 menit)", TextColor3 = th("GRAY"),
		Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
	}, p)
	local keyStatus = make("TextLabel", {
		Position = UDim2.fromOffset(2, 186), Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1, Text = "Belum diverifikasi (fitur terkunci)", TextColor3 = th("GRAY"),
		Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
	}, p)

	-- ---- logika key ----
	local function readSaved()
		if not (isfile and readfile) then return nil end
		local ok, s = pcall(function()
			if isfile(KEY_FILE) then return readfile(KEY_FILE) end
		end)
		if ok and type(s) == "string" and s ~= "" then return (s:gsub("%s+", "")) end
		return nil
	end
	env.__SenarFreeKey = env.__SenarFreeKey or readSaved()
	if env.__SenarFreeKey then box.Text = env.__SenarFreeKey end

	local function validateKey(text)
		text = (tostring(text or ""):gsub("%s+", ""))
		if text == "" then return false end
		if PREMIUM_KEYS[text] then return true, "Premium" end
		if env.__SenarFreeKey and text == env.__SenarFreeKey then return true, "Free" end
		return false
	end

	local function genKey()
		local chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
		local function part(n)
			local t = {}
			for i = 1, n do
				local k = math.random(1, #chars)
				t[i] = chars:sub(k, k)
			end
			return table.concat(t)
		end
		return "SENAR-FREE-" .. part(4) .. "-" .. part(4)
	end

	local function fmt(s)
		return string.format("%02d:%02d", math.floor(s / 60), s % 60)
	end

	local waitId, waiting = 0, false
	local function runWait()
		waitId += 1
		local id = waitId
		waiting = true
		getBtn.Text = "TUNGGU..."
		task.spawn(function()
			while id == waitId and gui.Parent do
				local elapsed = os.time() - env.__SenarKeyStart
				local remain = KEY_WAIT - elapsed
				if remain <= 0 then break end
				timeLbl.Text = "Menunggu key...  " .. fmt(remain)
				tween(fill, TweenInfo.new(1, Enum.EasingStyle.Linear),
					{ Size = UDim2.new(math.clamp(elapsed / KEY_WAIT, 0, 1), 0, 1, 0) })
				task.wait(1)
			end
			if id ~= waitId or not gui.Parent then return end

			local key = genKey()
			env.__SenarFreeKey = key
			env.__SenarKeyStart = nil
			if writefile then pcall(writefile, KEY_FILE, key) end
			if setclipboard then pcall(setclipboard, key) end
			tween(fill, TweenInfo.new(0.3), { Size = UDim2.new(1, 0, 1, 0) })
			box.Text = key
			timeLbl.Text = "Key siap! Sudah disalin, tekan CHECK KEY"
			getBtn.Text = "GET KEY"
			waiting = false
			toast("Key kamu sudah jadi")
		end)
	end

	getBtn.Activated:Connect(function()
		if waiting then
			toast("Masih menunggu key...")
			return
		end
		fill.Size = UDim2.new(0, 0, 1, 0)
		env.__SenarKeyStart = os.time()
		keyStatus.Text = "Belum diverifikasi (fitur terkunci)"
		keyStatus.TextColor3 = T.GRAY
		runWait()
	end)

	checkBtn.Activated:Connect(function()
		local ok, tier = validateKey(box.Text)
		if ok then
			keyStatus.Text = "Key valid  [" .. tier .. "] - fitur terbuka"
			keyStatus.TextColor3 = Color3.fromRGB(90, 225, 130)
			toast("Key valid (" .. tier .. ")")
			setUnlocked(true, tier)
		else
			keyStatus.Text = Gate.unlocked and "Key tidak valid (fitur tetap terbuka)" or "Key tidak valid"
			keyStatus.TextColor3 = Color3.fromRGB(255, 95, 95)
			toast("Key tidak valid")
		end
		local c1, e1 = pcall(UI.onKeySubmit, box.Text)
		if not c1 then warn("[Senar Hub] onKeySubmit: " .. tostring(e1)) end
		local c2, e2 = pcall(UI.onKeyResult, ok, tier)
		if not c2 then warn("[Senar Hub] onKeyResult: " .. tostring(e2)) end
	end)

	-- Premium Key -> Discord
	premBtn.Activated:Connect(function()
		local copied = false
		if setclipboard then
			copied = pcall(setclipboard, DISCORD_LINK)
		elseif toclipboard then
			copied = pcall(toclipboard, DISCORD_LINK)
		end
		local req = (syn and syn.request) or (http and http.request) or http_request or request
		local opened = false
		if req then
			local ok, res = pcall(req, {
				Url = "http://127.0.0.1:6463/rpc?v=1",
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json", ["Origin"] = "https://discord.com" },
				Body = HttpService:JSONEncode({
					cmd = "INVITE_BROWSER",
					args = { code = DISCORD_CODE },
					nonce = HttpService:GenerateGUID(false),
				}),
			})
			opened = ok and type(res) == "table" and (res.Success == true or res.StatusCode == 200)
		end
		if opened then
			toast("Membuka Discord...")
		elseif copied then
			toast("Link Discord disalin, tempel di browser")
		else
			toast(DISCORD_LINK)
		end
	end)

	-- lanjutkan hitung mundur kalau script dijalankan ulang
	if env.__SenarKeyStart then runWait() end
end

selectTab("System Key")

-- ---------- Kilatan cahaya ----------
do
	local streak = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(-60, H / 2),
		Size = UDim2.fromOffset(14, H + 120), Rotation = 18,
		BackgroundTransparency = 1, ZIndex = 50,
	}, main)
	make("Frame", {
		Position = UDim2.fromOffset(2, 0), Size = UDim2.fromOffset(3, H + 120),
		BackgroundColor3 = th("FLASH"), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 50,
	}, streak)
	make("Frame", {
		Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(5, H + 120),
		BackgroundColor3 = BLACK, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 50,
	}, streak)

	local tw = TweenService:Create(streak,
		TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 2.5),
		{ Position = UDim2.fromOffset(W + 60, H / 2) })
	tw:Play()
	table.insert(tweens, tw)
end

-- ---------- Resize grip (kanan bawah) ----------
do
	local grip = make("TextButton", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromOffset(W - 3, H - 3),
		Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Text = "",
		AutoButtonColor = false, ZIndex = 55,
	}, main)
	for i = 0, 2 do
		local cc = 21 - i * 6
		make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cc, cc),
			Size = UDim2.fromOffset(4 + i * 6, 2), Rotation = -45,
			BackgroundColor3 = th("TEXT"), BorderSizePixel = 0, ZIndex = 56,
		}, grip)
	end

	local dragging, startMouse, startMul
	table.insert(conns, grip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging, startMouse, startMul = true, input.Position, userMul
		end
	end))
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - startMouse
			userMul = math.clamp(startMul + (d.X + d.Y) / 600, 0.4 / math.max(fitMul, 0.01), 3)
			applyScale()
		end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			toast("Ukuran UI: " .. math.floor(fitScale.Scale * 100) .. "%")
		end
	end))
end

-- ---------- Buka / tutup ----------
local opened = true
local function setOpen(state)
	opened = state
	if state then
		holder.Visible = true
		popScale.Scale = modern and 0.7 or 0.85
		tween(popScale, TweenInfo.new(modern and 0.45 or 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
	else
		tween(popScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = modern and 0.6 or 0.85 })
		task.delay(0.18, function()
			if not opened and holder.Parent then holder.Visible = false end
		end)
	end
end
hideBtn.Activated:Connect(function() setOpen(false) end)

-- ---------- Drag window ----------
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
	Size = UDim2.new(1, -90, 0, 24), BackgroundTransparency = 1, Active = true, ZIndex = 40,
}, main))
attachDrag(make("Frame", {
	Position = UDim2.fromOffset(8, 24), Size = UDim2.fromOffset(124, 54),
	BackgroundTransparency = 1, Active = true, ZIndex = 40,
}, main))

-- ---------- Floating icon ----------
local iconBtn = make("TextButton", {
	Name = "FloatingIcon", Position = UDim2.new(0, 16, 0.5, -26), Size = UDim2.fromOffset(52, 52),
	BackgroundColor3 = th("BG"), BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 60,
}, gui)
corner(iconBtn, 26)
spinStroke(iconBtn, 2)
fx(iconBtn, iconBtn, 0.08)

local iconFallback = make("TextLabel", {
	Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "S",
	TextColor3 = th("ACCENT"), Font = Enum.Font.GothamBlack, TextSize = 24, ZIndex = 61,
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

-- ---------- Animasi utama ----------
do
	local t0 = os.clock()
	local acc, kacc = 0, 0
	table.insert(conns, RunService.Heartbeat:Connect(function(dt)
		local t = os.clock() - t0

		if kaitun then
			kacc += dt
			if kacc >= 1 then
				kacc = 0
				local s = math.floor(os.clock() - kStart)
				kSub.Text = string.format("Uptime %02d:%02d:%02d", s // 3600, (s // 60) % 60, s % 60)
			end
		end

		if not holder.Visible then return end

		local bw = blocks.width
		for _, b in ipairs(blocks) do
			b.frame.Size = UDim2.fromOffset(bw, b.base + math.sin(t * (modern and 3.2 or 2) + b.phase) * (modern and 5 or 3))
		end

		acc += dt
		if acc >= 0.05 then
			acc = 0
			hubGrad.Color = rainbowSeq(t)
		end

		if modern then
			main.Position = UDim2.new(0.5, 0, 0.5, math.sin(t * 1.8) * 3)
			mainStroke.Thickness = 1.5 + (math.sin(t * 3) + 1) * 0.5
			glow1.BackgroundTransparency = 0.72 + math.sin(t * 2.4) * 0.1
			for _, j in ipairs(jets) do
				j.frame.Size = UDim2.fromOffset(10, 24 + math.sin(t * 14 + j.ph) * 5 + math.sin(t * 5) * 3)
			end
			for _, l in ipairs(speedLines) do
				l.x += l.v * dt
				if l.x > W + 10 then
					l.x = -l.w
					l.y = math.random(30, H - 30)
				end
				l.frame.Position = UDim2.fromOffset(l.x, l.y)
			end
		end
	end))
end

-- ---------- Cleanup ----------
gui.Destroying:Connect(function()
	if kaitun then
		kaitun = false
		restoreRender()
	end
	if env.__SenarCleanup == myCleanup then env.__SenarCleanup = nil end
	if env.SenarUI == UI then env.SenarUI = nil end
	table.clear(sweepGradients)
	table.clear(spinGrads)
	for _, cn in ipairs(conns) do cn:Disconnect() end
	for _, tw in ipairs(tweens) do pcall(function() tw:Cancel() end) end
end)

applyTheme(currentTheme)
paintKaitun()

-- ====================================================================
-- FITUR BIKE FOR EGG  (semua baru aktif setelah System Key valid)
-- ====================================================================
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
			Vector3.new(4028.29, 70.88, -399.21),
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

	-- ================= STATE =================
	local S = { alive = true, busy = false, noclip = false, floatOn = false }
	local settings = {
		autosteal = false, autotreadmill = false, autoupgrade = false, autobuybike = false,
		autobring = false, autoopenegg = false, autosellall = false,
		zone = 0, method = 1, forcespeed = 100, tweenspeed = 120,
	}
	local binders = {}
	local function setSetting(k, v)
		if not Gate.unlocked then
			toast("Masukkan System Key dulu")
			return
		end
		settings[k] = v
		if binders[k] then binders[k](v) end
	end
	local function setStatus(t) UI.setStatus(t) end
	local floatPart

	-- ================= UTIL =================
	local function any(s, words)
		for _, w in ipairs(words) do if s:find(w, 1, true) then return true end end
		return false
	end
	local function jitter(t) return t * (0.9 + math.random() * 0.2) end
	local function hrp() local ch = LocalPlayer.Character return ch and ch:FindFirstChild("HumanoidRootPart") end
	local function hum() local ch = LocalPlayer.Character return ch and ch:FindFirstChildOfClass("Humanoid") end
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
		local ch = LocalPlayer.Character
		if not ch then return end
		for _, p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
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
		local ch = LocalPlayer.Character
		if ch then
			for _, d in ipairs(ch:GetChildren()) do
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
		local ch = LocalPlayer.Character
		local h = hrp()
		if not ch or not h then return nil, nil end
		ch.Archivable = true
		local clone = ch:Clone()
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
		if not Gate.unlocked then return end
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
			if Gate.unlocked and settings.autosteal and not S.busy and hrp() then
				runSteal(function() return S.alive and Gate.unlocked and settings.autosteal end)
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
			if Gate.unlocked and settings.autobring and not S.busy and hrp() then
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
			for _, ch in ipairs(node:GetChildren()) do
				if (ch:IsA("StringValue") or ch:IsA("IntValue") or ch:IsA("NumberValue")) and matchVal(ch.Value) then return true end
				if ch:IsA("ObjectValue") and ch.Value == me then return true end
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
			if Gate.unlocked and settings.autotreadmill and not S.busy and hrp() then
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
				for _, cn in ipairs(getconnections(b.MouseButton1Click)) do cn:Fire() end
				for _, cn in ipairs(getconnections(b.Activated)) do cn:Fire() end
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
				if Gate.unlocked and settings[flag] then
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

	-- ================= CONFIG (simpan/muat) =================
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

	-- ================= KOMPONEN UI (tema Senar) =================
	local pMain = makeList(pages.Main, UDim2.fromScale(1, 1))
	local pSet = makeList(pages.Config, UDim2.fromScale(1, 1))
	local order = 0

	local function row(page, text, h)
		order += 1
		local r = make("Frame", {
			Size = UDim2.new(1, 0, 0, h or 36), BackgroundColor3 = th("PANEL"), BorderSizePixel = 0, LayoutOrder = order,
		}, page)
		corner(r, 8)
		glowStroke(r, 1)
		if text then
			make("TextLabel", {
				Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -112, 1, 0), BackgroundTransparency = 1,
				Text = text, TextColor3 = th("TEXT"), Font = Enum.Font.GothamBold, TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			}, r)
		end
		return r
	end

	local function addSwitch(page, text, key)
		local r = row(page, text)
		local track = make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(38, 20), BorderSizePixel = 0,
		}, r)
		corner(track, 10)
		local knob = make("Frame", {
			Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0,
		}, track)
		corner(knob, 7)

		local function paint(v, animate)
			local pos2 = v and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
			local kc = v and T.ONACC or T.TEXT
			local tc = v and T.ACCENT or T.OFF
			if animate then
				tween(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Position = pos2, BackgroundColor3 = kc })
				tween(track, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundColor3 = tc })
			else
				knob.Position = pos2
				knob.BackgroundColor3 = kc
				track.BackgroundColor3 = tc
			end
		end
		binders[key] = function(v)
			paint(v, true)
			activeFeatures[text] = v or nil
			refreshKaitun()
			local okc, err = pcall(UI.onToggle, text, v)
			if not okc then warn("[Senar Hub] onToggle: " .. tostring(err)) end
		end
		onTheme(function() paint(settings[key], false) end)

		local btn = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5 }, r)
		fx(btn, r, 0.025)
		btn.Activated:Connect(function() setSetting(key, not settings[key]) end)
	end

	local function addInput(page, text, key, lo, hi)
		local r = row(page, text)
		local box = make("TextBox", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(78, 24),
			BackgroundColor3 = th("BG"), Text = tostring(settings[key]), TextColor3 = th("TEXT"), Font = Enum.Font.GothamBold,
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
			BackgroundColor3 = th("ACCENT_DK"), BorderSizePixel = 0, Text = btnText, TextColor3 = th("TEXT"),
			Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false,
		}, r)
		corner(b, 6)
		glowStroke(b, 1, "ACCENT")
		fx(b, b, 0.06)
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
			Position = UDim2.fromOffset(6, 5), Size = UDim2.new(1, -12, 1, -10), BackgroundColor3 = th("BG"), Text = "",
			PlaceholderText = placeholder, PlaceholderColor3 = th("GRAY"), TextColor3 = th("TEXT"), Font = Enum.Font.Gotham,
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
			BackgroundColor3 = th("ACCENT_DK"), BorderSizePixel = 0, Text = zoneLabel(settings.zone) .. " ▾",
			TextColor3 = th("TEXT"), Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false,
		}, r)
		corner(btn, 6)
		glowStroke(btn, 1, "ACCENT")
		fx(btn, btn, 0.06)

		order += 1
		local drop = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = th("SIDE"),
			BorderSizePixel = 0, LayoutOrder = order, Visible = false,
		}, page)
		corner(drop, 8)
		glowStroke(drop, 1)
		make("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, drop)
		make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, drop)

		for i = 0, #CFG.ZONES do
			local o = make("TextButton", {
				Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = th("PANEL"), BorderSizePixel = 0, LayoutOrder = i,
				Text = zoneLabel(i), TextColor3 = th("TEXT"), Font = Enum.Font.GothamBold, TextSize = 11, AutoButtonColor = false,
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
		if not Gate.unlocked then toast("Masukkan System Key dulu") return end
		if S.busy then setStatus("masih sibuk") return end
		task.spawn(function()
			runSteal(function() return S.alive and Gate.unlocked end)
		end)
	end)
	addSwitch(pMain, "Auto Steal", "autosteal")
	addSwitch(pMain, "Auto Treadmill (Tween ke treadmill-ku)", "autotreadmill")
	addSwitch(pMain, "Auto Upgrade Treadmill", "autoupgrade")
	addSwitch(pMain, "Auto Buy Bike", "autobuybike")
	addSwitch(pMain, "Auto Bring Egg (grab egg)", "autobring")
	addSwitch(pMain, "Auto Open Egg", "autoopenegg")
	addSwitch(pMain, "Auto Sell All", "autosellall")

	-- ================= ISI TAB CONFIG =================
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
		TextColor3 = th("GRAY"), Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
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

	-- saat key valid: pindah ke Main + muat config Default (sekali)
	local loaded = false
	onUnlock(function(on, tier)
		if not on then
			setStatus("Terkunci: butuh key")
			return
		end
		if not loaded then
			loaded = true
			local t = readCfg("Default")
			if t then applyText(t) end
			if currentTab == "System Key" then selectTab("Main") end
		end
		setStatus("Siap [" .. tostring(tier) .. "] | metode " .. settings.method)
	end)

	gui.Destroying:Connect(function()
		S.alive = false
		if floatPart then pcall(function() floatPart:Destroy() end) end
	end)
end)
if not okBike then
	warn("[Senar Hub] ERROR: " .. tostring(errBike))
	UI.setStatus("ERR: " .. tostring(errBike):sub(1, 60))
end

-- ====== TARUH KODE PROJECT KAMU DI BAWAH SINI ======
