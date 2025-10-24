extends GameState
# This state is entered when a player has drawn a card from either pile
# and must complete their turn by either discarding a card or playing their
# tableau in the final round.

@onready var playing_cards_control: Control = $'../../PlayingCardsControl'
@onready var players_container: Node2D = $'../../AllPlayersControl/PlayersContainer'

var is_my_turn: bool = false

const REVEAL_MELD_SCALE = Vector2(0.25, 0.25)

# TODO: Buy requests should be disallowed and ignored in this state!

func enter(_params: Dictionary):
	is_my_turn = Global.is_my_turn()
	Global.dbg("ENTER PlayerDrewState: is_my_turn=%s" % [str(is_my_turn)])
	Global.connect('card_clicked_signal', _on_card_clicked_signal)
	Global.connect('card_drag_started_signal', _on_card_drag_started_signal)
	Global.connect('card_moved_signal', _on_card_moved_signal)
	Global.connect('animate_move_card_from_player_to_discard_pile_signal', _on_animate_move_card_from_player_to_discard_pile_signal)
	Global.connect('animate_personally_meld_cards_only_signal', _on_animate_personally_meld_cards_only_signal)
	Global.connect('animate_publicly_meld_card_only_signal', _on_animate_publicly_meld_card_only_signal)
	Global.connect('animate_reorder_run_cards_signal', _on_animate_reorder_run_cards_signal)

	# MUST discard - do not enable tap or drag of either pile.
	if len(Global.discard_pile) > 0:
		Global.discard_pile[0].is_draggable = false
		Global.discard_pile[0].is_tappable = false
	if len(Global.stock_pile) > 0:
		Global.stock_pile[0].is_draggable = false
		Global.stock_pile[0].is_tappable = false


func exit():
	Global.dbg("LEAVE PlayerDrewState")
	Global.disconnect('card_clicked_signal', _on_card_clicked_signal)
	Global.disconnect('card_drag_started_signal', _on_card_drag_started_signal)
	Global.disconnect('card_moved_signal', _on_card_moved_signal)
	Global.disconnect('animate_move_card_from_player_to_discard_pile_signal', _on_animate_move_card_from_player_to_discard_pile_signal)
	Global.disconnect('animate_personally_meld_cards_only_signal', _on_animate_personally_meld_cards_only_signal)
	Global.disconnect('animate_publicly_meld_card_only_signal', _on_animate_publicly_meld_card_only_signal)
	Global.disconnect('animate_reorder_run_cards_signal', _on_animate_reorder_run_cards_signal)

func _on_card_clicked_signal(_playing_card, _global_position):
	pass

func _on_card_drag_started_signal(_playing_card, _from_position):
	pass

func _on_card_moved_signal(_playing_card, _from_position, _global_position):
	pass


func _on_animate_move_card_from_player_to_discard_pile_signal(playing_card: PlayingCard, player_id: String, player_won: bool, ack_sync_name: String) -> void:
	Global.dbg("07-player_drew_state: _on_animate_move_card_from_player_to_discard_pile_signal: player_id='%s', card='%s', player_won=%s" % [player_id, playing_card.key, player_won])
	var players = players_container.get_children().filter(func(node): return node.player_id == player_id)
	if len(players) != 1:
		push_error("Player node not found for player_id: %s" % player_id)
		return
	var player = players[0] as Node2D
	var players_by_id = Global.get_players_by_id()
	var player_public_info = players_by_id[player_id]
	Global.dbg("07-player_drew_state: BEFORE decrement: player_id='%s', num_cards=%d" % [player_id, player_public_info['num_cards']])
	player_public_info['num_cards'] -= 1
	Global.dbg("07-player_drew_state: AFTER decrement: player_id='%s', num_cards=%d, player_won=%s" % [player_id, player_public_info['num_cards'], player_won])
	player._on_game_state_updated_signal() # Update the player's UI
	if not playing_card.is_face_up and not player_won:
		playing_card.flip_card() # Flip the card to face-up for the local player so it can be seen while animating
	# elif playing_card.is_face_up and player_won:
	# 	playing_card.flip_card() # Flip the card to face-down for the winning local player

	var card_tween = playing_cards_control.create_tween()
	card_tween.set_parallel(true)
	tween_card_to_discard_pile(player, player_id, card_tween, playing_card, player_won)
	await card_tween.finished
	Global.dbg("07-player_drew_state: animation finished, ack_sync_name='%s'" % [ack_sync_name])
	if ack_sync_name:
		Global.ack_sync_completed(ack_sync_name)

