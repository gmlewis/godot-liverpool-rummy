extends GameState

@export var players_container: Node2D
@export var trophy1_image: CompressedTexture2D
@export var trophy2_image: CompressedTexture2D
@export var trophy3_image: CompressedTexture2D

@onready var state_advance_button: TextureButton = $'../../HUDLayer/Control/StateAdvanceButton'

var trophy1: Sprite2D
var trophy2: Sprite2D
var trophy3: Sprite2D
var continue_confetti: bool = false

const TROPHY1_YPOS_FACTOR = 0.2
const TROPHY2_YPOS_FACTOR = 0.4
const TROPHY3_YPOS_FACTOR = 0.6
const REMAINING_PLAYERS_YPOS_FACTOR = 0.85
const FINAL_TROPHY_SCALE = Vector2(0.25, 0.25)
const TROPHY_MOVE_DURATION = 0.5
const TROPHY_SPACING_FACTOR = 8 # as if fitting # items next to each other, centered

func enter(_params: Dictionary):
	Global.dbg("ENTER FinalScoresState")
	# Step 0: Create trophy sprites but keep them hidden for now.
	trophy1 = make_trophy(trophy1_image)
	trophy2 = make_trophy(trophy2_image)
	trophy3 = make_trophy(trophy3_image)
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
	# Step 7: Start confetti and fireworks animation but don't wait for it.
	animate_final_confetti_and_fireworks()
	# Step 8: Wait for host to click to reset the game. This is handled in player.gd.
	_setup_state_advance_button()
	state_advance_button.show()

func exit():
	Global.dbg("LEAVE FinalScoresState")
	continue_confetti = false
	# Hide the button and disconnect signal when leaving state
	if state_advance_button.visible:
		state_advance_button.hide()
		if state_advance_button.pressed.is_connected(_on_state_advance_button_pressed):
			state_advance_button.pressed.disconnect(_on_state_advance_button_pressed)
	# Free resources
	trophy1.queue_free()
	trophy2.queue_free()
	trophy3.queue_free()

func make_trophy(image: CompressedTexture2D) -> Sprite2D:
	var trophy = Sprite2D.new()
	trophy.texture = image
	trophy.visible = false
	trophy.scale = Vector2(0.01, 0.01)
	trophy.z_index = 200
	trophy.position = Global.screen_size * Vector2(0.5, 0.5)
	var all_players_control = get_tree().root.get_node("/root/RootNode/AllPlayersControl")
	all_players_control.add_child(trophy)
	return trophy

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
	var time_duration = TROPHY_MOVE_DURATION
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
			var target_pos = Global.screen_size * Vector2((player_rank + 1) / float(num_players_to_move + 1), REMAINING_PLAYERS_YPOS_FACTOR)
			tween.tween_property(child, "position", target_pos, time_duration).set_delay(delay).set_ease(Tween.EASE_OUT_IN)
			tween.tween_property(child, "rotation", 0.0, time_duration).set_delay(delay).set_ease(Tween.EASE_OUT_IN)
			delay += time_duration
	await tween.finished

func item_xpercent(item_index: int, num_items: int) -> float:
	var total_width = float(num_items) / float(TROPHY_SPACING_FACTOR + 1)
	var left_edge = 0.5 - total_width / 2.0
	var right_edge = 0.5 + total_width / 2.0
	var final_percent = left_edge + (item_index + 1) * (right_edge - left_edge) / float(num_items + 1)
	Global.dbg("item_xpercent: item_index=%d, num_items=%d, left_edge=%0.2f, right_edge=%0.2f, final_percent=%0.2f" % [item_index, num_items, left_edge, right_edge, final_percent])
	return final_percent

func animate_third_place_presentation(player_ids: Array) -> void:
	if len(player_ids) == 0: return # No third place player to present.
	await animate_trophy_placement(player_ids, trophy3, TROPHY3_YPOS_FACTOR)
	await animate_trophy_winners(player_ids, TROPHY3_YPOS_FACTOR)

func animate_second_place_presentation(player_ids: Array) -> void:
	await animate_trophy_placement(player_ids, trophy2, TROPHY2_YPOS_FACTOR)
	await animate_trophy_winners(player_ids, TROPHY2_YPOS_FACTOR)

func animate_first_place_presentation(player_ids: Array) -> void:
	await animate_trophy_placement(player_ids, trophy1, TROPHY1_YPOS_FACTOR)
	await animate_trophy_winners(player_ids, TROPHY1_YPOS_FACTOR)

