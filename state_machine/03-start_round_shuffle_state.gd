extends GameState

@onready var shuffler = $CardShuffler
@export var playing_cards_control: Control

const PLAYING_CARD_PATH = "res://playing_cards/playing_card.tscn"
const CARD_SHUFFLER_SCRIPT = "res://playing_cards/card_shuffler.gd"

# Internal signal
# signal stock_pile_synchronization_complete_signal

func enter(_params: Dictionary):
	Global.stock_pile = []
	Global.discard_pile = []
	var num_decks = Global.get_total_num_card_decks()
	Global.dbg("ENTER StartRoundShuffleState using %d decks" % [num_decks])
	if len(Global.playing_cards) == 0:
		# Now instantiate all the cards in preparation for the shuffling animation
		for idx in range(num_decks):
			generate_playing_cards_deck(idx)
	else: # Make all cards undraggable
		for card in Global.playing_cards.values():
			card.is_draggable = false
	await shuffler.random_shuffle()
	# Now copy the official deck order to Global.stock_pile on the host/server
	# and synchronize it to all clients.
	if Global.is_server():
		# Global.dbg("GML3")
		Global.stock_pile = shuffler.cards
		# Do NOT clear shuffler.cards because that also clears Global.stock_pile!!!
		# shuffler.cards.clear()
		# Global.dbg("GML4")
		Global.register_ack_sync_state('synchronize_all_stock_piles', {'next_state': 'DealNewRoundState'})
		Global.synchronize_all_stock_piles('synchronize_all_stock_piles')

func exit():
	Global.dbg("LEAVE StartRoundShuffleState")

func generate_playing_cards_deck(deck: int):
	# Create the two (different) jokers
	add_card('JOKER', '1', deck, 15, 'res://svg-card-fronts/JOKER-1.svg')
	add_card('JOKER', '2', deck, 15, 'res://svg-card-fronts/JOKER-2.svg')
	var suits = ['hearts', 'diamonds', 'clubs', 'spades']
	var file_prefixes = ['HEART', 'DIAMOND', 'CLUB', 'SPADE']
	var ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
	var points = [15, 5, 5, 5, 5, 5, 5, 5, 5, 10, 10, 10, 10]
	var file_suffixes = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11-JACK', '12-QUEEN', '13-KING']
	for suit_idx in range(len(suits)):
		var suit = suits[suit_idx]
		var file_prefix = file_prefixes[suit_idx]
		for rank_idx in range(len(ranks)):
			var rank = ranks[rank_idx]
			var file_suffix = file_suffixes[rank_idx]
			var face_path = 'res://svg-card-fronts/%s-%s.svg' % [file_prefix, file_suffix]
			add_card(rank, suit, deck, points[rank_idx], face_path)

func add_card(rank: String, suit: String, deck: int, points: int, face_path: String) -> void:
	var playing_card_scene = preload(PLAYING_CARD_PATH)
	var card = playing_card_scene.instantiate() as PlayingCard
	card.initialize(rank, suit, points, face_path)
	playing_cards_control.add_child(card)
	var key = Global.gen_playing_card_key(rank, suit, deck)
	card.key = key
	Global.playing_cards[key] = card
