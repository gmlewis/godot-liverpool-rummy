extends Control
class_name CardShuffler

@export var animation_duration: float = 3.0
@export var final_ending_card_rotation_delta: float = 0.0

var cards: Array[PlayingCard] = []
var is_shuffling: bool = false

enum ShuffleType {
	SPIRAL_SWIRL,
	TORNADO_FLIP,
	WAVE_COLLAPSE,
	EXPLOSION_GATHER,
	ORBITAL_DANCE,
	RIFFLE_BRIDGE,
	FOUNTAIN_CASCADE,
}

const DEFAULT_CARD_FLIP_DURATION = 0.5

# ============================================================================
# PUBLIC API
# ============================================================================

func shuffle_deck(shuffle_type: ShuffleType = ShuffleType.SPIRAL_SWIRL):
	if is_shuffling:
		return

	cards = Global.playing_cards.values()
	cards.shuffle()
	for card in cards:
		card.show()
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
		ShuffleType.RIFFLE_BRIDGE:
			Global.dbg('shuffling with RIFFLE_BRIDGE')
			await _riffle_bridge_shuffle()
		ShuffleType.FOUNTAIN_CASCADE:
			Global.dbg('shuffling with FOUNTAIN_CASCADE')
			await _fountain_cascade_shuffle()

	_force_all_face_down()
	is_shuffling = false

func random_shuffle():
	var shuffle_types = [
		ShuffleType.SPIRAL_SWIRL,
		ShuffleType.TORNADO_FLIP,
		ShuffleType.WAVE_COLLAPSE,
		ShuffleType.EXPLOSION_GATHER,
		ShuffleType.ORBITAL_DANCE,
		ShuffleType.RIFFLE_BRIDGE,
		ShuffleType.FOUNTAIN_CASCADE,
	]
	var random_type = shuffle_types[randi() % shuffle_types.size()]
	await shuffle_deck(random_type)

# ============================================================================
# ANIMATION 1: SPIRAL SWIRL (WORKING)
# Cards spiral in from edges, flip mid-flight, converge to center
# ============================================================================

func _spiral_swirl_shuffle():
	_form_spiral_formation()
	var tween = _create_spiral_inward_tween(animation_duration, true)
	await tween.finished

func _form_spiral_formation():
	var num_spirals = randi_range(3, 6)
	var radius = Global.screen_size.length() * 0.6
	for i in range(cards.size()):
		var card = cards[i]
		card.force_face_down()
		var angle = (i * PI * 2) / cards.size() * num_spirals
		var start_pos = Global.screen_center + Vector2(cos(angle), sin(angle)) * radius
		card.position = start_pos
		card.rotation = angle + PI / 2
		card.scale = Vector2(2, 2)
		card.z_index = i

func _create_spiral_inward_tween(spiral_duration: float, flip_twice: bool = false, card_flip_duration: float = DEFAULT_CARD_FLIP_DURATION):
	var tween = create_tween()
	tween.set_parallel(true)

	var first_flip_delay = spiral_duration * 0.2
	var second_flip_delay = spiral_duration * 0.4
	var delay_factor = _calc_delay_factor(0.0, spiral_duration * 0.01, card_flip_duration)
	var final_position_duration = spiral_duration * 0.1
	var swirl_phase_duration = spiral_duration - final_position_duration
	var final_position_offset = swirl_phase_duration

	for i in range(cards.size()):
		var card = cards[i]
		card.flip_duration = card_flip_duration
		var delay = i * delay_factor

		var angle_delta = PI * 4
		var start_pos = card.position
		var _update_spiral_card = func(progress: float):
			var current_angle = lerp(0.0, angle_delta, progress)
			var current_radius = lerp(start_pos.distance_to(Global.screen_center), 0.0, _ease_in_out(progress))
			var center_offset = start_pos.direction_to(Global.screen_center) * (1.0 - progress)
			card.position = Global.screen_center + center_offset + Vector2(cos(current_angle), sin(current_angle)) * current_radius
			card.rotation += 0.1

		tween.tween_method(_update_spiral_card, 0.0, 1.0, swirl_phase_duration).set_delay(delay)
		tween.tween_callback(card.flip_card).set_delay(delay + first_flip_delay)
		if flip_twice:
			tween.tween_callback(card.flip_card).set_delay(delay + second_flip_delay)

		tween.tween_property(card, "position",
			Global.stock_pile_position + Vector2(randf_range(-2, 2), -i * Global.CARD_SPACING_IN_STACK),
			final_position_duration
		).set_delay(delay + final_position_offset)
		tween.tween_property(card, "rotation", final_ending_card_rotation_delta + randf_range(-0.1, 0.1), final_position_duration).set_delay(delay + final_position_offset)
		tween.tween_property(card, "scale", Vector2.ONE, final_position_duration).set_delay(delay + final_position_offset)

	return tween

