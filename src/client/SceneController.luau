local Run=game:GetService("RunService")
local Collection=game:GetService("CollectionService")
local Lighting=game:GetService("Lighting")
local Theme=require(game.ReplicatedStorage.Shared.UITheme)
local Loader=require(game.ReplicatedStorage.Shared.PokemonModelLoader)
local Scene={Ambient={},Connections={},TeamModels={}}
function Scene:Destroy()
 self.TeamSignature=nil; self.PadCount=nil; self.Mode=nil
 for _,c in ipairs(self.Connections) do c:Disconnect() end; table.clear(self.Connections)
 for _,model in ipairs(self.TeamModels) do model:Destroy() end; table.clear(self.TeamModels); table.clear(self.Ambient)
end
function Scene:Register(node)
 if not (node:IsA("Model") or node:IsA("BasePart")) then return end
 self.Ambient[node]={Base=node:GetAttribute("BasePivot") or (node:IsA("Model") and node:GetPivot() or node.CFrame),Motion=node:GetAttribute("AmbientMotion"),Speed=node:GetAttribute("MotionSpeed") or .3}
end
function Scene:Init(ui)
 self:Destroy(); self.UI=ui
 for _,node in ipairs(Collection:GetTagged("ArenaAmbient")) do self:Register(node) end
 table.insert(self.Connections,Collection:GetInstanceAddedSignal("ArenaAmbient"):Connect(function(node) self:Register(node) end))
 table.insert(self.Connections,Collection:GetInstanceRemovedSignal("ArenaAmbient"):Connect(function(node) self.Ambient[node]=nil end))
 table.insert(self.Connections,ui.Gui.Destroying:Connect(function() self:Destroy() end))
 local elapsed=0
 table.insert(self.Connections,Run.RenderStepped:Connect(function(dt)
  elapsed+=dt; if elapsed<.05 then return end; elapsed=0
  local profile=ui.Profile; local mode=profile and profile.Settings.Graphics or "Medium"
  local cfg=Theme.Graphics[mode] or Theme.Graphics.Medium
  if mode~=self.Mode then
   self.Mode=mode; Lighting.GlobalShadows=cfg.Shadows
   for node in pairs(self.Ambient) do
    if node:GetAttribute("DecorativeNPC") then for _,part in ipairs(node:GetDescendants()) do if part:IsA("BasePart") then part.LocalTransparencyModifier=cfg.Ambient and 0 or 1 end end end
   end
  end
  local camera=workspace.CurrentCamera; local now=os.clock()
  if cfg.Ambient and camera then
   for node,data in pairs(self.Ambient) do
    if not node.Parent then self.Ambient[node]=nil; continue end
    if (data.Base.Position-camera.CFrame.Position).Magnitude>250 then continue end
    local time=now*data.Speed; local cf=data.Base
    if data.Motion=="FloatSpin" then cf*=CFrame.new(0,math.sin(time*2)*.5,0)*CFrame.Angles(0,time,0)
    elseif data.Motion=="Spin" then cf*=CFrame.Angles(0,time*3,0)
    elseif data.Motion=="Swing" then cf*=CFrame.Angles(0,math.sin(time)*.18,0)
    elseif data.Motion=="Patrol" then cf*=CFrame.new(math.sin(time)*4,math.abs(math.sin(time*5))*.08,0)
    elseif data.Motion=="Slide" then cf*=CFrame.new(math.sin(time)*9,0,0) end
    if node:IsA("Model") then node:PivotTo(cf) else node.CFrame=cf end
   end
  end
  if profile then
   local signature=table.concat(profile.Team,",")
   local pads=Collection:GetTagged("ArenaTeamPreviewPad")
   if signature~=self.TeamSignature or #pads~=self.PadCount then
    self.TeamSignature=signature; self.PadCount=#pads
    for _,model in ipairs(self.TeamModels) do model:Destroy() end; table.clear(self.TeamModels)
    for _,pad in ipairs(pads) do
     local id=profile.Team[pad:GetAttribute("TeamSlot")]
     if id then local model=Loader:ClonePokemon(id); model:PivotTo(pad.CFrame*CFrame.new(0,3,0)); model.Name="LocalTeamPreview"; model.Parent=workspace; table.insert(self.TeamModels,model) end
    end
   end
   if now-(self.BoardAt or 0)>5 then
    self.BoardAt=now
    for _,label in ipairs(Collection:GetTagged("ArenaLeaderboard")) do
     local key=label:GetAttribute("LeaderboardKey"); local lines={string.upper(key),"SEASON 01"}
     for i,entry in ipairs(ui.Boards[key] or {}) do if i>5 then break end; table.insert(lines,i.." / "..entry.Name.."  "..entry.Value) end
     if #lines==2 then table.insert(lines,"LEAGUE SCORES APPEAR AFTER PUBLISHED MATCHES") end
     label.Text=table.concat(lines,"\n")
    end
   end
  end
 end))
end
return Scene
