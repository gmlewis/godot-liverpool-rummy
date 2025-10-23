extends GameState
# This state is entered when one player fully satisfies this round's requirements.

func enter(_params: Dictionary):
	Global.dbg("ENTER PlayerWonRoundState")
	# Clear all sparkle shaders (set to fuzzy) for all 3 meld areas
	Global.emit_meld_area_state_changed_signal(false, 0)
	Global.emit_meld_area_state_changed_signal(false, 1)
	Global.emit_meld_area_state_changed_signal(false, 2)
	Global.send_animate_winning_confetti_explosion_signal(5000) # Trigger confetti explosion for 5 seconds

func exit():
	Global.dbg("LEAVE PlayerWonRoundState")
