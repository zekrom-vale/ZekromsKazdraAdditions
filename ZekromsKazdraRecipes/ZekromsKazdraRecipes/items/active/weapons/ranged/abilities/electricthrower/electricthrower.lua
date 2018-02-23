require "/items/active/weapons/ranged/gunfire.lua"

ElectricthrowerAttack = GunFire:new()

function ElectricthrowerAttack:init()
  GunFire.init(self)

  self.active = false
end

function ElectricthrowerAttack:update(dt, fireMode, shiftHeld)
  GunFire.update(self, dt, fireMode, shiftHeld)

  if self.weapon.currentAbility == self then
    if not self.active then self:activate() end
  elseif self.active then
    self:deactivate()
  end
end

function ElectricthrowerAttack:muzzleFlash()
  --disable normal muzzle flash
end

function ElectricthrowerAttack:activate()
  self.active = true
  animator.playSound("fireStart")
  animator.playSound("fireLoop", -1)
end

function ElectricthrowerAttack:deactivate()
  self.active = false
  animator.stopAllSounds("fireStart")
  animator.stopAllSounds("fireLoop")
  animator.playSound("fireEnd")
end
