extends Control

@export var players_container: Node2D
@export var player_scene: PackedScene

var player_circle_radius: float

const PLAYER_SCENE_PATH = 'res://players/player.tscn'
const PLAYER_ARC_RAD = deg_to_rad(20.0)
const PLAYER_CIRCLE_RADIUS_RATIO = 3800.0 / 2880.0
const PLAYER_Y_OFFSET = 250

func _ready():
	var background_aspect_ratio = $Background.size.y / $Background.size.x
	if Global.screen_aspect_ratio >= background_aspect_ratio:
		Global.dbg("RootNode: _ready(): screen_aspect_ratio=%f, background_aspect_ratio=%f, setting Background to EXPAND_FIT_WIDTH_PROPORTIONAL" % [Global.screen_aspect_ratio, background_aspect_ratio])
		$Background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	else:
		Global.dbg("RootNode: _ready(): screen_aspect_ratio=%f, background_aspect_ratio=%f, setting Background to EXPAND_FIT_HEIGHT_PROPORTIONAL" % [Global.screen_aspect_ratio, background_aspect_ratio])
		$Background.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	Global.dbg("RootNode: _ready(): screen_aspect_ratio=%f, $Background.expand_mode=%s" % [Global.screen_aspect_ratio, str($Background.expand_mode)])
	Global.connect('change_round_signal', _on_change_round_signal)
	Global.connect('player_connected_signal', _on_player_connected_signal)
	Global.connect('attach_bot_instance_to_player_signal', _on_attach_bot_instance_to_player_signal)
	Global.connect('player_disconnected_signal', _on_player_disconnected_signal)
	Global.connect('game_state_updated_signal', _on_game_state_updated_signal)
	Global.connect('players_reordered_signal', _on_players_reordered_signal)
	Global.connect('reset_game_signal', _on_reset_game_signal)
	Global.connect('animate_winning_confetti_explosion_signal', _on_animate_winning_confetti_explosion_signal)

	player_circle_radius = $AllPlayersControl.size.x * PLAYER_CIRCLE_RADIUS_RATIO
	$HUDLayer/Control/CustomRulesDialog/CustomRulesPanel.size = get_viewport().get_visible_rect().size * Vector2(0.9, 0.9)
	if Global.LANGUAGE == 'de':
		$HUDLayer/Control/CustomRulesDialog/Title.text = "Regeln für Moonridge Rummy"
		$HUDLayer/Control/CustomRulesDialog/CustomRulesPanel/ScrollContainer/Label.text = german_rules_text

func _exit_tree():
	Global.disconnect('change_round_signal', _on_change_round_signal)
	Global.disconnect('player_connected_signal', _on_player_connected_signal)
	Global.disconnect('attach_bot_instance_to_player_signal', _on_attach_bot_instance_to_player_signal)
	Global.disconnect('player_disconnected_signal', _on_player_disconnected_signal)
	Global.disconnect('game_state_updated_signal', _on_game_state_updated_signal)
	Global.disconnect('players_reordered_signal', _on_players_reordered_signal)
	Global.disconnect('reset_game_signal', _on_reset_game_signal)
	Global.disconnect('animate_winning_confetti_explosion_signal', _on_animate_winning_confetti_explosion_signal)

func _on_rules_button_pressed() -> void:
	var panel = $HUDLayer/Control/CustomRulesDialog/CustomRulesPanel
	panel.size = Global.screen_size * Vector2(0.9, 0.9)
	panel.position = Global.screen_center - panel.size / 2.0
	panel.show()

func _on_custom_rules_dialog_button_pressed() -> void:
	var panel = $HUDLayer/Control/CustomRulesDialog/CustomRulesPanel
	panel.hide()

func _on_reset_game_signal() -> void:
	# Global.dbg("root_node:_on_reset_game_signal")
	# Remove all children from PlayersContainer
	for child in players_container.get_children():
		players_container.remove_child(child)
		child.queue_free()
	# Remove all children from PlayingCardsControl
	for child in $PlayingCardsControl.get_children():
		$PlayingCardsControl.remove_child(child)
		child.queue_free()

func _on_change_round_signal(round_scene: PackedScene, ack_sync_name: String) -> void:
	Global.dbg('RootNode: _on_change_round_signal...')
	change_round.call_deferred(round_scene, ack_sync_name)

func change_round(scene: PackedScene, ack_sync_name: String) -> void:
	for child in $RoundNode.get_children():
		$RoundNode.remove_child(child)
		child.queue_free()
	if scene:
		$RoundNode.add_child(scene.instantiate())
	if ack_sync_name != '':
		Global.ack_sync_completed(ack_sync_name)

func _on_player_connected_signal(_id, player_info):
	#player_info['turn_index'] = len(players_container.get_children())
	# Global.dbg("root_node:_on_player_connected_signal(%s): %s" % [str(id), str(player_info)])
	add_new_player_instance_to_container(player_info)

func add_new_player_instance_to_container(player_info):
	var player_instance = player_scene.instantiate()
	player_instance.player_id = player_info.id
	player_instance.player_name = player_info.name
	# The [turn_index] field is set in rearrange_players().
	players_container.add_child(player_instance)
	rearrange_players()
	return player_instance

