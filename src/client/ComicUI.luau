local Tween=game:GetService("TweenService")
local Theme=require(game.ReplicatedStorage.Shared.UITheme)
local Audio=require(script.Parent.SoundController)
local Comic={}
function Comic.Make(class,parent,props)
 local node=Instance.new(class)
 for key,value in pairs(props or {}) do node[key]=value end
 node.Parent=parent; return node
end
local make=Comic.Make
function Comic.Stroke(node,color,width)
 return make("UIStroke",node,{Color=color or Theme.Light,Thickness=width or 1.5,Transparency=.15,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
end
function Comic.Text(parent,value,pos,size,fontSize,color)
 local label=make("TextLabel",parent,{Text=value,Position=pos,Size=size,BackgroundTransparency=1,Font=(fontSize or 15)>=22 and Theme.Fonts.Header or Theme.Fonts.Body,TextSize=fontSize or 15,TextColor3=color or Theme.Light,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,TextStrokeColor3=Theme.Ink,TextStrokeTransparency=.65})
 make("UITextSizeConstraint",label,{MinTextSize=10,MaxTextSize=fontSize or 15})
 return label
end
function Comic.Decorate(node,accent)
 if node:FindFirstChild("ComicBorder") then return end
 local border=Comic.Stroke(node,accent or Theme.Light); border.Name="ComicBorder"
 make("UIGradient",node,{Rotation=110,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Theme.Card),ColorSequenceKeypoint.new(1,Theme.Dark)})})
 local strip=make("Frame",node,{Name="ComicStripe",Size=UDim2.new(0,5,1,0),BackgroundColor3=accent or Theme.Primary,BorderSizePixel=0,ZIndex=node.ZIndex}); strip.Rotation=1
 local slash=make("Frame",node,{Name="ComicCutout",Position=UDim2.new(1,-24,0,-4),Size=UDim2.fromOffset(27,9),Rotation=24,BackgroundColor3=accent or Theme.Primary,BorderSizePixel=0,ZIndex=node.ZIndex})
end
function Comic.Pop(node,scale)
 local scaler=node:FindFirstChild("ComicScale")
 if not scaler then scaler=make("UIScale",node,{Name="ComicScale",Scale=1}) end
 local base=node:GetAttribute("BaseScale") or 1
 scaler.Scale=base*(scale or 1.08)
 Tween:Create(scaler,TweenInfo.new(.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=base}):Play()
end
function Comic.Button(parent,value,pos,size,callback,color)
 local b=make("TextButton",parent,{Text=string.upper(value),Position=pos,Size=size,BackgroundColor3=color or Theme.Card,TextColor3=Theme.Light,Font=Theme.Fonts.Subheader,TextSize=14,AutoButtonColor=false,BorderSizePixel=0})
 local stroke=Comic.Stroke(b,Theme.Muted,1)
 local scale=make("UIScale",b,{Name="ComicScale",Scale=1})
 make("UITextSizeConstraint",b,{MinTextSize=10,MaxTextSize=14})
 local last=-1
 b.MouseEnter:Connect(function()
  Audio:Play("Hover"); stroke.Color=Theme.Primary
  Tween:Create(scale,TweenInfo.new(.12),{Scale=1.035}):Play(); Tween:Create(b,TweenInfo.new(.12),{Rotation=-1.2}):Play()
 end)
 b.MouseLeave:Connect(function()
  stroke.Color=Theme.Muted; Tween:Create(scale,TweenInfo.new(.12),{Scale=1}):Play(); Tween:Create(b,TweenInfo.new(.12),{Rotation=0}):Play()
 end)
 b.Activated:Connect(function()
  if os.clock()-last<.18 then return end; last=os.clock()
  Audio:Play("Click"); Comic.Pop(b,.93); callback()
 end)
 return b
end
function Comic.Stagger(parent)
 local index=0
 for _,node in ipairs(parent:GetChildren()) do
  if node:IsA("TextLabel") or node:IsA("TextButton") then
   index+=1; local target=node.TextTransparency; node.TextTransparency=1
   local tween=Tween:Create(node,TweenInfo.new(.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,math.min(index*.015,.12)),{TextTransparency=target})
   tween:Play()
  end
 end
end
return Comic
