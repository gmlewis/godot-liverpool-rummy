class_name TestBots
extends Node

var test_bot: Bot

var test_framework: TestFramework

# Mock game state for testing
var mock_game_state: Dictionary
var mock_private_player_info: Dictionary

func _ready():
	test_framework = TestFramework.new()
	add_child(test_framework)
	test_bot = Bot.new("test_bot")
	add_child(test_bot)
	# Global is an autoload, access it directly
	setup_mock_data()

func setup_mock_data():
	# Create mock game state
	mock_game_state = {
		'current_round_num': 1,
		'current_player_turn_index': 0,
		'public_players_info': [
			{
				'id': 'player1',
				'name': 'Test Player 1',
				'is_bot': false,
				'turn_index': 0,
				'played_to_table': [],
				'score': 0,
				'num_cards': 13
			},
			{
				'id': 'player2',
				'name': 'Test Player 2',
				'is_bot': false,
				'turn_index': 1,
				'played_to_table': [ {
					'type': 'group',
					'card_keys': ['A-hearts-0', 'A-diamonds-0', 'A-clubs-0']
				}],
				'score': 0,
				'num_cards': 10
			},
			{
				'id': 'test_bot',
				'name': 'TestBot',
				'is_bot': true,
				'turn_index': 2,
				'played_to_table': [],
				'score': 0,
				'num_cards': 10
			},
		],
		'current_buy_request_player_ids': {}
	}

	# Set up the global instance with mock data
	Global.game_state = mock_game_state

func run_all_tests() -> bool:
	return test_framework.discover_and_run_test_suite("Bots Tests", self)

func cleanup_test_resources() -> void:
	# Clean up test bot and any other resources
	if test_bot and is_instance_valid(test_bot):
		if test_bot.is_inside_tree():
			remove_child(test_bot)
		test_bot.queue_free()
	test_bot = null

	# Clean up test framework
	if test_framework and is_instance_valid(test_framework):
		if test_framework.is_inside_tree():
			remove_child(test_framework)
		test_framework.queue_free()
	test_framework = null

func test_gen_hand_stats_basic() -> bool:
	var cards = ["A-hearts-0", "A-spades-0", "K-hearts-0", "2-hearts-0"]
	var stats = test_bot.gen_bot_hand_stats(cards)

	test_framework.assert_equal(4, stats['num_cards'], "Should have 4 cards")
	test_framework.assert_dict_has_key(stats, 'by_rank', "Should have by_rank")
	test_framework.assert_dict_has_key(stats, 'by_suit', "Should have by_suit")
	test_framework.assert_equal(2, len(stats['by_rank']['A']), "Should have 2 Aces")
	test_framework.assert_equal(3, len(stats['by_suit']['hearts']), "Should have 3 hearts")
	return true

func test_gen_hand_stats_with_jokers() -> bool:
	var cards = ["JOKER-1-0", "JOKER-2-0", "A-hearts-0"]
	var stats = test_bot.gen_bot_hand_stats(cards)

	test_framework.assert_equal(2, len(stats['jokers']), "Should have 2 jokers")
	test_framework.assert_equal(1, len(stats['by_rank']['A']), "Should have 1 Ace")
	return true

func test_gen_hand_stats_groups() -> bool:
	var cards = ["A-hearts-0", "A-spades-0", "A-diamonds-0", "K-hearts-0", "K-spades-0"]
	var stats = test_bot.gen_bot_hand_stats(cards)

	test_framework.assert_equal(1, len(stats['groups_of_3_plus']), "Should have 1 group of 3+")
	test_framework.assert_equal(1, len(stats['groups_of_2']), "Should have 1 group of 2")
	test_framework.assert_equal(3, len(stats['groups_of_3_plus'][0]), "First group should have 3 cards")
	return true

func test_gen_hand_stats_runs() -> bool:
	var cards = ["A-hearts-0", "2-hearts-0", "3-hearts-0", "4-hearts-0", "5-hearts-0"]
	var stats = test_bot.gen_bot_hand_stats(cards)

	test_framework.assert_equal(1, len(stats['runs_of_4_plus']), "Should have 1 run of 4+")
	test_framework.assert_equal(5, len(stats['runs_of_4_plus'][0]), "Run should have 5 cards")
	return true

