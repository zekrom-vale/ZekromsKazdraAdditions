require "/scripts/vec2.lua"

function init()
  self.chargeTime = config.getParameter("chargeTime")
  self.boostTime = config.getParameter("boostTime")
  self.boostSpeed = config.getParameter("boostSpeed")
  self.boostForce = config.getParameter("boostForce")
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.fallChance = config.getParameter("fallChance")
  self.upChance = config.getParameter("upChance")
  defineFall()
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
  --Detect ground Movement or liquid Movement
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
    if args.moves["right"] then
		direction[1] = 1
		direction[2] = fall()
    elseif args.moves["left"] then
		direction[1] = -1
		direction[2] = fall()
	end
    if args.moves["up"] or args.moves["jump"] then
		direction[2] = 2
    elseif args.moves["down"] then
		direction[2] = -2
    elseif vec2.eq(direction, {0, 0}) then
		boost({0, fall()}, prime)
	end
	boost(direction, prime)
end

function defineFall()
	if self.fallChance == 0 and self.upChance == 0 then
		fall = function ()
			return 0
		end
	else
		fall = function ()
			if math.random(0, self.fallChance) == 1 then
				return -0.1
			elseif math.random(0, self.upChance) == 1 then
				return 0.1
			else
				return 0
			end
		end
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
