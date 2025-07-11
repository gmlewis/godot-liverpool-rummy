extends Node2D
# class_name Player

@onready var game_state_machine: Node = $"/root/RootNode/GameStateMachine"

signal _local_player_is_meldable_signal(target_player_id: String, player_is_meldable: bool, melding_player_id: String, melding_card_key: String, melding_group_index: int) # Used locally to communicate with other player nodes.

var player_id: String
var player_name: String
var turn_index: int

# is_my_turn is used to animate the turn indicator (for live players only).
var is_my_turn: bool = false
var is_buying_card: bool = false # Used to animate the turn indicator when buying a card.
var is_meldable: bool = false # Used to animate the turn indicator when meldable (by current player or any other player).
var is_winning_player: bool = false # Used to indicate if this player is the winning player in the current round.

# When another player wishes to meld on this player, these variables are set for the upcoming click:
var is_meldable_player_id: String = ''
var is_meldable_card_key: String = ''
var is_meldable_meld_group_index: int = -1

const TURN_INDICATOR_DRAW_COLOR = Color(1.0, 0.45, 0.17, 1.0) # Orange color
const TURN_INDICATOR_DISCARD_COLOR = Color(0.8, 0.2, 0.8, 1.0) # Purple color
const TURN_INDICATOR_MELD_COLOR = Color(0.38, 0.73, 0.4, 1.0) # Greenish color

var last_hand_evaluation = null # Used to store the last hand evaluation for the player, used when melding.

func _ready():
	# Global.dbg('Player Node2D ready: player_id=%s, player_name=%s, num_cards=%d, score=%d, turn_index=%d' % [player_id, player_name, num_cards, score, turn_index])
	_on_custom_card_back_texture_changed_signal()
	Global.connect('custom_card_back_texture_changed_signal', _on_custom_card_back_texture_changed_signal)
	Global.connect('game_state_updated_signal', _on_game_state_updated_signal)
	Global.connect('card_clicked_signal', _on_card_clicked_signal)
	Global.connect('card_drag_started_signal', _on_card_drag_started_signal)
	Global.connect('card_moved_signal', _on_card_moved_signal)
	connect('_local_player_is_meldable_signal', _on_local_player_is_meldable_signal)
	game_state_machine.connect('gsm_changed_state_signal', _on_gsm_changed_state_signal)
	$PlayerNameLabel.text = player_name
	$TurnIndicatorRect.scale = Vector2(0.1, 0.1) # Hide turn indicator at start
	$TurnIndicatorRect.color = TURN_INDICATOR_DRAW_COLOR # Set initial color to draw color
	$BuyIndicatorSprite2D.hide()
	$MeldIndicatorSprite2D.hide()
	_set_num_cards(0)

func _exit_tree():
	Global.disconnect('custom_card_back_texture_changed_signal', _on_custom_card_back_texture_changed_signal)
	Global.disconnect('game_state_updated_signal', _on_game_state_updated_signal)
	Global.disconnect('card_clicked_signal', _on_card_clicked_signal)
	Global.disconnect('card_drag_started_signal', _on_card_drag_started_signal)
	Global.disconnect('card_moved_signal', _on_card_moved_signal)
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
	is_winning_player = current_state_name == 'PlayerWonRoundState' and public_player_info['num_cards'] == 0
	if is_winning_player:
		$TurnIndicatorRect.color = Color(0.8, 0.8, 0.2, 1.0) # Set color to yellow for winning player
		$TurnIndicatorRect.scale = Vector2(1.2, 1.2) # Show turn indicator
		Global.make_discard_pile_tappable(false)
		Global.make_stock_pile_tappable(false)
		return
	else:
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
	var already_played_to_table = len(public_player_info['played_to_table']) > 0
	_update_turn_indicator_color(current_state_name, already_played_to_table)
	# This is all handled within 06-new_discard_state.gd
	# if current_state_name == 'NewDiscardState':
	# 	# Allow the player to immediately tap only on the discard pile.
	# 	Global.make_discard_pile_tappable(true)
	# 	Global.dbg("Player('%s'): _on_game_state_updated_signal: NewDiscardState: making stock pile untappable during grace period" % player_id)
	# 	Global.make_stock_pile_tappable(false)
	# 	# Allow the current player to tap on the stock pile after the grace period.
	# 	# Note that if there are buy requests, a tap on the stock pile will allow the next buy request.
	# 	Global.dbg("Player('%s'): _on_game_state_updated_signal: NewDiscardState: calling await_grace_period" % player_id)
	# 	await Global.await_grace_period()
	# 	Global.dbg("Player('%s'): _on_game_state_updated_signal: NewDiscardState: making stock pile tappable after grace period" % player_id)
	# 	Global.make_stock_pile_tappable(true)
	# 	return
	# current_state_name == 'PlayerDrewState':
	# Global.dbg("Player('%s'): _on_game_state_updated_signal: is_my_turn=%s, current_state_name='%s', changing stock pile and discard pile tappable settings" % [player_id, is_my_turn, current_state_name])
	# Global.make_discard_pile_tappable(false)
	# Global.make_stock_pile_tappable(false)
	# Now see if the player can meld (more of) their hand.
	var card_keys_in_hand = Global.private_player_info['card_keys_in_hand']
	var current_hand_stats = Global.gen_hand_stats(card_keys_in_hand)
	if current_state_name == 'PlayerDrewState':
		# Store the last hand evaluation for melding when user clicks on the player.
		last_hand_evaluation = Global.evaluate_hand(current_hand_stats, player_id)
		if not already_played_to_table and len(last_hand_evaluation['can_be_personally_melded']) > 0:
			Global.dbg("Player('%s'): already_played_to_table=false, setting is_meldable=true, can_be_personally_melded=%s" % [player_id, str(last_hand_evaluation['can_be_personally_melded'])])
			$TurnIndicatorRect.color = TURN_INDICATOR_MELD_COLOR # Set color to meld color
			is_meldable = true
			$MeldIndicatorSprite2D.show() # Show meld indicator
		elif already_played_to_table and len(last_hand_evaluation['can_be_publicly_melded']) > 0:
			$TurnIndicatorRect.color = TURN_INDICATOR_MELD_COLOR # Set color to meld color
			Global.dbg("Player('%s'): found %d possibilities to meld publicly" % [player_id, len(last_hand_evaluation['can_be_publicly_melded'])])
			for possibility in last_hand_evaluation['can_be_publicly_melded']:
				var target_player_id = possibility['target_player_id']
				var card_key = possibility['card_key']
				var meld_group_index = possibility['meld_group_index']
				Global.dbg("Player('%s'): calling _local_player_is_meldable_signal.emit('%s', true, '%s', '%s', %d)" % [player_id, target_player_id, player_id, card_key, meld_group_index])
				_local_player_is_meldable_signal.emit(target_player_id, true, player_id, card_key, meld_group_index)

