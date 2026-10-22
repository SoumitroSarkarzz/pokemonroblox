-- One palette for every menu, HUD and elemental effect. Original comic identity.
local Theme={
 Primary=Color3.fromRGB(255,202,61),Secondary=Color3.fromRGB(50,204,232),Accent=Color3.fromRGB(255,97,116),
 Danger=Color3.fromRGB(255,69,93),Success=Color3.fromRGB(104,235,156),Warning=Color3.fromRGB(255,202,61),
 Dark=Color3.fromRGB(12,17,31),Light=Color3.fromRGB(250,247,236),Ranked=Color3.fromRGB(180,123,255),Casual=Color3.fromRGB(50,204,232),
 Panel=Color3.fromRGB(24,32,51),Card=Color3.fromRGB(37,48,69),Muted=Color3.fromRGB(164,182,204),Ink=Color3.fromRGB(7,11,20),
 Fonts={Header=Enum.Font.GothamBlack,Subheader=Enum.Font.GothamBold,Body=Enum.Font.GothamMedium,Stats=Enum.Font.RobotoMono},
 Motion={Open=.25,Close=.16,Hover=.12},
 Graphics={Low={Particles=6,Effects=12,Shadows=false,Ambient=false},Medium={Particles=12,Effects=24,Shadows=true,Ambient=true},High={Particles=22,Effects=36,Shadows=true,Ambient=true}},
 Elements={
  Fire=Color3.fromRGB(255,116,57),Water=Color3.fromRGB(64,181,255),Electric=Color3.fromRGB(255,223,65),Grass=Color3.fromRGB(107,232,117),
  Ice=Color3.fromRGB(151,239,255),Fighting=Color3.fromRGB(240,137,100),Poison=Color3.fromRGB(191,109,241),Ground=Color3.fromRGB(209,167,99),
  Flying=Color3.fromRGB(183,209,255),Psychic=Color3.fromRGB(255,126,199),Bug=Color3.fromRGB(174,215,75),Rock=Color3.fromRGB(185,172,131),
  Ghost=Color3.fromRGB(145,123,221),Dragon=Color3.fromRGB(129,127,255),Dark=Color3.fromRGB(151,141,169),Steel=Color3.fromRGB(182,218,225),
  Fairy=Color3.fromRGB(255,179,229),Normal=Color3.fromRGB(236,220,182),
 },
}
Theme.Background=Theme.Dark; Theme.Text=Theme.Light; Theme.Gold=Theme.Primary
return Theme
