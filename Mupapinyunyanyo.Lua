-- SENAR HUB | UI v3 + Bike for Egg + Farming Rarity
-- Layout: Title bar | Sidebar (Menu) | Panel Fitur | Panel Pengaturan (beda tiap tab)
-- + Default / Recommended per tab   + Background gambar (samar)
-- + 23 Tema (tab Tema)              + Super Modern Mode (tab Tema)
-- + Mode Kaitun (ikon di title bar) + Resize (pegangan kanan bawah)
-- + System Key (Check / Get 5 menit / Premium)
-- + SEMUA FITUR TERKUNCI sampai key valid (tab System Key -> CHECK KEY)
--
-- Hook untuk project (taruh kodemu di paling bawah):
--   local UI = getgenv().SenarUI
--   UI.onToggle    = function(name, state, tab) end
--   UI.onSlider    = function(name, value, tab) end
--   UI.onDropdown  = function(name, option, tab) end
--   UI.onInput     = function(tab, text) end
--   UI.onPreset    = function(tab, mode) end        -- "default" / "recommended"
--   UI.onJoin      = function(entry) end
--   UI.onCopy      = function(entry) end
--   UI.onClear     = function(tab) end
--   UI.onKeySubmit = function(text) end
--   UI.onKeyResult = function(valid, tier) end      -- tier: "Premium" / "Free"
--   UI.onKaitun    = function(state) end
--   UI.onTheme     = function(name) end
--   UI.addLog(name, income, info)   UI.clearLogs()
--   UI.addHistory(text)             UI.clearHistory()
--   UI.setStatus("Connected")       UI.setKeyStatus("Valid")
--   UI.setTheme("Dracula")          UI.destroy()
--   UI.getSetting(tab, name)        UI.setSetting(tab, name, value)
--   UI.getFeature(tab, name)        --> { enabled = bool, value = option/angka }
--   UI.isUnlocked()                 --> true kalau key sudah valid

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
local BG_ASSET_ID     = 15893685449      -- gambar background (opasitas diatur di tab Tema)
local DISCORD_LINK    = "https://discord.gg/6VeEjrRYy"
local DISCORD_CODE    = "6VeEjrRYy"
local PREMIUM_KEYS    = { ["SENAR-PREMIUM-KEY"] = true }
local KEY_WAIT        = 300 -- detik (5 menit)
local KEY_FILE        = "SenarHub_Key.txt"

local ZONE_COUNT   = 10
local RARITY_LIST  = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Eternal", "Divine", "Random" }

local W, H = 640, 350            -- ukuran window
local PH = 300                   -- tinggi area konten
local CW, SW = 318, 166          -- lebar panel tengah / panel pengaturan
local PAGE_W = CW + 8 + SW

-- ================= CLEANUP =================
local env = (getgenv and getgenv()) or _G
if env.__SenarCleanup then pcall(env.__SenarCleanup) end

-- ================= API PUBLIK =================
local UI = {
	onToggle = function(name, state, tab) end,
	onSlider = function(name, value, tab) end,
	onDropdown = function(name, option, tab) end,
	onInput = function(tab, text) end,
	onPreset = function(tab, mode) end,
	onJoin = function(entry) end,
	onCopy = function(entry) end,
	onClear = function(tab) end,
	onKeySubmit = function(text) end,
	onKeyResult = function(valid, tier) end,
	onKaitun = function(state) end,
	onTheme = function(name) end,
	addLog = function() end,
	clearLogs = function() end,
	addHistory = function() end,
	clearHistory = function() end,
	setStatus = function() end,
	setKeyStatus = function() end,
	setTheme = function() end,
	getSetting = function() end,
	setSetting = function() end,
	getFeature = function() end,
	isUnlocked = function() return false end,
	destroy = function() end,
}
env.SenarUI = UI

local function fire(name, ...)
	local fn = UI[name]
	if type(fn) == "function" then
		local ok, err = pcall(fn, ...)
		if not ok then warn("[Senar Hub] " .. name .. ": " .. tostring(err)) end
	end
end

-- status kunci fitur (true setelah key valid)
local unlocked = false
UI.isUnlocked = function() return unlocked end
local actions = {}   -- aksi tombol di tab Fitur (diisi oleh blok Bike for Egg)
local badges = {}    -- label "TERKUNCI / KEY AKTIF"

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

local function label(parent, props)
	local d = {
		BackgroundTransparency = 1, TextColor3 = th("TEXT"),
		Font = Enum.Font.GothamBold, TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
	}
	for k, v in pairs(props) do d[k] = v end
	return make("TextLabel", d, parent)
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

-- kecepatan tween (diatur dari setting "Kecepatan Tween")
local tweenSpeed = 15
local function dur(base)
	return math.clamp(base * 15 / tweenSpeed, 0.03, 0.8)
end

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

-- panel yang transparansinya bisa diatur
local panels = {}
local function regPanel(frame, base)
	table.insert(panels, { f = frame, base = base })
	frame.BackgroundTransparency = base
end
local function applyAlpha(a)
	for _, p in ipairs(panels) do
		if p.f.Parent then
			p.f.BackgroundTransparency = math.clamp(p.base + a, 0, 1)
		end
	end
end

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

-- skala = fit layar * resize grip * setting "Skala UI" * maximize
local fitMul, gripMul, setMul, zoomMul = 1, 1, 1, 1
local function maxTotal()
	local cam = workspace.CurrentCamera
	if not cam then return 1.5 end
	local vp = cam.ViewportSize
	return math.min(vp.X / (W + 10), vp.Y / (H + 10), 1.8)
end
local function applyScale()
	fitScale.Scale = math.clamp(fitMul * gripMul * setMul * zoomMul, 0.4, math.max(0.4, maxTotal()))
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

-- ---------- Gambar background (samar) ----------
local bgImg = make("ImageLabel", {
	Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
	Image = "rbxassetid://" .. tostring(BG_ASSET_ID),
	ImageTransparency = 0.82, ScaleType = Enum.ScaleType.Crop, BorderSizePixel = 0,
}, main)
corner(bgImg, 12)

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
			AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, x, 1, 0),
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
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(W / 2, H + 30),
	Size = UDim2.fromOffset(260, 24), BackgroundColor3 = th("PANEL"), BorderSizePixel = 0,
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
	toastLbl.Position = UDim2.fromOffset(W / 2, H + 30)
	toastLbl.Visible = true
	tween(toastLbl, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.fromOffset(W / 2, H - 8) })
	task.delay(2.4, function()
		if id ~= toastId or not toastLbl.Parent then return end
		tween(toastLbl, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Position = UDim2.fromOffset(W / 2, H + 30) })
		task.delay(0.28, function()
			if id == toastId and toastLbl.Parent then toastLbl.Visible = false end
		end)
	end)
end

-- ---------- Super Modern ----------
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

-- ================= SIDEBAR =================
local tabNames = { "Fitur", "Logs", "History", "Tema", "System Key" }

local side = make("Frame", {
	Position = UDim2.fromOffset(8, 30), Size = UDim2.fromOffset(124, PH),
	BackgroundColor3 = th("SIDE"), BorderSizePixel = 0,
}, main)
regPanel(side, 0.25)
corner(side, 10)
glowStroke(side, 1)

label(side, {
	Position = UDim2.fromOffset(14, 9), Size = UDim2.fromOffset(60, 14),
	Text = "MENU", TextColor3 = th("GRAY"), TextSize = 10,
})

local dot = make("Frame", {
	AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -34), Size = UDim2.fromOffset(6, 6),
	BackgroundColor3 = th("ACCENT"), BorderSizePixel = 0,
}, side)
corner(dot, 3)
local statusLbl = label(side, {
	AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 26, 1, -28), Size = UDim2.new(1, -32, 0, 18),
	Text = "Terkunci", TextColor3 = th("GRAY"), Font = Enum.Font.Gotham,
	TextTruncate = Enum.TextTruncate.AtEnd,
})
UI.setStatus = function(t) statusLbl.Text = tostring(t) end

