# Quick Debug Script
# Run this with: godot --headless --script tests/quick_debug.gd
# Use this to quickly test specific scenarios or reproduce bugs
extends Node

func _ready():
	print("=== Quick Debug Session ===")

	# Global is an autoload, access it directly

	# Example 1: Test hand evaluation with a specific hand
	test_specific_hand_scenario()

	# Example 2: Test game state consistency
	test_game_state_scenario()

	# Example 3: Test card logic
	test_card_logic_scenario()

	print("=== Debug Session Complete ===")
	get_tree().quit()

func test_specific_hand_scenario():
	print("\n--- Testing Hand Evaluation ---")

	# Create a test scenario - modify this to match your bug
	var test_cards = ["A-hearts-0", "A-spades-0", "A-diamonds-0", "K-hearts-0", "K-spades-0", "K-diamonds-0", "2-hearts-0"]

	print("Test hand: %s" % str(test_cards))

	# Generate hand stats
	var hand_stats = Global.gen_hand_stats(test_cards)
	DebugHelper.print_hand_stats(hand_stats)

	# Evaluate for round 1 (2 groups required)
	var all_public_meld_stats = Global._gen_all_public_meld_stats()
	var evaluation = Global._evaluate_hand_pre_meld(1, hand_stats, all_public_meld_stats)
	DebugHelper.print_hand_evaluation(evaluation)

	# Check if this should be a winning hand
	if len(evaluation['can_be_personally_melded']) >= 2:
		print("✓ Hand can meld required groups for round 1")
	else:
		print("✗ Hand cannot meld required groups for round 1")

func test_game_state_scenario():
	print("\n--- Testing Game State ---")

	# Create a test game state - modify this to match your scenario
	Global.game_state = {
		'current_round_num': 2,
		'current_player_turn_index': 1,
		'public_players_info': [
			{
				'id': 'player1',
				'name': 'Player 1',
				'turn_index': 0,
				'played_to_table': [ {
					'type': 'group',
					'card_keys': ['A-hearts-0', 'A-spades-0', 'A-diamonds-0']
				}],
				'num_cards': 10,
				'score': 0
			},
			{
				'id': 'player2',
				'name': 'Player 2',
				'turn_index': 1,
				'played_to_table': [],
				'num_cards': 13,
				'score': 0
			}
		],
		'current_buy_request_player_ids': {'player1': 'K-hearts-0'}
	}

	# Print game state
	DebugHelper.print_game_state(Global.game_state)

	# Validate consistency
	var issues = DebugHelper.validate_game_state_consistency(Global.game_state)
	if len(issues) == 0:
		print("✓ Game state is consistent")
	else:
		print("✗ Game state has issues:")
		for issue in issues:
			print("  - %s" % issue)
		get_tree().quit(1) # Exit if validation fails

	# Test player validation
	var valid_player = Global.validate_current_player_turn('player2')
	if valid_player:
		print("✓ Player2 is correctly validated as current player")
	else:
		print("✗ Player2 validation failed")
		get_tree().quit(1) # Exit if validation fails

func test_card_logic_scenario():
	print("\n--- Testing Card Logic ---")

	# Test card generation
	var test_key = Global.gen_playing_card_key('A', 'hearts', 0)
	print("Generated card key: %s" % test_key)

	# Test card scoring
	var score = Global.card_key_score(test_key)
	print("Card score: %d" % score)

	# Test deck calculations
	Global.game_state = {'public_players_info': [ {'id': '1'}, {'id': '2'}, {'id': '3'}, {'id': '4'}]}
	var num_decks = Global.get_total_num_card_decks()
	var num_cards = Global.get_total_num_cards()
	print("For 4 players: %d decks, %d total cards" % [num_decks, num_cards])

	# Test run validation
	var valid_run = ['A-hearts-0', '2-hearts-0', '3-hearts-0', '4-hearts-0']
	var invalid_run = ['A-hearts-0', '3-hearts-0', '5-hearts-0', '7-hearts-0']

	if Global._is_valid_run(valid_run):
		print("✓ Valid run correctly identified")
	else:
		print("✗ Valid run incorrectly rejected")

	if not Global._is_valid_run(invalid_run):
		print("✓ Invalid run correctly rejected")
	else:
		print("✗ Invalid run incorrectly accepted")

# Add your own custom test functions here
func test_my_specific_bug():
	# Customize this function to reproduce your specific issue
	print("\n--- Testing My Specific Bug ---")

	# Set up the exact scenario that's failing
	# Add debug output
	# Test the specific functionality

	pass

# Uncomment and modify this to test joker scenarios
# func test_joker_scenarios(Global: Global):
#     print("\n--- Testing Joker Scenarios ---")
#
#     var joker_hand = ["JOKER-1-0", "JOKER-2-0", "A-hearts-0", "3-hearts-0", "4-hearts-0"]
#     var hand_stats = Global.gen_hand_stats(joker_hand)
#     DebugHelper.print_hand_stats(hand_stats)
#
#     # Test run building with jokers
#     var all_public_meld_stats = Global._gen_all_public_meld_stats()
#     var evaluation = Global._evaluate_hand_pre_meld(2, hand_stats, all_public_meld_stats)
#     DebugHelper.print_hand_evaluation(evaluation)

# Uncomment and modify this to test specific round requirements
# func test_round_requirements(Global: Global):
#     print("\n--- Testing Round Requirements ---")
#
#     for round_num in range(1, 8):
#         var groups_required = Global._groups_per_round[round_num - 1]
#         var runs_required = Global._runs_per_round[round_num - 1]
#         print("Round %d: %d groups, %d runs" % [round_num, groups_required, runs_required])
