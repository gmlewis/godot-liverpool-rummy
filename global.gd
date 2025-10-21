extends Node

# The server (id=1) contains the official copy of [game_state] and sends a copy to
# all clients upon every update. It is a small object and is fast to send.
# It contains all public knowledge about the game state, but nothing private.
var game_state = {}

# Each player maintains their own copy of 'private_player_info' which is initially used
# to set up the player and then is copied onto a Player and copied into the
# game_state.public_players_info array which is then ordered by turn index where index 0
# is always the host (server) (even though the first turn starts to the right of the host.
var private_player_info = {}

# Bots are strictly run only on the server and each maintain their own equivalent of
# private_player_info (which is not sent to clients).
# Each bot is keyed by a string id of the form 'bot#' where # is a number.
var bots_private_player_info = {}

# Each peer (server or client) can customize their view of their playing card backs.
var custom_card_back: Sprite2D = Sprite2D.new()

# Flag to track if the game has started (prevents late joins)
var game_has_started = false

# playing_cards is a Dictionary (uniquely keyed by rank-suit-deck, e.g. 'A-spades-0', 'Joker-1-0', 'Joker-2-0', etc.)
# of Node2D instances of the PlayingCard class, one for each card in play.
# It is generated on-demand in the StartRoundShuffleState and each peer (server and clients) have their own copy.
var playing_cards: Dictionary[String, PlayingCard] = {}

# All peers have their own copy of the stock and discard piles that are kept in sync with the server.
var stock_pile: Array[PlayingCard] = [] # top of deck (back is visible) at index 0, bottom at index len(stock_pile)-1.
var discard_pile: Array[PlayingCard] = [] # top of deck (face is visible) at index 0, bottom at index len(discard_pile)-1.

# Values used in multiple places:
var deal_speed_pixels_per_second: float
var play_speed_pixels_per_second: float
var screen_aspect_ratio: float = 0.0 # Calculated from screen_size.y / screen_size.x
var screen_center: Vector2
var screen_size: Vector2
var stock_pile_position: Vector2
var discard_pile_position: Vector2
var player_hand_x_end: float
var player_hand_y_position: float

signal player_connected_signal(peer_id, public_player_info)
signal attach_bot_instance_to_player_signal(id, bot_instance)
signal player_disconnected_signal(peer_id)
signal server_disconnected_signal
signal players_reordered_signal(new_order: Array)
signal custom_card_back_texture_changed_signal
signal game_state_updated_signal
signal change_round_signal(scene: PackedScene, ack_sync_name: String)
signal reset_game_signal
signal animate_move_card_to_player_signal(playing_card: PlayingCard, player_id: String, ack_sync_name: String)
signal animate_move_card_from_player_to_discard_pile_signal(playing_card: PlayingCard, player_id: String, player_won: bool, ack_sync_name: String)
signal animate_personally_meld_cards_only_signal(player_id: String, hand_evaluation: Dictionary, ack_sync_name: String)
signal animate_publicly_meld_card_only_signal(player_id: String, card_key: String, target_player_id: String, meld_group_index: int, ack_sync_name: String)
signal animate_winning_confetti_explosion_signal(num_millis: int)
signal new_card_exposed_on_discard_pile_signal()
signal transition_all_clients_state_to_signal(state_name: String)
signal server_ack_sync_completed_signal(peer_id: int, operation_name: String, operation_params: Dictionary)
# Local player card manipulation signals:
signal card_clicked_signal(playing_card, global_position)
signal card_drag_started_signal(playing_card, from_position)
signal card_moved_signal(playing_card, from_position, global_position)
signal meld_area_state_changed(is_valid: bool, area_idx: int)

@onready var playing_cards_control: Control = $"/root/RootNode/PlayingCardsControl" if has_node("/root/RootNode/PlayingCardsControl") else null

const VERSION = '0.5.0'
const GAME_PORT = 7000
const DISCOVERY_PORT = 8910
const MAX_PLAYERS = 10
const CARD_SPACING_IN_STACK = 0.5 # Y-spacing for final stack in pixels
const PLAYER_SCALE = Vector2(0.65, 0.65)
const DEBUG_SHOW_CARD_INFO = false
const OTHER_PLAYER_BUY_GRACE_PERIOD_SECONDS: float = 3.0 # if DEBUG_SHOW_CARD_INFO else 10.0
const MELD_AREA_TOP_PERCENT = 0.7 # 70% down the screen
const MELD_AREA_RIGHT_PERCENT = 0.5 # 50% across the screen
const MELD_AREA_1_RIGHT_PERCENT = 0.333 * MELD_AREA_RIGHT_PERCENT # 16.65% across the screen
const MELD_AREA_2_RIGHT_PERCENT = 0.666 * MELD_AREA_RIGHT_PERCENT # 33.3% across the screen

# This game can be compiled in different languages (currently, only 'en' or 'de').
const LANGUAGE = 'en' # 'en', 'fr', 'de', etc.

func _ready():
	_initialize_from_command_line_args()

	# dbg("Global._ready: stock_pile_position=%s" % [str(stock_pile_position)])
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _exit_tree():
	multiplayer.peer_connected.disconnect(_on_peer_connected)
	multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)
	multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	multiplayer.connection_failed.disconnect(_on_connection_failed)
	multiplayer.server_disconnected.disconnect(_on_server_disconnected)

	# Clean up resources
	if custom_card_back:
		custom_card_back.queue_free()
		custom_card_back = null

# The following are only used on the desktop.
@export var SPLIT_SCREEN_STYLE := VERTICAL
@export var USE_RATIO := true

func _initialize_from_command_line_args() -> void:
	screen_size = get_viewport().get_visible_rect().size
	screen_aspect_ratio = screen_size.y / screen_size.x
	var screen_rect = DisplayServer.screen_get_usable_rect()
	var window_size = get_window().size
	dbg("Global._initialize_from_command_line_args: screen_size=%s, screen_aspect_ratio=%f, screen_rect=%s, window_size=%s" %
		[str(screen_size), screen_aspect_ratio, str(screen_rect), str(window_size)])

	var args = OS.get_cmdline_args()
	if "--server" in args:
		# Upper right corner
		get_window().position = Vector2(
			screen_rect.position.x + screen_rect.size.x - window_size.x,
			screen_rect.position.y
		)
	elif "--client1" in args:
		# Lower right corner
		get_window().position = Vector2(
			screen_rect.position.x + screen_rect.size.x - window_size.x,
			screen_rect.position.y + screen_rect.size.y - window_size.y
		)
	elif "--client2" in args:
		# Lower left corner
		get_window().position = Vector2(
			screen_rect.position.x,
			screen_rect.position.y + screen_rect.size.y - window_size.y
		)
	elif "--client3" in args:
		# Upper left corner
		get_window().position = Vector2(
			screen_rect.position.x,
			screen_rect.position.y
		)

	deal_speed_pixels_per_second = screen_size.length() * 5.0
	play_speed_pixels_per_second = deal_speed_pixels_per_second / 5.0
	screen_center = screen_size / 2
	stock_pile_position = screen_center + Vector2(-screen_size.x * 0.05, screen_size.y * 0.1)
	discard_pile_position = screen_center + Vector2(screen_size.x * 0.05, screen_size.y * 0.1)
	player_hand_y_position = screen_size.y * 0.9
	player_hand_x_end = screen_size.x * 0.925

func player_hand_x_start() -> float:
	if game_state.current_round_num <= 3:
		return screen_size.x * MELD_AREA_2_RIGHT_PERCENT + 200 # Start just to the right of meld area 2
	return screen_size.x * MELD_AREA_RIGHT_PERCENT + 200 # Start just to the right of meld area 3

func reset_game():
	dbg("ENTER Global.reset_game_signal")
	game_state = {
		'current_round_num': 1, # 1..7
		# Placing [current_state_name] in the [game_state] causes race conditions
		# in the clients, so do not do this.
		# 'current_state_name': '',
		'current_player_turn_index': 1, # start at player to host's right
		# public_players_info is an ordered array of strictly public player info.
		'public_players_info': [],
		# This keeps track of all player ids that wish to buy the current discard pile top card.
		'current_buy_request_player_ids': {},
	}
	private_player_info = {
		'id': '', # string version of multiplayer peer ID or 'bot#' for bots (run on server)
		'name': '',
		'is_bot': false,
		'turn_index': 0, # fixed per player once game is started
		'played_to_table': [], # ordered collection of Dictionaries of groups or runs with playing card keys
		'score': 0,
		# private fields that are not sent to clients:
		'card_keys_in_hand': [], # unordered collection of _ALL_ playing card keys (even if they are copied into a meld area)
		'meld_area_1_keys': [], # unordered collection of playing card keys in meld area 1
		'meld_area_2_keys': [], # unordered collection of playing card keys in meld area 2
		'meld_area_3_keys': [], # unordered collection of playing card keys in meld area 3
	}
	stock_pile.clear()
	discard_pile.clear()
	playing_cards.clear()
	request_change_round(null) # Remove any RoundNode
	reset_game_signal.emit()
	dbg("LEAVE Global.reset_game_signal")

# Global.is_my_turn() is _NEVER_ true for a bot!
func is_my_turn() -> bool:
	# dbg("Global.is_my_turn: private_player_info=%s, game_state=%s" % [str(private_player_info), str(game_state)])
	return private_player_info.turn_index == game_state.current_player_turn_index

func number_human_players() -> int:
	var count = 0
	for pi in game_state.public_players_info:
		if not pi.is_bot:
			count += 1
	return count

