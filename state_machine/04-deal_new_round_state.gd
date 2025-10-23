extends GameState

@onready var playing_cards_control: Control = $'../../PlayingCardsControl'
@onready var players_container: Node2D = $'../../AllPlayersControl/PlayersContainer'

# This is the number of cards dealt to each player, keyed by the round number.
const NUM_CARDS_PER_PLAYER = {1: 6, 2: 7, 3: 8, 4: 9, 5: 10, 6: 11, 7: 12}

func enter(_params: Dictionary):
	Global.dbg("ENTER DealNewRoundState: deal_speed_pixels_per_second=%0.1f" % [Global.deal_speed_pixels_per_second])
	var num_players = len(Global.game_state.public_players_info)
	assert(num_players >= 2, "There must be at least 2 players to start a new round.")
	assert(len(Global.playing_cards) > 0, "No playing cards found in Global.playing_cards.")
	var round_num = Global.game_state.current_round_num
	assert(round_num >= 1 && round_num <= 7, "Invalid round number: %d" % [Global.game_state.current_round_num])
	var cards_per_player = NUM_CARDS_PER_PLAYER[Global.game_state.current_round_num]
	await deal_cards_to_players(round_num, cards_per_player)
	await resize_stock_pile_to_resting_size()
	# Flip over the top card of the stock pile and place on the discard pile to reveal the next card.
	if Global.is_server():
		Global.register_ack_sync_state('RevealTopCardState', {'next_state': 'NewDiscardState'})
	transition_state_to('RevealTopCardState')

func exit():
	Global.dbg("LEAVE DealNewRoundState")

func resize_stock_pile_to_resting_size() -> void:
	var tween = playing_cards_control.create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	for card in Global.stock_pile:
		# tween.tween_property(card, 'position', Vector2(Global.stock_pile_position.x, card.position.y), 0.5)
		tween.tween_property(card, 'scale', Global.PLAYER_SCALE, 0.5)
	await tween.finished

