# Test Runner for Liverpool Rummy
# Main test runner that executes all test suites

class_name TestRunner
extends Node

const TestBots = preload("res://tests/test_bots.gd")
const TestCardLogic = preload("res://tests/test_card_logic.gd")
const TestGameState = preload("res://tests/test_game_state.gd")
const TestHandEvaluation = preload("res://tests/test_hand_evaluation.gd")
const TestMultiplayerSync = preload("res://tests/test_multiplayer_sync.gd")
const TestPlayer = preload("res://tests/test_player.gd")
const TestCodeStyle = preload("res://tests/test_code_style.gd")
const TestPostMeldLogic = preload("res://tests/test_post_meld_logic.gd")
const TestPostMeldFlow = preload("res://tests/test_post_meld_flow.gd")

var test_framework: TestFramework
var total_tests: int = 0
var total_passed: int = 0
var total_failed: int = 0

func _ready():
	test_framework = TestFramework.new()
	# Add test framework to scene tree so get_tree().quit() works
	add_child(test_framework)

func run_all_tests() -> bool:
	print("\n" + "=".repeat(60))
	print("   LIVERPOOL RUMMY - UNIT TEST SUITE")
	print("=".repeat(60))
	print("Running comprehensive tests for game logic...\n")

	var start_time = Time.get_unix_time_from_system()

	# Run all test suites
	var bots_result = run_bots_tests()
	if not bots_result: return false
	var hand_result = run_hand_evaluation_tests()
	if not hand_result: return false
	var card_result = run_card_logic_tests()
	if not card_result: return false
	var game_result = run_game_state_tests()
	if not game_result: return false
	var sync_result = run_multiplayer_sync_tests()
	if not sync_result: return false
	var player_result = run_player_tests()
	if not player_result: return false
	var post_meld_result = run_post_meld_logic_tests()
	if not post_meld_result: return false
	var post_meld_flow_result = run_post_meld_flow_tests()
	if not post_meld_flow_result: return false
	var style_result = run_code_style_tests()
	if not style_result: return false

	var end_time = Time.get_unix_time_from_system()
	var duration = end_time - start_time

	# Print final summary
	print("\n" + "=".repeat(60))
	print("   FINAL TEST RESULTS")
	print("=".repeat(60))
	print("Total test suites run: 9")
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

	# Clean up resources before quitting
	cleanup_test_resources()

	if total_failed == 0:
		get_tree().quit(0)
	else:
		get_tree().quit(1)
	return total_failed == 0

func run_bots_tests() -> bool:
	var test_suite = TestBots.new()
	add_child(test_suite)
	var result = test_suite.run_all_tests()
	update_totals(test_suite.test_framework)
	# Ensure proper cleanup of all child nodes
	test_suite.cleanup_test_resources()
	remove_child(test_suite)
	test_suite.queue_free()
	return result

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

func run_post_meld_logic_tests() -> bool:
	var test_suite = TestPostMeldLogic.new()
	add_child(test_suite)
	var result = test_suite.run_all_tests()
	update_totals(test_suite.test_framework)
	# Ensure proper cleanup of all child nodes
	test_suite.cleanup_test_resources()
	remove_child(test_suite)
	test_suite.queue_free()
	return result

func run_post_meld_flow_tests() -> bool:
	var test_suite = TestPostMeldFlow.new()
	add_child(test_suite)
	var result = test_suite.run_tests()
	# Update totals based on the dictionary returned
	total_tests += result["total"]
	total_passed += result["passed"]
	total_failed += result["failed"]
	# Cleanup
	remove_child(test_suite)
	test_suite.queue_free()
	return result["failed"] == 0

func run_code_style_tests() -> bool:
	var test_suite = TestCodeStyle.new()
	add_child(test_suite)
	var result = test_suite.run_all_tests()
	update_totals(test_suite.test_framework)
	# Ensure proper cleanup of all child nodes
	test_suite.cleanup_test_resources()
	remove_child(test_suite)
	test_suite.queue_free()
	return result

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
		test_basic_round_requirements
	]

	return test_framework.run_test_suite("Smoke Tests", quick_tests)

func test_basic_card_scoring() -> bool:
	# Global is an autoload, access it directly
	test_framework.assert_equal(15, Global.card_key_score("A-hearts-0"), "Ace should score 15")
	test_framework.assert_equal(10, Global.card_key_score("K-spades-0"), "King should score 10")
	return true

func test_basic_hand_stats() -> bool:
	# Global is an autoload, access it directly
	var cards = ["A-hearts-0", "A-spades-0", "K-hearts-0"]
	var stats = Global.gen_hand_stats(cards)
	test_framework.assert_equal(3, stats['num_cards'], "Should have 3 cards")
	test_framework.assert_equal(2, len(stats['by_rank']['A']), "Should have 2 Aces")
	return true

func test_basic_game_state() -> bool:
	# Global is an autoload, access it directly
	Global.reset_game()
	test_framework.assert_equal(1, Global.game_state['current_round_num'], "Should start at round 1")
	return true

func test_basic_round_requirements() -> bool:
	# Global is an autoload, access it directly
	test_framework.assert_equal(2, Global._groups_per_round[0], "Round 1 should require 2 groups")
	test_framework.assert_equal(0, Global._runs_per_round[0], "Round 1 should require 0 runs")
	return true
