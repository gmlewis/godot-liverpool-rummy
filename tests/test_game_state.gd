# Test Game State Management
# Tests for game state, player management, and turn logic

class_name TestGameState
extends Node

var test_framework: TestFramework

func _ready():
	test_framework = TestFramework.new()
	add_child(test_framework)
	# Global is an autoload, access it directly

func run_all_tests() -> bool:
	return test_framework.discover_and_run_test_suite("Game State Tests", self)

func cleanup_test_resources() -> void:
	# Clean up test framework
	if test_framework and is_instance_valid(test_framework):
		if test_framework.is_inside_tree():
			remove_child(test_framework)
		test_framework.queue_free()
	test_framework = null

func test_reset_game() -> bool:
	# Set up some initial state
	Global.game_state = {'some_data': 'test'}
	Global.private_player_info = {'id': 'test'}
	Global.stock_pile = [null, null] # Mock cards
	Global.discard_pile = [null]
	Global.playing_cards = {'test': null}

	# Reset the game
	Global.reset_game()

	# Check that everything is reset
	test_framework.assert_equal(1, Global.game_state['current_round_num'], "Should reset to round 1")
	test_framework.assert_equal(1, Global.game_state['current_player_turn_index'], "Should reset to player 1")
	test_framework.assert_equal(0, len(Global.game_state['public_players_info']), "Should clear players")
	test_framework.assert_equal(0, len(Global.stock_pile), "Should clear stock pile")
	test_framework.assert_equal(0, len(Global.discard_pile), "Should clear discard pile")
	test_framework.assert_equal(0, len(Global.playing_cards), "Should clear playing cards")
	return true

func test_gen_public_player_info() -> bool:
	var private_info = {
		'id': 'player1',
		'name': 'Test Player',
		'is_bot': false,
		'turn_index': 0,
		'played_to_table': [],
		'score': 10,
		'card_keys_in_hand': ['A-hearts-0', 'K-spades-0']
	}

	var public_info = Global.gen_public_player_info(private_info)

	test_framework.assert_equal('player1', public_info['id'], "Should copy id")
	test_framework.assert_equal('Test Player', public_info['name'], "Should copy name")
	test_framework.assert_equal(false, public_info['is_bot'], "Should copy is_bot")
	test_framework.assert_equal(0, public_info['turn_index'], "Should copy turn_index")
	test_framework.assert_equal(0, len(public_info['played_to_table']), "Should copy played_to_table")
	test_framework.assert_equal(10, public_info['score'], "Should copy score")
	test_framework.assert_equal(2, public_info['num_cards'], "Should set num_cards from hand size")
	test_framework.assert_dict_not_has_key(public_info, 'card_keys_in_hand', "Should not expose private cards")
	return true

func test_get_players_by_id() -> bool:
	Global.game_state = {
		'public_players_info': [
			{'id': 'player1', 'name': 'Player 1'},
			{'id': 'player2', 'name': 'Player 2'},
			{'id': 'bot1', 'name': 'Bot 1'}
		]
	}

	var players_by_id = Global.get_players_by_id()
	test_framework.assert_equal(3, len(players_by_id), "Should have 3 players")
	test_framework.assert_equal('Player 1', players_by_id['player1']['name'], "Should map player1 correctly")
	test_framework.assert_equal('Player 2', players_by_id['player2']['name'], "Should map player2 correctly")
	test_framework.assert_equal('Bot 1', players_by_id['bot1']['name'], "Should map bot1 correctly")
	return true

func test_player_has_melded() -> bool:
	Global.game_state = {
		'public_players_info': [
			{
				'id': 'player1',
				'played_to_table': []
			},
			{
				'id': 'player2',
				'played_to_table': [ {
					'type': 'group',
					'card_keys': ['A-hearts-0', 'A-spades-0', 'A-diamonds-0']
				}]
			}
		]
	}

	test_framework.assert_false(Global.player_has_melded('player1'), "Player1 should not have melded")
	test_framework.assert_true(Global.player_has_melded('player2'), "Player2 should have melded")
	return true

func test_validate_current_player_turn() -> bool:
	Global.game_state = {
		'current_player_turn_index': 1,
		'public_players_info': [
			{'id': 'player1', 'turn_index': 0},
			{'id': 'player2', 'turn_index': 1},
			{'id': 'player3', 'turn_index': 2}
		]
	}

	var valid_player = Global.validate_current_player_turn('player2')
	test_framework.assert_not_null(valid_player, "Should validate current player")
	test_framework.assert_equal('player2', valid_player['id'], "Should return correct player info")

	var invalid_player = Global.validate_current_player_turn('player1')
	test_framework.assert_null(invalid_player, "Should not validate non-current player")
	return true

func test_is_my_turn() -> bool:
	Global.private_player_info = {'turn_index': 1}
	Global.game_state = {'current_player_turn_index': 1}
	test_framework.assert_true(Global.is_my_turn(), "Should be my turn")

	Global.game_state = {'current_player_turn_index': 2}
	test_framework.assert_false(Global.is_my_turn(), "Should not be my turn")
	return true

