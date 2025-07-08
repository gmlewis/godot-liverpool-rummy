extends Bot
class_name DumbBot
# This bot randomly picks a card and randomly discards (but not the last drawn from the discard pile).
# The DumpBot can actually win due to its intelligent discard.

func get_bot_name() -> String:
	return 'Dumb %s' % bot_id

func _on_new_discard_state_entered() -> void:
	if not is_my_turn: return
	Global.dbg("BOT('%s'): ENTER _on_new_discard_state_entered()" % get_bot_name())
	if randf() < 0.5 and len(Global.discard_pile) > 0:
		_draw_card_from_discard_pile()
	elif Global.has_outstanding_buy_request():
		Global.dbg("BOT('%s'): calling: allow_outstanding_buy_request and returning" % get_bot_name())
		Global.allow_outstanding_buy_request(bot_id)
	else:
		_draw_card_from_stock_pile()
	Global.dbg("BOT('%s'): LEAVE _on_new_discard_state_entered()" % get_bot_name())