label(side, {
	AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -10), Size = UDim2.new(1, -20, 0, 14),
	Text = "Senar Hub v3", TextColor3 = th("STROKE"), Font = Enum.Font.Gotham, TextSize = 9,
})

-- ================= KONTEN & HALAMAN =================
local content = make("Frame", {
	Position = UDim2.fromOffset(140, 30), Size = UDim2.fromOffset(PAGE_W, PH),
	BackgroundTransparency = 1,
}, main)

local pages, tabBtns = {}, {}
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
		t.accent.Visible = on
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
		Position = UDim2.fromOffset(62, 45 + (i - 1) * 36), Size = UDim2.fromOffset(108, 30),
		BackgroundColor3 = th("HOVER"), BackgroundTransparency = 1, BorderSizePixel = 0,
		Text = name, TextColor3 = th("GRAY"), Font = Enum.Font.GothamBold, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
	}, side)
	corner(b, 8)
	make("UIPadding", { PaddingLeft = UDim.new(0, 16) }, b)
	local st = glowStroke(b, 1)
	st.Enabled = false
	local accent = make("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -10, 0.5, 0), Size = UDim2.fromOffset(3, 16),
		BackgroundColor3 = th("ACCENT"), BorderSizePixel = 0, Visible = false,
	}, b)
	corner(accent, 2)
	tabBtns[name] = { btn = b, stroke = st, accent = accent }
	fx(b, b, 0.05)
	b.Activated:Connect(function() selectTab(name) end)
end
onTheme(refreshTabs)

-- ================= KAITUN =================
local activeFeatures = {}
local kStart = os.clock()

local kBtn = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -96, 0, 3), Size = UDim2.fromOffset(22, 22),
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
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -122, 0, 6), Size = UDim2.fromOffset(80, 16),
	BackgroundTransparency = 1, Text = "KAITUN ON", TextColor3 = th("ACCENT"),
	Font = Enum.Font.GothamBold, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Right,
	Visible = false, ZIndex = 55,
}, main)
fx(kBtn, kBtn, 0.12)

local function kaitunUnlocked() return next(activeFeatures) ~= nil end

local function paintKaitun()
	local ul = kaitunUnlocked()
	kImg.ImageTransparency = (ul or kaitun) and 0 or 0.6
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
	fire("onKaitun", state)
	toast(state and "Kaitun Mode ON" or "Kaitun Mode OFF")
end

local function refreshKaitun()
	if kaitun and not kaitunUnlocked() then
		setKaitun(false)
	end
	paintKaitun()
end

kBtn.Activated:Connect(function() setKaitun(not kaitun) end)

-- ================= KOMPONEN =================

-- toggle switch (ikut tema). props.gated = terkunci sampai key valid
local function makeToggle(parent, props, onChange)
	local track = make("TextButton", {
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0.5), Position = props.Position,
		Size = UDim2.fromOffset(38, 20), BorderSizePixel = 0, Text = "", AutoButtonColor = false,
	}, parent)
	corner(track, 10)
	local knob = make("Frame", {
		Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0,
	}, track)
	corner(knob, 7)

	local state = false
	local function paint(animate)
		local pos2 = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
		local kc = state and T.ONACC or T.TEXT
		local tc = state and T.ACCENT or T.OFF
		if animate then
			tween(knob, TweenInfo.new(dur(modern and 0.3 or 0.18),
				modern and Enum.EasingStyle.Back or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = pos2, BackgroundColor3 = kc })
			tween(track, TweenInfo.new(dur(0.18), Enum.EasingStyle.Quad), { BackgroundColor3 = tc })
		else
			knob.Position = pos2
			knob.BackgroundColor3 = kc
			track.BackgroundColor3 = tc
		end
	end
	onTheme(function() paint(false) end)

	local obj = {}
	function obj.get() return state end
	function obj.set(s, silent, instant)
		s = not not s
		if s == state then return end
		state = s
		paint(not instant)
		if not silent and onChange then onChange(s) end
	end
	track.Activated:Connect(function()
		if props.gated and not unlocked and not state then
			toast("Terkunci! Verifikasi key di tab System Key")
			return
		end
		obj.set(not state)
	end)
	return obj
end

local function stepBtn(parent, text, anchor, pos)
	local b = make("TextButton", {
		AnchorPoint = anchor, Position = pos, Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = th("HOVER"), BorderSizePixel = 0, Text = text, TextColor3 = th("TEXT"),
		Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false,
	}, parent)
	corner(b, 5)
	return b
end

-- slider (opsional tombol - / +)
local function makeSlider(parent, o)
	local holderS = make("Frame", {
		AnchorPoint = o.AnchorPoint or Vector2.new(0, 0), Position = o.Position,
		Size = o.Size, BackgroundTransparency = 1,
	}, parent)

	local left, right = 0, 0
	local minus, plus
	if o.buttons then
		minus = stepBtn(holderS, "-", Vector2.new(0, 0.5), UDim2.new(0, 0, 0.5, 0))
		plus = stepBtn(holderS, "+", Vector2.new(1, 0.5), UDim2.new(1, 0, 0.5, 0))
		left, right = 24, 24
	end

	local hit = make("TextButton", {
		Position = UDim2.fromOffset(left, 0), Size = UDim2.new(1, -(left + right), 1, 0),
		BackgroundTransparency = 1, Text = "",
	}, holderS)
	local track = make("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = th("OFF"), BorderSizePixel = 0,
	}, hit)
	corner(track, 2)
	local fill = make("Frame", {
		Size = UDim2.fromScale(0, 1), BackgroundColor3 = th("ACCENT"), BorderSizePixel = 0,
	}, track)
	corner(fill, 2)
	local knob = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(12, 12), BackgroundColor3 = th("TEXT"), BorderSizePixel = 0, ZIndex = 2,
	}, track)
	corner(knob, 6)

	local step = o.step or 1
	local function snap(v)
		v = math.clamp(v, o.min, o.max)
		v = o.min + math.floor((v - o.min) / step + 0.5) * step
		return math.clamp(v, o.min, o.max)
	end

	local value = snap(o.value or o.min)
	local function render()
		local f = (value - o.min) / (o.max - o.min)
		fill.Size = UDim2.fromScale(f, 1)
		knob.Position = UDim2.fromScale(f, 0.5)
		if o.onVisual then o.onVisual(value) end
	end
	render()

	local obj = {}
	function obj.get() return value end
	function obj.set(v, silent)
		v = snap(v)
		if math.abs(v - value) < 1e-6 then return end
		value = v
		render()
		if not silent and o.onChange then o.onChange(value) end
	end

	local dragging = false
	local function fromInput(input)
		local w = track.AbsoluteSize.X
		if w <= 0 then return end
		local f = math.clamp((input.Position.X - track.AbsolutePosition.X) / w, 0, 1)
		obj.set(o.min + f * (o.max - o.min))
	end
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			fromInput(input)
		end
	end)
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			fromInput(input)
		end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
		end
	end))

	if minus then minus.Activated:Connect(function() obj.set(value - step) end) end
	if plus then plus.Activated:Connect(function() obj.set(value + step) end) end
	return obj
end

-- list scroll
local function makeList(parent, size, pos, plain)
	local s = make("ScrollingFrame", {
		Size = size, Position = pos or UDim2.new(),
		BackgroundColor3 = th("SIDE"), BackgroundTransparency = plain and 1 or 0.25, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = th("ACCENT"),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, parent)
	if not plain then
		corner(s, 8)
		glowStroke(s, 1)
	end
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, s)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 8),
	}, s)
	return s
