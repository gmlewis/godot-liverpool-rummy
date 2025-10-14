extends Node
class_name Bot
# This is the base class for all bots.

@onready var game_state_machine: Node = $"/root/RootNode/GameStateMachine" if has_node("/root/RootNode/GameStateMachine") else null

# bot_id is in the form of "bot#" and is used as a key into the
# Global.bots_private_player_info dictionary where the rest of the
# state information for this bot is stored.
var bot_id: String

var is_my_turn: bool = false
var is_currently_busy: bool = false
var last_drawn_card_key_from_discard_pile: String = ''

func _init(_bot_id: String) -> void:
	# Initialize the bot with its ID.
	bot_id = _bot_id
	Global.dbg("Bot initialized with ID: %s" % bot_id)

func get_bot_name() -> String:
	return '' # Override this method in subclasses to return the bot's name.

func _ready() -> void:
	if game_state_machine != null:
		game_state_machine.connect('gsm_changed_state_signal', _on_gsm_changed_state_signal)
	Global.connect('new_card_exposed_on_discard_pile_signal', _on_new_card_exposed_on_discard_pile_signal)
	Global.connect('server_ack_sync_completed_signal', _on_server_ack_sync_completed_signal)
	Global.dbg("BOT('%s') is ready." % get_bot_name())

func _exit_tree() -> void:
	if game_state_machine != null:
		game_state_machine.disconnect('gsm_changed_state_signal', _on_gsm_changed_state_signal)
	Global.disconnect('new_card_exposed_on_discard_pile_signal', _on_new_card_exposed_on_discard_pile_signal)
	Global.disconnect('server_ack_sync_completed_signal', _on_server_ack_sync_completed_signal)
	Global.dbg("BOT('%s') is exiting." % get_bot_name())

func _on_gsm_changed_state_signal(_from_state: String, to_state: String) -> void:
	# Global.dbg("BOT('%s'): _on_gsm_changed_state_signal: from_state='%s', to_state='%s'" % [get_bot_name(), _from_state, to_state])
	if not game_state_machine.is_playing_state():
		is_my_turn = false
		return
	var bot_private_player_info = Global.bots_private_player_info[bot_id]
	is_my_turn = bot_private_player_info.turn_index == Global.game_state.current_player_turn_index
	# Global.dbg("BOT('%s'): _on_gsm_changed_state_signal: is_my_turn=%s, from_state='%s', to_state='%s', private_player_info: %s" %
	# 	[get_bot_name(), is_my_turn, _from_state, to_state, str(bot_private_player_info)])
	if to_state == 'NewDiscardState':
		if is_my_turn:
			Global.dbg("BOT('%s'): _on_gsm_changed_state_signal: is_my_turn=true, calling await_grace_period" % get_bot_name())
			await Global.await_grace_period()
		# if is_currently_busy:
		# 	Global.dbg("BOT('%s'): _on_gsm_changed_state_signal: IS CURRENTLY BUSY!!! PROCEEDING ANYWAY!!!" % [get_bot_name()])
		is_currently_busy = true
		_on_new_discard_state_entered()
		is_currently_busy = false
		# Global.dbg("BOT('%s'): _on_gsm_changed_state_signal: A: is_currently_busy=%s" % [get_bot_name(), is_currently_busy])
	elif to_state == 'PlayerDrewState':
		# if is_currently_busy:
		# 	Global.dbg("BOT('%s'): _on_gsm_changed_state_signal: IS CURRENTLY BUSY!!! PROCEEDING ANYWAY!!!" % [get_bot_name()])
		is_currently_busy = true
		_on_player_drew_state_entered()
		is_currently_busy = false
		# Global.dbg("BOT('%s'): _on_gsm_changed_state_signal: B: is_currently_busy=%s" % [get_bot_name(), is_currently_busy])

# NOTE that after every time a card is bought, all bots should be given a chance to run _on_new_discard_state_entered() again!
func _on_new_card_exposed_on_discard_pile_signal() -> void:
	# Global.dbg("BOT('%s'): _on_new_card_exposed_on_discard_pile_signal: is_my_turn=%s" % [get_bot_name(), is_my_turn])
	if is_my_turn:
		Global.dbg("BOT('%s'): _on_new_card_exposed_on_discard_pile_signal: is_my_turn=true, calling await_grace_period" % get_bot_name())
		await Global.await_grace_period()
	is_currently_busy = true
	_on_new_discard_state_entered()
	is_currently_busy = false
	# Global.dbg("BOT('%s'): _on_new_card_exposed_on_discard_pile_signal: C: is_currently_busy=%s" % [get_bot_name(), is_currently_busy])

