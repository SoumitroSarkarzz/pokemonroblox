local Adapter={}; Adapter.__index=Adapter
function Adapter.new(model)
 local self=setmetatable({Model=model,Tracks={},Failed={}},Adapter)
 local controller=model:FindFirstChildWhichIsA("Humanoid",true) or model:FindFirstChildWhichIsA("AnimationController",true)
 if not controller then controller=Instance.new("AnimationController"); controller.Parent=model end
 self.Animator=controller:FindFirstChildOfClass("Animator") or Instance.new("Animator",controller)
 return self
end
function Adapter:GetRoot() return self.Model.PrimaryPart end
function Adapter:GetAnimator() return self.Animator end
function Adapter:GetBoundingBox() return self.Model:GetBoundingBox() end
function Adapter:GetHitboxOrigin() return self:GetRoot().CFrame end
function Adapter:SetFacingDirection(direction)
 if direction.Magnitude>.01 then local p=self.Model:GetPivot().Position; self.Model:PivotTo(CFrame.lookAt(p,p+direction)) end
end
function Adapter:PlayAnimation(animation)
 if animation and animation:IsA("Animation") and animation.AnimationId~="" then
  local id=animation.AnimationId
  if self.Failed[id] then return nil end
  local track=self.Tracks[id]
  if not track then
   local ok,result=pcall(function() return self.Animator:LoadAnimation(animation) end)
   if not ok then self.Failed[id]=true; warn("[Animation] Unavailable animation; using procedural fallback"); return nil end
   track=result; self.Tracks[id]=track
  end
  track:Play(.1); return track
 end
 return nil -- CreatureController supplies procedural movement when tracks are absent.
end
function Adapter:SetVisible(visible)
 for _,part in ipairs(self.Model:GetDescendants()) do if part:IsA("BasePart") then part.LocalTransparencyModifier=visible and 0 or 1 end end
end
function Adapter:Destroy()
 for _,track in pairs(self.Tracks) do track:Stop(0); track:Destroy() end
 table.clear(self.Tracks)
end
return Adapter
