local Config=require(game.ReplicatedStorage.Shared.Config)
local Maps=require(game.ReplicatedStorage.Shared.MapDatabase)
local Loader=require(game.ReplicatedStorage.Shared.PokemonModelLoader)
local World={Pads={},Screens={}}
local function part(parent,name,size,cf,color,material)
 local p=Instance.new("Part"); p.Name=name; p.Size=size; p.CFrame=cf; p.Anchored=true; p.Color=color; p.Material=material or Enum.Material.SmoothPlastic; p.Parent=parent; return p
end
local function sign(parent,text,position,width,height)
 local p=part(parent,"Display",Vector3.new(width or 20,height or 9,.5),CFrame.new(position),Color3.fromRGB(13,23,44))
 local surface=Instance.new("SurfaceGui"); surface.Face=Enum.NormalId.Back; surface.PixelsPerStud=35; surface.Parent=p
 local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.TextColor3=Color3.fromRGB(216,243,255); label.Font=Enum.Font.GothamBold; label.TextScaled=true; label.TextWrapped=true; label.Parent=surface; label.Text=text
 local padding=Instance.new("UIPadding"); padding.PaddingTop=UDim.new(0,12); padding.PaddingBottom=UDim.new(0,12); padding.PaddingLeft=UDim.new(0,12); padding.PaddingRight=UDim.new(0,12); padding.Parent=label
 return label
end
function World:Init()
 local old=workspace:FindFirstChild("Lobby"); if old then old:Destroy() end
 self.Lobby=Instance.new("Folder"); self.Lobby.Name="Lobby"; self.Lobby.Parent=workspace
 self.Zones=Instance.new("Folder"); self.Zones.Name="QueueZones"; self.Zones.Parent=workspace
 self.Arenas=Instance.new("Folder"); self.Arenas.Name="BattleArenas"; self.Arenas.Parent=workspace
 part(self.Lobby,"Plaza",Vector3.new(210,3,190),CFrame.new(0,-2,0),Color3.fromRGB(35,49,69))
 for _,x in ipairs({-95,95}) do part(self.Lobby,"LightRail",Vector3.new(2,1,180),CFrame.new(x,0,0),Color3.fromRGB(60,215,255),Enum.Material.Neon) end
 local spawn=Instance.new("SpawnLocation"); spawn.Name="CentralSpawn"; spawn.Size=Vector3.new(14,1,14); spawn.CFrame=CFrame.new(0,0,25); spawn.Anchored=true; spawn.Neutral=true; spawn.Color=Color3.fromRGB(60,170,220); spawn.Parent=self.Lobby
 sign(self.Lobby,"KANTO ARENA\nBUILD YOUR TEAM • MASTER THE ARENA",Vector3.new(0,17,-78),50,10)
 local order={"Casual1","Casual2","Casual3","Ranked1","Ranked2","Ranked3","Practice"}
 for i,key in ipairs(order) do
  local x=(i-4)*25; local z=-45
  local pad=part(self.Zones,key,Vector3.new(15,1,15),CFrame.new(x,0,z),Config.Modes[key].Ranked and Color3.fromRGB(185,98,255) or Color3.fromRGB(53,210,240),Enum.Material.Neon)
  pad.Shape=Enum.PartType.Cylinder; pad.Size=Vector3.new(1,15,15); pad.CFrame=CFrame.new(x,0,z)*CFrame.Angles(0,0,math.pi/2)
  pad:SetAttribute("Mode",key); self.Pads[key]=Vector3.new(x,0,z)
  self.Screens[key]=sign(self.Lobby,Config.Modes[key].Label.."\n0 / "..(Config.Modes[key].Practice and 1 or Config.Modes[key].Size*2).." PLAYERS\nWalk into the circle",Vector3.new(x,11,z-10),23,13)
 end
 local stations={"Shop","Crates","Collection","Team Builder","Daily Rewards","Player Stats","Leaderboards","Training","Settings"}
 for i,name in ipairs(stations) do
  local side=i<=5 and -1 or 1; local row=i<=5 and i or i-5
  local position=Vector3.new(side*78,0,15+(row-1)*14)
  local base=part(self.Lobby,name,Vector3.new(10,3,9),CFrame.new(position+Vector3.new(0,1,0)),Color3.fromRGB(42,85,110))
  local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="Open"; prompt.ObjectText=name; prompt.HoldDuration=0; prompt.MaxActivationDistance=13; prompt.Parent=base
  prompt.Triggered:Connect(function(player) if self.OnStation then self.OnStation(player,name) end end)
  sign(self.Lobby,name,position+Vector3.new(0,7,-2),12,4)
  if name=="Training" then self.TrainingPosition=position+Vector3.new(-15,0,0) end
 end
 -- Holographic model chambers always load through the central asset resolver.
 for i,id in ipairs({1,4,7,25}) do
  local position=Vector3.new(-45+(i-1)*30,3,74)
  part(self.Lobby,"HologramPedestal",Vector3.new(10,1,10),CFrame.new(position-Vector3.new(0,2,0)),Color3.fromRGB(50,180,200),Enum.Material.Neon)
  local model=Loader:ClonePokemon(id); model:PivotTo(CFrame.new(position)); model.Parent=self.Lobby
 end
 local light=game:GetService("Lighting"); light.ClockTime=14; light.Brightness=2; light.Ambient=Color3.fromRGB(135,150,175)