func _on_new_discard_state_entered() -> void:
	pass

# Most bots will want to use the "smart" discard strategy, so it is in the base class.
func _on_player_drew_state_entered() -> void:
	if not is_my_turn: return
	Global.dbg("BOT('%s'): ENTER _on_player_drew_state_entered()" % get_bot_name())
	var bot_private_player_info = Global.bots_private_player_info[bot_id]
	var card_keys_in_hand = bot_private_player_info.card_keys_in_hand
	# Global.dbg("BOT('%s'): _on_player_drew_state_entered: card_keys_in_hand=%s" % [get_bot_name(), str(card_keys_in_hand)])
	var current_hand_stats = gen_bot_hand_stats(card_keys_in_hand)
	# Global.dbg("BOT('%s'): _on_player_drew_state_entered: current_hand_stats=%s" % [get_bot_name(), str(current_hand_stats)])
	var current_hand_evaluation = evaluate_bot_hand(current_hand_stats, bot_id)
	# Global.dbg("BOT('%s'): _on_player_drew_state_entered: current_hand_evaluation=%s" % [get_bot_name(), str(current_hand_evaluation)])

	# Check to see if this bot can meld its hand.
	if current_hand_evaluation['can_be_personally_melded']:
		Global.dbg("BOT('%s'): _on_player_drew_state_entered: can_meld=true, melding hand" % [get_bot_name()])
		Global.personally_meld_hand(bot_id, current_hand_evaluation)
		Global.dbg("BOT('%s'): LEAVE1 _on_player_drew_state_entered()" % get_bot_name())
		return
	_smart_discard_card(current_hand_evaluation)

func _smart_discard_card(current_hand_evaluation: Dictionary) -> void:
	Global.dbg("BOT('%s'): ENTER _smart_discard_card(), last_drawn_card_key_from_discard_pile='%s'" % [get_bot_name(), last_drawn_card_key_from_discard_pile])
	var recommended_discards = current_hand_evaluation['recommended_discards']
	var discard_card_key = recommended_discards[0] if len(recommended_discards) > 0 else ''
	var can_be_publicly_melded = current_hand_evaluation['can_be_publicly_melded']
	if discard_card_key == '' and len(can_be_publicly_melded) > 0:
		discard_card_key = can_be_publicly_melded[0]['card_key']
	# Round 7 still calls Global.discard_card() but with an empty discard_card_key.
	if current_hand_evaluation['is_winning_hand']:
		Global.dbg("BOT('%s'): _smart_discard_card: is_winning_hand=true, discarding card_key=%s" % [get_bot_name(), discard_card_key])
		Global.discard_card(bot_id, discard_card_key, true) # true means this is a winning hand.
		Global.dbg("BOT('%s'): LEAVE1 _smart_discard_card()" % get_bot_name())
		return
	if discard_card_key == '' or discard_card_key == last_drawn_card_key_from_discard_pile:
		discard_random_card(last_drawn_card_key_from_discard_pile)
		Global.dbg("BOT('%s'): LEAVE2 _smart_discard_card()" % get_bot_name())
		return
	Global.dbg("BOT('%s'): _smart_discard_card: recommended_discards=%s, discarding card_key=%s" % [get_bot_name(), str(recommended_discards), discard_card_key])
	Global.discard_card(bot_id, discard_card_key, false)
	Global.dbg("BOT('%s'): LEAVE3 _smart_discard_card()" % get_bot_name())

################################################################################
## Utility functions for bots
################################################################################

func gen_current_hand_stats() -> Dictionary:
	var bot_private_player_info = Global.bots_private_player_info[bot_id]
	var card_keys_in_hand = bot_private_player_info.card_keys_in_hand
	# Global.dbg("BOT('%s'): gen_current_hand_stats: card_keys_in_hand=%s" % [get_bot_name(), str(card_keys_in_hand)])
	var current_hand_stats = gen_bot_hand_stats(card_keys_in_hand)
	# Global.dbg("BOT('%s'): gen_current_hand_stats: current_hand_stats=%s" % [get_bot_name(), str(current_hand_stats)])
	return current_hand_stats

