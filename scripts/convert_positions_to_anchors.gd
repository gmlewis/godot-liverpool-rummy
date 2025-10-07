@tool
extends Control

@export var convert_now: bool = false:
    set(value):
        if value and Engine.is_editor_hint():
            convert_children_to_anchors()
            convert_now = false

func convert_children_to_anchors():
    # var viewport_size = get_viewport_rect().size
    var viewport_size = Vector2(2880, 1440)

    # Safety check!
    if viewport_size.x == 0 or viewport_size.y == 0:
        push_error("Viewport size is zero! Make sure the scene is properly loaded.")
        print("ERROR: Viewport size is invalid!")
        return

    print("Viewport size: ", viewport_size)

    convert_node_recursive(self, viewport_size)

    print("Conversion complete!")

func convert_node_recursive(node: Node, viewport_size: Vector2):
    for child in node.get_children():
        if child is Control:
            # Get the global position and size
            var global_pos = child.global_position
            var child_size = child.size

            # Calculate anchor percentages relative to viewport
            child.anchor_left = global_pos.x / viewport_size.x
            child.anchor_top = global_pos.y / viewport_size.y
            child.anchor_right = (global_pos.x + child_size.x) / viewport_size.x
            child.anchor_bottom = (global_pos.y + child_size.y) / viewport_size.y

            # Reset offsets to 0 so anchors control everything
            child.offset_left = 0
            child.offset_top = 0
            child.offset_right = 0
            child.offset_bottom = 0

            print("Converted: ", child.name, " at ", global_pos)

        # Recursively process children
        convert_node_recursive(child, viewport_size)