extends GameState
# This state is entered when a player has drawn a card from either pile
# and must complete their turn by either discarding a card or playing their
# tableau in the final round.

@onready var playing_cards_control: Control = $'../../PlayingCardsControl'
@onready var players_container: Node2D = $'../../AllPlayersControl/PlayersContainer'

var is_my_turn: bool = false

const REVEAL_MELD_SCALE = Vector2(0.25, 0.25)

# TODO: Buy requests should be disallowed and ignored in this state!

func enter(_params: Dictionary):
	is_my_turn = Global.is_my_turn()
	Global.dbg("ENTER PlayerDrewState: is_my_turn=%s" % [str(is_my_turn)])
	Global.connect('card_clicked_signal', _on_card_clicked_signal)
	Global.connect('card_drag_started_signal', _on_card_drag_started_signal)
	Global.connect('card_moved_signal', _on_card_moved_signal)
	Global.connect('animate_move_card_from_player_to_discard_pile_signal', _on_animate_move_card_from_player_to_discard_pile_signal)
	Global.connect('animate_personally_meld_cards_only_signal', _on_animate_personally_meld_cards_only_signal)
	Global.connect('animate_publicly_meld_card_only_signal', _on_animate_publicly_meld_card_only_signal)

	# MUST discard - do not enable tap or drag of either pile.
	if len(Global.discard_pile) > 0:
		Global.discard_pile[0].is_draggable = false
		Global.discard_pile[0].is_tappable = false
	if len(Global.stock_pile) > 0:
		Global.stock_pile[0].is_draggable = false
		Global.stock_pile[0].is_tappable = false


func exit():
	Global.dbg("LEAVE PlayerDrewState")
	Global.disconnect('card_clicked_signal', _on_card_clicked_signal)
	Global.disconnect('card_drag_started_signal', _on_card_drag_started_signal)
	Global.disconnect('card_moved_signal', _on_card_moved_signal)
	Global.disconnect('animate_move_card_from_player_to_discard_pile_signal', _on_animate_move_card_from_player_to_discard_pile_signal)
	Global.disconnect('animate_personally_meld_cards_only_signal', _on_animate_personally_meld_cards_only_signal)
	Global.disconnect('animate_publicly_meld_card_only_signal', _on_animate_publicly_meld_card_only_signal)

func _on_card_clicked_signal(_playing_card, _global_position):
	pass

func _on_card_drag_started_signal(_playing_card, _from_position):
	pass

func _on_card_moved_signal(_playing_card, _from_position, _global_position):
	pass


func _on_animate_move_card_from_player_to_discard_pile_signal(playing_card: PlayingCard, player_id: String, player_won: bool, ack_sync_name: String) -> void:
	var players = players_container.get_children().filter(func(node): return node.player_id == player_id)
	if len(players) != 1:
		push_error("Player node not found for player_id: %s" % player_id)
		return
	var player = players[0] as Node2D
	var players_by_id = Global.get_players_by_id()
	var player_public_info = players_by_id[player_id]
	player_public_info['num_cards'] -= 1
	player._on_game_state_updated_signal() # Update the player's UI
	if not playing_card.is_face_up and not player_won:
		playing_card.flip_card() # Flip the card to face-up for the local player so it can be seen while animating
	# elif playing_card.is_face_up and player_won:
	# 	playing_card.flip_card() # Flip the card to face-down for the winning local player

	var card_tween = playing_cards_control.create_tween()
	card_tween.set_parallel(true)
	tween_card_to_discard_pile(player, player_id, card_tween, playing_card, player_won)
	await card_tween.finished
	if ack_sync_name:
		Global.ack_sync_completed(ack_sync_name)

func _on_animate_personally_meld_cards_only_signal(player_id: String, hand_evaluation: Dictionary, ack_sync_name: String) -> void:
	# var player_is_me = Global.private_player_info.id == player_id
	var players = players_container.get_children().filter(func(node): return node.player_id == player_id)
	if len(players) != 1:
		push_error("Player node not found for player_id: %s" % player_id)
		return
	var player = players[0] as Node2D
	var players_by_id = Global.get_players_by_id()
	var player_public_info = players_by_id[player_id]

	var meld_tween = playing_cards_control.create_tween()
	meld_tween.set_parallel(true)

	for meld_idx in len(hand_evaluation['can_be_personally_melded']):
		var meld_group = hand_evaluation['can_be_personally_melded'][meld_idx]
		var meld_group_card_keys = meld_group['card_keys']
		for card_idx in len(meld_group_card_keys):
			var card_key = meld_group_card_keys[card_idx]
			player_public_info['num_cards'] -= 1
			var playing_card = Global.playing_cards.get(card_key) as PlayingCard
			tween_card_into_personal_meld_group(player, player_id, meld_tween, playing_card, meld_idx, card_idx)

	# TODO: Make these separately-synced animations
	# for card_idx in len(hand_evaluation['can_be_publicly_melded']):
	# 	var card_key = hand_evaluation['can_be_publicly_melded'][card_idx]
	# 	player_public_info['num_cards'] -= 1
	# 	var playing_card = Global.playing_cards.get(card_key) as PlayingCard
	# 	tween_card_into_public_meld_group(player, player_id, meld_tween, playing_card, card_key)
	# if len(hand_evaluation['recommended_discards']) > 0:
	# 	var card_key = hand_evaluation['recommended_discards'][0]
	# 	player_public_info['num_cards'] -= 1
	# 	var playing_card = Global.playing_cards.get(card_key) as PlayingCard
	# 	tween_card_to_discard_pile(player, player_id, meld_tween, playing_card, hand_evaluation['is_winning_hand'])

	await meld_tween.finished
	if ack_sync_name:
		Global.ack_sync_completed(ack_sync_name)

