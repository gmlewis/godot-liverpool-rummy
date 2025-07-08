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
		return Vector2((Global.player_hand_x_start + Global.player_hand_x_end) / 2.0, Global.player_hand_y_position)

	var card_size = card_rects[0].size # All cards are the same size.
	var bounds_min_y = (Global.discard_pile_position.y + Global.player_hand_y_position) / 2.0
	var bounds_max_y = Global.player_hand_y_position
	var bounds_size = Vector2(Global.player_hand_x_end - Global.player_hand_x_start + 2.0 * card_size.x, bounds_max_y - bounds_min_y + 0.5 * card_size.y)
	var bounds_top_left = Vector2(Global.player_hand_x_start - card_size.x, bounds_min_y)
	var players_hand_bounds = Rect2(bounds_top_left, bounds_size)

	# players_container.set_debug_drawing(true)

	return find_minimum_overlap_position_enhanced(card_rects, players_hand_bounds) + Vector2(card_size.x / 2.0, card_size.y / 2.0)

func find_minimum_overlap_position(existing_rects: Array[Rect2], bounds: Rect2) -> Vector2:
	if existing_rects.is_empty():
		# If no existing rects, place at top-left of bounds
		return bounds.position

	# Get the size from the first rect (all are guaranteed to be identical)
	var rect_size = existing_rects[0].size

	# Ensure the new rect can fit within bounds
	if rect_size.x > bounds.size.x or rect_size.y > bounds.size.y:
		push_warning("Rectangle size is larger than bounds")
		return bounds.position

	var best_position = bounds.position
	var min_overlap_area = INF

	# Store debug data instead of drawing immediately
	if players_container.debug_enabled:
		players_container.clear_debug_data()
		players_container.debug_data.bounds = bounds
		players_container.debug_data.existing_rects = existing_rects.duplicate()

	# Define search granularity (smaller values = more precision but slower)
	var step_size = min(rect_size.x, rect_size.y) * 0.25

	var tested_positions = []

	# Search through the bounds area
	var y = bounds.position.y
	while y <= bounds.position.y + bounds.size.y - rect_size.y:
		var x = bounds.position.x
		while x <= bounds.position.x + bounds.size.x - rect_size.x:
			var test_position = Vector2(x, y)
			var test_rect = Rect2(test_position, rect_size)

			var total_overlap = calculate_total_overlap(test_rect, existing_rects)

			# Store for debug visualization
			if players_container.debug_enabled:
				tested_positions.append({"pos": test_position, "overlap": total_overlap, "rect": test_rect})

			# Prefer positions with less overlap, but if overlap is equal or very close,
			# prefer positions with greater y values
			if total_overlap < min_overlap_area or \
			   (abs(total_overlap - min_overlap_area) < 0.01 and test_position.y > best_position.y):
				min_overlap_area = total_overlap
				best_position = test_position

				# Early exit if we found a position with no overlap
				if total_overlap == 0:
					break

			x += step_size
		# Early exit if we found a position with no overlap
		if min_overlap_area == 0:
			break
		y += step_size

	# Store debug data
	if players_container.debug_enabled:
		players_container.debug_data.tested_positions = tested_positions
		players_container.debug_data.best_position = best_position
		players_container.debug_data.best_rect = Rect2(best_position, rect_size)
		players_container.debug_data.min_overlap = min_overlap_area

		# Trigger redraw
		players_container.queue_redraw()

	return best_position

func calculate_total_overlap(test_rect: Rect2, existing_rects: Array[Rect2]) -> float:
	var total_overlap = 0.0

	# Since rects are sorted by x position, we can optimize by breaking early
	for rect in existing_rects:
		# If this rect is too far to the right, all subsequent rects will be too
		if rect.position.x >= test_rect.position.x + test_rect.size.x:
			break

		# If this rect is too far to the left, skip it
		if rect.position.x + rect.size.x <= test_rect.position.x:
			continue

		# Calculate intersection
		var intersection = test_rect.intersection(rect)
		if intersection.has_area():
			total_overlap += intersection.get_area()

	return total_overlap

