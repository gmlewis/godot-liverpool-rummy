# countdown_timer.gd
extends CanvasLayer

@export var count_from: int = 3
@export var number_font_size: int = 200
@export var animation_duration: float = 0.5

var rotation_controller = null
var last_orientation: int = 0
var is_cancelled: bool = false
var current_tween: Tween = null

func _ready() -> void:
	# Connect to the global cancel signal
	Global.connect('cancel_countdown_timer_signal', _on_cancel_countdown_timer_signal)

	if len(Global.stock_pile) == 0:
		queue_free()
		return

	# Get rotation controller reference
	rotation_controller = get_tree().root.get_node("RootNode")
	if rotation_controller:
		last_orientation = rotation_controller.get_current_orientation()
	else:
		Global.error("CountdownTimer: RotationController node not found!")

	var top_card = Global.stock_pile[0]
	var target_position = calculate_position(top_card.position)
	update_rotation()

	$Sprite2D.position = target_position
	start_countdown(top_card.position)

func _exit_tree() -> void:
	# Ensure signal is disconnected when node is removed from scene tree
	if Global.is_connected('cancel_countdown_timer_signal', _on_cancel_countdown_timer_signal):
		Global.disconnect('cancel_countdown_timer_signal', _on_cancel_countdown_timer_signal)

func _process(_delta: float) -> void:
	# Check if orientation changed during animation
	if rotation_controller:
		var current_orientation = rotation_controller.get_current_orientation()
		if current_orientation != last_orientation:
			last_orientation = current_orientation
			update_rotation()
			# Recalculate positions for sprite and label
			if len(Global.stock_pile) > 0:
				var top_card = Global.stock_pile[0]
				$Sprite2D.position = calculate_position(top_card.position)
				$Label.position = calculate_position(top_card.position) - $Label.get_size() / 2

func calculate_position(original_pos: Vector2) -> Vector2:
	if rotation_controller and rotation_controller.get_current_orientation() == 180:
		return Global.screen_center - (original_pos - Global.screen_center)
	return original_pos

func update_rotation() -> void:
	var rot = 180 if (rotation_controller and rotation_controller.get_current_orientation() == 180) else 0
	$Sprite2D.rotation_degrees = rot
	$Label.rotation_degrees = rot

func start_countdown(top_card_position: Vector2) -> void:
	for i in range(count_from, 0, -1):
		if is_cancelled:
			break
		await animate_number(i, top_card_position)

	# Disconnect from signal before freeing
	if Global.is_connected('cancel_countdown_timer_signal', _on_cancel_countdown_timer_signal):
		Global.disconnect('cancel_countdown_timer_signal', _on_cancel_countdown_timer_signal)
	queue_free()

func cancel_countdown() -> void:
	is_cancelled = true
	if current_tween:
		current_tween.kill()
	# Disconnect from signal before freeing
	if Global.is_connected('cancel_countdown_timer_signal', _on_cancel_countdown_timer_signal):
		Global.disconnect('cancel_countdown_timer_signal', _on_cancel_countdown_timer_signal)
	queue_free()

func _on_cancel_countdown_timer_signal() -> void:
	cancel_countdown()

func animate_number(number: int, top_card_position: Vector2) -> void:
	if is_cancelled:
		return

	var label = $Label
	label.text = str(number)
	label.position = calculate_position(top_card_position) - label.get_size() / 2
	label.scale = Vector2.ZERO

	current_tween = create_tween()
	current_tween.set_parallel(false)

	current_tween.tween_property(label, "scale", Vector2.ONE, animation_duration).set_ease(Tween.EASE_OUT)
	current_tween.tween_property(label, "scale", Vector2.ZERO, animation_duration).set_ease(Tween.EASE_IN)

	await current_tween.finished

func set_countdown_params(from: int, duration: float = 0.5, font_size: int = 80) -> void:
	count_from = from
	animation_duration = duration
	number_font_size = font_size