func do_i_want_discard_card(current_hand_stats: Dictionary, current_eval_score: int) -> bool:
	if len(Global.discard_pile) == 0: return false
	var discard_card_key = Global.discard_pile[0].key
	var hand_stats_with_discard = Global.add_card_to_stats(current_hand_stats.duplicate(true), discard_card_key)
	var hand_evaluation_with_discard = evaluate_bot_hand(hand_stats_with_discard, bot_id)
	# Global.dbg("BOT('%s'): do_i_want_discard_card: hand_stats_with_discard=%s; hand_evaluation_with_discard=%s" % [get_bot_name(), str(hand_stats_with_discard), str(hand_evaluation_with_discard)])
	var eval_score_with_discard = hand_evaluation_with_discard['eval_score']
	var discard_key_in_discards = discard_card_key in hand_evaluation_with_discard['recommended_discards']
	# If this hand with the discard card is better than the current hand,
	# and the discard card does not show up in the 'recommended_discards' array,
	# then we want to draw the discard card.
	if eval_score_with_discard > current_eval_score and discard_key_in_discards:
		Global.error("BOT('%s'): do_i_want_discard_card: eval_score_with_discard=%d > current_eval_score=%d, discard_key_in_discards=%s" % [get_bot_name(), eval_score_with_discard, current_eval_score, str(discard_key_in_discards)])
	elif eval_score_with_discard > current_eval_score:
		# Global.dbg("BOT('%s'): do_i_want_discard_card: eval_score_with_discard=%d > current_eval_score=%d, want_discard_card=true" % [get_bot_name(), eval_score_with_discard, current_eval_score])
		return true
	# Global.dbg("BOT('%s'): do_i_want_discard_card: eval_score_with_discard=%d <= current_eval_score=%d, want_discard_card=false" % [get_bot_name(), eval_score_with_discard, current_eval_score])
	return false

func simplified_do_i_want_discard_card() -> bool:
	if not is_my_turn: return false
	var current_hand_stats = gen_current_hand_stats()
	var current_hand_evaluation = evaluate_bot_hand(current_hand_stats, bot_id)
	# Global.dbg("BOT('%s'): simplified_do_i_want_discard_card: current_hand_evaluation=%s" % [get_bot_name(), str(current_hand_evaluation)])
	var current_eval_score = current_hand_evaluation['eval_score']
	var want_discard_card = do_i_want_discard_card(current_hand_stats, current_eval_score)
	return want_discard_card

func discard_random_card(except_last_drawn_card_key: String) -> void:
	if not is_my_turn: return
	Global.dbg("BOT('%s'): ENTER discard_random_card(except_last_drawn_card_key='%s')" % [get_bot_name(), except_last_drawn_card_key])
	var bot_private_player_info = Global.bots_private_player_info[bot_id]
	# pick a random card from bot_private_player_info.card_keys_in_hand array
	var card_keys_in_hand = bot_private_player_info.card_keys_in_hand
	if card_keys_in_hand.size() == 0:
		Global.error("BOT('%s'): No cards in hand to discard!" % get_bot_name())
		return
	var card_key = ''
	var stripped_last_drawn_card = Global.strip_deck_from_card_key(except_last_drawn_card_key)
	for attempt in range(20):
		var random_index = randi() % card_keys_in_hand.size()
		card_key = card_keys_in_hand[random_index]
		if card_key.begins_with('JOKER'): # It would be stupid to discard a joker.
			continue
		if Global.strip_deck_from_card_key(card_key) == stripped_last_drawn_card:
			continue # Skip the last drawn card even if it is from a different deck!
		break # OK to discard this card.
	Global.discard_card(bot_id, card_key, false)
	Global.dbg("BOT('%s'): LEAVE discard_random_card(except_last_drawn_card_key='%s'): discard card_key='%s'" % [get_bot_name(), except_last_drawn_card_key, card_key])

