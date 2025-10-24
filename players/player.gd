extends Node2D
# class_name Player

@onready var game_state_machine: Node = $"/root/RootNode/GameStateMachine"

signal _local_player_is_meldable_signal(public_meld_possibility: Dictionary) # Used locally to communicate with other player nodes.

var player_id: String
var player_name: String
var turn_index: int

# is_my_turn is used to animate the turn indicator (for live players only).
var is_my_turn: bool = false
var is_buying_card: bool = false # Used to animate the turn indicator when buying a card.
var is_meldable: bool = false # Used to animate the turn indicator when meldable (by current player or any other player).
var is_winning_player: bool = false # Used to indicate if this player is the winning player in the current round.

# When another player wishes to meld on this player, the possibilities are saved here for the upcoming click:
var local_public_meld_possibilities: Array = []

const TURN_INDICATOR_DRAW_COLOR = Color(1.0, 0.45, 0.17, 1.0) # Orange color
const TURN_INDICATOR_DISCARD_COLOR = Color(0.8, 0.2, 0.8, 1.0) # Purple color
const TURN_INDICATOR_MELD_COLOR = Color(0.38, 0.73, 0.4, 1.0) # Greenish color

var last_hand_evaluation = null # Used to store the last hand evaluation for the player, used when melding.

var hack_hide_meld_indicator_next_frame: bool = false # Used to prevent meld flash after discard.

func _ready():
	# Global.dbg('Player Node2D ready: player_id=%s, player_name=%s, num_cards=%d, score=%d, turn_index=%d' % [player_id, player_name, num_cards, score, turn_index])
	_on_custom_card_back_texture_changed_signal()
	Global.connect('custom_card_back_texture_changed_signal', _on_custom_card_back_texture_changed_signal)
	Global.connect('game_state_updated_signal', _on_game_state_updated_signal)
	Global.connect('card_clicked_signal', _on_card_clicked_signal)
	Global.connect('card_drag_started_signal', _on_card_drag_started_signal)
	Global.connect('card_moved_signal', _on_card_moved_signal)
	Global.connect('all_meld_area_states_updated_signal', _on_all_meld_area_states_updated_signal)
	connect('_local_player_is_meldable_signal', _on_local_player_is_meldable_signal)
	game_state_machine.connect('gsm_changed_state_signal', _on_gsm_changed_state_signal)
	$PlayerNameLabel.text = player_name
	$TurnIndicatorRect.scale = Vector2(0.1, 0.1) # Hide turn indicator at start
	$TurnIndicatorRect.color = TURN_INDICATOR_DRAW_COLOR # Set initial color to draw color
	$TurnIndicatorRect.show()
	$BuyIndicatorSprite2D.hide()
	$MeldIndicatorSprite2D.hide()
	_set_num_cards(0)

func _exit_tree():
	Global.disconnect('custom_card_back_texture_changed_signal', _on_custom_card_back_texture_changed_signal)
	Global.disconnect('game_state_updated_signal', _on_game_state_updated_signal)
	Global.disconnect('card_clicked_signal', _on_card_clicked_signal)
	Global.disconnect('card_drag_started_signal', _on_card_drag_started_signal)
	Global.disconnect('card_moved_signal', _on_card_moved_signal)
	Global.disconnect('all_meld_area_states_updated_signal', _on_all_meld_area_states_updated_signal)
	disconnect('_local_player_is_meldable_signal', _on_local_player_is_meldable_signal)
	game_state_machine.disconnect('gsm_changed_state_signal', _on_gsm_changed_state_signal)

func _on_custom_card_back_texture_changed_signal():
	$CardBackSprite2D.texture = Global.custom_card_back.texture

func _set_num_cards(num_cards: int) -> void:
	if num_cards == 1:
		$CardCountLabel.text = '1 card'
	else:
		$CardCountLabel.text = '%d cards' % num_cards

func _set_score(score: int) -> void:
	# Do not set the score during the "TallyScoresState" state, as we wish to keep the current score visible
	# until the start of the next round.
	if game_state_machine.get_current_state_name() == 'TallyScoresState':
		return
	$ScoreLabel.text = '%d pts' % score

func _on_gsm_changed_state_signal(_from_state: String, _to_state: String):
	_on_game_state_updated_signal()

