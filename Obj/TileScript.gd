extends Node2D

const altarOffset = Vector2(0,-60)
const altarSize = 1.3
var Active : bool = false
var MouseInside : bool = false
var Coord : Vector3 = Vector3.ZERO
var Clicked : bool = false
var Value : String = "path"
var AValue : String = ""		#A1/A2/A3/A4
var size : Vector2 = Vector2(.23,.2)

func _ready():
	scale = Vector2(1,1) * size;

func _process(delta):
	if Active and MouseInside and Input.is_action_pressed("l_click") and not Clicked:
		Clicked = true

func play(anim):
	$AnimatedSprite.play(anim)
	Value = anim

func build(struct):
	$StructSprite.play(struct)
	if struct == "altar":
		$StructSprite.position += altarOffset
		$StructSprite.scale = Vector2(1,1) * altarSize

func _on_Area2D_mouse_entered():
	MouseInside = true
	if Active:
		scale = Vector2(1.2,1.2) * size

func _on_Area2D_mouse_exited():
	MouseInside = false
	scale = Vector2(1,1) * size