func _on_local_player_is_meldable_signal(target_player_id: String, player_is_meldable: bool, melding_player_id: String, melding_card_key: String, melding_group_index: int) -> void:
	if target_player_id != player_id:
		Global.dbg("Player('%s'): IGNORING _on_local_player_is_meldable_signal.emit('%s', true, '%s', '%s', %d)" % [player_id, target_player_id, melding_player_id, melding_card_key, melding_group_index])
		return
	Global.dbg("Player('%s'): _on_local_player_is_meldable_signal: player_is_meldable=%s, melding_player_id=%s, melding_card_key=%s, melding_group_index=%d" % [player_id, str(player_is_meldable), melding_player_id, melding_card_key, melding_group_index])
	is_meldable = player_is_meldable
	if is_meldable:
		is_meldable_player_id = melding_player_id
		is_meldable_card_key = melding_card_key
		is_meldable_meld_group_index = melding_group_index
		$MeldIndicatorSprite2D.show() # Show meld indicator
	else:
		is_meldable_player_id = ''
		is_meldable_card_key = ''
		is_meldable_meld_group_index = -1
		$MeldIndicatorSprite2D.hide() # Hide meld indicator

func _update_turn_indicator_color(current_state_name: String, already_played_to_table: bool) -> void:
	if current_state_name == 'PlayerDrewState':
		Global.dbg("current_state_name='%s': Setting player '%s' turn indicator to DISCARD color: %s" % [current_state_name, player_name, str(TURN_INDICATOR_DISCARD_COLOR)])
		$TurnIndicatorRect.color = TURN_INDICATOR_DISCARD_COLOR # Set color to discard color
	elif already_played_to_table:
		Global.dbg("current_state_name='%s': Setting player '%s' turn indicator to MELD color: %s" % [current_state_name, player_name, str(TURN_INDICATOR_MELD_COLOR)])
		$TurnIndicatorRect.color = TURN_INDICATOR_MELD_COLOR # Set color to meld color
	else:
		Global.dbg("current_state_name='%s': Setting player '%s' turn indicator to DRAW color: %s" % [current_state_name, player_name, str(TURN_INDICATOR_DRAW_COLOR)])
		$TurnIndicatorRect.color = TURN_INDICATOR_DRAW_COLOR # Set color to draw color

func is_mouse_over_player(mouse_pos: Vector2) -> bool:
	var sprite = $CardBackSprite2D
	if not sprite:
		Global.dbg("PROGRAMMING ERROR: player.gd: is_mouse_over_player(%s): No Sprite2D found!" % str(mouse_pos))
		return false
	if not sprite.texture:
		Global.dbg("PROGRAMMING ERROR: player.gd: is_mouse_over_player(%s): Sprite2D has no texture!" % str(mouse_pos))
		return false
	var texture_size = sprite.texture.get_size() * self.scale # NOT: sprite.scale!
	var sprite_pos = global_position + sprite.position
	var player_rect = Rect2(
		sprite_pos - texture_size / 2, # Top-left corner
		texture_size # Size
	)
	var is_over = player_rect.has_point(mouse_pos)
	# Global.dbg("player.gd: is_mouse_over_player(%s): player rect: %s, is_over=%s" % [str(mouse_pos), str(player_rect), str(is_over)])
	return is_over

################################################################################
## Signals
################################################################################

