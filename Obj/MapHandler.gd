extends Node2D

const Dir2Vect = {
	"NW" : Vector3(+1, 0, -1),
	"NE" : Vector3(+1, -1, 0),
	"HE" : Vector3(0, -1, +1),
	"SE" : Vector3(-1, 0, +1),
	"SW" : Vector3(-1, +1, 0),
	"HW" : Vector3(0, +1, -1)}
const TileBase = preload("res://Obj/TileObj.tscn")

var HexInstr = preload("res://Obj/HexInstr.gd").new();
var mapSize = 5
var NodeMap = {}
var LevelData = {
	"type" : "story",
	"level" : 0,
	"difficulty" : 0,
	"altar" : true}
var ActiveTiles = [] #For easy deactivating active tiles
var validCoords = []

#--------------------- Init stuff
func _ready():
	GenerateTiles(mapSize)

func GenerateTiles(size:int):
	var tile_dict = {}
	#Generating and placing tiles on the correct position
	for i in range(-size,size+1):
		for j in range(-size,size+1):
			for k in range(-size,size+1):
				if HexInstr.CheckValid(Vector3(i,j,k)):
					var temp_tile = TileBase.instance()
					temp_tile.Coord = Vector3(i,j,k)
					temp_tile.position = HexInstr.Cube2Coord(Vector3(i,j,k))
					add_child(temp_tile)
					tile_dict[str(Vector3(i,j,k))] = temp_tile
					temp_tile.play("path")
					validCoords.append(Vector3(i,j,k))
	
	#Set lava and walls here
	#For now, randomly generating walls/lava
	for i in range(5):
		tile_dict[str(validCoords[randi()%len(validCoords)])].play("wall")
	for i in range(5):
		tile_dict[str(validCoords[randi()%len(validCoords)])].play("lava")
	
	#Generate the node map for the tiles
	for tile in tile_dict:
		var temp_node = {"node":tile_dict[tile], "type":tile_dict[tile].Value, "addOn":"none", "addOnData":{},
			"struct":"null","structData":"null", "occupied":"none", "pathValueA":0, "pathValueB":0}
		for dir in Dir2Vect:
			if str(tile_dict[tile].Coord + Dir2Vect[dir]) in tile_dict:
				temp_node[dir] = tile_dict[str(tile_dict[tile].Coord + Dir2Vect[dir])]
			else:
				temp_node[dir] = null
		NodeMap[tile] = temp_node
		
	GenerateStructures()

func GenerateStructures():
	var tempVectors = [Vector3.ZERO]
	if LevelData["randomStructPos"]:
		var minDist = ceil(mapSize/2)
		var tempPos = Vector3.ZERO
		var structsAdded = 0
		var tempNum = len(LevelData["structPos"])
		var nameList = [] #for keeping track of altar vals
		while structsAdded < tempNum:
			tempPos = validCoords[randi()%len(validCoords)]
			var validPos = true
			for i in tempVectors:
				if HexInstr.CubeDistance(i, tempPos) <= minDist:
					validPos = false
			if validPos:
				if structsAdded == 0:
					NodeMap[str(tempPos)]["struct"] = "stairs"
				else:
					NodeMap[str(tempPos)]["struct"] = "altar"
					NodeMap[str(tempPos)]["structData"] = Data.GetRandomName(nameList)
					nameList.append(NodeMap[str(tempPos)]["structData"])
				structsAdded += 1
				tempVectors.append(tempPos)
		tempVectors.pop_front()
	else:
		tempVectors = LevelData["structPos"]
		for pos in range(len(LevelData["structPos"])):
			if pos:
				NodeMap[str(LevelData["structPos"][pos])]["struct"] = "altar"
				NodeMap[str(LevelData["structPos"][pos])]["structData"] = LevelData["altarDetails"][pos-1]
			else:
				NodeMap[str(LevelData["structPos"][pos])]["struct"] = "stairs"
	
	#Adding struct sprites
	for pos in tempVectors:
		#Also in case placed on a wall/lava
		NodeMap[str(pos)]["type"] = "path"
		var temp = NodeMap[str(pos)]["struct"]
		NodeMap[str(pos)]["node"].build(temp)
		if temp == "altar":
			NodeMap[str(pos)]["node"].play("altar"+NodeMap[str(pos)]["structData"])

