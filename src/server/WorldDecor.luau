-- Additive art pass. Decorations are non-colliding/non-queryable; gameplay pads,
-- covers, boundaries and service interfaces remain in WorldService.
local Collection=game:GetService("CollectionService")
local Lighting=game:GetService("Lighting")
local Theme=require(game.ReplicatedStorage.Shared.UITheme)
local Loader=require(game.ReplicatedStorage.Shared.PokemonModelLoader)
local Decor={}
local function block(parent,name,size,position,color,material,collision)
 local part=Instance.new("Part"); part.Name=name; part.Size=size; part.CFrame=typeof(position)=="CFrame" and position or CFrame.new(position); part.Anchored=true
 part.Color=color; part.Material=material or Enum.Material.SmoothPlastic; part.CanCollide=collision==true; part.CanTouch=false; part.CanQuery=collision==true; part.CastShadow=false; part.Parent=parent
 return part
end
local function group(parent,name)
 local model=Instance.new("Model"); model.Name=name; model.Parent=parent; return model
end
local function animate(node,kind,speed)
 node:SetAttribute("AmbientMotion",kind); node:SetAttribute("MotionSpeed",speed or .3); node:SetAttribute("BasePivot",node:IsA("Model") and node:GetPivot() or node.CFrame)
 Collection:AddTag(node,"ArenaAmbient")
end
local function screen(parent,title,position,size,color)
 local frame=block(parent,"InformationScreen",size or Vector3.new(20,7,.5),position,Theme.Ink)
 local gui=Instance.new("SurfaceGui"); gui.Face=Enum.NormalId.Back; gui.PixelsPerStud=30; gui.Parent=frame
 local text=Instance.new("TextLabel"); text.Size=UDim2.fromScale(1,1); text.BackgroundTransparency=1; text.Text=title; text.TextColor3=color or Theme.Primary; text.Font=Theme.Fonts.Header; text.TextScaled=true; text.Parent=gui
 local constraint=Instance.new("UITextSizeConstraint"); constraint.MaxTextSize=60; constraint.MinTextSize=14; constraint.Parent=text
 return text
end
local function pillar(parent,pos,height,color)
 block(parent,"StructuralColumn",Vector3.new(2,height,2),pos+Vector3.new(0,height/2,0),Theme.Card)
 block(parent,"ColumnLight",Vector3.new(.3,height-2,2.1),pos+Vector3.new(0,height/2,0),color,Enum.Material.Neon)
end
local function bench(parent,pos)
 block(parent,"BenchSeat",Vector3.new(10,1,3),pos+Vector3.new(0,2,0),Theme.Card)
 for _,x in ipairs({-4,4}) do block(parent,"BenchLeg",Vector3.new(1,2,2),pos+Vector3.new(x,1,0),Theme.Muted) end
 block(parent,"BenchBack",Vector3.new(10,3,.6),pos+Vector3.new(0,3.5,1.2),Theme.Panel)
end
local function plant(parent,pos)
 block(parent,"Planter",Vector3.new(4,2,4),pos+Vector3.new(0,1,0),Theme.Card)
 local bush=block(parent,"Foliage",Vector3.new(5,5,5),pos+Vector3.new(0,4,0),Theme.Elements.Grass); bush.Shape=Enum.PartType.Ball
end
local function npc(parent,name,pos)
 local model=group(parent,name)
 local body=block(model,"Coat",Vector3.new(2.5,3.5,1.4),pos+Vector3.new(0,3.3,0),Theme.Secondary)
 block(model,"Head",Vector3.new(1.8,1.8,1.8),pos+Vector3.new(0,6,0),Theme.Light).Shape=Enum.PartType.Ball
 block(model,"Visor",Vector3.new(1.6,.5,.15),pos+Vector3.new(0,6,-.9),Theme.Ink)
 for _,x in ipairs({-.7,.7}) do block(model,"Boot",Vector3.new(.9,1.6,1),pos+Vector3.new(x,.9,0),Theme.Panel) end
 model.PrimaryPart=body; model:SetAttribute("DecorativeNPC",true); animate(model,"Patrol",.3)
