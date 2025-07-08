extends Node

# Basic test to verify test framework works

const TestFramework = preload("res://tests/test_framework.gd")

func _ready():
	print("Running basic test...")
	
	var test_framework = TestFramework.new()
	
	# Simple tests that don't depend on Global
	test_framework.start_test("Basic math test")
	test_framework.assert_equal(4, 2 + 2, "2 + 2 should equal 4")
	test_framework.pass_test()
	
	test_framework.start_test("String test")
	test_framework.assert_equal("hello", "hello", "Strings should match")
	test_framework.pass_test()
	
	test_framework.start_test("Array test")
	var arr = [1, 2, 3]
	test_framework.assert_equal(3, arr.size(), "Array should have 3 elements")
	test_framework.pass_test()
	
	test_framework.print_results()
	
	print("Basic test completed")
	get_tree().quit()