end

local function smallButton(parent, text, pos, dim)
	local b = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = pos, Size = UDim2.fromOffset(44, 22),
		BackgroundColor3 = dim and th("HOVER") or th("PANEL"), BorderSizePixel = 0,
		Text = text, TextColor3 = dim and th("GRAY") or th("TEXT"),
		Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false,
	}, parent)
	corner(b, 6)
	glowStroke(b, 1)
	fx(b, b, 0.08)
	return b
end

local GREEN = Color3.fromRGB(90, 225, 130)
local REDC = Color3.fromRGB(255, 95, 95)
local function paintBadge(l)
	l.Text = unlocked and "KEY AKTIF" or "TERKUNCI"
	l.TextColor3 = unlocked and GREEN or REDC
end

-- panel tengah (judul + garis + badge kunci opsional)
local function makeCenter(page, title, badge)
	local f = make("Frame", {
		Size = UDim2.fromOffset(CW, PH), BorderSizePixel = 0, BackgroundColor3 = th("SIDE"),
	}, page)
	regPanel(f, 0.25)
	corner(f, 10)
	glowStroke(f, 1)
	label(f, { Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 16), Text = title, TextSize = 12 })
	if badge then
		local bl = label(f, {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 9), Size = UDim2.fromOffset(110, 14),
			Text = "", TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right,
		})
		table.insert(badges, bl)
		paintBadge(bl)
	end
	make("Frame", {
		Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 0, 1),
		BackgroundColor3 = th("STROKE"), BorderSizePixel = 0,
	}, f)
	return f
end

local function makeClearBtn(parent, y)
	return make("TextButton", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, y), Size = UDim2.fromOffset(44, 16),
		BackgroundTransparency = 1, Text = "Clear", TextColor3 = th("ACCENT2"),
		Font = Enum.Font.GothamBold, TextSize = 10,
	}, parent)
end

-- ================= REGISTRY TAB / SETTING =================
local tabs = {}
for _, n in ipairs(tabNames) do tabs[n] = { settings = {}, features = {}, toggles = {} } end

UI.getSetting = function(tab, name)
	local t = tabs[tab]
	local s = t and t.settings[name]
	if s then return s.ctl.get() end
	return nil
end
UI.setSetting = function(tab, name, value)
	local t = tabs[tab]
	local s = t and t.settings[name]
	if s then s.ctl.set(value) end
end
UI.getFeature = function(tab, name)
	local t = tabs[tab]
	local f = t and t.features[name]
	return f and f() or nil
end

-- buka / kunci semua fitur
local function setUnlocked(state)
	state = not not state
	unlocked = state
	for _, l in ipairs(badges) do
		if l.Parent then paintBadge(l) end
	end
	if not state then
		for _, t in pairs(tabs) do
			for _, tg in pairs(t.toggles) do tg.set(false) end
		end
		UI.setStatus("Terkunci")
	else
		UI.setStatus("Key aktif")
	end
end

-- efek internal dari beberapa setting (sisanya lewat hook UI.onXxx)
local streakFrame
local effects = {
	["Fitur/Kecepatan Tween"] = function(v) tweenSpeed = v end,
	["Fitur/Transparansi"] = function(v) applyAlpha(v / 100) end,
	["Fitur/Skala UI"] = function(v) setMul = v / 100; applyScale() end,
	["Tema/Super Modern Mode"] = function(s) setModern(s) end,
	["Tema/Efek Kilatan"] = function(s) if streakFrame then streakFrame.Visible = s end end,
	["Tema/Efek Balok"] = function(s)
		for _, b in ipairs(blocks) do b.frame.Visible = s end
	end,
	["Tema/Opasitas Background"] = function(v) bgImg.ImageTransparency = 1 - v / 100 end,
}

-- definisi pengaturan tiap tab (beda-beda)
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local SETTINGS = {
	["Fitur"] = {
		{ type = "slider", name = "Metode Farming", min = 1, max = 3, step = 1, default = 1, recommended = 1, labels = { "TP", "Paksa", "Instant" } },
		{ type = "slider", name = "Speed Gerak Paksa", min = 10, max = 500, step = 10, default = 100, recommended = 100 },
		{ type = "slider", name = "Tween Speed", min = 10, max = 500, step = 10, default = 120, recommended = 120 },
		{ type = "slider", name = "Kecepatan Tween", min = 1, max = 30, step = 1, default = 15, recommended = 20 },
		{ type = "slider", name = "Transparansi", min = 0, max = 60, step = 5, default = 0, recommended = 10, unit = "%" },
		{ type = "slider", name = "Skala UI", min = 70, max = 130, step = 5, default = 100, recommended = isMobile and 85 or 100, unit = "%" },
		{ type = "toggle", name = "Notifikasi", default = false, recommended = true },
		{ type = "toggle", name = "Auto Hide", default = false, recommended = false },
	},
	["Logs"] = {
		{ type = "slider", name = "Maks Feed", min = 5, max = 50, step = 5, default = 20, recommended = 30 },
		{ type = "slider", name = "Delay Join", min = 0, max = 10, step = 0.5, default = 0, recommended = 1.5, unit = "s" },
		{ type = "toggle", name = "Notifikasi", default = false, recommended = true },
		{ type = "toggle", name = "Suara", default = false, recommended = false },
	},
	["History"] = {
		{ type = "slider", name = "Batas Riwayat", min = 10, max = 100, step = 10, default = 50, recommended = 30 },
		{ type = "toggle", name = "Simpan Otomatis", default = false, recommended = true },
		{ type = "toggle", name = "Tampilkan Waktu", default = true, recommended = true },
	},
	["Tema"] = {
		{ type = "slider", name = "Opasitas Background", min = 0, max = 40, step = 2, default = 18, recommended = 14, unit = "%" },
		{ type = "toggle", name = "Super Modern Mode", default = false, recommended = false },
		{ type = "toggle", name = "Efek Kilatan", default = true, recommended = true },
		{ type = "toggle", name = "Efek Balok", default = true, recommended = true },
	},
	["System Key"] = {
		{ type = "toggle", name = "Ingat Key", default = true, recommended = true },
		{ type = "toggle", name = "Salin Otomatis", default = true, recommended = true },
		{ type = "toggle", name = "Auto Check", default = false, recommended = true },
	},
}

local function fmtValue(d, v)
	if d.labels then
		return d.labels[math.floor(v + 0.5)] or tostring(v)
	end
	local s
	if (d.step or 1) < 1 then
		s = string.format("%.1f", v)
	else
		s = tostring(math.floor(v + 0.5))
	end
	return s .. (d.unit or "")
end