func _on_attach_bot_instance_to_player_signal(id: String, bot_instance: Bot) -> void:
	var bot_private_player_info = Global.bots_private_player_info[id]
	if not bot_private_player_info:
		push_error("(%d)root_node: _on_attach_bot_instance_to_player_signal: No bot private player info found for id=%s" % [multiplayer.get_unique_id(), id])
		return
	for player_instance in players_container.get_children():
		if player_instance.player_id == id:
			player_instance.add_child(bot_instance)
			return # Bot instance successfully attached to player instance
	push_error("(%d)root_node: _on_attach_bot_instance_to_player_signal: could not find player instance for id=%s" % [multiplayer.get_unique_id(), id])

func rearrange_players():
	# Rearrange all players in a nice arc - only performed on the server node.
	if Global.is_not_server(): return
	var children = players_container.get_children()
	var num_players = len(children)
	if num_players == 0: return # should not happen
	# Global.dbg("root_node:rearrange_players: num_players=%d" % [num_players])
	var center_x = $AllPlayersControl.size.x / 2.0
	for idx in range(num_players):
		var child = children[idx]
		var t = 0.0 if num_players == 1 else float(idx) / float(num_players - 1)
		var rot = lerp(-PLAYER_ARC_RAD, PLAYER_ARC_RAD, t)
		child.position = player_circle_radius * Vector2(cos(PI / 2.0 - rot), -sin(PI / 2.0 - rot)) + Vector2(center_x, player_circle_radius + PLAYER_Y_OFFSET)
		child.rotation = rot
		child.scale = Global.PLAYER_SCALE
		child.turn_index = idx
		# Global.dbg"  player %d at t=%0.2f: (%0.1f,%0.1f), rot=%0.2f: %s" %
		#	[idx + 1, t, child.position.x, child.position.y, rot, child.player_name])
	Global.send_game_state()

func _on_game_state_updated_signal():
	var num_players = len(Global.game_state.public_players_info)
	if num_players == 0: return # should not happen
	# First, delete any players or bots that have been deleted from the host
	var server_players = {}
	for pi in Global.game_state.public_players_info:
		server_players[pi.id] = pi
	var children = {}
	for player in players_container.get_children():
		var player_id = player.player_id
		if not player_id in server_players: # Remove this player from game
			players_container.remove_child(player)
			player.queue_free()
			continue
		children[player_id] = player
	# If this client's player was removed from the game, then players_container will be empty
	if len(children) == 0: return
	var center_x = $AllPlayersControl.size.x / 2.0
	var tween = players_container.create_tween()
	tween.set_parallel(true)
	for idx in range(num_players):
		var player_info = Global.game_state.public_players_info[idx]
		# Make sure that this player's private turn_index is updated correctly
		if player_info.id == Global.private_player_info.id:
			Global.private_player_info.turn_index = player_info.turn_index
		var t = 0.0 if num_players == 1 else float(idx) / float(num_players - 1)
		var new_rotation = lerp(-PLAYER_ARC_RAD, PLAYER_ARC_RAD, t)
		var new_position = player_circle_radius * Vector2(cos(PI / 2.0 - new_rotation), -sin(PI / 2.0 - new_rotation)) + Vector2(center_x, player_circle_radius + PLAYER_Y_OFFSET)
		var child
		if player_info.id in children:
			child = children[player_info.id]
			tween.tween_property(child, 'position', new_position, 0.2)
			tween.tween_property(child, 'rotation', new_rotation, 0.2)
		else: # Add this player/bot to the players_container
			child = add_new_player_instance_to_container(player_info)
			child.position = new_position
			child.rotation = new_rotation
		child.scale = Global.PLAYER_SCALE
		child.turn_index = player_info.turn_index
		# Global.dbg("root_node: _on_game_state_updated_signal: Player: id=%s, name=%s, num_cards=%d, score=%d, turn_index=%d" %
		#	[ player_info.id, player_info.name, player_info.num_cards, player_info.score, player_info.turn_index])
	await tween.finished

func _on_player_disconnected_signal(id, _previous_id, _new_id):
	# Global.dbg("root_node:_on_player_disconnected_signal: id=%s: removing from players_container" % [id])
	var players = players_container.get_children().filter(func(node): return node.player_id == id)
	if len(players) == 1:
		players_container.remove_child(players[0])
		players[0].queue_free()
	#else:
		#push_error("(%d)root_node:_on_player_disconnected_signal: id=%s: could not find players_container node" % [multiplayer.get_unique_id(), id])
	rearrange_players()

func _on_players_reordered_signal(new_order: Array):
	# Global.dbg('root_node._on_players_reordered_signal: %s' % [str(new_order)])
	var players_by_id = Global.get_players_by_id()
	var new_players = []
	for id in new_order:
		var pi = players_by_id[id]
		pi.turn_index = len(new_players)
		new_players.append(players_by_id[id])
	Global.game_state.public_players_info = new_players
	rearrange_players()

################################################################################

