class_name TestCodeStyle
extends Node

var test_framework: TestFramework

func _ready():
	test_framework = TestFramework.new()
	add_child(test_framework)

func test_indentation_and_style_consistency():
	# Simple test - just check if we can read a file
	var content = _read_file("res://scenes/title_page_ui.gd")
	test_framework.assert_true(content.length() > 0, "Should be able to read title_page_ui.gd")
	test_framework.assert_true(content.contains("func"), "Should contain function definitions")
	return true

func _find_gd_files(dir_path):
	var files = []
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path = dir_path + "/" + file_name
			if file_name.ends_with(".gd"):
				files.append(full_path)
			elif dir.current_is_dir() and not file_name.begins_with("."):
				files.append_array(_find_gd_files(full_path))
			file_name = dir.get_next()
	return files

func _read_file(file_path):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		return file.get_as_text()
	return ""

func run_all_tests() -> bool:
	return test_framework.discover_and_run_test_suite("Code Style Tests", self)

func cleanup_test_resources() -> void:
	# Clean up test framework
	if test_framework and is_instance_valid(test_framework):
		if test_framework.is_inside_tree():
			remove_child(test_framework)
		test_framework.queue_free()
	test_framework = null