func _on_server_ack_sync_completed_signal(_peer_id: int, operation_name: String, _operation_params: Dictionary) -> void:
	if not is_my_turn: return
	Global.dbg("BOT('%s'): ENTER _on_server_ack_sync_completed_signal(operation_name='%s')" % [get_bot_name(), operation_name])
	var bot_private_player_info = Global.bots_private_player_info[bot_id]
	var card_keys_in_hand = bot_private_player_info.card_keys_in_hand
	var current_hand_stats = gen_bot_hand_stats(card_keys_in_hand)
	var current_hand_evaluation = evaluate_bot_hand(current_hand_stats, bot_id)
	# TODO: allow bot to manipulate the publicly melded cards (e.g. move jokers, etc.) - one sync'd operation at a time.
	var min_cards_to_discard = 1 if Global.game_state['current_round_num'] < 7 else 0
	if operation_name == '_rpc_personally_meld_cards_only' or operation_name == '_rpc_publicly_meld_card_only':
		# Check to see if this bot can meld cards onto other players' melds (one at a time).
		Global.dbg("BOT('%s'): _on_server_ack_sync_completed_signal(operation_name='%s'): current_hand_evaluation=%s" % [get_bot_name(), operation_name, str(current_hand_evaluation)])
		var can_be_publicly_melded = current_hand_evaluation['can_be_publicly_melded']
		if can_be_publicly_melded.size() > min_cards_to_discard:
			Global.dbg("BOT('%s'): _on_server_ack_sync_completed_signal(operation_name='%s'): can_be_publicly_melded=%s, requesting to meld next (one) card onto other players' melds" % [get_bot_name(), operation_name, str(can_be_publicly_melded)])
			var next_meld_operation = can_be_publicly_melded[0]
			var card_key = next_meld_operation['card_key']
			var target_player_id = next_meld_operation['target_player_id']
			var meld_group_index = next_meld_operation['meld_group_index']
			Global.meld_card_to_public_meld(bot_id, card_key, target_player_id, meld_group_index)
		else:
			Global.dbg("BOT('%s'): _on_server_ack_sync_completed_signal(operation_name='%s'): cannot meld cards onto other players' melds, discarding." % [get_bot_name(), operation_name])
			_smart_discard_card(current_hand_evaluation)
	Global.dbg("BOT('%s'): LEAVE _on_server_ack_sync_completed_signal(operation_name='%s')" % [get_bot_name(), operation_name])

################################################################################

func _draw_card_from_discard_pile() -> void:
	last_drawn_card_key_from_discard_pile = Global.discard_pile[0].key
	Global.draw_card_from_discard_pile(bot_id)

func _draw_card_from_stock_pile() -> void:
	last_drawn_card_key_from_discard_pile = ''
	Global.draw_card_from_stock_pile(bot_id)

################################################################################
## Bot hand evaluation functions
################################################################################

