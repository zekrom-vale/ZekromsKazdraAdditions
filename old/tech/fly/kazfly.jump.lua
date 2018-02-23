require "/scripts/vec2.lua"
require "/tech/doubletap.lua"

function init()
  self.chargeTime = config.getParameter("chargeTime")
  self.boostTime = config.getParameter("boostTime")
  self.boostSpeed = config.getParameter("boostSpeed")
  self.boostForce = config.getParameter("boostForce")
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.fallChance = config.getParameter("fallChance")
  self.upChance = config.getParameter("upChance")
  idle()
  self.available = true
  self.doubleTap = DoubleTap:new({"jumping"}, 0.25, idles())
  self.Clock = 0
  self.run = false
end

function idles()
	idle()
	self.run = true
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
	  self.Clock = -100
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
	if self.Clock >= 0 then
		self.doubleTap:update(args.dt, args.moves)
		if self.run == true then
			return
		end
	else
		DoubleTap:reset()
		self.Clock = self.Clock + 1
		self.run = false
	end
	if not args.moves.run then
		DoubleTap:reset()
		idle()
		return
	end
	--[[ Jump off
	if not prime then
		local Jump = args.moves["jump"] and not self.lastJump2
		self.lastJump2 = args.moves["jump"]
		self.Clock = 1 + self.Clock
		if self.Clock >= 0 then
			if self.Clock >= 8 then
				self.Clock = 0
				self.lastJump2 = false
			elseif Jump then
				idle()
				return
			end
		end
	end
	--]]
	local direction = {0, 0}
    if args.moves["right"] then
		direction[1] = 1
		if math.random(0, self.fallChance) == 1 then
			direction[2] = 0.4
		elseif math.random(0, self.upChance) == 1 then
			direction[2] = -0.4
		end
    elseif args.moves["left"] then
		direction[1] = -1
		if math.random(0, self.fallChance) == 1 then
			direction[2] = 0.4
		elseif math.random(0, self.upChance) == 1 then
			direction[2] = -0.4
		end
	end
    if args.moves["up"] or args.moves["jump"] then
		direction[2] = 1
    elseif args.moves["down"] then
		direction[2] = -1
    elseif vec2.eq(direction, {0, 0}) then
		if math.random(0, self.fallChance) == 1 then
			direction = {0, -0.1}
		elseif math.random(0, self.upChance) == 1 then
			direction = {0, 0.1}
		else
			direction = {0, 0}
		end
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
