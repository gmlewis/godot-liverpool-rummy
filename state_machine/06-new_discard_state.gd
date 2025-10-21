extends GameState

@onready var playing_cards_control: Control = $'../../PlayingCardsControl'
@onready var players_container: Node2D = $'../../AllPlayersControl/PlayersContainer'

var is_my_turn: bool = false

func enter(_params: Dictionary):
	is_my_turn = Global.is_my_turn()
	Global.dbg("ENTER NewDiscardState: is_my_turn=%s" % [str(is_my_turn)])
	Global.connect('card_clicked_signal', _on_card_clicked_signal)
	Global.connect('card_drag_started_signal', _on_card_drag_started_signal)
	Global.connect('card_moved_signal', _on_card_moved_signal)
	Global.connect('animate_move_card_to_player_signal', _on_animate_move_card_to_player_signal)
	Global.connect('new_card_exposed_on_discard_pile_signal', _on_new_card_exposed_on_discard_pile_signal)
	_on_new_card_exposed_on_discard_pile_signal()

func _start_grace_period_animation() -> void:
	var countdown = preload("res://scenes/countdown_timer.tscn").instantiate()
	add_child(countdown)

func _on_new_card_exposed_on_discard_pile_signal() -> void:
	sanitize_discard_pile()
	if is_my_turn:
		if len(Global.discard_pile) > 0:
			Global.discard_pile[0].is_draggable = false
			Global.discard_pile[0].is_tappable = true
			# After the grace period, allow the player to draw from the stock pile.
			if len(Global.stock_pile) > 0:
				Global.dbg("06-new_discard_state: enter: is_my_turn=true, making stock pile untappable before awaiting grace period")
				Global.stock_pile[0].is_tappable = false
				Global.dbg("06-new_discard_state: enter: is_my_turn=true, calling await_grace_period before making stock pile tappable")
				if len(Global.game_state.public_players_info) > 2 and Global.number_human_players() > 1:
					# Only do the grace period animation if there are more than 2 players AND more than 1 human player.
					_start_grace_period_animation()
					await Global.await_grace_period()
				Global.stock_pile[0].is_draggable = false
				Global.dbg("06-new_discard_state: enter: is_my_turn=true, making stock pile tappable after awaiting grace period: card_key='%s', z_index=%d, position=%s" % [Global.stock_pile[0].key, Global.stock_pile[0].z_index, str(Global.stock_pile[0].position)])
				Global.stock_pile[0].is_tappable = true
		elif len(Global.stock_pile) > 0:
			Global.stock_pile[0].is_draggable = false
			Global.dbg("06-new_discard_state: enter: is_my_turn=true, NO DISCARD PILE! making stock pile tappable immediately: card_key='%s', z_index=%d, position=%s" % [Global.stock_pile[0].key, Global.stock_pile[0].z_index, str(Global.stock_pile[0].position)])
			Global.stock_pile[0].is_tappable = true
	else:
		if len(Global.discard_pile) > 0:
			Global.discard_pile[0].is_draggable = false
			Global.discard_pile[0].is_tappable = true # for buying the discard card
		if len(Global.stock_pile) > 0:
			Global.stock_pile[0].is_draggable = false
			Global.dbg("06-new_discard_state: enter: is_my_turn=false, making stock pile untappable immediately: card_key='%s', z_index=%d, position=%s" % [Global.stock_pile[0].key, Global.stock_pile[0].z_index, str(Global.stock_pile[0].position)])
			Global.stock_pile[0].is_tappable = false

func exit():
	Global.dbg("LEAVE NewDiscardState")
	Global.disconnect('card_clicked_signal', _on_card_clicked_signal)
	Global.disconnect('card_drag_started_signal', _on_card_drag_started_signal)
	Global.disconnect('card_moved_signal', _on_card_moved_signal)
	Global.disconnect('animate_move_card_to_player_signal', _on_animate_move_card_to_player_signal)
	Global.disconnect('new_card_exposed_on_discard_pile_signal', _on_new_card_exposed_on_discard_pile_signal)

func sanitize_discard_pile():
	var z_index = len(Global.discard_pile)
	for idx in range(len(Global.discard_pile)):
		var playing_card = Global.discard_pile[idx]
		playing_card.is_draggable = false
		playing_card.is_tappable = false
		playing_card.z_index = z_index
		playing_card.position = Global.discard_pile_position + Vector2(randf_range(-2, 2), -z_index * Global.CARD_SPACING_IN_STACK)
		playing_card.rotation = randf_range(-0.1, 0.1) # Small random rotation for visual effect
		playing_card.show()
		# # If the card is face down, flip it over.
		# if not playing_card.is_face_up: # SHOULD NOT HAPPEN
		# 	playing_card.flip_card()
		z_index -= 1

func _on_card_clicked_signal(_playing_card, _global_position):
	pass

func _on_card_drag_started_signal(_playing_card, _from_position):
	pass

func _on_card_moved_signal(_playing_card, _from_position, _global_position):
	pass

