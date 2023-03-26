extends Node2D

const skillBase = preload("res://Obj/SkillObj.tscn")
const skillPos = 48
const size = 0.75
const skillSize = 0.5
const skillOffset = Vector2(-50, 150)

var MaxHP := 3
var HP := 3
var skills = ['Enna_Shuriken','Enna_Fly','Millie_Potion']
var shield := false
var skillObj = []
var playerChar := 'Enna'

func _ready():
	scale = Vector2(1,1) * size
	$HPanim.play('0')
	$HPspr.play(str(MaxHP)+'_'+str(HP))
	$HPportrait.play(playerChar)
	GenerateSkills()

func GenerateSkills():
	for i in skillObj:
		i.queue_free()
	skillObj = []
	for i in range(len(skills)):
		var temp = skillBase.instance()
		temp.scale = Vector2(1,1)*skillSize
		temp.position = Vector2(skillPos * ((i+1)%2),skillPos*i) + skillOffset
		add_child(temp)
		temp.play(skills[i])
		skillObj.append(temp)

func HPChange():
	$HPanim.play(str(HP+1))
	$HPspr.play(str(MaxHP)+'_'+str(HP))

func _on_HPanim_animation_finished():
	$HPanim.play('0')
	$HPanim.stop()
