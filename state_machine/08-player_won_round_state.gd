extends GameState
# This state is entered when one player fully satisfies this round's requirements.

func enter(_params: Dictionary):
	Global.dbg("ENTER PlayerWonRoundState")
	Global.send_animate_winning_confetti_explosion_signal(5000) # Trigger confetti explosion for 5 seconds

func exit():
	Global.dbg("LEAVE PlayerWonRoundState")
