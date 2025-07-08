extends Control
class_name CardShuffler

@export var animation_duration: float = 3.0
# Approximate ending rotation for each card in the stock pile.
# This is used so that when the hands are dealt, the cards are rotated
# with a single half-turn as if a dealer was handling the cards.
@export var final_ending_card_rotation_delta: float = 0.0 # - PI

var cards: Array[PlayingCard] = []
#var cards = []
var one_over_num_cards = 1.0
var is_shuffling: bool = false

enum ShuffleType {
	SPIRAL_SWIRL,
	TORNADO_FLIP,
	WAVE_COLLAPSE,
	EXPLOSION_GATHER,
	ORBITAL_DANCE,
}

const DEFAULT_CARD_FLIP_DURATION = 0.5

func shuffle_deck(shuffle_type: ShuffleType = ShuffleType.SPIRAL_SWIRL):
	if is_shuffling: return
	# Global.dbg("shuffle_deck: type='%s', Global.screen_size=%s, center=%s" % [str(shuffle_type), str(Global.screen_size), str(center)])
	cards = Global.playing_cards.values()
	cards.shuffle()
	for card in cards: # Make sure all cards are visible
		card.show()
	one_over_num_cards = 1.0 / (cards.size() - 1) # '- 1' since i in range(cards.size())
	is_shuffling = true
	match shuffle_type:
		ShuffleType.SPIRAL_SWIRL:
			Global.dbg('shuffling with SPIRAL_SWIRL')
			await _spiral_swirl_shuffle()
		ShuffleType.TORNADO_FLIP:
			Global.dbg('shuffling with TORNADO_FLIP')
			await _tornado_flip_shuffle()
		ShuffleType.WAVE_COLLAPSE:
			Global.dbg('shuffling with WAVE_COLLAPSE')
			await _wave_collapse_shuffle()
		ShuffleType.EXPLOSION_GATHER:
			Global.dbg('shuffling with EXPLOSION_GATHER')
			await _explosion_gather_shuffle()
		ShuffleType.ORBITAL_DANCE:
			Global.dbg('shuffling with ORBITAL_DANCE')
			await _orbital_dance_shuffle()
	# No matter what shuffling was done, make sure only card backs are showing
	force_all_face_down()
	is_shuffling = false
	# Global.dbg("GML: shuffle completed")

func random_shuffle():
	var shuffle_types = [
		ShuffleType.SPIRAL_SWIRL,
		ShuffleType.TORNADO_FLIP,
		#ShuffleType.WAVE_COLLAPSE,
		#ShuffleType.EXPLOSION_GATHER,
		#ShuffleType.ORBITAL_DANCE
	]
	var random_type = shuffle_types[randi() % shuffle_types.size()]
	await shuffle_deck(random_type)

func form_initial_spiral_formation():
	var num_spirals = randi_range(3, 6) # Multiple spirals
	var radius = Global.screen_size.length() * 0.6
	for i in range(cards.size()):
		var card = cards[i]
		card.force_face_down() # Ensure all cards start face down
		var angle = (i * PI * 2) / cards.size() * num_spirals
		var start_pos = Global.screen_center + Vector2(cos(angle), sin(angle)) * radius

		card.position = start_pos
		card.rotation = angle + PI / 2
		#card.scale = Vector2(0.7, 0.7)
		card.scale = Vector2(2, 2)
		card.z_index = i
		# Global.dbg("initial card state: %s" % [str(card)])

# Methods to force a specific state for the entire deck without animation
func force_all_face_up():
	for i in range(cards.size()):
		var card = cards[i]
		card.force_face_up()

func force_all_face_down():
	for i in range(cards.size()):
		var card = cards[i]
		card.force_face_down()

# Animation 1: Spiral Swirl - Cards spiral in from edges, flip mid-flight, converge to center
func _spiral_swirl_shuffle():
	# Phase 1: Position cards in spiral formation around screen edges
	form_initial_spiral_formation()
	var tween = _spiral_swirl_inward_animation(animation_duration, true)
	await tween.finished

