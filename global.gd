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
var player_hand_x_start: float
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

@onready var playing_cards_control: Control = $"/root/RootNode/PlayingCardsControl"

const VERSION = '0.2.0'
const GAME_PORT = 7000
const DISCOVERY_PORT = 8910
const MAX_PLAYERS = 10
const CARD_SPACING_IN_STACK = 0.5 # Y-spacing for final stack in pixels
const PLAYER_SCALE = Vector2(0.65, 0.65)
const DEBUG_SHOW_CARD_INFO = false
const OTHER_PLAYER_BUY_GRACE_PERIOD_SECONDS: float = 3.0 # if DEBUG_SHOW_CARD_INFO else 10.0

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
	player_hand_x_start = screen_size.x * 0.55 # Start at 55% of the screen width
	player_hand_x_end = screen_size.x * 0.9 # End at 90% of the screen width

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
		'card_keys_in_hand': [], # unordered collection of playing card keys
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

func create_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(GAME_PORT, MAX_PLAYERS)
	if error:
		reset_game()
		return error
	multiplayer.multiplayer_peer = peer
	private_player_info['id'] = '1'
	var public_player_info = gen_public_player_info(private_player_info)
	game_state.public_players_info.append(public_player_info)
	player_connected_signal.emit(1, public_player_info)