func _on_game_state_updated_signal():
	var players_by_id = Global.get_players_by_id()
	if not player_id in players_by_id:
		# This player was removed from the game. root_node.gd will remove this player instance.
		return
	var public_player_info = players_by_id[player_id]
	if not public_player_info:
		push_error("Player info not found for player_id: %s" % player_id)
		return
	# Global.dbg("Player('%s'): _on_game_state_updated_signal: public_player_info=%s" % [player_id, str(public_player_info)])
	_set_num_cards(public_player_info.num_cards)
	_set_score(public_player_info.score)

	is_buying_card = Global.game_state.current_buy_request_player_ids.has(player_id)
	if is_buying_card:
		$BuyIndicatorSprite2D.show() # Show buy indicator
	else:
		$BuyIndicatorSprite2D.hide() # Hide buy indicator
	is_meldable = false # Reset meldable state
	# if is_meldable:
	# 	$MeldIndicatorSprite2D.show() # Show meld indicator
	# else:
	$MeldIndicatorSprite2D.hide() # Hide meld indicator

	var current_state_name = game_state_machine.get_current_state_name()
	var num_cards = public_player_info['num_cards']
	is_winning_player = current_state_name == 'PlayerWonRoundState' and num_cards == 0
	Global.dbg("Player('%s'): _on_game_state_updated_signal: current_state='%s', num_cards=%d, is_winning_player=%s" % [player_id, current_state_name, num_cards, str(is_winning_player)])
	if is_winning_player:
		Global.dbg("Player('%s'): *** WINNING PLAYER ANIMATION TRIGGERED ***" % [player_id])
		$TurnIndicatorRect.color = Color(0.8, 0.8, 0.2, 1.0) # Set color to yellow for winning player
		$TurnIndicatorRect.scale = Vector2(1.2, 1.2) # Show turn indicator
		Global.make_discard_pile_tappable(false)
		Global.make_stock_pile_tappable(false)
		return
	else:
		if current_state_name == 'PlayerWonRoundState' and num_cards != 0:
			Global.dbg("Player('%s'): *** WARNING: PlayerWonRoundState but num_cards=%d (expected 0) - animation NOT triggered ***" % [player_id, num_cards])
		$TurnIndicatorRect.color = TURN_INDICATOR_DRAW_COLOR # reset
		$TurnIndicatorRect.rotation = 0.0

	# Global.dbg("Player: _on_game_state_updated_signal for player %s (turn_index=%d), current_player_turn_index=%d" % [player_name, turn_index, Global.game_state.current_player_turn_index])
	# This is called when the game state changes.
	# Update the player's turn indicator based on the current game state.
	# Bots don't have a display, so this is always false for them.
	is_my_turn = Global.private_player_info.id == player_id and Global.is_my_turn()
	if not is_my_turn:
		# This section runs for bots (their turn or not) and for live players when it is not their turn.
		# # Does this belong here? - NO!
		# Global.dbg("Player('%s'): _on_game_state_updated_signal: is_my_turn=%s, current_state_name='%s', changing stock pile and discard pile tappable settings" % [player_id, is_my_turn, current_state_name])
		# Global.make_discard_pile_tappable(true)
		# Global.make_stock_pile_tappable(false)
		if turn_index == Global.game_state.current_player_turn_index and game_state_machine.is_playing_state():
			# Global.dbg("Player: Showing turn indicator for player %s (turn_index=%d)" % [player_name, turn_index])
			$TurnIndicatorRect.scale = Vector2(1.2, 1.2) # Show turn indicator
		else:
			# Global.dbg("Player: Hiding turn indicator for player %s (turn_index=%d)" % [player_name, turn_index])
			$TurnIndicatorRect.scale = Vector2(0.1, 0.1) # Hide turn indicator
		return
	# This section runs only for live players when it is their turn.
	Global.dbg("Player('%s'): _on_game_state_updated_signal: public_player_info=%s" % [player_id, str(public_player_info)])
	var already_melded = len(public_player_info['played_to_table']) > 0
	_update_turn_indicator_color(current_state_name, already_melded)
	_update_hand_meldability()

func _update_hand_meldability() -> void:
	var current_state_name = game_state_machine.get_current_state_name()
	if current_state_name != 'PlayerDrewState': return

	var players_by_id = Global.get_players_by_id()
	var public_player_info = players_by_id[player_id]
	var already_melded = len(public_player_info['played_to_table']) > 0
	if already_melded: return # This method now is only used for pre-meld evaluation.
	# Now see if the player can meld (more of) their hand.
	# var card_keys_in_hand = ['card_keys_in_hand']
	var current_hand_stats = gen_player_hand_stats(Global.private_player_info)
	# Store the last hand evaluation for melding when user clicks on the player.
	last_hand_evaluation = evaluate_player_hand(current_hand_stats)
	is_meldable = false
	$MeldIndicatorSprite2D.hide()
	if len(last_hand_evaluation['can_be_personally_melded']) == 0: return
	if hack_hide_meld_indicator_next_frame:
		# Prevent meld flash right after discard
		hack_hide_meld_indicator_next_frame = false
		Global.dbg("Player('%s'): hack_hide_meld_indicator_next_frame is true, SKIPPING meld indicator SHOW" % [player_id])
		return
	var round_num = Global.game_state.current_round_num
	if round_num < 7 or (round_num >= 7 and last_hand_evaluation['is_winning_hand']): # suppress round 7 meld flash
		Global.dbg("Player('%s'): already_melded=false, setting is_meldable=true, can_be_personally_melded=%s SHOW MELD INDICATOR" % [player_id, str(last_hand_evaluation['can_be_personally_melded'])])
		$TurnIndicatorRect.color = TURN_INDICATOR_MELD_COLOR # Set color to meld color
		is_meldable = true
		$MeldIndicatorSprite2D.show() # Show meld indicator

	# elif already_melded and len(last_hand_evaluation['can_be_publicly_melded']) > 0:
	# 	$TurnIndicatorRect.color = TURN_INDICATOR_MELD_COLOR # Set color to meld color
	# 	Global.dbg("Player('%s'): found %d possibilities to meld publicly" % [player_id, len(last_hand_evaluation['can_be_publicly_melded'])])
	# 	local_public_meld_possibilities.clear()
	# 	for possibility in last_hand_evaluation['can_be_publicly_melded']:
	# 		Global.dbg("Player('%s'): calling _local_player_is_meldable_signal.emit(%s)" % [player_id, str(possibility)])
	# 		_local_player_is_meldable_signal.emit(possibility)

func _on_local_player_is_meldable_signal(possibility: Dictionary) -> void:
	if possibility.target_player_id != player_id:
		return
	Global.dbg("Player('%s'): _on_local_player_is_meldable_signal: possibility=%s SHOW MELD INDICATOR" % [player_id, str(possibility)])
	is_meldable = true
	local_public_meld_possibilities.append(possibility)
	$MeldIndicatorSprite2D.show() # Show meld indicator