func _playing_card_is_from_discard_pile(playing_card: PlayingCard) -> bool:
	return len(Global.discard_pile) > 0 and playing_card.key == Global.discard_pile[0].key

func _playing_card_is_from_stock_pile(playing_card: PlayingCard) -> bool:
	return len(Global.stock_pile) > 0 and playing_card.key == Global.stock_pile[0].key

func _on_card_clicked_signal(playing_card, _global_position):
	var player_is_me = Global.private_player_info.id == player_id
	if not player_is_me: return # bots do not click or drag cards.
	# Global.dbg("Player('%s'): _on_card_clicked_signal: playing_card=%s, is_my_turn=%s" % [player_id, playing_card.key, str(is_my_turn)])
	if not is_my_turn:
		if _playing_card_is_from_discard_pile(playing_card): # Express interest to Buy card.
			Global.request_to_buy_card_from_discard_pile(player_id)
		return
	if _playing_card_is_from_discard_pile(playing_card):
		# Moved to game_state_machine:
		# if len(Global.stock_pile) > 0:
		# 	Global.stock_pile[0].is_draggable = false
		# 	Global.stock_pile[0].is_tappable = false
		# Global.dbg("Player('%s'): _on_card_clicked_signal: Drawing card '%s' from discard pile for player %s" % [player_id, playing_card.key, player_id])
		Global.draw_card_from_discard_pile(Global.private_player_info.id)
		return
	if _playing_card_is_from_stock_pile(playing_card):
		# If there are outstanding buy requests, go ahead and allow the buy since the user clicked on the stock pile.
		if Global.has_outstanding_buy_request():
			# Global.dbg("Player('%s'): _on_card_clicked_signal: Allowing outstanding buy request" % [player_id])
			Global.allow_outstanding_buy_request(player_id)
			return
		# Moved to game_state_machine:
		# if len(Global.stock_pile) > 0:
		# 	Global.discard_pile[0].is_draggable = false
		# 	Global.discard_pile[0].is_tappable = false
		# Global.dbg("Player('%s'): _on_card_clicked_signal: Drawing card '%s' from stock pile for player %s" % [player_id, playing_card.key, player_id])
		Global.draw_card_from_stock_pile(Global.private_player_info.id)
		return
	if game_state_machine.get_current_state_name() == 'PlayerDrewState':
		# If the player can meld their hand, interpret this click as an accident and ignore it.
		if is_meldable:
			Global.dbg("Player('%s'): _on_card_clicked_signal: Ignoring click on meldable hand card '%s' for player %s" % [player_id, playing_card.key, player_id])
			return
		var player_won = len(Global.private_player_info['card_keys_in_hand']) == 1
		Global.discard_card(player_id, playing_card.key, player_won)
		return

func _on_card_drag_started_signal(_playing_card, _from_position):
	var player_is_me = Global.private_player_info.id == player_id
	if not player_is_me: return # bots do not click or drag cards.
	if not is_my_turn: return

func _on_card_moved_signal(playing_card, _from_position, _global_position):
	var player_is_me = Global.private_player_info.id == player_id
	if not player_is_me: return # bots do not click or drag cards.
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
	if Global.is_server() and (current_state_name == 'PlayerWonRoundState' or current_state_name == 'TallyScoresState'):
		if not is_mouse_over_player(mouse_pos): return # false alarm.
		if is_winning_player and current_state_name == 'PlayerWonRoundState':
			# Allow host to click on winner to advance to TallyScoresState
			Global.dbg("Player('%s'): _input: Clicked on winning player node, advancing to TallyScoresState" % player_id)
			Global.send_transition_all_clients_state_to_signal('TallyScoresState')
			# Don't allow any other nodes to also handle this event.
			get_viewport().set_input_as_handled()
		if current_state_name == 'TallyScoresState':
			# Allow host to click on any player to advance to next round.
			Global.server_advance_to_next_round()
			# Don't allow any other nodes to also handle this event.
			get_viewport().set_input_as_handled()
		return
	# Only current player can click on _ANY_ player node and only during playing state.
	if not Global.is_my_turn() or not game_state_machine.is_playing_state(): return
	if not is_meldable and not is_buying_card: return
	# Finally, after all the trivial rejects, now calculate if the mouse is actually over this player node.
	if not is_mouse_over_player(mouse_pos): return # false alarm.
	if is_meldable and is_my_turn and len(Global.private_player_info['played_to_table']) == 0:
		Global.dbg("Player('%s'): _input: is_meldable=%s, PERSONALLY MELD!" % [player_id, is_meldable])
		Global.personally_meld_hand(player_id, last_hand_evaluation)
		# Don't allow any other nodes to also handle this event.
		get_viewport().set_input_as_handled()
		return
	if is_meldable: # current player wishes to meld publicly on this player.
		Global.dbg("Player('%s'): _input: is_meldable=%s, PUBLICLY MELD ON ME!" % [player_id, is_meldable])
		Global.meld_card_to_public_meld(is_meldable_player_id, is_meldable_card_key, player_id, is_meldable_meld_group_index)
		# Don't allow any other nodes to also handle this event.
		get_viewport().set_input_as_handled()
		return
	if not is_my_turn and is_buying_card:
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
