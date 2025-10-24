extends GameState
# This state is entered after a player has won a round and the host triggers the tally phase.
# Scores are tallied and displayed. The host can then manually start the next round by clicking on any player.

@onready var players_container: Node2D = $'../../AllPlayersControl/PlayersContainer'

var transient_round_score: PackedScene
var added_children: Array = []
var _state_is_active: bool = false # For early exit
var rotation_controller = null

func enter(_params: Dictionary):
	transient_round_score = preload("res://scenes/transient_round_score.tscn")
	Global.dbg("ENTER TallyScoresState")
	_state_is_active = true

	# Get rotation controller reference
	rotation_controller = get_tree().root.get_node("RootNode")
	if not rotation_controller:
		Global.error("TallyScoresState: RotationController node not found!")

	# First, if this is the server, total up all bots' scores and share them with all players immediately.
	if Global.is_server():
		for bot_id in Global.bots_private_player_info.keys():
			var bot_private_player_info = Global.bots_private_player_info[bot_id]
			var round_score = Global.tally_hand_cards_score(bot_private_player_info['card_keys_in_hand'])
			bot_private_player_info['score'] += round_score
			var total_score = bot_private_player_info['score']
			var bot_name = bot_private_player_info['name']
			var turn_index = bot_private_player_info['turn_index']
			Global.game_state['public_players_info'][turn_index]['score'] = total_score
			Global.game_state['public_players_info'][turn_index]['played_to_table'] = []
			Global.dbg("Bot('%s') round score: %d, total score: %d, turn_index=%d" % [bot_name, round_score, total_score, turn_index])
			_rpc_receive_round_and_total_score_to_all_players.rpc(turn_index, round_score, total_score)
	_animate_and_send_local_player_score()

func exit():
	Global.dbg("LEAVE TallyScoresState")
	_state_is_active = false
	for child in added_children:
		child.queue_free()
	added_children.clear()

func calculate_position(original_pos: Vector2) -> Vector2:
	if rotation_controller and rotation_controller.get_current_orientation() == 180:
		return Global.screen_center - (original_pos - Global.screen_center)
	return original_pos

func get_rotation_degrees() -> float:
	return 180.0 if (rotation_controller and rotation_controller.get_current_orientation() == 180) else 0.0

@rpc('any_peer', 'call_local', 'reliable')
func _rpc_receive_round_and_total_score_to_all_players(turn_index: int, round_score: int, total_score: int) -> void:
	if not _state_is_active: return
	Global.dbg("TallyScoresState: _rpc_receive_round_and_total_score_to_all_players(turn_index=%d, round_score=%d, total_score=%d)" % [turn_index, round_score, total_score])
	Global.game_state['public_players_info'][turn_index]['score'] = total_score
	Global.game_state['public_players_info'][turn_index]['played_to_table'] = []
	if turn_index == Global.private_player_info['turn_index']:
		# Animate the local player's score change instead of an instant update like is done for other players' scores.
		return
	# Draw a big "+X" (where 'X' is `round_score`) on top of this player's `Player` `Node2D` that will last only for the duration of this state.
	var player_target_node = _get_current_player_node(turn_index)
	var target_position = calculate_position(player_target_node.position)
	var target_rotation = player_target_node.rotation + deg_to_rad(get_rotation_degrees())
	var new_z_index = 10 # just above the player node, but below the animating scores.
	var new_transient_round_score = transient_round_score.instantiate()
	new_transient_round_score.position = target_position
	new_transient_round_score.rotation = target_rotation
	new_transient_round_score.scale = Vector2(1, 1) # just for documentation purposes.
	new_transient_round_score.z_index = new_z_index
	added_children.append(new_transient_round_score)
	var score_label = new_transient_round_score.get_node("ScoreLabel") as Label
	score_label.text = "+%d" % round_score
	add_child(new_transient_round_score)

func _get_current_player_node(turn_index: int) -> Node2D:
	if not _state_is_active: return
	var players = players_container.get_children().filter(func(node): return node.turn_index == turn_index)
	if len(players) != 1:
		push_error("Player node not found for player_idx: %s" % turn_index)
		return
	return players[0]

