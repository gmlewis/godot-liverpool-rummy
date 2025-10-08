@tool
extends Control

@export var dump_now: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			dump_node_recursive(self)
			print("Dump complete!")
			dump_now = false

func dump_node_recursive(node: Node):
	print("Dump: ", node.name,
		" with anchors: (L:",
		node.anchor_left, ", T:", node.anchor_top, ", R:",
		node.anchor_right, ", B:", node.anchor_bottom, ")")
	for child in node.get_children():
		dump_node_recursive(child)

# Dump: MeldArea with anchors: (L:0.0, T:0.69999998807907, R:0.5, B:1.0)
# Dump: Book1 with anchors: (L:0.0, T:0.0, R:0.33300000429153, B:1.0)
# Dump: Book1Label with anchors: (L:0.0, T:0.0, R:1.0, B:0.10000000149012)
# Dump: Book1Area with anchors: (L:0.02500000037253, T:0.125, R:0.97500002384186, B:0.97500002384186)
# Dump: Book2 with anchors: (L:0.33300000429153, T:0.0, R:0.66600000858307, B:1.0)
# Dump: Book2Label with anchors: (L:0.0, T:0.0, R:1.0, B:0.10000000149012)
# Dump: Book2Area with anchors: (L:0.02500000037253, T:0.125, R:0.97500002384186, B:0.97500002384186)
# Dump complete!
