# Test Runner for Liverpool Rummy
# Main test runner that executes all test suites

class_name TestRunner
extends Node

# Preload dependencies
const TestFramework = preload("res://tests/test_framework.gd")
const TestHandEvaluation = preload("res://tests/test_hand_evaluation.gd")
const TestCardLogic = preload("res://tests/test_card_logic.gd")
const TestGameState = preload("res://tests/test_game_state.gd")
const TestMultiplayerSync = preload("res://tests/test_multiplayer_sync.gd")
const TestPlayer = preload("res://tests/test_player.gd")

var test_framework: TestFramework
var total_tests: int = 0
var total_passed: int = 0
var total_failed: int = 0

func _ready():
	test_framework = TestFramework.new()
	# Add test framework to scene tree so get_tree().quit() works
	add_child(test_framework)

	# Validate that all GDScript files can be compiled without syntax errors
func validate_script_compilation() -> bool:
	print("Validating script compilation...")
	
	# List of critical scripts to validate
	var scripts_to_check = [
		"res://global.gd",
		"res://players/player.gd",
		"res://playing_cards/playing_card.gd",
		"res://scripts/meld_area_manager.gd",
		"res://scenes/root_node.gd",
		"res://state_machine/game_state_machine.gd"
	]
	
	var all_valid = true
	
	for script_path in scripts_to_check:
		var script = load(script_path)
		if script == null:
			print("❌ FAILED: Could not load script: %s" % script_path)
			all_valid = false
			continue
			
		# Try to instantiate the script to check for compilation errors
		var instance = script.new()
		if instance == null:
			print("❌ FAILED: Could not instantiate script: %s (likely compilation error)" % script_path)
			all_valid = false
		else:
			# Clean up the instance
			if instance.has_method("_ready"):
				instance._ready()
			instance.queue_free()
			print("✓ PASSED: %s compiled successfully" % script_path)
	
	if not all_valid:
		print("\n❌ SCRIPT COMPILATION VALIDATION FAILED")
		print("One or more scripts have syntax errors that prevent compilation.")
		print("Fix these errors before running tests.")
		return false
	
	print("✓ All scripts compiled successfully\n")
	return true

func run_all_tests() -> bool:
	# First validate that all scripts compile correctly
	if not validate_script_compilation():
		print("❌ CRITICAL: Script compilation validation failed!")
		print("Fix syntax errors before running tests.")
		get_tree().quit(1)
		return false
	
	print("\n" + "=".repeat(60))
	print("   LIVERPOOL RUMMY - UNIT TEST SUITE")
	print("=".repeat(60))
	print("Running comprehensive tests for game logic...\n")

	var start_time = Time.get_unix_time_from_system()

	# Run all test suites
	var hand_result = run_hand_evaluation_tests()
	if not hand_result:
		return false
	var card_result = run_card_logic_tests()
	if not card_result:
		return false
	var game_result = run_game_state_tests()
	if not game_result:
		return false
	var sync_result = run_multiplayer_sync_tests()
	if not sync_result:
		return false
	var player_result = run_player_tests()
	if not player_result:
		return false
	var meld_result = run_meld_area_manager_tests()
	if not meld_result:
		return false

	var end_time = Time.get_unix_time_from_system()
	var duration = end_time - start_time

	# Print final summary
	print("\n" + "=".repeat(60))
	print("   FINAL TEST RESULTS")
	print("=".repeat(60))
	print("Total test suites run: 6")
	print("Total tests executed: %d" % total_tests)
	print("Total tests passed: %d" % total_passed)
	print("Total tests failed: %d" % total_failed)
	print("Execution time: %.2f seconds" % duration)

	# Check if Global is available - if not, this is a critical failure
	if Global == null:
		print("\n❌ CRITICAL FAILURE: Global autoload is not available")
		print("This indicates a syntax error in global.gd that prevents the game from running.")
		print("The test framework correctly detected this failure.")
		print("\nSUCCESS: Test framework is working correctly by detecting failures!")
		print("=".repeat(60))
		get_tree().quit(1)
		return false

	if total_failed == 0:
		print("\n🎉 ALL TESTS PASSED! 🎉")
		print("Your game logic is working correctly.")
	else:
		print("\n❌ SOME TESTS FAILED")
		print("Please review the failed tests above and fix the issues.")
		print("Failed tests may indicate bugs in your game logic.")
		get_tree().quit(1)
		return false

	print("\nSuccess rate: %.1f%%" % ((total_passed as float / total_tests as float) * 100.0))
	print("=".repeat(60))
	get_tree().quit(0)
	return true

