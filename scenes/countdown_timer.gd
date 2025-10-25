# countdown_timer.gd
extends CanvasLayer

@export var number_font_size: int = 200
@export var animation_duration: float = 0.5

var is_cancelled: bool = false
var current_tween: Tween = null

func _ready() -> void:
	# Connect to the global cancel signal
	Global.connect('cancel_countdown_timer_signal', _on_cancel_countdown_timer_signal)

	if len(Global.stock_pile) == 0:
		queue_free()
		return

	var top_card = Global.stock_pile[0]
	var target_position = top_card.position

	$Sprite2D.position = target_position
	start_countdown(top_card.position)

func _exit_tree() -> void:
	# Ensure signal is disconnected when node is removed from scene tree
	if Global.is_connected('cancel_countdown_timer_signal', _on_cancel_countdown_timer_signal):
		Global.disconnect('cancel_countdown_timer_signal', _on_cancel_countdown_timer_signal)

func start_countdown(top_card_position: Vector2) -> void:
	var count_from = int(Global.OTHER_PLAYER_BUY_GRACE_PERIOD_SECONDS)
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
	label.position = top_card_position - label.get_size() / 2
	label.scale = Vector2.ZERO

	current_tween = create_tween()
	current_tween.set_parallel(false)

	current_tween.tween_property(label, "scale", Vector2.ONE, animation_duration).set_ease(Tween.EASE_OUT)
	current_tween.tween_property(label, "scale", Vector2.ZERO, animation_duration).set_ease(Tween.EASE_IN)

	await current_tween.finished
