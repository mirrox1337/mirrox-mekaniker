Config                            = {}

Config.DrawDistance               = 10.0
Config.MarkerType                 = 1
Config.MarkerSize                 = { x = 1.5, y = 1.5, z = 0.5 }
Config.MarkerColor                = { r = 255, g = 237, b = 0 }

Config.EnablePlayerManagement     = true
Config.EnableArmoryManagement     = true
Config.EnableESXIdentity          = true -- enable if you're using esx_identity

Config.MaxInService               = -1
Config.Locale                     = 'sv'

Config.NPCSpawnDistance           = 500.0
Config.NPCNextToDistance          = 25.0
Config.NPCJobEarnings             = { min = 150, max = 200 }

Config.Vehicles = {
	'adder',
	'asea',
	'asterope',
	'banshee',
	'buffalo'
}

Config.Stations = {

	Mekonomen = {

		Blip = {
			Coords  = vector3(-351.470, -127.870, 38.010),
			Sprite  = 446,
			Display = 4,
			Scale   = 0.8,
			Colour  = 5
		},

		Cloakrooms = {
			vector3(-347.3, -122.37, 38.010)
		},

		Armories = {
			vector3(-350.34, -124.34, 38.010)
		},

		Vehicles = {
      Blip = {
        Coords  = vector3(-83.29, 6497.01, 31.49),
        Sprite  = 50,
			  Display = 4,
			  Scale   = 0.8,
			  Colour  = 5
      },
			{
				Spawner = vector3(-83.29, 6497.01, 31.49),
				InsideShop = vector3(-67.33, 6496.44, 31.49),
				SpawnPoints = {
					{ coords = vector3(-78.43, 6492.53, 31.47), heading = 218.7, radius = 6.0 },
				}
			},

			{
				Spawner = vector3(-354.95, -128.17, 39.43),
				InsideShop = vector3(228.5, -993.5, -99.0),
				SpawnPoints = {
					{ coords = vector3(-356.4, -115.16, 38.82), heading = 71.26, radius = 6.0 },
					{ coords = vector3(-372.05, -107.24, 38.82), heading = 71.26, radius = 6.0 }
				}
			}
		},

    VehicleDelivery = {
      Pos   = { x = -382.925, y = -133.748, z = 37.685 },
      Size  = { x = 20.0, y = 20.0, z = 3.0 },
      Color = { r = 204, g = 204, b = 0 },
      Type  = -1
    },

		Helicopters = {
			{
				Spawner = vector3(459.4, -983.93, 43.69),
				InsideShop = vector3(477.0, -1106.4, 43.0),
				SpawnPoints = {
					{ coords = vector3(449.5, -981.2, 43.6), heading = 92.6, radius = 10.0 }
				}
			}
		},

		BossActions = {
			vector3(-351.470, -127.870, 38.010)
		}

	}

}

Config.AuthorizedVehicles = {
	Shared = {
    { model = 'flatbed', label = 'Flatbed', price = 50000},
    ---{ model = 'towtruck2', label = 'Bärgare', price = 2500},
    { model = 'veln', label = 'Bil', price = 50000},
	},

	recruit = {},

	novice = {},
  
  experimente = {},

	chef = {},
  
  boss = {},
}

Config.AuthorizedHelicopters = {
	recruit = {},

	novice = {},
  
  experimente = {},

	chef = {},
  
  boss = {},
}

-- CHECK SKINCHANGER CLIENT MAIN.LUA for matching elements