func test_evaluate_hand_pre_meld_round1() -> bool:
	# Round 1 requires 2 groups
	var cards = ["A-hearts-0", "A-spades-0", "A-diamonds-0", "K-hearts-0", "K-spades-0", "K-diamonds-0", "2-hearts-0"]
	var hand_stats = test_bot.gen_bot_hand_stats(cards)
	var _all_public_meld_stats = Global._gen_all_public_meld_stats()
	var evaluation = test_bot._evaluate_hand_pre_meld(1, hand_stats, _all_public_meld_stats)

	test_framework.assert_equal(2, len(evaluation['can_be_personally_melded']), "Should be able to meld 2 groups")
	test_framework.assert_true(evaluation['eval_score'] > 0, "Should have positive evaluation score")
	return true

func test_evaluate_hand_pre_meld_round2() -> bool:
	Global.game_state['current_round_num'] = 2
	# Round 2 requires 1 group + 1 run
	var cards = ["A-hearts-0", "A-spades-0", "A-diamonds-0", "2-hearts-0", "3-hearts-0", "4-hearts-0", "5-hearts-0", "6-hearts-0"]
	var hand_stats = test_bot.gen_bot_hand_stats(cards)
	var _all_public_meld_stats = Global._gen_all_public_meld_stats()
	var evaluation = test_bot._evaluate_hand_pre_meld(2, hand_stats, _all_public_meld_stats)

	test_framework.assert_equal(2, len(evaluation['can_be_personally_melded']), "Should be able to meld 1 group + 1 run")
	# Check that we have one group and one run
	var has_group = false
	var has_run = false
	for meld in evaluation['can_be_personally_melded']:
		if meld['type'] == 'group':
			has_group = true
		if meld['type'] == 'run':
			has_run = true
	test_framework.assert_true(has_group, "Should have a group")
	test_framework.assert_true(has_run, "Should have a run")
	Global.game_state['current_round_num'] = 1 # Reset
	return true

func test_evaluate_hand_post_meld() -> bool:
	# Test post-meld evaluation with some cards that can be publicly melded
	var cards = ["A-spades-0", "2-hearts-0", "3-hearts-0"]
	var hand_stats = test_bot.gen_bot_hand_stats(cards)
	var _all_public_meld_stats = Global._gen_all_public_meld_stats()
	var evaluation = test_bot._evaluate_hand_post_meld(1, hand_stats, _all_public_meld_stats)

	test_framework.assert_dict_has_key(evaluation, 'can_be_publicly_melded', "Should have can_be_publicly_melded")
	test_framework.assert_dict_has_key(evaluation, 'recommended_discards', "Should have recommended_discards")
	return true

func test_find_groups_can_be_publicly_melded() -> bool:
	var hand_stats = {
		'by_rank': {
			'A': ['A-clubs-0']
		}
	}
	var all_public_meld_stats = {
		'by_rank': {
			'A': [ {
				'player_id': 'player2',
				'meld_group_index': 0,
				'meld_group_type': 'group'
			}]
		}
	}

	var result = test_bot._find_groups_can_be_publicly_melded(hand_stats, all_public_meld_stats)
	test_framework.assert_dict_has_key(result, 'A', "Should find Ace can be publicly melded")
	return true

func test_find_runs_can_be_publicly_melded() -> bool:
	var hand_stats = {
		'by_suit': {
			'hearts': {
				'6': ['6-hearts-0']
			}
		}
	}
	var all_public_meld_stats = {
		'by_suit': {
			'hearts': {
				'A': [ {
					'player_id': 'player2',
					'meld_group_index': 0,
					'meld_group_type': 'run'
				}]
			}
		}
	}

	var result = test_bot._find_runs_can_be_publicly_melded(hand_stats, {}, all_public_meld_stats)
	test_framework.assert_not_null(result, "Should return a result")
	return true

func test_is_publicly_meldable_groups() -> bool:
	var all_public_meld_stats = {
		'by_rank': {
			'A': [ {
				'meld_group_type': 'group'
			}]
		},
		'by_suit': {}
	}

	var result = test_bot._is_publicly_meldable('A', 'A-hearts-0', all_public_meld_stats)
	test_framework.assert_true(result, "Ace should be publicly meldable to group")
	return true

func test_is_publicly_meldable_runs() -> bool:
	# This is a more complex test - we need to mock the game state properly
	var all_public_meld_stats = {
		'by_rank': {},
		'by_suit': {
			'hearts': {
				'A': [ {
					'player_id': 'player2',
					'meld_group_index': 0,
					'meld_group_type': 'run'
				}]
			}
		}
	}

	var result = test_bot._is_publicly_meldable('6', '6-hearts-0', all_public_meld_stats)
	# This may be false because the helper functions need proper game state
	test_framework.assert_not_null(result, "Should return a boolean result")
	return true

