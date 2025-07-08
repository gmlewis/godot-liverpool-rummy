extends Bot
class_name BasicBot
# This bot makes a best attempt at building the current round's hand.

func get_bot_name() -> String:
	return 'Basic %s' % bot_id

func _on_new_discard_state_entered() -> void:
	Global.dbg("BOT('%s'): ENTER _on_new_discard_state_entered()" % get_bot_name())
	var current_hand_stats = gen_current_hand_stats()
	var current_hand_evaluation = Global.evaluate_hand(current_hand_stats, bot_id)
	Global.dbg("BOT('%s'): _on_new_discard_state_entered: current_hand_evaluation=%s" % [get_bot_name(), str(current_hand_evaluation)])
	var current_eval_score = current_hand_evaluation['eval_score']
	var want_discard_card = do_i_want_discard_card(current_hand_stats, current_eval_score)
	if not is_my_turn:
		if want_discard_card:
			Global.request_to_buy_card_from_discard_pile(bot_id)
		Global.dbg("BOT('%s'): LEAVE1 _on_new_discard_state_entered()" % get_bot_name())
		return
	# Now, if we don't want the discard card, allow outstanding buy requests and re-evaluate after each buy.
	if not want_discard_card and len(Global.discard_pile) > 0 and Global.has_outstanding_buy_request():
		Global.dbg("BOT('%s'): _on_new_discard_state_entered: allowing next buy request" % [get_bot_name()])
		Global.allow_outstanding_buy_request(bot_id)
		Global.dbg("BOT('%s'): LEAVE2 _on_new_discard_state_entered()" % get_bot_name())
		return
	if want_discard_card:
		_draw_card_from_discard_pile()
		return
	_draw_card_from_stock_pile()
	Global.dbg("BOT('%s'): LEAVE3 _on_new_discard_state_entered()" % get_bot_name())

# Use the base class' smart discard logic.