func _on_animate_move_card_to_player_signal(playing_card: PlayingCard, player_id: String, ack_sync_name: String) -> void:
	var player_is_me = Global.private_player_info.id == player_id
	# if player_is_me:
	# 	# TODO: Figure out how to move the card or let the player do it.
	# 	pass
	# else:
	var players = players_container.get_children().filter(func(node): return node.player_id == player_id)
	if len(players) != 1:
		push_error("Player node not found for player_id: %s" % player_id)
		return
	var player_target_node = players[0]
	var target_position = player_target_node.position
	var target_rotation = player_target_node.rotation
	var new_z_index = 100 # arbitrary high value
	if player_is_me:
		new_z_index = Global.sanitize_players_hand_z_index_values()
		# target_position = Vector2(playing_card.position.x, Global.player_hand_y_position)
		target_position = _get_next_card_position_in_players_hand()
		target_rotation = 0.0
	var card_travel_distance = target_position.distance_to(playing_card.position)
	var card_duration = card_travel_distance / Global.play_speed_pixels_per_second

	var card_tween = playing_cards_control.create_tween()
	card_tween.set_parallel(true)
	card_tween.tween_property(playing_card, "position", target_position, card_duration)
	card_tween.tween_property(playing_card, "rotation", target_rotation, card_duration)
	card_tween.tween_property(playing_card, "z_index", new_z_index, card_duration)

	# Hide or flip the card after it lands
	var hide_or_flip_card = func() -> void:
		var players_by_id = Global.get_players_by_id()
		var player_public_info = players_by_id[player_id]
		player_public_info['num_cards'] += 1 # Increment the number of cards for this player
		player_target_node._on_game_state_updated_signal() # Update the player's UI
		if player_is_me:
			if not playing_card.is_face_up:
				playing_card.flip_card() # Flip the card for the local player
			playing_card.is_draggable = true
			playing_card.is_tappable = true
		else:
			playing_card.hide() # Hide the card for remote players
			playing_card.is_draggable = false
			playing_card.is_tappable = false
	card_tween.tween_callback(hide_or_flip_card).set_delay(card_duration)
	await card_tween.finished
	if ack_sync_name:
		Global.ack_sync_completed(ack_sync_name)

# This function returns the most-open position along the x-axis in the player's hand
# where a new card can be placed. If there is not enough space, it chooses the least-crowded
# x-value and then it reduces the y-value of the position until the top third of the card is visible.
func _get_next_card_position_in_players_hand() -> Vector2:
	var card_rects = [] as Array[Rect2]
	for card_key in Global.private_player_info['card_keys_in_hand']:
		var playing_card = Global.playing_cards.get(card_key) as PlayingCard
		if playing_card:
			var card_rect = playing_card.get_rect()
			Global.dbg("PlayingCard: _get_next_card_position_in_players_hand: card_key=%s, rect=%s" % [card_key, str(card_rect)])
			card_rects.append(playing_card.get_rect())
	card_rects.sort_custom(func(a, b): return a.position.x < b.position.x)

	if len(card_rects) == 0:
		return Vector2((Global.player_hand_x_start() + Global.player_hand_x_end) / 2.0, Global.player_hand_y_position)

	var card_size = card_rects[0].size # All cards are the same size.
	var bounds_min_y = (Global.discard_pile_position.y + Global.player_hand_y_position) / 2.0
	var bounds_max_y = Global.player_hand_y_position
	var bounds_size = Vector2(Global.player_hand_x_end - Global.player_hand_x_start() + 2.0 * card_size.x, bounds_max_y - bounds_min_y + 0.5 * card_size.y)
	var bounds_top_left = Vector2(Global.player_hand_x_start() - card_size.x, bounds_min_y)
	var players_hand_bounds = Rect2(bounds_top_left, bounds_size)

	# players_container.set_debug_drawing(true)

	return find_leftmost_available_position(card_rects, players_hand_bounds) + Vector2(card_size.x / 2.0, card_size.y / 2.0)

func find_leftmost_available_position(existing_rects: Array[Rect2], bounds: Rect2) -> Vector2:
	if existing_rects.is_empty():
		return bounds.position

	var rect_size = existing_rects[0].size

	if rect_size.x > bounds.size.x or rect_size.y > bounds.size.y:
		push_warning("Rectangle size is larger than bounds")
		return bounds.position

	# Sort existing rects by x position (they should already be sorted, but ensure it)
	existing_rects.sort_custom(func(a, b): return a.position.x < b.position.x)

	# Try to place the card in the leftmost available position
	var current_x = bounds.position.x

	# Check each gap between existing cards and at the end
	for i in range(existing_rects.size()):
		var existing_rect = existing_rects[i]
		var gap_start = current_x
		var gap_end = existing_rect.position.x

		# Check if there's enough space in this gap
		if gap_end - gap_start >= rect_size.x:
			# Found a gap! Place the card at the left edge of this gap
			return Vector2(gap_start, bounds.position.y)

		# Move current_x to the right edge of this card
		current_x = max(current_x, existing_rect.position.x + existing_rect.size.x)

	# Check the space after the last card
	var final_gap_start = current_x
	var final_gap_end = bounds.position.x + bounds.size.x

	if final_gap_end - final_gap_start >= rect_size.x:
		return Vector2(final_gap_start, bounds.position.y)

	# No space found, place at the rightmost position as fallback
	return Vector2(bounds.position.x + bounds.size.x - rect_size.x, bounds.position.y)