func create_game():
	var current_peer = multiplayer.multiplayer_peer
	# Close existing connection if it exists
	if current_peer:
		if current_peer is ENetMultiplayerPeer:
			current_peer.close()
		multiplayer.multiplayer_peer = null

	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(GAME_PORT, MAX_PLAYERS)
	if err:
		reset_game()
		return err
	multiplayer.multiplayer_peer = peer
	private_player_info['id'] = '1'
	var public_player_info = gen_public_player_info(private_player_info)
	game_state.public_players_info.append(public_player_info)
	player_connected_signal.emit(1, public_player_info)

func gen_public_player_info(private_info: Dictionary) -> Dictionary:
	# Generate a new public player info dictionary for the current player.
	# This is used when a new player connects to the game.
	var num_cards = len(private_info['card_keys_in_hand'])
	var public_player_info = {
		'id': private_info['id'],
		'name': private_info['name'],
		'is_bot': private_info['is_bot'],
		'turn_index': private_info['turn_index'],
		'played_to_table': private_info['played_to_table'],
		'num_cards': num_cards,
		'score': private_info['score'],
	}
	return public_player_info

const BOT_RESOURCE_NAMES = ['01-dumb_bot', '02-stingy_bot', '03-generous_bot', '04-basic_bot']

func add_bot_to_game():
	var turn_index = len(game_state.public_players_info)
	var id = 'bot%d' % len(game_state.public_players_info)
	# Pick a random bot class name from the list of available bot classes.
	var bot_resource_name = BOT_RESOURCE_NAMES[int(randf() * len(BOT_RESOURCE_NAMES))]
	# Instantiate the bot class dynamically.
	var bot_class = load("res://players/%s.gd" % [bot_resource_name])
	if not bot_class:
		error("Could not load bot class: %s" % [bot_resource_name])
		return
	var bot_instance = bot_class.new(id)
	if not bot_instance:
		error("Could not instantiate bot class: %s" % [bot_resource_name])
		return
	var bot_name = bot_instance.get_bot_name()
	var bot_private_player_info = {
		'id': id,
		'name': bot_name,
		'is_bot': true,
		'turn_index': turn_index,
		'played_to_table': [],
		'score': 0,
		'card_keys_in_hand': [],
	}
	bots_private_player_info[id] = bot_private_player_info
	var bot_public_player_info = gen_public_player_info(bot_private_player_info)
	game_state.public_players_info.append(bot_public_player_info)
	# Note that for a bot instance to get all the game engine signals, it must be added
	# to the scene tree. Bots are added as children of the PlayerContainer Player node
	# that represents the bot.
	dbg("Global:add_bot_to_game: %s" % [str(bot_public_player_info)])
	player_connected_signal.emit(id, bot_public_player_info)
	attach_bot_instance_to_player_signal.emit(id, bot_instance)

func join_game(address):
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(address, GAME_PORT)
	if err: return err
	multiplayer.multiplayer_peer = peer

func _on_peer_connected(peer_id):
	if game_has_started:
		# Reject connection if game has already started
		dbg("Global._on_peer_connected: rejecting peer %d because game has started" % peer_id)
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		return
	var public_player_info = gen_public_player_info(private_player_info)
	dbg("Global._on_peer_connected(peer_id=%s): sending my player_info to peer_id: %s" % [str(peer_id), str(public_player_info)])
	_rpc_register_player.rpc_id(peer_id, public_player_info)

@rpc('any_peer', 'reliable')
func _rpc_register_player(new_player_info):
	if is_not_server(): return
	var new_player_id = new_player_info['id']
	dbg("Global._register_player: received new_player_info: %s" % [str(new_player_info)])
	# First check if there are too many players and delete a bot if possible.
	var current_num_players = len(game_state.public_players_info)
	if current_num_players >= MAX_PLAYERS:
		var all_bots = _get_bots()
		if len(all_bots) == 0:
			error("no bots found when current_num_players=%d" % [current_num_players])
			return
		_remove_bot_from_game()
	# Assign all players their proper turn_index values.
	game_state.public_players_info.append(new_player_info)
	for idx in range(len(game_state.public_players_info)):
		game_state.public_players_info[idx]['turn_index'] = idx
	dbg("Global._register_player: now have %d players" % [len(game_state.public_players_info)])
	player_connected_signal.emit(new_player_id, new_player_info)

func _remove_bot_from_game() -> void:
	if is_not_server(): return
	var all_bots = _get_bots()
	var last_bot = all_bots[len(all_bots) - 1]
	_on_peer_disconnected(last_bot.id)
	bots_private_player_info.erase(last_bot.id)

func _get_bots() -> Array:
	return game_state.public_players_info.filter(func(pi): return pi.is_bot)

# func get_winning_player_public_info() -> Dictionary:
# 	var winning_players = game_state.public_players_info.filter(func(pi): return pi['num_cards'] == 0)
# 	if len(winning_players) == 0:
# 		return {}
# 	if len(winning_players) > 1:
# 		error("get_winning_player_public_info: more than one winning player found: %s" % [str(winning_players)])
# 	return winning_players[0]

func _on_peer_disconnected(id):
	var str_id = str(id)
	game_state.public_players_info = game_state.public_players_info.filter(func(pi): return pi.id != str_id)
	#dbg("Global._on_peer_disconnected(id=%s): removed lost player from game_state: %s (now have %d players remaining)" %
		#[str_id, str(matching_players[0]), len(game_state.public_players_info)])
	dbg("Global._on_peer_disconnected(id=%s): removed lost player from game_state (now have %d players remaining)" %
		[str_id, len(game_state.public_players_info)])
	if str_id == '1': # host disconnected. Reset game
		reset_game()
		return
	player_disconnected_signal.emit(str_id)

func _on_connected_to_server():
	var peer_id = str(multiplayer.get_unique_id())
	private_player_info['id'] = peer_id
	var public_player_info = gen_public_player_info(private_player_info)
	game_state.public_players_info.append(public_player_info)
	dbg("Global._on_connected_to_server: got my unique peer_id=%s: %s" % [peer_id, str(public_player_info)])
	player_connected_signal.emit(peer_id, public_player_info)

func _on_connection_failed():
	multiplayer.multiplayer_peer = null

func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	if game_state.has('public_players_info'):
		game_state.public_players_info.clear()
	server_disconnected_signal.emit()

func change_custom_card_back(random_back_svg_name):
	custom_card_back.texture = load("res://svg-card-backs/%s" % [random_back_svg_name])
	custom_card_back_texture_changed_signal.emit()

func send_game_state():
	if is_not_server():
		error("send_game_state called on a client")
		return
	# The following line has a race condition error when sending the game state to
	# a just-disconnected client. Therefore, send the game state individually to
	# known-good peers.
	#receive_game_state.rpc(game_state)
	for pi in game_state.public_players_info:
		if pi.is_bot or pi.id == '1': continue
		_rpc_receive_game_state.rpc_id(int(pi.id), game_state)
	# Also trigger the event on the server to update any children that may be listening.
	game_state_updated_signal.emit()

@rpc('authority', 'call_remote', 'reliable')
func _rpc_receive_game_state(state: Dictionary):
	dbg("Global: received RPC receive_game_state: %s" % [str(state)])
	game_state = state
	dbg("Global: receive_game_state: calling game_state_updated_signal.emit()")
	game_state_updated_signal.emit()

func get_players_by_id() -> Dictionary:
	var players_by_id = {}
	for pi in game_state.public_players_info:
		players_by_id[pi.id] = pi
	return players_by_id

func is_server() -> bool:
	return multiplayer.has_multiplayer_peer() and multiplayer.is_server()

func is_not_server() -> bool: # convenience function
	return not is_server()

func reorder_players(new_order: Array) -> void:
	players_reordered_signal.emit(new_order)

func request_change_round(scene: PackedScene, ack_sync_name: String = '') -> void:
	change_round_signal.emit(scene, ack_sync_name)

################################################################################

func server_advance_to_next_round() -> void:
	if is_not_server(): return
	dbg("Global.server_advance_to_next_round()")
	game_state['current_round_num'] += 1
	game_state['current_player_turn_index'] = game_state['current_round_num'] % len(game_state['public_players_info'])
	game_state['current_buy_request_player_ids'] = {}
	for bot in bots_private_player_info.keys():
		bots_private_player_info[bot]['played_to_table'] = []
		bots_private_player_info[bot]['card_keys_in_hand'] = []
	for idx in range(len(game_state['public_players_info'])):
		game_state['public_players_info'][idx]['num_cards'] = 0
		game_state['public_players_info'][idx]['played_to_table'] = []
	register_ack_sync_state('_rpc_advance_to_next_round', {'next_state': 'StartRoundShuffleState'})
	_rpc_advance_to_next_round.rpc(game_state['current_round_num'])

@rpc('authority', 'call_local', 'reliable')
func _rpc_advance_to_next_round(new_round_num: int) -> void:
	dbg("Global._rpc_advance_to_next_round(new_round_num=%d)" % new_round_num)
	private_player_info['played_to_table'] = []
	private_player_info['card_keys_in_hand'] = []
	private_player_info['meld_area_1_keys'] = []
	private_player_info['meld_area_2_keys'] = []
	private_player_info['meld_area_3_keys'] = []
	var next_round_scene = load("res://rounds/round_%d.tscn" % new_round_num) as PackedScene
	request_change_round(next_round_scene, '_rpc_advance_to_next_round')

################################################################################

func reset_remote_player_game(str_id) -> void:
	game_state.public_players_info = game_state.public_players_info.filter(func(pi): return pi.id != str_id)
	var id = int(str_id)
	_rpc_remote_reset_game.rpc_id(id)
	multiplayer.multiplayer_peer.disconnect_peer(id)

@rpc('authority', 'call_remote', 'reliable')
func _rpc_remote_reset_game():
	reset_game()

func get_total_num_card_decks() -> int:
	var n = len(game_state.public_players_info)
	if n < 3: return 1
	if n < 5: return 2
	if n < 9: return 3
	return 4

