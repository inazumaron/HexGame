extends Node2D

const mapHandlerBase = preload("res://Obj/MapHandler.tscn")
const charBase = preload("res://Obj/CharObj.tscn")
const objBase = preload("res://Obj/Objects.tscn")
const sfxBase = preload("res://Obj/SFX.tscn")
const uiBase = preload("res://Obj/UIHandler.tscn")
var HexInstr = preload("res://Obj/HexInstr.gd").new()

const sfxOffset = 0.5 #offset when adding sfx to character
const moveSpeed = 1.4 #Move speed for animation
#-------------------------animation related
const animSpeed = 5
var animTimer = 1
var animDir = Vector2.ZERO
var animObjQue = []
var currObjAnim = null
var sfxObj = null #temp pointer to manual sfx
var miscData = {} #for more complex animations, can store data here

var processMode = 0
var processAfter4 = 2
var mapObj
var uiObj
#Difficulty 0 - easy, 1 - normal, 2 - hard
var levelData = {
	"type" : "story",
	"level" : 3,
	"difficulty" : 0,
	"altar" : true,
	"randomStructPos" : true,
	"structPos" : [
		Vector3.ZERO,
		Vector3.ZERO,
		Vector3.ZERO,
	], # first one will always be stairs, followed by altars. Vector3 format
	"altarDetails" : [], # string list of names
	}
var playerData = {
	"StartCoord":Vector3.ZERO,
	"character":"Enna",
	"appearance":[0,0], #determines which skin animation to display * 0,0-Base, 1,0-A, 0,1-B, 1,1-AB
	"prevCoord":Vector3.ZERO
	#add more stuff eventually
	}
var playerObj
var enemyList = []
var objList = [] #For terrain add ons/ hazards
var enemyDamaged = [] #[enemyObj, damageSource] -- for animation purposes
#temp datas
var tempData2 = null #enemy damaged handling
var damagePlayer = false #process 4 usage

#-------------------------------- init functions
func _ready():
	set_process(false)
	GenerateMap()
	GenerateEnemies()
	GeneratePlayer()
	GenerateUI()
	StartTurn()

func GenerateMap():
	mapObj = mapHandlerBase.instance()
	mapObj.LevelData = levelData
	add_child(mapObj)

func GenerateEnemies():
	#to be used if non story
	var budget = 2*levelData["level"] + 2^levelData["difficulty"]
	#Select suitable enemies given level data
	var enemy_list = []
	for e in Data.EnemyList:
		if Data.EnemyList[e]["level"] <= levelData["level"] + levelData["difficulty"]:
			enemy_list.append(e)
	#Get available coords
	var e_pos = mapObj.GetEnemyPos(playerData["StartCoord"])
	#create enemy list
	while budget > 0 and len(e_pos) > 0:
		var i = randi()%len(enemy_list)
		var j = randi()%len(e_pos)
		var temp_enemy = charBase.instance()
		temp_enemy.play("E_"+enemy_list[i])
		temp_enemy.Name = enemy_list[i]
		temp_enemy.position = HexInstr.Cube2Coord(e_pos[j])
		temp_enemy.Coord = e_pos[j]
		#set enemy stats here
		temp_enemy.Actions = Data.EnemyList[enemy_list[i]]["Actions"]
		temp_enemy.ActionDetails = Data.EnemyList[enemy_list[i]]["ActionDetails"]
		add_child(temp_enemy)
		enemyList.append(temp_enemy)
		budget -= Data.EnemyList[enemy_list[i]]["cost"]
		#update mapObj of enemy on tile
		mapObj.UpdateTile(e_pos[j],["occupied"],["enemy"])
		e_pos.remove(j)

func GeneratePlayer():
	playerObj = charBase.instance()
	playerObj.position = HexInstr.Cube2Coord(playerData["StartCoord"])
	playerObj.Coord = playerData["StartCoord"]
	playerObj.Actions = Data.PlayerActions
	playerObj.ActionDetails = Data.PlayerActionDetails
	playerObj.Stats["HP"] = 3
	playerObj.Stats["MaxHP"] = 3
	playerObj.Name = "Enna"
	var temp = ""
	if playerData["appearance"][0]:
		temp+='A'
	if playerData["appearance"][1]:
		temp+='B'
	if temp == "":
		playerObj.play("C_"+playerData["character"]+"_Base")
	else:
		playerObj.play("C_"+playerData["character"]+"_"+temp)
	add_child(playerObj)

func GenerateUI():
	uiObj = uiBase.instance()
	uiObj.HP = playerObj.Stats["HP"]
	uiObj.MaxHP = playerObj.Stats["MaxHP"]
	uiObj.position = Vector2(-425,-200)
	add_child(uiObj)

#------------------------------- misc functions
func getEnemyByCoord(coord:Vector3):
	for e in enemyList:
		if e.Coord == coord:
			return e

func getObjByCoord(coord:Vector3):
	for o in objList:
		if o.Coord == coord:
			return o

func removeEnemy(enemy:Node):
	mapObj.UpdateTile(enemy.Coord, ["occupied"], ["none"])
	enemy.queue_free()
	enemyList.erase(enemy)