end
local function room(parent,name,center,color,width,depth)
 width=width or 58; depth=depth or 44
 local model=group(parent,name)
 block(model,"DistrictFloor",Vector3.new(width,.25,depth),center+Vector3.new(0,-.45,0),Theme.Panel)
 for _,x in ipairs({-1,1}) do
  pillar(model,center+Vector3.new(x*(width/2-2),0,-depth/2),20,color)
  pillar(model,center+Vector3.new(x*(width/2-2),0,depth/2),20,color)
  block(model,"CanopyRail",Vector3.new(2,1,depth),center+Vector3.new(x*(width/2-2),20,0),color,Enum.Material.Neon)
 end
 block(model,"RearWall",Vector3.new(width,15,.6),center+Vector3.new(0,7,-depth/2),Theme.Card)
 screen(model,string.upper(name),center+Vector3.new(0,16,-depth/2+.5),Vector3.new(width-6,5,.5),color)
 for i=-2,2 do block(model,"FloorSeam",Vector3.new(1,.04,depth-5),center+Vector3.new(i*9,-.27,0),color) end
 return model
end
function Decor.Lobby(parent,stations,onStation)
 local folder=Instance.new("Folder"); folder.Name="FacilityDetails"; folder.Parent=parent
 for _,z in ipairs({-25,35,90}) do
  block(folder,"WayfindingLane",Vector3.new(310,.12,1.2),Vector3.new(0,-.25,z),Theme.Secondary,Enum.Material.Neon)
 end
 for _,x in ipairs({-62,62}) do block(folder,"MainWalkway",Vector3.new(2,.15,205),Vector3.new(x,-.23,0),Theme.Primary) end
 screen(folder,"ARENA / LEAGUE\nBUILD • BATTLE • BELONG",Vector3.new(0,24,5),Vector3.new(34,10,1),Theme.Primary)
 local holo=Loader:ClonePokemon(151); holo.Name="CentralHologram"; holo:ScaleTo(holo:GetScale()*2.5); holo:PivotTo(CFrame.new(0,10,0)); holo.Parent=folder
 for _,part in ipairs(holo:GetDescendants()) do if part:IsA("BasePart") then part.Material=Enum.Material.Neon; part.Transparency=.3; part.Color=Theme.Secondary end end
 animate(holo,"FloatSpin",.35)
 local dais=block(folder,"CentralDais",Vector3.new(2,24,24),CFrame.new(0,.3,0)*CFrame.Angles(0,0,math.pi/2),Theme.Card); dais.Shape=Enum.PartType.Cylinder
 for _,pos in ipairs({Vector3.new(-35,0,25),Vector3.new(35,0,25),Vector3.new(-35,0,55),Vector3.new(35,0,55)}) do bench(folder,pos); plant(folder,pos+Vector3.new(10,0,0)) end
 for _,entry in ipairs({{"SHOP DISTRICT","Shop",Theme.Primary},{"CRATE LAB","Crates",Theme.Ranked},{"CREATURE ARCHIVE","Collection",Theme.Secondary},{"TEAM MANAGEMENT","Team Builder",Theme.Success},{"TRAINING FACILITY","Training",Theme.Accent},{"LEADERBOARD HALL","Leaderboards",Theme.Primary}}) do
  local position=stations[entry[2]]
  local building=room(folder,entry[1],position,entry[3],entry[2]=="Leaderboards" and 85 or 58,44)
  npc(building,entry[2]=="Shop" and "Shopkeeper" or "FacilityGuide",position+Vector3.new(-18,0,8))
  plant(building,position+Vector3.new(20,0,13))
  if entry[2]=="Crates" then
   block(building,"ContainmentPlatform",Vector3.new(16,1,14),position+Vector3.new(0,1,-7),Theme.Ranked,Enum.Material.Neon)
   for _,x in ipairs({-1,1}) do
    local arm=group(building,"RewardArm")
    block(arm,"Support",Vector3.new(2,10,2),position+Vector3.new(x*10,6,-7),Theme.Card)
    block(arm,"Arm",Vector3.new(10,1.5,2),position+Vector3.new(x*6,11,-7),Theme.Muted)
    animate(arm,"Swing",.7)
   end
   local crate=block(building,"ResearchCrate",Vector3.new(5,5,5),position+Vector3.new(0,5,-7),Theme.Primary); animate(crate,"FloatSpin",.4)
   Collection:AddTag(crate,"CrateChamber")
  elseif entry[2]=="Team Builder" then
   for i=1,3 do
    local pad=block(building,"TeamPlinth"..i,Vector3.new(12,1,12),position+Vector3.new((i-2)*16,.6,-6),Theme.Success,Enum.Material.Neon)
    pad:SetAttribute("TeamSlot",i); Collection:AddTag(pad,"ArenaTeamPreviewPad")
   end
  elseif entry[2]=="Collection" then
   for i=1,5 do screen(building,string.format("KANTO DATABASE\n%03d / 151\nARCHIVE ONLINE",i*25),position+Vector3.new((i-3)*10,7,-20),Vector3.new(8,8,.4),Theme.Secondary) end
  elseif entry[2]=="Leaderboards" then
   for i,key in ipairs({"MMR","Wins","BestWinStreak"}) do
    local label=screen(building,string.upper(key).."\nSEASON 01\nCONNECTING TO LEAGUE",position+Vector3.new((i-2)*26,7,-18),Vector3.new(24,12,.5),Theme.Primary)
    label:SetAttribute("LeaderboardKey",key); Collection:AddTag(label,"ArenaLeaderboard")
   end
  elseif entry[2]=="Training" then
   for i=1,4 do
    local target=group(building,"PracticeTarget")
    local body=block(target,"Target",Vector3.new(4,5,1),position+Vector3.new((i-2.5)*10,4,-12),Theme.Accent)
    block(target,"Bullseye",Vector3.new(2,2,.3),body.Position+Vector3.new(0,0,.7),Theme.Primary)
    target.PrimaryPart=body; animate(target,"Slide",.5+i*.1)
   end
   screen(building,"COMBO LAB / AIM RANGE\nDAMAGE • DPS • LONGEST COMBO\nUSE TERMINAL TO START",position+Vector3.new(0,11,-20),Vector3.new(48,6,.5),Theme.Accent)
  end
 end
 -- Movement course and raised social walkway stay outside queue entry paths.
 for i=1,6 do block(folder,"MovementStep",Vector3.new(9,1,9),Vector3.new(-155+i*11,1+i*.6,125),Theme.Card,nil,true) end
 block(folder,"SocialWalkway",Vector3.new(65,1,14),Vector3.new(105,5,140),Theme.Card,nil,true)
 for _,z in ipairs({133,147}) do block(folder,"WalkwayRail",Vector3.new(65,2,.5),Vector3.new(105,7,z),Theme.Secondary) end
 for i=1,4 do
  local fan=group(folder,"VentilationFan")
  local position=Vector3.new(-60+i*25,21,-125)
  block(fan,"Blade",Vector3.new(8,.6,1),position,Theme.Muted)
  block(fan,"Blade",Vector3.new(1,.6,8),position,Theme.Muted)
  animate(fan,"Spin",1)
 end
 local bloom=Lighting:FindFirstChild("ArenaBloom") or Instance.new("BloomEffect",Lighting); bloom.Name="ArenaBloom"; bloom.Intensity=.15; bloom.Size=16; bloom.Threshold=1.4
 local correction=Lighting:FindFirstChild("ArenaGrade") or Instance.new("ColorCorrectionEffect",Lighting); correction.Name="ArenaGrade"; correction.Contrast=.08; correction.Saturation=.12
 local atmosphere=Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere",Lighting); atmosphere.Density=.18; atmosphere.Haze=.6
 -- Capability guarded: newer Studio versions can manage Lighting technology.
 pcall(function() Lighting.Technology=Enum.Technology.Future end)
 return folder
