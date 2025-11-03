extends GameState
# This state is entered when one player fully satisfies this round's requirements.

@onready var state_advance_button: TextureButton = $'../../HUDLayer/Control/StateAdvanceButton'

func enter(_params: Dictionary):
	Global.dbg("ENTER PlayerWonRoundState")
	# Clear all sparkle shaders (set to fuzzy) for all 3 meld areas
	Global.emit_meld_area_state_changed_signal(false, 0)
	Global.emit_meld_area_state_changed_signal(false, 1)
	Global.emit_meld_area_state_changed_signal(false, 2)
	Global.send_animate_winning_confetti_explosion_signal(5000) # Trigger confetti explosion for 5 seconds

	# Show the "Tally Scores" button only on the host/server
	if Global.is_server():
		_setup_tally_scores_button()
		state_advance_button.show()
	else:
		state_advance_button.hide()

func exit():
	Global.dbg("LEAVE PlayerWonRoundState")
	# Hide the button and disconnect signal when leaving state
	if state_advance_button.visible:
		state_advance_button.hide()
		if state_advance_button.pressed.is_connected(_on_tally_scores_button_pressed):
			state_advance_button.pressed.disconnect(_on_tally_scores_button_pressed)

func _setup_tally_scores_button() -> void:
	# Load the appropriate SVG based on language
	const texture_path = "res://svgs/tally-scores-%s.svg" % Global.LANGUAGE

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

	# Center the button by setting offsets based on the new size
	state_advance_button.offset_left = - target_width / 2.0
	state_advance_button.offset_top = - target_height / 2.0
	state_advance_button.offset_right = target_width / 2.0
	state_advance_button.offset_bottom = target_height / 2.0

	# Connect the button press signal
	if not state_advance_button.pressed.is_connected(_on_tally_scores_button_pressed):
		state_advance_button.pressed.connect(_on_tally_scores_button_pressed)

func _on_tally_scores_button_pressed() -> void:
	Global.dbg("Host pressed Tally Scores button, transitioning to TallyScoresState")
	# Transition to the next state
	Global.send_transition_all_clients_state_to_signal("TallyScoresState")