end
function World:CreateArena(index,size)
 local center=Vector3.new(index*500,0,-650)
 local radius=40+size*15
 local folder=Instance.new("Folder"); folder.Name="Arena_"..index; folder.Parent=self.Arenas
 local theme=(index-1)%#Maps+1
 local map=Maps[theme]
 local custom=game.ServerStorage.Maps:FindFirstChild(map.Name)
 if custom and custom:IsA("Model") then
  local clone=custom:Clone()
  for _,node in ipairs(clone:GetDescendants()) do if node:IsA("LuaSourceContainer") then node:Destroy() end end
  clone:PivotTo(CFrame.new(center)); clone.Parent=folder
 end
 part(folder,"BattleFloor",Vector3.new(radius*2,3,radius*2),CFrame.new(center-Vector3.new(0,2,0)),map.Color)
 for _,x in ipairs({-1,1}) do
  part(folder,"Boundary",Vector3.new(2,18,radius*2),CFrame.new(center+Vector3.new(x*radius,7,0)),Color3.fromRGB(25,35,55))
  part(folder,"Boundary",Vector3.new(radius*2,18,2),CFrame.new(center+Vector3.new(0,7,x*radius)),Color3.fromRGB(25,35,55))
  part(folder,"Cover",Vector3.new(7,5,7),CFrame.new(center+Vector3.new(x*18,1,0)),map.Color:Lerp(Color3.new(1,1,1),.15))
 end
 -- Theme-specific silhouettes stay outside the playable boundary.
 for i=1,8 do
  local angle=i*math.pi/4; local position=center+Vector3.new(math.cos(angle)*(radius+12),4,math.sin(angle)*(radius+12))
  local height=map.Decor=="City" and 18+i%3*7 or map.Decor=="Trees" and 14 or 10
  local column=part(folder,map.Decor,Vector3.new(7,height,7),CFrame.new(position+Vector3.new(0,height/2,0)),map.Color:Lerp(map.Accent,.35))
  if map.Decor=="Clouds" or map.Decor=="Trees" then column.Shape=Enum.PartType.Ball; column.Size=Vector3.new(16,height,16) end
  part(folder,"ThemeLight",Vector3.new(6,.4,6),CFrame.new(position+Vector3.new(0,height+1,0)),map.Accent,Enum.Material.Neon)
 end
 sign(folder,map.Name,center+Vector3.new(0,20,-radius),40,7)
 local actors=Instance.new("Folder"); actors.Name="Fighters"; actors.Parent=folder
 return folder,actors,center,radius
end
return World
