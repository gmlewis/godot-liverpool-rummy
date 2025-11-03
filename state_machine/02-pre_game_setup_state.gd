extends GameState

@export var players_container: Node2D
@export var round1_scene: PackedScene

@onready var state_advance_button: TextureButton = $'../../HUDLayer/Control/StateAdvanceButton'
@onready var options_button: TextureButton = $'../../HUDLayer/Control/OptionsButton'

func enter(_params: Dictionary):
	Global.dbg("ENTER PreGameSetupState")
	$'../../TitlePageUI'.connect('start_button_pressed_signal', _on_start_button_pressed_signal)

	# Setup the "Start Tutorial" and "Options" buttons but keep them hidden initially
	_setup_tutorial_and_options_buttons()
	state_advance_button.hide()
	options_button.hide()

	# Connect to detect when the player has chosen their name
	var start_game_panel = $"../../TitlePageUI/PanelPositionControl/StartGamePanel"
	if start_game_panel:
		start_game_panel.visibility_changed.connect(_on_start_game_panel_visibility_changed)

func exit():
	$"../../TitlePageUI".disconnect('start_button_pressed_signal', _on_start_button_pressed_signal)
	Global.dbg("LEAVE PreGameSetupState")
	# Disconnect from start game panel visibility
	var start_game_panel = $"../../TitlePageUI/PanelPositionControl/StartGamePanel"
	if start_game_panel and start_game_panel.visibility_changed.is_connected(_on_start_game_panel_visibility_changed):
		start_game_panel.visibility_changed.disconnect(_on_start_game_panel_visibility_changed)
	# Hide the button and disconnect signal when leaving state
	if state_advance_button.visible:
		state_advance_button.hide()
		if state_advance_button.pressed.is_connected(_on_tutorial_button_pressed):
			state_advance_button.pressed.disconnect(_on_tutorial_button_pressed)
	if options_button.visible:
		options_button.hide()
		if options_button.pressed.is_connected(_on_options_button_pressed):
			options_button.pressed.disconnect(_on_options_button_pressed)

var dragging_child: Node2D = null
var dragging_save_button_text: String
var dragging_save_button_disabled: bool
var drag_offset: Vector2
var original_positions: Array[Vector2]
var original_rotations: Array[float]
var leave_target: Node2D = null
var currently_tweening = false
var restore_last_index = 0
var restore_last_child: Node2D = null

func handle_input(event: InputEvent):
	if Global.is_not_server(): return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Find which child was clicked
			var clicked_child = get_child_at_position(event.global_position)
			if clicked_child and clicked_child.player_id != '1': # cannot move host
				Global.dbg("pre_game_setup_state:handle_input: clicked_child=%s" % [clicked_child.player_id])
				start_drag(clicked_child, event.global_position)
		else:
			end_drag()
	elif dragging_child and event is InputEventMouseMotion:
		update_drag(event.global_position)

func get_child_at_position(global_pos: Vector2) -> Node2D:
	for child in players_container.get_children():
		if dragging_child == child: continue
		if is_position_in_child(child, global_pos):
			return child
	return null

func is_position_in_child(child: Node2D, global_pos: Vector2) -> bool:
	var local_pos = child.to_local(global_pos)
	var sprite = child.get_child(0) as Sprite2D # A Player's first child is CardBackSprite2D
	if not sprite or not sprite.texture:
		push_error('is_position_in_child: expected sprite to be Sprite2D with texture')
		return false
	var size = sprite.texture.get_size()
	var rect = Rect2(-size / 2, size) # Assuming centered sprite
	return rect.has_point(local_pos)

func start_drag(child: Node2D, global_pos: Vector2):
	var button = $"../../TitlePageUI/PanelPositionControl/StartGamePanel/JoinGameButton"
	dragging_save_button_text = button.text
	dragging_save_button_disabled = button.disabled
	button.text = 'Remove'
	button.disabled = false
	dragging_child = child
	drag_offset = global_pos - child.global_position
	Global.dbg("pre_game_setup_state:start_drag: drag_offset=%s" % [str(drag_offset)])
	update_positions()

func create_leave_target(child: Node2D):
	var sprite = child.get_child(0) as Sprite2D # A Player's first child is CardBackSprite2D
	if not sprite is Sprite2D:
		push_error('create_leave_target: expected sprite to be Sprite2D')
		return
	leave_target = Sprite2D.new()
	leave_target.position = child.position
	leave_target.rotation = child.rotation
	leave_target.scale = child.scale
	leave_target.texture = sprite.texture
	leave_target.modulate = Color(1, 1, 1, 0.5)
	players_container.add_child(leave_target)

