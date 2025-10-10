# Test Framework for Liverpool Rummy
# Simple, lightweight test framework for GDScript

class_name TestFramework
extends Node

# Test results tracking
var tests_run: int = 0
var tests_passed: int = 0
var tests_failed: int = 0
var current_test_name: String = ""
var failed_tests: Array[String] = []

# Color codes for console output - using 256-color ANSI for better terminal compatibility
const COLOR_RED = "\u001b[38;5;196m" # 256-color bright red
const COLOR_GREEN = "\u001b[38;5;46m" # 256-color bright green
const COLOR_YELLOW = "\u001b[38;5;226m" # 256-color bright yellow
const COLOR_BLUE = "\u001b[38;5;75m" # 256-color medium-light blue (readable on black backgrounds)
const COLOR_RESET = "\u001b[0m"

# Test assertion methods
func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		fail_test("Expected true, got false" + (" - " + message if message else ""))

func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		fail_test("Expected false, got true" + (" - " + message if message else ""))

func assert_equal(expected, actual, message: String = "") -> void:
	if expected != actual:
		fail_test("Expected '%s', got '%s'" % [str(expected), str(actual)] + (" - " + message if message else ""))
		return # Stop execution on failure

func assert_not_equal(expected, actual, message: String = "") -> void:
	if expected == actual:
		fail_test("Expected values to be different, but both were '%s'" % [str(expected)] + (" - " + message if message else ""))

func assert_null(value, message: String = "") -> void:
	if value != null:
		fail_test("Expected null, got '%s'" % [str(value)] + (" - " + message if message else ""))

func assert_not_null(value, message: String = "") -> void:
	if value == null:
		fail_test("Expected non-null value, got null" + (" - " + message if message else ""))

func assert_array_size(array: Array, expected_size: int, message: String = "") -> void:
	if array.size() != expected_size:
		fail_test("Expected array size %d, got %d" % [expected_size, array.size()] + (" - " + message if message else ""))

func assert_dict_has_key(dict: Dictionary, key, message: String = "") -> void:
	if not dict.has(key):
		fail_test("Expected dictionary to have key '%s'" % [str(key)] + (" - " + message if message else ""))

func assert_dict_not_has_key(dict: Dictionary, key, message: String = "") -> void:
	if dict.has(key):
		fail_test("Expected dictionary to NOT have key '%s'" % [str(key)] + (" - " + message if message else ""))

func assert_in_range(value: float, min_val: float, max_val: float, message: String = "") -> void:
	if value < min_val or value > max_val:
		fail_test("Expected value %f to be in range [%f, %f]" % [value, min_val, max_val] + (" - " + message if message else ""))

# Test lifecycle methods
var current_test_failed: bool = false

func start_test(test_name: String) -> void:
	current_test_name = test_name
	tests_run += 1
	current_test_failed = false
	print(COLOR_BLUE + "  Running: " + test_name + COLOR_RESET)

func pass_test() -> void:
	if not current_test_failed:
		tests_passed += 1
		print(COLOR_GREEN + "  ✓ PASSED: " + current_test_name + COLOR_RESET)

func fail_test(reason: String) -> void:
	if not current_test_failed:
		tests_failed += 1
		current_test_failed = true
	failed_tests.append(current_test_name + ": " + reason)
	print(COLOR_RED + "  ✗ FAILED: " + current_test_name + " - " + reason + COLOR_RESET)
	# Don't quit here - let the test runner handle exit codes

# Test suite management
func run_test_suite(test_suite_name: String, test_functions: Array) -> bool:
	print(COLOR_YELLOW + "\n=== Running Test Suite: " + test_suite_name + " ===" + COLOR_RESET)

	# Check if Global is available before running any tests
	if Global == null:
		print(COLOR_RED + "ERROR: Global autoload is not available - likely due to syntax error in global.gd" + COLOR_RESET)
		print(COLOR_RED + "This indicates a compilation failure that should cause tests to fail!" + COLOR_RESET)
		print(COLOR_RED + "EXITING DUE TO GLOBAL AUTOLOAD FAILURE" + COLOR_RESET)
		return false

	for test_func in test_functions:
		var test_name = str(test_func.get_method())
		start_test(test_name)
		# GDScript doesn't have try/except, so we call the function directly
		# If it fails, it will print errors to console

		var result = test_func.call()
		# print("GML: test '%s' result: %s" % [test_name, str(result)])
		if result == null or result == false or current_test_failed:
			print("GML: test '%s' result: %s - test failed" % [test_name, str(result)])
			# Don't quit here - let the test runner handle exit codes
			return false
		pass_test()

	print_results()
	return true

func print_results() -> void:
	print(COLOR_YELLOW + "\n=== Test Results ===" + COLOR_RESET)
	print("Total tests run: %d" % tests_run)
	print(COLOR_GREEN + "Passed: %d" % tests_passed + COLOR_RESET)
	if tests_failed == 0:
		print(COLOR_GREEN + "Failed: %d" % tests_failed + COLOR_RESET)
	else:
		print(COLOR_RED + "Failed: %d" % tests_failed + COLOR_RESET)

	if tests_failed > 0:
		print(COLOR_RED + "\nFailed tests:" + COLOR_RESET)
		for failed_test in failed_tests:
			print(COLOR_RED + "  - " + failed_test + COLOR_RESET)

	var success_rate = (tests_passed as float / tests_run as float) * 100.0
	print("\nSuccess rate: %.1f%%" % success_rate)

	if tests_failed == 0:
		print(COLOR_GREEN + "🎉 All tests passed!" + COLOR_RESET)
	else:
		print(COLOR_RED + "❌ Some tests failed. Please review and fix." + COLOR_RESET)

# Utility method for testing exceptions
func assert_throws(_callable_func: Callable, _message: String = "") -> void:
	# GDScript doesn't have try/except, so we skip exception testing for now
	# This would need to be implemented differently in GDScript
	print("Warning: Exception testing not implemented in GDScript")
	pass

# Reset test state for multiple runs
func reset() -> void:
	tests_run = 0
	tests_passed = 0
	tests_failed = 0
	current_test_name = ""
	failed_tests.clear()