end
function Decor.Arena(parent,center,radius,map)
 local folder=Instance.new("Folder"); folder.Name="ArenaDetails"; folder.Parent=parent
 for _,side in ipairs({-1,1}) do
  for tier=1,3 do
   block(folder,"SpectatorStand",Vector3.new(radius*1.65,3,6),center+Vector3.new(0,tier*3,side*(radius+8+tier*6)),Theme.Card)
   if map.Decor=="Trees" then
    for i=-4,4 do
     local head=block(folder,"Audience",Vector3.new(1.5,2,1.5),center+Vector3.new(i*radius/6,tier*3+3,side*(radius+8+tier*6)),i%2==0 and Theme.Secondary or Theme.Primary); head.Shape=Enum.PartType.Ball
    end
   end
  end
  screen(folder,"KANTO LEAGUE\n"..string.upper(map.Name),center+Vector3.new(side*radius*.65,22,-radius-22),Vector3.new(30,10,1),map.Accent)
 end
 for i=1,16 do
  local a=i/16*math.pi*2
  local p=center+Vector3.new(math.cos(a)*(radius+1),1,math.sin(a)*(radius+1))
  block(folder,"BoundaryBeacon",Vector3.new(1.2,4,1.2),p,map.Accent,Enum.Material.Neon)
 end
 if map.Decor=="Lava" then
  block(folder,"LavaBasin",Vector3.new(radius*3,1,radius*3),center+Vector3.new(0,-12,0),Theme.Elements.Fire,Enum.Material.Neon)
  for i=1,5 do
   local p=center+Vector3.new((i-3)*30,12,-radius-30)
   block(folder,"Lavafall",Vector3.new(3,40,2),p,Theme.Elements.Fire,Enum.Material.Neon)
  end
 elseif map.Decor=="Pillars" then
  for _,x in ipairs({-1,1}) do
   for j=1,4 do pillar(folder,center+Vector3.new(x*(radius+12),0,(j-2.5)*22),22,Theme.Elements.Ice) end
  end
  for i=1,6 do
   local ice=block(folder,"FrozenSpire",Vector3.new(8,30+i*3,8),center+Vector3.new((i-3.5)*23,9,-radius-45),Theme.Elements.Ice,Enum.Material.Ice); ice.CFrame*=CFrame.Angles(0,0,.1)
  end
 elseif map.Decor=="City" then
  for i=1,8 do
   local x=(i-4.5)*24
   local tower=block(folder,"Skyline",Vector3.new(18,30+i%3*12,18),center+Vector3.new(x,15,-radius-48),Theme.Panel)
   screen(folder,i%2==0 and "BATTLE / LIVE" or "LEAGUE 01",tower.Position+Vector3.new(0,7,10),Vector3.new(12,7,.4),map.Accent)
  end
  local traffic=block(folder,"DistantTraffic",Vector3.new(8,1.5,3),center+Vector3.new(0,-6,-radius-30),Theme.Primary,Enum.Material.Neon); animate(traffic,"Slide",.7)
 elseif map.Decor=="Ruins" then
  for i=1,8 do
   local a=i/8*math.pi*2; local p=center+Vector3.new(math.cos(a)*(radius+19),0,math.sin(a)*(radius+19))
   pillar(folder,p,10+i%3*4,map.Accent); plant(folder,p+Vector3.new(3,0,0))
  end
  block(folder,"ReflectingPool",Vector3.new(radius*2,1,20),center+Vector3.new(0,-4,-radius-25),Theme.Elements.Water,Enum.Material.Glass)
 elseif map.Decor=="Clouds" then
  for i=1,6 do
   local cloud=block(folder,"CloudBank",Vector3.new(28,12,20),center+Vector3.new((i-3.5)*35,-6,-radius-25),Theme.Light); cloud.Shape=Enum.PartType.Ball; animate(cloud,"FloatSpin",.06)
  end
  local airship=group(folder,"Airship"); local hull=block(airship,"Hull",Vector3.new(35,12,14),center+Vector3.new(0,40,-radius-60),Theme.Secondary); hull.Shape=Enum.PartType.Ball; airship.PrimaryPart=hull; animate(airship,"Slide",.12)
 end
end
return Decor