func removeObj(obj:Node):
	mapObj.UpdateTile(obj.Coord, ["addOn"], ["none"])
	obj.queue_free()
	objList.erase(obj)

func playerDamage():
	playerObj.damage()
	uiObj.HP = playerObj.Stats["HP"]
	uiObj.HPChange()
#------------------------------- game flow functions
func StartTurn():
	#Process terrain cooldowns
	var objToRemove = []
	for o in objList:
		if o.Expires:
			o.Duration -= 1
			if o.Duration <= 0:
				objToRemove.append(o)
	for o in objToRemove:
		removeObj(o)
	#Activate tiles
	mapObj.ActivateTiles(playerObj.Coord, playerObj.Actions, playerObj.ActionDetails)
	#Process Passive skills/cooldowns
	playerObj.NextTurn()
	for e in enemyList:
		e.NextTurn()
	#Wait for player action
	processMode = 0
	set_process(true)

func _process(delta):
	var tempData = null #passing sfx values
	#Ignore numbering, they are just the order I made them in
	if processMode == 0: #Waiting for player input
		var res = mapObj.CheckTiles()
		if res[0]:
			ProcessPlayerAction([res[1],res[2]]) #[coord, actionCode]
	#=================== Player Processes   =====================================
	if processMode == 1: #Move player obj
		animTimer -= delta * moveSpeed
		playerObj.position += delta * animDir * moveSpeed
		if animTimer <= 0:
			animTimer = 1
			processMode = 7
			tempData = null
			#ProcessEnemyDamaged()
	if processMode == 7: #Player side attack sfx
		if tempData2 != null:
			tempData2[0].damage()
			if tempData2[0].Stats["HP"] <= 0:
				removeEnemy(tempData2[0])
			tempData2 = null
		if len(enemyDamaged) > 0:
			tempData2 = enemyDamaged.pop_front()
			var tempDir = (tempData2[0].position - playerObj.position)/2
			print("td ",tempDir)
			sfxObj = sfxBase.instance()
			sfxObj.manualFree = true
			sfxObj.position = playerObj.position + (tempDir)
			#sfxObj.rotation = currObjAnim.AnimDir.angle()
			add_child(sfxObj)
			sfxObj.play("Enna")
			processMode = 4
			processAfter4 = 7
		else:
			PostEnemyDamaging() #Damaging enemies finished
	#=================   Enemy processes   ========================================
	if processMode == 2: #Handle enemy animations
		processAfter4 = 2 #set to default behaviour
		if len(animObjQue):
			currObjAnim = animObjQue.pop_front()
			animTimer = 1
			processMode = 3
		else:
			animTimer = 1
			EndTurn()
	if processMode == 3: #handle individual enemy animation
		if "move" in currObjAnim.AnimQueue:
			animTimer -= delta * moveSpeed
			currObjAnim.position += delta * currObjAnim.AnimDir * moveSpeed
			if animTimer <= 0:
				animTimer = 1
				processMode = 2
		if "stab" in currObjAnim.AnimQueue:
			sfxObj = sfxBase.instance()
			sfxObj.manualFree = true
			sfxObj.waitAct = 1
			sfxObj.position = currObjAnim.position + (sfxOffset * currObjAnim.AnimDir)
			sfxObj.rotation = currObjAnim.AnimDir.angle()
			add_child(sfxObj)
			sfxObj.play("Aloupeep")
			damagePlayer = true
			processMode = 4
		if "shoot" in currObjAnim.AnimQueue:
			sfxObj = sfxBase.instance()
			sfxObj.manualFree = true
			sfxObj.rotation = currObjAnim.AnimDir.angle()
			sfxObj.moves = true
			sfxObj.startPos = currObjAnim.position
			sfxObj.finalPos = playerObj.position
			sfxObj.position = currObjAnim.position 
			add_child(sfxObj)
			sfxObj.play("Phantomo")
			damagePlayer = true
			processMode = 4
		if "fireLine" in currObjAnim.AnimQueue:
			processMode = 5
	if processMode == 4: #wait for sfx to finish
		if sfxObj.waitingFree:
			if sfxObj.data != null:
				tempData = sfxObj.data
			sfxObj.queue_free()
			if damagePlayer:
				damagePlayer = false
				playerDamage()
			processMode = processAfter4
	if processMode == 5: #For fire line specifically, as animation is complex
		if len(miscData["fireLine"]) <= 0:
			processMode = 2
		else:
			var temp = miscData["fireLine"].pop_front()
			processAfter4 = 6 #creating fire after sfx finished, then will return here
			sfxObj = sfxBase.instance()
			sfxObj.manualFree = true
			sfxObj.position = HexInstr.Cube2Coord(temp)
			sfxObj.data = temp
			add_child(sfxObj)
			sfxObj.play("Famillie")
			processMode = 4
	if processMode == 6: #For fire line, adding fire to terrain after afx finishes
		var tempObj = objBase.instance()
		tempObj.Coord = tempData
		tempObj.position = HexInstr.Cube2Coord(tempData)
		tempObj.Expires = true
		tempObj.Duration = 1
		var tempTile = mapObj.GetTile(tempData)
		if tempTile["addOn"] != "none":
			var tempObj2 = getObjByCoord(tempData)
			if tempObj2.Type == "foilage":
				tempObj.Duration += 1
			removeObj(tempObj2)
		add_child(tempObj)
		tempObj.play("Fire")
		mapObj.UpdateTile(tempData,["addOn"],["fire"])
		objList.append(tempObj)
		processMode = 5

