extends Node2D

var mapSize = 6 # map width + 1
var level = "11" #refer to Data.gd for resoning for this format
const TileBase = preload("res://Generic/MapTile.tscn")
const Dir2Vect = {
	"NW" : Vector3(+1, 0, -1),
	"NE" : Vector3(+1, -1, 0),
	"HE" : Vector3(0, -1, +1),
	"SE" : Vector3(-1, 0, +1),
	"SW" : Vector3(-1, +1, 0),
	"HW" : Vector3(0, +1, -1)
}
const Textures = {
	"floor" : preload("res://Resc/Tiles/Gravel.png"),
	"door" : preload("res://Resc/Tiles/Water.png"),
	"lava" : preload("res://Resc/Tiles/Magma.png"),
	"wall" : preload("res://Resc/Tiles/Stone.png"),
}
var tileArray
var validCoords = []
var hexInst = preload("res://Instructions.gd").new()
var tileValue := Vector3.ZERO
var newValue := false	#for differentiating vector3.zero if its just the default or actual selected
var tileNodes = {}		#For melee enemies path to player

func _ready():
	SetArray(mapSize + 2)
	GenerateTiles(int(mapSize/2))

func _process(delta): #for monitoring clicked tiles
	for coord in validCoords:
		var temp_tile = GetTileSlot(coord)
		if temp_tile.tileClicked:
			tileValue = temp_tile.hexCoord
			newValue = true
			temp_tile.tileClicked = false
			SetTileSlot(coord, temp_tile)

func SetTileSlot(hex_coord : Vector3, data) -> void:
	var temp_key = Vector3.ZERO
	#to accomodate negative values, well be translating them to positive index
	#0 - 0, positive - positive * 2, negative - abs(negative) * 2 + 1
	if hex_coord.x < 0:
		temp_key.x = (abs(hex_coord.x) * 2) + 1
	else:
		temp_key.x = hex_coord.x * 2
	if hex_coord.y < 0:
		temp_key.y = (abs(hex_coord.y) * 2) + 1
	else:
		temp_key.y = hex_coord.y * 2
	if hex_coord.z < 0:
		temp_key.z = (abs(hex_coord.z) * 2) + 1
	else:
		temp_key.z = hex_coord.z * 2
	tileArray[temp_key.x][temp_key.y][temp_key.z] = data

func GetTileSlot(hex_coord : Vector3):
	var temp_key = Vector3.ZERO
	#to accomodate negative values, well be translating them to positive index
	#0 - 0, positive - positive * 2, negative - abs(negative) * 2 + 1
	if hex_coord.x < 0:
		temp_key.x = (abs(hex_coord.x) * 2) + 1
	else:
		temp_key.x = hex_coord.x * 2
	if hex_coord.y < 0:
		temp_key.y = (abs(hex_coord.y) * 2) + 1
	else:
		temp_key.y = hex_coord.y * 2
	if hex_coord.z < 0:
		temp_key.z = (abs(hex_coord.z) * 2) + 1
	else:
		temp_key.z = hex_coord.z * 2
	return tileArray[temp_key.x][temp_key.y][temp_key.z]

func SetArray(size:int):
	var v_array = []
	v_array.resize(size)    # X-dimension
	for x in size:    # this method should be faster than range since it uses a real iterator iirc
		v_array[x] = []
		v_array[x].resize(size)    # Y-dimension
		for y in size:
			v_array[x][y] = []
			v_array[x][y].resize(size)    # Z-dimension
	tileArray = v_array

func GenerateTiles(size:int):
	var tile_dict = {}
	for i in range(-size,size+1):
		for j in range(-size,size+1):
			for k in range(-size,size+1):
				if hexInst.CheckValid(Vector3(i,j,k)):
					var temp_tile = TileBase.instance()
					temp_tile.hexCoord = Vector3(i,j,k)
					temp_tile.position = hexInst.Cube2Coord(Vector3(i,j,k))
					SetTileSlot(Vector3(i,j,k), temp_tile)
					add_child(temp_tile)
					tile_dict[str(Vector3(i,j,k))] = temp_tile
					temp_tile.Play("path")
					validCoords.append(Vector3(i,j,k))
	
	#Fetch level data
	var level_data_index = Data.MapTemplates[level][0]
	var lava_count = level_data_index.x
	var wall_count = level_data_index.y
	var altar_count = level_data_index.z
	
	#Generate lava
	if lava_count > 0:
		for i in range(1, lava_count+1):
			tile_dict[str(Data.MapTemplates[level][i])].Play("lava")
			tile_dict[str(Data.MapTemplates[level][i])].tileType = 3
	
	#generate walls
	if wall_count > 0:
		for i in range(lava_count+1, wall_count+lava_count+1):
			tile_dict[str(Data.MapTemplates[level][i])].Play("wall")
			tile_dict[str(Data.MapTemplates[level][i])].tileType = 2
	
	#generate altars
	if altar_count > 0:
		for i in range(wall_count+lava_count+1, wall_count+lava_count+altar_count+1):
			tile_dict[str(Data.MapTemplates[level][i])].Play("altar_enna")
			tile_dict[str(Data.MapTemplates[level][i])].tileType = 1
	
	#Generating door
	tile_dict[str(Data.MapTemplates[level][-1])].Play("stairs")
	tile_dict[str(Data.MapTemplates[level][-1])].tileType = 4
	
	#Creating tile nodes
	for tile in tile_dict:
		var temp_node = {"node":tile_dict[tile]}
		for dir in Dir2Vect:
			if str(tile_dict[tile].hexCoord + Dir2Vect[dir]) in tile_dict:
				temp_node[dir] = tile_dict[str(tile_dict[tile].hexCoord + Dir2Vect[dir])]
			else:
				temp_node[dir] = null
		tileNodes[tile] = temp_node