func _on_animate_winning_confetti_explosion_signal(num_millis: int) -> void:
	# Get viewport size for positioning
	var viewport_size = get_viewport().get_visible_rect().size

	# Create multiple confetti emitters across the top of the screen
	var num_emitters = 5
	var emitters = []

	for i in range(num_emitters):
		# Create CPUParticles2D node for confetti
		var confetti = CPUParticles2D.new()
		add_child(confetti)
		emitters.append(confetti)

		# Ensure confetti appears on top of everything
		confetti.z_index = 1000

		# Position emitters across the top of the screen
		confetti.position = Vector2(
			(viewport_size.x / num_emitters) * i + (viewport_size.x / num_emitters) * 0.5,
			-50 # Start slightly above screen
		)

		# Configure confetti properties
		confetti.emitting = true
		confetti.amount = 150
		confetti.lifetime = num_millis / 1000.0 # Convert milliseconds to seconds
		confetti.explosiveness = 0.8

		# Emission shape - spread horizontally
		confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		confetti.emission_rect_extents = Vector2(100, 10)

		# Movement properties
		confetti.direction = Vector2(0, 1) # Downward
		confetti.initial_velocity_min = 100.0
		confetti.initial_velocity_max = 200.0
		confetti.gravity = Vector2(0, 98) # Realistic gravity

		# Add some horizontal spread
		confetti.angular_velocity_min = -180.0
		confetti.angular_velocity_max = 180.0

		# Scale variation
		confetti.scale_amount_min = 0.5
		confetti.scale_amount_max = 1.5

		# Color variation - bright confetti colors
		var colors = [
			Color.RED,
			Color.BLUE,
			Color.GREEN,
			Color.YELLOW,
			Color.MAGENTA,
			Color.CYAN,
			Color.ORANGE
		]
		confetti.color = colors[i % colors.size()]

		# Add color variation over lifetime
		var gradient = Gradient.new()
		gradient.add_point(0.0, confetti.color)
		gradient.add_point(1.0, Color(confetti.color.r, confetti.color.g, confetti.color.b, 0.0))
		confetti.color_ramp = gradient

		# Shape - small rectangles for confetti pieces
		confetti.texture = preload("res://svgs/confetti_icon.svg")

	# Create tween for cleanup and additional effects
	var tween = create_tween()
	tween.set_parallel(true) # Allow multiple animations

	# Optional: Add screen shake effect
	# tween.tween_method(_shake_screen, 0.0, 0.0, num_millis / 1000.0)

	# Clean up particles after animation completes
	tween.tween_callback(_cleanup_confetti.bind(emitters)).set_delay(num_millis / 1000.0)

# Helper function for screen shake effect
func _shake_screen(intensity: float) -> void:
	if intensity > 0:
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		position = shake_offset
	else:
		position = Vector2.ZERO

# Cleanup function to remove particle emitters
func _cleanup_confetti(emitters: Array) -> void:
	for emitter in emitters:
		if is_instance_valid(emitter):
			emitter.emitting = false
			# Wait a bit for particles to fade out, then remove
			var cleanup_tween = create_tween()
			cleanup_tween.tween_callback(emitter.queue_free).set_delay(2.0)

var german_rules_text = "# Moonridge Rummy: Alle Runden und ihre Anforderungen\n\nMoonridge Rummy wird über sieben Runden gespielt, wobei jede Runde eine bestimmte  \nKombination aus Sätzen (Büchern) und Folgen (Sequenzen) erfordert, die ein Spieler\nablegen muss, um auszusteigen. Die Anforderungen werden mit jeder Runde anspruchsvoller.\nHier sind die Anforderungen für jede Runde:\n\n      |                                                                     | Karten gesamt\nRunde | Anforderung                                                         | benötigt\n------|---------------------------------------------------------------------|--------------\n  1   | Zwei Sätze zu drei Karten (2 Gruppen à 3 Karten)                    | 6\n  2   | Ein Satz zu drei und eine Folge von vier Karten                     | 7\n  3   | Zwei Folgen von vier Karten                                         | 8\n  4   | Drei Sätze zu drei Karten                                           | 9\n  5   | Zwei Sätze zu drei und eine Folge von vier Karten                   | 10\n  6   | Ein Satz zu drei und zwei Folgen von vier Karten                    | 11\n  7   | Drei Folgen von vier Karten (keine Restkarten, kein Abwurf erlaubt) | 12\n\n## Erklärung der Begriffe\n\n* Satz (Gruppe/Buch):\n  Drei oder mehr Karten gleichen Rangs (z. B. 8♥ 8♣ 8♠).\n\n* Folge (Sequenz):\n  Vier oder mehr aufeinanderfolgende Karten derselben Farbe (z. B. 3♥ 4♥ 5♥ 6♥).\n  Asse können hoch oder niedrig sein, aber Folgen dürfen nicht „umlaufen“ (z. B. König–Ass–2).\n\n## Besondere Hinweise\n\n* In der letzten Runde (Runde 7) müssen alle Karten in den geforderten\n  Kombinationen verwendet werden, und ein Abwurf am Ende ist nicht erlaubt.\n\n* Die Vorgaben für jede Runde müssen exakt erfüllt werden, bevor Karten abgelegt werden können."