func ProcessPlayerAction(res):
	set_process(false)
	mapObj.DeactivateTiles()
	enemyDamaged = []
	#Determine action taken
	if res[1] == "A1": #player A1 is by default AdjStab, so assume this for now
		#Get any viable enemies to damage
		mapObj.UpdateTile(playerObj.Coord,["occupied"],["none"])
		playerData["prevCoord"] = playerObj.Coord
		playerObj.Coord = res[0]
		mapObj.UpdateTile(playerObj.Coord,["occupied"],["player"])
		var tempCoords = HexInstr.MutualAdjacent(playerData["prevCoord"],res[0])
		for coord in tempCoords:
			var tempTile = mapObj.GetTile(coord)
			if tempTile["occupied"] == "enemy":
				enemyDamaged.append([getEnemyByCoord(coord),"A1"])
		#Prepping animation
		animDir = HexInstr.Cube2Coord(res[0]) - playerObj.position
		processMode = 1
	#Play animation
	set_process(true)

func PostEnemyDamaging():
	set_process(false)
	#Check tile landed
	if false: #If tile landed is stairs
		ProcessStairs()
	elif false:
		ProcessAltar()
	else:
		ProcessEnemyActions()

func ProcessStairs():
	#If player steps on stairs, end level
	pass

func ProcessAltar():
	ProcessEnemyActions()
	pass

func ProcessEnemyActions():
	#Get heatmap
	mapObj.GenHeatMap(playerObj.Coord)
	#Check actions available
	for enemy in enemyList:
		var res = enemy.GetActions()
		#First priority is check if A4 available
		if "A4" in res[0]:
			EnemyAttackRedirect(enemy, res[1]["A4"]["meta"]["name"])
		elif "A1" in res[0]:
			if res[1]["A1"]["meta"]["name"] in ["moveA","moveB"]:
				EnemyMove(enemy,res[1]["A1"]["meta"]["name"])
	processMode = 2
	set_process(true)

func EndTurn():
	#Apply terrain damage
	var tempFireDamaged = mapObj.GetTerrainHazards(true)
	for coord in tempFireDamaged:
		if coord == playerObj.Coord:
			playerDamage()
		else:
			var tempE = getEnemyByCoord(coord)
			tempE.damage()
			if tempE.Stats["HP"] <= 0:
				removeEnemy(tempE)
	set_process(false)
	StartTurn()

#--------------------------------------- Action specific handling 
func EnemyMove(enemy,moveType):
	var move = "pathValueA"
	if moveType == "moveB":
		move = "pathValueB"
	var res = mapObj.GetEnemyPath(enemy.Coord, move)
	if res[0]:
		mapObj.UpdateTile(enemy.Coord,["occupied"],["none"])
		enemy.AnimDir = HexInstr.Cube2Coord(res[1]) - enemy.position
		enemy.AnimQueue.append("move")
		animObjQue.append(enemy)
		#enemy.position = HexInstr.Cube2Coord(res[1])
		enemy.Coord = res[1]
		mapObj.UpdateTile(res[1],["occupied"],["enemy"])

func EnemyAttackRedirect(enemy, attack:String):
	if attack == "stab":
		#check if can stab, stab, else move
		if HexInstr.IsAdjacent(playerObj.Coord, enemy.Coord):
			enemy.AnimDir = playerObj.position - enemy.position
			enemy.AnimQueue.append("stab")
			animObjQue.append(enemy)
		else:
			EnemyMove(enemy,"moveA")
	elif attack == "shoot":
		var tile = mapObj.GetTile(enemy.Coord)
		if tile["pathValueB"] == 1 and mapObj.CheckEnemyBetween(enemy.Coord, playerObj.Coord):
			enemy.AnimDir = playerObj.position - enemy.position
			enemy.AnimQueue.append("shoot")
			animObjQue.append(enemy)
		else:
			EnemyMove(enemy,"moveB")
	elif attack == "fireLine":
		var tile = mapObj.GetTile(enemy.Coord)
		if tile["pathValueB"] == 1:
			enemy.AnimDir = playerObj.position - enemy.position
			enemy.AnimQueue.append("fireLine")
			animObjQue.append(enemy)
			var tempLine = mapObj.GetLineFromDir(enemy.Coord, playerObj.Coord)
			tempLine.pop_front() #exclude caster position
			if "fireLine" in miscData:
				miscData["fireLine"] += tempLine
			else:
				miscData["fireLine"] = tempLine
			#
			#for coord in tempLine:
				
		else:
			EnemyMove(enemy,"moveB")
