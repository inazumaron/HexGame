# Readme for general rules and research results

#Naming conventions
#	Funcs	- PascalCase
#	Global	- camelCase
#	Local	- snake_case
#	Const	- PascalCase
#	single word var will begin with v_/f_

#Hex grid related stuff
#source: https://www.redblobgames.com/grids/hexagons/

# Coordinate system: Cube coordinate
# Each hex will have 3 coordinates like in a 3d coordinate system
#	x + y + z = 0 at any time to keep it in one plane
#	moving in one axis does not change related axis variable but the other 2
#	orientation: x - x axis, y - NW axis, z - NE axis

# Will be working with pointy top orientataion
# Vector operations should still work as normal (so vector3 should work fine) but will need a
#	converter to 2d positioning

#Just add necessary stats when it gets complicated
const EnemyStats = {
	"grunt" : {
		"shield" : false,
		"aType" : 0,
		"aCD" : 1,
		"aPrep" : 0
	},
	"bow" : {
		"shield" : false,
		"aType" : 1,
		"aCD" : 1,
		"aPrep" : 0
	},
	"mage" : {
		"shield" : false,
		"aType" : 2,
		"aCD" : 1,
		"aPrep" : 0
	}
}

const HexWidth = 64
var cubeDirectionVectors = [
	Vector3(+1, 0, -1), Vector3(+1, -1, 0), Vector3(0, -1, +1), 
	Vector3(-1, 0, +1), Vector3(-1, +1, 0), Vector3(0, +1, -1), 
]
var vector2Dir = {
	str(Vector3(+1, 0, -1)) : "NW",
	str(Vector3(+1, -1, 0)) : "NE",
	str(Vector3(0, -1, +1)) : "E",
	str(Vector3(-1, 0, +1)) : "SE",
	str(Vector3(-1, +1, 0)) : "SW",
	str(Vector3(0, +1, -1)) : "W"
}

func IsAdjacent(coord_a : Vector3, coord_b : Vector3) -> bool:
	var coord_diff = CubeDistance(coord_a, coord_b)
	if coord_diff == 1.0:
		return true
	return false

func MutualAdjacent(coord_a : Vector3, coord_b : Vector3):
	var res = []
	for coord in cubeDirectionVectors:
		var temp_coord = coord_a + coord
		if IsAdjacent(temp_coord, coord_b):
			res.append(temp_coord)
	return res

func CheckValid(v_coord : Vector3) -> bool :
	if v_coord.x + v_coord.y + v_coord.z == 0:
		return true
	return false	

func CubeDirection(v_dir : int) -> Vector3 :
	return cubeDirectionVectors[v_dir]

func CubeDistance(cube_a : Vector3, cube_b : Vector3) -> float :
	var cube_diff = cube_a - cube_b
	return max(abs(cube_diff.x), max(abs(cube_diff.y), abs(cube_diff.z)))

func Cube2Coord(v_coord : Vector3) -> Vector2 :
	var temp_coord = Vector2.ZERO
	temp_coord += v_coord.x * Vector2(0, -0.75)
	temp_coord += v_coord.y * Vector2(-0.5, 0)
	temp_coord += v_coord.z * Vector2(0.5, 0)
	temp_coord *= HexWidth
	return temp_coord

func Coord2Cube(v_coord : Vector2) -> Vector3 :
	var temp_cube = Vector3.ZERO
	temp_cube += v_coord.x * Vector3(0, -2, 2)
	temp_cube += v_coord.y * Vector3(-4/3, 0, 0)
	temp_cube /= HexWidth
	return temp_cube

func LineDrawing(start_pos : Vector2, end_pos : Vector2) -> void :
	# let n = cube distance from the cube coordinate
	# draw line from start_pos to end_pos and divide line by n
	# convert the n (vec2) to vec3 cube coord
	# store in array and return
	pass

func GetAdjacent(coord_a : Vector3) -> Array:
	var temp_res = []
	for coord in cubeDirectionVectors:
		temp_res.append(coord_a + coord)
	return temp_res
#For further algorithms, refer to the given source

#Game hiearchy

#Scenes
#	Level Handler		- handles user input and calculations
#		Map Handler		- strictly graphics handling only
#		Avatar Handler	- strictly graphics handling only
#		Effect Handler	- strictly graphics handling only
#Singletons
#	Action Handler	- holds character skills, deals with character interactions