func _update_turn_indicator_color(current_state_name: String, already_melded: bool) -> void:
	if current_state_name == 'PlayerDrewState':
		Global.dbg("Player('%s'): current_state_name='%s': Setting player '%s' turn indicator to DISCARD color: %s" % [player_id, current_state_name, player_name, str(TURN_INDICATOR_DISCARD_COLOR)])
		$TurnIndicatorRect.color = TURN_INDICATOR_DISCARD_COLOR # Set color to discard color
	elif already_melded:
		Global.dbg("Player('%s'): current_state_name='%s': Setting player '%s' turn indicator to MELD color: %s" % [player_id, current_state_name, player_name, str(TURN_INDICATOR_MELD_COLOR)])
		$TurnIndicatorRect.color = TURN_INDICATOR_MELD_COLOR # Set color to meld color
	else:
		Global.dbg("Player('%s'): current_state_name='%s': Setting player '%s' turn indicator to DRAW color: %s" % [player_id, current_state_name, player_name, str(TURN_INDICATOR_DRAW_COLOR)])
		$TurnIndicatorRect.color = TURN_INDICATOR_DRAW_COLOR # Set color to draw color

func is_mouse_over_player(mouse_pos: Vector2) -> bool:
	var sprite = $CardBackSprite2D
	if not sprite:
		Global.error("Player('%s'): PROGRAMMING ERROR: player.gd: is_mouse_over_player(%s): No Sprite2D found!" % [player_id, str(mouse_pos)])
		return false
	if not sprite.texture:
		Global.error("Player('%s'): PROGRAMMING ERROR: player.gd: is_mouse_over_player(%s): Sprite2D has no texture!" % [player_id, str(mouse_pos)])
		return false
	var texture_size = sprite.texture.get_size() * self.scale # NOT: sprite.scale!
	var sprite_pos = global_position + sprite.position
	var player_rect = Rect2(
		sprite_pos - texture_size / 2, # Top-left corner
		texture_size # Size
	)
	var is_over = player_rect.has_point(mouse_pos)
	# Global.dbg("Player('%s'): is_mouse_over_player(%s): player rect: %s, is_over=%s" % [player_id, str(mouse_pos), str(player_rect), str(is_over)])
	return is_over

################################################################################
## Signals
################################################################################

func _get_next_z_index_for_player_cards() -> int:
	# Find the maximum z_index among all cards that belong to this player (hand + meld areas)
	var max_z_index = 1
	for card_key in Global.private_player_info['card_keys_in_hand']:
		var playing_card = Global.playing_cards.get(card_key) as PlayingCard
		if playing_card and playing_card.z_index > max_z_index:
			max_z_index = playing_card.z_index
	return max_z_index + 1

func _playing_card_is_from_discard_pile(playing_card: PlayingCard) -> bool:
	return len(Global.discard_pile) > 0 and playing_card.key == Global.discard_pile[0].key

func _playing_card_is_from_stock_pile(playing_card: PlayingCard) -> bool:
	return len(Global.stock_pile) > 0 and playing_card.key == Global.stock_pile[0].key

func _on_card_clicked_signal(playing_card, _global_position):
	var player_is_me = Global.private_player_info.id == player_id
	if not player_is_me: return # bots do not click or drag cards.
	Global.dbg("Player('%s'): _on_card_clicked_signal: playing_card=%s, is_my_turn=%s" % [player_id, playing_card.key, str(is_my_turn)])
	if _playing_card_is_from_discard_pile(playing_card):
		if not is_my_turn:
			Global.request_to_buy_card_from_discard_pile(player_id)
			return
		# Global.dbg("Player('%s'): _on_card_clicked_signal: Drawing card '%s' from discard pile for player %s" % [player_id, playing_card.key, player_id])
		Global.draw_card_from_discard_pile(Global.private_player_info.id)
		return
	if is_my_turn and _playing_card_is_from_stock_pile(playing_card):
		# If there are outstanding buy requests, go ahead and allow the buy since the user clicked on the stock pile.
		if Global.has_outstanding_buy_request():
			# Global.dbg("Player('%s'): _on_card_clicked_signal: Allowing outstanding buy request" % [player_id])
			Global.allow_outstanding_buy_request(player_id)
			return
		# Global.dbg("Player('%s'): _on_card_clicked_signal: Drawing card '%s' from stock pile for player %s" % [player_id, playing_card.key, player_id])
		Global.draw_card_from_stock_pile(Global.private_player_info.id)
		return
	# To prevent accidental discards, disallow discarding any cards from any of the meld areas directly.
	# The player must first move the card back to their hand before discarding it.
	var meld_area_idx = _get_playing_card_meld_area_idx(playing_card)
	if meld_area_idx >= 0:
		# Instead of ignoring, raise the card to the top z-index so it shows above other cards
		Global.dbg("Player('%s'): _on_card_clicked_signal: Raising meld area card '%s' to top z-index" % [player_id, playing_card.key])
		playing_card.z_index = _get_next_z_index_for_player_cards()
		return
	if is_my_turn and game_state_machine.get_current_state_name() == 'PlayerDrewState':
		# If the player can meld their hand, interpret this click as an accident and ignore it.
		if is_meldable:
			Global.dbg("Player('%s'): _on_card_clicked_signal: Ignoring click on meldable hand card '%s' for player %s" % [player_id, playing_card.key, player_id])
			return
		var player_won = len(Global.private_player_info['card_keys_in_hand']) == 1
		Global.dbg("Player('%s'): _on_card_clicked_signal: hiding meld indicator" % [player_id])
		$MeldIndicatorSprite2D.hide() # hack to stop meld indicator showing after discard
		hack_hide_meld_indicator_next_frame = true
		Global.discard_card(player_id, playing_card.key, player_won)
		return

func _on_card_drag_started_signal(_playing_card, _from_position):
	hack_hide_meld_indicator_next_frame = false
	var player_is_me = Global.private_player_info.id == player_id
	if not player_is_me: return # bots do not click or drag cards.
	if not is_my_turn: return