func _animate_and_send_local_player_score() -> void:
	if not _state_is_active: return
	var turn_index = Global.private_player_info['turn_index']
	var player_name = Global.private_player_info['name']
	var round_score = Global.tally_hand_cards_score(Global.private_player_info['card_keys_in_hand'])
	Global.private_player_info['score'] += round_score
	var total_score = Global.private_player_info['score']
	Global.dbg("Player('%s') round score: %d, total score: %d, turn_index=%d" % [player_name, round_score, total_score, turn_index])
	_rpc_receive_round_and_total_score_to_all_players.rpc(turn_index, round_score, total_score)
	# Now animate each card moving to the center of the screen with its own score label.
	var player_target_node = _get_current_player_node(turn_index)
	var target_position = calculate_position(player_target_node.position)
	var target_rotation = player_target_node.rotation + deg_to_rad(get_rotation_degrees())
	var target_scale = player_target_node.scale
	# First, create a reusable score label scene.
	if not _state_is_active: return
	var card_score = transient_round_score.instantiate()
	card_score.z_index = 1000 # arbitrary high value
	added_children.append(card_score)
	var score_label = card_score.get_node("ScoreLabel") as Label
	score_label.text = "+%d" % round_score
	card_score.position = Global.screen_center
	card_score.rotation = deg_to_rad(get_rotation_degrees())
	card_score.scale = Vector2(3, 3)
	add_child(card_score)
	# Now animate each card moving to the center of the screen.
	for card_key in Global.private_player_info['card_keys_in_hand']:
		var card = Global.playing_cards[card_key]
		card.z_index = 999 # arbitrary high value
		var card_value = Global.card_key_score(card_key)
		score_label.text = "+%d" % card_value
		card_score.position = calculate_position(card.position)
		card_score.rotation = card.rotation + deg_to_rad(get_rotation_degrees())
		card_score.scale = card.scale
		var card_tween = card_score.create_tween()
		card_tween.set_parallel(true)

		# Calculate duration based on distance and deal speed (same as dealing animation)
		var distance_to_center = card.position.distance_to(Global.screen_center)
		var duration_to_center = distance_to_center / Global.deal_speed_pixels_per_second

		card_tween.tween_property(card, "position", Global.screen_center, duration_to_center)
		card_tween.tween_property(card_score, "position", Global.screen_center, duration_to_center)
		card_tween.tween_property(card, "scale", Vector2(3, 3), duration_to_center)
		card_tween.tween_property(card_score, "scale", Vector2(4, 4), duration_to_center)
		# Keep cards at rotation 0 (upright) when moving to center, regardless of screen orientation
		card_tween.tween_property(card, "rotation", 0.0, duration_to_center)
		card_tween.tween_property(card_score, "rotation", deg_to_rad(get_rotation_degrees()), duration_to_center)
		await card_tween.finished
		if not _state_is_active: return

		# Now let the card sit in the center for a moment before moving it to the player's score position.
		await get_tree().create_timer(0.3).timeout # Reduced from 1.0 to 0.3 seconds
		if not _state_is_active: return

		# Calculate duration for movement from center to player position
		var distance_to_player = Global.screen_center.distance_to(target_position)
		var duration_to_player = distance_to_player / Global.deal_speed_pixels_per_second

		card_tween = card_score.create_tween()
		card_tween.set_parallel(true)
		card_tween.tween_property(card, "position", target_position, duration_to_player)
		card_tween.tween_property(card_score, "position", target_position, duration_to_player)
		card_tween.tween_property(card, "rotation", target_rotation, duration_to_player)
		card_tween.tween_property(card_score, "rotation", target_rotation, duration_to_player)
		card_tween.tween_property(card, "scale", target_scale, duration_to_player)
		card_tween.tween_property(card_score, "scale", Vector2(1, 1), duration_to_player)
		await card_tween.finished
		if not _state_is_active: return

		card.hide()
	if not _state_is_active: return

	# After the very last card has been animated, we can set the player's round score label.
	score_label.text = "+%d" % round_score
	card_score.position = target_position
	card_score.rotation = target_rotation
	card_score.scale = Vector2(1, 1)