func _on_animate_personally_meld_cards_only_signal(player_id: String, hand_evaluation: Dictionary, ack_sync_name: String) -> void:
	# var player_is_me = Global.private_player_info.id == player_id
	var players = players_container.get_children().filter(func(node): return node.player_id == player_id)
	if len(players) != 1:
		push_error("Player node not found for player_id: %s" % player_id)
		return
	var player = players[0] as Node2D
	var players_by_id = Global.get_players_by_id()
	var player_public_info = players_by_id[player_id]

	var meld_tween = playing_cards_control.create_tween()
	meld_tween.set_parallel(true)

	for meld_idx in len(hand_evaluation['can_be_personally_melded']):
		var meld_group = hand_evaluation['can_be_personally_melded'][meld_idx]
		var meld_group_card_keys = meld_group['card_keys']
		for card_idx in len(meld_group_card_keys):
			var card_key = meld_group_card_keys[card_idx]
			player_public_info['num_cards'] -= 1
			var playing_card = Global.playing_cards.get(card_key) as PlayingCard
			tween_card_into_personal_meld_group(player, player_id, meld_tween, playing_card, meld_idx, card_idx)

	await meld_tween.finished
	if ack_sync_name:
		Global.ack_sync_completed(ack_sync_name)
	if Global.game_state.current_round_num == 7 and player_public_info['num_cards'] == 0:
		transition_state_to('PlayerWonRoundState')

func _on_animate_publicly_meld_card_only_signal(_player_id: String, card_key: String, target_player_id: String, meld_group_index: int, ack_sync_name: String) -> void:
	Global.dbg("=== PUBLIC MELD DEBUG: _player_id='%s', card_key='%s', target_player_id='%s', meld_group_index=%d ===" % [_player_id, card_key, target_player_id, meld_group_index])

	var players = players_container.get_children().filter(func(node): return node.player_id == target_player_id)
	if len(players) != 1:
		push_error("Player node not found for target_player_id: %s" % target_player_id)
		return
	var target_player = players[0] as Node2D
	var players_by_id = Global.get_players_by_id()
	# Decrement card count for the player WHO is publicly melding (not the target player)
	var melding_player_public_info = players_by_id[_player_id]
	melding_player_public_info['num_cards'] -= 1
	# Get the target player's meld group (where the card is being added)
	var player_public_info = players_by_id[target_player_id]
	var meld_group = player_public_info['played_to_table'][meld_group_index]

	Global.dbg("PUBLIC MELD DEBUG: meld_group BEFORE adding card: %s" % str(meld_group))

	var card_idx = len(meld_group['card_keys']) - 1

	Global.dbg("PUBLIC MELD DEBUG: card_idx=%d, card will be positioned at index %d in meld" % [card_idx, card_idx])
	Global.dbg("PUBLIC MELD DEBUG: meld_group type='%s', card_keys=%s" % [meld_group.get('type', 'UNKNOWN'), str(meld_group['card_keys'])])

	var playing_card = Global.playing_cards.get(card_key) as PlayingCard
	if not playing_card.is_face_up:
		playing_card.flip_card()
	var meld_tween = playing_cards_control.create_tween()
	meld_tween.set_parallel(true)
	tween_card_into_personal_meld_group(target_player, target_player_id, meld_tween, playing_card, meld_group_index, card_idx)
	await meld_tween.finished
	if ack_sync_name:
		Global.ack_sync_completed(ack_sync_name)

func tween_card_into_personal_meld_group(player: Node2D, player_id: String, meld_tween: Tween, playing_card: PlayingCard, meld_idx: int, card_idx: int) -> void:
	Global.dbg("PUBLIC MELD DEBUG: tween_card_into_personal_meld_group: player_id='%s', card='%s', meld_idx=%d, card_idx=%d" % [player_id, playing_card.key, meld_idx, card_idx])

	var player_is_me = Global.private_player_info.id == player_id
	if not player_is_me:
		playing_card.position = player.position
		playing_card.rotation = player.rotation

	Global.dbg("PUBLIC MELD DEBUG: card starting position: %s" % str(playing_card.position))

	playing_card.is_draggable = false
	playing_card.is_tappable = false
	playing_card.z_index = 20 # TODO
	playing_card.show()
	# if not playing_card.is_face_up: # TODO
	# 	await playing_card.flip_card()

	var meld_pile_position = player.position + Vector2(75 * meld_idx - 50, 200 + 25 * card_idx)

	Global.dbg("PUBLIC MELD DEBUG: calculated meld_pile_position: %s (player.pos=%s, offset=Vector2(%f, %f))" % [str(meld_pile_position), str(player.position), 75.0 * meld_idx - 50, 200 + 25 * card_idx])

	var card_travel_distance = meld_pile_position.distance_to(playing_card.position)
	var card_duration = card_travel_distance / Global.play_speed_pixels_per_second

	meld_tween.tween_property(playing_card, "position", meld_pile_position, card_duration)
	meld_tween.tween_property(playing_card, "rotation", 0.0, card_duration)
	meld_tween.tween_property(playing_card, "scale", REVEAL_MELD_SCALE, card_duration)
	meld_tween.tween_property(playing_card, "z_index", 2 + card_idx, card_duration)

	# Flip the card after it lands
	var hide_or_flip_card = func() -> void:
		if not playing_card.is_face_up:
			playing_card.flip_card() # Flip the card for the local player
	meld_tween.tween_callback(hide_or_flip_card).set_delay(card_duration)

