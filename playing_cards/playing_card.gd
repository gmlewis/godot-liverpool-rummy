extends Node2D
class_name PlayingCard

# signal card_clicked_signal(playing_card, global_position)
# signal card_drag_started_signal(playing_card, from_position)
# signal card_moved_signal(playing_card, from_position, global_position)
# signal flip_complete_signal

@onready var sprite: Sprite2D = $Sprite2D
@onready var card_border: Sprite2D = $CardBoarder
@export var flip_duration: float = 0.6

var rank: String # "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "JOKER"
var suit: String # "hearts", "diamonds", "clubs", "spades" ("1" or "2" for jokers)
var points: int # value of card when calculating scores
var key: String # key (e.g. 'A-spades-0', 'Joker-1-0', 'Joker-2-0', etc.) used to access Global.playing_cards Dictionary

var is_draggable = false # Whether the card can be dragged by the player
var is_tappable = false # Whether the card can be tapped to buy or auto-move by the player

var back_texture: Texture2D
var face_texture: Texture2D
var is_face_up: bool = false
var is_flipping: bool = false
var tween: Tween = null

func _ready():
	# Global.dbg("PlayerCard _ready called")
	# Global.dbg("Card position: ", global_position)
	Global.connect('custom_card_back_texture_changed_signal', _on_custom_card_back_texture_changed_signal)
	back_texture = Global.custom_card_back.texture
	# Start with the back of the card and border shown
	if back_texture:
		sprite.texture = back_texture
	is_face_up = false
	card_border.show()
	if Global.DEBUG_SHOW_CARD_INFO:
		# Create a label on the card to show its properties
		var label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_constant_override('outline_size', 10)
		label.add_theme_font_size_override('font_size', 36)
		label.text = _to_string()
		sprite.add_child(label)

func _exit_tree() -> void:
	Global.disconnect('custom_card_back_texture_changed_signal', _on_custom_card_back_texture_changed_signal)

func _to_string() -> String:
	return "key: %s; %s; z: %0.0f; can draggable=%s, tappable=%s" % [key, position, z_index, is_draggable, is_tappable]

func _process(_delta: float) -> void:
	if Global.DEBUG_SHOW_CARD_INFO:
		var label = sprite.get_child(0) as Label
		label.text = _to_string() # Update label text with current properties
		label.position = - label.size / 2

# Constructor-like method to initialize the card with texture paths
func initialize(new_rank: String, new_suit: String, new_points: int, face_texture_path: String):
	self.rank = new_rank
	self.suit = new_suit
	self.points = new_points
	face_texture = load(face_texture_path)
	if not sprite:
		# If _ready hasn't been called yet, wait for it
		await ready
	# If the sprite is ready, set the initial texture and show card border
	sprite.texture = back_texture
	card_border.show()
	return self

func flip_card():
	if is_flipping: return
	is_flipping = true
	card_border.hide()
	# Create the flip animation using a Tween
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true) # Allow multiple animations to run simultaneously
	# First half: scale down horizontally (revealing the "edge" of the card)
	tween.tween_method(_update_flip_scale, 1.0, 0.0, flip_duration / 2.0)
	tween.tween_callback(_switch_texture).set_delay(flip_duration / 2.0)
	# Second half: scale back up horizontally (now showing the other side)
	tween.tween_method(_update_flip_scale, 0.0, 1.0, flip_duration / 2.0).set_delay(flip_duration / 2.0)
	# Add a subtle Y-axis bounce for more realistic 3D effect
	tween.tween_method(_update_flip_y_scale, 1.0, 1.1, flip_duration / 4.0)
	tween.tween_method(_update_flip_y_scale, 1.1, 1.0, flip_duration / 4.0).set_delay(flip_duration / 4.0)
	tween.tween_method(_update_flip_y_scale, 1.0, 1.1, flip_duration / 4.0).set_delay(flip_duration / 2.0)
	tween.tween_method(_update_flip_y_scale, 1.1, 1.0, flip_duration / 4.0).set_delay(flip_duration * 3.0 / 4.0)
	# Optional: Add a subtle rotation for more dynamic effect
	tween.tween_method(_update_flip_rotation, 0.0, deg_to_rad(5), flip_duration / 2.0)
	tween.tween_method(_update_flip_rotation, deg_to_rad(5), 0.0, flip_duration / 2.0).set_delay(flip_duration / 2.0)
	# Cleanup when animation is complete
	tween.tween_callback(_on_flip_complete).set_delay(flip_duration)
	await tween.finished

func _update_flip_scale(scale_x: float):
	sprite.scale.x = scale_x

func _update_flip_y_scale(scale_y: float):
	sprite.scale.y = scale_y