const CARDS_PER_DECK = 54 # 13*4=52 + 2 jokers
func get_total_num_cards() -> int:
	return CARDS_PER_DECK * get_total_num_card_decks()

func gen_playing_card_key(rank: String, suit: String, deck: int) -> String:
	return "%s-%s-%d" % [rank, suit, deck]

################################################################################
# Local player card meld area signals:
################################################################################

func emit_card_clicked_signal(playing_card, global_position):
	card_clicked_signal.emit(playing_card, global_position)

func emit_card_drag_started_signal(playing_card, from_position):
	card_drag_started_signal.emit(playing_card, from_position)

func emit_card_moved_signal(playing_card, from_position, global_position):
	card_moved_signal.emit(playing_card, from_position, global_position)

func emit_meld_area_state_changed(is_valid: bool, area_idx: int):
	dbg("GML: emit_meld_area_state_changed: is_valid=%s, area_idx=%d" % [str(is_valid), area_idx])
	meld_area_state_changed.emit(is_valid, area_idx)

func emit_meld_areas_states() -> void:
	if player_has_melded(private_player_info['id']):
		emit_meld_areas_states_post_meld()
		return
	emit_meld_areas_states_pre_meld()

func emit_meld_areas_states_pre_meld() -> void:
	var meld_area_1_keys = private_player_info['meld_area_1_keys']
	var meld_area_2_keys = private_player_info['meld_area_2_keys']
	var meld_area_3_keys = private_player_info['meld_area_3_keys']
	match game_state.current_round_num:
		1:
			emit_meld_area_state_changed(is_valid_group(meld_area_1_keys), 0)
			emit_meld_area_state_changed(is_valid_group(meld_area_2_keys), 1)
		2:
			emit_meld_area_state_changed(is_valid_group(meld_area_1_keys), 0)
			emit_meld_area_state_changed(is_valid_run(meld_area_2_keys), 1)
		3:
			emit_meld_area_state_changed(is_valid_run(meld_area_1_keys), 0)
			emit_meld_area_state_changed(is_valid_run(meld_area_2_keys), 1)
		4:
			emit_meld_area_state_changed(is_valid_group(meld_area_1_keys), 0)
			emit_meld_area_state_changed(is_valid_group(meld_area_2_keys), 1)
			emit_meld_area_state_changed(is_valid_group(meld_area_3_keys), 2)
		5:
			emit_meld_area_state_changed(is_valid_group(meld_area_1_keys), 0)
			emit_meld_area_state_changed(is_valid_group(meld_area_2_keys), 1)
			emit_meld_area_state_changed(is_valid_run(meld_area_3_keys), 2)
		6:
			emit_meld_area_state_changed(is_valid_group(meld_area_1_keys), 0)
			emit_meld_area_state_changed(is_valid_run(meld_area_2_keys), 1)
			emit_meld_area_state_changed(is_valid_run(meld_area_3_keys), 2)
		7:
			emit_meld_area_state_changed(is_valid_run(meld_area_1_keys), 0)
			emit_meld_area_state_changed(is_valid_run(meld_area_2_keys), 1)
			emit_meld_area_state_changed(is_valid_run(meld_area_3_keys), 2)

func emit_meld_areas_states_post_meld() -> void:
	var meld_area_1_keys = private_player_info['meld_area_1_keys']
	var meld_area_2_keys = private_player_info['meld_area_2_keys']
	var meld_area_3_keys = private_player_info['meld_area_3_keys']
	var round_num = game_state.current_round_num
	match round_num:
		1:
			var all_public_group_ranks = gen_all_public_group_ranks()
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_group(meld_area_1_keys, all_public_group_ranks), 0)
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_group(meld_area_2_keys, all_public_group_ranks), 1)
		2:
			var all_public_group_ranks = gen_all_public_group_ranks()
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_group(meld_area_1_keys, all_public_group_ranks), 0)
			var all_public_run_suits = gen_all_public_run_suits()
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_run(meld_area_2_keys, all_public_run_suits), 1)
		3:
			var all_public_run_suits = gen_all_public_run_suits()
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_run(meld_area_1_keys, all_public_run_suits), 0)
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_run(meld_area_2_keys, all_public_run_suits), 1)
		4:
			var all_public_group_ranks = gen_all_public_group_ranks()
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_group(meld_area_1_keys, all_public_group_ranks), 0)
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_group(meld_area_2_keys, all_public_group_ranks), 1)
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_group(meld_area_3_keys, all_public_group_ranks), 2)
		5:
			var all_public_group_ranks = gen_all_public_group_ranks()
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_group(meld_area_1_keys, all_public_group_ranks), 0)
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_group(meld_area_2_keys, all_public_group_ranks), 1)
			var all_public_run_suits = gen_all_public_run_suits()
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_run(meld_area_3_keys, all_public_run_suits), 2)
		6:
			var all_public_group_ranks = gen_all_public_group_ranks()
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_group(meld_area_1_keys, all_public_group_ranks), 0)
			var all_public_run_suits = gen_all_public_run_suits()
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_run(meld_area_2_keys, all_public_run_suits), 1)
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_run(meld_area_3_keys, all_public_run_suits), 2)
		7:
			var all_public_run_suits = gen_all_public_run_suits()
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_run(meld_area_1_keys, all_public_run_suits), 0)
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_run(meld_area_2_keys, all_public_run_suits), 1)
			emit_meld_area_state_changed(all_keys_can_publicly_meld_to_some_run(meld_area_3_keys, all_public_run_suits), 2)

func all_keys_can_publicly_meld_to_some_group(card_keys: Array, all_public_group_ranks: Dictionary) -> bool:
	return card_keys.all(func(card_key):
		var parts = card_key.split('-')
		var rank = parts[0]
		if rank == 'JOKER':
			return true
		return all_public_group_ranks.has(rank)
	)

func all_keys_can_publicly_meld_to_some_run(card_keys: Array, all_public_run_suits: Dictionary) -> bool:
	return card_keys.all(func(card_key):
		var parts = card_key.split('-')
		var rank = parts[0]
		if rank == 'JOKER':
			return true
		var suit = parts[1]
		var all_runs_by_suit = all_public_run_suits.get(suit, [])
		return all_runs_by_suit.any(func(run_card_keys):
			var new_run_card_keys = run_card_keys.duplicate()
			new_run_card_keys.append(card_key)
			return is_valid_run(new_run_card_keys)
		)
	)

# Dictionary of 'rank': true for fast lookup
func gen_all_public_group_ranks() -> Dictionary:
	var ranks = {}
	for pi in game_state.public_players_info:
		if not pi.has('played_to_table'): continue
		for meld in pi.played_to_table:
			if meld.type != 'group': continue
			for card_key in meld.cards_keys:
				var parts = card_key.split('-')
				var rank = parts[0]
				if rank == 'JOKER': continue
				ranks[rank] = true
	return ranks

# Dictionary of 'suit': [[run_card_keys]] for fast lookup
func gen_all_public_run_suits() -> Dictionary:
	var suits = {}
	for pi in game_state.public_players_info:
		if not pi.has('played_to_table'): continue
		for meld in pi.played_to_table:
			if meld.type != 'run': continue
			var run_suit = get_run_suit(meld.cards_keys)
			if run_suit == '': continue
			if not suits.has(run_suit):
				suits[run_suit] = []
			suits[run_suit].append(meld.cards_keys.duplicate())
	return suits

func get_run_suit(card_keys: Array) -> String:
	for card_key in card_keys:
		var parts = card_key.split('-')
		var rank = parts[0]
		if rank != 'JOKER':
			return parts[1]
	return '' # all jokers?

################################################################################
## Game play, stats, and hand evaluation functions
################################################################################

func card_key_score(card_key: String) -> int:
	var parts = card_key.split('-')
	var rank = parts[0]
	if rank == 'JOKER':
		return 15
	elif rank == 'A':
		return 15
	elif rank == 'K':
		return 10
	elif rank == 'Q':
		return 10
	elif rank == 'J':
		return 10
	elif rank == '10':
		return 10
	else:
		return 5 # All other cards are worth 5 points

func sort_card_keys_by_score(card_keys: Array) -> Array:
	var sorted_keys = card_keys.duplicate()
	sorted_keys.sort_custom(func(a, b):
		var score_a = card_key_score(a)
		var score_b = card_key_score(b)
		if score_a == score_b: return a < b # If scores are equal, sort by card key
		return score_a > score_b # Sort by score descending, so higher scores come first
	)
	return sorted_keys

func tally_hand_cards_score(card_keys_in_hand: Array) -> int:
	# Tally the score of the hand based on the card keys in hand.
	var score = 0
	for card_key in card_keys_in_hand:
		score += card_key_score(card_key)
	return score

func player_has_melded(player_id: String) -> bool:
	# Check if the player has melded any cards.
	var public_player_info = game_state.public_players_info.filter(func(pi): return pi.id == player_id)
	if len(public_player_info) != 1:
		error("player_has_melded: could not find player_id='%s' in game_state" % [player_id])
		return false
	var played_to_table = public_player_info[0].played_to_table
	return len(played_to_table) > 0

# func get_public_meld_card_keys_dict(player_id: String) -> Dictionary:
# 	var card_keys = {}
# 	var public_player_info = game_state.public_players_info.filter(func(pi): return pi.id == player_id)
# 	if len(public_player_info) != 1:
# 		error("get_public_meld_card_keys_dict: could not find player_id='%s' in game_state" % [player_id])
# 		return card_keys
# 	var played_to_table = public_player_info[0].played_to_table
# 	for meld_idx in range(len(played_to_table)):
# 		var meld = played_to_table[meld_idx]
# 		for card_key in meld:
# 			card_keys[card_key] = {
# 				'meld_group_index': meld_idx, # index of the meld group this card belongs to
# 			}
# 	return card_keys

