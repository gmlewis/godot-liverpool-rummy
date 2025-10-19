extends GameState

@export var players_container: Node2D

func enter(_params: Dictionary):
	Global.dbg("ENTER FinalScoresState")
	# Step 1: Hide rid of all playing cards on the screen.
	hide_all_playing_cards()
	# Step 2: Sort players by total score (lowest to highest)
	Global.game_state['public_players_info'].sort_custom(func(a, b): return a['score'] < b['score'])
	Global.dbg("Final scores:")
	for player_info in Global.game_state['public_players_info']:
		Global.dbg("Player('%s') total score: %d" % [player_info['name'], player_info['score']])
	# Step 3: Move 4th to last-place players left-to-right across the bottom of the screen.
	await move_fourth_to_last_place_players()
	# Step 4: Animated 3rd place trophy presentation.
	await animate_third_place_presentation()
	# Step 5: Animated 2nd place trophy presentation.
	await animate_second_place_presentation()
	# Step 6: Animated 1st place trophy presentation.
	await animate_first_place_presentation()
	# Step 7: Confetti and fireworks animation.
	await animate_final_confetti_and_fireworks()
	# Step 8: Wait for host to click to reset the game. This is handled in player.gd.

func exit():
	Global.dbg("LEAVE FinalScoresState")

func hide_all_playing_cards() -> void:
	# Clear the pile arrays:
	Global.stock_pile = []
	Global.discard_pile = []
	for card in Global.playing_cards.values():
		card.hide()

func move_fourth_to_last_place_players() -> void:
	if len(Global.game_state['public_players_info']) <= 3:
		return # No fourth to last place players to move.
	# Move each player into place starting with 4th place on the left to last place on the right.
	var tween = players_container.create_tween()
	tween.set_parallel(true)
	var time_duration = 0.5
	var delay = time_duration
	var num_players_to_move = len(Global.game_state['public_players_info']) - 3

	for i in range(3, len(Global.game_state['public_players_info'])):
		var player_info = Global.game_state['public_players_info'][i]
		var player_rank = i - 3
		for j in players_container.get_child_count():
			var child = players_container.get_child(j)
			if child.player_id != player_info['id']:
				continue
			# Spread them evenly across the bottom of the screen using player_rank
			# num_players_to_move == 1 -> 0.5
			# num_players_to_move == 2 -> 0.3333, 0.6666
			# num_players_to_move == 3 -> 0.25, 0.5, 0.75
			# num_players_to_move == 4 -> 0.2, 0.4, 0.6, 0.8
			# num_players_to_move == n -> (1 / (n + 1)), (2 / (n + 1)), ..., (n / (n + 1))
			var target_pos = Global.screen_size * Vector2((player_rank + 1) / float(num_players_to_move + 1), 0.85)
			tween.tween_property(child, "position", target_pos, time_duration).set_delay(delay)
			tween.tween_property(child, "rotation", 0.0, time_duration).set_delay(delay)
			delay += time_duration
	await tween.finished

func animate_third_place_presentation() -> void:
	if len(Global.game_state['public_players_info']) <= 2:
		return # No third place player to present.
	pass

func animate_second_place_presentation() -> void:
	pass

func animate_first_place_presentation() -> void:
	pass

func animate_final_confetti_and_fireworks() -> void:
	pass
