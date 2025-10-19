extends GameState

@export var players_container: Node2D
@export var trophy1_image: CompressedTexture2D
@export var trophy2_image: CompressedTexture2D
@export var trophy3_image: CompressedTexture2D

var trophy1: Sprite2D
var trophy2: Sprite2D
var trophy3: Sprite2D

func enter(_params: Dictionary):
	Global.dbg("ENTER FinalScoresState")
	# Step 0: Create trophy sprites but keep them hidden for now.
	trophy1 = Sprite2D.new()
	trophy1.texture = trophy1_image
	trophy1.visible = false
	trophy1.scale = Vector2(0.01, 0.01)
	trophy1.z_index = 200
	trophy1.position = Global.screen_size * Vector2(0.5, 0.5)
	add_child(trophy1)
	trophy2 = Sprite2D.new()
	trophy2.texture = trophy2_image
	trophy2.visible = false
	trophy2.scale = Vector2(0.01, 0.01)
	trophy2.z_index = 200
	trophy2.position = Global.screen_size * Vector2(0.5, 0.5)
	add_child(trophy2)
	trophy3 = Sprite2D.new()
	trophy3.texture = trophy3_image
	trophy3.visible = false
	trophy3.scale = Vector2(0.01, 0.01)
	trophy3.z_index = 200
	trophy3.position = Global.screen_size * Vector2(0.5, 0.5)
	add_child(trophy3)
	# Step 1: Hide rid of all playing cards on the screen.
	hide_all_playing_cards()
	# Step 2: Sort players by total score (lowest to highest)
	var winning_ids = sort_winning_players_by_score(Global.game_state['public_players_info'])
	Global.dbg("Final scores:")
	Global.dbg("1st place: %s" % str(winning_ids[0]))
	Global.dbg("2nd place: %s" % str(winning_ids[1]))
	Global.dbg("3rd place: %s" % str(winning_ids[2]))
	Global.dbg("remaining: %s" % str(winning_ids[3]))
	# Step 3: Move 4th to last-place players left-to-right across the bottom of the screen.
	await move_fourth_to_last_place_players(winning_ids[3])
	# Step 4: Animated 3rd place trophy presentation.
	await animate_third_place_presentation(winning_ids[2])
	# Step 5: Animated 2nd place trophy presentation.
	await animate_second_place_presentation(winning_ids[1])
	# Step 6: Animated 1st place trophy presentation.
	await animate_first_place_presentation(winning_ids[0])
	# Step 7: Confetti and fireworks animation.
	await animate_final_confetti_and_fireworks()
	# Step 8: Wait for host to click to reset the game. This is handled in player.gd.

func exit():
	Global.dbg("LEAVE FinalScoresState")
	# Free resources
	trophy1.queue_free()
	trophy2.queue_free()
	trophy3.queue_free()

func hide_all_playing_cards() -> void:
	# Clear the pile arrays:
	Global.stock_pile = []
	Global.discard_pile = []
	for card in Global.playing_cards.values():
		card.hide()

func move_fourth_to_last_place_players(remaining_ids: Array) -> void:
	if len(remaining_ids) == 0: return # No players to move.
	# Move each player into place starting with 4th place on the left to last place on the right.
	var tween = players_container.create_tween()
	tween.set_parallel(true)
	var time_duration = 0.5
	var delay = time_duration
	var num_players_to_move = len(remaining_ids)

	for player_rank in range(num_players_to_move):
		var player_id = remaining_ids[player_rank]
		for j in players_container.get_child_count():
			var child = players_container.get_child(j)
			if child.player_id != player_id:
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

func animate_third_place_presentation(player_ids: Array) -> void:
	if len(player_ids) == 0: return # No third place player to present.
	trophy3.visible = true
	var tween = trophy3.create_tween()
	tween.tween_property(trophy3, "scale", Vector2(1.0, 1.0), 1.0)
	await tween.finished

func animate_second_place_presentation(player_ids: Array) -> void:
	trophy2.visible = true
	var tween = trophy2.create_tween()
	tween.tween_property(trophy2, "scale", Vector2(1.0, 1.0), 1.0)
	await tween.finished

func animate_first_place_presentation(player_ids: Array) -> void:
	trophy1.visible = true
	var tween = trophy1.create_tween()
	tween.tween_property(trophy1, "scale", Vector2(1.0, 1.0), 1.0)
	await tween.finished

func animate_final_confetti_and_fireworks() -> void:
	pass

static func sort_winning_players_by_score(public_players_info: Array) -> Array:
	var sorted_players = public_players_info.duplicate()
	sorted_players.sort_custom(func(a, b): return a['score'] < b['score'])
	var result = []
	var obj = next_winners(sorted_players)
	result.append(obj['result'])
	obj = next_winners(obj['remaining_players'])
	result.append(obj['result'])
	obj = next_winners(obj['remaining_players'])
	result.append(obj['result'])
	result.append(obj['remaining_players'].map(func(p): return p['id']))
	return result

static func next_winners(remaining_players: Array) -> Dictionary:
	if len(remaining_players) == 0:
		return {'result': [], 'remaining_players': []}
	var last_score = remaining_players[0]['score']
	var result = []
	while len(remaining_players) > 0 and remaining_players[0]['score'] == last_score:
		var player = remaining_players.pop_front()
		result.append(player['id'])
	return {'result': result, 'remaining_players': remaining_players}