# func get_all_public_meld_card_keys_dict() -> Dictionary:
# 	var all_card_keys = {} # maps card_key to player_id and meld_group_index
# 	for pi in game_state.public_players_info:
# 		var players_public_meld_card_keys_dict = get_public_meld_card_keys_dict(pi.id)
# 		for card_key in players_public_meld_card_keys_dict.keys():
# 			var meld_group_index = players_public_meld_card_keys_dict[card_key]['meld_group_index']
# 			all_card_keys[card_key] = {
# 				'player_id': pi.id, # the player who played this card
# 				'meld_group_index': meld_group_index, # index of the meld group this card belongs to
# 			}
# 	return all_card_keys

# add_card_to_stats generates stats both for cards in-hand and also for cards played to the table.
# If player_id is provided, Dictionary objects are created instead of just the card_key.
func add_card_to_stats(acc: Dictionary, card_key: String, player_id: String = '', meld_group_index: int = 0, meld_group_type: String = '') -> Dictionary:
	var parts = card_key.split('-')
	var rank = parts[0]
	if rank == 'JOKER':
		if player_id != '':
			acc['jokers'].append({
				'card_key': card_key,
				'player_id': player_id,
				'meld_group_index': meld_group_index,
				'meld_group_type': meld_group_type,
			})
		else:
			acc['jokers'].append(card_key)
		return acc # JOKERs are not added to 'by_rank' or 'by_suit'.
	var suit = parts[1]

	if not rank in acc['by_rank']:
		acc['by_rank'][rank] = []

	if player_id != '':
		acc['by_rank'][rank].append({
			'card_key': card_key,
			'player_id': player_id,
			'meld_group_index': meld_group_index,
			'meld_group_type': meld_group_type,
		})
	else:
		acc['by_rank'][rank].append(card_key)

	if not suit in acc['by_suit']:
		acc['by_suit'][suit] = {}
	if not rank in acc['by_suit'][suit]:
		acc['by_suit'][suit][rank] = []

	if player_id != '':
		acc['by_suit'][suit][rank].append({
			'card_key': card_key,
			'player_id': player_id,
			'meld_group_index': meld_group_index,
			'meld_group_type': meld_group_type,
		})
	else:
		acc['by_suit'][suit][rank].append(card_key)
	return acc

func empty_evaluation() -> Dictionary:
	return {
		'eval_score': 0, # relative score of the hand, higher is better
		# 'need_ranks': {}, # 'A': 1, 'K': 3, etc.
		# 'need_suits': {}, # '2-hearts': 2, '3-diamonds': 1, etc.
		'is_winning_hand': false,
		'can_be_personally_melded': [], # Dicts with 'type' ('group' or 'run') and 'card_keys' of cards that can be melded onto this player's public meld
		'can_be_publicly_melded': [], # cards that can be individually melded onto other public melds
		'recommended_discards': [], # card keys to discard, if any, sorted by their score (higher score first)
	}

# Value lookup for run validation
var _value_lookup = {
	'JOKER': 15, 'A': 14, 'J': 11, 'Q': 12, 'K': 13,
	'2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9, '10': 10
}

func is_valid_run(card_keys: Array) -> bool:
	# Runs must have at least 4 cards
	if len(card_keys) < 4:
		return false

	# Separate jokers from regular cards
	var regular_cards = []
	var num_jokers = 0
	var has_ace = false

	for card_key in card_keys:
		var parts = card_key.split('-')
		var rank = parts[0]
		if rank == 'JOKER':
			num_jokers += 1
		else:
			var value = _value_lookup[rank]
			if value == 14: # Ace
				has_ace = true
			regular_cards.append(value)

	# Calculate gaps
	var min_gaps = 999
	if has_ace:
		# Try ace as low (1)
		var cards_low = regular_cards.duplicate()
		for i in range(len(cards_low)):
			if cards_low[i] == 14:
				cards_low[i] = 1
		cards_low.sort()
		var gaps_low = 0
		for i in range(1, len(cards_low)):
			var diff = cards_low[i] - cards_low[i - 1] - 1
			if diff > 0:
				gaps_low += diff
		min_gaps = gaps_low

		# Try ace as high (14)
		var cards_high = regular_cards.duplicate()
		for i in range(len(cards_high)):
			if cards_high[i] == 14:
				cards_high[i] = 14
		cards_high.sort()
		var gaps_high = 0
		for i in range(1, len(cards_high)):
			var diff = cards_high[i] - cards_high[i - 1] - 1
			if diff > 0:
				gaps_high += diff
		if gaps_high < min_gaps:
			min_gaps = gaps_high
	else:
		# No ace, just calculate gaps
		regular_cards.sort()
		var gaps = 0
		for i in range(1, len(regular_cards)):
			var diff = regular_cards[i] - regular_cards[i - 1] - 1
			if diff > 0:
				gaps += diff
		min_gaps = gaps

	# Check if we have enough jokers to fill the gaps
	return num_jokers >= min_gaps

func is_valid_group(card_keys: Array) -> bool:
	if len(card_keys) < 3:
		return false

	var ranks = {}
	for card_key in card_keys:
		var parts = card_key.split('-')
		var rank = parts[0]
		dbg("is_valid_group: card_key=%s, rank=%s" % [card_key, rank])
		if rank == 'JOKER':
			continue
		ranks[rank] = true

	return len(ranks) <= 1 # all-jokers is a valid group

# A perfect winning hand, performed after drawing a card, is a hand that can be melded to win the round.
# (Rounds 1-6 required a discard, and round 7 requires no discard.)

################################################################################
## Player actions
################################################################################

func validate_current_player_turn(player_id: String):
	var player_infos = game_state.public_players_info.filter(func(pi): return pi.id == player_id)
	if len(player_infos) != 1:
		error("validate_current_player_turn: could not find player_id='%s' in game_state" % [player_id])
		return null
	var player_info = player_infos[0]
	if player_info.turn_index != game_state.current_player_turn_index:
		# error("validate_current_player_turn: player_id='%s' is not the current player (turn_index=%d)" %
		# 	[player_id, game_state.current_player_turn_index])
		return null
	return player_info

################################################################################

func allow_outstanding_buy_request(player_id: String) -> void:
	dbg("allow_outstanding_buy_request(player_id='%s')" % [player_id])
	if is_server(): server_allow_outstanding_buy_request(player_id)
	else: _rpc_request_server_allow_outstanding_buy_request.rpc_id(1, player_id)

@rpc('any_peer', 'call_remote', 'reliable')
func _rpc_request_server_allow_outstanding_buy_request(player_id: String) -> void:
	server_allow_outstanding_buy_request(player_id)

func server_allow_outstanding_buy_request(player_id: String) -> void:
	if is_not_server():
		error("server_allow_outstanding_buy_request: called on non-server peer")
		return
	var player_info = validate_current_player_turn(player_id)
	if not player_info:
		error("server_allow_outstanding_buy_request: player_id='%s' is not the current player" %
			[player_id])
		return
	if len(game_state.current_buy_request_player_ids) == 0: return
	dbg("server_allow_outstanding_buy_request: player_id='%s' is allowing a buy from discard pile" % [player_id])
	for idx in range(len(game_state.public_players_info)):
		var turn_index = (player_info.turn_index + idx) % len(game_state.public_players_info)
		var pi = game_state.public_players_info[turn_index]
		if pi.id in game_state.current_buy_request_player_ids:
			dbg("server_allow_outstanding_buy_request: player_id='%s' allowing buy request from player_id='%s'" %
				[player_id, pi.id])
			allow_player_to_buy_card_from_discard_pile(pi.id)
			break

################################################################################

func discard_card(player_id: String, card_key: String, player_won: bool) -> void:
	dbg("discard_card(player_id='%s', card_key='%s', player_won=%s)" % [player_id, card_key, player_won])
	if is_server(): server_discard_card(player_id, card_key, player_won)
	else: _rpc_request_server_discard_card.rpc_id(1, player_id, card_key, player_won)

@rpc('any_peer', 'call_remote', 'reliable')
func _rpc_request_server_discard_card(player_id: String, card_key: String, player_won: bool) -> void:
	server_discard_card(player_id, card_key, player_won)

func server_discard_card(player_id: String, card_key: String, player_won: bool) -> void:
	if is_not_server():
		error("server_discard_card: called on non-server peer")
		return
	var player_info = validate_current_player_turn(player_id)
	if not player_info:
		error("server_discard_card: player_id='%s' is not the current player" % [player_id])
		return
	dbg("server_discard_card: player_id='%s' discarding card_key='%s', player_won=%s" % [player_id, card_key, player_won])
	var sync_args = {
		'next_state': 'NewDiscardState',
		'advance_player_turn': true,
	} if not player_won else {
		'next_state': 'PlayerWonRoundState',
	}
	if card_key != '':
		register_ack_sync_state('_rpc_move_player_card_to_discard_pile', sync_args)
		_rpc_move_player_card_to_discard_pile.rpc(player_id, card_key, player_won)
	else:
		transition_all_clients_state_to_signal.emit('PlayerWonRoundState')

################################################################################

func draw_card_from_discard_pile(player_id: String) -> void:
	dbg("draw_card_from_discard_pile(player_id='%s')" % [player_id])
	if is_server(): server_draw_card_from_discard_pile(player_id)
	else: _rpc_request_server_draw_card_from_discard_pile.rpc_id(1, player_id)

@rpc('any_peer', 'call_remote', 'reliable')
func _rpc_request_server_draw_card_from_discard_pile(player_id: String) -> void:
	server_draw_card_from_discard_pile(player_id)

