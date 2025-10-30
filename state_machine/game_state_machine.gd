extends Node
class_name GameStateMachine

signal gsm_changed_state_signal(from_state: String, to_state: String)

var initial_state: String = "ResetGameState"
var current_state: GameState
var states: Dictionary = {}

func _ready() -> void:
	Global.connect('reset_game_signal', _on_reset_game_signal)
	Global.connect('transition_all_clients_state_to_signal', _on_transition_all_clients_state_to_signal)
	_on_reset_game_signal()

func _exit_tree() -> void:
	Global.disconnect('reset_game_signal', _on_reset_game_signal)
	Global.disconnect('transition_all_clients_state_to_signal', _on_transition_all_clients_state_to_signal)

func _on_reset_game_signal() -> void:
	# Initialize all GSM child states
	for child in get_children():
		if child is GameState and not child.state_machine:
			states[child.name] = child
			child.state_machine = self
			child.transition_requested_signal.connect(_on_transition_requested_signal)
	# Start with initial state
	if initial_state in states:
		change_state(initial_state, {})
	else:
		push_error("Initial state '%s' not found" % [initial_state])
	# if not Global.is_connected('game_state_updated_signal', _on_game_state_updated_signal):
	# 	Global.connect('game_state_updated_signal', _on_game_state_updated_signal)

func _input(event: InputEvent) -> void:
	# GameStateMachine delegates input to current state - this doesn't call set_input_as_handled()
	# Global.dbg("GameStateMachine._input: Delegating to current_state '%s'" % get_current_state_name())
	if current_state:
		current_state.handle_input(event)

func _process(delta: float) -> void:
	if current_state:
		current_state.handle_process(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.handle_physics_process(delta)

# func _on_game_state_updated_signal():
# 	if Global.game_state.current_state_name == get_current_state_name(): return
# 	Global.dbg("GSM:_on_game_state_updated_signal: current_state_name='%s' - IS THIS CORRECT?!?!?" % [Global.game_state.current_state_name])
# 	change_state(Global.game_state.current_state_name)

func change_state(new_state_name: String, params: Dictionary) -> void:
	Global.dbg("GSM:change_state('%s')" % [new_state_name])
	var previous_state_name = get_current_state_name()
	# new_state_name can be empty to force re-entry into the current state
	if (new_state_name == previous_state_name):
		# push_error("(%d)GSM:change_state('%s') same as current state!" % [multiplayer.get_unique_id(), new_state_name])
		return
	if new_state_name == '':
		new_state_name = previous_state_name
	var new_state = states.get(new_state_name)
	if not new_state:
		push_error("State '" + new_state_name + "' not found!")
		return
	if current_state: current_state.exit()
	current_state = new_state
	current_state.enter(params)
	# The following print statement always appears out-of-order and is therefore not helpful.
	#Global.dbg("GSM: State changed from '%s' to '%s'" % [previous_state_name, new_state_name])
	# if Global.is_server() and Global.game_state.current_state_name != new_state_name:
	# 	Global.game_state.current_state_name = new_state_name
	# 	Global.send_game_state()
	gsm_changed_state_signal.emit(previous_state_name, new_state_name)

func _on_transition_requested_signal(to_state: String, params: Dictionary) -> void:
	Global.dbg("GSM:_on_transition_requested_signal('%s')" % [to_state])
	change_state(to_state, params)

func get_current_state_name() -> String:
	return str(current_state.name) if current_state else ""

func is_playing_state() -> bool:
	var current_state_name = get_current_state_name()
	return current_state_name == 'NewDiscardState' or current_state_name == 'PlayerDrewState'

func _on_transition_all_clients_state_to_signal(new_state: String) -> void:
	if Global.is_not_server(): return
	Global.dbg("GSM: _on_transition_all_clients_state_to_signal('%s') - calling RPC" % [new_state])
	_rpc_transition_all_clients_state_to.rpc(new_state)

# Convenience method for state transitions to all clients (from the server only)
@rpc('authority', 'call_local', 'reliable')
func _rpc_transition_all_clients_state_to(state_name: String, params: Dictionary = {}):
	Global.dbg("GSM: received RPC transition_all_clients_state_to('%s')" % [state_name])
	_on_transition_requested_signal(state_name, params)
