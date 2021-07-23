
---------------------------------------------------------------------
-- Selected v1.2 - code library
--[[-----------------------------------------------------------------
	
]]
local path = mod_loader.mods[modApi.currentMod].scriptPath
local getModUtils = require(path .."getModUtils")
local this = {}

sdlext.addGameExitedHook(function()
	this.selected = nil
end)

function this:Get()
	return self.selected
end

function this:load()
	local modUtils = getModUtils()
	
	modUtils:addPawnSelectedHook(function(_, pawn)
		self.selected = pawn
	end)
	
	modUtils:addPawnDeselectedHook(function(_, pawn)
		self.selected = nil
	end)
	
	modApi:addTestMechEnteredHook(function()
		modApi:runLater(function()
			for id = 0, 2 do
				self.selected = Board:GetPawn(id)
				if self.selected then
					break
				end
			end
		end)
	end)
	
	modApi:addTestMechExitedHook(function()
		self.selected = nil
	end)
end

return this