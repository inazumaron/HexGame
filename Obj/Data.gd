extends Node

const CharacterNames = ["Enna", "Millie", "Reimu", "Nina"]
const AltarNames = ["Enna", "Millie", "Reimu", "Nina", "Finana", "Pomu", "Elira"]

#For now, default starting actions available to player
var PlayerActions = ["A1"]
var PlayerActionDetails = {
	"A1":{"meta":{"name":"adjStab", "code":"A1D"}}
}
var SkillData = {
	'Def_Lunge':{
		'description': 'Moving towards an enemy will attack them'
	},
	'Def_Leap':{
		'description': 'Jumps 2-3 tiles to any direction'
	},
	'Def_Defend':{
		'description': 'Blocks 1 damage for 1 turn'
	},
	'Enna_Fly' : {
		'description': 'Tap self to fly. While flying, cant be attacked by melee attacks and cant attack.'
	},
	'Enna_shuriken': {
		'description': 'When moving to an adjacent tile from besides an enemy, attacks with shuriken.'
	},
	'Enna_Wings': {
		'description': 'Pushes away enemies in the front 3 tiles with her wings'
	},
	'Millie_Broom': {
		'description': 'Flies in a straight line, if it hits an enemy, pushes enemy back'
	},
	'Millie_Potion': {
		'description': 'Throws a potion at an enemy and affects an area. Enemy takes damage in 2 turns'
	},
	'Millie_Scratch': {
		'description': 'When moving to an adjacent tile from besides an enemy, claws enemy.'
	},
	'Nina_Tail': {
		'description': 'When moving to an adjacent tile, uses tail to damage enemy'
	},
	'Nina_Intoxicate':{
		'description': 'Spills wine in the adjacent tiles, intoxicating enemies that step on it'
	},
	'Nina_Swap':{
		'description': 'Switches place with an enemy within 3 tiles'
	},
	'Reimu_Slap':{
		'description': 'When moving to an adjacent tile, slaps enemy'
	},
	'Reimu_Ghost':{
		'description': 'Sends ghost hat to an enemy to attack. Needs to be picked up to do again'
	},
	'Reimu_Blink':{
		'description': 'Teleports to an unoccupied tile within 2 tiles'
	}
}
var DefSkills = [
	'Def_Lunge', 'Def_Leap', 'Def_Defend'
]
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

func GetSkillFromData(data, exclude := []):
	var skills = SkillData.keys()
	var choices = []
	#Remove excluded
	for skill in exclude:
		skills.erase(skill)
	#Get character skills available
	for skill in skills:
		if skill.find(data) != -1:
			choices.append(skill)
	
	#Randomly remove skills
	while len(choices) > 3:
		choices.remove(randi()%len(choices))
	
	skills = DefSkills.duplicate()
	while len(choices) < 3:
		#add default skills here
		var n = randi()%len(skills)
		choices.append(skills[n])
		skills.remove(n)
	return choices

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

#================================  Idea dump for content ========================
#Skill list not yet made
# Enna
#   - stay away - P - when landing from flight, pushes enemy away
# Millie
#   - potion master - P - potions take less time to take effect
# Reimu
#   - slap - A1
#   - posses - A4
#	   - switch - A3
#   - blink - A2
#   - ethereal - P - after blinking, become ethereal for the turn (ignores damage)
# Nina
#   - tail whip - A1
#   - swap - A4
#   - intoxicate - A3
#   - fire?? - P - when swapping, leaves fire
# Pomu
#   - Im pomu - A4 - switches place with adj enemy, enemyh becomes leaves
#   - Forest fairy - P - when doing actions besides movement, leaves leaves on prev tile (if moved, else curr tile)
#   - 
# Default
#   - lunge - P
#      - pierce - P 
#   - defend - A3
#      - parry - A3 - blocks first attack and attacks back
#   - leap - A2
#      - ground pound
#   - gaslight - A4 - big stun to enemy
#      - charm - make enemy into ally
