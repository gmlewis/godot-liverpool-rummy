extends Node

# Test Scene for Liverpool Rummy
# This scene can run tests in the proper Godot context with autoloads

const TestRunner = preload("res://tests/test_runner.gd")

func _ready():
	print("Starting Liverpool Rummy test suite...")

	# Create and run the test runner
	var test_runner = TestRunner.new()
	# Add the test runner to the scene tree so get_tree().quit() works
	add_child(test_runner)
	var result = test_runner.run_all_tests()
	if not result:
		get_tree().quit(1)
