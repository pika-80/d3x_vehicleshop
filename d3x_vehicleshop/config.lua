Config                            = {}
Config.DrawDistance               = 50.0
Config.MarkerColor                = { r = 255, g = 0, b = 0 }
Config.EnableOwnedVehicles        = true
Config.ResellPercentage           = 5

Config.Locale                     = 'br'

Config.LicenseEnable = false -- require people to own drivers license when buying vehicles? Only applies if EnablePlayerManagement is disabled. Requires esx_license

-- looks like this: 'LLL NNN'
-- The maximum plate length is 8 chars (including spaces & symbols), don't go past it!
Config.PlateLetters  = 2
Config.PlateNumbers  = 4
Config.PlateUseSpace = true

Config.Zones = {
	
	ShopEntering = {
		Pos = vector3(-56.835, -1098.817, 26.415),
		Heading = 22.677 -- ou o heading que quiseres para o NPC
	},
	
	ShopOutside = {
		Pos   = { x = -31.898, y = -1080.626, z = 26.634 },
		Size  = { x = 1.5, y = 1.5, z = 1.0 },
		Heading = 68.031,
		Type  = -1
	},

	TestDrive = {
		Pos   = { x = -20.215, y = -1113.599, z = 26.668 }, 
		Size  = { x = 1.5, y = 1.5, z = 1.0 },
		Heading = 161.574,
		Type  = -1
	},

	ResellVehicle = {
		Pos   = { x = -44.439, y = -1081.704, z = 26.668},
		Size  = { x = 2.4, y = 2.4, z = 1.0 },
	--	Heading = 239.13,
		Type  = 1
	}

}
