-- Server timing, damage, range and colliders never come from client input.
return {
 Basic={Name="Strike",Kind="Melee",Damage=7,Cooldown=.34,Range=7,Startup=.09,Active=.1,Endlag=.2,HitboxSize=Vector3.new(6,6,7),Knockback=10,Stun=.18},
 Pulse={Name="Type Pulse",Kind="Projectile",Damage=12,Cooldown=3,Range=65,Startup=.2,Active=.1,Endlag=.25,HitboxSize=Vector3.new(4,4,4),Knockback=12,Stun=.25,ProjectileSpeed=85},
 Rush={Name="Rush",Kind="Dash",Damage=9,Cooldown=6,Range=17,Startup=.12,Active=.18,Endlag=.3,HitboxSize=Vector3.new(6,6,12),Knockback=25,Stun=.4},
 Ward={Name="Guard Field",Kind="Shield",Damage=0,Cooldown=10,Range=0,Startup=.15,Active=2,Endlag=.2,HitboxSize=Vector3.new(1,1,1),Knockback=0,Stun=0,StatusEffects={Shield=2}},
 Nova={Name="Signature Nova",Kind="AOE",Damage=24,Cooldown=18,Range=14,Startup=.65,Active=.15,Endlag=.7,HitboxSize=Vector3.new(28,12,28),Knockback=35,Stun=.7},
}
