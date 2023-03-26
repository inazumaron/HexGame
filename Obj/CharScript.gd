extends Node2D

const Size = Vector2(0.35,0.35) #to fit with tiles

var Name : String = ""		#Mainly in debugging
var Type : String = ""
var Coord := Vector3.ZERO
var Actions = [] #["A1","A2","A3","A4"]
var ActionDetails = {}
var Stats := {
	"MaxHP" : 1,
	"HP" : 1,
	"TempShield" : [0,0], #[time, stack]
	"PermaShield": 0,
}
#For enemy animation things
var AnimDir := Vector2.ZERO
var AnimQueue = []

# Called when the node enters the scene tree for the first time.
func _ready():
	scale = Size

func GetActions():
	#Returns available actions to take after accounting for cooldowns etc
	return [Actions, ActionDetails]

func NextTurn():
	#Deal with cooldowns, status effects, passives, etc that takes effect when turn changes
	AnimQueue = []
	AnimDir = Vector2.ZERO

func play(anim : String):
	$AnimatedSprite.play(anim)

func damage():
	if Stats["TempShield"][1] != 0:
		Stats["TempShield"][1] -= 1
	elif Stats["PermaShield"] != 0:
		Stats["PermaShield"] -= 1
	else:
		Stats["HP"] -= 1
	print(Name," damaged ",Stats["HP"])
