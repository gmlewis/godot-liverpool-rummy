extends Node
class_name Bot
# This is the base class for all bots.

@onready var game_state_machine: Node = $"/root/RootNode/GameStateMachine"

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
	game_state_machine.connect('gsm_changed_state_signal', _on_gsm_changed_state_signal)
	Global.connect('new_card_exposed_on_discard_pile_signal', _on_new_card_exposed_on_discard_pile_signal)
	Global.connect('server_ack_sync_completed_signal', _on_server_ack_sync_completed_signal)
	Global.dbg("BOT('%s') is ready." % get_bot_name())

func _exit_tree() -> void:
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
	var current_hand_stats = Global.gen_hand_stats(card_keys_in_hand)
	# Global.dbg("BOT('%s'): _on_player_drew_state_entered: current_hand_stats=%s" % [get_bot_name(), str(current_hand_stats)])
	var current_hand_evaluation = Global.evaluate_hand(current_hand_stats, bot_id)
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
	var current_hand_stats = Global.gen_hand_stats(card_keys_in_hand)
	# Global.dbg("BOT('%s'): gen_current_hand_stats: current_hand_stats=%s" % [get_bot_name(), str(current_hand_stats)])
	return current_hand_stats

func do_i_want_discard_card(current_hand_stats: Dictionary, current_eval_score: int) -> bool:
	if len(Global.discard_pile) == 0: return false
	var discard_card_key = Global.discard_pile[0].key
	var hand_stats_with_discard = Global.add_card_to_stats(current_hand_stats.duplicate(true), discard_card_key)
	var hand_evaluation_with_discard = Global.evaluate_hand(hand_stats_with_discard, bot_id)
	# Global.dbg("BOT('%s'): do_i_want_discard_card: hand_stats_with_discard=%s; hand_evaluation_with_discard=%s" % [get_bot_name(), str(hand_stats_with_discard), str(hand_evaluation_with_discard)])
	var eval_score_with_discard = hand_evaluation_with_discard['eval_score']
	var discard_key_in_discards = discard_card_key in hand_evaluation_with_discard['recommended_discards']
	# If this hand with the discard card is better than the current hand,
	# and the discard card does not show up in the 'recommended_discards' array,
	# then we want to draw the discard card.
	if eval_score_with_discard > current_eval_score and discard_key_in_discards:
		Global.dbg("ERROR: BOT('%s'): do_i_want_discard_card: eval_score_with_discard=%d > current_eval_score=%d, discard_key_in_discards=%s" % [get_bot_name(), eval_score_with_discard, current_eval_score, str(discard_key_in_discards)])
	elif eval_score_with_discard > current_eval_score:
		# Global.dbg("BOT('%s'): do_i_want_discard_card: eval_score_with_discard=%d > current_eval_score=%d, want_discard_card=true" % [get_bot_name(), eval_score_with_discard, current_eval_score])
		return true
	# Global.dbg("BOT('%s'): do_i_want_discard_card: eval_score_with_discard=%d <= current_eval_score=%d, want_discard_card=false" % [get_bot_name(), eval_score_with_discard, current_eval_score])
	return false

func simplified_do_i_want_discard_card() -> bool:
	if not is_my_turn: return false
	var current_hand_stats = gen_current_hand_stats()
	var current_hand_evaluation = Global.evaluate_hand(current_hand_stats, bot_id)
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
		Global.dbg("ERROR: BOT('%s'): No cards in hand to discard!" % get_bot_name())
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
	var current_hand_stats = Global.gen_hand_stats(card_keys_in_hand)
	var current_hand_evaluation = Global.evaluate_hand(current_hand_stats, bot_id)
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
