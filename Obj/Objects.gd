extends Node2D

const size := Vector2(1,1) * 0.30
var Expires := false
var Duration : int = 0
var Type := "none"
var Coord := Vector3.ZERO

func _ready():
	scale = size

func play(anim):
	$AnimatedSprite.play(anim)