func update_drag(global_pos: Vector2):
	#Global.dbg("pre_game_setup_state:update_drag")
	if not dragging_child: return
	var new_pos = global_pos - drag_offset
	dragging_child.position = new_pos
	var t = clamp(inverse_lerp(original_positions[0].x, original_positions[len(original_positions) - 1].x, new_pos.x), 0.0, 1.0)
	dragging_child.rotation = lerp(original_rotations[0], original_rotations[len(original_rotations) - 1], t)
	if currently_tweening: return # Don't test for overlap during animation
	if leave_target: # Check to see if drag is outside of leave_target
		var local_pos = leave_target.to_local(global_pos)
		var size = leave_target.texture.get_size()
		var rect = Rect2(-size / 2, size) # Assuming centered sprite
		if not rect.has_point(local_pos):
			destroy_leave_target()
			restore_original_positions()
		return
	var over_child = get_child_at_position(new_pos)
	if not over_child or over_child.player_id == '1': return # cannot move host
	create_leave_target(over_child)
	reorder_child(dragging_child, over_child.turn_index)

func destroy_leave_target():
	players_container.remove_child(leave_target)
	leave_target.queue_free()
	leave_target = null

func restore_original_positions():
	Global.dbg('pre_game_setup_state:restore_original_positions of all moved children')
	if restore_last_child:
		players_container.move_child(restore_last_child, restore_last_index)
		restore_last_child = null
	# Animate to original positions
	currently_tweening = true
	var tween = players_container.create_tween()
	tween.set_parallel(true)
	tween.finished.connect(func(): currently_tweening = false)
	for i in players_container.get_child_count():
		var child = players_container.get_child(i)
		if child == dragging_child or i >= original_positions.size(): continue
		var target_pos = original_positions[i]
		var target_rot = original_rotations[i]
		tween.tween_property(child, "position", target_pos, 0.2)
		tween.tween_property(child, "rotation", target_rot, 0.2)
	await tween.finished

func reorder_child(child: Node2D, new_index: int):
	Global.dbg("pre_game_setup_state:reorder_child")
	if child.get_index() == new_index: return
	restore_last_index = child.get_index()
	restore_last_child = child
	players_container.move_child(child, new_index)
	update_visual_positions()

func update_visual_positions():
	Global.dbg("pre_game_setup_state:update_visual_positions")
	# Animate to new positions
	currently_tweening = true
	var tween = players_container.create_tween()
	tween.set_parallel(true)
	tween.finished.connect(func(): currently_tweening = false)
	for i in players_container.get_child_count():
		var child = players_container.get_child(i)
		if child == dragging_child or i >= original_positions.size(): continue
		var target_pos = original_positions[i]
		var target_rot = original_rotations[i]
		tween.tween_property(child, "position", target_pos, 0.2)
		tween.tween_property(child, "rotation", target_rot, 0.2)
	await tween.finished

func end_drag():
	if not dragging_child: return
	Global.dbg("pre_game_setup_state:end_drag")
	var button = $"../../TitlePageUI/PanelPositionControl/StartGamePanel/JoinGameButton"
	button.text = dragging_save_button_text
	button.disabled = dragging_save_button_disabled
	var remove_rect = button.get_global_rect()
	var ending_position = dragging_child.global_position
	if leave_target: # Snap to final position and reorder
		dragging_child = null
		destroy_leave_target()
		emit_reorder_signal()
	elif remove_rect.has_point(ending_position):
		remove_player(dragging_child)
		dragging_child = null
		emit_reorder_signal()
	else:
		dragging_child = null
		restore_original_positions()

func remove_player(child: Node2D) -> void:
	var player_id = child.player_id
	Global.dbg("pre_game_setup_state: remove_player(id=%s)" % [player_id])
	Global.reset_remote_player_game(player_id)
	players_container.remove_child(child)
	child.queue_free()

func update_positions():
	Global.dbg("pre_game_setup_state:update_positions")
	original_positions.clear()
	original_rotations.clear()
	for child in players_container.get_children():
		original_positions.append(child.position)
		original_rotations.append(child.rotation)

func emit_reorder_signal():
	var order_array = []
	for child in players_container.get_children():
		order_array.append(child.player_id)
	Global.dbg("pre_game_setup_state:emit_reorder_signal: new order: %s" % [str(order_array)])
	Global.reorder_players(order_array)

func _on_start_game_panel_visibility_changed() -> void:
	# When StartGamePanel becomes visible, the player has chosen their name
	var start_game_panel = $"../../TitlePageUI/PanelPositionControl/StartGamePanel"
	if start_game_panel and start_game_panel.visible:
		state_advance_button.show()
		options_button.show()

