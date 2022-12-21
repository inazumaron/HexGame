extends Node2D

var bodyType := "player" #other types are "enemy", "item", "etc"
var hexCoord := Vector3.ZERO
var hexInst = preload("res://Instructions.gd").new()

#Stat related
var gShield := false
var gHp := 1		# by default 1, only player >1 max hp
var maxHp := 1
#Specifically for enemy
var attackType := 0 # 0 - melee, 1 - ranged
var attackCooldown := 1 #turns before can attack again
var cooldownTimer := 1
var attackPrep := 1 #turns before attacking
var prepTimer := 1

#For movement animation things
const MaxDist = 0.5
var moveDir := Vector2.ZERO
var distMoved := 0.0
var reverse := false
var animQueue = []	#In case need to play multiple
var animMode := -1	# -1 - no movement, 0 - in tile movement, 1 - moving to other tiles
var moveSpeed := 1	#generally 1 = 1 tile/s, change when character moves more than 1 tile

func _ready():
	#set_process(false)
	pass

func _process(delta):
	if animMode == 0:
		if reverse:
			position -= delta * moveDir
			distMoved += delta
			if distMoved >= MaxDist:
				reverse = false
				distMoved = 0
				if animQueue.empty():
					animMode = -1
				else:
					MoveDir(animQueue.pop_front(), true)
		else:
			position += delta * moveDir
			distMoved += delta
			if distMoved >= MaxDist:
				reverse = true
				distMoved = 0
	
	if animMode == 1:
		if distMoved < MaxDist * 2:
			position -= delta * moveDir
			distMoved += delta
		else:
			position += delta * moveDir
			distMoved = 0
			animMode = -1

func play(anim : String) -> void:
	$AnimatedSprite.play(anim)

func MoveDir(l_dir : Vector3, from_process := false) -> void :
	if animMode == 0 and !from_process:
		animQueue.append(l_dir)
	else:
		moveDir = hexInst.Cube2Coord(l_dir)
		animMode = 0
		distMoved = 0

func MovePos(new_coord : Vector3) -> void:
	moveDir = hexInst.Cube2Coord(new_coord)
	distMoved = 0
	animMode = 1

func Damage() -> void:
	print("damaged")
	if gShield:
		gShield = false
	else:
		gHp -= 1