func server_draw_card_from_discard_pile(player_id: String) -> void:
	if is_not_server():
		error("server_draw_card_from_discard_pile: called on non-server peer")
		return
	server_check_if_stock_pile_empty_and_reshuffle()
	var player_info = validate_current_player_turn(player_id)
	if not player_info:
		error("server_draw_card_from_discard_pile: player_id='%s' is not the current player" % [player_id])
		return
	dbg("server_draw_card_from_discard_pile: player_id='%s' drawing card from discard pile" % [player_id])
	register_ack_sync_state('_rpc_give_top_discard_pile_card_to_player', {'next_state': 'PlayerDrewState'})
	_rpc_give_top_discard_pile_card_to_player.rpc(player_id)

################################################################################

func draw_card_from_stock_pile(player_id: String) -> void:
	dbg("draw_card_from_stock_pile(player_id='%s')" % [player_id])
	if is_server(): server_draw_card_from_stock_pile(player_id)
	else: _rpc_request_server_draw_card_from_stock_pile.rpc_id(1, player_id)

@rpc('any_peer', 'call_remote', 'reliable')
func _rpc_request_server_draw_card_from_stock_pile(player_id: String) -> void:
	server_draw_card_from_stock_pile(player_id)

func server_draw_card_from_stock_pile(player_id: String) -> void:
	if is_not_server():
		error("server_draw_card_from_stock_pile: called on non-server peer")
		return
	var player_info = validate_current_player_turn(player_id)
	if not player_info:
		error("server_draw_card_from_stock_pile: player_id='%s' is not the current player" % [player_id])
		return
	if has_outstanding_buy_request():
		allow_outstanding_buy_request(player_id)
		# NOTE that allowing an outstanding request means that the draw_card_from_stock_pile
		# request is not valid, so return here.
		return
	dbg("server_draw_card_from_stock_pile: player_id='%s' drawing card from stock pile" % [player_id])
	register_ack_sync_state('_rpc_give_top_stock_pile_card_to_player', {'next_state': 'PlayerDrewState'})
	_rpc_give_top_stock_pile_card_to_player.rpc(player_id)

################################################################################

func has_outstanding_buy_request() -> bool:
	return len(game_state.current_buy_request_player_ids) > 0

################################################################################

func request_to_buy_card_from_discard_pile(player_id: String) -> void:
	dbg("request_to_buy_card_from_discard_pile(player_id='%s')" % [player_id])
	if is_server(): server_request_to_buy_card_from_discard_pile(player_id)
	else: _rpc_request_server_request_to_buy_card_from_discard_pile.rpc_id(1, player_id)

@rpc('any_peer', 'call_remote', 'reliable')
func _rpc_request_server_request_to_buy_card_from_discard_pile(player_id: String) -> void:
	server_request_to_buy_card_from_discard_pile(player_id)

func server_request_to_buy_card_from_discard_pile(player_id: String) -> void:
	if is_not_server():
		error("server_request_to_buy_card_from_discard_pile: called on non-server peer")
		return
	var player_info = validate_current_player_turn(player_id)
	if player_info:
		error("server_request_to_buy_card_from_discard_pile: player_id='%s' IS the current player" % [player_id])
		return
	if len(discard_pile) == 0:
		error("server_request_to_buy_card_from_discard_pile: discard pile is empty")
		return
	var top_card = discard_pile[0] as PlayingCard
	dbg("server_request_to_buy_card_from_discard_pile: player_id='%s' requesting to buy card '%s' from discard pile" % [player_id, top_card.key])
	_rpc_show_player_requests_to_buy_card.rpc(player_id, top_card.key)

################################################################################

@rpc('authority', 'call_local', 'reliable')
func _rpc_give_top_discard_pile_card_to_player(player_id: String) -> void:
	dbg("received RPC _rpc_give_top_discard_pile_card_to_player: player_id='%s'" % [player_id])
	game_state.current_buy_request_player_ids = {} # clear all buy requests
	game_state_updated_signal.emit()
	if len(discard_pile) == 0:
		error("_rpc_give_top_discard_pile_card_to_player: discard pile is empty")
		return
	var top_card = discard_pile.pop_front() as PlayingCard
	var player_is_me = private_player_info.id == player_id
	# This top card from the discard pile is now only tappable and draggable by the player who drew it.
	top_card.is_tappable = player_is_me
	top_card.is_draggable = player_is_me
	# Make the new top of the discard pile tappable only.
	if len(discard_pile) > 0:
		var new_top_card = discard_pile[0] as PlayingCard
		new_top_card.is_tappable = true
		new_top_card.is_draggable = false
	if player_is_me:
		private_player_info.card_keys_in_hand.append(top_card.key)
	elif is_server():
		if player_id in bots_private_player_info:
			var bot = bots_private_player_info[player_id]
			bot.card_keys_in_hand.append(top_card.key)
	dbg("_rpc_give_top_discard_pile_card_to_player: player_id='%s' receiving top card from discard pile: %s" % [player_id, top_card.key])
	dbg("_rpc_give_top_discard_pile_card_to_player: private_player_info.card_keys_in_hand (ME): %s" % [str(private_player_info.card_keys_in_hand)])
	dbg("_rpc_give_top_discard_pile_card_to_player: game_state.public_players_info (AFTER RPC): %s" % [str(game_state.public_players_info.filter(func(pi): return pi.id == player_id)[0])])
	animate_move_card_to_player_signal.emit(top_card, player_id, '_rpc_give_top_discard_pile_card_to_player')

@rpc('authority', 'call_local', 'reliable')
func _rpc_give_top_stock_pile_card_to_player(player_id: String) -> void:
	dbg("received RPC _rpc_give_top_stock_pile_card_to_player: player_id='%s'" % [player_id])
	game_state.current_buy_request_player_ids = {} # clear all buy requests
	game_state_updated_signal.emit()
	if len(stock_pile) == 0:
		error("_rpc_give_top_stock_pile_card_to_player: stock pile is empty")
		return
	var top_card = stock_pile.pop_front() as PlayingCard
	var player_is_me = private_player_info.id == player_id
	# This top card from the stock pile is now only tappable and draggable by the player who drew it.
	top_card.is_tappable = player_is_me
	top_card.is_draggable = player_is_me
	# Make the new top of the stock pile tappable only.
	if len(stock_pile) > 0:
		var new_top_card = stock_pile[0] as PlayingCard
		new_top_card.is_tappable = true
		new_top_card.is_draggable = false
	if player_is_me:
		private_player_info.card_keys_in_hand.append(top_card.key)
	elif is_server():
		if player_id in bots_private_player_info:
			var bot = bots_private_player_info[player_id]
			bot.card_keys_in_hand.append(top_card.key)
	dbg("_rpc_give_top_stock_pile_card_to_player: player_id='%s' receiving top card from stock pile: %s" %
		[player_id, top_card.key])
	dbg("_rpc_give_top_stock_pile_card_to_player: private_player_info.card_keys_in_hand (ME): %s" % [str(private_player_info.card_keys_in_hand)])
	dbg("_rpc_give_top_stock_pile_card_to_player: game_state.public_players_info (AFTER RPC): %s" % [str(self.game_state.public_players_info.filter(func(pi): return pi.id == player_id)[0])])
	animate_move_card_to_player_signal.emit(top_card, player_id, '_rpc_give_top_stock_pile_card_to_player')

@rpc('authority', 'call_local', 'reliable')
func _rpc_move_player_card_to_discard_pile(player_id: String, card_key: String, player_won: bool) -> void:
	dbg("received RPC _rpc_move_player_card_to_discard_pile: player_id='%s', card_key='%s', player_won=%s" % [player_id, card_key, player_won])
	var top_card = playing_cards.get(card_key) as PlayingCard
	if not top_card:
		error("_rpc_move_player_card_to_discard_pile: unable to find card_key='%s' in playing_cards" % [card_key])
		return
	discard_pile.push_front(top_card)
	var player_is_me = private_player_info.id == player_id
	top_card.is_tappable = true
	top_card.is_draggable = false # player_is_me
	if player_is_me:
		private_player_info.card_keys_in_hand.erase(top_card.key)
		private_player_info.meld_area_1_keys.erase(top_card.key)
		private_player_info.meld_area_2_keys.erase(top_card.key)
		private_player_info.meld_area_3_keys.erase(top_card.key)
	elif is_server():
		if player_id in bots_private_player_info:
			var bot = bots_private_player_info[player_id]
			bot.card_keys_in_hand.erase(top_card.key)
	dbg("_rpc_move_player_card_to_discard_pile: player_id='%s' moving card from discard pile: '%s', player_won=%s" % [player_id, top_card.key, player_won])
	animate_move_card_from_player_to_discard_pile_signal.emit(top_card, player_id, player_won, '_rpc_move_player_card_to_discard_pile')

func allow_player_to_buy_card_from_discard_pile(buying_player_id: String) -> void:
	if is_not_server():
		error("allow_player_to_buy_card_from_discard_pile called on a client")
		return
	dbg("allow_player_to_buy_card_from_discard_pile: buying_player_id='%s'" % [buying_player_id])
	game_state.current_buy_request_player_ids = {} # clear all buy requests
	game_state_updated_signal.emit()
	register_ack_sync_state('_rpc_give_top_discard_pile_card_to_player', {'emit': 'deal_penalty_card_to_player', 'player_id': buying_player_id}) # not really an emit.
	_rpc_give_top_discard_pile_card_to_player.rpc(buying_player_id) # Do NOT advance to a new state.

func deal_penalty_card_to_player(buying_player_id: String) -> void:
	if is_not_server():
		error("deal_penalty_card_to_player called on a client")
		return
	register_ack_sync_state('_rpc_give_top_stock_pile_card_to_player', {'emit': 'new_card_exposed_on_discard_pile_signal'})
	_rpc_give_top_stock_pile_card_to_player.rpc(buying_player_id)

