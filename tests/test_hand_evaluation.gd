# Test Hand Evaluation Logic
# Tests for the complex hand evaluation and melding logic in global.gd

class_name TestHandEvaluation
extends Node

var test_framework: TestFramework

# Mock game state for testing
var mock_game_state: Dictionary
var mock_private_player_info: Dictionary

func _ready():
	test_framework = TestFramework.new()
	add_child(test_framework)
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
					'rank': 'A',
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
	return test_framework.discover_and_run_test_suite("Hand Evaluation Tests", self)

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

func cleanup_test_resources() -> void:
	# Clean up test framework
	if test_framework and is_instance_valid(test_framework):
		if test_framework.is_inside_tree():
			remove_child(test_framework)
		test_framework.queue_free()
	test_framework = null