# ============================================================================
# ANIMATION 2: TORNADO FLIP (WORKING)
# Cards form tornado, all flip simultaneously, collapse
# ============================================================================

func _tornado_flip_shuffle():
	_form_spiral_formation()

	var tween = create_tween()
	tween.set_parallel(true)
	var card_flip_duration = 0.6
	var phase1_duration = clamp(animation_duration * 0.8, 2 * card_flip_duration, 30.0)
	var first_flip_delay = animation_duration * 0.3
	var second_flip_delay = clamp(first_flip_delay + card_flip_duration + animation_duration * 0.3, 0.0, phase1_duration - card_flip_duration)
	first_flip_delay = clamp(first_flip_delay, 0.0, second_flip_delay - card_flip_duration)
	Global.dbg('_tornado_flip_shuffle: phase1_duration: %0.2f, first_flip_delay: %0.2f, second_flip_delay: %0.2f' % [phase1_duration, first_flip_delay, second_flip_delay])

	var delay_factor = _calc_delay_factor(0.0, phase1_duration * 0.3, card_flip_duration)
	for i in range(cards.size()):
		var card = cards[i]
		card.flip_duration = card_flip_duration
		var delay = i * delay_factor

		var height_factor = float(i) / cards.size()
		var radius = lerp(Global.screen_size.y / 2, 50.0, height_factor)
		var angle = height_factor * PI * 8
		var tornado_pos = Global.screen_center + Vector2(cos(angle) * radius, sin(angle) * radius)
		tornado_pos.y = lerp(Global.screen_size.y - 200, 200.0, height_factor)

		tween.tween_property(card, "position", tornado_pos, phase1_duration)
		tween.tween_property(card, "rotation", angle, phase1_duration)
		tween.tween_property(card, "scale", Vector2(0.8, 0.8), phase1_duration)
		tween.tween_callback(card.flip_card).set_delay(delay + first_flip_delay)
		tween.tween_callback(card.flip_card).set_delay(delay + second_flip_delay)

	await tween.finished
	_force_all_face_down()

	var collapse_duration = animation_duration - phase1_duration
	await _collapse_to_stack(collapse_duration)

# ============================================================================
# ANIMATION 3: WAVE COLLAPSE
# Cards enter in waves from different sides, flip in sequence, collapse
# ============================================================================

func _wave_collapse_shuffle():
	var waves = 5
	var cards_per_wave = ceili(float(cards.size()) / waves)

	for i in range(cards.size()):
		var card = cards[i]
		card.force_face_down()
		var wave = int(i / float(cards_per_wave))
		var wave_progress = float(i % cards_per_wave) / cards_per_wave
		var start_side = wave % 4

		match start_side:
			0: card.position = Vector2(-200, lerp(0.0, Global.screen_size.y, wave_progress))
			1: card.position = Vector2(lerp(0.0, Global.screen_size.x, wave_progress), -200)
			2: card.position = Vector2(Global.screen_size.x + 200, lerp(Global.screen_size.y, 0.0, wave_progress))
			3: card.position = Vector2(lerp(Global.screen_size.x, 0.0, wave_progress), Global.screen_size.y + 200)

		card.rotation = randf_range(-PI / 4, PI / 4)
		card.scale = Vector2(0.6, 0.6)
		card.z_index = i

	var tween = create_tween()
	tween.set_parallel(true)
	var wave_duration = animation_duration * 0.5

	for i in range(cards.size()):
		var card = cards[i]
		card.flip_duration = DEFAULT_CARD_FLIP_DURATION
		var wave = int(i / float(cards_per_wave))
		var wave_delay = wave * 0.2
		var card_in_wave = i % cards_per_wave
		var card_delay = card_in_wave * 0.015

		var temp_pos = Global.screen_center + Vector2(
			randf_range(-200, 200),
			randf_range(-150, 150) - wave * 30
		)

		tween.tween_property(card, "position", temp_pos, wave_duration * 0.6).set_delay(wave_delay + card_delay)
		tween.tween_property(card, "scale", Vector2(0.9, 0.9), wave_duration * 0.6).set_delay(wave_delay + card_delay)
		tween.tween_property(card, "rotation", randf_range(-0.2, 0.2), wave_duration * 0.6).set_delay(wave_delay + card_delay)
		tween.tween_callback(card.flip_card).set_delay(wave_delay + card_delay + 0.3)
		tween.tween_callback(card.flip_card).set_delay(wave_delay + card_delay + 0.6)

	await tween.finished
	await _collapse_to_stack(animation_duration * 0.5)

