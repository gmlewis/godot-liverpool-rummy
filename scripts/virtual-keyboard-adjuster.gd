extends LineEdit

var root_node: Control
# var is_monitoring_keyboard = false
var original_position_y = 0
var last_keyboard_height = 0

func _ready():
	if not OS.has_feature("mobile"): return
	root_node = get_node("/root/RootNode")
	original_position_y = root_node.position.y

	focus_entered.connect(_on_focus_entered)
	# focus_exited.connect(_on_focus_exited)

func _exit_tree():
	if not OS.has_feature("mobile"): return
	focus_entered.disconnect(_on_focus_entered)
	# focus_exited.disconnect(_on_focus_exited)

func _on_focus_entered():
	# is_monitoring_keyboard = true
	last_keyboard_height = 0

# func _on_focus_exited():
# 	# Keep monitoring so it tracks the keyboard going down
# 	# Don't reset anything here
# 	pass

func _process(_delta):
	if not OS.has_feature("mobile"): return
	# if is_monitoring_keyboard:
	var keyboard_height = DisplayServer.virtual_keyboard_get_height()

	# Only update if the height has changed
	if keyboard_height != last_keyboard_height:
		print("Keyboard height: ", keyboard_height)
		last_keyboard_height = keyboard_height

		# When keyboard is gone (height is 0), return to original position
		if keyboard_height == 0:
			root_node.position.y = original_position_y
			# Stop monitoring once keyboard is fully gone
			# is_monitoring_keyboard = false
		else:
			# Add extra pixels to account for suggestion bars and decorations
			var extra_padding = 400
			var adjusted_height = keyboard_height + extra_padding

			print("Adjusted height: ", adjusted_height)

			# Move the screen to match the adjusted keyboard position
			root_node.position.y = original_position_y - adjusted_height