func _on_card_moved_signal(playing_card, _from_position, _global_position):
	hack_hide_meld_indicator_next_frame = false
	Global.dbg("Player('%s'): _on_card_moved_signal: playing_card=%s, is_my_turn=%s, Global.is_my_turn=%s, has_melded=%s" % [
		player_id, playing_card.key, str(is_my_turn), str(Global.is_my_turn()), str(Global.player_has_melded(Global.private_player_info['id']))])
	# if Global.is_my_turn() and Global.player_has_melded(Global.private_player_info['id']):
	# 	_update_hand_meldability()
	# 	return

	var player_is_me = Global.private_player_info.id == player_id
	if not player_is_me: return # bots do not click or drag cards.

	var meld_area_idx = _get_playing_card_meld_area_idx(playing_card)
	if meld_area_idx >= 0:
		Global.dbg("Player('%s'): _on_card_moved_signal: Moving card '%s' to meld area %d for player %s" % [player_id, playing_card.key, meld_area_idx + 1, player_id])
		Global.private_player_info.meld_area_1_keys.erase(playing_card.key)
		Global.private_player_info.meld_area_2_keys.erase(playing_card.key)
		Global.private_player_info.meld_area_3_keys.erase(playing_card.key)
		match meld_area_idx:
			0:
				Global.private_player_info.meld_area_1_keys.append(playing_card.key)
			1:
				Global.private_player_info.meld_area_2_keys.append(playing_card.key)
			2:
				Global.private_player_info.meld_area_3_keys.append(playing_card.key)
		_update_meld_area_counts_and_sparkles()
		_update_hand_meldability()
		return

	# Card is not in a meld area now - check if it was previously in one and remove it
	var was_in_meld_area = (
		Global.private_player_info.meld_area_1_keys.has(playing_card.key) or
		Global.private_player_info.meld_area_2_keys.has(playing_card.key) or
		Global.private_player_info.meld_area_3_keys.has(playing_card.key)
	)
	if was_in_meld_area:
		Global.dbg("Player('%s'): _on_card_moved_signal: Moving card '%s' out of meld area for player %s" % [player_id, playing_card.key, player_id])
		Global.private_player_info.meld_area_1_keys.erase(playing_card.key)
		Global.private_player_info.meld_area_2_keys.erase(playing_card.key)
		Global.private_player_info.meld_area_3_keys.erase(playing_card.key)
		_update_meld_area_counts_and_sparkles()
		_update_hand_meldability()
		return

	# Global.dbg("Player('%s'): _on_card_moved_signal: playing_card=%s, is_my_turn=%s" % [player_id, playing_card.key, str(is_my_turn)])
	if not is_my_turn:
		# Should not be able to drag card.
		return
	if _playing_card_is_from_discard_pile(playing_card):
		# Moved to game_state_machine:
		# if len(Global.stock_pile) > 0:
		# 	Global.stock_pile[0].is_draggable = false
		# 	Global.stock_pile[0].is_tappable = false
		# Global.dbg("Player('%s'): _on_card_moved_signal: Drawing card '%s' from discard pile for player %s" % [player_id, playing_card.key, player_id])
		Global.draw_card_from_discard_pile(Global.private_player_info.id)
		return
	if _playing_card_is_from_stock_pile(playing_card):
		# Moved to game_state_machine:
		# if len(Global.stock_pile) > 0:
		# 	Global.discard_pile[0].is_draggable = false
		# 	Global.discard_pile[0].is_tappable = false
		# Global.dbg("Player('%s'): _on_card_moved_signal: Drawing card '%s' from stock pile for player %s" % [player_id, playing_card.key, player_id])
		Global.draw_card_from_stock_pile(Global.private_player_info.id)
		return
	var distance_to_discard_pile = int(_global_position.distance_to(Global.discard_pile_position))
	# Global.dbg("Player('%s'): _on_card_moved_signal: distance_to_discard_pile=%d" % [player_id, distance_to_discard_pile])
	if distance_to_discard_pile < 200 and game_state_machine.get_current_state_name() == 'PlayerDrewState':
		var player_won = len(Global.private_player_info['card_keys_in_hand']) == 1
		Global.discard_card(player_id, playing_card.key, player_won)
		return

################################################################################
## Input handling and animations
################################################################################

