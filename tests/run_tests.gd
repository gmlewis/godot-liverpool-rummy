#!/usr/bin/env godot
# Test execution script for Liverpool Rummy
# This script can be run from the command line to execute all tests

extends Node

# Preload required classes
# const TestRunner = preload("res://tests/test_runner.gd")

func _initialize():
	print("Starting Liverpool Rummy test suite...")

	# Create and run the test runner
	var test_runner = TestRunner.new()
	var result = test_runner.run_all_tests()
	if not result:
		get_tree().quit(1)
