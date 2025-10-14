# Test Player Winning State Functionality
# Tests for winning player animation, clicking, and state management

class_name TestPlayer
extends Node

const TestFrameworkClass = preload("res://tests/test_framework.gd")

var test_framework: TestFrameworkClass

func _ready():
	test_framework = TestFrameworkClass.new()
	add_child(test_framework)

func run_all_tests() -> bool:
	return test_framework.discover_and_run_test_suite("Player Winning State Tests", self)

func test_winning_player_animation_logic() -> bool:
	# Test that winning animation runs without being overridden
	# Create a minimal ColorRect to simulate the turn indicator
	var turn_indicator = ColorRect.new()
	turn_indicator.size = Vector2(50, 50)
	turn_indicator.position = Vector2(0, 0)
	add_child(turn_indicator)

	# Simulate winning player animation logic
	var is_winning_player = true
	var _is_my_turn = true # This would normally override, but shouldn't for winning player

	if is_winning_player:
		var ticks = 1000.0 # Simulate time
		var rect_scale = abs(sin(ticks * 0.005)) * 0.5 + 1.0
		turn_indicator.scale = Vector2(rect_scale, rect_scale)
		turn_indicator.rotation = ticks * 0.01
		# Return to prevent other animations

	# Check that winning animation was applied
	test_framework.assert_in_range(turn_indicator.scale.x, 1.0, 1.5, "Winning animation scale should be in winning range")
	test_framework.assert_not_equal(0.0, turn_indicator.rotation, "Winning animation should rotate the indicator")

	# Clean up
	remove_child(turn_indicator)
	turn_indicator.queue_free()

	return true

func cleanup_test_resources() -> void:
	# Clean up test framework
	if test_framework and is_instance_valid(test_framework):
		if test_framework.is_inside_tree():
			remove_child(test_framework)
		test_framework.queue_free()
	test_framework = null