func run_hand_evaluation_tests() -> bool:
	var test_suite = TestHandEvaluation.new()
	add_child(test_suite)
	var result = test_suite.run_all_tests()
	update_totals(test_suite.test_framework)
	# Ensure proper cleanup of all child nodes
	test_suite.cleanup_test_resources()
	remove_child(test_suite)
	test_suite.queue_free()
	return result

func run_card_logic_tests() -> bool:
	var test_suite = TestCardLogic.new()
	add_child(test_suite)
	var result = test_suite.run_all_tests()
	update_totals(test_suite.test_framework)
	# Ensure proper cleanup of all child nodes
	test_suite.cleanup_test_resources()
	remove_child(test_suite)
	test_suite.queue_free()
	return result

func run_game_state_tests() -> bool:
	var test_suite = TestGameState.new()
	add_child(test_suite)
	var result = test_suite.run_all_tests()
	update_totals(test_suite.test_framework)
	# Ensure proper cleanup of all child nodes
	test_suite.cleanup_test_resources()
	remove_child(test_suite)
	test_suite.queue_free()
	return result

func run_multiplayer_sync_tests() -> bool:
	var test_suite = TestMultiplayerSync.new()
	add_child(test_suite)
	var result = test_suite.run_all_tests()
	update_totals(test_suite.test_framework)
	# Ensure proper cleanup of all child nodes
	test_suite.cleanup_test_resources()
	remove_child(test_suite)
	test_suite.queue_free()
	return result

func run_player_tests() -> bool:
	var test_suite = TestPlayer.new()
	add_child(test_suite)
	var result = test_suite.run_all_tests()
	update_totals(test_suite.test_framework)
	# Ensure proper cleanup of all child nodes
	test_suite.cleanup_test_resources()
	remove_child(test_suite)
	test_suite.queue_free()
	return result

func run_meld_area_manager_tests() -> bool:
	var tests = [
		test_meld_area_manager
	]
	return test_framework.run_test_suite("Meld Area Manager Tests", tests)

func update_totals(framework: TestFramework) -> void:
	total_tests += framework.tests_run
	total_passed += framework.tests_passed
	total_failed += framework.tests_failed

func cleanup_test_resources() -> void:
	# Clean up test framework
	if test_framework and is_instance_valid(test_framework):
		if test_framework.is_inside_tree():
			remove_child(test_framework)
		test_framework.queue_free()
	test_framework = null

func run_quick_smoke_tests() -> bool:
	"""Run a subset of critical tests for quick validation"""
	print("\n" + "=".repeat(40))
	print("   QUICK SMOKE TESTS")
	print("=".repeat(40))

	# Just run basic functionality tests
	# Note: Global is an autoload, access it directly
	test_framework.reset()

	var quick_tests = [
		test_basic_card_scoring,
		test_basic_hand_stats,
		test_basic_game_state,
		test_basic_round_requirements,
		test_meld_area_manager
	]

	return test_framework.run_test_suite("Smoke Tests", quick_tests)

func test_basic_card_scoring() -> bool:
	# Global is an autoload, access it directly
	test_framework.assert_equal(15, Global.card_key_score("A-hearts-0"), "Ace should score 15")
	test_framework.assert_equal(10, Global.card_key_score("K-spades-0"), "King should score 10")
	return true

