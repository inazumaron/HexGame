extends Node2D

var objType = "projectie"	# projectile, terrain, doodad
# projectiles - will move to a point before disappearing
# terrain - recorded in levelHandler, may interact with characters
# doodad - does not interact with anything nor does it move

#Projectile related stats
var finalPos := Vector2.ZERO
var gSpeed := 5
var gBlockable := false
var gVelocity := Vector2.ZERO
var onHitAction := 0
# 0 - do nothing, 1 - damage, 2 - push, 3 - push or damage (if cant push)
var gPersist := 0 #number of turns to persist upon landing on tile

func _ready():
	if objType == "projectile":
		set_process(true)

func _process(delta):
	gVelocity = position.direction_to(finalPos) * gSpeed
	if position.distance_to(finalPos) > 5:
		position += gVelocity
	else:
		if gPersist == 0:
			queue_free()
		set_process(false)