# This function returns a tween that then must be awaited.
func _spiral_swirl_inward_animation(spiral_duration, flip_twice = false, card_flip_duration = DEFAULT_CARD_FLIP_DURATION):
	# Phase 2: Animate spiral inward with flip
	var tween = create_tween()
	tween.set_parallel(true)

	var first_flip_delay = spiral_duration * 0.2
	var second_flip_delay = spiral_duration * 0.4
	var delay_factor = calc_delay_factor(0.0, spiral_duration * 0.01, card_flip_duration)
	var final_position_duration = spiral_duration * 0.1
	var swirl_phase_duration = spiral_duration - final_position_duration
	var final_position_offset = swirl_phase_duration
	for i in range(cards.size()):
		var card = cards[i]
		card.flip_duration = card_flip_duration
		var delay = i * delay_factor # Stagger the animation

		# Spiral movement to center
		var angle_delta = PI * 4 # Multiple rotations while moving
		var start_pos = card.position
		var _update_spiral_card = func(progress: float):
			var current_angle = lerp(0.0, angle_delta, progress)
			var current_radius = lerp(start_pos.distance_to(Global.screen_center), 0.0, ease_in_out(progress))
			var center_offset = start_pos.direction_to(Global.screen_center) * (1.0 - progress) # * start_pos.distance_to(Global.screen_center)
			card.position = Global.screen_center + center_offset + Vector2(cos(current_angle), sin(current_angle)) * current_radius
			card.rotation += 0.1

		tween.tween_method(
			_update_spiral_card,
			0.0, 1.0, swirl_phase_duration
		).set_delay(delay)

		# Flip animation during movement
		tween.tween_callback(card.flip_card).set_delay(delay + first_flip_delay)
		if flip_twice:
			# And flip them back half-way through
			tween.tween_callback(card.flip_card).set_delay(delay + second_flip_delay)

		# Final positioning in stack
		tween.tween_property(card, "position",
			Global.stock_pile_position + Vector2(randf_range(-2, 2), -i * Global.CARD_SPACING_IN_STACK),
			final_position_duration
		).set_delay(delay + final_position_offset)
		tween.tween_property(card, "rotation", final_ending_card_rotation_delta + randf_range(-0.1, 0.1), final_position_duration).set_delay(delay + final_position_offset)
		tween.tween_property(card, "scale", Vector2.ONE, final_position_duration).set_delay(delay + final_position_offset)
	return tween

#func _update_spiral_card(card: PlayingCard, start_pos: Vector2, angle_delta: float, progress: float):
	#var current_angle = lerp(0.0, angle_delta, progress)
	#var current_radius = lerp(start_pos.distance_to(Global.screen_center), 0.0, ease_in_out(progress))
	#var center_offset = start_pos.direction_to(Global.screen_center) * (1.0 - progress) * start_pos.distance_to(Global.screen_center)
	#
	#card.position = Global.screen_center + center_offset + Vector2(cos(current_angle), sin(current_angle)) * current_radius
	#card.rotation += 0.1

# calc_delay_factor is used to spread out the delay over a phase_duration
# when the delay is calcuated like this:
#   var delay = offset + i * delay_factor
# where i is in the range(0, len(cards))  (inclusive, exclusive].
# It is calculated such that the very last card flipped has enough time to perform its
# flip animation.
func calc_delay_factor(offset: float, phase_duration: float, card_flip_duration: float) -> float:
	var last_card_flip_offset = phase_duration - offset - card_flip_duration
	return last_card_flip_offset * one_over_num_cards

