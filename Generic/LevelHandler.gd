extends Node2D

var hexInst = preload("res://Instructions.gd").new()
const MapBase = preload("res://Generic/MapHandler.tscn")
const CharBase = preload("res://Generic/Character.tscn")
const MapSize = 8
var activeMap
var playerChar
var playerPrevCoord : Vector3
var enemyList = []
var objMap = {}		#Dictionary containing character/enemies with their coord as keys
var deadKeys = []	#To contain dead enemies after player action been processed
var processTimer := 0.0
var processMode := 0 #Determines what process do
# 0 - awaiting player input
# 1 - enemy damage delay

#-----------------------------level specific variables
var enemyCount = 2
var enemyCoords = [Vector3(-2,2,0), Vector3(-1,0,1)]
var floorLevel = 1

func _ready():
	set_process(false)
	GenerateMap()
	GeneratePlayer()
	GenerateEnemies()
	StartTurn()

func GenerateMap() -> void:
	var temp_map = MapBase.instance()
	temp_map.mapSize = MapSize
	temp_map.z_index = 0
	add_child(temp_map)
	activeMap = temp_map

func GeneratePlayer() -> void:
	var temp_char = CharBase.instance()
	temp_char.z_index = 1
	temp_char.maxHp = 3
	temp_char.gHp = 3
	add_child(temp_char)
	temp_char.play("Calli_Idle_right")
	playerChar = temp_char
	objMap[str(playerChar.hexCoord)] = playerChar

func GenerateEnemies() -> void:
	for i in range(0,enemyCount):
		var temp_char = CharBase.instance()
		temp_char.z_index = 1
		temp_char.bodyType = "enemy"
		temp_char.hexCoord = enemyCoords[i]
		temp_char.position = hexInst.Cube2Coord(enemyCoords[i])
		add_child(temp_char)
		temp_char.play("Zombie_Idle")
		enemyList.append(temp_char)
		objMap[str(enemyCoords[i])] = temp_char

func StartTurn() -> void:
	activeMap.DeactivateTiles()
	activeMap.newValue = false
	var active_tiles = GetActiveTiles()
	activeMap.ActivateTiles(active_tiles)
	processMode = 0
	set_process(true)

func _process(delta): #for monitoring clicked tiles
	if processMode == 0:	#Awaiting player action
		if activeMap.newValue:
			CharAction()
	
	if processMode == 3:	#Player moving, dont mind numbering, its the order when added
		if processTimer > 0:
			processTimer -= delta
		else:
			processMode = -1
			processTimer = 0
			ProcessAction()
	
	if processMode == 1:	#Player attacking enemies
		if processTimer > 0 and deadKeys.size() > 0:
			processTimer -= delta
		else:
			processTimer = 1
			if deadKeys.size() > 0:
				DamageEnemy()
			else:
				processMode = 2
				processTimer = 0.5
	
	if processMode == 2:	#Enemy attacking
		if processTimer > 0:
			processTimer -= delta
		else:
			processMode = -1
			EnemyAction()
	
	if Input.is_action_just_pressed("ui_accept"):
		print(objMap)

func CharAction():
	processMode = -1
	var temp_val = activeMap.tileValue
	#If action is move (i.e tile clicked is adjacent to player)
	playerPrevCoord = playerChar.hexCoord
	objMap.erase(str(playerChar.hexCoord))
	playerChar.hexCoord = temp_val
	#playerChar.position = hexInst.Cube2Coord(temp_val)
	objMap[str(playerChar.hexCoord)] = playerChar
	activeMap.GenerateHeatMap(temp_val)
	
	processTimer = 1
	playerChar.MovePos(playerPrevCoord - temp_val)
	processMode = 3

func ProcessAction(action_code := 0):
	#action_code is what player did
	
	#Probably move assesment of action here or pass action_code from CharAction to global var
	
	# 0 - default moving to a tile
	if action_code == 0:
		#Check for mutually adjacent enemies
		var temp_mutual_adj = hexInst.MutualAdjacent(playerChar.hexCoord, playerPrevCoord)
		if temp_mutual_adj.size() > 0:
			for temp_index in temp_mutual_adj:
				if str(temp_index) in objMap:
					playerChar.MoveDir(temp_index - playerChar.hexCoord)
					if objMap[str(temp_index)].bodyType == "enemy":
						objMap[str(temp_index)].Damage()
	
	#remove dead enemies before enemy takes a turn
	deadKeys = []
	for temp_obj in objMap:
		if objMap[temp_obj].gHp <= 0:
			deadKeys.append(temp_obj)
	processMode = 1
	processTimer = 0.5

func EnemyAction() -> void:
	#Iterate through enemy list
	for enemy in enemyList:
		if enemy.attackType:
			RangedEnemyAction(enemy)
		else:
			MeleeEnemyAction(enemy)
	EndTurn()

func RangedEnemyAction(temp_enemy):
	#check if player in range
	if activeMap.tileNodes[str(temp_enemy.hexCoord)]["node"].pathValueAlt == 0:
		#attack player code here
		pass
	else:
		var e_path = activeMap.GetEnemyPath(temp_enemy.hexCoord,1)
		var path_available = false
		var new_path = Vector3.ZERO
		var prev_coord = temp_enemy.hexCoord
		
		for path in e_path:
			if !(str(path) in objMap):
				path_available = true
				new_path = path
				break
		
		if path_available:
			objMap.erase(str(temp_enemy.hexCoord))
			objMap[str(new_path)] = temp_enemy
			temp_enemy.hexCoord = new_path
			temp_enemy.MovePos(prev_coord - new_path)

func MeleeEnemyAction(temp_enemy):
	var coord_check = hexInst.GetAdjacent(temp_enemy.hexCoord)
	
	#Check if player nearby, attack else move
	var player_nearby := false
	for coord in coord_check:
		if str(coord) in objMap:
			if objMap[str(coord)].bodyType == "player":
				player_nearby = true
	#Attack
	if player_nearby:
		temp_enemy.MoveDir(playerChar.hexCoord - temp_enemy.hexCoord)
		playerChar.Damage()
	#move
	else:
		var e_path = activeMap.GetEnemyPath(temp_enemy.hexCoord,0,-1)
		var path_available = false
		var new_path = Vector3.ZERO
		var prev_coord = temp_enemy.hexCoord
		
		for path in e_path:
			if !(str(path) in objMap):
				path_available = true
				new_path = path
				break
		
		if path_available:
			objMap.erase(str(temp_enemy.hexCoord))
			objMap[str(new_path)] = temp_enemy
			temp_enemy.hexCoord = new_path
			temp_enemy.MovePos(prev_coord - new_path)

func DamageEnemy() -> void:
	var temp_dead_key = deadKeys.pop_back()
	var temp_enemy = objMap[temp_dead_key]
	objMap[temp_dead_key].queue_free()
	objMap.erase(temp_dead_key)
	enemyList.erase(temp_enemy)

func EndTurn():
	StartTurn()

func GetActiveTiles() -> Array:
	var char_pos = playerChar.hexCoord
	var active_tiles = []
	#get movement tiles
	for t_dir in hexInst.cubeDirectionVectors:
		var temp_vec = char_pos + t_dir
		if temp_vec in activeMap.validCoords:
			if !objMap.has(str(temp_vec)):
				active_tiles.append(temp_vec)
	#get skill tiles
	#filter for occupied spaces/ invalid terrains
	return active_tiles