func test_basic_hand_stats() -> bool:
	# Create a test bot to access hand stats
	var test_bot = load("res://players/00-bot.gd").new("test_bot")
	var cards = ["A-hearts-0", "A-spades-0", "K-hearts-0"]
	var stats = test_bot.gen_bot_hand_stats(cards)
	test_framework.assert_equal(3, stats['num_cards'], "Should have 3 cards")
	test_framework.assert_equal(2, len(stats['by_rank']['A']), "Should have 2 Aces")
	return true

func test_basic_game_state() -> bool:
	# Global is an autoload, access it directly
	Global.reset_game()
	test_framework.assert_equal(1, Global.game_state['current_round_num'], "Should start at round 1")
	return true

func test_basic_round_requirements() -> bool:
	# Test round 1 requirements: areas 1 and 2 need groups, area 3 is always satisfied
	test_framework.assert_true(Global.is_valid_group(["A-hearts-0", "A-spades-0", "A-diamonds-0"]), "Three of a kind should be valid group")
	test_framework.assert_false(Global.is_valid_group(["A-hearts-0", "K-spades-0"]), "Two different ranks should not be valid group")
	return true

func test_meld_area_manager() -> bool:
	# Test meld area manager instantiation and basic functionality
	var meld_area_manager = load("res://scripts/meld_area_manager.gd").new()
	test_framework.assert_not_null(meld_area_manager, "MeldAreaManager should instantiate")
	
	# Create a mock parent with ColorRect children
	var mock_parent = Control.new()
	var area1 = ColorRect.new()
	area1.name = "Book1Area"
	var area2 = ColorRect.new()
	area2.name = "Book2Area"
	
	var control1 = Control.new()
	control1.add_child(area1)
	meld_area_manager.add_child(control1)
	
	var control2 = Control.new()
	control2.add_child(area2)
	meld_area_manager.add_child(control2)
	
	meld_area_manager.set_name("MeldArea")
	mock_parent.add_child(meld_area_manager)
	
	# Add to scene tree
	add_child(mock_parent)
	
	# Manually initialize the meld area manager
	meld_area_manager.sparkle_material = ShaderMaterial.new()
	meld_area_manager.sparkle_material.shader = preload("res://shaders/sparkle.gdshader")
	meld_area_manager.sparkle_material.set_shader_parameter("border_width", 10.0)
	meld_area_manager.sparkle_material.set_shader_parameter("border_color", Color(1.0, 1.0, 0.8, 1.0))
	meld_area_manager.sparkle_material.set_shader_parameter("sparkle_intensity", 2.0)
	meld_area_manager.sparkle_material.set_shader_parameter("time_speed", 5.0)
	
	# Find areas manually
	var areas = []
	for child in meld_area_manager.get_children():
		if child is Control:
			for grandchild in child.get_children():
				if grandchild is ColorRect:
					areas.append(grandchild)
	
	for area in areas:
		meld_area_manager.default_materials[area] = area.material
	
	test_framework.assert_true(meld_area_manager.default_materials.size() > 0, "Should find default materials")
	test_framework.assert_not_null(meld_area_manager.sparkle_material, "Sparkle material should be created")
	
	# Simulate having cards in meld area 1 (a valid group for round 1)
	if not Global.private_player_info:
		Global.private_player_info = {}
	Global.private_player_info.merge({
		'meld_area_1_keys': ['A-hearts-0', 'A-spades-0', 'A-diamonds-0'],
		'meld_area_2_keys': [],
		'meld_area_3_keys': []
	}, true)
	
	# Ensure round is set to 1
	if not Global.game_state:
		Global.game_state = {}
	Global.game_state['current_round_num'] = 1
	
	# Update satisfaction
	meld_area_manager.update_meld_satisfaction()
	
	# Check that sparkle material was applied to area 1
	test_framework.assert_equal(meld_area_manager.sparkle_material, area1.material, "Area 1 should have sparkle material")
	test_framework.assert_equal(meld_area_manager.default_materials[area2], area2.material, "Area 2 should have default material")
	
	# Cleanup
	remove_child(mock_parent)
	mock_parent.queue_free()
	Global.private_player_info = null
	
	return true
