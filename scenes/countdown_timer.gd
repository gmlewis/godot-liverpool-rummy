# countdown_timer.gd
extends CanvasLayer

@export var count_from: int = 3
@export var number_font_size: int = 200
@export var animation_duration: float = 0.5

var center_position: Vector2

func _ready() -> void:
	center_position = get_viewport().get_visible_rect().size / 2
	$Sprite2D.position = center_position
	# $Sprite2D.scale = Vector2(0.2, 0.2)
	start_countdown()

func start_countdown() -> void:
	for i in range(count_from, 0, -1):
		await animate_number(i)
		# await get_tree().create_timer(0.1).timeout # Small gap between numbers

	# Animation complete, remove this scene
	queue_free()

func animate_number(number: int) -> void:
	var label = $Label
	label.text = str(number)
	# label.add_theme_font_size_override("font_size", number_font_size)
	# label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = center_position - label.get_size() / 2
	# add_child(label)

	label.scale = Vector2.ZERO # Start at zero scale

	# Create a Tween for the animation
	var tween = create_tween()
	tween.set_parallel(false) # Sequential animation

	# Zoom in: scale from 0 to 1
	tween.tween_property(label, "scale", Vector2.ONE, animation_duration).set_ease(Tween.EASE_OUT)

	# Hold at full size briefly (optional, can comment out)
	# tween.tween_callback(func(): await get_tree().create_timer(0.1).timeout)

	# Zoom out: scale from 1 to 0
	tween.tween_property(label, "scale", Vector2.ZERO, animation_duration).set_ease(Tween.EASE_IN)

	# Wait for animation to complete
	await tween.finished

# Optional: Override these values when instantiating
func set_countdown_params(from: int, duration: float = 0.5, font_size: int = 80) -> void:
	count_from = from
	animation_duration = duration
	number_font_size = font_size
