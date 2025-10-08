@tool
extends Control

@export var generate_script: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			generate_recreation_script()
			generate_script = false

func generate_recreation_script():
	var script_lines = []
	script_lines.append("@tool")
	script_lines.append("extends Control")
	script_lines.append("")
	script_lines.append("@export var create_nodes: bool = false:")
	script_lines.append("\tset(value):")
	script_lines.append("\t\tif value and Engine.is_editor_hint():")
	script_lines.append("\t\t\trecreate_hierarchy()")
	script_lines.append("\t\t\tcreate_nodes = false")
	script_lines.append("")
	script_lines.append("func recreate_hierarchy():")

	# Generate code for this node and all children
	generate_node_code(self, script_lines, 1, "self")

	script_lines.append("\tprint('Hierarchy recreation complete!')")

	var full_script = "\n".join(script_lines)
	var separator = "================================================================================"
	print(separator)
	print("GENERATED SCRIPT - Copy everything below:")
	print(separator)
	print(full_script)
	print(separator)
	print("Script generation complete! Copy the output above.")

func generate_node_code(node: Node, script_lines: Array, indent: int, parent_var: String):
	var tab = "\t".repeat(indent)

	for i in range(node.get_child_count()):
		var child = node.get_child(i)

		# Only process Control, Label, and ColorRect
		if not (child is Control or child is Label or child is ColorRect):
			continue

		var node_type = child.get_class()
		var var_name = "node_" + str(script_lines.size())

		# Create the node
		script_lines.append(tab + "var " + var_name + " = " + node_type + ".new()")
		script_lines.append(tab + var_name + ".name = \"" + child.name + "\"")
		script_lines.append(tab + parent_var + ".add_child(" + var_name + ")")
		script_lines.append(tab + var_name + ".owner = get_tree().edited_scene_root")

		# Set Control properties
		if child is Control:
			script_lines.append(tab + var_name + ".position = Vector2(" + str(child.position.x) + ", " + str(child.position.y) + ")")
			script_lines.append(tab + var_name + ".size = Vector2(" + str(child.size.x) + ", " + str(child.size.y) + ")")
			script_lines.append(tab + var_name + ".anchor_left = " + str(child.anchor_left))
			script_lines.append(tab + var_name + ".anchor_top = " + str(child.anchor_top))
			script_lines.append(tab + var_name + ".anchor_right = " + str(child.anchor_right))
			script_lines.append(tab + var_name + ".anchor_bottom = " + str(child.anchor_bottom))
			script_lines.append(tab + var_name + ".offset_left = " + str(child.offset_left))
			script_lines.append(tab + var_name + ".offset_top = " + str(child.offset_top))
			script_lines.append(tab + var_name + ".offset_right = " + str(child.offset_right))
			script_lines.append(tab + var_name + ".offset_bottom = " + str(child.offset_bottom))

		# Set Label-specific properties
		if child is Label:
			script_lines.append(tab + var_name + ".text = \"" + child.text.replace("\"", "\\\"") + "\"")
			script_lines.append(tab + var_name + ".horizontal_alignment = " + str(child.horizontal_alignment))
			script_lines.append(tab + var_name + ".vertical_alignment = " + str(child.vertical_alignment))

		# Set ColorRect-specific properties
		if child is ColorRect:
			var color = child.color
			script_lines.append(tab + var_name + ".color = Color(" + str(color.r) + ", " + str(color.g) + ", " + str(color.b) + ", " + str(color.a) + ")")

		# Handle material (for shaders)
		if child.material != null:
			script_lines.append(tab + "# Note: Material/Shader must be set manually")

		script_lines.append("")

		# Recursively process children
		if child.get_child_count() > 0:
			generate_node_code(child, script_lines, indent, var_name)
