extends Bot
class_name StingyBot
# This bot always declines a request to buy a card and will
# draw from the drawing_pile if asked by anyone to buy.
# Otherwise, it attempts to build the current round's hand.
# It never attmpts to buy a card from the discard pile.

func get_bot_name() -> String:
	return 'Stingy %s' % bot_id

func _on_new_discard_state_entered() -> void:
	if not is_my_turn: return
	Global.dbg("BOT('%s'): ENTER _on_new_discard_state_entered()" % get_bot_name())
	if Global.has_outstanding_buy_request():
		_draw_card_from_discard_pile() # prevent other player from buying
	else:
		var want_discard_card = simplified_do_i_want_discard_card()
		if want_discard_card:
			_draw_card_from_discard_pile()
		else:
			_draw_card_from_stock_pile()
	Global.dbg("BOT('%s'): LEAVE _on_new_discard_state_entered()" % get_bot_name())

# Use the base class' smart discard logic.
