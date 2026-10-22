-- Exercise the real bootstrap with a failed input controller and an immediate
-- profile response. The profile must load independently of PlayerModule readiness.
local profile={Coins=0}
local UI={Stats={Text="Connecting"},Init=function() end,Toast=function() end}
function UI:ProfileChanged(value) self.Profile=value end
local clientCallback
local signal={Connect=function(_,fn) clientCallback=fn end}
local state={OnClientEvent=signal}
local requested=0
local intent={FireServer=function(_,action)
 if action=="Ready" then
  requested+=1
  assert(clientCallback,"Ready sent before state listener was attached")
  clientCallback("Profile",profile)
 end
end}
local remotes={WaitForChild=function(_,name) return name=="Intent" and intent or state end}
local replicated={WaitForChild=function() return remotes end,GetAttribute=function() return nil end,
 GetAttributeChangedSignal=function() return {Connect=function() end} end}
local game={ReplicatedStorage=replicated,GetService=function() return {} end}
local warnings=0
local function warn() warnings+=1 end
local refs=setmetatable({},{__index=function(_,key) return key end})
local script={Parent=refs}
local controllers={UIController=UI,InputController={Init=function() error("PlayerModule unavailable") end},
 CameraController={Init=function() end},VFXController={Init=function() end},CreatureController={Init=function() end}}
local function require(key) return assert(controllers[key],key) end
local task={spawn=function(fn) fn() end,wait=function() end,delay=function() end}
local function run()
-- BOOTSTRAP --
end
run()
assert(UI.Profile==profile,"Controller failure prevented profile loading")
assert(requested==1,"Profile response did not finish handshake")
assert(warnings==1,"Failed input controller was not diagnosed")
print("PASS: client profile handshake survives unavailable PlayerModule/controller failure")
