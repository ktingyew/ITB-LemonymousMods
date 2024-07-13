
local mod = modApi:getCurrentMod()
local utils = require(mod.scriptPath .."libs/utils")
local effectBurst = mod.libs.effectBurst
local worldConstants = mod.libs.worldConstants

lmn_ds_PulseRifle = Skill:new{
	Name = "Pulse Rifle",
	Description = "Teleport, and fire a damaging projectile back in the direction you came from. Deals more damage if not firing from smoke or water.",
	Icon = "weapons/ds_pulse_rifle.png",
	Class = "Prime",
	PowerCost = 1,
	Range = INT_MAX,
	BaseDamage = 1,
	LeaveSmoke = false,
	CanFireFromSmoke = true,
	CanFireFromWater = true,
	Push = 0,
	Fire = 0,
	Upgrades = 2,
	UpgradeList = { "Push", "Fire" },
	UpgradeCost = { 1, 2 },
	TipImage = {
		Unit = Point(2,4),
		Mountain = Point(2,3),
		Target = Point(2,1),
		Enemy1 = Point(2,2)
	}
}


lmn_ds_PulseRifle_A = lmn_ds_PulseRifle:new{
	UpgradeDescription = "Pushes target away from you.",
	Push = 1,
}

lmn_ds_PulseRifle_B = lmn_ds_PulseRifle:new{
	UpgradeDescription = "Add fire",
	Fire = 1
}

lmn_ds_PulseRifle_AB = lmn_ds_PulseRifle:new{
	Push = 1,
	Fire = 1
}

function lmn_ds_PulseRifle:GetTargetArea(point)
	local ret = PointList()

	for dir = DIR_START, DIR_END do
		for k = 1, self.Range do
			local curr = point + DIR_VECTORS[dir] * k

			if not Board:IsValid(curr) then
				break
			end

			if
				not Board:IsBlocked(curr, Pawn:GetPathProf())                            and
				(not utils.IsTerrainWaterLogging(curr, Pawn) or self.CanFireFromWater)   and
				not Board:IsItem(curr)                                                   and
				(not Board:IsSmoke(curr) or self.CanFireFromSmoke)
			then
				ret:push_back(curr)
			end
		end
	end

	return ret
end

function lmn_ds_PulseRifle:GetSkillEffect(p1, p2)
	local ret = lmn_ds_Teleport.GetSkillEffect(self, p1, p2, lmn_ds_Teleport)
	local dir = GetDirection(p1 - p2)
	local target = p1
	local final_damage = self.BaseDamage

	for k = 1, self.Range do
		local curr = p2 + DIR_VECTORS[dir] * k

		if Board:IsValid(curr) then
			target = curr
		else
			break
		end

		if target ~= p1 and Board:IsBlocked(target, PATH_PROJECTILE) then
			break
		end
	end

	-- +1 Damage if not in smoke and water
	if 
		Board:GetTerrain(p2) ~= TERRAIN_WATER and 
		not Board:IsSmoke(p2) 
	then
		final_damage = self.BaseDamage + 1
	end

	local projectile = SpaceDamage(target, final_damage)

	-- Push if upgraded
	if self.Push == 1 then
		projectile = SpaceDamage(target, final_damage, dir)
	end

	-- Fire if upgraded
	if self.Fire == 1 then
		projectile.iFire = 1
	end

	projectile.sSound = "/props/electric_smoke_damage"
	projectile.sScript = string.format("Board:AddAnimation(%s, 'ds_explo_plasma', NO_DELAY)", target:GetString())

	ret:AddSound("/impact/generic/tractor_beam")
	ret:AddDelay(0.1)

	local laserDuration = 0.05
	for i = 1, 10 do
		if i < 7 and i % 2 == 0 or i >= 7 then
			ret:AddSound("/props/square_lightup")
		end

		worldConstants:setLaserDuration(ret, laserDuration + 0.05)
		ret:AddProjectile(p2, SpaceDamage(target), "effects/ds_laser", NO_DELAY)
		worldConstants:resetLaserDuration(ret)
		ret:AddDelay(laserDuration)
	end

	ret:AddSound("/weapons/burst_beam")

	local velocity = 1.8
	worldConstants:setSpeed(ret, velocity)
	ret:AddProjectile(p2, projectile, "effects/ds_shot_plasma", NO_DELAY)
	worldConstants:resetSpeed(ret)

	return ret
end
