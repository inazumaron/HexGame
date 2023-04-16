extends Node2D

const size = Vector2(1,1) * 0.4
const skillBase = preload("res://Obj/SkillObj.tscn")
const skillDist = 250
const skillPos = [
	Vector2(-skillDist, -48),
	Vector2(0, -48),
	Vector2(skillDist, -48),
]
var choices: Array = [] #contains skill string names
var skillObj: Array = []
var skillSelected := false
var skillVal: String = ''

func _ready():
	scale = size
	#for now generating only the skill icons as cards not yet prepared
	for i in range(3):
		var temp = skillBase.instance()
		temp.Value = choices[i]
		temp.Active = true
		temp.position = skillPos[i]
		temp.play(choices[i])
		add_child(temp)
		skillObj.append(temp)

func _process(delta):
	for i in skillObj:
		if i.Clicked:
			getSkill(i)
			set_process(false)

func getSkill(i):
	skillVal = i.Value
	skillSelected = true
	