func test_can_card_extend_run() -> bool:
	# This requires proper game state setup
	var pub_meld = {
		'player_id': 'player2',
		'meld_group_index': 0
	}

	var result = test_bot._can_card_extend_run('6-hearts-0', pub_meld)
	test_framework.assert_not_null(result, "Should return a boolean result")
	return true

func test_can_card_replace_joker_in_run() -> bool:
	# This requires proper game state setup
	var pub_meld = {
		'player_id': 'player2',
		'meld_group_index': 0
	}

	var result = test_bot._can_card_replace_joker_in_run('6-hearts-0', pub_meld)
	test_framework.assert_not_null(result, "Should return a boolean result")
	return true

func test_is_valid_run() -> bool:
	var valid_run = ['A-hearts-0', '2-hearts-0', '3-hearts-0', '4-hearts-0']
	var invalid_run = ['A-hearts-0', '3-hearts-0', '5-hearts-0', '7-hearts-0']

	# Test basic valid and invalid runs
	test_framework.assert_true(Global.is_valid_run(valid_run), "A-2-3-4 of hearts should be valid")
	test_framework.assert_false(Global.is_valid_run(invalid_run), "A-3-5-7 of hearts should be invalid")

	# Test runs with jokers
	var valid_run_with_joker = ['2-hearts-0', '3-hearts-0', 'JOKER-1-0', '5-hearts-0', '6-hearts-0']
	var invalid_run_with_joker = ['2-hearts-0', '3-hearts-0', 'JOKER-1-0', '6-hearts-0', '7-hearts-0']
	var invalid_run_too_short = ['2-hearts-0', '3-hearts-0', 'JOKER-1-0']

	test_framework.assert_true(Global.is_valid_run(valid_run_with_joker), "2-3-JOKER-5-6 should be valid (joker fills the 4)")
	test_framework.assert_false(Global.is_valid_run(invalid_run_with_joker), "2-3-JOKER-6-7 should be invalid (joker can only fill 1 gap, but 2 gaps exist)")
	test_framework.assert_false(Global.is_valid_run(invalid_run_too_short), "2-3-JOKER should be invalid (runs must be at least 4 cards)")

	return true

func test_rank_to_bitmap() -> bool:
	test_framework.assert_equal(0x0001 | 0x2000, test_bot._rank_to_bitmap('A'), "Ace should have both low and high bits")
	test_framework.assert_equal(0x0002, test_bot._rank_to_bitmap('2'), "Two should have bit 1")
	test_framework.assert_equal(0x1000, test_bot._rank_to_bitmap('K'), "King should have bit 12")
	return true

func test_build_run_with_jokers() -> bool:
	# Test building runs with jokers
	var available_jokers = ['JOKER-1-0']
	var already_used = {}
	var by_rank = {
		'A': ['A-hearts-0'],
		'3': ['3-hearts-0'],
		'4': ['4-hearts-0']
	}

	var result = test_bot._build_a_run_with_suit(available_jokers, already_used, by_rank, 1)
	test_framework.assert_dict_has_key(result, 'success', "Should have success key")
	return true

# Test bot hand evaluation with the new logic for leaving cards to discard
func test_bot_evaluation_leaves_discard_round1() -> bool:
	# Round 1: bot has cards that can be fully melded, should leave one for discard
	var cards = ["A-hearts-0", "A-spades-0", "A-diamonds-0", "K-hearts-0", "K-spades-0", "K-diamonds-0", "2-hearts-0"]
	var hand_stats = test_bot.gen_bot_hand_stats(cards)
	var evaluation = test_bot.evaluate_bot_hand(hand_stats, "test_bot")

	test_framework.assert_equal(1, len(evaluation['recommended_discards']), "Should leave exactly 1 card to discard in round 1")
	test_framework.assert_equal(2, len(evaluation['can_be_personally_melded']), "Should meld 2 groups")
	test_framework.assert_true(evaluation['is_winning_hand'], "Should be winning hand")
	return true