# Handle clicks on this player node.
func _input(event):
	# Only handle click events on the player node.
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT): return
	var current_state_name = game_state_machine.get_current_state_name()
	var mouse_pos = get_global_mouse_position()

	Global.dbg("Player('%s')._input: BUTTON PRESSED at mouse_pos=%s, state=%s" % [player_id, str(mouse_pos), current_state_name])

	if Global.is_server() and (current_state_name == 'PlayerWonRoundState' or current_state_name == 'TallyScoresState' or current_state_name == 'FinalScoresState'):
		if not is_mouse_over_player(mouse_pos):
			Global.dbg("Player('%s')._input: Mouse NOT over player, ignoring" % player_id)
			return # false alarm.
		Global.dbg("Player('%s')._input: Mouse IS over player in end-game state, processing..." % player_id)
		if is_winning_player and current_state_name == 'PlayerWonRoundState':
			# Allow host to click on winner to advance to TallyScoresState
			Global.dbg("Player('%s')._input: Clicked on winning player node, advancing to TallyScoresState - calling set_input_as_handled()" % player_id)
			Global.send_transition_all_clients_state_to_signal('TallyScoresState')
			# Don't allow any other nodes to also handle this event.
			get_viewport().set_input_as_handled()
		if current_state_name == 'TallyScoresState':
			Global.dbg("Player('%s')._input: TallyScoresState, advancing to next round - calling set_input_as_handled()" % player_id)
			# Allow host to click on any player to advance to next round (or reset game if round 7 is complete).
			if Global.game_state.current_round_num >= 7:
				Global.dbg("Player('%s')._input: Round 7 complete, showing final scores" % player_id)
				var next_round_scene = load("res://rounds/final_scores.tscn") as PackedScene
				Global.request_change_round(next_round_scene)
				Global.send_transition_all_clients_state_to_signal('FinalScoresState')
			else:
				Global.server_advance_to_next_round()
			# Don't allow any other nodes to also handle this event.
			if not get_viewport():
				return # Happens in round 7 after a win.
			get_viewport().set_input_as_handled()
		if current_state_name == 'FinalScoresState':
			Global.dbg("Player('%s')._input: FinalScoresState, resetting game - calling set_input_as_handled()" % player_id)
			Global.reset_game_signal.emit()
			if not get_viewport():
				return # Happens in round 7 after a win.
			get_viewport().set_input_as_handled()
		return
	# Only current player can click on _ANY_ player node and only during playing state.
	if not Global.is_my_turn() or not game_state_machine.is_playing_state():
		Global.dbg("Player('%s')._input: Not my turn or not playing state, ignoring" % player_id)
		return
	if not is_meldable and not is_buying_card:
		Global.dbg("Player('%s')._input: Not meldable and not buying, ignoring" % player_id)
		return
	# Finally, after all the trivial rejects, now calculate if the mouse is actually over this player node.
	if not is_mouse_over_player(mouse_pos):
		Global.dbg("Player('%s')._input: Mouse NOT over player (rect check), ignoring" % player_id)
		return # false alarm.
	Global.dbg("Player('%s')._input: Mouse IS over player! is_meldable=%s, is_buying_card=%s" % [player_id, is_meldable, is_buying_card])
	if is_meldable and is_my_turn and len(Global.private_player_info['played_to_table']) == 0:
		Global.dbg("Player('%s')._input: PERSONALLY MELDING - calling set_input_as_handled()" % player_id)
		Global.personally_meld_hand(player_id, last_hand_evaluation)
		# Clear the meldable area sparklers
		Global.emit_meld_area_state_changed_signal(false, 0)
		Global.emit_meld_area_state_changed_signal(false, 1)
		Global.emit_meld_area_state_changed_signal(false, 2)
		# Don't allow any other nodes to also handle this event.
		get_viewport().set_input_as_handled()
		return
	if is_meldable: # current player wishes to meld publicly on this player.
		Global.dbg("Player('%s')._input: PUBLICLY MELDING on this player - calling set_input_as_handled()" % player_id)
		# Don't allow any other nodes to also handle this event.
		get_viewport().set_input_as_handled()
		for possibility in local_public_meld_possibilities:
			var is_meldable_player_id = possibility.target_player_id
			var is_meldable_card_key = possibility.card_key
			var is_meldable_meld_group_index = possibility.meld_group_index
			Global.meld_card_to_public_meld(is_meldable_player_id, is_meldable_card_key, player_id, is_meldable_meld_group_index)
			# wait 0.1 seconds between melds to allow for animation
			await get_tree().create_timer(0.1).timeout
		local_public_meld_possibilities.clear()
		return
	if not is_my_turn and is_buying_card:
		Global.dbg("Player('%s')._input: BUYING CARD - calling set_input_as_handled()" % player_id)
		var current_player_id = Global.private_player_info.id
		Global.allow_outstanding_buy_request(current_player_id)
		# Don't allow any other nodes to also handle this event.
		get_viewport().set_input_as_handled()
		return

const ANIMATE_SPEED = 0.005

func _process(_delta: float) -> void:
	if is_winning_player:
		var ticks = Time.get_ticks_msec()
		var rect_scale = abs(sin(ticks * ANIMATE_SPEED)) * 0.5 + 1.0
		$TurnIndicatorRect.scale = Vector2(rect_scale, rect_scale)
		$TurnIndicatorRect.rotation = ticks * 0.01 # Rotate the winning player indicator
	if not game_state_machine.is_playing_state(): return
	if is_my_turn:
		var rect_scale = abs(sin(Time.get_ticks_msec() * ANIMATE_SPEED)) * 0.2 + 1.0
		$TurnIndicatorRect.scale = Vector2(rect_scale, rect_scale)
	elif is_buying_card:
		var rect_scale = abs(sin(Time.get_ticks_msec() * ANIMATE_SPEED)) * 0.2 + 0.8
		$BuyIndicatorSprite2D.scale = Vector2(rect_scale, rect_scale)
	if is_meldable:
		var rect_scale = abs(sin(Time.get_ticks_msec() * ANIMATE_SPEED)) * 0.2 + 0.8
		$MeldIndicatorSprite2D.scale = Vector2(rect_scale, rect_scale)

################################################################################
## Utility functions
################################################################################

# _get_playing_card_meld_area_idx returns the meld area index (0, 1, or 2) if the playing_card
# is physically within one of the player's meld areas, or -1 if the playing_card is not in any meld area.
func _get_playing_card_meld_area_idx(playing_card: PlayingCard) -> int:
	# Trivial reject:
	if playing_card.position.y <= Global.screen_size.y * Global.MELD_AREA_TOP_PERCENT:
		return -1
	var round_num = Global.game_state.current_round_num
	if round_num <= 3:
		if playing_card.position.x >= Global.screen_size.x * Global.MELD_AREA_2_RIGHT_PERCENT:
			return -1
		if playing_card.position.x >= Global.screen_size.x * Global.MELD_AREA_1_RIGHT_PERCENT:
			return 1
		return 0
	if playing_card.position.x >= Global.screen_size.x * Global.MELD_AREA_RIGHT_PERCENT:
		return -1
	if playing_card.position.x >= Global.screen_size.x * Global.MELD_AREA_2_RIGHT_PERCENT:
		return 2
	if playing_card.position.x >= Global.screen_size.x * Global.MELD_AREA_1_RIGHT_PERCENT:
		return 1
	return 0

