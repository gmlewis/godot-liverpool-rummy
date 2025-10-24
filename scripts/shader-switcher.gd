extends ColorRect

enum ShaderType {FUZZY, SPARKLE}

var fuzzy_shader: Shader
var sparkle_shader: Shader

var current_shader: ShaderType = ShaderType.FUZZY
var meld_area_index: int

func _ready() -> void:
	fuzzy_shader = load("res://shaders/fuzzyrect.gdshader")
	sparkle_shader = load("res://shaders/sparklerect.gdshader")

	meld_area_index = get_parent().get_index()
	Global.dbg("GML: ShaderSwitcher for meld_area_index=%d, parent=%s" % [meld_area_index, str(get_parent())])

	Global.meld_area_state_changed_signal.connect(_on_meld_area_state_changed_signal)

func _exit_tree() -> void:
	Global.meld_area_state_changed_signal.disconnect(_on_meld_area_state_changed_signal)

func _on_meld_area_state_changed_signal(is_complete: bool, area_index: int) -> void:
	Global.dbg("GML: ShaderSwitcher(%d) meld_area_state_changed_signal: is_complete=%s, area_index=%d" % [meld_area_index, str(is_complete), area_index])
	if area_index != meld_area_index:
		return
	var new_shader = ShaderType.SPARKLE if is_complete else ShaderType.FUZZY
	if new_shader == current_shader:
		return
	current_shader = new_shader
	if current_shader == ShaderType.FUZZY:
		material = ShaderMaterial.new()
		material.shader = fuzzy_shader
	else:
		material = ShaderMaterial.new()
		material.shader = sparkle_shader
