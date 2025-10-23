class_name TestCodeStyle
extends Node

var test_framework: TestFramework

func _ready():
	test_framework = TestFramework.new()
	add_child(test_framework)

func test_indentation_and_style_consistency():
	# Test code style on key files
	var key_files = [
		"res://scenes/title_page_ui.gd",
		"res://global.gd",
		"res://tests/test_runner.gd",
		"res://tests/test_code_style.gd"
	]

	var total_files_checked = 0
	var total_issues_found = 0

	for file_path in key_files:
		var result = _check_file_style(file_path)
		total_files_checked += 1
		total_issues_found += result["issues_found"]

		# If issues found, report them and auto-fix
		if result["issues_found"] > 0:
			print("Style issues in %s: %d issues found - auto-fixing..." % [file_path, result["issues_found"]])
			for issue in result["issues"]:
				print("  " + issue)

			# Auto-fix the file
			if _write_file(file_path, result["fixed_content"]):
				print("  ✓ Auto-fixed %s" % file_path)
				total_issues_found -= result["issues_found"] # Issues are now fixed
			else:
				print("  ✗ Failed to auto-fix %s" % file_path)

	test_framework.assert_equal(4, total_files_checked, "Should have checked 4 key files")
	test_framework.assert_true(total_issues_found == 0, "No style issues should be found (found %d)" % total_issues_found)
	return true

func _check_file_style(file_path):
	var result = {
		"issues_found": 0,
		"issues": [],
		"fixed_content": ""
	}

	var content = _read_file(file_path)
	if content == "":
		result["issues"].append("Could not read file: %s" % file_path)
		result["issues_found"] = 1
		return result

	var lines = content.split("\n")
	var fixed_lines = []

	for i in range(lines.size()):
		var line = lines[i]
		var issues = []

		# Check for trailing whitespace (spaces only, not tabs or newlines)
		if line.rstrip("\t").ends_with(" "):
			issues.append("Line %d: Trailing spaces" % (i + 1))
			line = line.rstrip(" ") # Remove trailing spaces only

		# Check indentation consistency (tabs only, no leading spaces)
		if line.begins_with(" ") and not line.begins_with("\t"):
			issues.append("Line %d: Uses spaces for indentation instead of tabs" % (i + 1))
			# Convert leading spaces to tabs (4 spaces = 1 tab)
			var leading_spaces = 0
			for j in range(line.length()):
				if line[j] == " ":
					leading_spaces += 1
				else:
					break
			var tabs_needed = int(leading_spaces / 4.0)
			var tab_string = ""
			for j in range(tabs_needed):
				tab_string += "\t"
			line = tab_string + line.substr(leading_spaces)

		# Add issues to result
		for issue in issues:
			result["issues"].append(issue)
			result["issues_found"] += 1

		fixed_lines.append(line)

	result["fixed_content"] = "\n".join(fixed_lines)
	return result

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

func _write_file(file_path, content):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		return true
	return false

func run_all_tests() -> bool:
	return test_framework.discover_and_run_test_suite("Code Style Tests", self)

func cleanup_test_resources() -> void:
	# Clean up test framework
	if test_framework and is_instance_valid(test_framework):
		if test_framework.is_inside_tree():
			remove_child(test_framework)
		test_framework.queue_free()
	test_framework = null
