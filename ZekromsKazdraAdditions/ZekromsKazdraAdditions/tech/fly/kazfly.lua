require "/scripts/vec2.lua"

function init()
	self={
		chargeTime=config.getParameter("chargeTime",0.5),
		boostTime=config.getParameter("boostTime",0.25),
		boostSpeed=config.getParameter("boostSpeed",20),
		boostForce=config.getParameter("boostForce",500),
		energyCostPerSecond=config.getParameter("energyCostPerSecond",15),
		fallChance=config.getParameter("fallChance",-1),
		riseChance=config.getParameter("riseChance",-1),
		mag=config.getParameter("magnitude",0.4),
		mode={nil,nil},
		space=config.getParameter("space",false),
		available=true
	}
	idle()
end

function uninit()	idle()	end

function update(args)
	local jumpActivated=args.moves.jump and not self.lastJump
	self.lastJump=args.moves.jump
	self.stateTimer=math.max(0, self.stateTimer-args.dt)
	if mcontroller.groundMovement()or mcontroller.liquidMovement()then
		if self.state then	idle()	end
		self.available=true
	end
	if not self.state and jumpActivated and canKazFly()then
		getVector(args)
		animator.stopSounds("charge","chargeLoop")
		animator.playSound("boost")
	elseif self.state=="boost"then
		local factor=FIF(self.mode[2]==0,
			function()return fif(self.mode[1]==0,0.5,0.7)end,
			function()return FIF(self.mode[2]==1,
				function()return fif(self.mode[1]==0,1,1.2)end,
				function()return FIF(self.mode[2]==-1,
					function()return fif(self.mode[1]==0,0.35,0.5)end,
					function()return fif(vec2.eq(self.mode,{nil,nil}),0,1)end
				)end
			)end
		)
		if status.overConsumeResource("energy",self.energyCostPerSecond*factor*args.dt)then
			mcontroller.controlApproachVelocity(self.boostVelocity,self.boostForce)
			if canKazFly()then	getVector(args)	end
		else
			idle()
		end
	end
	animator.setFlipped(mcontroller.facingDirection()<0)
end

function FIF(c,t,f)
	if c then	return t()	end
	return f()
end
function fif(c,t,f)
	if c then	return t	end
	return f
end

function getVector(args)
	if not args.moves.run then
		idle()
		return
	end
	local direction,self={0,0},self
	if args.moves.right or args.moves.left then
		direction={
			fif(args.moves.right,1,-1),
			FIF(rand0(self.fallChance),
				function()return self.mag end,
				function()return fif(rand0(self.riseChance),-self.mag,direction[2])end
			)
		}
	end
	if args.moves.up or args.moves.jump then
		direction[2]=1
	elseif args.moves.down then
		direction[2]=-1
	elseif vec2.eq(direction,{0,0}) then
		direction={
			0,
			FIF(rand0(self.fallChance),
				function()return -self.mag end,
				function()return fif(rand0(self.riseChance),self.mag,0)end
			)
		}
	end
	self.mode=vec2.norm(direction)
	boost(direction)
end

function rand0(a)
	return math.random(-1,a)==0
end

function canKazFly()
	return self.available and not(
		mcontroller.jumping() or
		mcontroller.canJump() or
		mcontroller.liquidMovement() or
		status.statPositive("activeMovementAbilities") or
		airLess()
	)
end

function airLess()
	if self.space then	return	end
	return listContains(world.environmentStatusEffects(entity.position()),"biomeairless")
end

function listContains(arr,v)
	for _,i in pairs(arr)do
		if i==v then	return true	end
	end
end

function charge()
	self.state="charge"
	self.stateTimer=self.chargeTime
	self.available=false
	status.setPersistentEffects("movementAbility", {{stat="activeMovementAbilities", amount=1}})
	--tech.setParentState("Fly")
	animator.playSound("charge")
	animator.playSound("chargeLoop",-1)
end

function boost(direction)
	self.state="boost"
	self.stateTimer=self.boostTime
	self.boostVelocity=vec2.mul(direction, self.boostSpeed)
	--tech.setParentState("Fly")
end

function idle()
	self.state=nil
	self.mode={nil,nil}
	self.stateTimer=0
	status.clearPersistentEffects("movementAbility")
	tech.setParentState()
	animator.stopSounds("charge","chargeLoop")
end

if animator==nil then
	animator={}
end

function animator.stopSounds(...)
	for _,v in ipairs(arg)do
		animator.stopAllSounds(v)
	end
end