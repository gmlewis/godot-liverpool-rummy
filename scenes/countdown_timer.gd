# countdown_timer.gd
extends CanvasLayer

@export var count_from: int = 3
@export var number_font_size: int = 200
@export var animation_duration: float = 0.5

func _ready() -> void:
	if len(Global.stock_pile) == 0: # This should not happen - no stock pile
		queue_free()
		return
	var top_card = Global.stock_pile[0]
	var target_position = top_card.position

	# Get the rotation controller to account for screen rotation
	var rotation_controller = get_tree().root.get_node("RootNode")

	if rotation_controller and rotation_controller.get_current_orientation() == 180:
		# Adjust position for 180 degree rotation
		target_position = Global.screen_center - (top_card.position - Global.screen_center)
		# Also rotate the sprite and label so they're readable
		$Sprite2D.rotation_degrees = 180
		$Label.rotation_degrees = 180
	else:
		$Sprite2D.rotation_degrees = 0
		$Label.rotation_degrees = 0

	$Sprite2D.position = target_position
	start_countdown(target_position)

func start_countdown(top_card_position: Vector2) -> void:
	for i in range(count_from, 0, -1):
		await animate_number(i, top_card_position)

	# Animation complete, remove this scene
	queue_free()

func animate_number(number: int, top_card_position: Vector2) -> void:
	var label = $Label
	label.text = str(number)
	label.position = top_card_position - label.get_size() / 2
	label.scale = Vector2.ZERO # Start at zero scale

	# Create a Tween for the animation
	var tween = create_tween()
	tween.set_parallel(false) # Sequential animation

	# Zoom in: scale from 0 to 1
	tween.tween_property(label, "scale", Vector2.ONE, animation_duration).set_ease(Tween.EASE_OUT)

	# Zoom out: scale from 1 to 0
	tween.tween_property(label, "scale", Vector2.ZERO, animation_duration).set_ease(Tween.EASE_IN)

	# Wait for animation to complete
	await tween.finished

# Optional: Override these values when instantiating
func set_countdown_params(from: int, duration: float = 0.5, font_size: int = 80) -> void:
	count_from = from
	animation_duration = duration
	number_font_size = font_size
