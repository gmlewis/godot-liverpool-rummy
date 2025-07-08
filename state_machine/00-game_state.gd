extends Node
class_name GameState

signal transition_requested_signal(to_state: String, params: Dictionary)

var state_machine: GameStateMachine

# Override these methods in child states
func enter(_params: Dictionary):
	pass

func exit():
	pass

func handle_input(_event: InputEvent):
	pass

func handle_process(_delta: float):
	pass

func handle_physics_process(_delta: float):
	pass

# Convenience method for state transitions
func transition_state_to(state_name: String, params: Dictionary = {}):
	transition_requested_signal.emit(state_name, params)

# Convenience method for state transitions to all clients (from the server only)
@rpc('authority', 'call_local', 'reliable')
func _rpc_transition_all_clients_state_to(state_name: String, params: Dictionary = {}):
	Global.dbg("00-game_state.gd: received RPC transition_all_clients_state_to('%s')" % [state_name])
	transition_requested_signal.emit(state_name, params)