# Animation 2: Tornado Flip - Cards form tornado, all flip simultaneously, collapse
func _tornado_flip_shuffle():
	form_initial_spiral_formation()

	# Phase 1: Form tornado shape
	var tween = create_tween()
	tween.set_parallel(true)
	var card_flip_duration = 0.6
	var phase1_duration = clamp(animation_duration * 0.8, 2 * card_flip_duration, 30.0) # 30 for debugging
	var first_flip_delay = animation_duration * 0.3
	var second_flip_delay = clamp(first_flip_delay + card_flip_duration + animation_duration * 0.3, 0.0, phase1_duration - card_flip_duration)
	first_flip_delay = clamp(first_flip_delay, 0.0, second_flip_delay - card_flip_duration)
	Global.dbg('_tornado_flip_shuffle: phase1_duration: %0.2f, first_flip_delay: %0.2f, second_flip_delay: %0.2f' % [phase1_duration, first_flip_delay, second_flip_delay])
	var delay_factor = calc_delay_factor(0.0, phase1_duration * 0.3, card_flip_duration)
	for i in range(cards.size()):
		var card = cards[i]
		card.flip_duration = card_flip_duration
		var delay = i * delay_factor # Stagger the card flipping

		var height_factor = float(i) / cards.size()
		var radius = lerp(Global.screen_size.y / 2, 50.0, height_factor)
		var angle = height_factor * PI * 8 # Tornado spiral
		var tornado_pos = Global.screen_center + Vector2(cos(angle) * radius, sin(angle) * radius)
		tornado_pos.y = lerp(Global.screen_size.y - 200, 200.0, height_factor)

		tween.tween_property(card, "position", tornado_pos, phase1_duration)
		tween.tween_property(card, "rotation", angle, phase1_duration)
		tween.tween_property(card, "scale", Vector2(0.8, 0.8), phase1_duration)
		tween.tween_callback(card.flip_card).set_delay(delay + first_flip_delay) # reveal face
		# And flip them back half-way through
		tween.tween_callback(card.flip_card).set_delay(delay + second_flip_delay)
	# Global.dbg('GML1: _tornado_flip_shuffle")
	await tween.finished
	# Global.dbg('GML2: _tornado_flip_shuffle")

	# Global.dbg('phase 1 completed - checking %d cards to be all face-up...' % [cards.size()])
	# for i in range(cards.size()):
	# 	var card = cards[i]
	# 	if not card.is_face_up:
	# 		Global.dbg("card '%s' is face down!!!" % [card.key])
	# force_all_face_up() # workaround when some faces don't get properly flipped.
	# Global.dbg('phase 2 starting')

	# Phase 2: Simultaneous flip while swirling
	# var phase2_duration = animation_duration * 0.4
	# tween = _spiral_swirl_inward_animation(phase2_duration, card_flip_duration) # Doesn't keep original position between transitions.
	# tween = create_tween()
	# tween.set_parallel(true)
	# This is broken:
	# delay_factor = calc_delay_factor(card_flip_offset, phase2_duration, card_flip_duration)
	# for i in range(cards.size()):
	# 	var card = cards[i]
	# 	card.flip_duration = card_flip_duration
	# 	tween.tween_callback(card.flip_card).set_delay(card_flip_offset + i * delay_factor) # Flip card to back

	# 	var current_pos = card.position
	# 	var tornado_radius = 200.0
	# 	var rot_range = randf_range(-0.5, 0.5)
	# 	var radius_range = randf_range(-10.0, 10.0)
	# 	var _update_tornado_swirl = func(progress: float):
	# 		var angle_progress = progress * 2.0 * PI
	# 		var r = tornado_radius + progress * radius_range
	# 		var rot = rot_range * progress
	# 		var offset = clamp(10.0 * progress, 0.0, 1.0) * Vector2(cos(rot + angle_progress) * r, sin(rot + angle_progress) * r)
	# 		card.position = current_pos + offset

	# 	# Continue swirling during flip
	# 	tween.tween_method(
	# 		_update_tornado_swirl,
	# 		0.0, 1.0, phase2_duration
	# 	) # .set_delay(animation_duration * 0.1)

	force_all_face_down() # workaround when some faces don't get properly flipped.
	# ensure that all cards are face down before collapsing
	# for i in range(cards.size()):
	# 	var card = cards[i]
	# 	if card.tween: await card.tween.finished # This hangs forever!!!

	var collapse_duration = animation_duration - phase1_duration
	# Global.dbg('GML3: _tornado_flip_shuffle: collapse_duration=%0.2f' % [collapse_duration])
	await _collapse_to_stack(collapse_duration)
	# tween.tween_callback(collapse_tween_func)
	# Global.dbg('GML4: _tornado_flip_shuffle")
	# await tween.finished
	# Global.dbg('GML5: _tornado_flip_shuffle")
	# Global.dbg('phase 2 completed')

