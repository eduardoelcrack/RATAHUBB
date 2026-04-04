-- ============================================================
--  RATAHUB  |  by Bambi  |  Fluent UI
-- ============================================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer.Character

-- ╔══════════════════════════════════════════════════════════╗
-- ║                      SERVICIOS                          ║
-- ╚══════════════════════════════════════════════════════════╝
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local GuiService       = game:GetService("GuiService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera
local Mouse            = LocalPlayer:GetMouse()

local function IsAlive(plr)
	return plr and plr.Character
		and plr.Character:FindFirstChildOfClass("Humanoid")
		and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║                     FLUENT WINDOW                       ║
-- ╚══════════════════════════════════════════════════════════╝
local Window = Fluent:CreateWindow({
	Title    = "RATAHUB",
	SubTitle = "by Bambi",
	TabWidth = 160,
	Size     = UDim2.fromOffset(580, 460),
	Acrylic  = true,
	Theme    = "Dark",
	MinimizeKey = Enum.KeyCode.K
})

local Tabs = {
	Main    = Window:AddTab({ Title = "Main",    Icon = "zap" }),
	Aimlock = Window:AddTab({ Title = "Aimlock", Icon = "crosshair" }),
	Scripts = Window:AddTab({ Title = "Scripts", Icon = "code" }),
}

local Options = Fluent.Options

-- ╔══════════════════════════════════════════════════════════╗
-- ║                         FLY                             ║
-- ╚══════════════════════════════════════════════════════════╝
local FlyToggleEnabled = false
local FlyActive        = false
local FlySpeed         = 140
local BV, BG           = nil, nil
local OldAnimate       = nil
local FlyLoop          = nil

local function StartFly()
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local hum  = char:FindFirstChildOfClass("Humanoid")
	local root = char.HumanoidRootPart
	if hum then hum.PlatformStand = true end
	if char:FindFirstChild("Animate") then
		OldAnimate = char.Animate:Clone()
		char.Animate:Destroy()
	end
	BV = Instance.new("BodyVelocity")
	BV.MaxForce = Vector3.new(1e5,1e5,1e5)
	BV.Velocity = Vector3.zero
	BV.Parent   = root
	BG = Instance.new("BodyGyro")
	BG.MaxTorque = Vector3.new(1e5,1e5,1e5)
	BG.P  = 20000
	BG.D  = 800
	BG.Parent = root
	FlyLoop = RunService.RenderStepped:Connect(function()
		if not FlyActive then return end
		local look  = Camera.CFrame.LookVector
		local right = look:Cross(Vector3.new(0,1,0))
		local move  = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W)           then move += look end
		if UserInputService:IsKeyDown(Enum.KeyCode.S)           then move -= look end
		if UserInputService:IsKeyDown(Enum.KeyCode.A)           then move -= right end
		if UserInputService:IsKeyDown(Enum.KeyCode.D)           then move += right end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then move += Vector3.new(0,1,0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
		BV.Velocity = move * FlySpeed
		BG.CFrame   = Camera.CFrame
	end)
end

local function StopFly()
	FlyActive = false
	if FlyLoop then FlyLoop:Disconnect(); FlyLoop = nil end
	if BV then BV:Destroy(); BV = nil end
	if BG then BG:Destroy(); BG = nil end
	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = false end
		if OldAnimate then OldAnimate.Parent = char; OldAnimate = nil end
	end
end

Tabs.Main:AddToggle("FlyToggle", {
	Title   = "Fly",
	Default = false,
	Callback = function(v)
		FlyToggleEnabled = v
		FlyActive = false
		StopFly()
	end
})

Tabs.Main:AddKeybind("FlyKeybind", {
	Title   = "Fly Keybind",
	Mode    = "Toggle",
	Default = "V",
	Callback = function(v)
		if not FlyToggleEnabled then return end
		FlyActive = not FlyActive
		if FlyActive then
			StartFly()
			Fluent:Notify({Title="Fly", Content="Activado", Duration=1.5})
		else
			StopFly()
			Fluent:Notify({Title="Fly", Content="Desactivado", Duration=1.5})
		end
	end
})

Tabs.Main:AddSlider("FlySpeed", {
	Title   = "Velocidad Fly",
	Min     = 50,
	Max     = 600,
	Default = 140,
	Rounding= 0,
	Callback = function(v) FlySpeed = v end
})

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.2)
	FlyActive = false
	StopFly()
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║                    INFINITE JUMP                        ║
-- ╚══════════════════════════════════════════════════════════╝
local InfiniteJumpEnabled = false
Tabs.Main:AddToggle("InfJump", {
	Title   = "Infinite Jump",
	Default = false,
	Callback = function(v) InfiniteJumpEnabled = v end
})
UserInputService.JumpRequest:Connect(function()
	if InfiniteJumpEnabled and LocalPlayer.Character then
		pcall(function() LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping") end)
	end
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║                      WALKSPEED                          ║
-- ╚══════════════════════════════════════════════════════════╝
local WSToggleEnabled = false
local WSActive        = false
local TargetWalkSpeed = 140
local OriginalWalkSpeed = nil
local WalkSpeedLoop   = nil

local function StartWalkSpeedLoop()
	if WalkSpeedLoop then return end
	WalkSpeedLoop = RunService.Heartbeat:Connect(function()
		local char = LocalPlayer.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		if not OriginalWalkSpeed then OriginalWalkSpeed = hum.WalkSpeed end
		hum.WalkSpeed = WSActive and TargetWalkSpeed or OriginalWalkSpeed
	end)
end

local function StopWalkSpeedLoop()
	if WalkSpeedLoop then WalkSpeedLoop:Disconnect(); WalkSpeedLoop = nil end
	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and OriginalWalkSpeed then hum.WalkSpeed = OriginalWalkSpeed end
	end
end

Tabs.Main:AddToggle("WSToggle", {
	Title   = "WalkSpeed",
	Default = false,
	Callback = function(v)
		WSToggleEnabled = v
		if not v then WSActive = false; StopWalkSpeedLoop()
		else StartWalkSpeedLoop() end
	end
})

Tabs.Main:AddKeybind("WSKeybind", {
	Title   = "WalkSpeed Keybind",
	Mode    = "Toggle",
	Default = "C",
	Callback = function()
		if not WSToggleEnabled then return end
		WSActive = not WSActive
	end
})

Tabs.Main:AddSlider("WSSlider", {
	Title    = "WalkSpeed",
	Min      = 16,
	Max      = 300,
	Default  = 140,
	Rounding = 0,
	Callback = function(v) TargetWalkSpeed = v end
})

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.2)
	WSActive = false
	OriginalWalkSpeed = nil
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║                   ESP (HIGHLIGHT)                       ║
-- ╚══════════════════════════════════════════════════════════╝
local ESPFillColor    = Color3.fromRGB(175, 25, 255)
local ESPOutlineColor = Color3.fromRGB(175, 25, 255)
local ESPConns        = {}
local ESPStorage      = nil

local function SetupHighlightESP(Value)
	if ESPStorage then ESPStorage:Destroy(); ESPStorage = nil end
	for _, c in pairs(ESPConns) do c:Disconnect() end
	ESPConns = {}
	if not Value then return end

	ESPStorage = Instance.new("Folder")
	ESPStorage.Name   = "Highlight_Storage"
	ESPStorage.Parent = CoreGui

	local function Highlight(plr)
		if plr == LocalPlayer then return end
		local function apply(char)
			if ESPStorage:FindFirstChild(plr.Name) then ESPStorage[plr.Name]:Destroy() end
			local h = Instance.new("Highlight")
			h.Name                = plr.Name
			h.DepthMode           = "AlwaysOnTop"
			h.FillColor           = ESPFillColor
			h.OutlineColor        = ESPOutlineColor
			h.FillTransparency    = 0.5
			h.OutlineTransparency = 0
			h.Adornee             = char
			h.Parent              = ESPStorage
		end
		if plr.Character then apply(plr.Character) end
		ESPConns[plr] = plr.CharacterAdded:Connect(function(char)
			task.wait(0.5); apply(char)
		end)
	end

	for _, p in ipairs(Players:GetPlayers()) do Highlight(p) end
	ESPConns["Added"]   = Players.PlayerAdded:Connect(Highlight)
	ESPConns["Removed"] = Players.PlayerRemoving:Connect(function(plr)
		if ESPStorage:FindFirstChild(plr.Name) then ESPStorage[plr.Name]:Destroy() end
		if ESPConns[plr] then ESPConns[plr]:Disconnect() end
	end)
end

Tabs.Main:AddToggle("ESP", {
	Title   = "ESP",
	Default = false,
	Callback = SetupHighlightESP
})

-- ╔══════════════════════════════════════════════════════════╗
-- ║                     ESP NOMBRES                         ║
-- ╚══════════════════════════════════════════════════════════╝
local NameESPFolder = nil
local nameConns     = {}

Tabs.Main:AddToggle("ESPNombres", {
	Title   = "ESP Nombres",
	Default = false,
	Callback = function(enabled)
		if NameESPFolder then NameESPFolder:Destroy(); NameESPFolder = nil end
		for _, c in ipairs(nameConns) do c:Disconnect() end
		nameConns = {}
		if not enabled then return end

		NameESPFolder        = Instance.new("Folder")
		NameESPFolder.Name   = "NameESP_Storage"
		NameESPFolder.Parent = CoreGui

		local function createNameTag(plr)
			if plr == LocalPlayer then return end
			local function apply(char)
				local head = char:WaitForChild("Head", 5)
				if not head or not NameESPFolder then return end
				if NameESPFolder:FindFirstChild(plr.Name) then NameESPFolder[plr.Name]:Destroy() end
				local bg = Instance.new("BillboardGui")
				bg.Name        = plr.Name
				bg.Adornee     = head
				bg.Size        = UDim2.new(0,140,0,26)
				bg.StudsOffset = Vector3.new(0,3,0)
				bg.AlwaysOnTop = true
				bg.Parent      = NameESPFolder
				local txt = Instance.new("TextLabel", bg)
				txt.Size                   = UDim2.new(1,0,1,0)
				txt.BackgroundTransparency = 1
				txt.Text                   = plr.Name
				txt.TextColor3             = Color3.fromRGB(255,255,255)
				txt.TextStrokeColor3       = Color3.new(0,0,0)
				txt.TextStrokeTransparency = 0
				txt.Font                   = Enum.Font.Arcade
				txt.TextScaled             = true
			end
			if plr.Character then task.spawn(apply, plr.Character) end
			table.insert(nameConns, plr.CharacterAdded:Connect(function(char)
				task.wait(0.5); apply(char)
			end))
		end

		for _, p in Players:GetPlayers() do createNameTag(p) end
		table.insert(nameConns, Players.PlayerAdded:Connect(createNameTag))
	end
})

-- ╔══════════════════════════════════════════════════════════╗
-- ║                  ESP NOMBRE + STUDS                     ║
-- ╚══════════════════════════════════════════════════════════╝
local ESPEnabled    = false
local ESPObjects    = {}
local ESPConnection = nil

local function createDistESP(player)
	if player == LocalPlayer then return end
	local billboard = Instance.new("BillboardGui")
	billboard.Size        = UDim2.new(0,120,0,36)
	billboard.AlwaysOnTop = true
	billboard.StudsOffset = Vector3.new(0,3,0)
	local nameLabel = Instance.new("TextLabel", billboard)
	nameLabel.Size                   = UDim2.new(1,0,0.5,0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3             = Color3.fromRGB(255,255,255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled             = true
	nameLabel.Text                   = player.Name
	local distLabel = Instance.new("TextLabel", billboard)
	distLabel.Size                   = UDim2.new(1,0,0.5,0)
	distLabel.Position               = UDim2.new(0,0,0.5,0)
	distLabel.BackgroundTransparency = 1
	distLabel.TextColor3             = Color3.fromRGB(200,200,200)
	distLabel.TextStrokeTransparency = 0.2
	distLabel.TextScaled             = true
	ESPObjects[player] = {Gui=billboard, Name=nameLabel, Dist=distLabel}
end

Tabs.Main:AddToggle("ESPStuds", {
	Title   = "ESP Nombre + Studs",
	Default = false,
	Callback = function(v)
		ESPEnabled = v
		for _, p in pairs(Players:GetPlayers()) do
			if v then
				createDistESP(p)
				p.CharacterAdded:Connect(function()
					task.wait(0.5)
					if ESPEnabled then
						if ESPObjects[p] then ESPObjects[p].Gui:Destroy(); ESPObjects[p] = nil end
						createDistESP(p)
					end
				end)
			else
				if ESPObjects[p] then ESPObjects[p].Gui:Destroy(); ESPObjects[p] = nil end
			end
		end
		if v and not ESPConnection then
			ESPConnection = RunService.RenderStepped:Connect(function()
				local myChar = LocalPlayer.Character
				local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
				if not myHRP then return end
				for player, data in pairs(ESPObjects) do
					pcall(function()
						local char = player.Character
						local hrp  = char and char:FindFirstChild("HumanoidRootPart")
						if hrp then
							data.Gui.Parent    = hrp
							local dist         = (myHRP.Position - hrp.Position).Magnitude
							data.Dist.Text     = math.floor(dist).." studs"
							local scale        = math.clamp(2-(dist/500),0.4,2)
							data.Gui.Size      = UDim2.new(0,120*scale,0,36*scale)
						else
							if data.Gui then data.Gui.Parent = nil end
						end
					end)
				end
			end)
		elseif not v and ESPConnection then
			ESPConnection:Disconnect(); ESPConnection = nil
		end
	end
})

-- ╔══════════════════════════════════════════════════════════╗
-- ║             HITBOX EXPANDER + ANTI WALL                 ║
-- ╚══════════════════════════════════════════════════════════╝
getgenv().HBE            = false
getgenv().AntiWallHitbox = false
getgenv().HitboxSize     = 5

local OriginalSizes = {}
local RayParams     = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Blacklist

local function CanSeeTarget(char)
	local head = char:FindFirstChild("Head")
	if not head then return false end
	RayParams.FilterDescendantsInstances = {LocalPlayer.Character}
	local origin = Camera.CFrame.Position
	local dir    = head.Position - origin
	local ray    = workspace:Raycast(origin, dir, RayParams)
	return ray and ray.Instance and ray.Instance:IsDescendantOf(char)
end

local function RestoreHitbox(plr)
	local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if hrp and OriginalSizes[plr] then
		hrp.Size        = OriginalSizes[plr]
		hrp.Transparency= 1
		hrp:SetAttribute("IsExpandedHitbox", false)
		OriginalSizes[plr] = nil
	end
end

local function ApplyHitbox(plr)
	if plr == LocalPlayer or not IsAlive(plr) then return end
	local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	OriginalSizes[plr]  = OriginalSizes[plr] or hrp.Size
	hrp.Size            = Vector3.new(getgenv().HitboxSize,getgenv().HitboxSize,getgenv().HitboxSize)
	hrp.Transparency    = 0.5
	hrp.Material        = Enum.Material.Neon
	hrp.Color           = Color3.fromRGB(175,25,255)
	hrp.CanCollide      = false
	hrp:SetAttribute("IsExpandedHitbox", true)
end

RunService.Heartbeat:Connect(function()
	for _, p in Players:GetPlayers() do
		if p ~= LocalPlayer and IsAlive(p) then
			if getgenv().HBE and not getgenv().AntiWallHitbox then
				ApplyHitbox(p)
			elseif getgenv().HBE and getgenv().AntiWallHitbox then
				if CanSeeTarget(p.Character) then ApplyHitbox(p) else RestoreHitbox(p) end
			else
				RestoreHitbox(p)
			end
		end
	end
end)

Tabs.Main:AddToggle("HBE", {
	Title   = "Hitbox Expander",
	Default = false,
	Callback = function(v) getgenv().HBE = v end
})

Tabs.Main:AddToggle("AntiWall", {
	Title   = "Anti Wall Hitbox",
	Default = false,
	Callback = function(v) getgenv().AntiWallHitbox = v end
})

Tabs.Main:AddSlider("HBESize", {
	Title    = "Tamaño del Hitbox",
	Min      = 1,
	Max      = 150,
	Default  = 5,
	Rounding = 0,
	Callback = function(v) getgenv().HitboxSize = v end
})

-- ╔══════════════════════════════════════════════════════════╗
-- ║                       NOCLIP                            ║
-- ╚══════════════════════════════════════════════════════════╝
local noclipEnabled    = false
local noclipConnection = nil

local function applyNoclip(char)
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then part.CanCollide = false end
	end
end

local function startNoclip()
	local char = LocalPlayer.Character
	if not char then return end
	noclipConnection = RunService.Stepped:Connect(function()
		local c = LocalPlayer.Character
		if c then pcall(applyNoclip, c) end
	end)
	applyNoclip(char)
end

local function stopNoclip()
	if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
	local char = LocalPlayer.Character
	if char then
		for _, part in pairs(char:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = true end
		end
	end
end

Tabs.Main:AddToggle("Noclip", {
	Title   = "Noclip",
	Default = false,
	Callback = function(v)
		noclipEnabled = v
		if v then startNoclip() else stopNoclip() end
	end
})

LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.1)
	if noclipEnabled then applyNoclip(char) end
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║                       BOTONES                           ║
-- ╚══════════════════════════════════════════════════════════╝
Tabs.Main:AddButton({
	Title    = "Force Reset",
	Callback = function() pcall(function() LocalPlayer.Character:BreakJoints() end) end
})

Tabs.Main:AddButton({
	Title    = "Rejoin",
	Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId) end
})

local AntiAFKConn = nil
Tabs.Main:AddButton({
	Title    = "Anti-AFK",
	Callback = function()
		if AntiAFKConn then
			AntiAFKConn:Disconnect(); AntiAFKConn = nil
			Fluent:Notify({Title="Anti-AFK", Content="Desactivado", Duration=1.5})
		else
			AntiAFKConn = LocalPlayer.Idled:Connect(function()
				game:GetService("VirtualUser"):ClickButton2(Vector2.new())
			end)
			Fluent:Notify({Title="Anti-AFK", Content="Activado", Duration=1.5})
		end
	end
})

-- ╔══════════════════════════════════════════════════════════╗
-- ║                       AIMLOCK                           ║
-- ╚══════════════════════════════════════════════════════════╝
getgenv().Aimlock = { Enabled=false, ToggleOn=false }

local AimConfig = {
	MaxDistance    = 1000,
	UseFOV         = false,
	FOVRadius      = 150,
	AimPart        = "Head",
	UseMaxDistance = true,
}

local LockedTarget  = nil
local AimESP        = {}
local HeartbeatConn = nil
local SmartESPEnabled = true
local SmartHighlight  = nil
local FrameCounter  = 0
local TriedLock     = false

local function ClearESP()
	for _, h in pairs(AimESP) do if h then h:Destroy() end end
	AimESP = {}
	if SmartHighlight then SmartHighlight:Destroy(); SmartHighlight = nil end
end

local function GetAimPart(char)
	if not char then return nil end
	for _, name in ipairs({"Head","HumanoidRootPart","UpperTorso","Torso"}) do
		local part = char:FindFirstChild(name)
		if part then return part end
	end
	return char:FindFirstChildWhichIsA("BasePart")
end

local function CreateNormalESP(plr)
	ClearESP()
	if not plr or not plr.Character then return end
	local h = Instance.new("Highlight")
	h.Adornee          = plr.Character
	h.FillColor        = Color3.fromRGB(255,0,0)
	h.OutlineColor     = Color3.new(1,1,1)
	h.FillTransparency = 0.5
	h.Parent           = plr.Character
	AimESP[plr]        = h
end

local function UpdateSmartESP()
	if not SmartESPEnabled or not LockedTarget or not IsAlive(LockedTarget) then
		if SmartHighlight then SmartHighlight:Destroy(); SmartHighlight = nil end
		return
	end
	local char = LockedTarget.Character
	local head = char and char:FindFirstChild("Head")
	if not head then return end
	if not SmartHighlight then
		SmartHighlight = Instance.new("Highlight")
		SmartHighlight.FillTransparency    = 0.3
		SmartHighlight.OutlineTransparency = 0
		SmartHighlight.OutlineColor        = Color3.new(1,1,1)
		SmartHighlight.Parent              = char
	end
	FrameCounter += 1
	if FrameCounter % 2 == 0 then
		local origin    = Camera.CFrame.Position
		local dir       = (head.Position - origin).Unit * 500
		local params    = RaycastParams.new()
		local ignoreList= {LocalPlayer.Character}
		for _, p in Players:GetPlayers() do
			if p.Character then
				local hrp = p.Character:FindFirstChild("HumanoidRootPart")
				if hrp and hrp:GetAttribute("IsExpandedHitbox") then
					table.insert(ignoreList, hrp)
				end
			end
		end
		params.FilterDescendantsInstances = ignoreList
		params.FilterType = Enum.RaycastFilterType.Blacklist
		local r = workspace:Raycast(origin, dir, params)
		SmartHighlight.FillColor =
			(r and r.Instance and r.Instance:IsDescendantOf(char))
			and Color3.fromRGB(0,255,0)
			or  Color3.fromRGB(255,0,0)
	end
end

local FOVCircle     = Drawing.new("Circle")
FOVCircle.Color     = Color3.fromRGB(175,25,255)
FOVCircle.Thickness = 2
FOVCircle.Filled    = false
FOVCircle.Visible   = false
FOVCircle.Radius    = AimConfig.FOVRadius

RunService.RenderStepped:Connect(function()
	if not AimConfig.UseFOV then FOVCircle.Visible = false; return end
	local inset       = GuiService:GetGuiInset()
	FOVCircle.Position= Vector2.new(Mouse.X, Mouse.Y + inset.Y)
	FOVCircle.Radius  = AimConfig.FOVRadius
	FOVCircle.Visible = true
end)

local function GetClosest()
	local closestPlayer = nil
	local shortest      = math.huge
	for _, plr in Players:GetPlayers() do
		if plr ~= LocalPlayer and IsAlive(plr) then
			local char = plr.Character
			if not char then continue end
			local partsToCheck = {
				"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg",
				"UpperTorso","LowerTorso","HumanoidRootPart",
				"LeftUpperArm","LeftLowerArm","LeftHand",
				"RightUpperArm","RightLowerArm","RightHand",
				"LeftUpperLeg","LeftLowerLeg","LeftFoot",
				"RightUpperLeg","RightLowerLeg","RightFoot"
			}
			for _, partName in ipairs(partsToCheck) do
				local part = char:FindFirstChild(partName)
				if part then
					local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
					if not onScreen then continue end
					local dist = (Vector2.new(screenPos.X,screenPos.Y) - Vector2.new(Mouse.X,Mouse.Y)).Magnitude
					if AimConfig.UseFOV and dist > AimConfig.FOVRadius then continue end
					if dist < shortest then
						shortest      = dist
						closestPlayer = plr
					end
				end
			end
		end
	end
	return closestPlayer
end

local function StopAimlock()
	getgenv().Aimlock.Enabled = false
	TriedLock    = false
	LockedTarget = nil
	ClearESP()
	RunService:UnbindFromRenderStep("AimlockSnap")
	if HeartbeatConn then HeartbeatConn:Disconnect(); HeartbeatConn = nil end
end

local function StartAimlock()
	TriedLock    = false
	LockedTarget = nil
	ClearESP()
	RunService:UnbindFromRenderStep("AimlockSnap")
	if HeartbeatConn then HeartbeatConn:Disconnect(); HeartbeatConn = nil end

	RunService:BindToRenderStep("AimlockSnap", Enum.RenderPriority.Camera.Value+1, function()
		if not getgenv().Aimlock.Enabled then return end
		if LockedTarget and not IsAlive(LockedTarget) then
			StopAimlock(); getgenv().Aimlock.Enabled = false; return
		end
		if not LockedTarget then
			if TriedLock then return end
			TriedLock    = true
			LockedTarget = GetClosest()
			if LockedTarget then
				CreateNormalESP(LockedTarget)
			else
				StopAimlock()
				Fluent:Notify({Title="Aimlock", Content="Sin targets", Duration=1.5})
			end
		else
			local part = GetAimPart(LockedTarget.Character)
			if part then Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, part.Position) end
		end
	end)

	HeartbeatConn = RunService.RenderStepped:Connect(function()
		if getgenv().Aimlock.Enabled then UpdateSmartESP() end
	end)
end

Tabs.Aimlock:AddToggle("AimlockToggle", {
	Title   = "Aimlock",
	Default = false,
	Callback = function(v)
		getgenv().Aimlock.ToggleOn = v
		if not v then StopAimlock() end
	end
})

Tabs.Aimlock:AddKeybind("AimlockKeybind", {
	Title   = "Keybind Aimlock",
	Mode    = "Toggle",
	Default = "RightShift",
	Callback = function()
		if not getgenv().Aimlock.ToggleOn then return end
		getgenv().Aimlock.Enabled = not getgenv().Aimlock.Enabled
		if getgenv().Aimlock.Enabled then StartAimlock() else StopAimlock() end
	end
})

Tabs.Aimlock:AddToggle("SmartESP", {
	Title   = "Smart ESP (WallCheck)",
	Default = true,
	Callback = function(v) SmartESPEnabled = v end
})

Tabs.Aimlock:AddDropdown("AimPart", {
	Title   = "Aim Part Priority",
	Values  = {"Head","Torso","Auto"},
	Default = "Head",
	Callback = function(v) AimConfig.AimPart = v end
})

Tabs.Aimlock:AddSlider("MaxDist", {
	Title    = "Max Distance",
	Min      = 100,
	Max      = 5000,
	Default  = 1000,
	Rounding = 0,
	Callback = function(v) AimConfig.MaxDistance = v end
})

Tabs.Aimlock:AddToggle("UseMaxDist", {
	Title   = "Usar Max Distance",
	Default = true,
	Callback = function(v) AimConfig.UseMaxDistance = v end
})

Tabs.Aimlock:AddSlider("FOVSize", {
	Title    = "FOV Size",
	Min      = 50,
	Max      = 500,
	Default  = 150,
	Rounding = 0,
	Callback = function(v) AimConfig.FOVRadius = v end
})

Tabs.Aimlock:AddToggle("UseFOV", {
	Title   = "Use FOV",
	Default = false,
	Callback = function(v) AimConfig.UseFOV = v end
})

-- ╔══════════════════════════════════════════════════════════╗
-- ║                    SCRIPTS TAB                          ║
-- ╚══════════════════════════════════════════════════════════╝
Tabs.Scripts:AddButton({
	Title    = "Fling",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/0Ben1/fe/main/obf_rf6iQURzu1fqrytcnLBAvW34C9N55kS9g9G3CKz086rC47M6632sEd4ZZYB0AYgV.lua.txt"))()
	end
})

Window:SelectTab(1)

print("RATAHUB gg")
Fluent:Notify({Title="RATAHUB", Content="maldito 😝", Duration=4})