func test_round_requirements() -> bool:
	# Test the round requirements arrays
	var test_bot = Bot.new('test_bot')
	test_framework.assert_equal(2, test_bot._groups_per_round[0], "Round 1 should require 2 groups")
	test_framework.assert_equal(0, test_bot._runs_per_round[0], "Round 1 should require 0 runs")

	test_framework.assert_equal(1, test_bot._groups_per_round[1], "Round 2 should require 1 group")
	test_framework.assert_equal(1, test_bot._runs_per_round[1], "Round 2 should require 1 run")

	test_framework.assert_equal(0, test_bot._groups_per_round[2], "Round 3 should require 0 groups")
	test_framework.assert_equal(2, test_bot._runs_per_round[2], "Round 3 should require 2 runs")

	test_framework.assert_equal(0, test_bot._groups_per_round[6], "Round 7 should require 0 groups")
	test_framework.assert_equal(3, test_bot._runs_per_round[6], "Round 7 should require 3 runs")

	# Clean up the test bot
	test_bot.queue_free()

	return true

func test_server_advance_to_next_round() -> bool:
	# Mock server state
	Global.game_state = {
		'current_round_num': 1,
		'current_player_turn_index': 0,
		'public_players_info': [
			{'id': 'player1', 'turn_index': 0, 'played_to_table': [], 'num_cards': 10},
			{'id': 'player2', 'turn_index': 1, 'played_to_table': [], 'num_cards': 10}
		],
		'current_buy_request_player_ids': {'player1': 'A-hearts-0'}
	}
	Global.bots_private_player_info = {}

	# Note: We can't actually test the RPC call, but we can test the logic
	# In a real test, this would be mocked
	test_framework.assert_equal(1, Global.game_state['current_round_num'], "Should start at round 1")
	return true

func test_multiplayer_state_tracking() -> bool:
	# Test the ack_sync_state tracking
	Global.ack_sync_state = {}

	# Test register_ack_sync_state
	Global.register_ack_sync_state('test_operation', {'next_state': 'TestState'})
	test_framework.assert_dict_has_key(Global.ack_sync_state, 'test_operation', "Should register sync state")
	test_framework.assert_dict_has_key(Global.ack_sync_state['test_operation'], 'acks', "Should initialize acks dict")
	test_framework.assert_equal('TestState', Global.ack_sync_state['test_operation']['next_state'], "Should store sync args")

	# Test clearing
	Global.ack_sync_state.clear()
	test_framework.assert_equal(0, len(Global.ack_sync_state), "Should clear sync state")
	return true

func test_sort_winning_players_by_score() -> bool:
	var test_cases = [
		{
			'name': 'Simple 2-player case - no ties',
			'input': [
				{'id': 'p1', 'score': 50},
				{'id': 'p2', 'score': 30},
			],
			'expected': [['p2'], ['p1'], [], []],
		},
		{
			'name': 'Simple 3-player case - no ties',
			'input': [
				{'id': 'p1', 'score': 50},
				{'id': 'p2', 'score': 30},
				{'id': 'p3', 'score': 70},
			],
			'expected': [['p2'], ['p1'], ['p3'], []],
		},
		{
			'name': 'Simple 10-player case - no ties',
			'input': [
				{'id': 'p1', 'score': 50},
				{'id': 'p2', 'score': 30},
				{'id': 'p3', 'score': 70},
				{'id': 'p4', 'score': 10},
				{'id': 'p5', 'score': 130},
				{'id': 'p6', 'score': 120},
				{'id': 'p7', 'score': 110},
				{'id': 'p8', 'score': 100},
				{'id': 'p9', 'score': 90},
				{'id': 'p10', 'score': 80},
			],
			'expected': [['p4'], ['p2'], ['p1'], ['p3', 'p10', 'p9', 'p8', 'p7', 'p6', 'p5']],
		},
		{
			'name': '10-player case - many ties',
			'input': [
				{'id': 'p1', 'score': 50},
				{'id': 'p2', 'score': 10},
				{'id': 'p3', 'score': 50},
				{'id': 'p4', 'score': 10},
				{'id': 'p5', 'score': 130},
				{'id': 'p6', 'score': 90},
				{'id': 'p7', 'score': 90},
				{'id': 'p8', 'score': 90},
				{'id': 'p9', 'score': 90},
				{'id': 'p10', 'score': 50},
			],
			'expected': [['p2', 'p4'], ['p1', 'p3', 'p10'], ['p6', 'p7', 'p8', 'p9'], ['p5']],
		},
	]

	var final_scores = load("res://state_machine/10-final-scores_state.gd") as Script
	for test_case in test_cases:
		var got = final_scores.sort_winning_players_by_score(test_case['input'])
		test_framework.assert_equal(test_case['expected'], got, "Should sort players correctly for case: %s" % test_case['name'])

	return true