func GetEnemyPos(PlayerCoord) -> Array:
	#getting starting enemy positions, at least 1 tile away from player starting pos
	#Data to return will be in vector3 coords
	var validTiles = []
	for node in NodeMap:
		if NodeMap[node]["type"] == "path":
			var temp = str2var("Vector3"+node)
			if HexInstr.CubeDistance(temp, PlayerCoord) > 1:
				validTiles.append(temp)
	return validTiles

#----------------------- 

func ActivateTiles(coord : Vector3, type : Array, AData = {}):
	#A1 - adj, A2 - nonAdj, non-occ, A3 - curr tile, A4 - occ tile, check A4D
	#Details - [range : int, maxRange : int, wallValid : bool, lavaValid : bool, behindWall : bool, behindLava : bool ]
	if "A1" in type:
		for dir in Dir2Vect:
			var temp = str(coord + Dir2Vect[dir])
			if (coord + Dir2Vect[dir]) in validCoords:
				if NodeMap[temp]["type"] == "path" and NodeMap[temp]["occupied"] == "none":
					NodeMap[temp]["node"].Active = true;
					NodeMap[temp]["node"].AValue = "A1";
					ActiveTiles.append(NodeMap[temp]["node"])
	if "A2" in type:
		var offsetCoords = HexInstr.GetTileRange(AData["A2D"]["range"])
		if AData["A2D"]["range"] != AData["A2D"]["maxRange"]:
			for i in range(AData["A2D"]["range"]+1, AData["A2D"]["maxRange"]+1):
				offsetCoords += (HexInstr.GetTileRange(i))
		for offCoord in offsetCoords:
			var temp = str(coord + offCoord)
			if (coord + offCoord) in validCoords:
				if NodeMap[temp]["occupied"] == "none":
					if  NodeMap[temp]["type"] == "path" or (NodeMap[temp]["type"] == "lava" and AData["A2D"]["lavaValid"]) or (NodeMap[temp]["type"] == "wall" and AData["A2D"]["wallValid"]):
						NodeMap[temp]["node"].Active = true;
						NodeMap[temp]["node"].AValue = "A2";
						ActiveTiles.append(NodeMap[temp]["node"]) 
	if "A3" in type:
		NodeMap[str(coord)]["node"].Active = true
		NodeMap[str(coord)]["node"].AValue = "A3"
		ActiveTiles.append(NodeMap[str(coord)]["node"])

func DeactivateTiles():
	for tile in ActiveTiles:
		tile.Active = false
		tile.Clicked = false
	ActiveTiles = []

func UpdateTile(coord:Vector3, values:Array, newVals:Array):
	#Update tile properties as set in the nodemap
	for i in range(len(values)):
		NodeMap[str(coord)][values[i]] = newVals[i]

func GetTile(coord:Vector3):
	return NodeMap[str(coord)]

func CheckTiles():
	for tile in ActiveTiles:
		if tile.Clicked:
			return [true, tile.Coord, tile.AValue]
	return [false]

func GenHeatMap(coord) -> void:
	for tCoord in NodeMap:
		NodeMap[tCoord]["pathValueA"] = 99
		NodeMap[tCoord]["pathValueB"] = 99
	#Set heatmap for melee
	RecHeatMapA(coord,0)
	#Set heatmap for ranged
	for dir in Dir2Vect:
		RecHeatMapB_Init(coord, dir)
	RecHeatMapB_End()