-- panel pengaturan (kanan) + tombol Default / Recommended
local function buildSettingsPanel(tabName, page)
	local tab = tabs[tabName]
	local defs = SETTINGS[tabName] or {}

	local panel = make("Frame", {
		Position = UDim2.fromOffset(CW + 8, 0), Size = UDim2.fromOffset(SW, PH),
		BorderSizePixel = 0, BackgroundColor3 = th("SIDE"),
	}, page)
	regPanel(panel, 0.25)
	corner(panel, 10)
	glowStroke(panel, 1)

	label(panel, { Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 16), Text = "Pengaturan", TextSize = 12 })
	make("Frame", {
		Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 0, 1),
		BackgroundColor3 = th("STROKE"), BorderSizePixel = 0,
	}, panel)

	local list = makeList(panel, UDim2.new(1, -8, 1, -72), UDim2.fromOffset(4, 32), true)

	for i, d in ipairs(defs) do
		local key = tabName .. "/" .. d.name
		if d.type == "slider" then
			local item = make("Frame", {
				LayoutOrder = i, Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1,
			}, list)
			label(item, { Size = UDim2.new(1, -46, 0, 16), Text = d.name, TextTruncate = Enum.TextTruncate.AtEnd })
			local val = label(item, {
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.fromOffset(46, 16), TextColor3 = th("ACCENT2"), TextXAlignment = Enum.TextXAlignment.Right,
			})
			local sl = makeSlider(item, {
				Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 20), buttons = true,
				min = d.min, max = d.max, step = d.step, value = d.default,
				onVisual = function(v) val.Text = fmtValue(d, v) end,
				onChange = function(v)
					local eff = effects[key]
					if eff then pcall(eff, v) end
					fire("onSlider", d.name, v, tabName)
				end,
			})
			tab.settings[d.name] = { ctl = sl, default = d.default, recommended = d.recommended }
		else
			local item = make("Frame", {
				LayoutOrder = i, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
			}, list)
			label(item, { Size = UDim2.new(1, -46, 1, 0), Text = d.name, TextTruncate = Enum.TextTruncate.AtEnd })
			local tg = makeToggle(item, {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
			}, function(s)
				local eff = effects[key]
				if eff then pcall(eff, s) end
				fire("onToggle", d.name, s, tabName)
			end)
			if d.default then tg.set(true, true, true) end
			tab.settings[d.name] = { ctl = tg, default = d.default, recommended = d.recommended }
		end
	end

	local function applyPreset(mode)
		for _, s in pairs(tab.settings) do
			s.ctl.set(mode == "default" and s.default or s.recommended)
		end
		fire("onPreset", tabName, mode)
	end

	local function presetBtn(text, pos, mode)
		local isRec = mode == "recommended"
		local b = make("TextButton", {
			AnchorPoint = Vector2.new(0, 1), Position = pos, Size = UDim2.fromOffset(72, 26),
			BackgroundColor3 = isRec and th("ACCENT") or th("PANEL"), BorderSizePixel = 0,
			Text = text, TextColor3 = isRec and th("ONACC") or th("TEXT"),
			Font = Enum.Font.GothamBold, TextSize = 9, AutoButtonColor = false,
		}, panel)
		corner(b, 7)
		glowStroke(b, 1, isRec and "ACCENT_DK" or nil)
		fx(b, b, 0.05)
		b.Activated:Connect(function()
			applyPreset(mode)
			b.Text = "OK!"
			task.delay(0.8, function()
				if b.Parent then b.Text = text end
			end)
		end)
	end
	presetBtn("Default", UDim2.new(0, 8, 1, -8), "default")
	presetBtn("Recommended", UDim2.new(0, 86, 1, -8), "recommended")
end

---------------------------------------------------------------------
-- TAB: FITUR  (Bike for Egg + Farming Rarity)
---------------------------------------------------------------------
do
	local tabName = "Fitur"
	local tab = tabs[tabName]
	local p = pages[tabName]
	local f = makeCenter(p, "Features", true)
	local list = makeList(f, UDim2.new(1, -12, 1, -82), UDim2.fromOffset(6, 34), true)

	local function makeFeatureRow(def, order)
		local ROW_H = 38

		-- baris tombol aksi (tanpa toggle)
		if def.kind == "button" then
			local row = make("Frame", {
				LayoutOrder = order, Size = UDim2.new(1, 0, 0, ROW_H),
				BackgroundColor3 = th("PANEL"), BorderSizePixel = 0,
			}, list)
			corner(row, 8)
			glowStroke(row, 1)
			label(row, {
				Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -86, 1, 0),
				Text = def.name, TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local b = smallButton(row, def.button or "RUN", UDim2.new(1, -8, 0.5, 0), false)
			b.Size = UDim2.fromOffset(60, 22)
			b.Activated:Connect(function()
				if not unlocked then
					toast("Terkunci! Verifikasi key di tab System Key")
					return
				end
				local fn = actions[def.name]
				if fn then task.spawn(fn) else toast("Aksi belum siap") end
			end)
			return
		end

		local row = make("Frame", {
			LayoutOrder = order, Size = UDim2.new(1, 0, 0, ROW_H),
			BackgroundColor3 = th("PANEL"), BorderSizePixel = 0, ClipsDescendants = true,
		}, list)
		corner(row, 8)
		glowStroke(row, 1)

		local rightW = 0
		if def.kind == "dropdown" then rightW = 116 elseif def.kind == "slider" then rightW = 104 end

		local tg = makeToggle(row, { Position = UDim2.fromOffset(10, ROW_H / 2), gated = true }, function(s)
			activeFeatures[tabName .. "/" .. def.name] = s or nil
			refreshKaitun()
			fire("onToggle", def.name, s, tabName)
		end)
		tab.toggles[def.name] = tg
		label(row, {
			Position = UDim2.fromOffset(56, 0), Size = UDim2.new(1, -(56 + rightW + 8), 0, ROW_H),
			Text = def.name, TextTruncate = Enum.TextTruncate.AtEnd,
		})

		local getValue = function() return nil end

		if def.kind == "dropdown" then
			local opts = def.options
			local selected = opts[1]
			local open = false
			local fullH = ROW_H + 4 + #opts * 26

			local btn = make("TextButton", {
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 6), Size = UDim2.fromOffset(108, 26),
				BackgroundColor3 = th("HOVER"), BorderSizePixel = 0, Text = "", AutoButtonColor = false,
			}, row)
			corner(btn, 6)
			glowStroke(btn, 1)
			local txt = label(btn, {
				Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -26, 1, 0), Text = selected,
				Font = Enum.Font.Gotham, TextTruncate = Enum.TextTruncate.AtEnd,
			})
			local arrow = label(btn, {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(14, 14),
				Text = "v", TextColor3 = th("GRAY"), TextSize = 10, TextXAlignment = Enum.TextXAlignment.Center,
			})

			local function setOpen(s)
				open = s
				arrow.Rotation = s and 180 or 0
				tween(row, TweenInfo.new(dur(0.18), Enum.EasingStyle.Quad), {
					Size = UDim2.new(1, 0, 0, s and fullH or ROW_H),
				})
			end

			for i, o in ipairs(opts) do
				local ob = make("TextButton", {
					Position = UDim2.fromOffset(8, ROW_H + 2 + (i - 1) * 26), Size = UDim2.new(1, -16, 0, 24),
					BackgroundColor3 = th("HOVER"), BorderSizePixel = 0, Text = o, TextColor3 = th("TEXT"),
					Font = Enum.Font.Gotham, TextSize = 11, AutoButtonColor = false,
				}, row)
				corner(ob, 6)
				ob.Activated:Connect(function()
					selected = o
					txt.Text = o
					setOpen(false)
					fire("onDropdown", def.name, o, tabName)
				end)
			end
			btn.Activated:Connect(function() setOpen(not open) end)
			getValue = function() return selected end

		elseif def.kind == "slider" then
			local sl = makeSlider(row, {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(92, 20),
				min = def.min, max = def.max, step = def.step or 1, value = def.value or def.min,
				onChange = function(v) fire("onSlider", def.name, v, tabName) end,
			})
			getValue = sl.get
		end

		tab.features[def.name] = function()
			return { enabled = tg.get(), value = getValue() }
		end
	end

	local zoneOpts = { "Auto" }
	for i = 1, ZONE_COUNT do zoneOpts[#zoneOpts + 1] = "Zone " .. i end

	local featureDefs = {
		{ name = "Auto Steal", kind = "dropdown", options = zoneOpts },
		{ name = "Farming Rarity", kind = "dropdown", options = RARITY_LIST },
		{ name = "Auto Bring Egg" },
		{ name = "Auto Treadmill" },
		{ name = "Auto Upgrade Treadmill" },
		{ name = "Auto Buy Bike" },
		{ name = "Auto Open Egg" },
		{ name = "Auto Sell All" },
		{ name = "Steal Sekarang", kind = "button", button = "STEAL" },
		{ name = "Dump Egg Rarity", kind = "button", button = "DUMP" },
	}
	for i, d in ipairs(featureDefs) do makeFeatureRow(d, i) end

	local box = make("TextBox", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -10), Size = UDim2.new(1, -24, 0, 32),
		BackgroundColor3 = th("PANEL"), BorderSizePixel = 0, Text = "",
		PlaceholderText = "Enter feature details...", PlaceholderColor3 = th("GRAY"),
		TextColor3 = th("TEXT"), Font = Enum.Font.Gotham, TextSize = 12,
		ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
	}, f)
	corner(box, 8)
	glowStroke(box, 1)
	make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, box)
	box.FocusLost:Connect(function(enter)
		if enter then fire("onInput", tabName, box.Text) end
	end)
