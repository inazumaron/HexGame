extends Node2D

var hexCoord := Vector3.ZERO
var setSprite := false
var mouseInside := false
var tileActive := false
var tileClicked := false
var pathValue := -1		#Used for pathfinding purposes
var pathValueAlt := -1	#Used for pathfinding but for ranged enemies (will just go to nearest adjacent line)
var tileType := 1	#For checking if walkable
	# 1 - floor, 2 - wall, 3 - lava, 4 - door
const HexWidth = 60
const HexPoints = [Vector2(0,-HexWidth/2), Vector2(HexWidth/2,-HexWidth/4), 
	Vector2(HexWidth/2,HexWidth/4), Vector2(0, HexWidth/2),
	Vector2(-HexWidth/2,HexWidth/4), Vector2(-HexWidth/2,-HexWidth/4)]

func _ready():
	$Label.text = str(hexCoord)

func _process(delta):
	if Input.is_action_just_pressed("ui_select") and mouseInside and tileActive:
		tileClicked = true
		scale = 1 * Vector2(1,1)

func _draw():
	var v_color = [Color(0,0,0,1)]
	draw_polygon(HexPoints, v_color)

func SetSprite(spr_path) -> void : #spr_path should be a preloaded item
	$Sprite.texture = spr_path

func Play(anim : String) -> void :
	$AnimatedSprite.play(anim)

func ShowPathVal() -> void:
	$Label.text = str(pathValue)

func _on_Area2D_mouse_entered():
	mouseInside = true
	if tileActive:
		scale = 1.1 * Vector2(1,1)

func _on_Area2D_mouse_exited():
	mouseInside = false
	if tileActive:
		scale = 1 * Vector2(1,1)