func test_bot_evaluation_leaves_discard_round2() -> bool:
	# Round 2: bot has cards that can be fully melded, should leave one for discard
	Global.game_state['current_round_num'] = 2
	var cards = ["A-hearts-0", "A-spades-0", "A-diamonds-0", "2-hearts-0", "3-hearts-0", "4-hearts-0", "5-hearts-0", "6-hearts-0"]
	var hand_stats = test_bot.gen_bot_hand_stats(cards)
	var evaluation = test_bot.evaluate_bot_hand(hand_stats, "test_bot")

	test_framework.assert_equal(1, len(evaluation['recommended_discards']), "Should leave exactly 1 card to discard in round 2")
	test_framework.assert_true(evaluation['is_winning_hand'], "Should be winning hand")
	Global.game_state['current_round_num'] = 1 # Reset
	return true

func test_bot_evaluation_full_meld_round7() -> bool:
	# Round 7: bot can meld all 13 cards into 3 runs
	Global.game_state['current_round_num'] = 7
	var cards = ["A-hearts-0", "2-hearts-0", "3-hearts-0", "4-hearts-0", "5-diamonds-0", "6-diamonds-0", "7-diamonds-0", "8-diamonds-0", "9-diamonds-0", "10-clubs-0", "J-clubs-0", "Q-clubs-0", "K-clubs-0"]
	var hand_stats = test_bot.gen_bot_hand_stats(cards)
	var evaluation = test_bot.evaluate_bot_hand(hand_stats, "test_bot")

	test_framework.assert_equal(0, len(evaluation['recommended_discards']), "Should have no cards to discard in round 7")
	test_framework.assert_true(evaluation['is_winning_hand'], "Should be winning hand")
	Global.game_state['current_round_num'] = 1 # Reset
	return true

func test_bot_evaluation_prevents_invalid_meld_round1() -> bool:
	# Round 1: bot has only 1 group, should not be able to meld
	var cards = ["A-hearts-0", "A-spades-0", "A-diamonds-0", "2-hearts-0", "5-clubs-0", "6-clubs-0", "9-diamonds-0"]
	var hand_stats = test_bot.gen_bot_hand_stats(cards)
	var evaluation = test_bot.evaluate_bot_hand(hand_stats, "test_bot")

	test_framework.assert_equal(0, len(evaluation['can_be_personally_melded']), "Should not be able to meld with only 1 group in round 1")
	return true

func test_bot_evaluation_with_partial_melds() -> bool:
	# Test with cards that can't be fully melded
	var cards = ["A-hearts-0", "A-spades-0", "K-hearts-0", "2-hearts-0", "3-hearts-0", "6-clubs-0", "9-diamonds-0"]
	var hand_stats = test_bot.gen_bot_hand_stats(cards)
	var evaluation = test_bot.evaluate_bot_hand(hand_stats, "test_bot")

	test_framework.assert_equal(0, len(evaluation['can_be_personally_melded']), "Should not be able to fully meld")
	test_framework.assert_true(len(evaluation['recommended_discards']) > 0, "Should have cards to discard")
	test_framework.assert_false(evaluation['is_winning_hand'], "Should not be winning hand")
	return true

func test_meld_validity() -> bool:
	# Test that melds in can_be_personally_melded are valid
	var cards = ["A-hearts-0", "A-spades-0", "A-diamonds-0", "K-hearts-0", "K-spades-0", "K-diamonds-0", "2-hearts-0"]
	var hand_stats = test_bot.gen_bot_hand_stats(cards)
	var evaluation = test_bot.evaluate_bot_hand(hand_stats, "test_bot")

	for meld in evaluation['can_be_personally_melded']:
		var card_keys = meld['card_keys']
		if meld['type'] == 'group':
			test_framework.assert_true(len(card_keys) >= 3, "Groups must have at least 3 cards")
			var parts = card_keys[0].split('-')
			var rank = parts[0]
			for card_key in card_keys:
				var parts2 = card_key.split('-')
				var rank2 = parts2[0]
				test_framework.assert_equal(rank, rank2, "All cards in group must have same rank")
		elif meld['type'] == 'run':
			test_framework.assert_true(len(card_keys) >= 4, "Runs must have at least 4 cards")
			test_framework.assert_true(Global.is_valid_run(card_keys), "Run must be valid sequence")
	return true

