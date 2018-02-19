require "/scripts/vec2.lua"

function init()
  self.chargeTime = config.getParameter("chargeTime")
  self.boostTime = config.getParameter("boostTime")
  self.boostSpeed = config.getParameter("boostSpeed")
  self.boostForce = config.getParameter("boostForce")
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.fallChance = config.getParameter("fallChance")
  self.riseChance = config.getParameter("riseChance")
  self.mag = config.getParameter("magnitude")
  idle()
  self.available = true
end

function uninit()
  idle()
end

function update(args)
  local jumpActivated = args.moves.jump and not self.lastJump
  self.lastJump = args.moves.jump
  self.stateTimer = math.max(0, self.stateTimer - args.dt)
  if mcontroller.groundMovement() or mcontroller.liquidMovement() then
    if self.state ~= "idle" then
      idle()
    end
    self.available = true
  end
  if self.state == "idle" then
    if jumpActivated and canKazFly() then
      getVector(args, true)
    end
  elseif self.state == "boost" then
	if status.overConsumeResource("energy", self.energyCostPerSecond * args.dt) then
	  mcontroller.controlApproachVelocity(self.boostVelocity, self.boostForce)
	  if canKazFly() then
		getVector(args, false)
	  end
	else
	  idle()
	end
  end
  animator.setFlipped(mcontroller.facingDirection() < 0)
end

function getVector(args, prime)
	if not args.moves.run then
		idle()
		return
	end
	local direction = {0, 0}
    if args.moves.right then
		direction[1] = 1
		if math.random(-1, self.fallChance) == 0 then
			direction[2] = self.mag
		elseif math.random(-1, self.riseChance) == 0 then
			direction[2] = -self.mag
		end
    elseif args.moves.left then
		direction[1] = -1
		if math.random(-1, self.fallChance) == 0 then
			direction[2] = self.mag
		elseif math.random(-1, self.riseChance) == 0 then
			direction[2] = -self.mag
		end
	end
    if args.moves.up or args.moves.jump then
		boost({direction[1], 1}, prime)
    elseif args.moves.down then
		boost({direction[1], -1}, prime)
    elseif vec2.eq(direction, {0, 0}) then
		if math.random(-1, self.fallChance) == 0 then
			boost({0, -self.mag}, prime)
		elseif math.random(-1, self.riseChance) == 0 then
			boost({0, self.mag}, prime)
		else
			boost({0, 0}, prime)
		end
		return
	else
		boost(direction, prime)
	end
end

function canKazFly()
  return self.available
      and not mcontroller.jumping()
      and not mcontroller.canJump()
      and not mcontroller.liquidMovement()
      and not status.statPositive("activeMovementAbilities")
end

function charge()
  self.state = "charge"
  self.stateTimer = self.chargeTime
  self.available = false
  status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  tech.setParentState("fly")
  animator.playSound("charge")
  animator.playSound("chargeLoop", -1)
end

function boost(direction, sound)
  self.state = "boost"
  self.stateTimer = self.boostTime
  self.boostVelocity = vec2.mul(direction, self.boostSpeed)
  tech.setParentState()
  if sound then
	animator.stopAllSounds("charge")
	animator.stopAllSounds("chargeLoop")
	animator.playSound("boost")
  end
end

function idle()
  self.state = "idle"
  self.stateTimer = 0
  status.clearPersistentEffects("movementAbility")
  tech.setParentState()
  animator.stopAllSounds("charge")
  animator.stopAllSounds("chargeLoop")
end
