local Loader=require(script.Parent.PokemonModelLoader)
local Settings=require(script.Parent.PokemonModelSettings)
local Viewport={}; Viewport.__index=Viewport
function Viewport.new(frame) return setmetatable({Frame=frame},Viewport) end
function Viewport:Clear()
 if self.World then self.World:Destroy(); self.World=nil end
 if self.Camera then self.Camera:Destroy(); self.Camera=nil end
 self.Model=nil
end
function Viewport:SetCamera(distance)
 if not self.Model then return end
 local cf,size=self.Model:GetBoundingBox()
 local center=cf.Position
 self.Camera.CFrame=CFrame.lookAt(center+Vector3.new(distance*.65,distance*.3,distance),center)
 self.Camera.FieldOfView=40
end
function Viewport:DisplayPokemon(frame,id)
 self.Frame=frame or self.Frame; self:Clear()
 self.World=Instance.new("WorldModel"); self.World.Parent=self.Frame
 self.Model=Loader:ClonePokemon(id)
 if not self.Model then return end
 self.Model.Parent=self.World; self.Model:PivotTo(CFrame.new())
 self.Camera=Instance.new("Camera"); self.Camera.Parent=self.Frame; self.Frame.CurrentCamera=self.Camera
 self.Frame.Ambient=Color3.fromRGB(190,200,230); self.Frame.LightDirection=Vector3.new(-1,-1,-1)
 local _,size=self.Model:GetBoundingBox()
 self:SetCamera(math.max(Settings[id].CameraDistance,size.Magnitude))
end
function Viewport:RotateModel(angle)
 if self.Model then self.Model:PivotTo(CFrame.Angles(0,angle or .03,0)*self.Model:GetPivot()) end
end
return Viewport
