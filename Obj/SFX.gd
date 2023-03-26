extends Node2D

#This object auto deletes itself upon finishing animation, so no need to keep track
const size = Vector2(1,1)*0.3

var animRepeat = 0
var duration = 0 #if duration not 0, means play until duration elapses
var autoFree = true
var manualFree = false
var waitingFree = false #for manual free, will be true when can be freed
var waitAct = 0 #what to do while waiting to be freed (animation) 0 - continue playing, 1 - pause, 2 - invi
var postAct = 0 #does something before removing itself
#--------------- movement stuff
var moves = false
var dir = Vector2.ZERO
var startPos = Vector2.ZERO
var finalPos = Vector2.ZERO
#--------------
var data = null #in random cases where it needs to pass some value

func _ready():
	scale = size
	if rotation > 1:
		scale.y *= -1
	set_process(false)
	if moves:
		set_process(true)
		dir = finalPos - startPos
		if duration == 0:
			duration = 1
		else:
			dir /= duration
	if duration:
		autoFree = false
		set_process(true)
		

func _process(delta):
	duration -= delta
	if duration <= 0:
		Qfree()
	if moves:
		position += dir * delta

func _on_AnimatedSprite_animation_finished():
	if animRepeat == 0 and not duration:
		Qfree()
	else:
		animRepeat -= 1

func Qfree():
	if not manualFree:
		queue_free()
	else:
		waitingFree = true
		if waitAct == 2:
			play("None")
		if waitAct == 1:
			$AnimatedSprite.stop()

func play(anim):
	$AnimatedSprite.play(anim)
