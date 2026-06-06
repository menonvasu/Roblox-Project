local FORCE_MULTIPLIER = 0.2

return {
	Damping = 0.15,
	Stiffness = 0.1,
	Inertia = 0.3,
	Elasticity = 0.05,
	BlendWeight = 1,
	Radius = 0.1,
	AnchorDepth = 1,
	
	-- Environmental Forces
	Force = Vector3.yAxis * FORCE_MULTIPLIER,
	Gravity = -Vector3.yAxis,
	
	-- Wind Dynamics
	WindDirection = -Vector3.xAxis,
	WindSpeed = 12,
	WindStrength = 0.5,
	WindInfluence = 1,
	
	AnchorsRotate = true,
	UpdateRate = 60,
	ActivationDistance = 45,
	ThrottleDistance = 15,
}