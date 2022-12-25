extends Node
#This nodes purpose is to handle scene transitions as there wont be a single overseeing scene to do it
#Why? idk, tho doesnt really matter why im writing this part here

func NextLevel(LHI) -> void:
	#call when player enters stairs
	#LHI - levelhandler instance
	var player_start_coord = LHI.playerChar.hexCoord
	var prevLevel = LHI.levelValAlt
	var newLevel
	if prevLevel.x == 1:
		newLevel = Vector2(prevLevel.x, prevLevel.y + 1)
	else:
		newLevel = Vector2(prevLevel.x + 1, randi()%10)
