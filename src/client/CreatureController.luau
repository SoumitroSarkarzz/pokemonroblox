local Run=game:GetService("RunService")
local Shared=game.ReplicatedStorage.Shared
local Rig=require(Shared.PokemonRigAdapter)
local Loader=require(Shared.PokemonModelLoader)
local Controller={Actors={}}
function Controller:Init(ui)
 self.UI=ui
 local function inspect(model)
  if not model:IsA("Model") or model.Name~="BattlePokemon" then return end
  task.defer(function()
   local visual=model:WaitForChild("VisualModel",5)
   if visual then self.Actors[model]={Rig=Rig.new(visual),Tracks={},Last="",Offset=0} end
  end)
 end
 workspace.DescendantAdded:Connect(inspect)
 for _,model in ipairs(workspace:GetDescendants()) do inspect(model) end
 Run.RenderStepped:Connect(function()
  for model,actor in pairs(self.Actors) do
   if not model.Parent then self.Actors[model]=nil; continue end
   local root=model.PrimaryPart
   if not root then continue end
   local speed=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude
   local state=speed>1 and "Run" or "Idle"
   if state~=actor.Last then
    actor.Last=state
    for _,track in pairs(actor.Tracks) do track:Stop(.15) end
    local folder=Loader:GetPokemonFolder(model:GetAttribute("PokemonID"))
    local animation=folder and folder.Animations:FindFirstChild(state)
    if animation and animation.AnimationId~="" then
     local track=actor.Rig:PlayAnimation(animation)
     if track then actor.Tracks[state]=track end
    end
   end
   -- Unanimated rigid assets remain functional, without altering combat roots.
   local visual=actor.Rig.Model
   local rootPart=visual.PrimaryPart
   if rootPart then
    local joint=rootPart:FindFirstChild("Procedural")
    if joint and joint:IsA("Motor6D") then joint.Transform=CFrame.new(0,math.sin(os.clock()*9)*math.min(speed/20,1)*.12,0) end
   end
  end
 end)
end
function Controller:Effect(data)
 for model,actor in pairs(self.Actors) do
  if model:GetAttribute("ActorID")==data.ActorID then
   local folder=Loader:GetPokemonFolder(model:GetAttribute("PokemonID")); if not folder then return end
   local mapping={Basic="M1_"..tostring(data.Extra and data.Extra.Combo or 1),Pulse="Ability1",Rush="Ability2",Ward="Ability3",Nova="Ability4",Hit="Hit",Switch="SwitchOut",Dash="Dash"}
   local name=mapping[data.Name]
   if name then actor.Rig:PlayAnimation(folder.Animations:FindFirstChild(name)) end
   local sound=folder.Sounds:FindFirstChild(data.Name=="Basic" and "Attack" or name or "Spawn")
   if sound and sound.SoundId~="" then
    local clone=sound:Clone(); clone.Parent=model.PrimaryPart; clone:Play(); game:GetService("Debris"):AddItem(clone,10)
   end
   local vfx=folder.VFX:FindFirstChild(name or "")
   if vfx and (not self.UI.Profile or self.UI.Profile.Settings.Effects) then
    for _,source in ipairs(vfx:GetChildren()) do
     local clone=source:Clone(); clone.Parent=model.PrimaryPart
     if clone:IsA("ParticleEmitter") then clone:Emit(math.min(24,clone:GetAttribute("EmitCount") or 12)) end
     game:GetService("Debris"):AddItem(clone,3)
    end
   end
  end
 end
end
return Controller