@rpc('authority', 'call_local', 'reliable')
func _rpc_show_player_requests_to_buy_card(player_id: String, card_key: String) -> void:
	dbg("received RPC _rpc_show_player_requests_to_buy_card: player_id='%s'" % [player_id])
	game_state.current_buy_request_player_ids[player_id] = card_key
	game_state_updated_signal.emit()

################################################################################

func personally_meld_hand(player_id: String, hand_evaluation: Dictionary) -> void:
	dbg("personally_meld_hand(player_id='%s', hand_evaluation=%s)" % [player_id, str(hand_evaluation)])
	if is_server(): server_personally_meld_hand(player_id, hand_evaluation)
	else: _rpc_request_server_personally_meld_hand.rpc_id(1, player_id, hand_evaluation)

@rpc('any_peer', 'call_remote', 'reliable')
func _rpc_request_server_personally_meld_hand(player_id: String, hand_evaluation: Dictionary) -> void:
	server_personally_meld_hand(player_id, hand_evaluation)

func server_personally_meld_hand(player_id: String, hand_evaluation: Dictionary) -> void:
	if is_not_server():
		error("server_personally_meld_hand: called on non-server peer")
		return
	var player_info = validate_current_player_turn(player_id)
	if not player_info:
		error("server_personally_meld_hand: player_id='%s' is not the current player" % [player_id])
		return
	dbg("server_personally_meld_hand: player_id='%s' hand_evaluation=%s" % [player_id, hand_evaluation])
	var turn_index = player_info['turn_index']

	# Sort cards within runs for proper display order
	var sorted_melds = []
	for meld in hand_evaluation['can_be_personally_melded']:
		var sorted_meld = meld.duplicate()
		if meld['type'] == 'run':
			sorted_meld['card_keys'] = sort_run_cards(meld['card_keys'])
		sorted_melds.append(sorted_meld)

	game_state.public_players_info[turn_index]['played_to_table'].append_array(sorted_melds)
	# Update hand_evaluation with sorted melds for RPC
	var sorted_hand_evaluation = hand_evaluation.duplicate(true)
	sorted_hand_evaluation['can_be_personally_melded'] = sorted_melds
	register_ack_sync_state('_rpc_personally_meld_cards_only') # stay within same state, {'next_state': 'NewDiscardState'})
	_rpc_personally_meld_cards_only.rpc(player_id, sorted_hand_evaluation)

@rpc('authority', 'call_local', 'reliable')
func _rpc_personally_meld_cards_only(player_id: String, hand_evaluation: Dictionary) -> void:
	dbg("received RPC _rpc_personally_meld_cards_only: player_id='%s'" % [player_id])
	# Move the playable cards from the player's hand to the table and then perform the animations.
	for meld_group in hand_evaluation['can_be_personally_melded']:
		_personally_meld_group_update_private_player_info(meld_group, player_id)
	animate_personally_meld_cards_only_signal.emit(player_id, hand_evaluation, '_rpc_personally_meld_cards_only')

func _remove_card_from_player_hand(card_key: String, player_id: String) -> void:
	dbg("_remove_card_from_player_hand: player_id='%s', card_key='%s'" % [player_id, card_key])
	var player_is_me = private_player_info.id == player_id
	if player_is_me:
		private_player_info.card_keys_in_hand.erase(card_key)
		private_player_info.meld_area_1_keys.erase(card_key)
		private_player_info.meld_area_2_keys.erase(card_key)
		private_player_info.meld_area_3_keys.erase(card_key)
		dbg("_remove_card_from_player_hand: private_player_info.card_keys_in_hand (ME): %s" % [str(private_player_info.card_keys_in_hand)])
	elif is_server():
		if player_id in bots_private_player_info:
			var bot = bots_private_player_info[player_id]
			bot.card_keys_in_hand.erase(card_key)
			dbg("_remove_card_from_player_hand: bots_private_player_info[player_id].card_keys_in_hand (BOT): %s" % [str(bot.card_keys_in_hand)])

func _personally_meld_group_update_private_player_info(meld_group: Dictionary, player_id: String) -> void:
	dbg("_personally_meld_group_update_private_player_info: meld_group=%s, player_id='%s'" % [str(meld_group), player_id])
	var player_is_me = private_player_info.id == player_id
	if player_is_me:
		private_player_info.played_to_table.append(meld_group)
		dbg("_personally_meld_group_update_private_player_info: private_player_info.played_to_table (ME): %s" % [str(private_player_info.played_to_table)])
	elif is_server():
		if player_id in bots_private_player_info:
			var bot = bots_private_player_info[player_id]
			bot.played_to_table.append(meld_group)
			dbg("_personally_meld_group_update_private_player_info: bots_private_player_info[player_id].played_to_table (BOT): %s" % [str(bot.played_to_table)])
	for card_key in meld_group['card_keys']:
		_remove_card_from_player_hand(card_key, player_id)

################################################################################

func meld_card_to_public_meld(player_id: String, card_key: String, target_player_id: String, meld_group_index: int) -> void:
	dbg("meld_card_to_public_meld(player_id='%s', card_key='%s', target_player_id='%s', meld_group_index=%d)" %
		[player_id, card_key, target_player_id, meld_group_index])
	if is_server(): server_meld_card_to_public_meld(player_id, card_key, target_player_id, meld_group_index)
	else: _rpc_request_server_meld_card_to_public_meld.rpc_id(1, player_id, card_key, target_player_id, meld_group_index)

@rpc('any_peer', 'call_remote', 'reliable')
func _rpc_request_server_meld_card_to_public_meld(player_id: String, card_key: String, target_player_id: String, meld_group_index: int) -> void:
	server_meld_card_to_public_meld(player_id, card_key, target_player_id, meld_group_index)

func server_meld_card_to_public_meld(player_id: String, card_key: String, target_player_id: String, meld_group_index: int) -> void:
	if is_not_server():
		error("server_meld_card_to_public_meld: called on non-server peer")
		return
	var player_info = validate_current_player_turn(player_id)
	if not player_info:
		error("server_meld_card_to_public_meld: player_id='%s' is not the current player" % [player_id])
		return
	dbg("server_meld_card_to_public_meld: player_id='%s', card_key='%s', target_player_id='%s', meld_group_index=%d" %
		[player_id, card_key, target_player_id, meld_group_index])
	register_ack_sync_state('_rpc_publicly_meld_card_only')
	_rpc_publicly_meld_card_only.rpc(player_id, card_key, target_player_id, meld_group_index)

@rpc('authority', 'call_local', 'reliable')
func _rpc_publicly_meld_card_only(player_id: String, card_key: String, target_player_id: String, meld_group_index: int) -> void:
	dbg("received RPC _rpc_publicly_meld_card_only: player_id='%s', card_key='%s', target_player_id='%s', meld_group_index=%d" %
		[player_id, card_key, target_player_id, meld_group_index])
	# Move the playable card from the player's hand to the table and then perform the animations.
	_publicly_meld_card(player_id, card_key, target_player_id, meld_group_index)
	animate_publicly_meld_card_only_signal.emit(player_id, card_key, target_player_id, meld_group_index, '_rpc_publicly_meld_card_only')

func _publicly_meld_card(_player_id: String, card_key: String, target_player_id: String, meld_group_index: int) -> void:
	_remove_card_from_player_hand(card_key, _player_id)
	dbg("_publicly_meld_card: player_id='%s', card_key='%s', target_player_id='%s', meld_group_index=%d" %
		[_player_id, card_key, target_player_id, meld_group_index])
	var target_player_is_me = private_player_info.id == target_player_id
	if target_player_is_me:
		private_player_info.played_to_table[meld_group_index]['card_keys'].append(card_key)
		dbg("_publicly_meld_card: private_player_info.played_to_table (ME): %s" % [str(private_player_info.played_to_table)])
	elif is_server():
		if target_player_id in bots_private_player_info:
			var bot = bots_private_player_info[target_player_id]
			bot.played_to_table[meld_group_index]['card_keys'].append(card_key)
			dbg("_publicly_meld_card: bots_private_player_info[player_id].played_to_table (BOT): %s" % [str(bot.played_to_table)])

################################################################################
## MULTIPLAYER SYNCHRONIZATION
################################################################################

# Dictionary to track sync state for each operation which is only used
# by the server.
var ack_sync_state = {}

func ack_sync_completed(operation_name: String) -> void:
	dbg("SYNC: ack_sync_completed(operation_name='%s')" % [operation_name])
	if is_server(): server_ack_sync_completed(1, operation_name)
	else: _rpc_request_server_ack_sync_completed.rpc_id(1, operation_name)

@rpc('any_peer', 'call_remote', 'reliable')
func _rpc_request_server_ack_sync_completed(operation_name: String) -> void:
	var peer_id = multiplayer.get_remote_sender_id()
	server_ack_sync_completed(peer_id, operation_name)