func gen_public_player_info(private_info: Dictionary) -> Dictionary:
	# Generate a new public player info dictionary for the current player.
	# This is used when a new player connects to the game.
	var public_player_info = {
		'id': private_info['id'],
		'name': private_info['name'],
		'is_bot': private_info['is_bot'],
		'turn_index': private_info['turn_index'],
		'played_to_table': private_info['played_to_table'],
		'num_cards': len(private_info['card_keys_in_hand']),
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
		dbg("ERROR: Could not load bot class: %s" % [bot_resource_name])
		return
	var bot_instance = bot_class.new(id)
	if not bot_instance:
		dbg("ERROR: Could not instantiate bot class: %s" % [bot_resource_name])
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
	var error = peer.create_client(address, GAME_PORT)
	if error:
		return error
	multiplayer.multiplayer_peer = peer

func _on_peer_connected(peer_id):
	var public_player_info = gen_public_player_info(private_player_info)
	dbg("Global._on_peer_connected(peer_id=%s): sending my player_info to peer_id: %s" % [str(peer_id), str(public_player_info)])
	_rpc_register_player.rpc_id(peer_id, public_player_info)

@rpc('any_peer', 'reliable') # TODO: Fix this.
func _rpc_register_player(new_player_info):
	if is_not_server(): return
	var new_player_id = new_player_info['id']
	dbg("Global._register_player: received new_player_info: %s" % [str(new_player_info)])
	# First check if there are too many players and delete a bot if possible.
	var current_num_players = len(game_state.public_players_info)
	if current_num_players >= MAX_PLAYERS:
		var all_bots = _get_bots()
		if len(all_bots) == 0:
			dbg("ERROR: no bots found when current_num_players=%d" % [current_num_players])
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
# 		dbg("ERROR: get_winning_player_public_info: more than one winning player found: %s" % [str(winning_players)])
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
	game_state.public_players_info.clear()
	server_disconnected_signal.emit()

func change_custom_card_back(random_back_svg_name):
	custom_card_back.texture = load("res://svg-card-backs/%s" % [random_back_svg_name])
	custom_card_back_texture_changed_signal.emit()

func send_game_state():
	if is_not_server():
		dbg("ERROR: send_game_state called on a client")
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

# Local player card manipulation signals:

func emit_card_clicked_signal(playing_card, global_position):
	card_clicked_signal.emit(playing_card, global_position)

func emit_card_drag_started_signal(playing_card, from_position):
	card_drag_started_signal.emit(playing_card, from_position)

func emit_card_moved_signal(playing_card, from_position, global_position):
	card_moved_signal.emit(playing_card, from_position, global_position)

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
		dbg("ERROR: player_has_melded: could not find player_id='%s' in game_state" % [player_id])
		return false
	var played_to_table = public_player_info[0].played_to_table
	return len(played_to_table) > 0

# func get_public_meld_card_keys_dict(player_id: String) -> Dictionary:
# 	var card_keys = {}
# 	var public_player_info = game_state.public_players_info.filter(func(pi): return pi.id == player_id)
# 	if len(public_player_info) != 1:
# 		dbg("ERROR: get_public_meld_card_keys_dict: could not find player_id='%s' in game_state" % [player_id])
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

func gen_hand_stats(card_keys_in_hand: Array) -> Dictionary:
	var hand_stats = card_keys_in_hand.reduce(func(acc, card_key):
		return add_card_to_stats(acc, card_key), {
			# by_rank: 'A':[],'2':[],...,'10':[],'J':[],'Q':[],'K':[],'JOKER':[],
			'by_rank': {},
			# by_suit: 'hearts':{'A':[],'2':[],...,'10':[],'J':[],'Q':[],'K':[],'JOKER':[]},
			# by_suit: 'diamonds':{'A':[],'2':[],...,'10':[],'J':[],'Q':[],'K':[],'JOKER': []},
			# by_suit: 'clubs':{'A':[],'2':[],...,'10':[],'J':[],'Q':[],'K':[],'JOKER':[]},
			# by_suit: 'spades':{'A':[],'2':[],...,'10':[],'J':[],'Q':[],'K':[],'JOKER':[]},
			'by_suit': {},
			'num_cards': len(card_keys_in_hand),
			'jokers': [],
		})

	# Generate Groups stats - ordered descending by total score
	var groups_of_3_plus = []
	var groups_of_2 = []
	for rank in hand_stats['by_rank'].keys():
		# if rank == 'JOKER': continue
		var cards = hand_stats['by_rank'][rank]
		if len(cards) >= 3:
			groups_of_3_plus.append(cards)
		elif len(cards) == 2:
			groups_of_2.append(cards)
	hand_stats['groups_of_3_plus'] = _sort_hands_by_score(groups_of_3_plus)
	hand_stats['groups_of_2'] = _sort_hands_by_score(groups_of_2)

	# Generate Runs stats
	var runs_of_4_plus = []
	var runs_of_3 = []
	var runs_of_2 = []
	for suit in hand_stats['by_suit'].keys():
		var ranks_map = hand_stats['by_suit'][suit]
		var run = []
		var already_used = {}

		var next_usable_card_in_rank = func(rank: String) -> String:
			if rank in ranks_map:
				for card_key in ranks_map[rank]:
					if not card_key in already_used:
						return card_key
			return ""

		var mark_run_as_used = func(run_cards: Array) -> void:
			for card_key in run_cards:
				already_used[card_key] = true

		for rank in ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A', 'rank-will-not-be-found-terminator']:
			var card_key = next_usable_card_in_rank.call(rank)
			if card_key != "":
				run.append(card_key)
				continue
			else:
				# Found a run
				if len(run) >= 4:
					runs_of_4_plus.append(run)
					mark_run_as_used.call(run)
				elif len(run) == 3:
					runs_of_3.append(run)
					mark_run_as_used.call(run)
				elif len(run) == 2:
					runs_of_2.append(run)
					mark_run_as_used.call(run)
				run = []

	hand_stats['runs_of_4_plus'] = _sort_hands_by_score(runs_of_4_plus)
	hand_stats['runs_of_3'] = _sort_hands_by_score(runs_of_3)
	hand_stats['runs_of_2'] = _sort_hands_by_score(runs_of_2)
	return hand_stats

func _gen_all_public_meld_stats() -> Dictionary:
	var all_melds = game_state.public_players_info.reduce(func(acc, ppi):
		for meld_idx in range(len(ppi.played_to_table)):
			var meld = ppi.played_to_table[meld_idx]
			var meld_type = meld['type'] # 'group' or 'run'
			for card_key in meld['card_keys']:
				acc = add_card_to_stats(acc, card_key, ppi.id, meld_idx, meld_type)
		return acc, {
		'by_rank': {},
		'by_suit': {},
		# 'num_cards': 0,
		'jokers': [],
	})
	return all_melds

func evaluate_hand(hand_stats: Dictionary, player_id: String) -> Dictionary:
	var all_public_meld_stats = _gen_all_public_meld_stats()
	var pre_meld = not player_has_melded(player_id)
	var evaluation = null
	if pre_meld:
		dbg("ENTER PRE-MELD Global.evaluate_hand: round_num=%d, player_id='%s', all_public_meld_stats=%s" % [game_state.current_round_num, player_id, str(all_public_meld_stats)])
		evaluation = _evaluate_hand_pre_meld(game_state.current_round_num, hand_stats, all_public_meld_stats)
		dbg("LEAVE PRE-MELD Global.evaluate_hand: round_num=%d, player_id='%s', evaluation=%s" % [game_state.current_round_num, player_id, str(evaluation)])
	else:
		dbg("ENTER POST-MELD Global.evaluate_hand: round_num=%d, player_id='%s', hand_stats=%s, all_public_meld_stats=%s" % [game_state.current_round_num, player_id, str(hand_stats), str(all_public_meld_stats)])
		evaluation = _evaluate_hand_post_meld(game_state.current_round_num, hand_stats, all_public_meld_stats)
		dbg("LEAVE POST-MELD Global.evaluate_hand: round_num=%d, player_id='%s', evaluation=%s" % [game_state.current_round_num, player_id, str(evaluation)])
	return evaluation

# Helper function to sort hands by score
func _sort_hands_by_score(hands: Array) -> Array:
	var hands_copy = hands.duplicate()
	var scores = []
	for hand in hands_copy:
		scores.append(tally_hand_cards_score(hand))

	# Sort using indices to maintain correspondence
	var indices = range(len(hands_copy))
	indices.sort_custom(func(i, j):
		var score_i = scores[i]
		var score_j = scores[j]
		if score_i == score_j:
			# Sort by first card key if scores are equal
			return hands_copy[i][0] < hands_copy[j][0]
		return score_i > score_j # descending
	)

	var sorted_hands = []
	for i in indices:
		sorted_hands.append(hands_copy[i])
	return sorted_hands

# Round requirements
var _groups_per_round = [2, 1, 0, 3, 2, 1, 0]
var _runs_per_round = [0, 1, 2, 0, 1, 2, 3]

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

# Main evaluation functions
func _evaluate_hand_pre_meld(round_num: int, hand_stats: Dictionary, all_public_meld_stats: Dictionary) -> Dictionary:
	var num_groups = _groups_per_round[round_num - 1]
	var num_runs = _runs_per_round[round_num - 1]

	# Filter out irrelevant structures for this round
	if num_runs == 0:
		hand_stats['runs_of_4_plus'] = []
		hand_stats['runs_of_3'] = []
		hand_stats['runs_of_2'] = []
	if num_groups == 0:
		hand_stats['groups_of_3_plus'] = []
		hand_stats['groups_of_2'] = []

	dbg("ENTER Global._evaluate_hand_pre_meld: round_num=%d, num_groups=%d, num_runs=%d, hand_stats=%s" % [round_num, num_groups, num_runs, str(hand_stats)])

	var acc = empty_evaluation()
	var already_used = {}
	var available_jokers = hand_stats['jokers'].duplicate()

	var all_cards_available = func(card_keys: Array) -> bool:
		for card_key in card_keys:
			if card_key in already_used:
				return false
		return true

	var mark_all_as_used = func(card_keys: Array) -> void:
		for card_key in card_keys:
			already_used[card_key] = true

	# Meld groups first
	var melded_groups = 0
	for group_idx in range(num_groups):
		if melded_groups >= len(hand_stats['groups_of_3_plus']) or group_idx >= len(hand_stats['groups_of_3_plus']):
			break
		var hand = hand_stats['groups_of_3_plus'][group_idx]
		var available_cards = _filter_available_cards(hand, already_used)
		if len(available_cards) >= 3:
			if len(available_cards) == 3:
				mark_all_as_used.call(available_cards)
				melded_groups += 1
				acc['can_be_personally_melded'].append({
					'type': 'group',
					'card_keys': available_cards
				})
				continue
			# Optimize group if more than 3 cards
			available_cards = _optimize_group(available_cards, already_used, available_jokers, hand_stats['by_suit'])
			mark_all_as_used.call(available_cards)
			melded_groups += 1
			acc['can_be_personally_melded'].append({
				'type': 'group',
				'card_keys': available_cards
			})

	# Meld runs second
	var melded_runs = 0
	for run_idx in range(num_runs):
		if melded_runs >= len(hand_stats['runs_of_4_plus']) or run_idx >= len(hand_stats['runs_of_4_plus']):
			break
		var hand = hand_stats['runs_of_4_plus'][run_idx]
		var available_cards = _filter_available_cards(hand, already_used)
		if len(available_cards) >= 4: # Need at least 4 cards for a run
			# Try to use the available cards to form a run
			if len(available_cards) == len(hand): # All cards available
				mark_all_as_used.call(available_cards)
				melded_runs += 1
				acc['can_be_personally_melded'].append({
					'type': 'run',
					'card_keys': available_cards
				})
			else:
				# Try to form a shorter run with available cards
				var shorter_run = _try_shorter_run(available_cards)
				if len(shorter_run) >= 4:
					mark_all_as_used.call(shorter_run)
					melded_runs += 1
					acc['can_be_personally_melded'].append({
						'type': 'run',
						'card_keys': shorter_run
					})

	# Build additional runs with bitmap algorithm
	while true:
		var need_runs = num_runs - melded_runs
		if need_runs <= 0:
			break
		var new_run = _build_a_run(available_jokers, already_used, hand_stats['by_suit'])
		if new_run.has('success') and new_run['success']:
			available_jokers = new_run['remaining_jokers']
			mark_all_as_used.call(new_run['run'])
			acc['can_be_personally_melded'].append({
				'type': 'run',
				'card_keys': new_run['run']
			})
			melded_runs += 1
		else:
			break

	# Try to build runs from smaller sequences with jokers
	while true:
		var need_runs = num_runs - melded_runs
		if need_runs <= 0 or len(available_jokers) == 0 or len(hand_stats['runs_of_3']) == 0:
			break
		var joker = available_jokers[0]
		var new_run = _try_valid_run(joker, already_used, hand_stats['runs_of_3'][0])
		if new_run.has('success') and new_run['success']:
			available_jokers.pop_front()
			hand_stats['runs_of_3'].pop_front()
			mark_all_as_used.call(new_run['run'])
			acc['can_be_personally_melded'].append({
				'type': 'run',
				'card_keys': new_run['run']
			})
			melded_runs += 1
		else:
			break

	# Try to build runs from 2-card sequences with 2 jokers
	while true:
		var need_runs = num_runs - melded_runs
		if need_runs <= 0 or len(available_jokers) <= 1 or len(hand_stats['runs_of_2']) == 0:
			break
		var joker1 = available_jokers[0]
		var temp_run = _try_valid_run(joker1, already_used, hand_stats['runs_of_2'][0])
		if temp_run.has('success') and temp_run['success']:
			var joker2 = available_jokers[1]
			var new_run = _try_valid_run(joker2, already_used, temp_run['run'])
			if new_run.has('success') and new_run['success']:
				available_jokers.pop_front()
				available_jokers.pop_front()
				hand_stats['runs_of_2'].pop_front()
				mark_all_as_used.call(new_run['run'])
				acc['can_be_personally_melded'].append({
					'type': 'run',
					'card_keys': new_run['run']
				})
				melded_runs += 1
			else:
				break
		else:
			break

	# Try to build groups from 2-card groups with jokers
	while true:
		var need_groups = num_groups - melded_groups
		if need_groups <= 0 or len(available_jokers) == 0 or len(hand_stats['groups_of_2']) == 0:
			break
		var joker = available_jokers[0]
		var hand = [joker] + hand_stats['groups_of_2'][0]
		hand_stats['groups_of_2'].pop_front()
		if all_cards_available.call(hand):
			available_jokers.pop_front()
			mark_all_as_used.call(hand)
			acc['can_be_personally_melded'].append({
				'type': 'group',
				'card_keys': hand
			})
			melded_groups += 1

	# Add remaining jokers to existing melds
	while len(available_jokers) > 0:
		if melded_groups > 0:
			var joker = available_jokers.pop_front()
			_add_to_melded_group(acc, joker)
		elif melded_runs > 0:
			var joker = available_jokers.pop_front()
			if not _add_to_melded_run(acc, joker):
				break
		else:
			break

	# Calculate final score
	acc['eval_score'] = 100 * len(acc['can_be_personally_melded'])

	if melded_groups == num_groups and melded_runs == num_runs:
		acc['eval_score'] += 1000 # bonus for melding
		# Clear partial hands since we can meld
		hand_stats['groups_of_3_plus'] = []
		hand_stats['groups_of_2'] = []
		hand_stats['runs_of_4_plus'] = []
		hand_stats['runs_of_3'] = []
		hand_stats['runs_of_2'] = []
	else:
		acc['eval_score'] += 50 * (len(hand_stats['groups_of_3_plus']) + len(hand_stats['groups_of_2']) + len(hand_stats['runs_of_4_plus']) + len(hand_stats['runs_of_3']) + len(hand_stats['runs_of_2']))
		acc['can_be_personally_melded'] = []

	_gen_recommended_discards(acc, hand_stats, already_used, all_public_meld_stats)
	var penalty_score = - tally_hand_cards_score(acc['recommended_discards'])
	acc['eval_score'] += penalty_score

	if melded_groups == num_groups and melded_runs == num_runs:
		acc['is_winning_hand'] = (round_num < 7 and len(acc['recommended_discards']) == 1) or (round_num == 7 and len(acc['recommended_discards']) == 0)
		if acc['is_winning_hand']:
			acc['eval_score'] += 1000 # bonus for winning

	return acc

func _evaluate_hand_post_meld(round_num: int, hand_stats: Dictionary, all_public_meld_stats: Dictionary) -> Dictionary:
	var acc = empty_evaluation()
	var already_used = {}
	var available_jokers = hand_stats['jokers'].duplicate()
	var penalty_cards = []

	# First, attempt to find publicly meldable groups
	var possibilities = _find_groups_can_be_publicly_melded(hand_stats, all_public_meld_stats)
	var can_be_publicly_melded = []

	for rank in hand_stats['by_rank']:
		var card_keys = hand_stats['by_rank'][rank]
		if not rank in possibilities:
			penalty_cards.append_array(card_keys)
			continue

		for possibility in possibilities[rank]:
			for card_key in card_keys:
				if card_key in already_used: continue
				already_used[card_key] = true
				can_be_publicly_melded.append({
					'card_key': card_key,
					'target_player_id': possibility['player_id'],
					'meld_group_index': possibility['meld_group_index'],
				})
				# Add available jokers to this meld
				while len(available_jokers) > 0:
					var joker = available_jokers.pop_front()
					can_be_publicly_melded.append({
						'card_key': joker,
						'target_player_id': possibility['player_id'],
						'meld_group_index': possibility['meld_group_index'],
					})

	if len(available_jokers) > 0:
		dbg("ERROR! available_jokers=%s but should be 0" % [str(available_jokers)])

	# Now attempt to find publicly meldable runs
	possibilities = _find_runs_can_be_publicly_melded(hand_stats, already_used, all_public_meld_stats)
	for suit in hand_stats['by_suit']:
		if not suit in possibilities:
			# Add unused cards to penalty cards
			for rank in hand_stats['by_suit'][suit]:
				var card_keys = hand_stats['by_suit'][suit][rank]
				for card_key in card_keys:
					if not card_key in already_used:
						penalty_cards.append(card_key)
			continue

		# Process each possible run meld for this suit
		for possibility in possibilities[suit]:
			var card_key = possibility['card_key']
			if card_key in already_used:
				continue
			already_used[card_key] = true
			can_be_publicly_melded.append({
				'card_key': card_key,
				'target_player_id': possibility['player_id'],
				'meld_group_index': possibility['meld_group_index'],
			})

			# If this card can extend a run, add available jokers to this meld
			if possibility['can_extend']:
				while len(available_jokers) > 0:
					var joker = available_jokers.pop_front()
					can_be_publicly_melded.append({
						'card_key': joker,
						'target_player_id': possibility['player_id'],
						'meld_group_index': possibility['meld_group_index'],
					})
					break # Only add one joker per extension

		# Add any remaining unused cards in this suit to penalty cards
		for rank in hand_stats['by_suit'][suit]:
			var card_keys = hand_stats['by_suit'][suit][rank]
			for card_key in card_keys:
				if not card_key in already_used:
					penalty_cards.append(card_key)

	_gen_recommended_discards(acc, hand_stats, already_used, all_public_meld_stats)

	acc['can_be_publicly_melded'] = can_be_publicly_melded
	var can_be_publicly_melded_score = 100 * len(can_be_publicly_melded)
	var penalty_cards_score = - tally_hand_cards_score(penalty_cards)
	acc['eval_score'] = can_be_publicly_melded_score + penalty_cards_score
	acc['is_winning_hand'] = (round_num < 7 and len(acc['recommended_discards']) == 1) or (round_num == 7 and len(acc['recommended_discards']) == 0)
	if acc['is_winning_hand']:
		acc['eval_score'] += 1000

	return acc

# Helper functions for hand evaluation

func _filter_available_cards(card_keys: Array, already_used: Dictionary) -> Array:
	var available_cards = []
	for card_key in card_keys:
		if not card_key in already_used:
			available_cards.append(card_key)
	return available_cards

func _try_shorter_run(card_keys: Array) -> Array:
	# Try to form the longest possible run from available cards
	# This is a simplified approach - just return the cards if they form a valid sequence
	if len(card_keys) < 4:
		return []

	# Sort cards by rank to find sequences
	var cards_by_rank = {}
	var suit = ""
	for card_key in card_keys:
		var parts = card_key.split('-')
		if suit == "":
			suit = parts[1]
		elif suit != parts[1]:
			# Mixed suits, can't form a run
			return []
		var rank = parts[0]
		cards_by_rank[rank] = card_key

	# Try to find a sequence of 4 or more cards
	var rank_order = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
	var sequence = []
	for rank in rank_order:
		if rank in cards_by_rank:
			sequence.append(cards_by_rank[rank])
		else:
			# Break in sequence
			if len(sequence) >= 4:
				return sequence
			sequence = []

	# Check final sequence
	if len(sequence) >= 4:
		return sequence

	return card_keys # Return original if no better sequence found

func _optimize_group(available_cards: Array, already_used: Dictionary, available_jokers: Array, by_suit: Dictionary) -> Array:
	for new_group in _permutations_of_3_at_a_time(available_cards):
		var new_already_used = already_used.duplicate()
		for card_key in new_group:
			new_already_used[card_key] = true
		var run_result = _build_a_run(available_jokers, new_already_used, by_suit)
		if run_result.has('success') and run_result['success']:
			return new_group
	return available_cards

func _permutations_of_3_at_a_time(card_keys: Array) -> Array:
	var permutations = []
	if len(card_keys) <= 3:
		return [card_keys]
	for i in range(len(card_keys)):
		for j in range(i + 1, len(card_keys)):
			for k in range(j + 1, len(card_keys)):
				var permutation = [card_keys[i], card_keys[j], card_keys[k]]
				permutations.append(permutation)
	return permutations

func _add_to_melded_group(acc: Dictionary, card_key: String) -> void:
	for meld in acc['can_be_personally_melded']:
		if meld['type'] == 'group':
			meld['card_keys'].insert(0, card_key)
			return

func _add_to_melded_run(acc: Dictionary, card_key: String) -> bool:
	for meld in acc['can_be_personally_melded']:
		if meld['type'] == 'run':
			var new_run = _try_valid_run(card_key, {}, meld['card_keys'])
			if new_run.has('success') and new_run['success']:
				meld['card_keys'] = new_run['run']
				return true
	return false

func _gen_recommended_discards(acc: Dictionary, hand_stats: Dictionary, already_used: Dictionary, all_public_meld_stats: Dictionary) -> void:
	var save_for_last = []
	var save_cards = func(groups: Array) -> void:
		for card_keys in groups:
			for card_key in card_keys:
				if card_key in already_used:
					continue
				already_used[card_key] = true
				save_for_last.append(card_key)

	save_cards.call(hand_stats['groups_of_3_plus'])
	save_cards.call(hand_stats['groups_of_2'])
	save_cards.call(hand_stats['runs_of_4_plus'])
	save_cards.call(hand_stats['runs_of_3'])
	save_cards.call(hand_stats['runs_of_2'])
	save_for_last = sort_card_keys_by_score(save_for_last)

	for rank in hand_stats['by_rank']:
		var card_keys = hand_stats['by_rank'][rank]
		for card_key in card_keys:
			if card_key in already_used:
				continue
			if _is_publicly_meldable(rank, card_key, all_public_meld_stats):
				save_for_last.append(card_key)
				continue
			acc['recommended_discards'].append(card_key)

	acc['recommended_discards'] = sort_card_keys_by_score(acc['recommended_discards'])
	acc['recommended_discards'].append_array(save_for_last)

func _is_publicly_meldable(rank: String, card_key: String, all_public_meld_stats: Dictionary) -> bool:
	# Check if card can be melded to public groups or runs
	if all_public_meld_stats == null:
		return false

	# Check for groups - same rank can be added to existing groups
	if rank in all_public_meld_stats['by_rank']:
		var melds_by_rank = all_public_meld_stats['by_rank'][rank]
		for single_meld in melds_by_rank:
			if single_meld['meld_group_type'] == 'group':
				return true

	# Check for runs - card can extend or replace jokers in runs of same suit
	var parts = card_key.split('-')
	if len(parts) >= 2: # Not a joker
		var suit = parts[1]
		if suit in all_public_meld_stats['by_suit']:
			for pub_rank in all_public_meld_stats['by_suit'][suit]:
				for pub_meld in all_public_meld_stats['by_suit'][suit][pub_rank]:
					if pub_meld['meld_group_type'] == 'run':
						# Check if this card can extend or replace in this run
						if _can_card_extend_run(card_key, pub_meld) or _can_card_replace_joker_in_run(card_key, pub_meld):
							return true

	return false

func _find_groups_can_be_publicly_melded(hand_stats: Dictionary, all_public_meld_stats: Dictionary) -> Dictionary:
	var possible_group_melds = {}
	for rank in hand_stats['by_rank']:
		if not rank in all_public_meld_stats['by_rank']:
			continue
		var pub_melds = all_public_meld_stats['by_rank'][rank]
		possible_group_melds[rank] = pub_melds
	return possible_group_melds

func _can_card_extend_run(card_key: String, pub_meld: Dictionary) -> bool:
	# Get all cards in the public run to determine if this card can extend it
	var run_cards = []
	var player_id = pub_meld['player_id']
	var meld_group_index = pub_meld['meld_group_index']

	# Find the actual run by looking at the player's played_to_table
	for ppi in game_state.public_players_info:
		if ppi.id == player_id:
			if meld_group_index < len(ppi.played_to_table):
				var meld_group = ppi.played_to_table[meld_group_index]
				if meld_group['type'] == 'run':
					run_cards = meld_group['card_keys']
					break
			break

	if len(run_cards) == 0:
		return false

	# Try adding the card to the front or back of the run
	var test_run_front = [card_key] + run_cards
	var test_run_back = run_cards + [card_key]

	return _is_valid_run(test_run_front) or _is_valid_run(test_run_back)

func _can_card_replace_joker_in_run(card_key: String, pub_meld: Dictionary) -> bool:
	# Get all cards in the public run to determine if this card can replace a joker
	var run_cards = []
	var player_id = pub_meld['player_id']
	var meld_group_index = pub_meld['meld_group_index']

	# Find the actual run by looking at the player's played_to_table
	for ppi in game_state.public_players_info:
		if ppi.id == player_id:
			if meld_group_index < len(ppi.played_to_table):
				var meld_group = ppi.played_to_table[meld_group_index]
				if meld_group['type'] == 'run':
					run_cards = meld_group['card_keys']
					break
			break

	if len(run_cards) == 0:
		return false

	# Check if any position in the run has a joker and this card can replace it
	for i in range(len(run_cards)):
		var run_card = run_cards[i]
		var parts = run_card.split('-')
		if parts[0] == 'JOKER':
			# Try replacing this joker with our card
			var test_run = run_cards.duplicate()
			test_run[i] = card_key
			if _is_valid_run(test_run):
				return true

	return false

func _find_runs_can_be_publicly_melded(hand_stats: Dictionary, already_used: Dictionary, all_public_meld_stats: Dictionary) -> Dictionary:
	var possible_run_melds = {}
	# Find runs that can be extended or have jokers replaced
	for suit in hand_stats['by_suit']:
		if not suit in all_public_meld_stats['by_suit']:
			continue
		possible_run_melds[suit] = []

		# Check each rank in this suit to see if it can extend or replace in public runs
		for rank in hand_stats['by_suit'][suit]:
			var card_keys = hand_stats['by_suit'][suit][rank]
			for card_key in card_keys:
				if card_key in already_used:
					continue

				# Check if this card can extend or replace in any public run of this suit
				for pub_rank in all_public_meld_stats['by_suit'][suit]:
					for pub_meld in all_public_meld_stats['by_suit'][suit][pub_rank]:
						if pub_meld['meld_group_type'] == 'run':
							# Check if this card can extend this run
							if _can_card_extend_run(card_key, pub_meld):
								possible_run_melds[suit].append({
									'card_key': card_key,
									'player_id': pub_meld['player_id'],
									'meld_group_index': pub_meld['meld_group_index'],
									'can_extend': true,
									'can_replace_joker': false
								})
							# Check if this card can replace a joker in this run
							if _can_card_replace_joker_in_run(card_key, pub_meld):
								possible_run_melds[suit].append({
									'card_key': card_key,
									'player_id': pub_meld['player_id'],
									'meld_group_index': pub_meld['meld_group_index'],
									'can_extend': false,
									'can_replace_joker': true
								})

		# Remove suits with no possible melds
		if len(possible_run_melds[suit]) == 0:
			possible_run_melds.erase(suit)

	return possible_run_melds

# Run building functions
func _build_a_run(available_jokers: Array, already_used: Dictionary, by_suit: Dictionary) -> Dictionary:
	var suits = ['clubs', 'spades', 'hearts', 'diamonds']
	for use_num_jokers in range(len(available_jokers) + 1):
		for suit in suits:
			if not suit in by_suit:
				continue
			var by_rank = by_suit[suit]
			var result = _build_a_run_with_suit(available_jokers, already_used, by_rank, use_num_jokers)
			if result.has('success') and result['success']:
				return result
	return {'success': false}

func _build_a_run_with_suit(available_jokers: Array, already_used: Dictionary, by_rank: Dictionary, use_num_jokers: int) -> Dictionary:
	var involved_cards = {}
	var bitmap = 0
	for rank in by_rank:
		for card_key in by_rank[rank]:
			if not card_key in already_used:
				bitmap |= _rank_to_bitmap(rank)
				involved_cards[rank] = card_key
				break

	if len(involved_cards) == 0 or bitmap == 0:
		return {'success': false}

	var new_jokers = available_jokers.duplicate()
	var new_run = _longest_sequence_with_jokers(involved_cards, bitmap, use_num_jokers)
	if new_run.has('success') and new_run['success']:
		new_run['run'] = _replace_jokers(new_run['run'], new_jokers.slice(0, use_num_jokers))
		new_run['remaining_jokers'] = new_jokers.slice(use_num_jokers)
		return new_run

	return {'success': false}

func _rank_to_bitmap(rank: String) -> int:
	var rank_to_bitmap = {
		'A': 0x0001 | 0x2000, # low ace | high ace
		'2': 0x0002, '3': 0x0004, '4': 0x0008, '5': 0x0010,
		'6': 0x0020, '7': 0x0040, '8': 0x0080, '9': 0x0100,
		'10': 0x0200, 'J': 0x0400, 'Q': 0x0800, 'K': 0x1000
	}
	return rank_to_bitmap.get(rank, 0)

func _pos_to_rank(pos: int) -> String:
	var pos_to_rank = {
		0x0001: 'A', 0x0002: '2', 0x0004: '3', 0x0008: '4', 0x0010: '5',
		0x0020: '6', 0x0040: '7', 0x0080: '8', 0x0100: '9', 0x0200: '10',
		0x0400: 'J', 0x0800: 'Q', 0x1000: 'K', 0x2000: 'A'
	}
	return pos_to_rank.get(pos, '')

func _longest_sequence_with_jokers(involved_cards: Dictionary, bitmap: int, use_num_jokers: int) -> Dictionary:
	if bitmap == 0:
		return {'success': false}

	var best_run = []
	var best_length = 0

	# Try all possible starting positions
	for start in range(14):
		for end in range(start + 3, 14): # Minimum run length is 4
			if _is_valid_run_with_jokers(bitmap, start, end, use_num_jokers):
				var length = end - start + 1
				if length > best_length:
					var run = _build_run_from_range(involved_cards, start, end, bitmap, use_num_jokers)
					if run.has('success') and run['success']:
						best_run = run['run']
						best_length = length

	# Check special case for ace sequences
	if (bitmap & 0x0001) != 0 and (bitmap & 0x2000) != 0:
		var high_ace_start = 9 # Position of 10
		var high_ace_end = 13 # Position of high ace
		if _is_valid_run_with_jokers(bitmap, high_ace_start, high_ace_end, use_num_jokers):
			var length = high_ace_end - high_ace_start + 1
			if length > best_length:
				var run = _build_run_from_range(involved_cards, high_ace_start, high_ace_end, bitmap, use_num_jokers)
				if run.has('success') and run['success']:
					best_run = run['run']
					best_length = length

	if best_length >= 4:
		return {'success': true, 'run': best_run}

	return {'success': false}

func _is_valid_run_with_jokers(bitmap: int, start: int, end: int, use_num_jokers: int) -> bool:
	if start < 0 or end >= 14 or start >= end:
		return false

	var total_positions = end - start + 1
	if total_positions < 4:
		return false

	var set_bits = 0
	for i in range(start, end + 1):
		if (bitmap & (1 << i)) != 0:
			set_bits += 1

	var required_jokers = total_positions - set_bits
	return required_jokers == use_num_jokers

func _build_run_from_range(involved_cards: Dictionary, start: int, end: int, bitmap: int, use_num_jokers: int) -> Dictionary:
	if not _is_valid_run_with_jokers(bitmap, start, end, use_num_jokers):
		return {'success': false}

	var result = []
	for i in range(start, end + 1):
		var bit_pos = 1 << i
		if (bitmap & bit_pos) != 0:
			var rank = _pos_to_rank(bit_pos)
			if rank in involved_cards:
				result.append(involved_cards[rank])
			else:
				return {'success': false}
		else:
			result.append('JOKER')

	return {'success': true, 'run': result}

func _replace_jokers(run: Array, new_jokers: Array) -> Array:
	if len(new_jokers) == 0:
		return run

	var result = run.duplicate()
	var joker_idx = 0
	for i in range(len(result)):
		if result[i] == 'JOKER' and joker_idx < len(new_jokers):
			result[i] = new_jokers[joker_idx]
			joker_idx += 1
	return result

# Value lookup for run validation
var _value_lookup = {
	'JOKER': 15, 'A': 14, 'J': 11, 'Q': 12, 'K': 13,
	'2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9, '10': 10
}

func _is_valid_run(card_keys: Array) -> bool:
	var values = []
	var lowest_value = 15
	var lowest_value_idx = len(card_keys)

	for i in range(len(card_keys)):
		var card_key = card_keys[i]
		var parts = card_key.split('-')
		var rank = parts[0]
		var value = _value_lookup[rank]
		values.append(value)
		if value < lowest_value:
			lowest_value = value
			lowest_value_idx = i

	if lowest_value >= 14:
		return false

	# Check the front end
	for i in range(lowest_value_idx - 1, -1, -1):
		if values[i] == 15: # joker
			if values[i + 1] <= 1:
				return false
			values[i] = values[i + 1] - 1
		elif values[i] == 14: # ace
			if values[i + 1] != 2:
				return false
			values[i] = 1

	# Check the whole run as a sequence
	for i in range(1, len(card_keys)):
		if values[i] == 15: # joker
			if values[i - 1] >= 14:
				return false
			values[i] = values[i - 1] + 1
		elif values[i] == 14: # ace
			if values[i - 1] != 13:
				return false
			values[i] = values[i - 1] + 1

	return true

func _try_valid_run(card_key: String, already_used: Dictionary, card_keys: Array) -> Dictionary:
	# Check if all cards are available
	if already_used != null:
		if card_key in already_used:
			return {'success': false}
		for ck in card_keys:
			if ck in already_used:
				return {'success': false}

	# Try adding to front
	var new_run = [card_key] + card_keys
	if _is_valid_run(new_run):
		return {'success': true, 'run': new_run}

	# Try adding to back
	new_run = card_keys + [card_key]
	if _is_valid_run(new_run):
		return {'success': true, 'run': new_run}

	return {'success': false}

# A perfect winning hand, performed after drawing a card, is a hand that can be melded to win the round.
# (Rounds 1-6 required a discard, and round 7 requires no discard.)

################################################################################
## Player actions
################################################################################

func validate_current_player_turn(player_id: String):
	var player_infos = game_state.public_players_info.filter(func(pi): return pi.id == player_id)
	if len(player_infos) != 1:
		dbg("ERROR: validate_current_player_turn: could not find player_id='%s' in game_state" % [player_id])
		return null
	var player_info = player_infos[0]
	if player_info.turn_index != game_state.current_player_turn_index:
		# dbg("ERROR: validate_current_player_turn: player_id='%s' is not the current player (turn_index=%d)" %
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
		dbg("ERROR: server_allow_outstanding_buy_request: called on non-server peer")
		return
	var player_info = validate_current_player_turn(player_id)
	if not player_info:
		dbg("ERROR: server_allow_outstanding_buy_request: player_id='%s' is not the current player" %
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
		dbg("ERROR: server_discard_card: called on non-server peer")
		return
	var player_info = validate_current_player_turn(player_id)
	if not player_info:
		dbg("ERROR: server_discard_card: player_id='%s' is not the current player" % [player_id])
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
		dbg("ERROR: server_draw_card_from_discard_pile: called on non-server peer")
		return
	server_check_if_stock_pile_empty_and_reshuffle()
	var player_info = validate_current_player_turn(player_id)
	if not player_info:
		dbg("ERROR: server_draw_card_from_discard_pile: player_id='%s' is not the current player" % [player_id])
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
		dbg("ERROR: server_draw_card_from_stock_pile: called on non-server peer")
		return
	var player_info = validate_current_player_turn(player_id)
	if not player_info:
		dbg("ERROR: server_draw_card_from_stock_pile: player_id='%s' is not the current player" % [player_id])
		return
	if has_outstanding_buy_request():
		allow_outstanding_buy_request(player_id)
		# Now wait the grace period in case another player wishes to buy.
		# dbg("server_draw_card_from_stock_pile: waiting for grace period after allowing outstanding buy request")
		# await await_grace_period()
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
		dbg("ERROR: server_request_to_buy_card_from_discard_pile: called on non-server peer")
		return
	var player_info = validate_current_player_turn(player_id)
	if player_info:
		dbg("ERROR: server_request_to_buy_card_from_discard_pile: player_id='%s' IS the current player" % [player_id])
		return
	if len(discard_pile) == 0:
		dbg("ERROR: server_request_to_buy_card_from_discard_pile: discard pile is empty")
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
		dbg("ERROR: _rpc_give_top_discard_pile_card_to_player: discard pile is empty")
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
		dbg("ERROR: _rpc_give_top_stock_pile_card_to_player: stock pile is empty")
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
		dbg("ERROR: _rpc_move_player_card_to_discard_pile: unable to find card_key='%s' in playing_cards" % [card_key])
		return
	discard_pile.push_front(top_card)
	var player_is_me = private_player_info.id == player_id
	top_card.is_tappable = true
	top_card.is_draggable = false # player_is_me
	if player_is_me:
		private_player_info.card_keys_in_hand.erase(top_card.key)
	elif is_server():
		if player_id in bots_private_player_info:
			var bot = bots_private_player_info[player_id]
			bot.card_keys_in_hand.erase(top_card.key)
	dbg("_rpc_move_player_card_to_discard_pile: player_id='%s' moving card from discard pile: '%s', player_won=%s" % [player_id, top_card.key, player_won])
	animate_move_card_from_player_to_discard_pile_signal.emit(top_card, player_id, player_won, '_rpc_move_player_card_to_discard_pile')

func allow_player_to_buy_card_from_discard_pile(buying_player_id: String) -> void:
	if is_not_server():
		dbg("ERROR: allow_player_to_buy_card_from_discard_pile called on a client")
		return
	dbg("allow_player_to_buy_card_from_discard_pile: buying_player_id='%s'" % [buying_player_id])
	game_state.current_buy_request_player_ids = {} # clear all buy requests
	game_state_updated_signal.emit()
	register_ack_sync_state('_rpc_give_top_discard_pile_card_to_player', {'emit': 'deal_penalty_card_to_player', 'player_id': buying_player_id}) # not really an emit.
	_rpc_give_top_discard_pile_card_to_player.rpc(buying_player_id) # Do NOT advance to a new state.

func deal_penalty_card_to_player(buying_player_id: String) -> void:
	if is_not_server():
		dbg("ERROR: deal_penalty_card_to_player called on a client")
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
		dbg("ERROR: server_personally_meld_hand: called on non-server peer")
		return
	var player_info = validate_current_player_turn(player_id)
	if not player_info:
		dbg("ERROR: server_personally_meld_hand: player_id='%s' is not the current player" % [player_id])
		return
	dbg("server_personally_meld_hand: player_id='%s' discarding hand_evaluation=%s" % [player_id, hand_evaluation])
	var turn_index = player_info['turn_index']
	game_state.public_players_info[turn_index]['played_to_table'].append_array(hand_evaluation['can_be_personally_melded'])
	register_ack_sync_state('_rpc_personally_meld_cards_only') # stay within same state, {'next_state': 'NewDiscardState'})
	_rpc_personally_meld_cards_only.rpc(player_id, hand_evaluation)

@rpc('authority', 'call_local', 'reliable')
func _rpc_personally_meld_cards_only(player_id: String, hand_evaluation: Dictionary) -> void:
	dbg("received RPC _rpc_personally_meld_cards_only: player_id='%s'" % [player_id])
	# Move the playable cards from the player's hand to the table and then perform the animations.
	for meld_group in hand_evaluation['can_be_personally_melded']:
		_personally_meld_group(meld_group, player_id)
	# TODO: Make these separately-synced animations
	# for card_key in hand_evaluation['can_be_publicly_melded']:
	# 	_remove_card_from_player_hand(card_key, player_id)
	# if len(hand_evaluation['recommended_discards']) > 0:
	# 	var card_key = hand_evaluation['recommended_discards'][0]
	# 	var top_card = playing_cards.get(card_key) as PlayingCard
	# 	if not top_card:
	# 		dbg("ERROR: _rpc_personally_meld_cards_only: unable to find card_key='%s' in playing_cards" % [card_key])
	# 		return
	# 	discard_pile.push_front(top_card)
	# 	_remove_card_from_player_hand(card_key, player_id) # Discard the highest score card.
	animate_personally_meld_cards_only_signal.emit(player_id, hand_evaluation, '_rpc_personally_meld_cards_only')

func _remove_card_from_player_hand(card_key: String, player_id: String) -> void:
	dbg("_remove_card_from_player_hand: player_id='%s', card_key='%s'" % [player_id, card_key])
	var player_is_me = private_player_info.id == player_id
	if player_is_me:
		private_player_info.card_keys_in_hand.erase(card_key)
		dbg("_remove_card_from_player_hand: private_player_info.card_keys_in_hand (ME): %s" % [str(private_player_info.card_keys_in_hand)])
	elif is_server():
		if player_id in bots_private_player_info:
			var bot = bots_private_player_info[player_id]
			bot.card_keys_in_hand.erase(card_key)
			dbg("_remove_card_from_player_hand: bots_private_player_info[player_id].card_keys_in_hand (BOT): %s" % [str(bot.card_keys_in_hand)])

func _personally_meld_group(meld_group: Dictionary, player_id: String) -> void:
	dbg("_personally_meld_group: meld_group=%s, player_id='%s'" % [str(meld_group), player_id])
	var player_is_me = private_player_info.id == player_id
	if player_is_me:
		private_player_info.played_to_table.append(meld_group)
		dbg("_personally_meld_group: private_player_info.played_to_table (ME): %s" % [str(private_player_info.played_to_table)])
	elif is_server():
		if player_id in bots_private_player_info:
			var bot = bots_private_player_info[player_id]
			bot.played_to_table.append(meld_group)
			dbg("_personally_meld_group: bots_private_player_info[player_id].played_to_table (BOT): %s" % [str(bot.played_to_table)])
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
		dbg("ERROR: server_meld_card_to_public_meld: called on non-server peer")
		return
	var player_info = validate_current_player_turn(player_id)
	if not player_info:
		dbg("ERROR: server_meld_card_to_public_meld: player_id='%s' is not the current player" % [player_id])
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
		dbg("ERROR: SYNC: server_ack_sync_completed(peer_id=%d, operation_name='%s'): called on non-server peer" %
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
			dbg("ERROR: SYNC: server_ack_sync_completed(peer_id=%d, operation_name='%s'): unknown emit signal: %s" % [peer_id, operation_name, emit_signal_name])
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
		dbg("ERROR: send_transition_all_clients_state_to_signal('%s') called on a client" % new_state)
		return
	dbg("SYNC: send_transition_all_clients_state_to_signal('%s'): transitioning all clients to new state" % [new_state])
	transition_all_clients_state_to_signal.emit(new_state)

func register_ack_sync_state(operation_name: String, sync_args: Dictionary = {}) -> void:
	if is_not_server():
		dbg("ERROR: register_ack_sync_state('%s') called on a client: sync_args=%s" % [operation_name, str(sync_args)])
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
	# TODO: Handle empty pile by reshuffling.

func strip_deck_from_card_key(card_key: String) -> String:
	var parts = card_key.split('-')
	if parts[0] == "JOKER": return "JOKER" # Handle joker specially
	if len(parts) < 2: return parts[0] # For unexpected format
	return "%s-%s" % [parts[0], parts[1]] # Return the rank and suit, e.g., "A-hearts", "2-diamonds", etc.

func send_animate_winning_confetti_explosion_signal(num_millis: int) -> void:
	animate_winning_confetti_explosion_signal.emit(num_millis)

func await_grace_period() -> void:
	if len(discard_pile) == 0: return # no need to wait
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
	# 		dbg("ERROR! Card '%s' z_index mismatch: %d != %d" % [card.key, card.z_index, expected_z_index])
	# 	dbg("stock_pile[%d]: key='%s', z_index=%d, position=%s" % [card_idx, card.key, card.z_index, str(card.position)])
	ack_sync_completed('synchronize_all_stock_piles')

################################################################################
## DEBUG
################################################################################

func dbg(s: String) -> void:
	var my_peer_id = multiplayer.get_unique_id()
	var display_id = "(%10d)" % my_peer_id if my_peer_id != 1 else "(SERVER)    "
	print("%d: %s: %s" % [get_system_time_msec(), display_id, s])

func get_system_time_msec() -> int:
	return int(1000.0 * Time.get_unix_time_from_system())