func _update_meld_area_counts_and_sparkles() -> void:
	var meld_area_counts = [
		len(Global.private_player_info.meld_area_1_keys),
		len(Global.private_player_info.meld_area_2_keys),
		len(Global.private_player_info.meld_area_3_keys),
	]
	# Meld area counts are in a fixed location in all the scene trees.
	var meld_area = $"/root/RootNode/RoundNode".get_child(0).get_child(2)
	# Global.dbg("Player('%s'): _update_meld_area_counts_and_sparkles: meld_area: %s" % [player_id, str(meld_area)])
	var round_children = meld_area.get_children()
	for idx in range(len(round_children)):
		var child = round_children[idx]
		var meld_area_label: Label = child.get_child(0)
		# Global.dbg("Player('%s'): _update_meld_area_counts_and_sparkles: found label: %s" % [player_id, meld_area_label.text])
		_update_meld_area_label(meld_area_label, meld_area_counts[idx])
	Global.emit_meld_areas_states()

func _update_meld_area_label(meld_area_label: Label, count: int) -> void:
	if meld_area_label.text.begins_with('Book '):
		meld_area_label.text = meld_area_label.text.substr(0, 6) + ' (%d)' % count
		return
	# It must be a run
	meld_area_label.text = meld_area_label.text.substr(0, 5) + ' (%d)' % count

################################################################################
## Player hand evaluation functions
################################################################################

func gen_player_hand_stats(stats_private_player_info: Dictionary) -> Dictionary:
	var card_keys_in_hand = stats_private_player_info['card_keys_in_hand']
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
	return hand_stats

func evaluate_player_hand(hand_stats: Dictionary) -> Dictionary:
	var pre_meld = not Global.player_has_melded(player_id)
	var evaluation = {}
	if pre_meld:
		evaluation = _evaluate_player_hand_pre_meld(hand_stats)
		Global.dbg("Player('%s'): LEAVE _evaluate_player_hand_pre_meld: round_num=%d, evaluation=%s" % [player_id, Global.game_state.current_round_num, str(evaluation)])
	# else:
	# 	evaluation = _evaluate_player_hand_post_meld(hand_stats)
	# 	Global.dbg("Player('%s'): LEAVE _evaluate_player_hand_post_meld: round_num=%d, evaluation=%s" % [player_id, Global.game_state.current_round_num, str(evaluation)])
	return evaluation

func _basic_evaluation() -> Dictionary:
	var acc = Global.empty_evaluation()
	acc['meld_area_1_keys'] = Global.private_player_info['meld_area_1_keys']
	acc['meld_area_2_keys'] = Global.private_player_info['meld_area_2_keys']
	acc['meld_area_3_keys'] = Global.private_player_info['meld_area_3_keys']
	var already_seen = {}
	for card_key in acc.meld_area_1_keys:
		already_seen[card_key] = true
	for card_key in acc.meld_area_2_keys:
		already_seen[card_key] = true
	for card_key in acc.meld_area_3_keys:
		already_seen[card_key] = true
	for card_key in Global.private_player_info['card_keys_in_hand']:
		if not already_seen.has(card_key):
			acc.recommended_discards.append(card_key)
	return acc

func gen_group(card_keys: Array) -> Dictionary:
	var rank = Global.get_group_rank(card_keys)
	var group = {
		'type': 'group',
		'rank': rank,
		'card_keys': card_keys.duplicate(),
	}
	return group

func gen_run(card_keys: Array) -> Dictionary:
	var suit = Global.get_run_suit(card_keys)
	var run = {
		'type': 'run',
		'suit': suit,
		'card_keys': card_keys.duplicate(),
	}
	return run