func server_ack_sync_completed(peer_id: int, operation_name: String) -> void:
	if is_not_server():
		error("SYNC: server_ack_sync_completed(peer_id=%d, operation_name='%s'): called on non-server peer" %
			[peer_id, operation_name])
		return
	if not operation_name in ack_sync_state:
		ack_sync_state[operation_name] = {'acks': {}}
	elif not 'acks' in ack_sync_state[operation_name]:
		ack_sync_state[operation_name]['acks'] = {}

	ack_sync_state[operation_name]['acks'][peer_id] = true
	var num_players = len(multiplayer.get_peers()) + 1 # Does not count the server!
	var num_acks = len(ack_sync_state[operation_name]['acks'])
	if num_acks < num_players:
		dbg("SYNC: server_ack_sync_completed(peer_id=%d, operation_name='%s'): waiting for %d more peers to ack sync: %s" %
			[peer_id, operation_name, num_players - num_acks, str(ack_sync_state)])
		return
	# dbg("SYNC: server_ack_sync_completed(peer_id=%d, operation_name='%s'): COMPLETED! ack_sync_state: %s, game_state=%s, syncing game_state" %
		# [peer_id, operation_name, str(ack_sync_state), str(game_state)]) # Too verbose
	dbg("SYNC: server_ack_sync_completed(peer_id=%d, operation_name='%s'): COMPLETED!" % [peer_id, operation_name])

	# Check that there are still cards on the stock pile, and if not, reshuffle the discard pile and move to the stock pile.
	server_check_if_stock_pile_empty_and_reshuffle()

	var operation_params = ack_sync_state[operation_name].duplicate(true)
	ack_sync_state.erase(operation_name) # Clear the ack state for this operation.
	dbg("SYNC: server_ack_sync_completed(peer_id=%d, operation_name='%s'): ack_sync_state after completion: %s, current operation_params: %s" %
		[peer_id, operation_name, str(ack_sync_state), str(operation_params)])
	if 'advance_player_turn' in operation_params and operation_params['advance_player_turn']:
		# Clear all buy requests
		game_state.current_buy_request_player_ids = {}
		dbg("SYNC: server_ack_sync_completed(peer_id=%d, operation_name='%s'): advancing player turn" % [peer_id, operation_name])
		game_state.current_player_turn_index = (game_state.current_player_turn_index + 1) % len(game_state.public_players_info)
		dbg("SYNC: server_ack_sync_completed(peer_id=%d, operation_name='%s'): game_state.current_player_turn_index=%d" % [peer_id, operation_name,
			game_state.current_player_turn_index])
	dbg("SYNC: server_ack_sync_completed(peer_id=%d, operation_name='%s'): calling sending_game_state" % [peer_id, operation_name])
	send_game_state()
	if 'emit' in operation_params:
		var emit_signal_name = operation_params['emit']
		if emit_signal_name == 'new_card_exposed_on_discard_pile_signal':
			dbg("SYNC: server_ack_sync_completed(peer_id=%d, operation_name='%s'): emitting signal: %s" % [peer_id, operation_name, emit_signal_name])
			new_card_exposed_on_discard_pile_signal.emit()
		elif emit_signal_name == 'deal_penalty_card_to_player':
			var player_id = operation_params['player_id']
			dbg("SYNC: server_ack_sync_completed(peer_id=%d, operation_name='%s'): calling deal_penalty_card_to_player(player_id='%s')" % [peer_id, operation_name, player_id])
			deal_penalty_card_to_player(player_id)
		else:
			error("SYNC: server_ack_sync_completed(peer_id=%d, operation_name='%s'): unknown emit signal: %s" % [peer_id, operation_name, emit_signal_name])
	if 'next_state' in operation_params:
		var next_state = operation_params['next_state']
		if next_state != '':
			dbg("SYNC: server_ack_sync_completed(peer_id=%d, operation_name='%s'): transitioning all players to next state: %s" % [peer_id, operation_name, next_state])
			transition_all_clients_state_to_signal.emit(next_state)
	# Send a signal for _EVERY_ server_ack_sync that has completed on the server so that bots can appropriately react.
	server_ack_sync_completed_signal.emit(peer_id, operation_name, operation_params)

# Convenience function only to be used on the server.
func send_transition_all_clients_state_to_signal(new_state: String) -> void:
	if is_not_server():
		error("send_transition_all_clients_state_to_signal('%s') called on a client" % new_state)
		return
	dbg("SYNC: send_transition_all_clients_state_to_signal('%s'): transitioning all clients to new state" % [new_state])
	transition_all_clients_state_to_signal.emit(new_state)

func register_ack_sync_state(operation_name: String, sync_args: Dictionary = {}) -> void:
	if is_not_server():
		error("register_ack_sync_state('%s') called on a client: sync_args=%s" % [operation_name, str(sync_args)])
		return
	ack_sync_state[operation_name] = sync_args
	ack_sync_state[operation_name]['acks'] = {} # Initialize the acks dictionary.
	dbg("SYNC: register_ack_sync_state(operation_name='%s', sync_args=%s): ack_sync_state=%s" % [operation_name, str(sync_args), str(ack_sync_state)])

################################################################################

# This function sorts the card keys in the player's hand by z_index and then
# makes sure there are no gaps, then returns the next z_index for any new card
# played on top of the player's hand.
func sanitize_players_hand_z_index_values() -> int:
	var players_cards = []
	for card_key in Global.private_player_info['card_keys_in_hand']:
		var playing_card = Global.playing_cards.get(card_key) as PlayingCard
		if playing_card:
			players_cards.append(playing_card)
	players_cards.sort_custom(func(a, b): return a.z_index < b.z_index)
	# Now reassign z_index values to make them consecutive starting from 1.
	for idx in range(len(players_cards)):
		var playing_card = players_cards[idx]
		playing_card.z_index = idx + 1 # Start from 1 to avoid z_index 0
	return len(players_cards) + 1 # Return the next z_index for any new card played on top of the player's hand

func make_discard_pile_tappable(tappable: bool) -> void:
	if len(discard_pile) > 0:
		var top_card = discard_pile[0] as PlayingCard
		top_card.is_tappable = tappable
		top_card.is_draggable = false # Do not allow dragging the top card of the discard pile.

func make_stock_pile_tappable(tappable: bool) -> void:
	if len(stock_pile) > 0:
		var top_card = stock_pile[0] as PlayingCard
		top_card.is_tappable = tappable
		top_card.is_draggable = false # Do not allow dragging the top card of the stock pile.
	else:
		# TODO: Handle empty pile by reshuffling.
		error("make_stock_pile_tappable: stock pile is empty!")

func strip_deck_from_card_key(card_key: String) -> String:
	var parts = card_key.split('-')
	if parts[0] == "JOKER": return "JOKER" # Handle joker specially
	if len(parts) < 2: return parts[0] # For unexpected format
	return "%s-%s" % [parts[0], parts[1]] # Return the rank and suit, e.g., "A-hearts", "2-diamonds", etc.

func send_animate_winning_confetti_explosion_signal(num_millis: int) -> void:
	animate_winning_confetti_explosion_signal.emit(num_millis)

func await_grace_period() -> void:
	if len(discard_pile) == 0: return # no need to wait
	if len(game_state.public_players_info) <= 2: return # no need to wait
	dbg("await_grace_period: waiting for %d seconds for other players to buy from discard pile" % [OTHER_PLAYER_BUY_GRACE_PERIOD_SECONDS])
	await get_tree().create_timer(OTHER_PLAYER_BUY_GRACE_PERIOD_SECONDS).timeout

################################################################################
## synchronize stock and discard piles
################################################################################

func server_check_if_stock_pile_empty_and_reshuffle():
	if is_not_server(): return
	if len(stock_pile) == 0:
		stock_pile = discard_pile.duplicate()
		stock_pile.shuffle()
		discard_pile.clear()
		synchronize_all_stock_piles()

# Synchronizes the stock piles of all players by sending an [rpc] message to each client.
# Note that the stock pile order is descending by z_index (eg. 54..1).
func synchronize_all_stock_piles(ack_sync_name: String = '') -> void:
	if is_not_server(): return
	# dbg("GML10")
	var stock_pile_order = []
	var z_index = len(stock_pile)
	# for card in stock_pile:
	for card_idx in range(len(stock_pile)):
		var card = stock_pile[card_idx]
		card.z_index = z_index
		card.position = stock_pile_position + Vector2(0, -z_index * CARD_SPACING_IN_STACK)
		card.force_face_down()
		# dbg("stock_pile[%d]: key='%s', z_index=%d, position=%s" % [card_idx, card.key, card.z_index, str(card.position)])
		stock_pile_order.append(card.key)
		z_index -= 1
	_rpc_send_stock_pile_order_to_clients.rpc(stock_pile_order)
	if ack_sync_name != '':
		ack_sync_completed(ack_sync_name)

@rpc('authority', 'call_remote', 'reliable')
func _rpc_send_stock_pile_order_to_clients(stock_pile_order: Array) -> void:
	# dbg("GML12")
	# dbg("_send_stock_pile_order_to_clients: stock_pile_order=%s" % [str(stock_pile_order)])
	discard_pile = []
	stock_pile = []
	var new_index_by_key = {}
	var z_index = len(stock_pile_order)
	for key in stock_pile_order:
		var card = playing_cards.get(key)
		if card:
			# DOES NOT WORK:
			# card.z_index = z_index
			# card.set_z_index(card.z_index) # Update the z_index in the scene tree
			# dbg("A: Card key='%s', z_index=%d" % [card.key, card.z_index])
			stock_pile.append(card)
			card.force_face_down()
			new_index_by_key[card.key] = z_index
		else:
			push_error("Card with key '%s' not found in Global.playing_cards!" % [key])
		z_index -= 1
	# Setting the z_index of each playing card from Global.playing_cards does not update the scene tree,
	# so we need to do it manually for each PlayingCard instance in the PlayingCardsControl.
	# Using a tween appears to be the most reliable way to ensure that the values get updated in the scene tree.
	var tween = playing_cards_control.create_tween()
	tween.set_parallel(true)
	for child in playing_cards_control.get_children():
		if child is PlayingCard:
			# Global.dbg("B: Card key='%s', z_index=%d" % [child.key, child.z_index])
			# if child.z_index != Global.playing_cards.get(child.key).z_index:
				# push_error("Card '%s' z_index mismatch: %d != %d" % [child.key, child.z_index, Global.playing_cards.get(child.key).z_index])
			var new_z_index = new_index_by_key[child.key]
			tween.tween_property(child, 'z_index', new_z_index, 0.1)
			# var position = child.get_position()
			var new_position = stock_pile_position + Vector2(0, -new_z_index * CARD_SPACING_IN_STACK)
			tween.tween_property(child, 'position', new_position, 0.1)
			# dbg("GML13, Card '%s' z_index=%d, position=%s" % [child.key, child.z_index, str(child.position)])
		else:
			push_error("Child '%s' is not a PlayingCard!" % [child.name])
	await tween.finished
	# Verify that the 'z_index' field is correct
	# for card_idx in range(len(stock_pile)):
	# 	var card = stock_pile[card_idx]
	# 	var expected_z_index = new_index_by_key.get(card.key)
	# 	if card.z_index != expected_z_index:
	# 		error("Card '%s' z_index mismatch: %d != %d" % [card.key, card.z_index, expected_z_index])
	# 	dbg("stock_pile[%d]: key='%s', z_index=%d, position=%s" % [card_idx, card.key, card.z_index, str(card.position)])
	ack_sync_completed('synchronize_all_stock_piles')