func DeactivateTiles() -> void:
	for coord in validCoords:
		var temp_tile = GetTileSlot(coord)
		if temp_tile.tileActive:
			temp_tile.tileActive = false
			SetTileSlot(coord,temp_tile)

func ActivateTile(hex_coord : Vector3) -> void:
	var temp = GetTileSlot(hex_coord)
	temp.tileActive = true
	SetTileSlot(hex_coord, temp)

func ActivateTiles(hex_array) -> void:
	for temp_coord in hex_array:
		ActivateTile(temp_coord)

#For pathing purposes, for melee units
func GenerateHeatMap(coord_origin : Vector3) -> void:
	#clear existing values
	for tile in tileNodes:
		tileNodes[tile]["node"].pathValue = 999
		tileNodes[tile]["node"].pathValueAlt = 999
	#call recursive function
	RecGenHeatMap(coord_origin, 0)
	
	#Generating heat manp for ranged units
	RangedHeatMapInit(coord_origin)

func RecGenHeatMap(coord : Vector3, value : int, valid_tiles := [1, 4]) -> void:
	tileNodes[str(coord)]["node"].pathValue = value
	#tileNodes[str(coord)]["node"].ShowPathVal()
	var rec_coord_list = []
	
	for dir in Dir2Vect:
		if tileNodes[str(coord)][dir] != null:
			if tileNodes[str(coord)][dir].tileType in valid_tiles:
				if (value + 1) < tileNodes[str(coord)][dir].pathValue:
					tileNodes[str(coord)][dir].pathValue = value + 1
					rec_coord_list.append(tileNodes[str(coord)][dir].hexCoord)
	
	for rec_coord in rec_coord_list:
		RecGenHeatMap(rec_coord, value + 1)

#For ranged unit pathing purposes
func RangedHeatMapInit(coord : Vector3, valid_tiles := [1,3,4]) -> void:
	#setting direct adjacent lines to 0
	for dir in Dir2Vect:
		RangedHeatMapRecA(coord, Dir2Vect[dir], valid_tiles)
	
	RangedHeatMapRecB(validCoords)

func RangedHeatMapRecA(coord : Vector3, coord_dir : Vector3, valid_tiles) -> void:
	if tileNodes[str(coord)]["node"].tileType in valid_tiles:
		tileNodes[str(coord)]["node"].pathValueAlt = 0
		tileNodes[str(coord)]["node"].ShowPathVal()
		if str(coord + coord_dir) in tileNodes:
			RangedHeatMapRecA(coord + coord_dir, coord_dir, valid_tiles)

func TileGetMinAdj(coord : Vector3) -> int:
	var res := 999
	for dir in Dir2Vect:
		if tileNodes[str(coord)][dir] != null:
			res = min(tileNodes[str(coord + Dir2Vect[dir])]["node"].pathValueAlt, res)
	return res

func RangedHeatMapRecB(coord_list : Array, valid_tiles := [1,4]) -> void:
	var unknown_tiles = []
	for coord in coord_list:
		if tileNodes[str(coord)]["node"].pathValueAlt == 999 and tileNodes[str(coord)]["node"].tileType in valid_tiles:
			var temp_val = TileGetMinAdj(coord)
			if temp_val == 999:
				unknown_tiles.append(coord)
			else:
				tileNodes[str(coord)]["node"].pathValueAlt = temp_val + 1
				tileNodes[str(coord)]["node"].ShowPathVal()
	if unknown_tiles.size() > 0:
		RangedHeatMapRecB(unknown_tiles, valid_tiles)

func GetEnemyPath(coord : Vector3, type := 0, to_player := 1) -> Array:
	#Scans surrounding tiles pathValue, returns an array of min values
	#type unused, mainly for range type, 0 - melee, 1 - ranged, add numbers when needed
	#to_player currently unused
	var temp_min = 99
	var temp_array = []
	for dir in Dir2Vect:
		if type == 0:
			if str(Dir2Vect[dir] + coord) in tileNodes:
				if tileNodes[str(Dir2Vect[dir] + coord)]["node"].pathValue < temp_min:
					temp_min = tileNodes[str(Dir2Vect[dir] + coord)]["node"].pathValue
					temp_array = []
					temp_array.append(Dir2Vect[dir] + coord)
				elif tileNodes[str(Dir2Vect[dir] + coord)]["node"].pathValue == temp_min:
					temp_array.append(Dir2Vect[dir] + coord)
		else:
			if str(Dir2Vect[dir] + coord) in tileNodes:
				if tileNodes[str(Dir2Vect[dir] + coord)]["node"].pathValueAlt < temp_min:
					temp_min = tileNodes[str(Dir2Vect[dir] + coord)]["node"].pathValueAlt
					temp_array = []
					temp_array.append(Dir2Vect[dir] + coord)
				elif tileNodes[str(Dir2Vect[dir] + coord)]["node"].pathValueAlt == temp_min:
					temp_array.append(Dir2Vect[dir] + coord)
	return temp_array

#For player processing and other miscellaneous things from levelHandler
func IsWalkable(coord : Vector3) -> bool:
	if str(coord) in tileNodes:
		if tileNodes[str(coord)]["node"].tileType in Data.playerWalkableVals:
			return true
	return false