end

---------------------------------------------------------------------
-- TAB: LOGS
---------------------------------------------------------------------
do
	local tabName = "Logs"
	local tab = tabs[tabName]
	local p = pages[tabName]
	local f = makeCenter(p, "Logs", true)

	local function miniSwitch(name, pos)
		local card = make("Frame", {
			Position = pos, Size = UDim2.new(0.5, -13, 0, 32),
			BackgroundColor3 = th("PANEL"), BorderSizePixel = 0,
		}, f)
		corner(card, 8)
		glowStroke(card, 1)
		label(card, { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -56, 1, 0), Text = name })
		local tg = makeToggle(card, {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), gated = true,
		}, function(s)
			activeFeatures[tabName .. "/" .. name] = s or nil
			refreshKaitun()
			fire("onToggle", name, s, tabName)
		end)
		tab.toggles[name] = tg
		tab.features[name] = function() return { enabled = tg.get() } end
	end
	miniSwitch("Auto-Join", UDim2.new(0, 10, 0, 36))
	miniSwitch("Auto-Force", UDim2.new(0.5, 3, 0, 36))

	label(f, {
		Position = UDim2.fromOffset(12, 76), Size = UDim2.fromOffset(100, 14),
		Text = "LIVE FEED", TextColor3 = th("GRAY"), TextSize = 10,
	})
	local clearBtn = makeClearBtn(f, 75)

	local list = makeList(f, UDim2.new(1, -12, 1, -100), UDim2.fromOffset(6, 94), false)

	local feed = {}
	local counter = 0
	local maxFeed = 20
	local function trimFeed()
		while #feed > maxFeed do
			local old = table.remove(feed, 1)
			if old and old.Parent then old:Destroy() end
		end
	end
	effects["Logs/Maks Feed"] = function(v) maxFeed = v; trimFeed() end

	UI.addLog = function(name, income, info)
		counter += 1
		local entry = {
			name = tostring(name or "Item Name"),
			income = tostring(income or "$0.0B/s"),
			info = tostring(info or "0/5 · Rarity · 0:00"),
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
			Position = UDim2.fromOffset(16, 13), Size = UDim2.fromOffset(26, 26),
			BackgroundColor3 = th("OFF"), BorderSizePixel = 0,
		}, card)
		corner(icon, 13)

		label(card, {
			Position = UDim2.fromOffset(48, 8), Size = UDim2.new(1, -152, 0, 18),
			Text = string.format("%s [ %s ]", entry.name, entry.income),
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		label(card, {
			Position = UDim2.fromOffset(48, 28), Size = UDim2.new(1, -152, 0, 14),
			Text = entry.info, TextColor3 = th("GRAY"), Font = Enum.Font.Gotham, TextSize = 10,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		local joinBtn = smallButton(card, "JOIN", UDim2.new(1, -56, 0.5, 0), false)
		local copyBtn = smallButton(card, "COPY", UDim2.new(1, -8, 0.5, 0), true)
		joinBtn.Activated:Connect(function() fire("onJoin", entry) end)
		copyBtn.Activated:Connect(function() fire("onCopy", entry) end)

		table.insert(feed, card)
		trimFeed()
		return card
	end

	UI.clearLogs = function()
		for _, cd in ipairs(feed) do
			if cd.Parent then cd:Destroy() end
		end
		table.clear(feed)
	end

	clearBtn.Activated:Connect(function()
		UI.clearLogs()
		fire("onClear", tabName)
	end)

	for i = 1, 3 do
		UI.addLog("Item Name " .. i, "$0.0B/s", "0/5 · Rarity · 0:0" .. i)
	end
end

---------------------------------------------------------------------
-- TAB: HISTORY
---------------------------------------------------------------------
do
	local tabName = "History"
	local p = pages[tabName]
	local f = makeCenter(p, "History")
	local clearBtn = makeClearBtn(f, 7)
	local list = makeList(f, UDim2.new(1, -12, 1, -40), UDim2.fromOffset(6, 34), true)

	local empty = label(list, {
		Size = UDim2.new(1, 0, 0, 30), Text = "Belum ada riwayat", TextColor3 = th("GRAY"),
		Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
	})

	local rows, timeLbls = {}, {}
	local n = 0
	local maxHistory = 50
	local showTime = true
	local function trimHistory()
		while #rows > maxHistory do
			local old = table.remove(rows, 1)
			if old and old.Parent then old:Destroy() end
		end
		empty.Visible = (#rows == 0)
	end
	effects["History/Batas Riwayat"] = function(v) maxHistory = v; trimHistory() end
	effects["History/Tampilkan Waktu"] = function(s)
		showTime = s
		for _, l in ipairs(timeLbls) do
			if l.Parent then l.Visible = s end
		end
	end

	UI.addHistory = function(text)
		n += 1
		empty.Visible = false
		local row = make("Frame", {
			LayoutOrder = -n, Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = th("PANEL"), BorderSizePixel = 0,
		}, list)
		corner(row, 8)
		glowStroke(row, 1)
		label(row, {
			Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -84, 1, 0),
			Text = tostring(text), TextTruncate = Enum.TextTruncate.AtEnd,
		})
		local tl = label(row, {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.fromOffset(62, 30),
			Text = os.date("%H:%M:%S"), TextColor3 = th("GRAY"), Font = Enum.Font.Gotham, TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Right, Visible = showTime,
		})
		table.insert(timeLbls, tl)
		table.insert(rows, row)
		trimHistory()
		return row
	end

	UI.clearHistory = function()
		for _, r in ipairs(rows) do
			if r.Parent then r:Destroy() end
		end
		table.clear(rows)
		table.clear(timeLbls)
		empty.Visible = true
	end

	clearBtn.Activated:Connect(function()
		UI.clearHistory()
		fire("onClear", tabName)
	end)
end

---------------------------------------------------------------------
-- TAB: TEMA  (23 tema + Super Modern lewat panel pengaturan)
---------------------------------------------------------------------
do
	local p = pages["Tema"]
	local f = makeCenter(p, "Theme")
	local list = makeList(f, UDim2.new(1, -12, 1, -40), UDim2.fromOffset(6, 34), true)

	local themeBtns = {}
	for i, e in ipairs(THEMES) do
		local name, tm = e[1], e[2]
		local b = make("TextButton", {
			LayoutOrder = i, Size = UDim2.new(1, 0, 0, 32),
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

		label(b, {
			Position = UDim2.fromOffset(48, 0), Size = UDim2.new(1, -74, 1, 0), Text = name,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
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
			fire("onTheme", name)
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
-- TAB: SYSTEM KEY
---------------------------------------------------------------------
do
	local p = pages["System Key"]
	local f = makeCenter(p, "System Key", true)

	local box = make("TextBox", {
		Position = UDim2.fromOffset(12, 40), Size = UDim2.new(1, -24, 0, 34),
		BackgroundColor3 = th("PANEL"), BorderSizePixel = 0, Text = "",
		PlaceholderText = "Masukkan key...", PlaceholderColor3 = th("GRAY"),
		TextColor3 = th("TEXT"), Font = Enum.Font.Gotham, TextSize = 12,
		ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
	}, f)
	corner(box, 8)
	glowStroke(box, 1)
	make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, box)

	local checkBtn = make("TextButton", {
		Position = UDim2.fromOffset(12, 82), Size = UDim2.new(0.5, -16, 0, 32),
		BackgroundColor3 = th("ACCENT"), BorderSizePixel = 0, Text = "CHECK KEY",
		TextColor3 = th("ONACC"), Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false,
	}, f)
	corner(checkBtn, 8)
	glowStroke(checkBtn, 1, "ACCENT_DK")
	fx(checkBtn, checkBtn, 0.04)

	local getBtn = make("TextButton", {
		Position = UDim2.new(0.5, 4, 0, 82), Size = UDim2.new(0.5, -16, 0, 32),
		BackgroundColor3 = th("PANEL"), BorderSizePixel = 0, Text = "GET KEY",
		TextColor3 = th("TEXT"), Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false,
	}, f)
	corner(getBtn, 8)
	glowStroke(getBtn, 1)
	fx(getBtn, getBtn, 0.04)

	local premBtn = make("TextButton", {
		Position = UDim2.fromOffset(12, 122), Size = UDim2.new(1, -24, 0, 30),
		BackgroundColor3 = Color3.fromRGB(88, 101, 242), BorderSizePixel = 0, Text = "PREMIUM KEY",
		TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false,
	}, f)
	corner(premBtn, 8)
	fx(premBtn, premBtn, 0.03)

	-- progress bar
	local track = make("Frame", {
		Position = UDim2.fromOffset(12, 168), Size = UDim2.new(1, -24, 0, 12),
		BackgroundColor3 = th("PANEL"), BorderSizePixel = 0, ClipsDescendants = true,
	}, f)
	corner(track, 6)
	glowStroke(track, 1)
	local fill = make("Frame", {
		Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0,
	}, track)
	corner(fill, 6)
	addSweep(fill, "ACCENT", "FLASH")

	local timeLbl = label(f, {
		Position = UDim2.fromOffset(14, 186), Size = UDim2.new(1, -28, 0, 16),
		Text = "Tekan GET KEY (tunggu 5 menit)", TextColor3 = th("GRAY"), Font = Enum.Font.Gotham,
	})
	local keyStatus = label(f, {
		Position = UDim2.fromOffset(14, 208), Size = UDim2.new(1, -28, 0, 16),
		Text = "Belum diverifikasi", TextColor3 = th("GRAY"),
	})
	UI.setKeyStatus = function(t) keyStatus.Text = tostring(t) end

	-- ---- logika key ----
	local function setting(name)
		local v = UI.getSetting("System Key", name)
		if v == nil then v = true end
		return v
	end

	local function readSaved()
		if not (isfile and readfile) then return nil end
		local ok, s = pcall(function()
			if isfile(KEY_FILE) then return readfile(KEY_FILE) end
		end)
		if ok and type(s) == "string" and s ~= "" then return (s:gsub("%s+", "")) end
		return nil
	end
	env.__SenarFreeKey = env.__SenarFreeKey or readSaved()

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

	local function doCheck()
		local ok, tier = validateKey(box.Text)
		if ok then
			keyStatus.Text = "Key valid  [" .. tier .. "]"
			keyStatus.TextColor3 = GREEN
			toast("Key valid (" .. tier .. ") - fitur terbuka")
		else
			keyStatus.Text = "Key tidak valid"
			keyStatus.TextColor3 = REDC
			toast("Key tidak valid - fitur terkunci")
		end
		setUnlocked(ok)
		fire("onKeySubmit", box.Text)
		fire("onKeyResult", ok, tier)
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
			if writefile and setting("Ingat Key") then pcall(writefile, KEY_FILE, key) end
			local copied = false
			if setclipboard and setting("Salin Otomatis") then copied = pcall(setclipboard, key) end
			tween(fill, TweenInfo.new(0.3), { Size = UDim2.new(1, 0, 1, 0) })
			box.Text = key
			timeLbl.Text = copied and "Key siap! Sudah disalin, tekan CHECK KEY" or "Key siap! Tekan CHECK KEY"
			getBtn.Text = "GET KEY"
			waiting = false
			toast("Key kamu sudah jadi")
			if setting("Auto Check") == true and UI.getSetting("System Key", "Auto Check") ~= nil then
				doCheck()
			end
		end)
	end

	getBtn.Activated:Connect(function()
		if waiting then
			toast("Masih menunggu key...")
			return
		end
		fill.Size = UDim2.new(0, 0, 1, 0)
		env.__SenarKeyStart = os.time()
		keyStatus.Text = "Belum diverifikasi"
		keyStatus.TextColor3 = T.GRAY
		runWait()
	end)

	checkBtn.Activated:Connect(doCheck)

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

-- panel pengaturan untuk semua tab (isinya beda per tab)
for _, name in ipairs(tabNames) do
	buildSettingsPanel(name, pages[name])
end

selectTab("Fitur")

-- ================= KILATAN CAHAYA =================
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
	streakFrame = streak

	local tw = TweenService:Create(streak,
		TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 2.5),
		{ Position = UDim2.fromOffset(W + 60, H / 2) })
	tw:Play()
	table.insert(tweens, tw)
end

-- ================= RESIZE GRIP (kanan bawah) =================
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
			dragging, startMouse, startMul = true, input.Position, gripMul
		end
	end))
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - startMouse
			gripMul = math.clamp(startMul + (d.X + d.Y) / 600, 0.4 / math.max(fitMul, 0.01), 3)
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

-- ================= BUKA / TUTUP =================
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

-- ================= TITLE BAR =================
local hubGrad
local function rainbowSeq(t)
	local kps = {}
	for i = 0, 6 do
		kps[#kps + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((t * 0.25 + i / 6) % 1, 0.85, 1))
	end
	return ColorSequence.new(kps)
end

do
	local titleRow = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
	}, main)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5),
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, titleRow)

	-- "Senar": Se = accent, nar = accent2
	local senar = make("TextLabel", {
		Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1, Text = "Senar", TextColor3 = WHITE,
		Font = Enum.Font.GothamBlack, TextSize = 16, LayoutOrder = 1,
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

	-- "Hub": rainbow
	local hub = make("TextLabel", {
		Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1, Text = "Hub", TextColor3 = WHITE,
		Font = Enum.Font.GothamBlack, TextSize = 16, LayoutOrder = 2,
	}, titleRow)
	hubGrad = make("UIGradient", {}, hub)
	hubGrad.Color = rainbowSeq(0)

	-- tombol window
	local function winBtn(posX, hoverColor)
		local b = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, posX, 0, 3), Size = UDim2.fromOffset(26, 22),
			BackgroundColor3 = hoverColor, BackgroundTransparency = 1, BorderSizePixel = 0,
			Text = "", AutoButtonColor = false, ZIndex = 45,
		}, main)
		corner(b, 6)
		b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.45 end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
		return b
	end

	local minBtn = winBtn(-64, th("HOVER"))
	make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 4), Size = UDim2.fromOffset(10, 2),
		BackgroundColor3 = th("TEXT"), BorderSizePixel = 0, ZIndex = 46,
	}, minBtn)

	local maxBtn = winBtn(-36, th("HOVER"))
	do
		local sq = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 10),
			BackgroundTransparency = 1, ZIndex = 46,
		}, maxBtn)
		make("UIStroke", { Color = th("TEXT"), Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, sq)
	end

	local closeBtn = winBtn(-8, Color3.fromRGB(235, 50, 60))
	for _, rot in ipairs({ 45, -45 }) do
		make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(13, 2),
			Rotation = rot, BackgroundColor3 = th("TEXT"), BorderSizePixel = 0, ZIndex = 46,
		}, closeBtn)
	end

	minBtn.Activated:Connect(function() setOpen(false) end)
	maxBtn.Activated:Connect(function()
		zoomMul = (zoomMul == 1) and 1.2 or 1
		applyScale()
	end)
	closeBtn.Activated:Connect(function() UI.destroy() end)

	-- drag window (title bar)
	local dragFrame = make("Frame", {
		Size = UDim2.new(1, -130, 0, 28), BackgroundTransparency = 1, Active = true, ZIndex = 40,
	}, main)
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

