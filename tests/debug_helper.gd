# Debug Helper for Liverpool Rummy
# Utilities for debugging game logic and multiplayer issues

class_name DebugHelper
extends RefCounted

# Debug utilities for game state inspection
static func print_game_state(game_state: Dictionary) -> void:
	print("=== GAME STATE DEBUG ===")
	print("Round: %d" % game_state.get('current_round_num', 'N/A'))
	print("Current Player Turn: %d" % game_state.get('current_player_turn_index', 'N/A'))
	print("Players: %d" % len(game_state.get('public_players_info', [])))

	for i in range(len(game_state.get('public_players_info', []))):
		var player = game_state['public_players_info'][i]
		print("  Player %d: %s (ID: %s, Cards: %d, Melded: %d)" % [
			i, player.get('name', 'Unknown'), player.get('id', 'N/A'),
			player.get('num_cards', 0), len(player.get('played_to_table', []))
		])

	var buy_requests = game_state.get('current_buy_request_player_ids', {})
	if len(buy_requests) > 0:
		print("Buy Requests: %s" % str(buy_requests))
	print("========================")

static func print_hand_stats(hand_stats: Dictionary) -> void:
	print("=== HAND STATS DEBUG ===")
	print("Total Cards: %d" % hand_stats.get('num_cards', 0))
	print("Jokers: %d" % len(hand_stats.get('jokers', [])))

	print("Groups:")
	print("  3+: %d groups" % len(hand_stats.get('groups_of_3_plus', [])))
	print("  2: %d groups" % len(hand_stats.get('groups_of_2', [])))

	print("Runs:")
	print("  4+: %d runs" % len(hand_stats.get('runs_of_4_plus', [])))
	print("  3: %d runs" % len(hand_stats.get('runs_of_3', [])))
	print("  2: %d runs" % len(hand_stats.get('runs_of_2', [])))

	print("By Rank:")
	for rank in hand_stats.get('by_rank', {}):
		print("  %s: %d cards" % [rank, len(hand_stats['by_rank'][rank])])

	print("By Suit:")
	for suit in hand_stats.get('by_suit', {}):
		print("  %s: %d cards" % [suit, len(hand_stats['by_suit'][suit])])
	print("==========================")

static func print_hand_evaluation(evaluation: Dictionary) -> void:
	print("=== HAND EVALUATION DEBUG ===")
	print("Evaluation Score: %d" % evaluation.get('eval_score', 0))
	print("Is Winning Hand: %s" % str(evaluation.get('is_winning_hand', false)))

	var personal_melds = evaluation.get('can_be_personally_melded', [])
	print("Personal Melds: %d" % len(personal_melds))
	for i in range(len(personal_melds)):
		var meld = personal_melds[i]
		print("  Meld %d: %s (%d cards)" % [i, meld.get('type', 'unknown'), len(meld.get('card_keys', []))])

	var public_melds = evaluation.get('can_be_publicly_melded', [])
	print("Public Melds: %d" % len(public_melds))
	for i in range(len(public_melds)):
		var meld = public_melds[i]
		print("  Card: %s -> Player %s" % [meld.get('card_key', 'unknown'), meld.get('target_player_id', 'unknown')])

	var discards = evaluation.get('recommended_discards', [])
	print("Recommended Discards: %d" % len(discards))
	for i in range(min(3, len(discards))):
		print("  %d: %s" % [i + 1, discards[i]])
	print("==============================")

static func print_multiplayer_sync_state(ack_sync_state: Dictionary) -> void:
	print("=== MULTIPLAYER SYNC DEBUG ===")
	print("Active Sync Operations: %d" % len(ack_sync_state))

	for operation in ack_sync_state:
		var sync_data = ack_sync_state[operation]
		var acks = sync_data.get('acks', {})
		print("  Operation: %s" % operation)
		print("    Acks: %d" % len(acks))
		print("    Next State: %s" % sync_data.get('next_state', 'N/A'))
		print("    Advance Turn: %s" % str(sync_data.get('advance_player_turn', false)))
	print("===============================\n")