#func _update_tornado_swirl(card: PlayingCard, angle_progress: float):
	#var current_pos = card.position
	##var center = get_viewport().get_visible_rect().size / 2
	#var offset = Vector2(cos(angle_progress) * 20, sin(angle_progress) * 20)
	#card.position = current_pos + offset

# Animation 3: Wave Collapse - Cards enter in waves, flip in sequence, collapse in layers
func _wave_collapse_shuffle():
	var waves = 5
	var cards_per_wave = int(float(cards.size()) / waves)

	# Phase 1: Waves enter from different sides
	for wave in range(waves):
		var start_side = wave % 4 # 0=left, 1=top, 2=right, 3=bottom
		var wave_start = wave * cards_per_wave
		var wave_end = min((wave + 1) * cards_per_wave, cards.size())

		for i in range(wave_start, wave_end):
			var card = cards[i]
			card.flip_duration = DEFAULT_CARD_FLIP_DURATION
			var wave_progress = float(i - wave_start) / cards_per_wave

			# Position based on entry side
			match start_side:
				0: card.position = Vector2(-100, lerp(0.0, Global.screen_size.y, wave_progress))
				1: card.position = Vector2(lerp(0.0, Global.screen_size.x, wave_progress), -100)
				2: card.position = Vector2(Global.screen_size.x + 100, lerp(Global.screen_size.y, 0.0, wave_progress))
				3: card.position = Vector2(lerp(Global.screen_size.x, 0.0, wave_progress), Global.screen_size.y + 100)

			card.rotation = randf_range(-PI / 4, PI / 4)
			card.scale = Vector2(0.6, 0.6)

	# Phase 2: Wave animation with flips
	var tween = create_tween()
	tween.set_parallel(true)

	for wave in range(waves):
		var wave_start = wave * cards_per_wave
		var wave_end = min((wave + 1) * cards_per_wave, cards.size())
		var wave_delay = wave * 0.3

		for i in range(wave_start, wave_end):
			var card = cards[i]
			card.flip_duration = DEFAULT_CARD_FLIP_DURATION
			var card_delay = (i - wave_start) * one_over_num_cards

			# Move to temporary formation
			var temp_pos = Global.screen_center + Vector2(
				randf_range(-150, 150),
				randf_range(-100, 100) - wave * 20
			)

			tween.tween_property(card, "position", temp_pos, 0.8).set_delay(wave_delay + card_delay)
			tween.tween_property(card, "scale", Vector2.ONE, 0.8).set_delay(wave_delay + card_delay)
			tween.tween_callback(card.flip_card).set_delay(wave_delay + card_delay + 0.3)
	await tween.finished
	await get_tree().create_timer(animation_duration * 0.7).timeout

	# Phase 3: Final collapse
	await _collapse_to_stack()