func RecHeatMapA(coord:Vector3, value:int)->void:
	NodeMap[str(coord)]["pathValueA"] = value
	#tileNodes[str(coord)]["node"].ShowPathVal()
	var rec_coord_list = []
	
	for dir in Dir2Vect:
		if NodeMap[str(coord)][dir] != null:
			if NodeMap[str(coord)][dir].Value == "path":
				if (value + 1) < NodeMap[str(coord + Dir2Vect[dir])]["pathValueA"]:
					NodeMap[str(coord + Dir2Vect[dir])]["pathValueA"] = value + 1
					rec_coord_list.append(coord + Dir2Vect[dir])
	
	for rec_coord in rec_coord_list:
		RecHeatMapA(rec_coord, value + 1)

func RecHeatMapB_Init(coord:Vector3, dir:String):
	NodeMap[str(coord)]["pathValueB"] = 1
	if NodeMap[str(coord)][dir] != null:
		if NodeMap[str(coord+Dir2Vect[dir])]["node"].Value in ["path","lava"]:
			RecHeatMapB_Init(coord+Dir2Vect[dir], dir)

func RecHeatMapB_End():
	var changes = true
	while changes:
		changes = false
		for coords in validCoords:
			#if path, check adj for smaller value
			if NodeMap[str(coords)]["node"].Value == "path":
				var temp = NodeMap[str(coords)]["pathValueB"]
				for dir in Dir2Vect:
					if NodeMap[str(coords)][dir] != null:
						temp = min(temp, NodeMap[str(coords+Dir2Vect[dir])]["pathValueB"]+1)
				if temp != NodeMap[str(coords)]["pathValueB"]:
					changes = true
					NodeMap[str(coords)]["pathValueB"] = temp

func GetEnemyPath(coord:Vector3, pathVal : String):
	var tempMinVal = INF
	var tempCoord = Vector3.ZERO
	for dir in Dir2Vect:
		if NodeMap[str(coord)][dir] != null:
			if NodeMap[str(coord + Dir2Vect[dir])]["node"].Value == "path" and NodeMap[str(coord + Dir2Vect[dir])]["occupied"] == "none":
				if tempMinVal > NodeMap[str(coord + Dir2Vect[dir])][pathVal]:
					tempCoord = coord + Dir2Vect[dir]
					tempMinVal = NodeMap[str(coord + Dir2Vect[dir])][pathVal]
	if tempMinVal == INF:
		return [false]
	else:
		return [true, tempCoord]

func CheckEnemyBetween(eCoord:Vector3, pCoord:Vector3)->bool:
	#Check if there are enemies between 2 coords
	#for ranged enemy to avoid friendly fire
	var dir = HexInstr.Normalize(pCoord - eCoord)
	var tempCoord = eCoord
	while tempCoord != pCoord:
		tempCoord += dir
		if not(tempCoord in validCoords):
			#Shouldnt happen
			print("MH out of bounds??")
			return false
		if NodeMap[str(tempCoord)]["occupied"] == "enemy":
			return false
	return true

func GetTerrainHazards(occ:bool):
	#occ - if true, only gets terrain hazards that are occupied, else gets all hazards
	var res = []
	for coord in NodeMap:
		if NodeMap[coord]["addOn"] == "fire": #for now, fire is the only terrain hazard
			if occ:
				if NodeMap[coord]["occupied"] != "none":
					res.append(str2var("Vector3"+coord))
			else:
				res.append(str2var("Vector3"+coord))
	return res

func GetLineFromDir(coord_a:Vector3, coord_b:Vector3):
	#For now being used by move "FireLine" of famillie
	var res = []
	var dir = HexInstr.Normalize(coord_b-coord_a)
	while NodeMap[str(coord_a)]["node"].Value in ["path","lava"]:
		if NodeMap[str(coord_a)]["node"].Value == "path":
			res.append(coord_a)
		coord_a += dir
		if not(coord_a in validCoords):
			break
	return res
