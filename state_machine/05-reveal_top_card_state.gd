extends GameState

@onready var playing_cards_control: Control = $'../../PlayingCardsControl'

func enter(_params: Dictionary):
	Global.dbg("ENTER RevealTopCardState")
	await flip_over_top_card()
	Global.ack_sync_completed('RevealTopCardState')

func exit():
	Global.dbg("LEAVE RevealTopCardState")

func flip_over_top_card() -> void:
	# TODO: Handle the case where the stock pile is empty.
	var new_discard_pile_top_card = Global.stock_pile.pop_front() as PlayingCard
	Global.dbg("RevealTopCardState: Flipping over top card: %s" % [str(new_discard_pile_top_card)])
	Global.dbg("stock_pile_position=%s" % [Global.stock_pile_position])
	Global.discard_pile.push_front(new_discard_pile_top_card)
	var new_z_index = len(Global.discard_pile)
	var tween = playing_cards_control.create_tween()
	tween.set_parallel(true)
	var new_position = Global.discard_pile_position + Vector2(randf_range(-2, 2), -new_z_index * Global.CARD_SPACING_IN_STACK)
	Global.dbg("RevealTopCardState: New position for top card: %s, z_index=%d" % [str(new_position), new_z_index])
	var flip_duration = 0.5
	tween.tween_property(new_discard_pile_top_card, "position", new_position, flip_duration)
	tween.tween_property(new_discard_pile_top_card, "z_index", new_z_index, flip_duration).set_delay(flip_duration * 0.5)
	tween.tween_callback(new_discard_pile_top_card.flip_card).set_delay(flip_duration * 0.5)
	await tween.finished
	# Now mark the top card as tappable for all players.
	new_discard_pile_top_card.is_tappable = true
	# For the current player, mark the top of the both piles as draggable and tappable.
	# TODO: Handle the case where the stock pile is empty.
	var round_num = Global.game_state.current_round_num
	var current_player_index = round_num % len(Global.game_state.public_players_info)
	Global.dbg("RevealTopCardState: current_player_index=%d, round_num=%d" % [current_player_index, round_num])
	if Global.private_player_info.id == Global.game_state.public_players_info[current_player_index].id:
		var new_stock_pile_top_card = Global.stock_pile[0] as PlayingCard
		Global.dbg("RevealTopCardState: Marking stock pile top card as tappable for player idx=%d %s: %s" %
			[current_player_index, Global.private_player_info.id, str(new_stock_pile_top_card)])
		new_stock_pile_top_card.is_draggable = false
		new_stock_pile_top_card.is_tappable = true
		new_discard_pile_top_card.is_draggable = false