# Animation 4: Explosion Gather - Cards explode outward, flip, then get sucked back in
func _explosion_gather_shuffle():
	# Phase 1: Explosion outward
	var tween = create_tween()
	tween.set_parallel(true)

	for i in range(cards.size()):
		var card = cards[i]
		card.flip_duration = DEFAULT_CARD_FLIP_DURATION
		var angle = randf() * PI * 2
		var distance = randf_range(300, 600)
		var explosion_pos = Global.screen_center + Vector2(cos(angle), sin(angle)) * distance

		# Keep cards on screen
		explosion_pos.x = clamp(explosion_pos.x, 50, Global.screen_size.x - 50)
		explosion_pos.y = clamp(explosion_pos.y, 50, Global.screen_size.y - 50)

		card.position = Global.screen_center
		card.scale = Vector2(0.3, 0.3)

		tween.tween_property(card, "position", explosion_pos, animation_duration * 0.3)
		tween.tween_property(card, "scale", Vector2(0.9, 0.9), animation_duration * 0.3)
		tween.tween_property(card, "rotation", randf_range(-PI, PI), animation_duration * 0.3)

		# Flip during explosion
		tween.tween_callback(card.flip_card).set_delay(animation_duration * 0.15)
	await tween.finished
	await get_tree().create_timer(animation_duration * 0.4).timeout

	# Phase 2: Gather back with magnetic effect
	tween = create_tween()
	tween.set_parallel(true)

	for i in range(cards.size()):
		var card = cards[i]
		card.flip_duration = DEFAULT_CARD_FLIP_DURATION
		var delay = randf() * 0.5 # Random timing for magnetic effect

		tween.tween_property(card, "position",
			Global.screen_center + Vector2(randf_range(-3, 3), -i * Global.CARD_SPACING_IN_STACK),
			animation_duration * 0.6
		).set_delay(delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)

		tween.tween_property(card, "rotation", 0.0, animation_duration * 0.4).set_delay(delay)
		tween.tween_property(card, "scale", Vector2.ONE, animation_duration * 0.4).set_delay(delay)
	await tween.finished

# Animation 5: Orbital Dance - Cards orbit in multiple rings, flip in harmony, converge
func _orbital_dance_shuffle():
	var rings = 4
	var cards_per_ring = int(float(cards.size()) / rings)

	# Phase 1: Form orbital rings
	var tween = create_tween()
	tween.set_parallel(true)

	for ring in range(rings):
		var ring_radius = 100 + ring * 60
		var ring_start = ring * cards_per_ring
		var ring_end = min((ring + 1) * cards_per_ring, cards.size())
		var cards_in_ring = ring_end - ring_start

		for i in range(ring_start, ring_end):
			var card = cards[i]
			card.flip_duration = DEFAULT_CARD_FLIP_DURATION
			var angle = (float(i - ring_start) / cards_in_ring) * PI * 2
			var orbit_pos = Global.screen_center + Vector2(cos(angle), sin(angle)) * ring_radius

			card.position = Vector2(randf_range(0, Global.screen_center.x * 2), randf_range(0, Global.screen_center.y * 2))
			card.scale = Vector2(0.7, 0.7)

			tween.tween_property(card, "position", orbit_pos, animation_duration * 0.4)
			tween.tween_property(card, "scale", Vector2(0.8, 0.8), animation_duration * 0.4)
	await tween.finished

	# Phase 2: Orbital dance with synchronized flips
	tween = create_tween()
	tween.set_parallel(true)

	for ring in range(rings):
		var ring_start = ring * cards_per_ring
		var ring_end = min((ring + 1) * cards_per_ring, cards.size())
		var orbit_speed = 1.0 + ring * 0.5 # Outer rings move faster
		var cards_in_ring = ring_end - ring_start

		for i in range(ring_start, ring_end):
			var card = cards[i]
			card.flip_duration = DEFAULT_CARD_FLIP_DURATION
			var card_index = i - ring_start
			var _update_orbital_motion = func(angle_progress: float):
				var radius = 100 + ring * 60
				var base_angle = (float(card_index) / cards_in_ring) * PI * 2
				var current_angle = base_angle + angle_progress
				card.position = Global.screen_center + Vector2(cos(current_angle), sin(current_angle)) * radius
				card.rotation = current_angle + PI / 2

			# Orbital motion
			tween.tween_method(
				_update_orbital_motion,
				0.0, PI * 2 * orbit_speed, animation_duration * 0.5
			)

			# Synchronized flip
			tween.tween_callback(card.flip_card).set_delay(animation_duration * 0.25)
	await tween.finished
	await get_tree().create_timer(animation_duration * 0.6).timeout

	# Phase 3: Spiral convergence
	await _spiral_convergence()