func _update_flip_rotation(rotation_rad: float):
	sprite.rotation = rotation_rad

func _switch_texture():
	# Switch the texture at the midpoint of the animation
	if is_face_up:
		sprite.texture = back_texture
		is_face_up = false
	else:
		sprite.texture = face_texture
		is_face_up = true

func _update_card_border():
	# # Ensure final state is clean
	sprite.scale = Vector2.ONE
	sprite.rotation = 0.0
	sprite.skew = 0.0
	sprite.position = Vector2.ZERO
	if not is_face_up: # only show border for card back
		card_border.show()
	else:
		card_border.hide()

func _on_flip_complete():
	if is_flipping:
		is_flipping = false
		# flip_complete_signal.emit()
	_update_card_border()

# Methods to force a specific state without animation
func force_face_up():
	if tween:
		# Global.dbg("Forcing face up, killing tween: key=%s" % key)
		tween.kill()
		tween = null
	is_flipping = false
	sprite.texture = face_texture
	is_face_up = true
	_update_card_border()

func force_face_down():
	if tween:
		# Global.dbg("Forcing face down, killing tween: key=%s" % key)
		tween.kill()
		tween = null
	is_flipping = false
	sprite.texture = back_texture
	is_face_up = false
	_update_card_border()

func _on_custom_card_back_texture_changed_signal():
	back_texture = Global.custom_card_back.texture
	if not is_face_up:
		sprite.texture = back_texture
	_update_card_border()

################################################################################
## Dragging functionality
################################################################################

const DRAG_START_THRESHOLD = 15 # Slightly higher for touch screens

var got_mouse_down: bool = false
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var initial_touch_pos: Vector2 = Vector2.ZERO # Store initial touch position

func _input(event):
	if not is_draggable and not is_tappable:
		return

	# Handle both mouse and touch input
	if event is InputEventMouseButton:
		var mouse_pos = get_global_mouse_position()

		# For release events, only handle if we're currently dragging or got_mouse_down
		# For press events, check if mouse is over this card AND we're the topmost card
		if event.pressed:
			# There are only 2 specific cards that can be tapped (top of stock pile or discard pile)
			# and one class of cards that can be tapped or dragged (the player's hand).
			if len(Global.stock_pile) > 0 and Global.stock_pile[0].key == key:
				# CASE 1: This card is the top of the stock pile
				if not is_mouse_over_card(mouse_pos):
					return
				if not Global.is_my_turn():
					# Global.dbg("PlayingCard: _input: Mouse PRESSED on stock pile card '%s' by non-current player at z_index=%d, position: %s - IGNORING" % [key, z_index, str(mouse_pos)])
					return
				# Global.dbg("PlayingCard: _input: Mouse PRESSED on stock pile card '%s' by current player at z_index=%d, position: %s" % [key, z_index, str(mouse_pos)])
			elif len(Global.discard_pile) > 0 and Global.discard_pile[0].key == key:
				# CASE 2: This card is the top of the discard pile
				if not is_mouse_over_card(mouse_pos):
					return
				# Global.dbg("PlayingCard: _input: Mouse PRESSED on discard pile card '%s' at z_index=%d, position: %s" % [key, z_index, str(mouse_pos)])
			elif key in Global.private_player_info['card_keys_in_hand']:
				# CASE 3: Player's hand
				if not is_mouse_over_card(mouse_pos):
					return
				if not is_topmost_card_under_mouse(mouse_pos):
					return
				# Global.dbg("PlayingCard: _input: Mouse PRESSED on player's card '%s' at z_index=%d, position: %s" % [key, z_index, str(mouse_pos)])
			else:
				# Not a valid card to interact with - do NOT handle this input event!
				return

			# if not is_mouse_over_card(mouse_pos):
			# 	return
			# # Check if we're the topmost card under the mouse within the player's hand
			# if key in Global.private_player_info['card_keys_in_hand'] and not is_topmost_card_under_mouse(mouse_pos):
			# 	return
			# # Check if the mouse is over the top card of the stock pile
			# if len(Global.stock_pile) > 0 and Global.stock_pile[0].is_mouse_over_card(mouse_pos):
			# 	if not Global.is_my_turn() or Global.stock_pile[0].key != key:
			# 		return
			# elif len(Global.discard_pile) > 0 and Global.discard_pile[0].is_mouse_over_card(mouse_pos):
			# 	if Global.discard_pile[0].key != key:
			# 		return
			# 	Global.dbg("PlayingCard: _intput: Mouse PRESSED on discard pile card '%s' at z_index=%d, position: %s" % [key, z_index, str(mouse_pos)])
		elif not (dragging or got_mouse_down):
			# Release event
			return

		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = false
			got_mouse_down = true
			initial_touch_pos = mouse_pos # Store the initial touch position
			drag_offset = mouse_pos - global_position
			# Global.dbg("PlayingCard: _input: Mouse PRESSED on card '%s' at z_index=%d, position: %s - SET_INPUT_AS_HANDLED" % [key, z_index, str(mouse_pos)])
			get_viewport().set_input_as_handled()

		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if dragging:
				# Handle drag end
				dragging = false
				got_mouse_down = false
				var from_position = global_position + drag_offset # Use release position
				_handle_card_moved(from_position)
				# Global.dbg("PlayingCard: _input: Mouse STOPPED DRAGGING on card '%s' at z_index=%d, position: %s - SET_INPUT_AS_HANDLED" % [key, z_index, str(mouse_pos)])
			elif got_mouse_down:
				# Handle tap/click
				got_mouse_down = false
				if is_tappable:
					_handle_card_click()
				# Global.dbg("PlayingCard: _input: Mouse RELEASED on card '%s' at z_index=%d, position: %s - SET_INPUT_AS_HANDLED" % [key, z_index, str(mouse_pos)])
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		if dragging:
			var mouse_pos = get_global_mouse_position()
			global_position = mouse_pos - drag_offset
			get_viewport().set_input_as_handled()
		elif got_mouse_down:
			# Check if we should start dragging
			var mouse_pos = get_global_mouse_position()
			if mouse_pos.distance_to(initial_touch_pos) > DRAG_START_THRESHOLD:
				if is_draggable:
					dragging = true
					_handle_card_drag_started(initial_touch_pos)
				else:
					# If not draggable, just reset the mouse down state
					got_mouse_down = false
			get_viewport().set_input_as_handled()