func gen_bot_hand_stats(card_keys_in_hand: Array) -> Dictionary:
	var hand_stats = card_keys_in_hand.reduce(func(acc, card_key):
		return Global.add_card_to_stats(acc, card_key), {
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

func _sort_hands_by_score(hands: Array) -> Array:
	var hands_copy = hands.duplicate()
	var scores = []
	for hand in hands_copy:
		scores.append(Global.tally_hand_cards_score(hand))

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

func evaluate_bot_hand(hand_stats: Dictionary, player_id: String) -> Dictionary:
	var all_public_meld_stats = Global._gen_all_public_meld_stats()
	var pre_meld = not Global.player_has_melded(player_id)
	var evaluation = null
	if pre_meld:
		Global.dbg("ENTER PRE-MELD evaluate_bot_hand: round_num=%d, player_id='%s', all_public_meld_stats=%s" % [Global.game_state.current_round_num, player_id, str(all_public_meld_stats)])
		evaluation = _evaluate_hand_pre_meld(Global.game_state.current_round_num, hand_stats, all_public_meld_stats)
		Global.dbg("LEAVE PRE-MELD evaluate_bot_hand: round_num=%d, player_id='%s', evaluation=%s" % [Global.game_state.current_round_num, player_id, str(evaluation)])
	else:
		Global.dbg("ENTER POST-MELD evaluate_bot_hand: round_num=%d, player_id='%s', hand_stats=%s, all_public_meld_stats=%s" % [Global.game_state.current_round_num, player_id, str(hand_stats), str(all_public_meld_stats)])
		evaluation = _evaluate_hand_post_meld(Global.game_state.current_round_num, hand_stats, all_public_meld_stats)
		Global.dbg("LEAVE POST-MELD evaluate_bot_hand: round_num=%d, player_id='%s', evaluation=%s" % [Global.game_state.current_round_num, player_id, str(evaluation)])
	return evaluation

# Round requirements
var _groups_per_round = [2, 1, 0, 3, 2, 1, 0]
var _runs_per_round = [0, 1, 2, 0, 1, 2, 3]

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

	Global.dbg("ENTER Global._evaluate_hand_pre_meld: round_num=%d, num_groups=%d, num_runs=%d, hand_stats=%s" % [round_num, num_groups, num_runs, str(hand_stats)])

	var acc = Global.empty_evaluation()
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
	var penalty_score = - Global.tally_hand_cards_score(acc['recommended_discards'])
	acc['eval_score'] += penalty_score

	# If in rounds 1-6 and all cards are melded, remove one card to leave for discarding
	if round_num < 7 and len(acc['recommended_discards']) == 0 and len(acc['can_be_personally_melded']) > 0:
		# Count melded cards
		var melded_cards = 0
		for meld in acc['can_be_personally_melded']:
			melded_cards += len(meld['card_keys'])
		if melded_cards == hand_stats['num_cards']:
			# Find the meld with the most cards (prefer groups over runs)
			var max_meld = null
			var max_len = 0
			for meld in acc['can_be_personally_melded']:
				var meld_len = len(meld['card_keys'])
				if meld_len > max_len and (max_meld == null or (meld['type'] == 'group' and max_meld['type'] == 'run') or meld_len > len(max_meld['card_keys'])):
					max_len = meld_len
					max_meld = meld
			if max_meld:
				# Find the lowest scoring card in max_meld
				var lowest_card = null
				var lowest_score = 999
				for card_key in max_meld['card_keys']:
					var score = Global.card_key_score(card_key)
					if score < lowest_score:
						lowest_score = score
						lowest_card = card_key
				if lowest_card:
					max_meld['card_keys'].erase(lowest_card)
					# Check if the meld is still valid
					var is_valid = false
					if max_meld['type'] == 'group':
						is_valid = Global.is_valid_group(max_meld['card_keys'])
					elif max_meld['type'] == 'run':
						is_valid = Global.is_valid_run(max_meld['card_keys'])
					if not is_valid:
						# Add all cards from the invalid meld to recommended_discards
						for card_key in max_meld['card_keys']:
							if not card_key in acc['recommended_discards']:
								acc['recommended_discards'].append(card_key)
						acc['can_be_personally_melded'].erase(max_meld)
					# Add the removed card to recommended_discards
					acc['recommended_discards'].append(lowest_card)
					acc['recommended_discards'] = Global.sort_card_keys_by_score(acc['recommended_discards'])
					# Recalculate penalty
					penalty_score = - Global.tally_hand_cards_score(acc['recommended_discards'])
					acc['eval_score'] += penalty_score

	# Prevent melding if it would leave no cards to discard in rounds 1-6
	if round_num < 7 and len(acc['recommended_discards']) == 0:
		acc['can_be_personally_melded'] = []

	if melded_groups == num_groups and melded_runs == num_runs:
		acc['is_winning_hand'] = (round_num < 7 and len(acc['recommended_discards']) == 1) or (round_num == 7 and len(acc['recommended_discards']) == 0)
		if acc['is_winning_hand']:
			acc['eval_score'] += 1000 # bonus for winning

	return acc

func _evaluate_hand_post_meld(round_num: int, hand_stats: Dictionary, all_public_meld_stats: Dictionary) -> Dictionary:
	var acc = Global.empty_evaluation()
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
		Global.dbg("ERROR! available_jokers=%s but should be 0" % [str(available_jokers)])

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
	var penalty_cards_score = - Global.tally_hand_cards_score(penalty_cards)
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
	save_for_last = Global.sort_card_keys_by_score(save_for_last)

	for rank in hand_stats['by_rank']:
		var card_keys = hand_stats['by_rank'][rank]
		for card_key in card_keys:
			if card_key in already_used:
				continue
			if _is_publicly_meldable(rank, card_key, all_public_meld_stats):
				save_for_last.append(card_key)
				continue
			acc['recommended_discards'].append(card_key)

	acc['recommended_discards'] = Global.sort_card_keys_by_score(acc['recommended_discards'])
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
	for ppi in Global.game_state.public_players_info:
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

	return Global.is_valid_run(test_run_front) or Global.is_valid_run(test_run_back)

func _can_card_replace_joker_in_run(card_key: String, pub_meld: Dictionary) -> bool:
	# Get all cards in the public run to determine if this card can replace a joker
	var run_cards = []
	var player_id = pub_meld['player_id']
	var meld_group_index = pub_meld['meld_group_index']

	# Find the actual run by looking at the player's played_to_table
	for ppi in Global.game_state.public_players_info:
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
			if Global.is_valid_run(test_run):
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
	if Global.is_valid_run(new_run):
		return {'success': true, 'run': new_run}

	# Try adding to back
	new_run = card_keys + [card_key]
	if Global.is_valid_run(new_run):
		return {'success': true, 'run': new_run}

	return {'success': false}
