extends Node2D

var mapSize = 6 # map width + 1
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
					temp_tile.SetSprite(Textures["floor"])
					validCoords.append(Vector3(i,j,k))
	
	#Generate walls
	var wall_index = 0
	for i in range(0,12):
		wall_index = randi()%validCoords.size()
		while wall_index == 0:
			wall_index = randi()%validCoords.size()
		tile_dict[str(validCoords[wall_index])].SetSprite(Textures["wall"])
		tile_dict[str(validCoords[wall_index])].tileType = 2
	
	#Generating door
	var rand_index = 0
	while rand_index == 0:
		rand_index = randi()%validCoords.size()
	tile_dict[str(validCoords[rand_index])].SetSprite(Textures["door"])
	tile_dict[str(validCoords[rand_index])].tileType = 4
	
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

#For pathing purposes
func GenerateHeatMap(coord_origin : Vector3) -> void:
	#clear existing values
	for tile in tileNodes:
		tileNodes[tile]["node"].pathValue = 999
	#call recursive function
	RecGenHeatMap(coord_origin, 0)

func RecGenHeatMap(coord : Vector3, value : int, valid_tiles := [1, 4]) -> void:
	tileNodes[str(coord)]["node"].pathValue = value
	tileNodes[str(coord)]["node"].ShowPathVal()
	var rec_coord_list = []
	
	for dir in Dir2Vect:
		if tileNodes[str(coord)][dir] != null:
			if tileNodes[str(coord)][dir].tileType in valid_tiles:
				if (value + 1) < tileNodes[str(coord)][dir].pathValue:
					tileNodes[str(coord)][dir].pathValue = value + 1
					rec_coord_list.append(tileNodes[str(coord)][dir].hexCoord)
	
	for rec_coord in rec_coord_list:
		RecGenHeatMap(rec_coord, value + 1)

func GetEnemyPath(coord : Vector3, type := 0, to_player := true) -> Array:
	#Scans surrounding tiles pathValue, returns an array of min values
	#type unused, mainly for range type, 0 - melee, 1 - ranged
	#to_player also unused for now
	var temp_min = 99
	var temp_array = []
	for dir in Dir2Vect:
		if str(Dir2Vect[dir] + coord) in tileNodes:
			if tileNodes[str(Dir2Vect[dir] + coord)]["node"].pathValue < temp_min:
				temp_min = tileNodes[str(Dir2Vect[dir] + coord)]["node"].pathValue
				temp_array = []
				temp_array.append(Dir2Vect[dir] + coord)
			elif tileNodes[str(Dir2Vect[dir] + coord)]["node"].pathValue == temp_min:
				temp_array.append(Dir2Vect[dir] + coord)
	return temp_array
