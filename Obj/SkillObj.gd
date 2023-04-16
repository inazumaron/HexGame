extends Node2D

const HoverSize = Vector2(1,1) * 1.2
var Active := false
var MouseInside := false
var Clicked := false
var Value: String = ''

func _ready():
	set_process(false)
	if Active:
		set_process(true)

func play(anim):
	$Spr.play(anim)

func _process(delta):
	if Active and MouseInside and Input.action_press("l_click"):
		Active = false
		Clicked = true
		print('asddsa')

func _on_Area2D_mouse_entered():
	if Active:
		MouseInside = true
		scale = HoverSize

func _on_Area2D_mouse_exited():
	if Active:
		MouseInside = false
		scale = Vector2(1,1)