Config.Uniforms = {

      recruit_wear = {
        male = {
          ['tshirt_1'] = 15, ['tshirt_2'] = 0,
          ['torso_1'] = 241, ['torso_2'] = 4,
          ['decals_1'] = 0, ['decals_2'] = 0,
          ['arms'] = 0,
          ['pants_1'] = 98, ['pants_2'] = 25,
          ['shoes_1'] = 71, ['shoes_2'] = 25,
          ['helmet_1'] = -1, ['helmet_2'] = 0,
          ['glasses_1'] = -1, ['glasses_2'] = 0,
          ['chain_1'] = 0, ['chain_2'] = 0,
        },
        female = {
          ['tshirt_1'] = 6, ['tshirt_2'] = 0,
          ['torso_1'] = 249, ['torso_2'] = 5,
          ['decals_1'] = 0, ['decals_2'] = 0,
          ['arms'] = 14,
          ['pants_1'] = 100, ['pants_2'] = 25,
          ['shoes_1'] = 73, ['shoes_2'] = 25,
          ['chain_1'] = 0, ['chain_2'] = 0,
        }
      },

      novice_wear = {
        male = {
          ['tshirt_1'] = 15, ['tshirt_2'] = 0,
          ['torso_1'] = 241, ['torso_2'] = 4,
          ['decals_1'] = 0, ['decals_2'] = 0,
          ['arms'] = 0,
          ['pants_1'] = 98, ['pants_2'] = 25,
          ['shoes_1'] = 71, ['shoes_2'] = 25,
          ['helmet_1'] = -1, ['helmet_2'] = 0,
          ['glasses_1'] = -1, ['glasses_2'] = 0,
          ['chain_1'] = 0, ['chain_2'] = 0,
        },
        female = {
          ['tshirt_1'] = 6, ['tshirt_2'] = 0,
          ['torso_1'] = 249, ['torso_2'] = 5,
          ['decals_1'] = 0, ['decals_2'] = 0,
          ['arms'] = 14,
          ['pants_1'] = 100, ['pants_2'] = 25,
          ['shoes_1'] = 73, ['shoes_2'] = 25,
          ['chain_1'] = 0, ['chain_2'] = 0,
        }
      },

      experienced_wear = {
        male = {
          ['tshirt_1'] = 15, ['tshirt_2'] = 0,
          ['torso_1'] = 241, ['torso_2'] = 4,
          ['decals_1'] = 0, ['decals_2'] = 0,
          ['arms'] = 0,
          ['pants_1'] = 98, ['pants_2'] = 25,
          ['shoes_1'] = 71, ['shoes_2'] = 25,
          ['helmet_1'] = -1, ['helmet_2'] = 0,
          ['glasses_1'] = -1, ['glasses_2'] = 0,
          ['chain_1'] = 0, ['chain_2'] = 0,
        },
        female = {
          ['tshirt_1'] = 6, ['tshirt_2'] = 0,
          ['torso_1'] = 249, ['torso_2'] = 5,
          ['decals_1'] = 0, ['decals_2'] = 0,
          ['arms'] = 14,
          ['pants_1'] = 100, ['pants_2'] = 25,
          ['shoes_1'] = 73, ['shoes_2'] = 25,
          ['chain_1'] = 0, ['chain_2'] = 0,
        }
      },

      chef_wear = {
        male = {
          ['tshirt_1'] = 15, ['tshirt_2'] = 0,
          ['torso_1'] = 241, ['torso_2'] = 4,
          ['decals_1'] = 0, ['decals_2'] = 0,
          ['arms'] = 0,
          ['pants_1'] = 98, ['pants_2'] = 25,
          ['shoes_1'] = 71, ['shoes_2'] = 25,
          ['helmet_1'] = -1, ['helmet_2'] = 0,
          ['glasses_1'] = -1, ['glasses_2'] = 0,
          ['chain_1'] = 0, ['chain_2'] = 0,
        },
        female = {
          ['tshirt_1'] = 6, ['tshirt_2'] = 0,
          ['torso_1'] = 249, ['torso_2'] = 5,
          ['decals_1'] = 0, ['decals_2'] = 0,
          ['arms'] = 14,
          ['pants_1'] = 100, ['pants_2'] = 25,
          ['shoes_1'] = 73, ['shoes_2'] = 25,
          ['chain_1'] = 0, ['chain_2'] = 0,
        }
      },

      boss_wear = {
        male = {
          ['tshirt_1'] = 15, ['tshirt_2'] = 0,
          ['torso_1'] = 241, ['torso_2'] = 5,
          ['decals_1'] = 0, ['decals_2'] = 0,
          ['arms'] = 0,
          ['pants_1'] = 98, ['pants_2'] = 25,
          ['shoes_1'] = 71, ['shoes_2'] = 25,
          ['helmet_1'] = -1, ['helmet_2'] = 0,
          ['glasses_1'] = -1, ['glasses_2'] = 0,
          ['chain_1'] = 0, ['chain_2'] = 0,
        },
        female = {
          ['tshirt_1'] = 6, ['tshirt_2'] = 0,
          ['torso_1'] = 249, ['torso_2'] = 5,
          ['decals_1'] = 0, ['decals_2'] = 0,
          ['arms'] = 14,
          ['pants_1'] = 100, ['pants_2'] = 25,
          ['shoes_1'] = 73, ['shoes_2'] = 25,
          ['chain_1'] = 0, ['chain_2'] = 0,
        }
      }
    }

    Config.Towables = {
      vector3(-2480.9, -212.0, 17.4),
      vector3(-2723.4, 13.2, 15.1),
      vector3(-3169.6, 976.2, 15.0),
      vector3(-3139.8, 1078.7, 20.2),
      vector3(-1656.9, -246.2, 54.5),
      vector3(-1586.7, -647.6, 29.4),
      vector3(-1036.1, -491.1, 36.2),
      vector3(-1029.2, -475.5, 36.4),
      vector3(75.2, 164.9, 104.7),
      vector3(-534.6, -756.7, 31.6),
      vector3(487.2, -30.8, 88.9),
      vector3(-772.2, -1281.8, 4.6),
      vector3(-663.8, -1207.0, 10.2),
      vector3(719.1, -767.8, 24.9),
      vector3(-971.0, -2410.4, 13.3),
      vector3(-1067.5, -2571.4, 13.2),
      vector3(-619.2, -2207.3, 5.6),
      vector3(1192.1, -1336.9, 35.1),
      vector3(-432.8, -2166.1, 9.9),
      vector3(-451.8, -2269.3, 7.2),
      vector3(939.3, -2197.5, 30.5),
      vector3(-556.1, -1794.7, 22.0),
      vector3(591.7, -2628.2, 5.6),
      vector3(1654.5, -2535.8, 74.5),
      vector3(1642.6, -2413.3, 93.1),
      vector3(1371.3, -2549.5, 47.6),
      vector3(383.8, -1652.9, 37.3),
      vector3(27.2, -1030.9, 29.4),
      vector3(229.3, -365.9, 43.8),
      vector3(-85.8, -51.7, 61.1),
      vector3(-4.6, -670.3, 31.9),
      vector3(-111.9, 92.0, 71.1),
      vector3(-314.3, -698.2, 32.5),
      vector3(-366.9, 115.5, 65.6),
      vector3(-592.1, 138.2, 60.1),
      vector3(-1613.9, 18.8, 61.8),
      vector3(-1709.8, 55.1, 65.7),
      vector3(-521.9, -266.8, 34.9),
      vector3(-451.1, -333.5, 34.0),
      vector3(322.4, -1900.5, 25.8)
    }
--[[ Orsakar problem
    for k,v in ipairs(Config.Towables) do
      Config.Stations['Towable' .. k] = {
        Pos   = v,
        Size  = { x = 1.5, y = 1.5, z = 1.0 },
        Color = { r = 204, g = 204, b = 0 },
        Type  = -1
      }
end
--]]