#func _update_orbital_motion(card: PlayingCard, ring: int, card_index: int, cards_in_ring: int, angle_progress: float):
	#var center = get_viewport().get_visible_rect().size / 2
	#var radius = 100 + ring * 60
	#var base_angle = (float(card_index) / cards_in_ring) * PI * 2
	#var current_angle = base_angle + angle_progress
	#
	#card.position = Global.screen_center + Vector2(cos(current_angle), sin(current_angle)) * radius
	#card.rotation = current_angle + PI/2

# Helper function: Collapse all cards to final stack with no flipping.
func _collapse_to_stack(collapse_duration: float = 1.0):
	var tween = create_tween()
	tween.set_parallel(true)
	var position_duration = collapse_duration * 0.7
	var rotation_duration = collapse_duration * 0.6
	var scale_duration = collapse_duration * 0.6
	var z_index_duration = collapse_duration * 0.1
	var delay_randomization_factor = collapse_duration * 0.3
	var z_index_delay = (collapse_duration - delay_randomization_factor) - z_index_duration

	for i in range(cards.size()):
		var card = cards[i]
		var delay = randf() * delay_randomization_factor
		var new_z_index = cards.size() - i # Reverse order for stacking

		tween.tween_property(card, "position",
			Global.stock_pile_position + Vector2(randf_range(-2, 2), -new_z_index * Global.CARD_SPACING_IN_STACK),
			position_duration
		).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		tween.tween_property(card, "rotation", final_ending_card_rotation_delta + randf_range(-0.1, 0.1), rotation_duration).set_delay(delay)
		tween.tween_property(card, "scale", Vector2.ONE, scale_duration).set_delay(delay)
		tween.tween_property(card, "z_index", new_z_index, z_index_duration).set_delay(delay + z_index_delay)
	await tween.finished

# Helper function: Spiral convergence for orbital dance
func _spiral_convergence():
	var tween = create_tween()
	tween.set_parallel(true)

	for i in range(cards.size()):
		var card = cards[i]
		card.flip_duration = DEFAULT_CARD_FLIP_DURATION
		var spiral_delay = i * 0.02
		var start_pos = card.position
		var _update_spiral_convergence = func(progress: float):
			var spiral_progress = ease_in_out(progress)
			var angle = progress * PI * 4
			var radius = lerp(start_pos.distance_to(Global.screen_center), 0.0, spiral_progress)
			var current_center = start_pos.lerp(Global.screen_center, spiral_progress)
			card.position = current_center + Vector2(cos(angle), sin(angle)) * radius
			card.scale = Vector2.ONE.lerp(Vector2.ONE, progress)

		tween.tween_method(
			_update_spiral_convergence,
			0.0, 1.0, animation_duration * 0.4
		).set_delay(spiral_delay)
	await tween.finished

#func _update_spiral_convergence(card: PlayingCard, start_pos: Vector2, progress: float):
	#var spiral_progress = ease_in_out(progress)
	#var angle = progress * PI * 4
	#var radius = lerp(start_pos.distance_to(Global.screen_center), 0.0, spiral_progress)
	#var current_center = start_pos.lerp(Global.screen_center, spiral_progress)
	#
	#card.position = current_Global.screen_center + Vector2(cos(angle), sin(angle)) * radius
	#card.scale = Vector2.ONE.lerp(Vector2.ONE, progress)

# Utility function to ease animation curves
func ease_in_out(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)