func _on_start_button_pressed_signal(): # only run on host/server
	# Normal game play:
	Global.request_change_round(round1_scene)
	_rpc_transition_all_clients_state_to.rpc('StartRoundShuffleState')
	#
	# DEVELOPMENT1: Jump to specific round (change number for different rounds)
	# var dev_round_num = 7
	# var dev_round_scene = load("res://rounds/round_%d.tscn" % dev_round_num) as PackedScene
	# Global.game_state['current_round_num'] = dev_round_num
	# Global.request_change_round(dev_round_scene)
	# _rpc_transition_all_clients_state_to.rpc('StartRoundShuffleState')
	#
	# DEVELOPMENT2: Simulate final scores scene - dole out random scores
	# for player_info in Global.game_state['public_players_info']:
	# 	player_info['score'] = randi() % 10
	# Global.game_state['current_round_num'] = 7
	# var next_round_scene = load("res://rounds/final_scores.tscn") as PackedScene
	# Global.request_change_round(next_round_scene)
	# Global.send_transition_all_clients_state_to_signal('FinalScoresState')
	#
	# DEVELOPMENT3: Give all the bots a bunch of books in round 1 so they can all be melded upon
	# Make this happen in 04-deal_new_round_state.gd.

func _setup_tutorial_and_options_buttons() -> void:
	# Load the appropriate SVG based on language
	const tutorial_texture_path = "res://svgs/start-tutorial-%s.svg" % Global.LANGUAGE
	const options_texture_path = "res://svgs/options-%s.svg" % Global.LANGUAGE

	_initialize_button(tutorial_texture_path, state_advance_button, 0.65)
	_initialize_button(options_texture_path, options_button, 0.80)

	# Connect the button press signal
	if not state_advance_button.pressed.is_connected(_on_tutorial_button_pressed):
		state_advance_button.pressed.connect(_on_tutorial_button_pressed)
	# Connect the button press signal
	if not options_button.pressed.is_connected(_on_options_button_pressed):
		options_button.pressed.connect(_on_options_button_pressed)


func _initialize_button(texture_path: String, button: TextureButton, vertical_percentage: float) -> void:
	var texture = load(texture_path)
	button.texture_normal = texture
	button.texture_pressed = texture
	button.texture_hover = texture

	# Enable texture scaling
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

	# Resize button to 25% of screen width while maintaining aspect ratio
	var target_width = Global.screen_size.x * 0.25
	var texture_size = texture.get_size()
	var aspect_ratio = texture_size.y / texture_size.x
	var target_height = target_width * aspect_ratio

	button.custom_minimum_size = Vector2(target_width, target_height)
	button.size = Vector2(target_width, target_height)

	# Calculate position offset from center anchor (0.5, 0.5)
	var target_y_center = Global.screen_size.y * vertical_percentage
	var screen_center_y = Global.screen_size.y * 0.5
	var y_offset_from_center = target_y_center - screen_center_y

	button.offset_left = - target_width / 2.0
	button.offset_top = y_offset_from_center - target_height / 2.0
	button.offset_right = target_width / 2.0
	button.offset_bottom = y_offset_from_center + target_height / 2.0

	# Set z_index to be visible
	button.z_index = 1000

func _on_tutorial_button_pressed() -> void:
	Global.dbg("Start Tutorial button pressed, loading tutorial")

	# Hide the title page UI (similar to starting a game)
	var title_page_ui = $"../../TitlePageUI"
	if title_page_ui:
		title_page_ui.game_has_started = true
		Global.game_has_started = true
		title_page_ui.get_node("PanelPositionControl/StartGamePanel").hide()
		# Call the RPC to hide title page and show playing cards
		title_page_ui._rpc_hide_title_page_ui.rpc()

	var tutorial_scene = load("res://rounds/tutorial.tscn") as PackedScene
	Global.request_change_round(tutorial_scene)

	Global.send_transition_all_clients_state_to_signal("TutorialState")

func _on_options_button_pressed() -> void:
	Global.dbg("Options button pressed, loading options")

	# Hide the title page UI (similar to starting a game)
	var title_page_ui = $"../../TitlePageUI"
	if title_page_ui:
		title_page_ui.game_has_started = true
		Global.game_has_started = true
		title_page_ui.get_node("PanelPositionControl/StartGamePanel").hide()
		# Call the RPC to hide title page and show playing cards
		title_page_ui._rpc_hide_title_page_ui.rpc()

	var options_scene = load("res://rounds/options.tscn") as PackedScene
	Global.request_change_round(options_scene)

	Global.send_transition_all_clients_state_to_signal("OptionsState")