func animate_trophy_placement(player_ids: Array, trophy: Sprite2D, ypos_factor: float) -> void:
	trophy.visible = true
	var tween = trophy.create_tween()
	tween.tween_property(trophy, "scale", Vector2(1.0, 1.0), TROPHY_MOVE_DURATION).set_ease(Tween.EASE_OUT_IN)
	await tween.finished
	await get_tree().create_timer(TROPHY_MOVE_DURATION).timeout
	var num_items = len(player_ids) + 1
	var target_pos = Global.screen_size * Vector2(item_xpercent(0, num_items), ypos_factor)
	tween = trophy.create_tween()
	tween.set_parallel(true)
	tween.tween_property(trophy, "scale", FINAL_TROPHY_SCALE, TROPHY_MOVE_DURATION).set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(trophy, "position", target_pos, TROPHY_MOVE_DURATION).set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(trophy, "z_index", 0, TROPHY_MOVE_DURATION).set_ease(Tween.EASE_OUT_IN)
	await tween.finished

func animate_trophy_winners(player_ids: Array, ypos_factor: float) -> void:
	var num_items = len(player_ids) + 1
	var tween = players_container.create_tween()
	tween.set_parallel(true)
	var time_duration = TROPHY_MOVE_DURATION
	var delay = time_duration
	for player_rank in range(len(player_ids)):
		var player_id = player_ids[player_rank]
		for j in players_container.get_child_count():
			var child = players_container.get_child(j)
			if child.player_id != player_id:
				continue
			var original_scale = child.scale
			var target_pos = Global.screen_size * Vector2(0.5, 0.5)
			tween.tween_property(child, "scale", Vector2(3.0, 3.0), time_duration).set_delay(delay).set_ease(Tween.EASE_OUT_IN)
			tween.tween_property(child, "position", target_pos, time_duration).set_delay(delay).set_ease(Tween.EASE_OUT_IN)
			tween.tween_property(child, "rotation", 0.0, time_duration).set_delay(delay).set_ease(Tween.EASE_OUT_IN)
			tween.tween_property(child, "z_index", 200, time_duration).set_delay(delay).set_ease(Tween.EASE_OUT_IN)
			delay += 2 * time_duration
			target_pos = Global.screen_size * Vector2(item_xpercent(player_rank + 1, num_items), ypos_factor)
			tween.tween_property(child, "scale", original_scale, time_duration).set_delay(delay).set_ease(Tween.EASE_OUT_IN)
			tween.tween_property(child, "position", target_pos, time_duration).set_delay(delay).set_ease(Tween.EASE_OUT_IN)
			tween.tween_property(child, "z_index", 0, time_duration).set_delay(delay).set_ease(Tween.EASE_OUT_IN)
			delay += time_duration
	await tween.finished
	await get_tree().create_timer(TROPHY_MOVE_DURATION).timeout

func animate_final_confetti_and_fireworks() -> void:
	# TODO: fireworks
	continue_confetti = true
	while continue_confetti:
		Global.send_animate_winning_confetti_explosion_signal(5000)
		await get_tree().create_timer(5.0).timeout

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

func _setup_state_advance_button() -> void:
	# Load the appropriate SVG based on language
	var texture_path: String
	if Global.LANGUAGE == 'de':
		texture_path = "res://svgs/main-menu-german.svg"
	else:
		texture_path = "res://svgs/main-menu-english.svg"

	var texture = load(texture_path)
	state_advance_button.texture_normal = texture
	state_advance_button.texture_pressed = texture
	state_advance_button.texture_hover = texture

	# Enable texture scaling
	state_advance_button.ignore_texture_size = true
	state_advance_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

	# Resize button to 25% of screen width while maintaining aspect ratio
	var target_width = Global.screen_size.x * 0.25
	var texture_size = texture.get_size()
	var aspect_ratio = texture_size.y / texture_size.x
	var target_height = target_width * aspect_ratio

	state_advance_button.custom_minimum_size = Vector2(target_width, target_height)
	state_advance_button.size = Vector2(target_width, target_height)

	# Position button at 25% of screen width (left side), centered vertically
	# Calculate position offset from center anchor (0.5, 0.5)
	var target_x_center = Global.screen_size.x * 0.25
	var screen_center_x = Global.screen_size.x * 0.5
	var x_offset_from_center = target_x_center - screen_center_x

	state_advance_button.offset_left = x_offset_from_center - target_width / 2.0
	state_advance_button.offset_top = - target_height / 2.0
	state_advance_button.offset_right = x_offset_from_center + target_width / 2.0
	state_advance_button.offset_bottom = target_height / 2.0

	# Set z_index to be above confetti and trophies
	state_advance_button.z_index = 1000

	# Connect the button press signal
	if not state_advance_button.pressed.is_connected(_on_state_advance_button_pressed):
		state_advance_button.pressed.connect(_on_state_advance_button_pressed)

func _on_state_advance_button_pressed() -> void:
	Global.dbg("Host pressed Main Menu button, resetting game")
	Global.reset_game_signal.emit()
