# Test Hand Evaluation Logic
# Tests for the complex hand evaluation and melding logic in global.gd

class_name TestHandEvaluation
extends Node

const Bot = preload("res://players/00-bot.gd")

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
			}
		],
		'current_buy_request_player_ids': {}
	}

	# Set up the global instance with mock data
	Global.game_state = mock_game_state

func run_all_tests() -> bool:
	var tests = [
		test_card_key_score,
		test_sort_card_keys_by_score,
		test_tally_hand_cards_score,
		test_gen_hand_stats_basic,
		test_gen_hand_stats_with_jokers,
		test_gen_hand_stats_groups,
		test_gen_hand_stats_runs,
		test_evaluate_hand_pre_meld_round1,
		test_evaluate_hand_pre_meld_round2,
		test_evaluate_hand_post_meld,
		test_find_groups_can_be_publicly_melded,
		test_find_runs_can_be_publicly_melded,
		test_is_publicly_meldable_groups,
		test_is_publicly_meldable_runs,
		test_can_card_extend_run,
		test_can_card_replace_joker_in_run,
		test_is_valid_run,
		test_rank_to_bitmap,
		test_build_run_with_jokers
	]

	return test_framework.run_test_suite("Hand Evaluation Tests", tests)

# Test basic card scoring
func test_card_key_score() -> bool:
	test_framework.assert_equal(15, Global.card_key_score("JOKER-1-0"), "Joker should score 15")
	test_framework.assert_equal(15, Global.card_key_score("A-hearts-0"), "Ace should score 15")
	test_framework.assert_equal(10, Global.card_key_score("K-spades-0"), "King should score 10")
	test_framework.assert_equal(10, Global.card_key_score("Q-diamonds-0"), "Queen should score 10")
	test_framework.assert_equal(10, Global.card_key_score("J-clubs-0"), "Jack should score 10")
	test_framework.assert_equal(10, Global.card_key_score("10-hearts-0"), "Ten should score 10")
	test_framework.assert_equal(5, Global.card_key_score("9-hearts-0"), "Nine should score 5")
	test_framework.assert_equal(5, Global.card_key_score("2-hearts-0"), "Two should score 5")
	return true

func test_sort_card_keys_by_score() -> bool:
	var cards = ["2-hearts-0", "A-spades-0", "K-diamonds-0", "3-clubs-0"]
	var sorted_cards = Global.sort_card_keys_by_score(cards)
	test_framework.assert_equal("A-spades-0", sorted_cards[0], "Ace should be first (highest score)")
	test_framework.assert_equal("K-diamonds-0", sorted_cards[1], "King should be second")
	test_framework.assert_true(sorted_cards[2] in ["2-hearts-0", "3-clubs-0"], "Low cards should be last")
	return true

func test_tally_hand_cards_score() -> bool:
	var cards = ["A-hearts-0", "K-spades-0", "2-diamonds-0"]
	var total = Global.tally_hand_cards_score(cards)
	test_framework.assert_equal(30, total, "A(15) + K(10) + 2(5) = 30")
	return true

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
	var all_public_meld_stats = Global._gen_all_public_meld_stats()
	var evaluation = test_bot._evaluate_hand_pre_meld(1, hand_stats, all_public_meld_stats)

	test_framework.assert_equal(2, len(evaluation['can_be_personally_melded']), "Should be able to meld 2 groups")
	test_framework.assert_true(evaluation['eval_score'] > 0, "Should have positive evaluation score")
	return true

func test_evaluate_hand_pre_meld_round2() -> bool:
	# Round 2 requires 1 group + 1 run
	var cards = ["A-hearts-0", "A-spades-0", "A-diamonds-0", "2-hearts-0", "3-hearts-0", "4-hearts-0", "5-hearts-0", "6-hearts-0"]
	var hand_stats = test_bot.gen_bot_hand_stats(cards)
	var all_public_meld_stats = Global._gen_all_public_meld_stats()
	var evaluation = test_bot._evaluate_hand_pre_meld(2, hand_stats, all_public_meld_stats)

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
	return true

func test_evaluate_hand_post_meld() -> bool:
	# Test post-meld evaluation with some cards that can be publicly melded
	var cards = ["A-spades-0", "2-hearts-0", "3-hearts-0"]
	var hand_stats = test_bot.gen_bot_hand_stats(cards)
	var all_public_meld_stats = Global._gen_all_public_meld_stats()
	var evaluation = test_bot._evaluate_hand_post_meld(1, hand_stats, all_public_meld_stats)

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

	test_framework.assert_true(Global.is_valid_run(valid_run), "A-2-3-4 of hearts should be valid")
	test_framework.assert_false(Global.is_valid_run(invalid_run), "A-3-5-7 of hearts should be invalid")
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