static func validate_game_state_consistency(game_state: Dictionary) -> Array[String]:
	"""Validate game state for common consistency issues"""
	var issues: Array[String] = []

	# Check round number
	var round_num = game_state.get('current_round_num', 0)
	if round_num < 1 or round_num > 7:
		issues.append("Invalid round number: %d" % round_num)

	# Check player turn index
	var turn_index = game_state.get('current_player_turn_index', -1)
	var players = game_state.get('public_players_info', [])
	if turn_index < 0 or turn_index >= len(players):
		issues.append("Invalid turn index: %d for %d players" % [turn_index, len(players)])

	# Check player consistency
	for i in range(len(players)):
		var player = players[i]
		if player.get('turn_index', -1) != i:
			issues.append("Player %d has wrong turn_index: %d" % [i, player.get('turn_index', -1)])

		if player.get('num_cards', 0) < 0:
			issues.append("Player %s has negative cards: %d" % [player.get('name', 'unknown'), player.get('num_cards', 0)])

	return issues

static func create_test_scenario(scenario_name: String) -> Dictionary:
	"""Create common test scenarios for debugging"""
	match scenario_name:
		"basic_game":
			return {
				'current_round_num': 1,
				'current_player_turn_index': 0,
				'public_players_info': [
					{
						'id': 'player1',
						'name': 'Player 1',
						'is_bot': false,
						'turn_index': 0,
						'played_to_table': [],
						'score': 0,
						'num_cards': 13
					},
					{
						'id': 'player2',
						'name': 'Player 2',
						'is_bot': false,
						'turn_index': 1,
						'played_to_table': [],
						'score': 0,
						'num_cards': 13
					}
				],
				'current_buy_request_player_ids': {}
			}
		"with_melds":
			return {
				'current_round_num': 2,
				'current_player_turn_index': 1,
				'public_players_info': [
					{
						'id': 'player1',
						'name': 'Player 1',
						'is_bot': false,
						'turn_index': 0,
						'played_to_table': [ {
							'type': 'group',
							'rank': 'A',
							'card_keys': ['A-hearts-0', 'A-diamonds-0', 'A-clubs-0']
						}],
						'score': 0,
						'num_cards': 10
					},
					{
						'id': 'player2',
						'name': 'Player 2',
						'is_bot': false,
						'turn_index': 1,
						'played_to_table': [ {
							'type': 'run',
							'suit': 'hearts',
							'card_keys': ['2-hearts-0', '3-hearts-0', '4-hearts-0', '5-hearts-0']
						}],
						'score': 0,
						'num_cards': 9
					}
				],
				'current_buy_request_player_ids': {}
			}
		_:
			return {}

static func create_test_hand(hand_type: String) -> Array[String]:
	"""Create common test hands for debugging"""
	match hand_type:
		"winning_round1":
			return ['A-hearts-0', 'A-spades-0', 'A-diamonds-0', 'K-hearts-0', 'K-spades-0', 'K-diamonds-0', '2-hearts-0']
		"partial_groups":
			return ['A-hearts-0', 'A-spades-0', 'K-hearts-0', 'K-spades-0', 'Q-hearts-0', 'Q-spades-0', 'J-hearts-0']
		"good_run":
			return ['A-hearts-0', '2-hearts-0', '3-hearts-0', '4-hearts-0', '5-hearts-0', '6-hearts-0', '7-hearts-0']
		"mixed_hand":
			return ['A-hearts-0', 'A-spades-0', 'A-diamonds-0', '2-hearts-0', '3-hearts-0', '4-hearts-0', 'JOKER-1-0']
		"joker_heavy":
			return ['JOKER-1-0', 'JOKER-2-0', 'A-hearts-0', 'K-spades-0', 'Q-diamonds-0', 'J-clubs-0', '10-hearts-0']
		_:
			return []

static func benchmark_function(func_name: String, callable_func: Callable, iterations: int = 1000) -> Dictionary:
	"""Benchmark a function to help identify performance issues"""
	var start_time = Time.get_unix_time_from_system()
	var results = []

	for i in range(iterations):
		var result = callable_func.call()
		results.append(result)

	var end_time = Time.get_unix_time_from_system()
	var total_time = end_time - start_time
	var avg_time = total_time / iterations

	return {
		'function_name': func_name,
		'iterations': iterations,
		'total_time': total_time,
		'avg_time': avg_time,
		'results': results
	}