# ============================================================================
# ANIMATION 4: EXPLOSION GATHER
# Cards explode outward from center, flip, then get sucked back in
# ============================================================================

func _explosion_gather_shuffle():
	for i in range(cards.size()):
		var card = cards[i]
		card.force_face_down()
		card.position = Global.screen_center
		card.scale = Vector2(0.3, 0.3)
		card.rotation = 0.0
		card.z_index = i

	var tween = create_tween()
	tween.set_parallel(true)
	var explosion_duration = animation_duration * 0.35

	for i in range(cards.size()):
		var card = cards[i]
		card.flip_duration = DEFAULT_CARD_FLIP_DURATION
		var angle = randf() * PI * 2
		var distance = randf_range(250, 500)
		var explosion_pos = Global.screen_center + Vector2(cos(angle), sin(angle)) * distance

		explosion_pos.x = clamp(explosion_pos.x, 100, Global.screen_size.x - 100)
		explosion_pos.y = clamp(explosion_pos.y, 100, Global.screen_size.y - 100)

		tween.tween_property(card, "position", explosion_pos, explosion_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(card, "scale", Vector2(0.85, 0.85), explosion_duration)
		tween.tween_property(card, "rotation", randf_range(-PI * 1.5, PI * 1.5), explosion_duration)
		tween.tween_callback(card.flip_card).set_delay(explosion_duration * 0.4)

	await tween.finished
	await get_tree().create_timer(0.3).timeout

	tween = create_tween()
	tween.set_parallel(true)
	var gather_duration = animation_duration * 0.65

	for i in range(cards.size()):
		var card = cards[i]
		var delay = randf() * 0.3

		tween.tween_callback(card.flip_card).set_delay(delay)
		tween.tween_property(card, "position",
			Global.stock_pile_position + Vector2(randf_range(-2, 2), -i * Global.CARD_SPACING_IN_STACK),
			gather_duration * 0.7
		).set_delay(delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		tween.tween_property(card, "rotation", final_ending_card_rotation_delta + randf_range(-0.1, 0.1), gather_duration * 0.6).set_delay(delay)
		tween.tween_property(card, "scale", Vector2.ONE, gather_duration * 0.6).set_delay(delay)

	await tween.finished

# ============================================================================
# ANIMATION 5: ORBITAL DANCE
# Cards orbit in multiple rings, flip in harmony, spiral to center
# ============================================================================

func _orbital_dance_shuffle():
	var rings = 4
	var cards_per_ring = ceili(float(cards.size()) / rings)

	for i in range(cards.size()):
		var card = cards[i]
		card.force_face_down()
		card.position = Vector2(randf_range(0, Global.screen_size.x), randf_range(0, Global.screen_size.y))
		card.scale = Vector2(0.5, 0.5)
		card.rotation = randf_range(0, PI * 2)
		card.z_index = i

	var tween = create_tween()
	tween.set_parallel(true)
	var formation_duration = animation_duration * 0.3

	for i in range(cards.size()):
		var card = cards[i]
		var ring = int(i / float(cards_per_ring))
		var card_in_ring = i % cards_per_ring
		var cards_in_this_ring = min(cards_per_ring, cards.size() - ring * cards_per_ring)
		var ring_radius = 120 + ring * 70
		var angle = (float(card_in_ring) / cards_in_this_ring) * PI * 2
		var orbit_pos = Global.screen_center + Vector2(cos(angle), sin(angle)) * ring_radius

		tween.tween_property(card, "position", orbit_pos, formation_duration)
		tween.tween_property(card, "scale", Vector2(0.75, 0.75), formation_duration)
		tween.tween_property(card, "rotation", angle + PI / 2, formation_duration)

	await tween.finished

	tween = create_tween()
	tween.set_parallel(true)
	var orbit_duration = animation_duration * 0.4

	for i in range(cards.size()):
		var card = cards[i]
		card.flip_duration = DEFAULT_CARD_FLIP_DURATION
		var ring = int(i / float(cards_per_ring))
		var card_in_ring = i % cards_per_ring
		var cards_in_this_ring = min(cards_per_ring, cards.size() - ring * cards_per_ring)
		var orbit_speed = 1.0 + ring * 0.3
		var ring_radius = 120 + ring * 70
		var base_angle = (float(card_in_ring) / cards_in_this_ring) * PI * 2

		var _update_orbit = func(progress: float):
			var current_angle = base_angle + progress * orbit_speed
			card.position = Global.screen_center + Vector2(cos(current_angle), sin(current_angle)) * ring_radius
			card.rotation = current_angle + PI / 2

		tween.tween_method(_update_orbit, 0.0, PI * 2, orbit_duration)
		tween.tween_callback(card.flip_card).set_delay(orbit_duration * 0.3)
		tween.tween_callback(card.flip_card).set_delay(orbit_duration * 0.65)

	await tween.finished
	await _spiral_converge_to_stack(animation_duration * 0.3)

# ============================================================================
# ANIMATION 6: RIFFLE BRIDGE (NEW)
# Classic riffle shuffle effect with cards interleaving and bridging
# ============================================================================

func _riffle_bridge_shuffle():
	var half = int(cards.size() / 2.0)

	for i in range(cards.size()):
		var card = cards[i]
		card.force_face_down()
		card.scale = Vector2.ONE
		card.rotation = 0.0
		card.z_index = i

		if i < half:
			card.position = Global.screen_center + Vector2(-300, 0) + Vector2(0, -i * 0.5)
		else:
			card.position = Global.screen_center + Vector2(300, 0) + Vector2(0, - (i - half) * 0.5)

	var tween = create_tween()
	tween.set_parallel(true)
	var riffle_duration = animation_duration * 0.4

	for i in range(cards.size()):
		var card = cards[i]
		card.flip_duration = DEFAULT_CARD_FLIP_DURATION
		var is_left = i < half
		var index_in_half = i if is_left else i - half
		var delay = index_in_half * 0.015

		var bridge_height = -200.0 - (abs(index_in_half - half / 2.0) * 2.0)
		var mid_x = float(Global.screen_center.x + (50.0 if is_left else -50.0))
		var mid_y = float(Global.screen_center.y + bridge_height)

		var _create_bridge_motion = func(progress: float):
			if progress < 0.5:
				var t = progress * 2.0
				var start_x = -300.0 if is_left else 300.0
				var current_x = lerp(start_x, mid_x - Global.screen_center.x, t)
				var current_y = lerp(0.0, mid_y - Global.screen_center.y, t)
				card.position = Global.screen_center + Vector2(current_x, current_y)
				card.rotation = lerp(0.0, PI * 0.15 * (-1 if is_left else 1), t)
			else:
				var t = (progress - 0.5) * 2.0
				var current_x = lerp(mid_x - Global.screen_center.x, 0.0, t)
				var current_y = lerp(mid_y - Global.screen_center.y, -i * 2.0, t)
				card.position = Global.screen_center + Vector2(current_x, current_y)
				card.rotation = lerp(PI * 0.15 * (-1.0 if is_left else 1.0), 0.0, t)

		tween.tween_method(_create_bridge_motion, 0.0, 1.0, riffle_duration).set_delay(delay)
		tween.tween_callback(card.flip_card).set_delay(delay + riffle_duration * 0.4)

	await tween.finished
	await get_tree().create_timer(0.2).timeout
	await _collapse_to_stack(animation_duration * 0.6)

# ============================================================================
# ANIMATION 7: FOUNTAIN CASCADE (NEW)
# Cards shoot up like a fountain and cascade down
# ============================================================================

func _fountain_cascade_shuffle():
	for i in range(cards.size()):
		var card = cards[i]
		card.force_face_down()
		card.position = Global.screen_center + Vector2(randf_range(-50, 50), 100)
		card.scale = Vector2(0.8, 0.8)
		card.rotation = 0.0
		card.z_index = i

	var tween = create_tween()
	tween.set_parallel(true)
	var fountain_duration = animation_duration * 0.5

	for i in range(cards.size()):
		var card = cards[i]
		card.flip_duration = DEFAULT_CARD_FLIP_DURATION
		var delay = i * 0.02
		var angle = randf_range(-PI * 0.3, PI * 0.3)
		var x_velocity = sin(angle) * 300
		var y_velocity = - randf_range(500, 700)
		var gravity = 1200.0

		var _fountain_motion = func(progress: float):
			var t = progress * fountain_duration
			var x = Global.screen_center.x + x_velocity * t + randf_range(-20, 20)
			var y = Global.screen_center.y + 100 + y_velocity * t + 0.5 * gravity * t * t
			card.position = Vector2(x, y)
			card.rotation = angle + progress * PI * 2

		tween.tween_method(_fountain_motion, 0.0, 1.0, fountain_duration).set_delay(delay)
		tween.tween_callback(card.flip_card).set_delay(delay + fountain_duration * 0.3)

	await tween.finished
	await get_tree().create_timer(0.2).timeout

	_force_all_face_down()
	await _collapse_to_stack(animation_duration * 0.5)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

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
		var new_z_index = cards.size() - i

		tween.tween_property(card, "position",
			Global.stock_pile_position + Vector2(randf_range(-2, 2), -new_z_index * Global.CARD_SPACING_IN_STACK),
			position_duration
		).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		tween.tween_property(card, "rotation", final_ending_card_rotation_delta + randf_range(-0.1, 0.1), rotation_duration).set_delay(delay)
		tween.tween_property(card, "scale", Vector2.ONE, scale_duration).set_delay(delay)
		tween.tween_property(card, "z_index", new_z_index, z_index_duration).set_delay(delay + z_index_delay)

	await tween.finished

func _spiral_converge_to_stack(converge_duration: float):
	var tween = create_tween()
	tween.set_parallel(true)

	for i in range(cards.size()):
		var card = cards[i]
		var delay = i * 0.01
		var start_pos = card.position

		var _spiral_to_stack = func(progress: float):
			var eased = _ease_in_out(progress)
			var angle = progress * PI * 3
			var radius = lerp(start_pos.distance_to(Global.screen_center), 0.0, eased)
			var center_lerp = start_pos.lerp(Global.stock_pile_position, eased)
			card.position = center_lerp + Vector2(cos(angle), sin(angle)) * radius
			card.rotation = lerp(card.rotation, final_ending_card_rotation_delta, eased)
			card.scale = card.scale.lerp(Vector2.ONE, eased)

		tween.tween_method(_spiral_to_stack, 0.0, 1.0, converge_duration).set_delay(delay)

	await tween.finished

	for i in range(cards.size()):
		var card = cards[i]
		card.position = Global.stock_pile_position + Vector2(randf_range(-2, 2), - (cards.size() - i) * Global.CARD_SPACING_IN_STACK)
		card.z_index = cards.size() - i

func _force_all_face_down():
	for card in cards:
		card.force_face_down()

func _calc_delay_factor(offset: float, phase_duration: float, card_flip_duration: float) -> float:
	var last_card_flip_offset = phase_duration - offset - card_flip_duration
	var one_over_num_cards = 1.0 / (cards.size() - 1)
	return last_card_flip_offset * one_over_num_cards

func _ease_in_out(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

func lerp(a: float, b: float, t: float) -> float:
	return a + (b - a) * t