var bot_test_scenarios = [
	# Don't test eval_score in this suite of tests.
	{
		'name': 'Basic 2 Groups Meld Round 1',
		'round': 1,
		'cards': ["A-hearts-0", "A-spades-0", "A-diamonds-0", "K-hearts-0", "K-spades-0", "K-diamonds-0", "2-clubs-0"],
		'want_evaluation': {
			'can_be_personally_melded': [
				{"type": "group", "card_keys": ["A-hearts-0", "A-spades-0", "A-diamonds-0"]},
				{"type": "group", "card_keys": ["K-hearts-0", "K-spades-0", "K-diamonds-0"]},
			],
			'can_be_publicly_melded': [],
			'is_winning_hand': true,
			'recommended_discards': ["2-clubs-0"],
		},
	},
	{
		'name': 'All Jokers Meld Round 1',
		'round': 1,
		'cards': ["JOKER-1-0", "JOKER-2-0", "JOKER-1-1", "JOKER-2-1", "JOKER-1-2", "JOKER-2-2", "JOKER-1-3"],
		'want_evaluation': {
			'can_be_personally_melded': [
				{"type": "group", "card_keys": ["JOKER-1-0", "JOKER-2-0", "JOKER-1-1"]},
				{"type": "group", "card_keys": ["JOKER-2-1", "JOKER-1-2", "JOKER-2-2"]},
			],
			'can_be_publicly_melded': [],
			'is_winning_hand': true,
			'recommended_discards': ["JOKER-1-3"],
		},
	},
	{
		'name': 'Basic Group+Run Meld Round 2',
		'round': 2,
		'cards': ["A-hearts-0", "A-spades-0", "A-diamonds-0", "4-hearts-0", "5-hearts-0", "6-hearts-0", "7-hearts-0", "2-clubs-0"],
		'want_evaluation': {
			'can_be_personally_melded': [
				{"type": "group", "card_keys": ["A-hearts-0", "A-spades-0", "A-diamonds-0"]},
				{"type": "run", "card_keys": ["4-hearts-0", "5-hearts-0", "6-hearts-0", "7-hearts-0"]},
			],
			'can_be_publicly_melded': [],
			'is_winning_hand': true,
			'recommended_discards': ["2-clubs-0"],
		},
	},
	{
		'name': 'All Jokers Meld Round 2',
		'round': 2,
		'cards': ["JOKER-1-0", "JOKER-2-0", "JOKER-1-1", "JOKER-2-1", "JOKER-1-2", "JOKER-2-2", "JOKER-1-3", "JOKER-2-3"],
		'want_evaluation': {
			'can_be_personally_melded': [
				{"type": "group", "card_keys": ["JOKER-1-0", "JOKER-2-0", "JOKER-1-1"]},
				{"type": "run", "card_keys": ["JOKER-2-1", "JOKER-1-2", "JOKER-2-2", "JOKER-1-3"]},
			],
			'can_be_publicly_melded': [],
			'is_winning_hand': true,
			'recommended_discards': ["JOKER-2-3"],
		},
	},
	{
		'name': 'Basic 2 Runs Meld Round 3',
		'round': 3,
		'cards': ["A-clubs-0", "2-clubs-0", "3-clubs-0", "4-clubs-0", "4-hearts-0", "5-hearts-0", "6-hearts-0", "7-hearts-0", "2-spades-0"],
		'want_evaluation': {
			'can_be_personally_melded': [
				{"type": "run", "card_keys": ["A-clubs-0", "2-clubs-0", "3-clubs-0", "4-clubs-0"]},
				{"type": "run", "card_keys": ["4-hearts-0", "5-hearts-0", "6-hearts-0", "7-hearts-0"]},
			],
			'can_be_publicly_melded': [],
			'is_winning_hand': true,
			'recommended_discards': ["2-spades-0"],
		},
	},
	{
		'name': 'All Jokers Meld Round 3',
		'round': 3,
		'cards': ["JOKER-1-0", "JOKER-2-0", "JOKER-1-1", "JOKER-2-1", "JOKER-1-2", "JOKER-2-2", "JOKER-1-3", "JOKER-2-3", "JOKER-1-4"],
		'want_evaluation': {
			'can_be_personally_melded': [
				{"type": "run", "card_keys": ["JOKER-1-0", "JOKER-2-0", "JOKER-1-1", "JOKER-2-1"]},
				{"type": "run", "card_keys": ["JOKER-1-2", "JOKER-2-2", "JOKER-1-3", "JOKER-2-3"]},
			],
			'can_be_publicly_melded': [],
			'is_winning_hand': true,
			'recommended_discards': ["JOKER-1-4"],
		},
	},
	{
		'name': 'Basic 3 Groups Meld Round 4',
		'round': 4,
		'cards': ["A-hearts-0", "A-spades-0", "A-diamonds-0", "K-hearts-0", "K-spades-0", "K-diamonds-0", "7-hearts-0", "7-spades-0", "7-diamonds-0", "2-clubs-0"],
		'want_evaluation': {
			'can_be_personally_melded': [
				{"type": "group", "card_keys": ["A-hearts-0", "A-spades-0", "A-diamonds-0"]},
				{"type": "group", "card_keys": ["K-hearts-0", "K-spades-0", "K-diamonds-0"]},
				{"type": "group", "card_keys": ["7-hearts-0", "7-spades-0", "7-diamonds-0"]},
			],
			'can_be_publicly_melded': [],
			'is_winning_hand': true,
			'recommended_discards': ["2-clubs-0"],
		},
	},
	{
		'name': 'All Jokers Meld Round 4',
		'round': 4,
		'cards': ["JOKER-1-0", "JOKER-2-0", "JOKER-1-1", "JOKER-2-1", "JOKER-1-2", "JOKER-2-2", "JOKER-1-3", "JOKER-2-3", "JOKER-1-4", "JOKER-2-4"],
		'want_evaluation': {
			'can_be_personally_melded': [
				{"type": "group", "card_keys": ["JOKER-1-0", "JOKER-2-0", "JOKER-1-1"]},
				{"type": "group", "card_keys": ["JOKER-2-1", "JOKER-1-2", "JOKER-2-2"]},
				{"type": "group", "card_keys": ["JOKER-1-3", "JOKER-2-3", "JOKER-1-4"]},
			],
			'can_be_publicly_melded': [],
			'is_winning_hand': true,
			'recommended_discards': ["JOKER-2-4"],
		},
	},
	{
		'name': 'Basic 2 Groups + 1 Run Meld Round 5',
		'round': 5,
		'cards': ["A-hearts-0", "A-spades-0", "A-diamonds-0", "K-hearts-0", "K-spades-0", "K-diamonds-0", "4-hearts-0", "5-hearts-0", "6-hearts-0", "7-hearts-0", "2-spades-0"],
		'want_evaluation': {
			'can_be_personally_melded': [
				{"type": "group", "card_keys": ["A-hearts-0", "A-spades-0", "A-diamonds-0"]},
				{"type": "group", "card_keys": ["K-hearts-0", "K-spades-0", "K-diamonds-0"]},
				{"type": "run", "card_keys": ["4-hearts-0", "5-hearts-0", "6-hearts-0", "7-hearts-0"]},
			],
			'can_be_publicly_melded': [],
			'is_winning_hand': true,
			'recommended_discards': ["2-spades-0"],
		},
	},
	{
		'name': 'All Jokers Meld Round 5',
		'round': 5,
		'cards': ["JOKER-1-0", "JOKER-2-0", "JOKER-1-1", "JOKER-2-1", "JOKER-1-2", "JOKER-2-2", "JOKER-1-3", "JOKER-2-3", "JOKER-1-4", "JOKER-2-4", "JOKER-1-5"],
		'want_evaluation': {
			'can_be_personally_melded': [
				{"type": "group", "card_keys": ["JOKER-1-0", "JOKER-2-0", "JOKER-1-1"]},
				{"type": "group", "card_keys": ["JOKER-2-1", "JOKER-1-2", "JOKER-2-2"]},
				{"type": "run", "card_keys": ["JOKER-1-3", "JOKER-2-3", "JOKER-1-4", "JOKER-2-4"]},
			],
			'can_be_publicly_melded': [],
			'is_winning_hand': true,
			'recommended_discards': ["JOKER-1-5"],
		},
	},
]

func test_bot_scenarios() -> bool:
	for scenario in bot_test_scenarios:
		var passed = run_test_scenario(scenario)
		test_framework.assert_true(passed, "Scenario %s passed" % scenario.name)
	Global.game_state['current_round_num'] = 1 # Reset
	return true

func run_test_scenario(scenario: Dictionary) -> bool:
	Global.game_state['current_round_num'] = scenario.round
	var hand_stats = test_bot.gen_bot_hand_stats(scenario.cards)
	var evaluation = test_bot.evaluate_bot_hand(hand_stats, "test_bot")
	evaluation.erase('eval_score') # Remove eval_score for comparison
	test_framework.assert_dict_equal(scenario.want_evaluation, evaluation, "Bot hand evaluation should match expected")
	return true
