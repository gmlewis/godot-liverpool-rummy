extends Node2D

var debug_enabled = false
var debug_data = {
	"bounds": null,
	"existing_rects": [],
	"tested_positions": [],
	"candidate_positions": [],
	"best_position": null,
	"best_rect": null,
	"min_overlap": 0.0
}

func set_debug_drawing(enabled: bool):
	debug_enabled = enabled
	# debug_canvas_item = canvas_item
	# if debug_canvas_item and debug_enabled:
	# 	# Connect to the draw signal if not already connected
	# 	if not debug_canvas_item.draw.is_connected(_draw_debug_info):
	# 		debug_canvas_item.draw.connect(_draw_debug_info)

func clear_debug_data():
	debug_data = {
		"bounds": null,
		"existing_rects": [],
		"tested_positions": [],
		"candidate_positions": [],
		"best_position": null,
		"best_rect": null,
		"min_overlap": 0.0
	}

func _draw():
	if debug_enabled:
		_draw_debug_info()

# This method should be called from the CanvasItem's _draw() method
func _draw_debug_info():
	if not debug_enabled: # or not debug_canvas_item:
		return

	# Draw bounds
	if debug_data.bounds:
		draw_rect(debug_data.bounds, Color.BLUE, false, 3.0)
		var label_pos = debug_data.bounds.position + Vector2(5, -5)
		draw_string(ThemeDB.fallback_font, label_pos, "Bounds", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.BLUE)

	# Draw existing rectangles
	for i in range(debug_data.existing_rects.size()):
		var rect = debug_data.existing_rects[i]
		draw_rect(rect, Color.RED, false, 2.0)
		var label_pos = rect.position + Vector2(5, -5)
		draw_string(ThemeDB.fallback_font, label_pos, "Existing " + str(i), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.RED)

	# Draw tested positions (grid search)
	for test_data in debug_data.tested_positions:
		var rect = test_data.rect
		var overlap = test_data.overlap

		# Color code based on overlap amount
		var color: Color
		if overlap == 0:
			color = Color.CYAN # Perfect positions
		elif overlap == debug_data.min_overlap:
			color = Color.MAGENTA # Best positions found
		elif overlap < debug_data.min_overlap * 2:
			color = Color.YELLOW # Good positions
		else:
			color = Color.GRAY # Poor positions

		# Draw with low opacity to avoid cluttering
		color.a = 0.3
		draw_rect(rect, color, true)

		# Draw outline
		color.a = 0.8
		draw_rect(rect, color, false, 1.0)

	# Draw candidate positions
	for candidate_data in debug_data.candidate_positions:
		var rect = candidate_data.rect
		var overlap = candidate_data.overlap
		var index = candidate_data.index

		var color = Color.YELLOW if overlap == 0 else Color.ORANGE
		draw_rect(rect, color, false, 1.5)
		var label_pos = rect.position + Vector2(5, -5)
		draw_string(ThemeDB.fallback_font, label_pos, "Candidate " + str(index) + " (Overlap: " + str(overlap) + ")", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)

	# Draw the final chosen position
	if debug_data.best_rect:
		draw_rect(debug_data.best_rect, Color.GREEN, false, 4.0)
		var label_pos = debug_data.best_rect.position + Vector2(5, -5)
		draw_string(ThemeDB.fallback_font, label_pos, "Best Position (Overlap: " + str(debug_data.min_overlap) + ")", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GREEN)
