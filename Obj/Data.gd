extends Node

const CharacterNames = ["Enna", "Millie", "Reimu", "Nina"]
const AltarNames = ["Enna", "Millie", "Reimu", "Nina", "Finana", "Pomu", "Elira"]

#For now, default starting actions available to player
var PlayerActions = ["A1"]
var PlayerActionDetails = {
	"A1":{"meta":{"name":"adjStab", "code":"A1D"}}
}

#Enemy List details: level - minimum level before it can appear. cost determines how difficult they are
#In regards to 'difficulty' this increases cost and lowers minimum level of enemies
# moveA - move for melee units, moveB - move for ranged units
var EnemyList = {
	"Aloupeep" : {"level":1, "cost":1, 
		"Actions":["A1","A4"], "ActionDetails":{
			"A1":{"meta":{"name":"moveA","code":"A1D"}},
			"A4":{"meta":{"name":"stab","code":"A4D"}}
		}},
	"Phantomos" : {"level":2, "cost":2,
		"Actions":["A1","A4"], "ActionDetails":{
			"A1":{"meta":{"name":"moveB","code":"A1D"}},
			"A4":{"meta":{"name":"shoot","code":"A4D"}}
		}},
	"Famillie" : {"level":3, "cost":3,
		"Actions":["A1","A4"], "ActionDetails":{
			"A1":{"meta":{"name":"moveB","code":"A1D"}},
			"A4":{"meta":{"name":"fireLine","code":"A4D"}}
		}},
}

func GetRandomName(exclude := []):
	var tempName = AltarNames[randi()%len(AltarNames)]
	while (tempName in exclude):
		tempName = AltarNames[randi()%len(AltarNames)]
	return tempName

#========== To do list when you dont know what to do
#-- features/ revamp
		#stairs work
		#altar UI
		#altar works (not skills)
#-- bugs
#		

#====================================================================================================
#------------------this portion will be dedicated to compiling the formats of complex objects---------
#-----------------------------for the sake of having a one all ez ref --------------------------------

#	Character Related
#	Actions - will only consist of "An" where n = [1,2,3,4]
#		A1 - Adjacent, unoccupied tile action, usually for movement
#		A2 - Non Adjacent, unoccupied tile action, ranged attack consisting
#			the 6 lines spread out (in betweens for easier comp, will be outside range)
#		A3 - Own tile, actions that dont involve outside factors, can be wait, heal, etc
#		A4 - Occupied tiles, can be non adjacent. For actions that needs a target to do
#
#	ActionDetails - will contain details for the actions, dictionary with key being the action code above
#		{ "An" : { details here } }
#		Details:
#			meta - contains generic data for general use
#				- name - name of move
#				- code - mainly will be "AnD" for easier packaging
#			tileDetails - contains mapHandler needed details, mainly for activating tiles
#				- range - min range as distance from user
#				- maxRange
#				- wallValid/ lavaValid - if can apply to wall/lava tiles
#				- behindWall/ behindLava - if above valid, see if range goes also behind the tiles
#			actionDetails - contains levelHandler needed details, to be updated

#	Level Related
#	LevelData - contains basic data on the level

#	MapHandler Related
#	ValidCoords - a lite version of NodeMap, contains the possible coordinates/keys
#	NodeMap - a dictionary containing every tile nodes, addressed by their coordinates
#		- content:
#			-node - contains link to the tile object itself
#			-type - path/lava/wall
#			-addOn - null/foilage/fire
#			-addOnData - things like { timer : int } // depracated, timer will be handled by objects themselves
#			-struct - null/stairs/altar
#			-structData - for altar uses
#			-occupied - enemy/player/misc (misc -> player things)
#			-NW/NE/HE/SE/SW/HW - corners pointing to next tileObj or null
#			-pathValueA - for melee heatmap value
#			-pathValueB - for ranged heatmap