################################################################################
## DEBUG/ERRORS
################################################################################

func dbg(s: String) -> void:
	var my_peer_id = multiplayer.get_unique_id()
	var display_id = "(%10d)" % my_peer_id if my_peer_id != 1 else "(SERVER)    "
	print("%d: %s: %s" % [get_system_time_msec(), display_id, s])

var error_count = 0 # for unit testing purposes

func error(s: String) -> void:
	error_count += 1
	dbg("ERROR(%d): %s" % [error_count, s])

func get_system_time_msec() -> int:
	return int(1000.0 * Time.get_unix_time_from_system())

func sort_run_cards(card_keys: Array) -> Array:
	# Assert that the input card keys represent a valid run (same suit, at least 4 cards):
	if len(card_keys) < 4:
		error("sort_run_cards: invalid run, less than 4 cards: %s" % [str(card_keys)])
		return card_keys
	if !is_valid_run(card_keys):
		error("sort_run_cards: invalid run: %s" % [str(card_keys)])
		return card_keys
	# Sort cards in a run for proper display order
	# Aces are positioned as low or high to minimize gaps, other cards in rank order, jokers fill gaps
	# Separate jokers from regular cards
	var regular_cards = []
	var _num_jokers = 0
	var joker_keys = []
	var has_ace = false

	for card_key in card_keys:
		var parts = card_key.split('-')
		var rank = parts[0]
		if rank == 'JOKER':
			_num_jokers += 1
			joker_keys.append(card_key)
		else:
			var value = _value_lookup[rank]
			if value == 14: # Ace
				has_ace = true
			regular_cards.append({'key': card_key, 'value': value, 'rank': rank})

	# Determine best ace positioning
	var best_sequence = []
	if has_ace:
		# Try ace as low (1)
		var cards_low = []
		for card in regular_cards:
			var new_card = card.duplicate()
			if new_card['value'] == 14:
				new_card['value'] = 1
			cards_low.append(new_card)
		cards_low.sort_custom(func(a, b): return a['value'] < b['value'])

		# Try ace as high (14)
		var cards_high = []
		for card in regular_cards:
			var new_card = card.duplicate()
			if new_card['value'] == 14:
				new_card['value'] = 14
			cards_high.append(new_card)
		cards_high.sort_custom(func(a, b): return a['value'] < b['value'])

		# Calculate gaps for both configurations
		var gaps_low = _calculate_sequence_gaps(cards_low)
		var gaps_high = _calculate_sequence_gaps(cards_high)

		# Use the configuration with fewer gaps
		if gaps_high < gaps_low:
			best_sequence = cards_high
		else:
			best_sequence = cards_low
	else:
		# No ace, just sort by value
		regular_cards.sort_custom(func(a, b): return a['value'] < b['value'])
		best_sequence = regular_cards

	# Build the sorted sequence with jokers placed in gaps
	var result = []
	var joker_idx = 0

	for i in range(len(best_sequence)):
		var card = best_sequence[i]
		result.append(card['key'])

		# Check if there's a gap after this card
		if i < len(best_sequence) - 1:
			var next_card = best_sequence[i + 1]
			var gap_size = next_card['value'] - card['value'] - 1
			# Fill gaps with jokers
			for j in range(gap_size):
				if joker_idx < len(joker_keys):
					result.append(joker_keys[joker_idx])
					joker_idx += 1

	# Check if the sequence has an ace positioned high (value 14)
	var has_high_ace = false
	for card in best_sequence:
		if card['value'] == 14:
			has_high_ace = true
			break

	# Add any remaining jokers
	if has_high_ace:
		# Place remaining jokers at the beginning
		for j in range(len(joker_keys) - 1, joker_idx - 1, -1):
			result.push_front(joker_keys[j])
	else:
		# Place remaining jokers at the end
		for j in range(joker_idx, len(joker_keys)):
			result.append(joker_keys[j])

	return result

func _calculate_sequence_gaps(cards: Array) -> int:
	if len(cards) <= 1:
		return 0

	var gaps = 0
	for i in range(1, len(cards)):
		var diff = cards[i]['value'] - cards[i - 1]['value'] - 1
		if diff > 0:
			gaps += diff
	return gaps

# AI-generated:
# # Post-meld public melding functions
# func can_publicly_meld_card(card_key: String, all_public_meld_stats: Dictionary) -> bool:
# 	# Check if card can be melded to public groups or runs
# 	if all_public_meld_stats == null:
# 		return false
#
# 	var parts = card_key.split('-')
# 	var rank = parts[0]
# 	var suit = parts[1] if len(parts) > 1 else ""
#
# 	# Check for groups - same rank can be added to existing groups
# 	if rank in all_public_meld_stats['by_rank']:
# 		var melds_by_rank = all_public_meld_stats['by_rank'][rank]
# 		for single_meld in melds_by_rank:
# 			if single_meld['meld_group_type'] == 'group':
# 				return true
#
# 	# Check for runs - card can extend or replace jokers in runs of same suit
# 	if suit in all_public_meld_stats['by_suit']:
# 		for pub_rank in all_public_meld_stats['by_suit'][suit]:
# 			for pub_meld in all_public_meld_stats['by_suit'][suit][pub_rank]:
# 				if pub_meld['meld_group_type'] == 'run':
# 					# Check if this card can extend or replace in this run
# 					if can_card_extend_run(card_key, pub_meld) or can_card_replace_joker_in_run(card_key, pub_meld):
# 						return true
#
# 	return false
#
# func can_card_extend_run(card_key: String, pub_meld: Dictionary) -> bool:
# 	# Get all cards in the public run to determine if this card can extend it
# 	var run_cards = []
# 	var player_id = pub_meld['player_id']
# 	var meld_group_index = pub_meld['meld_group_index']
#
# 	# Find the actual run by looking at the player's played_to_table
# 	for ppi in game_state.public_players_info:
# 		if ppi.id == player_id:
# 			if meld_group_index < len(ppi.played_to_table):
# 				var meld_group = ppi.played_to_table[meld_group_index]
# 				if meld_group['type'] == 'run':
# 					run_cards = meld_group['card_keys']
# 					break
# 			break
#
# 	if len(run_cards) == 0:
# 		return false
#
# 	# Check if the card can be used in this run (suit validation)
# 	if not can_card_be_used_in_run(card_key, run_cards):
# 		return false
#
# 	# Try adding the card to the front or back of the run
# 	var test_run_front = [card_key] + run_cards
# 	var test_run_back = run_cards + [card_key]
#
# 	return is_valid_run(test_run_front) or is_valid_run(test_run_back)
#
# func can_card_replace_joker_in_run(card_key: String, pub_meld: Dictionary) -> bool:
# 	# Get all cards in the public run to determine if this card can replace a joker
# 	var run_cards = []
# 	var player_id = pub_meld['player_id']
# 	var meld_group_index = pub_meld['meld_group_index']
#
# 	# Find the actual run by looking at the player's played_to_table
# 	for ppi in game_state.public_players_info:
# 		if ppi.id == player_id:
# 			if meld_group_index < len(ppi.played_to_table):
# 				var meld_group = ppi.played_to_table[meld_group_index]
# 				if meld_group['type'] == 'run':
# 					run_cards = meld_group['card_keys']
# 					break
# 			break
#
# 	if len(run_cards) == 0:
# 		return false
#
# 	# Check if the card can be used in this run (suit validation)
# 	if not can_card_be_used_in_run(card_key, run_cards):
# 		return false
#
# 	# Check if any position in the run has a joker and this card can replace it
# 	for i in range(len(run_cards)):
# 		var run_card = run_cards[i]
# 		var parts = run_card.split('-')
# 		if parts[0] == 'JOKER':
# 			# Try replacing this joker with our card
# 			var test_run = run_cards.duplicate()
# 			test_run[i] = card_key
# 			if is_valid_run(test_run):
# 				return true
#
# 	return false
#
# func can_card_be_used_in_run(card_key: String, run_cards: Array) -> bool:
# 	# Check if the card has the same suit as the run (jokers can be used in any run)
# 	var card_parts = card_key.split('-')
# 	if len(card_parts) < 2:
# 		return false
# 	var is_joker = card_parts[0] == 'JOKER'
# 	var card_suit = card_parts[1] if not is_joker else ""
#
# 	# Determine run suit from existing cards (skip jokers)
# 	var run_suit = ""
# 	for run_card in run_cards:
# 		var run_parts = run_card.split('-')
# 		if run_parts[0] != 'JOKER':
# 			run_suit = run_parts[1]
# 			break
#
# 	# Jokers can be used in any run, but regular cards must match suit
# 	if is_joker:
# 		return run_suit != ""  # Jokers can only be used in runs with at least one non-joker card
# 	else:
# 		return card_suit == run_suit