func tween_card_to_discard_pile(player: Node2D, player_id: String, discard_tween: Tween, playing_card: PlayingCard, is_winning_hand: bool) -> void:
	var player_is_me = Global.private_player_info.id == player_id
	if not player_is_me:
		playing_card.position = player.position
		playing_card.rotation = player.rotation
	playing_card.is_draggable = false
	playing_card.is_tappable = false
	playing_card.z_index = len(Global.discard_pile)
	playing_card.show()

	var discard_pile_position = Global.discard_pile_position + Vector2(randf_range(-2, 2), -playing_card.z_index * Global.CARD_SPACING_IN_STACK)
	var card_travel_distance = discard_pile_position.distance_to(playing_card.position)
	var card_duration = card_travel_distance / Global.play_speed_pixels_per_second

	discard_tween.tween_property(playing_card, "position", discard_pile_position, card_duration)
	var rotation = randf_range(-0.1, 0.1)
	discard_tween.tween_property(playing_card, "rotation", rotation, card_duration)

	# Flip the card after it lands
	var hide_or_flip_card = func() -> void:
		if not playing_card.is_face_up and not is_winning_hand:
			playing_card.flip_card() # Flip the card to face up
		elif playing_card.is_face_up and is_winning_hand:
			playing_card.flip_card() # Flip the card to face down
	discard_tween.tween_callback(hide_or_flip_card).set_delay(card_duration)

func _on_animate_reorder_run_cards_signal(player_id: String, card_key: String, target_player_id: String, meld_group_index: int, sorted_card_keys: Array, ack_sync_name: String) -> void:
	Global.dbg("=== REORDER RUN DEBUG: player_id='%s', card_key='%s', target_player_id='%s', meld_group_index=%d, sorted_card_keys=%s ===" % [player_id, card_key, target_player_id, meld_group_index, str(sorted_card_keys)])

	var players = players_container.get_children().filter(func(node): return node.player_id == target_player_id)
	if len(players) != 1:
		push_error("Player node not found for target_player_id: %s" % target_player_id)
		if ack_sync_name:
			Global.ack_sync_completed(ack_sync_name)
		return
	var target_player = players[0] as Node2D

	# Decrement card count for the player WHO is publicly melding (not the target player)
	var players_by_id = Global.get_players_by_id()
	var melding_player_public_info = players_by_id[player_id]
	melding_player_public_info['num_cards'] -= 1

	# Create a tween to animate all cards in the run to their new positions
	var reorder_tween = playing_cards_control.create_tween()
	reorder_tween.set_parallel(true)

	for card_idx in range(len(sorted_card_keys)):
		var sorted_card_key = sorted_card_keys[card_idx]
		var playing_card = Global.playing_cards.get(sorted_card_key) as PlayingCard
		if not playing_card:
			Global.error("REORDER RUN DEBUG: PlayingCard not found for key '%s'" % sorted_card_key)
			continue
		# Check if this is the newly added card (needs full setup)
		var is_new_card = (sorted_card_key == card_key)

		if is_new_card:
			# Set up the newly added card similar to tween_card_into_personal_meld_group
			var player_is_me = Global.private_player_info.id == target_player_id
			if not player_is_me:
				playing_card.position = target_player.position
				playing_card.rotation = target_player.rotation
			playing_card.is_draggable = false
			playing_card.is_tappable = false
			playing_card.z_index = 20 # Start high, will tween down

		if not playing_card.is_face_up:
			playing_card.flip_card()
		playing_card.show()

		var new_position = target_player.position + Vector2(75 * meld_group_index - 50, 200 + 25 * card_idx)
		var new_z_index = 2 + card_idx
		var card_travel_distance = new_position.distance_to(playing_card.position)
		var card_duration = card_travel_distance / Global.play_speed_pixels_per_second
		reorder_tween.tween_property(playing_card, "position", new_position, card_duration)
		reorder_tween.tween_property(playing_card, "z_index", new_z_index, card_duration)

		if is_new_card:
			# Also tween rotation and scale for the new card
			reorder_tween.tween_property(playing_card, "rotation", 0.0, card_duration)
			reorder_tween.tween_property(playing_card, "scale", REVEAL_MELD_SCALE, card_duration)

		Global.dbg("REORDER RUN DEBUG: Moving card '%s' to position %s with z_index %d%s" % [sorted_card_key, str(new_position), new_z_index, " (NEW CARD)" if is_new_card else ""])

	await reorder_tween.finished
	if ack_sync_name:
		Global.ack_sync_completed(ack_sync_name)