func _evaluate_player_hand_pre_meld(hand_stats: Dictionary) -> Dictionary:
	var round_num = Global.game_state.current_round_num
	Global.dbg("Player('%s'): ENTER _evaluate_player_hand_pre_meld: round_num=%d, hand_stats=%s" % [player_id, round_num, str(hand_stats)])

	var acc = _basic_evaluation()
	var meld_area_1_is_complete = false
	var meld_area_2_is_complete = false
	var meld_area_3_is_complete = false
	var can_be_personally_melded = []
	var have_sufficient_discards = false
	var is_winning_hand = false

	match round_num:
		1:
			meld_area_1_is_complete = Global.is_valid_group(acc.meld_area_1_keys)
			can_be_personally_melded.append(gen_group(acc.meld_area_1_keys))
			meld_area_2_is_complete = Global.is_valid_group(acc.meld_area_2_keys)
			can_be_personally_melded.append(gen_group(acc.meld_area_2_keys))
			meld_area_3_is_complete = true
			have_sufficient_discards = len(acc.recommended_discards) >= 1
			is_winning_hand = len(acc.recommended_discards) == 1
		2:
			meld_area_1_is_complete = Global.is_valid_group(acc.meld_area_1_keys)
			can_be_personally_melded.append(gen_group(acc.meld_area_1_keys))
			meld_area_2_is_complete = Global.is_valid_run(acc.meld_area_2_keys)
			can_be_personally_melded.append(gen_run(acc.meld_area_2_keys))
			meld_area_3_is_complete = true
			have_sufficient_discards = len(acc.recommended_discards) >= 1
			is_winning_hand = len(acc.recommended_discards) == 1
		3:
			meld_area_1_is_complete = Global.is_valid_run(acc.meld_area_1_keys)
			can_be_personally_melded.append(gen_run(acc.meld_area_1_keys))
			meld_area_2_is_complete = Global.is_valid_run(acc.meld_area_2_keys)
			can_be_personally_melded.append(gen_run(acc.meld_area_2_keys))
			meld_area_3_is_complete = true
			have_sufficient_discards = len(acc.recommended_discards) >= 1
			is_winning_hand = len(acc.recommended_discards) == 1
		4:
			meld_area_1_is_complete = Global.is_valid_group(acc.meld_area_1_keys)
			can_be_personally_melded.append(gen_group(acc.meld_area_1_keys))
			meld_area_2_is_complete = Global.is_valid_group(acc.meld_area_2_keys)
			can_be_personally_melded.append(gen_group(acc.meld_area_2_keys))
			meld_area_3_is_complete = Global.is_valid_group(acc.meld_area_3_keys)
			can_be_personally_melded.append(gen_group(acc.meld_area_3_keys))
			have_sufficient_discards = len(acc.recommended_discards) >= 1
			is_winning_hand = len(acc.recommended_discards) == 1
		5:
			meld_area_1_is_complete = Global.is_valid_group(acc.meld_area_1_keys)
			can_be_personally_melded.append(gen_group(acc.meld_area_1_keys))
			meld_area_2_is_complete = Global.is_valid_group(acc.meld_area_2_keys)
			can_be_personally_melded.append(gen_group(acc.meld_area_2_keys))
			meld_area_3_is_complete = Global.is_valid_run(acc.meld_area_3_keys)
			can_be_personally_melded.append(gen_run(acc.meld_area_3_keys))
			have_sufficient_discards = len(acc.recommended_discards) >= 1
			is_winning_hand = len(acc.recommended_discards) == 1
		6:
			meld_area_1_is_complete = Global.is_valid_group(acc.meld_area_1_keys)
			can_be_personally_melded.append(gen_group(acc.meld_area_1_keys))
			meld_area_2_is_complete = Global.is_valid_run(acc.meld_area_2_keys)
			can_be_personally_melded.append(gen_run(acc.meld_area_2_keys))
			meld_area_3_is_complete = Global.is_valid_run(acc.meld_area_3_keys)
			can_be_personally_melded.append(gen_run(acc.meld_area_3_keys))
			have_sufficient_discards = len(acc.recommended_discards) >= 1
			is_winning_hand = len(acc.recommended_discards) == 1
		7:
			meld_area_1_is_complete = Global.is_valid_run(acc.meld_area_1_keys)
			can_be_personally_melded.append(gen_run(acc.meld_area_1_keys))
			meld_area_2_is_complete = Global.is_valid_run(acc.meld_area_2_keys)
			can_be_personally_melded.append(gen_run(acc.meld_area_2_keys))
			meld_area_3_is_complete = Global.is_valid_run(acc.meld_area_3_keys)
			can_be_personally_melded.append(gen_run(acc.meld_area_3_keys))
			have_sufficient_discards = len(acc.recommended_discards) == 0
			is_winning_hand = len(acc.recommended_discards) == 0

	if meld_area_1_is_complete and meld_area_2_is_complete and meld_area_3_is_complete && have_sufficient_discards:
		acc['can_be_personally_melded'] = can_be_personally_melded
		acc['is_winning_hand'] = is_winning_hand
	return acc

func _evaluate_player_hand_post_meld(hand_stats: Dictionary) -> Dictionary:
	var round_num = Global.game_state.current_round_num
	Global.dbg("Player('%s'): ENTER _evaluate_player_hand_post_meld: round_num=%d, hand_stats=%s" % [player_id, round_num, str(hand_stats)])

	var acc = _basic_evaluation()
	if round_num < 7 and len(acc.recommended_discards) == 0: return acc
	if round_num >= 7 and len(acc.recommended_discards) != 0: return acc
	match round_num:
		1:
			var all_public_group_ranks = Global.gen_all_public_group_ranks()
			add_public_group_meld_possibilities(acc, acc.meld_area_1_keys, all_public_group_ranks)
			add_public_group_meld_possibilities(acc, acc.meld_area_2_keys, all_public_group_ranks)
		2:
			var all_public_group_ranks = Global.gen_all_public_group_ranks()
			add_public_group_meld_possibilities(acc, acc.meld_area_1_keys, all_public_group_ranks)
			var all_public_run_suits = Global.gen_all_public_run_suits()
			add_public_run_meld_possibilities(acc, acc.meld_area_2_keys, all_public_run_suits)
		3:
			var all_public_run_suits = Global.gen_all_public_run_suits()
			add_public_run_meld_possibilities(acc, acc.meld_area_1_keys, all_public_run_suits)
			add_public_run_meld_possibilities(acc, acc.meld_area_2_keys, all_public_run_suits)
		4:
			var all_public_group_ranks = Global.gen_all_public_group_ranks()
			add_public_group_meld_possibilities(acc, acc.meld_area_1_keys, all_public_group_ranks)
			add_public_group_meld_possibilities(acc, acc.meld_area_2_keys, all_public_group_ranks)
			add_public_group_meld_possibilities(acc, acc.meld_area_3_keys, all_public_group_ranks)
		5:
			var all_public_group_ranks = Global.gen_all_public_group_ranks()
			add_public_group_meld_possibilities(acc, acc.meld_area_1_keys, all_public_group_ranks)
			add_public_group_meld_possibilities(acc, acc.meld_area_2_keys, all_public_group_ranks)
			var all_public_run_suits = Global.gen_all_public_run_suits()
			add_public_run_meld_possibilities(acc, acc.meld_area_3_keys, all_public_run_suits)
		6:
			var all_public_group_ranks = Global.gen_all_public_group_ranks()
			add_public_group_meld_possibilities(acc, acc.meld_area_1_keys, all_public_group_ranks)
			var all_public_run_suits = Global.gen_all_public_run_suits()
			add_public_run_meld_possibilities(acc, acc.meld_area_2_keys, all_public_run_suits)
			add_public_run_meld_possibilities(acc, acc.meld_area_3_keys, all_public_run_suits)
		7:
			var all_public_run_suits = Global.gen_all_public_run_suits()
			add_public_run_meld_possibilities(acc, acc.meld_area_1_keys, all_public_run_suits)
			add_public_run_meld_possibilities(acc, acc.meld_area_2_keys, all_public_run_suits)
			add_public_run_meld_possibilities(acc, acc.meld_area_3_keys, all_public_run_suits)

	return acc

