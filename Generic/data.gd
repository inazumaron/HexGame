extends Node

# This node is for containing various data information such as level templates
# enemy stats and so on. This also is meant to keep track of current player stats, upgrades, etc
# which needs to carry over levelhandlers

#Map template format for easier handling
# 2 digits, 1st digit = fixed level - 1, random room template - 2-9
# 2nd digit levels/variations 0-9
#Data meaning - data will all be Vector3, the 1st vector3 will dictate:
# (x,y,z)	x - # of lava, y - # of walls, z - # of altars, last entry will always be coord of stairs
const MapTemplates = {
	"10" : [Vector3(0,0,1), Vector3(-3,0,3), Vector3(4,0,-4)],
	"11" : [Vector3(3,2,0), Vector3(2,-2,0), Vector3(1,-2,1), Vector3(0,-2,2), Vector3(-1,-2,3), 
	Vector3(1,1,-2), Vector3(-4,4,0)],
	"12" : [Vector3(0,0,1), Vector3(2,-2,0), Vector3(0,-3,3)]
}
#Map coordinates for easy visualizing (with flat top hex)
#TL - (1,0,-1), TR - (1,-1,0)
#ML - (0,1,-1), MR - (0,-1,1)
#BL - (-1,1,0), BR - (-1,0,1)
#notes, player can start at center, stairs at edge, altar at opposite edge

#for numbering same format as above. But for non fixed maps, format is different
# fixed map: [[string - type, vector3 - coord] ... ]
# templates: [vector3 - coord ... ]
# number of enemies can be acquired from the number of elements in data, for templates, enemy type
# can be randomly decided on 
const EnemyData = {
	"10" : [["grunt", Vector3(-2,2,0)], ["grunt", Vector3(-1,0,1)]],
	"11" : [["",Vector3(2,-3,1)], ["grunt",Vector3(0,2,-2)], ["grunt",Vector3(-2,1,1)]],
	"12" : []
}

#Player related stats
var playerWalkableVals = [1,4]	#values based on tileTypes, mainly just add 2 if can go over lava
