extends Node2D

var hexInst = preload("res://Instructions.gd").new()
const MapBase = preload("res://Generic/MapHandler.tscn")
const CharBase = preload("res://Generic/Character.tscn")
const ObjBase = preload("res://Generic/Object.tscn")
const MapSize = 8
const AltarOffset = Vector2(0, -16)
var activeMap
var playerChar
var playerPrevCoord : Vector3
var playerStartCoord := Vector3(2,-1,-1)
var enemyList = []
var objMap = {}		#Dictionary containing character/enemies with their coord as keys
var terMap = {}		#Dictionary containing terrain objects with coord as keys (fire)
var dooMap = {}		#Dictionary containing doodad ocjects (altar and stairs) with coord as keys
var deadKeys = []	#To contain dead enemies after player action been processed
var processTimer := 0.0
var processMode := 0 #Determines what process do
# 0 - awaiting player input
# 1 - enemy damage delay
var levelVal = "11"		#to send to data for getting specific level data
var levelValAlt = Vector2(1,1)
#-----------------------------level specific variables
var floorLevel = 1

func _ready():
	set_process(false)
	GenerateMap()
	GeneratePlayer()
	GenerateEnemies()
	# getting/adding map doodads
	var level_data = Data.MapTemplates[levelVal][0]
	dooMap[str(Data.MapTemplates[levelVal][-1])] = "stairs"
	
	if level_data.z > 0:
		for i in range(level_data.x + level_data.y + 1, level_data.x + level_data.y + level_data.z + 1):
			var temp_doodad = ObjBase.instance()
			temp_doodad.objType = "doodad"
			temp_doodad.position = hexInst.Cube2Coord(Data.MapTemplates[levelVal][i]) + AltarOffset
			add_child(temp_doodad)
			temp_doodad.Play("altar")
			dooMap[Data.MapTemplates[levelVal][i]] = temp_doodad
	
	StartTurn()

func GenerateMap() -> void:
	var temp_map = MapBase.instance()
	temp_map.level = levelVal
	temp_map.mapSize = MapSize
	temp_map.z_index = 0
	add_child(temp_map)
	activeMap = temp_map

func GeneratePlayer() -> void:
	var temp_char = CharBase.instance()
	temp_char.hexCoord = playerStartCoord
	temp_char.z_index = 1
	temp_char.maxHp = 3
	temp_char.gHp = 3
	temp_char.position = hexInst.Cube2Coord(playerStartCoord)
	add_child(temp_char)
	temp_char.play("Enna_a")
	playerChar = temp_char
	objMap[str(playerChar.hexCoord)] = playerChar

func GenerateEnemies() -> void:
	var enemy_count = Data.EnemyData[levelVal].size()
	for i in range(0,enemy_count):
		var temp_char = CharBase.instance()
		temp_char.z_index = 1
		temp_char.bodyType = "enemy"
		temp_char.hexCoord = Data.EnemyData[levelVal][i][1]
		temp_char.position = hexInst.Cube2Coord(temp_char.hexCoord)
		add_child(temp_char)
		SetEnemyStats(temp_char,Data.EnemyData[levelVal][i][0])
		enemyList.append(temp_char)
		objMap[str(temp_char.hexCoord)] = temp_char

func SetEnemyStats(enemy : Node2D, type : String) -> void : 
	var temp_stats = hexInst.EnemyStats[type]
	
	enemy.play(type)
	
	if "shield" in temp_stats:
		enemy.gShield = temp_stats["shield"]
	if "aType" in temp_stats:
		enemy.attackType = temp_stats["aType"]
	if "aCD" in temp_stats:
		enemy.attackCooldown = temp_stats["aCD"]
	if "aPrep" in temp_stats:
		enemy.attackPrep = temp_stats["aPrep"]

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
	print("tv ",temp_val)
	if str(temp_val) in dooMap:
		if dooMap[str(temp_val)] == "stairs":
			pass
		else: #altar
			pass
		print()
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
		if enemy.attackType > 0:
			RangedEnemyAction(enemy)
		else:
			MeleeEnemyAction(enemy)
	EndTurn()

func RangedEnemyAction(temp_enemy):
	#check if player in range
	if activeMap.tileNodes[str(temp_enemy.hexCoord)]["node"].pathValueAlt == 0:
		if temp_enemy.attackType == 1:
			if RangedCheckInBetween(playerChar.hexCoord, temp_enemy.hexCoord):
				playerChar.Damage()
				var temp_proj = ObjBase.instance()
				temp_proj.position = temp_enemy.position
				temp_proj.finalPos = playerChar.position
				add_child(temp_proj)
				temp_proj.set_process(true)
		elif temp_enemy.attackType == 2:
			#Mage
			if RangedCheckInBetween(playerChar.hexCoord, temp_enemy.hexCoord):
				var temp_data = {
					"coord_e" : temp_enemy.hexCoord,
					"coord_p" : playerChar.hexCoord,
					"value" : 1
				}
				MiscAttackHandler("famillie", temp_data)
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

func RangedCheckInBetween(coord_e : Vector3, coord_p : Vector3) -> bool:
	#Checks if there are any objects in between the two points
	#checks for coors stored in objMap
	var slope = coord_p - coord_e
	var dir = slope/(max(slope.x,max(slope.y,slope.z)))
	var temp_tile = coord_e + dir
	var res = true
	while temp_tile != coord_p:
		if str(temp_tile) in objMap:
			res = false
			break
		temp_tile += dir
	return res

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
	#Correct position deviations
	playerChar.position = hexInst.Cube2Coord(playerChar.hexCoord)
	#Apply terrain damage
	var temp_to_free_terrain = []
	for terrain in terMap:
		if terMap[terrain].value == 1: #fire
			if terrain in objMap:
				objMap[terrain].Damage()
			terMap[terrain].gPersist -= 1
			if terMap[terrain].gPersist < 0:
				temp_to_free_terrain.append(terrain)
	for i in temp_to_free_terrain:
		terMap[i].queue_free()
		terMap.erase(i)
				
	StartTurn()

func GetActiveTiles() -> Array:
	var char_pos = playerChar.hexCoord
	var active_tiles = []
	#get movement tiles
	for t_dir in hexInst.cubeDirectionVectors:
		var temp_vec = char_pos + t_dir
		if activeMap.IsWalkable(temp_vec):
			if !objMap.has(str(temp_vec)):
				active_tiles.append(temp_vec)
	#get skill tiles
	#filter for occupied spaces/ invalid terrains
	return active_tiles

func MiscAttackHandler(type: String, data) -> void:
	#handles attacks that are more complicated to simply do
	if type == "famillie":
		var slope = data["coord_p"] - data["coord_e"]
		var dir = slope/(max(slope.x,max(slope.y,slope.z)))
		var temp_tile = data["coord_e"] + dir
		while temp_tile in activeMap.validCoords:
			if activeMap.IsValid(temp_tile,[1,3,4]):
				if activeMap.IsValid(temp_tile,[1,4]):
					CreateObj(temp_tile, data["value"])
				temp_tile += dir
			else:
				break

func CreateObj(coord_a : Vector3, value : int, persist := 2) -> void:
	var temp_obj = ObjBase.instance()
	temp_obj.objType = "terrain"
	temp_obj.value = value
	temp_obj.gPersist = persist
	temp_obj.position = hexInst.Cube2Coord(coord_a)
	add_child(temp_obj)
	temp_obj.Play("fire")
	terMap[str(coord_a)] = temp_obj