func add_public_group_meld_possibilities(acc: Dictionary, meld_area_keys: Array, all_public_group_ranks: Dictionary) -> void:
	if len(meld_area_keys) == 0:
		Global.dbg("Player('%s'): add_public_group_meld_possibilities: NO meld_area_keys, returning" % player_id)
		return
	for card_key in meld_area_keys:
		var parts = card_key.split('_')
		var rank = parts[0]
		Global.dbg("Player('%s'): add_public_group_meld_possibilities: looking at card_key=%s, rank=%s" % [player_id, card_key, rank])
		if rank == 'JOKER':
			add_joker_to_every_public_group_possibility(acc, card_key, all_public_group_ranks)
			continue
		if not all_public_group_ranks.has(rank):
			Global.dbg("Player('%s'): add_public_group_meld_possibilities: card_key=%s, No public groups for rank='%s'" % [player_id, card_key, rank])
			continue
		for possibility in all_public_group_ranks[rank]:
			possibility.card_key = card_key
			acc.can_be_publicly_melded.append(possibility)
			Global.dbg("Player('%s'): add_public_group_meld_possibilities: card_key=%s, possibility=%s" % [player_id, card_key, str(possibility)])

func add_joker_to_every_public_group_possibility(acc: Dictionary, card_key, all_public_group_ranks: Dictionary) -> void:
	for rank in all_public_group_ranks.keys():
		for possibility in all_public_group_ranks[rank]:
			possibility.card_key = card_key
			acc.can_be_publicly_melded.append(possibility)
			Global.dbg("Player('%s'): add_joker_to_every_public_group_possibility: rank=%s, possibility=%s" % [player_id, rank, str(possibility)])

func add_public_run_meld_possibilities(acc: Dictionary, meld_area_keys: Array, all_public_run_suits: Dictionary) -> void:
	if len(meld_area_keys) == 0: return
	for card_key in meld_area_keys:
		var parts = card_key.split('-')
		var rank = parts[0]
		if rank == 'JOKER':
			add_joker_to_every_public_run_possibility(acc, card_key, all_public_run_suits)
			continue
		var suit = parts[1]
		if not all_public_run_suits.has(suit): continue
		for possibility in all_public_run_suits[suit]:
			var new_run_card_keys = possibility.card_keys.duplicate()
			new_run_card_keys.append(card_key)
			if not Global.is_valid_run(new_run_card_keys): continue
			# Now determine if the newly-added card replaced a JOKER in the run
			new_run_card_keys = Global.sort_run_cards(new_run_card_keys)
			var card_key_idx = new_run_card_keys.find(card_key)
			if card_key_idx == -1:
				Global.error("Player('%s'): PROGRAMMING ERROR: add_public_run_meld_possibilities: Could not find newly added card_key '%s' in new_run_card_keys=%s" % [player_id, card_key, str(new_run_card_keys)])
				continue
			if card_key_idx > len(possibility.card_keys):
				# Added card is beyond the original run cards, so it did not replace a JOKER
				acc.can_be_publicly_melded.append(possibility)
				Global.dbg("Player('%s'): add_public_run_meld_possibilities: possibility=%s" % [player_id, str(possibility)])
				continue
			var original_card_key = possibility.card_keys[card_key_idx]
			parts = original_card_key.split('-')
			var original_rank = parts[0]
			if original_rank == 'JOKER':
				# Valid run with the new card replacing a JOKER
				possibility['return_joker_to_players_hand'] = original_card_key
			acc.can_be_publicly_melded.append(possibility)
			Global.dbg("Player('%s'): add_public_run_meld_possibilities: possibility=%s" % [player_id, str(possibility)])

func add_joker_to_every_public_run_possibility(acc: Dictionary, card_key: String, all_public_run_suits: Dictionary) -> void:
	for suit in all_public_run_suits.keys():
		for possibility in all_public_run_suits[suit]:
			possibility.card_key = card_key
			acc.can_be_publicly_melded.append(possibility)
			Global.dbg("Player('%s'): add_joker_to_every_public_run_possibility: possibility=%s" % [player_id, str(possibility)])

func _on_all_meld_area_states_updated_signal(post_meld_data: Dictionary) -> void:
	# If it is the current player's turn and they are in PlayerDrewState and they have already melded,
	# update the "Meld!" indicators on _ALL_ players.
	# Note that this signal is handled _ONLY_ by the Player node representing the current player
	# which calculates all meld possibilities, then fires a second "local" signal to all Player nodes
	# to update their "Meld!" indicators accordingly.
	var player_is_me = Global.private_player_info.id == player_id
	if not player_is_me: return
	if not Global.is_my_turn(): return
	var current_state_name = game_state_machine.get_current_state_name()
	if current_state_name != 'PlayerDrewState': return
	if not Global.player_has_melded(Global.private_player_info['id']): return
	Global.dbg("Player('%s'): _on_all_meld_area_states_updated_signal: updating _ALL_ Meld! indicators by alerting all Player nodes... post_meld_data=%s" % [player_id, str(post_meld_data)])