func is_mouse_over_card(mouse_pos: Vector2) -> bool:
	if not sprite or not sprite.texture:
		return false
	var card_rect = get_rect(5.0)
	var result = card_rect.has_point(mouse_pos)
	if result:
		Global.dbg("PlayingCard: is_mouse_over_card: Card '%s' at global_pos=%s, scale=%s, rect=%s contains mouse_pos=%s" % [key, str(global_position), str(scale), str(card_rect), str(mouse_pos)])
	return result

func get_rect(padding: float = 0.0) -> Rect2:
	if not sprite or not sprite.texture:
		return Rect2(Vector2.ZERO, Vector2.ZERO)

	var texture_size = sprite.texture.get_size() * self.scale
	var sprite_pos = global_position

	Global.dbg("PlayingCard.get_rect: card='%s', sprite.position=%s, global_position=%s, sprite.scale=%s, self.scale=%s" % [key, str(sprite.position), str(global_position), str(sprite.scale), str(self.scale)])

	# Add some padding for easier touch interaction on mobile
	return Rect2(
		sprite_pos - texture_size / 2 - Vector2(padding, padding),
		texture_size + Vector2(padding * 2, padding * 2)
	)

func is_topmost_card_under_mouse(mouse_pos: Vector2) -> bool:
	# Find the card with the highest z_index whose bounding box contains the mouse position.
	# This works correctly because in Godot, higher z_index means visually on top.
	# We don't need to worry about "visible portions" - we just need the highest z_index.
	var highest_z_index = -1
	var topmost_card = null

	# Check all cards in player's hand
	for card_key in Global.private_player_info['card_keys_in_hand']:
		var card = Global.playing_cards.get(card_key) as PlayingCard
		if not card:
			continue

		# If this card's bounding box contains the mouse AND it has the highest z_index so far
		if card.is_mouse_over_card(mouse_pos) and card.z_index > highest_z_index:
			highest_z_index = card.z_index
			topmost_card = card

	# We are topmost if we have the highest z_index among all cards under the mouse
	return topmost_card == self

################################################################################
## Handle mouse interactions
################################################################################

func _handle_card_click():
	# Global.dbg("playing_card.gd: _handle_card_click: Card clicked at position: %s" % [str(global_position)])
	Global.emit_card_clicked_signal(self, global_position)

func _handle_card_drag_started(from_position: Vector2):
	# Global.dbg("playing_card.gd: _handle_card_drag_started: Card drag started from position: %s" % [str(from_position)])
	z_index = Global.sanitize_players_hand_z_index_values() # raise card above all others in hand
	Global.emit_card_drag_started_signal(self, from_position)

func _handle_card_moved(from_position: Vector2):
	# Global.dbg("playing_card.gd: _handle_card_moved: Card moved from position: %s to: %s" % [str(from_position), str(global_position)])
	Global.emit_card_moved_signal(self, from_position, global_position)
