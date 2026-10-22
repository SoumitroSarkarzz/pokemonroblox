local function path(node, ...)
 for _,name in ipairs({...}) do node=assert(node:FindFirstChild(name),name..' missing') end
 return node
end
local root=fs.read('build/KantoArena.rbxlx')
local replicated=root:FindFirstChild('ReplicatedStorage')
assert(replicated,'ReplicatedStorage missing')
local pokemon=replicated:FindFirstChild('Pokemon')
assert(#path(pokemon,'Models'):GetChildren()==151,'Wrong slot count')
for index,slot in ipairs(path(pokemon,'Models'):GetChildren()) do
 assert(slot:GetAttribute('PokemonID')==index,'Attribute serialization failed')
 assert(slot:GetAttribute('Region')=='Kanto','String attribute serialization failed')
 assert(slot:GetAttribute('ReadyForBattle')==true,'Boolean attribute serialization failed')
 assert(path(slot,'ModelSlot','PlaceholderModel').PrimaryPart~=nil,'Placeholder has no root')
 assert(#path(slot,'Animations'):GetChildren()==22,'Wrong animation slot count')
 assert(#path(slot,'Sounds'):GetChildren()==8,'Wrong sound slot count')
 assert(#path(slot,'VFX'):GetChildren()==4,'Wrong VFX slot count')
 assert(path(pokemon,'Icons'):FindFirstChild(slot.Name),'Missing icon slots')
end
assert(path(root,'Workspace'):GetAttribute('UseMockData')==true,'Studio mock flag missing')
assert(path(root,'ServerScriptService','Services','Bootstrap').Source~='','Server entry missing')
assert(path(root,'StarterPlayer','StarterPlayerScripts','Controllers','Bootstrap').Source~='','Client entry missing')
local sources=0
for _,node in ipairs(root:GetDescendants()) do
 if node.ClassName=='ModuleScript' or node.ClassName=='Script' or node.ClassName=='LocalScript' then sources=sources+1 end
end
assert(sources==31,'Lost embedded sources')
fs.write('build/KantoArena.rbxl',root)
local binary=fs.read('build/KantoArena.rbxl')
assert(#path(binary,'ReplicatedStorage','Pokemon','Models'):GetChildren()==151,'Binary round trip failed')
print('PASS: Roblox XML decoded; 151 asset trees and attributes verified; binary place round trip passed')
