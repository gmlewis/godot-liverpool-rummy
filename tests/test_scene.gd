extends Node

# Test Scene for Liverpool Rummy
# This scene can run tests in the proper Godot context with autoloads

func _ready():
	print("Starting Liverpool Rummy test suite...")

	# Check for command line arguments to determine which tests to run
	var args = OS.get_cmdline_user_args()
	var test_type = "all" # Default to all tests

	for arg in args:
		if arg.begins_with("test_type="):
			test_type = arg.split("=")[1]
			break

	# Create and run the test runner
	var test_runner = TestRunner.new()
	# Add the test runner to the scene tree so get_tree().quit() works
	add_child(test_runner)

	var result: bool
	match test_type:
		"hand":
			result = test_runner.run_hand_evaluation_tests()
		"card":
			result = test_runner.run_card_logic_tests()
		"state":
			result = test_runner.run_game_state_tests()
		"sync":
			result = test_runner.run_multiplayer_sync_tests()
		"bots":
			result = test_runner.run_bots_tests()
		_:
			result = test_runner.run_all_tests()

	# Note: Resource leaks in headless testing are expected and don't affect test validity
	# The warnings about CanvasItem RIDs and ObjectDB instances are Godot engine artifacts
	# that occur when running tests in headless mode but don't impact the actual test results

	if not result:
		get_tree().quit(1)
	else:
		get_tree().quit(0)
