# Test Card Logic
# Tests for card generation, manipulation, and validation

class_name TestCardLogic
extends Node

# const TestFramework = preload("res://tests/test_framework.gd")

var test_framework: TestFramework

func _ready():
	test_framework = TestFramework.new()
	add_child(test_framework)
	# Global is an autoload, access it directly

func run_all_tests() -> bool:
	return test_framework.discover_and_run_test_suite("Card Logic Tests", self)

func test_gen_playing_card_key() -> bool:
	var key1 = Global.gen_playing_card_key('A', 'hearts', 0)
	test_framework.assert_equal('A-hearts-0', key1, "Should generate correct card key")

	var key2 = Global.gen_playing_card_key('JOKER', '1', 0)
	test_framework.assert_equal('JOKER-1-0', key2, "Should generate correct joker key")
	return true

func test_get_total_num_card_decks() -> bool:
	# Mock different player counts
	Global.game_state = {'public_players_info': [ {'id': '1'}, {'id': '2'}]}
	test_framework.assert_equal(1, Global.get_total_num_card_decks(), "2 players should use 1 deck")

	Global.game_state = {'public_players_info': [ {'id': '1'}, {'id': '2'}, {'id': '3'}, {'id': '4'}]}
	test_framework.assert_equal(2, Global.get_total_num_card_decks(), "4 players should use 2 decks")

	Global.game_state = {'public_players_info': [ {'id': '1'}, {'id': '2'}, {'id': '3'}, {'id': '4'}, {'id': '5'}, {'id': '6'}]}
	test_framework.assert_equal(3, Global.get_total_num_card_decks(), "6 players should use 3 decks")

	Global.game_state = {'public_players_info': [ {'id': '1'}, {'id': '2'}, {'id': '3'}, {'id': '4'}, {'id': '5'}, {'id': '6'}, {'id': '7'}, {'id': '8'}, {'id': '9'}]}
	test_framework.assert_equal(4, Global.get_total_num_card_decks(), "9 players should use 4 decks")
	return true

func test_get_total_num_cards() -> bool:
	Global.game_state = {'public_players_info': [ {'id': '1'}, {'id': '2'}]}
	test_framework.assert_equal(54, Global.get_total_num_cards(), "Should have 54 cards for 1 deck")

	Global.game_state = {'public_players_info': [ {'id': '1'}, {'id': '2'}, {'id': '3'}, {'id': '4'}]}
	test_framework.assert_equal(108, Global.get_total_num_cards(), "Should have 108 cards for 2 decks")
	return true

func test_strip_deck_from_card_key() -> bool:
	test_framework.assert_equal('A-hearts', Global.strip_deck_from_card_key('A-hearts-0'), "Should strip deck from normal card")
	test_framework.assert_equal('JOKER', Global.strip_deck_from_card_key('JOKER-1-0'), "Should handle joker correctly")
	test_framework.assert_equal('K-spades', Global.strip_deck_from_card_key('K-spades-2'), "Should strip deck from any deck number")
	return true

func test_card_key_parsing() -> bool:
	# Test that card keys are parsed correctly
	var card_key = 'A-hearts-0'
	var parts = card_key.split('-')
	test_framework.assert_equal('A', parts[0], "Should extract rank correctly")
	test_framework.assert_equal('hearts', parts[1], "Should extract suit correctly")
	test_framework.assert_equal('0', parts[2], "Should extract deck correctly")

	var joker_key = 'JOKER-1-0'
	var joker_parts = joker_key.split('-')
	test_framework.assert_equal('JOKER', joker_parts[0], "Should extract joker rank correctly")
	test_framework.assert_equal('1', joker_parts[1], "Should extract joker suit correctly")
	return true

func test_joker_handling() -> bool:
	# Test joker scoring
	test_framework.assert_equal(15, Global.card_key_score('JOKER-1-0'), "Joker should score 15")
	test_framework.assert_equal(15, Global.card_key_score('JOKER-2-0'), "Second joker should also score 15")

	# Test joker in hand stats
	var cards_with_jokers = ['A-hearts-0', 'JOKER-1-0', 'JOKER-2-0']
	var test_bot = Bot.new('test_bot')
	var stats = test_bot.gen_bot_hand_stats(cards_with_jokers)
	test_framework.assert_equal(2, len(stats['jokers']), "Should identify 2 jokers")
	test_framework.assert_equal(1, len(stats['by_rank']['A']), "Should have 1 ace in by_rank")
	test_framework.assert_dict_not_has_key(stats['by_rank'], 'JOKER', "Jokers should not be in by_rank")
	return true

func test_card_generation_logic() -> bool:
	# Test that all expected cards would be generated
	var expected_ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
	var expected_suits = ['hearts', 'diamonds', 'clubs', 'spades']

	# Test normal cards
	for rank in expected_ranks:
		for suit in expected_suits:
			var key = Global.gen_playing_card_key(rank, suit, 0)
			test_framework.assert_equal(rank + '-' + suit + '-0', key, "Should generate correct key for " + rank + " of " + suit)

	# Test jokers
	var joker1 = Global.gen_playing_card_key('JOKER', '1', 0)
	var joker2 = Global.gen_playing_card_key('JOKER', '2', 0)
	test_framework.assert_equal('JOKER-1-0', joker1, "Should generate correct first joker")
	test_framework.assert_equal('JOKER-2-0', joker2, "Should generate correct second joker")

	# Test multi-deck keys
	var multi_deck_key = Global.gen_playing_card_key('A', 'hearts', 1)
	test_framework.assert_equal('A-hearts-1', multi_deck_key, "Should generate correct multi-deck key")
	return true

func cleanup_test_resources() -> void:
	# Clean up test framework
	if test_framework and is_instance_valid(test_framework):
		if test_framework.is_inside_tree():
			remove_child(test_framework)
		test_framework.queue_free()
	test_framework = null
