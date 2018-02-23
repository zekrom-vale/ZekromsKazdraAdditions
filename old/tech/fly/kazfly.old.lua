require "/scripts/vec2.lua"

function init()
  self.chargeTime = config.getParameter("chargeTime")
  self.boostTime = config.getParameter("boostTime")
  self.boostSpeed = config.getParameter("boostSpeed")
  self.boostForce = config.getParameter("boostForce")
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.fallChance = config.getParameter("fallChance")
  self.upChance = config.getParameter("upChance")
  self.defaultDirection = {
	config.getParameter("defaultDirection")[1],
	config.getParameter("defaultDirection")[2]
  }
  idle()
  self.available = true
end

function uninit()
  idle()
end

function update(args)
  local jumpActivated = args.moves["jump"] and not self.lastJump
  self.lastJump = args.moves["jump"]
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
	if canKazFly() then
      getVector(args, false)
	end
	if status.overConsumeResource("energy", self.energyCostPerSecond * args.dt) then
	  mcontroller.controlApproachVelocity(self.boostVelocity, self.boostForce)
	else
	  idle()
	end
  end
  animator.setFlipped(mcontroller.facingDirection() < 0)
end

function getVector(args, prime)
	local direction = {0, 0}
    if args.moves["right"] then
		direction[1] = direction[1] + 1
		if math.random(0, self.fallChance) == 1 then
			direction[2] = direction[2] - 1/10
		elseif math.random(0, self.upChance) == 1 then
			direction[2] = direction[2] + 1/10
		end
	end
    if args.moves["left"] then
		direction[1] = direction[1] - 1
		if math.random(0, self.fallChance) == 1 then
			direction[2] = direction[2] - 1/10
		elseif math.random(0, self.upChance) == 1 then
			direction[2] = direction[2] + 1/10
		end
	end
    if args.moves["up"] then
		direction[2] = direction[2] + 1
		
	end
    if args.moves["down"] then
		direction[2] = direction[2] - 1
	end

    if vec2.eq(direction, {0, 0}) then
		if self.defaultDirection[2] == 0 then 
			if math.random(0, self.fallChance) == 1 then
				direction = {0, -1/10}
			elseif math.random(0, self.upChance) == 1 then
				direction = {0, 1/10}
			else
				direction = self.defaultDirection
			end
		else
			direction = self.defaultDirection
		end
	end
	if not args.moves.run then
		idle()
		return
	end
	if args.moves["jump"] then
		direction[2] = direction[2] + 1
	end
	boost(direction, prime)
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
  self.boostVelocity = vec2.mul(vec2.norm(direction), self.boostSpeed)
  tech.setParentState()
  if sound then
	animator.stopAllSounds("charge")
	animator.stopAllSounds("chargeLoop")
	animator.playSound("boost")
  end
  --activeItem.setFrontArmFrame(self.stance.frontArmFrame)
  --activeItem.setBackArmFrame(self.stance.backArmFrame)
end

function idle()
  self.state = "idle"
  self.stateTimer = 0
  status.clearPersistentEffects("movementAbility")
  tech.setParentState()
  animator.stopAllSounds("charge")
  animator.stopAllSounds("chargeLoop")
end