func _on_animate_publicly_meld_card_only_signal(_player_id: String, card_key: String, target_player_id: String, meld_group_index: int, ack_sync_name: String) -> void:
	var players = players_container.get_children().filter(func(node): return node.player_id == target_player_id)
	if len(players) != 1:
		push_error("Player node not found for target_player_id: %s" % target_player_id)
		return
	var target_player = players[0] as Node2D
	var players_by_id = Global.get_players_by_id()
	var player_public_info = players_by_id[target_player_id]
	player_public_info['num_cards'] -= 1
	var meld_group = player_public_info['played_to_table'][meld_group_index]
	var card_idx = len(meld_group['card_keys']) - 1
	var playing_card = Global.playing_cards.get(card_key) as PlayingCard
	var meld_tween = playing_cards_control.create_tween()
	meld_tween.set_parallel(true)
	tween_card_into_personal_meld_group(target_player, target_player_id, meld_tween, playing_card, meld_group_index, card_idx)
	await meld_tween.finished
	if ack_sync_name:
		Global.ack_sync_completed(ack_sync_name)

func tween_card_into_personal_meld_group(player: Node2D, player_id: String, meld_tween: Tween, playing_card: PlayingCard, meld_idx: int, card_idx: int) -> void:
	var player_is_me = Global.private_player_info.id == player_id
	if not player_is_me:
		playing_card.position = player.position
		playing_card.rotation = player.rotation
	playing_card.is_draggable = false
	playing_card.is_tappable = false
	playing_card.z_index = 20 # TODO
	playing_card.show()
	# if not playing_card.is_face_up: # TODO
	# 	await playing_card.flip_card()

	var meld_pile_position = player.position + Vector2(75 * meld_idx - 50, 200 + 25 * card_idx)
	var card_travel_distance = meld_pile_position.distance_to(playing_card.position)
	var card_duration = card_travel_distance / Global.play_speed_pixels_per_second

	meld_tween.tween_property(playing_card, "position", meld_pile_position, card_duration)
	meld_tween.tween_property(playing_card, "rotation", 0.0, card_duration)
	meld_tween.tween_property(playing_card, "scale", REVEAL_MELD_SCALE, card_duration)
	meld_tween.tween_property(playing_card, "z_index", 2 + card_idx, card_duration)

	# Flip the card after it lands
	var hide_or_flip_card = func() -> void:
		if not playing_card.is_face_up:
			playing_card.flip_card() # Flip the card for the local player
	meld_tween.tween_callback(hide_or_flip_card).set_delay(card_duration)

func tween_card_into_public_meld_group(player: Node2D, player_id: String, _meld_tween: Tween, playing_card: PlayingCard, _ard_key: String) -> void:
	var player_is_me = Global.private_player_info.id == player_id
	if not player_is_me:
		playing_card.position = player.position
		playing_card.rotation = player.rotation
	playing_card.is_draggable = false
	playing_card.is_tappable = false
	playing_card.z_index = 20 # TODO
	playing_card.show()
	if not playing_card.is_face_up:
		await playing_card.flip_card()
	# TODO: Find public meld group position based on card_key

func tween_card_to_discard_pile(player: Node2D, player_id: String, discard_tween: Tween, playing_card: PlayingCard, is_winning_hand: bool) -> void:
	var player_is_me = Global.private_player_info.id == player_id
	if not player_is_me:
		playing_card.position = player.position
		playing_card.rotation = player.rotation
	playing_card.is_draggable = false
	playing_card.is_tappable = false
	playing_card.z_index = len(Global.discard_pile)
	playing_card.show()

	var discard_pile_position = Global.discard_pile_position + Vector2(randf_range(-2, 2), -playing_card.z_index * Global.CARD_SPACING_IN_STACK)
	var card_travel_distance = discard_pile_position.distance_to(playing_card.position)
	var card_duration = card_travel_distance / Global.play_speed_pixels_per_second

	discard_tween.tween_property(playing_card, "position", discard_pile_position, card_duration)
	var rotation = randf_range(-0.1, 0.1)
	discard_tween.tween_property(playing_card, "rotation", rotation, card_duration)

	# Flip the card after it lands
	var hide_or_flip_card = func() -> void:
		if not playing_card.is_face_up and not is_winning_hand:
			playing_card.flip_card() # Flip the card to face up
		elif playing_card.is_face_up and is_winning_hand:
			playing_card.flip_card() # Flip the card to face down
	discard_tween.tween_callback(hide_or_flip_card).set_delay(card_duration)
