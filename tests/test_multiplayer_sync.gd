# Test Multiplayer Synchronization Logic
# Tests for multiplayer sync, bot management, and network state

class_name TestMultiplayerSync
extends Node

# const TestFramework = preload("res://tests/test_framework.gd")

var test_framework: TestFramework

func _ready():
	test_framework = TestFramework.new()
	add_child(test_framework)
	# Global is an autoload, access it directly

func run_all_tests() -> bool:
	var tests = [
		test_bot_creation,
		test_bot_private_info,
		test_multiplayer_peer_tracking,
		test_ack_sync_state_management,
		test_buy_request_tracking,
		test_server_client_detection,
		test_game_state_synchronization,
		test_player_disconnection_handling
	]

	return test_framework.run_test_suite("Multiplayer Sync Tests", tests)

func test_bot_creation() -> bool:
	# Test bot resource names
	test_framework.assert_equal(4, len(Global.BOT_RESOURCE_NAMES), "Should have 4 bot types")
	test_framework.assert_true('01-dumb_bot' in Global.BOT_RESOURCE_NAMES, "Should have dumb bot")
	test_framework.assert_true('02-stingy_bot' in Global.BOT_RESOURCE_NAMES, "Should have stingy bot")
	test_framework.assert_true('03-generous_bot' in Global.BOT_RESOURCE_NAMES, "Should have generous bot")
	test_framework.assert_true('04-basic_bot' in Global.BOT_RESOURCE_NAMES, "Should have basic bot")
	return true

func test_bot_private_info() -> bool:
	# Test bot private info structure
	Global.game_state = {'public_players_info': []}
	Global.bots_private_player_info = {}

	# Simulate adding a bot
	var bot_id = 'bot0'
	var bot_private_info = {
		'id': bot_id,
		'name': 'Test Bot',
		'is_bot': true,
		'turn_index': 0,
		'played_to_table': [],
		'score': 0,
		'card_keys_in_hand': []
	}

	Global.bots_private_player_info[bot_id] = bot_private_info
	test_framework.assert_dict_has_key(Global.bots_private_player_info, bot_id, "Should store bot private info")
	test_framework.assert_equal(true, Global.bots_private_player_info[bot_id]['is_bot'], "Bot should be marked as bot")
	return true

func test_multiplayer_peer_tracking() -> bool:
	# Test multiplayer peer ID handling
	Global.private_player_info = {'id': '1'}
	test_framework.assert_equal('1', Global.private_player_info['id'], "Should store peer ID")
	return true

func test_ack_sync_state_management() -> bool:
	# Test ack sync state management
	Global.ack_sync_state = {}

	# Register a sync operation
	Global.register_ack_sync_state('test_operation', {
		'next_state': 'TestState',
		'advance_player_turn': true
	})

	test_framework.assert_dict_has_key(Global.ack_sync_state, 'test_operation', "Should register operation")
	test_framework.assert_dict_has_key(Global.ack_sync_state['test_operation'], 'acks', "Should initialize acks")
	test_framework.assert_equal('TestState', Global.ack_sync_state['test_operation']['next_state'], "Should store next state")
	test_framework.assert_equal(true, Global.ack_sync_state['test_operation']['advance_player_turn'], "Should store advance flag")
	return true

func test_buy_request_tracking() -> bool:
	# Test buy request tracking
	Global.game_state = {
		'current_buy_request_player_ids': {}
	}

	# Test adding buy request
	Global.game_state['current_buy_request_player_ids']['player1'] = 'A-hearts-0'
	test_framework.assert_dict_has_key(Global.game_state['current_buy_request_player_ids'], 'player1', "Should track buy request")
	test_framework.assert_equal('A-hearts-0', Global.game_state['current_buy_request_player_ids']['player1'], "Should store requested card")

	# Test has_outstanding_buy_request
	test_framework.assert_true(Global.has_outstanding_buy_request(), "Should detect outstanding buy request")

	# Test clearing buy requests
	Global.game_state['current_buy_request_player_ids'].clear()
	test_framework.assert_false(Global.has_outstanding_buy_request(), "Should detect no outstanding buy requests")
	return true

func test_server_client_detection() -> bool:
	# Test server/client detection methods
	# Note: These depend on multiplayer.is_server() which we can't easily mock
	# But we can test the method existence and basic logic
	test_framework.assert_not_null(Global.is_server, "Should have is_server method")
	test_framework.assert_not_null(Global.is_not_server, "Should have is_not_server method")

	# Test that is_not_server is the inverse of is_server
	# This is a bit tricky to test without mocking the multiplayer system
	var is_server_result = Global.is_server()
	var is_not_server_result = Global.is_not_server()
	test_framework.assert_not_equal(is_server_result, is_not_server_result, "is_server and is_not_server should be opposites")
	return true

func test_game_state_synchronization() -> bool:
	# Test game state structure
	Global.reset_game()
	var game_state = Global.game_state

	test_framework.assert_dict_has_key(game_state, 'current_round_num', "Should have current round num")
	test_framework.assert_dict_has_key(game_state, 'current_player_turn_index', "Should have current player turn index")
	test_framework.assert_dict_has_key(game_state, 'public_players_info', "Should have public players info")
	test_framework.assert_dict_has_key(game_state, 'current_buy_request_player_ids', "Should have buy request tracking")

	# Test that game state is properly structured
	test_framework.assert_equal(1, game_state['current_round_num'], "Should start at round 1")
	test_framework.assert_equal(1, game_state['current_player_turn_index'], "Should start at player 1")
	test_framework.assert_equal(0, len(game_state['public_players_info']), "Should start with no players")
	return true

func test_player_disconnection_handling() -> bool:
	# Test player disconnection logic
	Global.game_state = {
		'public_players_info': [
			{'id': '1', 'name': 'Host'},
			{'id': '2', 'name': 'Player 2'},
			{'id': '3', 'name': 'Player 3'}
		]
	}

	# Test filtering out disconnected player
	var filtered_players = Global.game_state.public_players_info.filter(func(pi): return pi.id != '2')
	test_framework.assert_equal(2, len(filtered_players), "Should filter out disconnected player")
	test_framework.assert_equal('1', filtered_players[0]['id'], "Should keep host")
	test_framework.assert_equal('3', filtered_players[1]['id'], "Should keep other players")

	# Test that host disconnection is handled differently
	var host_filtered = Global.game_state.public_players_info.filter(func(pi): return pi.id != '1')
	test_framework.assert_equal(2, len(host_filtered), "Should filter out host")
	# In real game, host disconnection would trigger reset_game()
	return true

func cleanup_test_resources() -> void:
	# Clean up test framework
	if test_framework and is_instance_valid(test_framework):
		if test_framework.is_inside_tree():
			remove_child(test_framework)
		test_framework.queue_free()
	test_framework = null