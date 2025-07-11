extends GameState
# This state is entered after a player has won a round and the host triggers the tally phase.
# Scores are tallied and displayed. The host can then manually start the next round by clicking on any player.

@onready var players_container: Node2D = $'../../AllPlayersControl/PlayersContainer'

var transient_round_score: PackedScene
var added_children: Array = []
var _state_is_active: bool = false # For early exit

func enter(_params: Dictionary):
	transient_round_score = preload("res://scenes/transient_round_score.tscn")
	Global.dbg("ENTER TallyScoresState")
	_state_is_active = true
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
	var target_position = player_target_node.position
	var target_rotation = player_target_node.rotation
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
	var target_position = player_target_node.position
	var target_rotation = player_target_node.rotation
	var target_scale = player_target_node.scale
	# First, create a reusable score label scene.
	if not _state_is_active: return
	var card_score = transient_round_score.instantiate()
	card_score.z_index = 1000 # arbitrary high value
	added_children.append(card_score)
	var score_label = card_score.get_node("ScoreLabel") as Label
	score_label.text = "+%d" % round_score
	card_score.position = Global.screen_center
	card_score.rotation = 0
	card_score.scale = Vector2(3, 3)
	add_child(card_score)
	# Now animate each card moving to the center of the screen.
	for card_key in Global.private_player_info['card_keys_in_hand']:
		var card = Global.playing_cards[card_key]
		card.z_index = 999 # arbitrary high value
		var card_value = Global.card_key_score(card_key)
		score_label.text = "+%d" % card_value
		card_score.position = card.position
		card_score.rotation = card.rotation
		card_score.scale = card.scale
		var card_tween = card_score.create_tween()
		card_tween.set_parallel(true)
		card_tween.tween_property(card, "position", Global.screen_center, 0.5)
		card_tween.tween_property(card_score, "position", Global.screen_center, 0.5)
		card_tween.tween_property(card, "scale", Vector2(3, 3), 0.5)
		card_tween.tween_property(card_score, "scale", Vector2(4, 4), 0.5)
		await card_tween.finished
		if not _state_is_active: return

		# Now let the card sit in the center for a moment before moving it to the player's score position.
		await get_tree().create_timer(1.0).timeout
		if not _state_is_active: return

		card_tween = card_score.create_tween()
		card_tween.set_parallel(true)
		card_tween.tween_property(card, "position", target_position, 0.5)
		card_tween.tween_property(card_score, "position", target_position, 0.5)
		card_tween.tween_property(card, "rotation", target_rotation, 0.5)
		card_tween.tween_property(card_score, "rotation", target_rotation, 0.5)
		card_tween.tween_property(card, "scale", target_scale, 0.5)
		card_tween.tween_property(card_score, "scale", Vector2(1, 1), 0.5)
		await card_tween.finished
		if not _state_is_active: return

		card.hide()
	if not _state_is_active: return

	# After the very last card has been animated, we can set the player's round score label.
	score_label.text = "+%d" % round_score
	card_score.position = target_position
	card_score.rotation = target_rotation
	card_score.scale = Vector2(1, 1)
