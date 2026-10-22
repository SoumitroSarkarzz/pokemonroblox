local Database = require(script.Parent.PokemonDatabase)
local settings = {}
for id in pairs(Database) do
 settings[id] = {Scale=1,GroundOffset=0,RotationOffset=Vector3.new(0,0,0),CameraDistance=9,HitboxSize=Vector3.new(4,5,4),RootOffset=Vector3.new(0,0,0),TargetHeight=4.5}
end
return settings
