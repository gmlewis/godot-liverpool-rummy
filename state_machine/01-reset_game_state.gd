extends GameState

func enter(_params: Dictionary):
	Global.dbg("ENTER ResetGameState")
	# Only the host initally resets the game
	if Global.is_server(): Global.reset_game()
	transition_state_to('PreGameSetupState')

#func exit():
	Global.dbg("LEAVE ResetGameState")