-- ================= FLOATING ICON =================
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

-- ================= ANIMASI UTAMA =================
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

-- ================= CLEANUP =================
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

-- ====== TARUH KODE PROJECT KAMU DI BAWAH SINI ======

---------------------------------------------------------------------
-- BIKE FOR EGG  (semua fitur HANYA jalan kalau key sudah valid)
---------------------------------------------------------------------
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

	local RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Eternal", "Divine" }
	local RARITY_ATTRS = { "Rarity", "rarity", "EggRarity", "Tier" }

	-- ================= STATE =================
	local S = { alive = true, busy = false, noclip = false, floatOn = false }
	local function setStatus(t) UI.setStatus(t) end
	local floatPart

	local function featOn(name)
		if not unlocked then return false end
		local fe = UI.getFeature("Fitur", name)
		return fe ~= nil and fe.enabled == true
	end
	local function featVal(name)
		local fe = UI.getFeature("Fitur", name)
		return fe and fe.value
	end
	local function cfgNum(name, dflt)
		local v = UI.getSetting("Fitur", name)
		return tonumber(v) or dflt
	end
	local function zoneSel()
		local v = featVal("Auto Steal") or "Auto"
		return tonumber(tostring(v):match("%d+")) or 0
	end

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
		for _, pt in ipairs(ch:GetDescendants()) do if pt:IsA("BasePart") then pt.CanCollide = false end end
	end))
	table.insert(conns, LocalPlayer.Idled:Connect(function()
		if not unlocked then return end
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
	local function promptPos(pr) return partPos(pr.Parent) end
	local function ptext(pr)
		local par = pr.Parent
		return (pr.ActionText .. " " .. pr.ObjectText .. " " .. pr.Name .. " " .. (par and par.Name or "")):lower()
	end
	local function firePrompt(pr)
		pcall(function()
			pr.HoldDuration = 0
			pr.RequiresLineOfSight = false
			if pr.MaxActivationDistance < 40 then pr.MaxActivationDistance = 40 end
		end)
		if fireproximityprompt then pcall(fireproximityprompt, pr)
		else pcall(function() pr:InputHoldBegin() pr:InputHoldEnd() end) end
	end
	local function isTake(pr)
		local t = ptext(pr)
		return any(t, CFG.TAKE_WORDS) and not any(t, CFG.PLACE_WORDS)
	end
	local function isPlace(pr) return any(ptext(pr), CFG.PLACE_WORDS) end
	local function isOther(pr) -- prompt apa saja yang bukan place/sell/open (cadangan)
		local t = ptext(pr)
		return not any(t, CFG.PLACE_WORDS) and not any(t, CFG.SELL_WORDS) and not any(t, CFG.OPEN_WORDS)
	end

	local function nearestPrompt(center, radius, matcher, minFromSafe)
		local best, bpos, bd = nil, nil, radius
		local mychar = LocalPlayer.Character
		for pr in pairs(prompts) do
			if pr.Parent and pr.Enabled and not (mychar and pr:IsDescendantOf(mychar)) and matcher(pr) then
				local pos = promptPos(pr)
				if pos and (not minFromSafe or (pos - CFG.SAFE).Magnitude > minFromSafe) then
					local d = (pos - center).Magnitude
					if d <= bd then best, bpos, bd = pr, pos, d end
				end
			end
		end
		return best, bpos
	end

	-- ================= DETEKSI RARITY EGG =================
	local rarityCache = setmetatable({}, { __mode = "k" })

	local function hasWord(s, w)
		return s:find("%f[%a]" .. w .. "%f[%A]") ~= nil
	end
	local function rarityOfText(s)
		if type(s) ~= "string" or s == "" then return nil end
		s = s:lower()
		for _, r in ipairs(RARITIES) do
			local k = r:lower()
			if hasWord(s, k) then return r end
			if k == "eternal" and hasWord(s, "enternal") then return r end
		end
		return nil
	end

	-- cari teks rarity di dalam model egg terdekat (dibatasi supaya tidak salah ambil egg lain)
	local function scanModel(model)
		local n = 0
		for _, d in ipairs(model:GetDescendants()) do
			n += 1
			if n > 250 then return nil end
			if d:IsA("TextLabel") or d:IsA("TextButton") then
				local r = rarityOfText(d.Text)
				if r then return r end
			elseif d:IsA("ValueBase") and d.Name:lower():find("rarity", 1, true) then
				local r = rarityOfText(tostring(d.Value))
				if r then return r end
			end
		end
		return nil
	end

	local function eggRarity(pr)
		local cached = rarityCache[pr]
		if cached then return cached end
		local r

		-- 1) attribute / value / nama pada induk (maks 3 tingkat)
		local node = pr.Parent
		for _ = 1, 3 do
			if not node or node == workspace then break end
			for _, an in ipairs(RARITY_ATTRS) do
				local v = node:GetAttribute(an)
				if v ~= nil then r = rarityOfText(tostring(v)) end
				if r then break end
			end
			if r then break end
			local rv = node:FindFirstChild("Rarity")
			if rv and rv:IsA("ValueBase") then r = rarityOfText(tostring(rv.Value)) end
			if r then break end
			r = rarityOfText(node.Name)
			if r then break end
			node = node.Parent
		end

		-- 2) teks prompt
		if not r then r = rarityOfText(pr.ActionText .. " " .. pr.ObjectText) end

		-- 3) label / value di dalam model egg
		if not r then
			local m = pr:FindFirstAncestorWhichIsA("Model")
			if m and m ~= workspace then r = scanModel(m) end
		end

		if r then rarityCache[pr] = r end
		return r
	end

	local function takeMatcher(want)
		return function(pr)
			return isTake(pr) and (not want or eggRarity(pr) == want)
		end
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
					local nm = t.Name:lower()
					if any(nm, CFG.CARRY_WORDS) then return t end
					if not any(nm, CFG.NOT_CARRY) then fb = fb or t end
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
			h.AssemblyLinearVelocity = d.Unit * cfgNum("Speed Gerak Paksa", 100)
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
			TweenInfo.new(dist / math.max(cfgNum("Tween Speed", 120), 1), Enum.EasingStyle.Linear),
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
		if cfgNum("Metode Farming", 1) == 2 then return forceMove(target, stop, cond) end
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
			firePrompt(pp)
			return true
		end
		if tool then pcall(function() tool:Activate() end) return true end
		return false
	end

	-- want = nama rarity (nil = egg apa saja)
	local function waitEggNear(center, timeout, cond, want)
		local t0 = os.clock()
		local matcher = takeMatcher(want)
		repeat
			local pr, pos = nearestPrompt(center, CFG.ZONE_RADIUS, matcher, CFG.SAFE_RADIUS)
			if pr then return pr, pos end
			task.wait(0.25)
		until os.clock() - t0 >= timeout or not cond()
		if want then return nil end -- mode rarity: jangan ambil egg lain
		return nearestPrompt(center, CFG.ZONE_RADIUS, isOther, CFG.SAFE_RADIUS)
	end

	-- ================= STEAL: pergi ke zone -> ambil -> safe zone =================
	-- return true kalau ada egg & berhasil
	local function zoneSteal(zi, cond, want)
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
			local mth = cfgNum("Metode Farming", 1)
			local tag = want and (want .. " ") or ""

			if mth == 3 then
				local chm
				clone, chm = createClone()
				if chm and camera then camera.CameraSubject = chm end
				setStatus(string.format("[3] %sZ%d", tag, zi))
				setPos(h, zpos + Vector3.new(0, 3, 0))
				task.wait(0.15)
			else
				setStatus(string.format("[%d] %sZ%d", mth, tag, zi))
				if not moveTo(zpos, 4, cond) then setStatus("gagal sampai Z" .. zi) return end
			end

			local pr, ppos = waitEggNear(zpos, CFG.FIND_TIMEOUT, cond, want)
			if not pr then
				setStatus(want and ("tidak ada " .. want .. " di Z" .. zi) or ("tidak ada egg Z" .. zi))
				return
			end
			result = true

			-- dekati egg
			h = hrp()
			if h and (ppos - h.Position).Magnitude > 8 then
				if mth == 3 then
					setPos(h, ppos + Vector3.new(0, 3, 0))
					task.wait(0.1)
				else
					moveTo(ppos, 7, cond)
				end
			end

			setStatus("ambil egg Z" .. zi)
			local before = carryScore()
			local got = false
			for _ = 1, 8 do
				if not (pr.Parent and pr.Enabled) or not cond() then break end
				firePrompt(pr)
				task.wait(0.06)
				if carryScore() > before then got = true break end
			end
			if not got then got = carryScore() > before or not (pr.Parent and pr.Enabled) end
			if not got then setStatus("gagal ambil egg") result = false return end

			-- ke safe zone
			setStatus("bawa ke safe zone")
			if mth == 3 then
				setPos(hrp(), CFG.SAFE + Vector3.new(0, 3, 0))
				task.wait(0.15)
			else
				moveTo(CFG.SAFE, 4, cond)
			end
			placeEgg()
			task.wait(0.3)
			setStatus(string.format("selesai Z%d", zi))
		end)
		if not ok then warn("[Senar Hub] zoneSteal: " .. tostring(err)) end
		finish()
		return result
	end

	-- want = nil -> pakai dropdown zone (Auto Steal); want = rarity -> scan semua zone
	local function runSteal(cond, want)
		if S.busy then return end
		S.busy = true
		local ok, err = pcall(function()
			if want then
				local order = {}
				for i = 1, #CFG.ZONES do order[i] = i end
				local filter = want
				if want == "Random" then
					filter = nil
					for i = #order, 2, -1 do
						local j = math.random(i)
						order[i], order[j] = order[j], order[i]
					end
				end
				for _, i in ipairs(order) do
					if not cond() then break end
					if zoneSteal(i, cond, filter) then break end
				end
			else
				local z = zoneSel()
				if z >= 1 and z <= #CFG.ZONES then
					zoneSteal(z, cond)
				else
					for i = 1, #CFG.ZONES do
						if not cond() then break end
						if zoneSteal(i, cond) then break end
					end
				end
			end
		end)
		if not ok then warn("[Senar Hub] runSteal: " .. tostring(err)) end
		S.busy = false
	end

	-- Auto Steal (zona dari dropdown)
	task.spawn(function()
		while S.alive do
			if featOn("Auto Steal") and not featOn("Farming Rarity") and not S.busy and hrp() then
				runSteal(function() return S.alive and featOn("Auto Steal") and not featOn("Farming Rarity") end)
				task.wait(1.5)
			else
				task.wait(0.4)
			end
		end
	end)

	-- Farming Rarity (pilih rarity dari dropdown; Random = egg apa saja, urutan zone acak)
	task.spawn(function()
		while S.alive do
			if featOn("Farming Rarity") and not S.busy and hrp() then
				local want = tostring(featVal("Farming Rarity") or "Random")
				runSteal(function() return S.alive and featOn("Farming Rarity") end, want)
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
			if featOn("Auto Bring Egg") and not S.busy and hrp() then
				local h = hrp()
				local pr = nearestPrompt(h.Position, 20, isTake, CFG.SAFE_RADIUS)
				if pr and (cd[pr] or 0) < os.clock() then
					cd[pr] = os.clock() + 2
					firePrompt(pr)
					task.wait(0.3)
				end
				h = hrp()
				if h and carryScore() > 0 and (h.Position - CFG.SAFE).Magnitude > CFG.SAFE_RADIUS then
					S.busy = true
					local cond = function() return S.alive and featOn("Auto Bring Egg") end
					setStatus("bring egg ke safe zone")
					if cfgNum("Metode Farming", 1) == 3 then
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
			if featOn("Auto Treadmill") and not S.busy and hrp() then
				local pos = findTreadmill()
				if pos then
					local h = hrp()
					if (h.Position - pos).Magnitude > 7 then
						setStatus("tween ke treadmill")
						S.busy = true
						tweenMove(pos + Vector3.new(0, 3, 0), 4, function() return S.alive and featOn("Auto Treadmill") end)
						S.floatOn, S.noclip, S.busy = false, false, false
					end
					h = hrp()
					local pr = h and nearestPrompt(h.Position, 25, function(x) return any(ptext(x), CFG.TREADMILL_USE) end)
					if pr then firePrompt(pr) end
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
		for pr in pairs(prompts) do
			if pr.Parent and pr.Enabled then
				local t = ptext(pr)
				if any(t, words) and (not extra or any(t, extra)) then firePrompt(pr) did = true end
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

	local function loopPress(featName, words, extra, fallbackWords, delay)
		task.spawn(function()
			while S.alive do
				if featOn(featName) then
					local ok, did = pcall(pressKeywords, words, extra)
					if fallbackWords and not (ok and did) then pcall(pressKeywords, fallbackWords) end
				end
				task.wait(delay)
			end
		end)
	end
	loopPress("Auto Upgrade Treadmill", CFG.UPGRADE_WORDS, CFG.TREADMILL, CFG.UPGRADE_WORDS, 2)
	loopPress("Auto Buy Bike", CFG.BUYBIKE_WORDS, CFG.BIKE_WORDS, nil, 2)
	loopPress("Auto Open Egg", CFG.OPEN_WORDS, CFG.EGG_WORDS, CFG.OPEN_WORDS, 2)
	loopPress("Auto Sell All", CFG.SELL_WORDS, nil, nil, 3)

	-- ================= AKSI TOMBOL =================
	actions["Steal Sekarang"] = function()
		if S.busy then setStatus("masih sibuk") return end
		runSteal(function() return S.alive and unlocked end)
	end

	-- debug: lihat rarity yang terbaca dari prompt egg di sekitar
	actions["Dump Egg Rarity"] = function()
		local h = hrp()
		local lines = {}
		for pr in pairs(prompts) do
			if pr.Parent and pr.Enabled and isTake(pr) then
				local pos = promptPos(pr)
				local dist = (h and pos) and math.floor((pos - h.Position).Magnitude) or -1
				if dist >= 0 and dist <= 400 then
					lines[#lines + 1] = string.format("%s | rarity=%s | %d stud", ptext(pr), tostring(eggRarity(pr)), dist)
				end
			end
			if #lines >= 40 then break end
		end
		local s = #lines > 0 and table.concat(lines, "\n") or "(tidak ada egg dalam 400 stud)"
		if setclipboard then pcall(setclipboard, s) end
		print(s)
		setStatus("dump disalin")
	end

	gui.Destroying:Connect(function()
		S.alive = false
		if floatPart then pcall(function() floatPart:Destroy() end) end
	end)
end)
if not okBike then
	warn("[Senar Hub] ERROR: " .. tostring(errBike))
	UI.setStatus("ERR: " .. tostring(errBike):sub(1, 60))
end