# Enhanced version that also considers edge positions and corners
func find_minimum_overlap_position_enhanced(existing_rects: Array[Rect2], bounds: Rect2) -> Vector2:
	if existing_rects.is_empty():
		return bounds.position

	var rect_size = existing_rects[0].size

	if rect_size.x > bounds.size.x or rect_size.y > bounds.size.y:
		push_warning("Rectangle size is larger than bounds")
		return bounds.position

	# Store debug data instead of drawing immediately
	if players_container.debug_enabled:
		players_container.clear_debug_data()
		players_container.debug_data.bounds = bounds
		players_container.debug_data.existing_rects = existing_rects.duplicate()

	var best_position = bounds.position
	var min_overlap_area = INF

	# Collect candidate positions from existing rect edges and corners
	var candidate_positions = []

	# Add bounds corners and edges
	candidate_positions.append(bounds.position)
	candidate_positions.append(Vector2(bounds.position.x + bounds.size.x - rect_size.x, bounds.position.y))
	candidate_positions.append(Vector2(bounds.position.x, bounds.position.y + bounds.size.y - rect_size.y))
	candidate_positions.append(Vector2(bounds.position.x + bounds.size.x - rect_size.x, bounds.position.y + bounds.size.y - rect_size.y))

	# Add positions adjacent to existing rectangles
	for rect in existing_rects:
		# Right edge of existing rect
		var right_pos = Vector2(rect.position.x + rect.size.x, rect.position.y)
		if is_position_within_bounds(right_pos, rect_size, bounds):
			candidate_positions.append(right_pos)

		# Left edge of existing rect (new rect to the left)
		var left_pos = Vector2(rect.position.x - rect_size.x, rect.position.y)
		if is_position_within_bounds(left_pos, rect_size, bounds):
			candidate_positions.append(left_pos)

		# Bottom edge of existing rect
		var bottom_pos = Vector2(rect.position.x, rect.position.y + rect.size.y)
		if is_position_within_bounds(bottom_pos, rect_size, bounds):
			candidate_positions.append(bottom_pos)

		# Top edge of existing rect (new rect above)
		var top_pos = Vector2(rect.position.x, rect.position.y - rect_size.y)
		if is_position_within_bounds(top_pos, rect_size, bounds):
			candidate_positions.append(top_pos)

	# Remove duplicates and test all candidate positions
	var unique_candidates = []
	for pos in candidate_positions:
		var is_duplicate = false
		for existing_pos in unique_candidates:
			if pos.distance_to(existing_pos) < 1.0: # Close enough to be considered duplicate
				is_duplicate = true
				break
		if not is_duplicate:
			unique_candidates.append(pos)

	# Test all candidate positions
	var candidate_debug_data = []
	for i in range(unique_candidates.size()):
		var pos = unique_candidates[i]
		var test_rect = Rect2(pos, rect_size)
		var total_overlap = calculate_total_overlap(test_rect, existing_rects)

		# Store candidate data for debug visualization
		if players_container.debug_enabled:
			candidate_debug_data.append({
				"rect": test_rect,
				"overlap": total_overlap,
				"index": i
			})

		# Prefer positions with less overlap, but if overlap is equal or very close,
		# prefer positions with greater y values
		if total_overlap < min_overlap_area or \
		   (abs(total_overlap - min_overlap_area) < 0.01 and pos.y > best_position.y):
			min_overlap_area = total_overlap
			best_position = pos

			if total_overlap == 0:
				break

	# Store debug data
	if players_container.debug_enabled:
		players_container.debug_data.candidate_positions = candidate_debug_data
		players_container.debug_data.best_position = best_position
		players_container.debug_data.best_rect = Rect2(best_position, rect_size)
		players_container.debug_data.min_overlap = min_overlap_area

	# If no perfect position found through candidates, fall back to grid search
	if min_overlap_area > 0:
		# Note: Grid search will have its own debug drawing
		var grid_result = find_minimum_overlap_position(existing_rects, bounds)
		var grid_rect = Rect2(grid_result, rect_size)
		var grid_overlap = calculate_total_overlap(grid_rect, existing_rects)

		# Prefer grid result if it has less overlap, or if overlap is similar but y is greater
		if grid_overlap < min_overlap_area or \
		   (abs(grid_overlap - min_overlap_area) < 0.01 and grid_result.y > best_position.y):
			best_position = grid_result
			min_overlap_area = grid_overlap

			# Update debug data for the new best position
			if players_container.debug_enabled:
				players_container.debug_data.best_position = best_position
				players_container.debug_data.best_rect = Rect2(best_position, rect_size)
				players_container.debug_data.min_overlap = min_overlap_area

	# Trigger redraw for debug visualization
	if players_container.debug_enabled: # and players_container:
		players_container.queue_redraw()

	return best_position

func is_position_within_bounds(pos: Vector2, rect_size: Vector2, bounds: Rect2) -> bool:
	return pos.x >= bounds.position.x and \
		   pos.y >= bounds.position.y and \
		   pos.x + rect_size.x <= bounds.position.x + bounds.size.x and \
		   pos.y + rect_size.y <= bounds.position.y + bounds.size.y
