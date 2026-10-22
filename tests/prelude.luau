local modules={}
local refs=setmetatable({},{__index=function(_,k) return k end})
local script={Parent=refs}
local function require(key) assert(modules[key],"Missing mock module "..tostring(key)); return modules[key] end
local clock=1000
local realOs=os
local os={time=realOs.time,clock=function() return clock end}
local Vector3={}
local vectorMeta={}
vectorMeta.__index=function(v,key)
 if key=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
 if key=="Unit" then return v/v.Magnitude end
 if key=="Dot" then return function(a,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
end
function Vector3.new(x,y,z) return setmetatable({X=x,Y=y,Z=z,__type="Vector3"},vectorMeta) end
vectorMeta.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vectorMeta.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vectorMeta.__unm=function(a) return a*-1 end
vectorMeta.__mul=function(a,b) if type(a)=="number" then a,b=b,a end; return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
vectorMeta.__div=function(a,b) return a*(1/b) end
Vector3.zero=Vector3.new(0,0,0); Vector3.one=Vector3.new(1,1,1)
local builtinTypeof=typeof
local function typeof(v) return type(v)=="table" and v.__type or builtinTypeof(v) end
local CFrame={}
function CFrame.lookAt(position,at)
 local direction=(at-position).Unit
 local right=Vector3.new(-direction.Z,0,direction.X)
 return {Position=position,LookVector=direction,PointToObjectSpace=function(_,p)
  local d=p-position; return Vector3.new(d:Dot(right),d.Y,-d:Dot(direction))
 end}
end
function CFrame.new(x,y,z) local p=type(x)=="table" and x or Vector3.new(x or 0,y or 0,z or 0); return CFrame.lookAt(p,p+Vector3.new(0,0,-1)) end
local RaycastParams={new=function() return {} end}
local Enum={RaycastFilterType={Exclude=1},Material={Air=1}}
local Color3={fromRGB=function(...) return {...} end}
local Random={new=function()
 local seed=7189
 return {NextNumber=function(_,lo,hi) seed=(seed*16807)%2147483647; return lo+(hi-lo)*seed/2147483647 end,
 NextInteger=function(self,lo,hi) return math.min(hi,math.floor(self:NextNumber(lo,hi+1))) end}
end}
local pending={}
local task={spawn=function(fn) table.insert(pending,fn) end,delay=function(_,fn) table.insert(pending,fn) end,wait=function(dt) clock+=dt or .03 end}
local records={}
local mockFailure=false
local storeOpenFailure=true
local storeOpens=0
local orderedStoreOpens=0
local studio=false
local mockMode=false
local store={UpdateAsync=function(_,key,fn)
 if mockFailure then error("DataStore offline") end
 local record=records[key]
 local updated=fn(record)
 if updated then records[key]=updated; return updated end
 return nil
end}
local game={JobId="test-job",ReplicatedStorage={Shared=refs},Players={GetPlayers=function() return {} end},GetService=function(_,name)
 if name=="DataStoreService" then return {GetDataStore=function()
  storeOpens+=1
  if storeOpenFailure then error("You must publish this place to access DataStore") end
  return store
 end,GetOrderedDataStore=function() orderedStoreOpens+=1; error("No live API in test") end} end
 if name=="RunService" then return {IsStudio=function() return studio end} end
 if name=="HttpService" then return {GenerateGUID=function() return "test-id" end} end
 return {}
end}
local wall=false
local workspace={GetAttribute=function() return mockMode end,Raycast=function(_,origin,delta) if wall then return {Position=origin+delta*.5} end end}
local function flush()
 local batch=pending; pending={}
 for _,fn in ipairs(batch) do fn() end
end
local function warn(...) end
local passed=0
local function check(value,message) assert(value,message); passed+=1 end