# Deals cards in the classic card game style, where cards are dealt one at a time
# to each player in a round-robin fashion, starting with the nth player to the host's
# right, where n is the round number. Each PlayeringCard rotates to the exact position,
# rotation, and scale of each [Player] in the [PlayersContainer] (located in the [AllPlayerControl] node).
# All animations are performed in a single [tween] and the final tween is awaited until finished.
# When each card lands to its final position, the card is hidden and the [card_keys_in_hand] property
# of the [Player] is updated with the new [key] of the [PlayingCard] by an [rpc_id] message sent
# from the host/server (only to that one client).
func deal_cards_to_players(round_num: int, cards_per_player: int) -> void:
	var players = Global.game_state.public_players_info
	var num_players = len(players)
	var total_cards = num_players * cards_per_player
	var num_cards_in_stock_pile = playing_cards_control.get_child_count()
	if num_cards_in_stock_pile == 0 or num_cards_in_stock_pile != len(Global.stock_pile):
		Global.dbg("FATAL: Mismatch in stock pile size: %d vs %d" % [num_cards_in_stock_pile, len(Global.stock_pile)])
		return
	# DEVELOPMENT3: Force way more cards to be dealt so that melding can be tested easily:
	total_cards = min(total_cards + 50, num_cards_in_stock_pile) # ONLY FOR TESTING!!!

	if total_cards > num_cards_in_stock_pile:
		# TODO: Handle this case more gracefully, e.g. by reshuffling the discard pile
		Global.dbg("Not enough cards in stock pile to deal %d cards to %d players for round %d. Only %d cards available." % [total_cards, num_players, round_num, num_cards_in_stock_pile])
		return
	var player_target_nodes = {} # keyed by player ID
	for player in players_container.get_children():
		if player.player_id:
			player_target_nodes[player.player_id] = player
	# var stock_pile_cards = playing_cards_control.get_children()
	# Sort cards by z_index in descending order so that the top card is at the start of the array.
	# stock_pile_cards.sort_custom(func(a, b): return a.z_index > b.z_index)
	Global.dbg("deal_cards_to_players: stock_pile_cards=%d, num_players=%d, total_cards=%d, round_num=%d" % [len(Global.stock_pile), num_players, total_cards, round_num])

	for card_index in range(total_cards):
		var player_index = (card_index + round_num) % num_players # Start with the nth player to the host's right, where n is the round number
		var player = players[player_index]
		var player_target_node = player_target_nodes[player.id]
		# num_cards_in_stock_pile -= 1
		# var playing_card = stock_pile_cards[card_index]
		var playing_card = Global.stock_pile.pop_front() # Get the top card from the stock pile
		if not playing_card:
			Global.dbg("PROGRAMMING ERROR: Global.stock_pile is empty!!!")
			break
		# Global.dbg("Dealing card %d/%d to player %s (%s): %s" % [card_index + 1, total_cards, player.name, player.id, playing_card.key])
		# Determine how long this animation should take based on the travel distance.
		var card_travel_distance = player_target_node.position.distance_to(playing_card.position)
		var card_duration = card_travel_distance / Global.deal_speed_pixels_per_second
		# Global.dbg("GML: card_travel_distance=%0.2f, card_duration=%0.2f" % [card_travel_distance, card_duration])
		# Set up the tween for the card to move to the player's position
		var card_tween = playing_card.create_tween()
		card_tween.set_parallel(true)
		if Global.private_player_info.id == player.id:
			# For the local player, move the card to the player's hand position based on the number of cards they already have.
			var card_hand_idx = len(Global.private_player_info.card_keys_in_hand)
			Global.private_player_info.card_keys_in_hand.append(playing_card.key) # Update the local player's hand
			var card_x = gen_card_deal_position_x(card_hand_idx, cards_per_player)
			var card_y = gen_card_deal_position_y(card_hand_idx, cards_per_player)
			var player_card_position = Vector2(card_x, card_y)
			card_tween.tween_property(playing_card, "position", player_card_position, card_duration)
			card_tween.tween_property(playing_card, "rotation", 0, card_duration)
			card_tween.tween_property(playing_card, "z_index", 20.0 + card_hand_idx, 0.01).set_delay(card_duration)
		else:
			if Global.is_server() and player.is_bot:
				Global.bots_private_player_info[player.id].card_keys_in_hand.append(playing_card.key) # Update the bot's hand
			card_tween.tween_property(playing_card, "position", player_target_node.position, card_duration)
			card_tween.tween_property(playing_card, "rotation", player_target_node.rotation, card_duration)
			card_tween.tween_property(playing_card, "z_index", 20.0, 0.01).set_delay(card_duration)
		card_tween.tween_property(playing_card, "scale", player_target_node.scale, card_duration)

		# Hide/flip the card after it lands
		var hide_or_flip_card = func() -> void:
			player['num_cards'] += 1 # Update the player's num_cards property
			player_target_node._on_game_state_updated_signal() # Update the player's UI
			if Global.private_player_info.id == player.id:
				playing_card.flip_card() # Flip the card for the local player
				playing_card.is_draggable = true
				playing_card.is_tappable = true
			else:
				playing_card.hide() # Hide the card for remote players
				playing_card.is_draggable = false
				playing_card.is_tappable = false
		card_tween.tween_callback(hide_or_flip_card).set_delay(card_duration)
		await card_tween.finished
	# Finally, force all cards in the player's hand to be face up in case any were dealt face down (due to a bug above?!?!?)
	for card_key in Global.private_player_info.card_keys_in_hand:
		var card = Global.playing_cards.get(card_key) as PlayingCard
		card.force_face_up()
	Global.dbg("Dealt %d cards to %d players for round %d." % [total_cards, num_players, round_num])

func gen_card_deal_position_x(card_hand_idx: int, cards_per_player: int) -> float:
	var card_x = Global.player_hand_x_start() + (card_hand_idx * (Global.player_hand_x_end - Global.player_hand_x_start()) / (cards_per_player - 1))
	if card_x > Global.screen_size.x - 50.0: # happens during debugging with extra cards
		card_x = Global.screen_size.x / 2.0
	return card_x

func gen_card_deal_position_y(card_hand_idx: int, _cards_per_player: int) -> float:
	# Alternate Y position slightly to make overlapping cards easier to read during dealing
	var base_y = Global.player_hand_y_position
	var alternation_offset = -30.0 # pixels to alternate upward for odd cards
	var alternation = (card_hand_idx % 2) * 2
	return base_y + (alternation * alternation_offset)
