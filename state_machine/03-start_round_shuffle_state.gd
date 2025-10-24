extends GameState

@onready var shuffler = $CardShuffler
@export var playing_cards_control: Control

const PLAYING_CARD_PATH = "res://playing_cards/playing_card.tscn"
const CARD_SHUFFLER_SCRIPT = "res://playing_cards/card_shuffler.gd"

# Shuffle synchronization tracking
var shuffle_completed_clients: Array = []
var waiting_for_shuffle_completion: bool = false
var shuffle_completion_signal_emitted: bool = false

# Internal signal
signal all_clients_shuffle_complete_signal
# signal stock_pile_synchronization_complete_signal

func enter(_params: Dictionary):
	Global.stock_pile = []
	Global.discard_pile = []
	shuffle_completed_clients.clear()
	waiting_for_shuffle_completion = false
	shuffle_completion_signal_emitted = false
	var num_decks = Global.get_total_num_card_decks()
	Global.dbg("ENTER StartRoundShuffleState using %d decks" % [num_decks])
	if len(Global.playing_cards) == 0:
		# Now instantiate all the cards in preparation for the shuffling animation
		for idx in range(num_decks):
			generate_playing_cards_deck(idx)
	else: # Make all cards undraggable
		for card in Global.playing_cards.values():
			card.is_draggable = false

	# For server, set waiting flag BEFORE shuffle starts so it can receive client notifications
	if Global.is_server():
		waiting_for_shuffle_completion = true
		Global.dbg("StartRoundShuffleState: Server starting shuffle and ready to receive client notifications")

	await shuffler.random_shuffle()

	# Notify the server that this client has completed shuffling
	if Global.is_server():
		# Server/host marks itself as complete
		_on_client_shuffle_complete(1) # Server is always peer_id 1
		# Wait for all clients to complete their shuffle
		Global.dbg("StartRoundShuffleState: Server waiting for all clients to complete shuffle...")
		await all_clients_shuffle_complete_signal
		Global.dbg("StartRoundShuffleState: All clients have completed shuffle!")
	else:
		# Client notifies server that it has completed shuffling
		Global.dbg("StartRoundShuffleState: Client notifying server of shuffle completion")
		_rpc_notify_shuffle_complete.rpc_id(1) # Send to server only
		# Client waits for server to synchronize stock pile
		return

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

@rpc('any_peer', 'call_remote', 'reliable')
func _rpc_notify_shuffle_complete() -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	Global.dbg("StartRoundShuffleState: Received shuffle complete notification from peer %d" % sender_id)
	_on_client_shuffle_complete(sender_id)

func _on_client_shuffle_complete(peer_id: int) -> void:
	if not Global.is_server():
		Global.error("StartRoundShuffleState: _on_client_shuffle_complete called on non-server!")
		return

	if not waiting_for_shuffle_completion:
		Global.dbg("StartRoundShuffleState: Received shuffle complete from peer %d but not waiting" % peer_id)
		return

	if shuffle_completed_clients.has(peer_id):
		Global.dbg("StartRoundShuffleState: Peer %d already marked as shuffle complete" % peer_id)
		return

	shuffle_completed_clients.append(peer_id)
	var num_network_players = Global.game_state.public_players_info.filter(func(pi): return not pi.is_bot).size()
	Global.dbg("StartRoundShuffleState: Peer %d shuffle complete. %d/%d network clients done" % [peer_id, len(shuffle_completed_clients), num_network_players])

	# Check if all network clients (non-bots) have completed
	if len(shuffle_completed_clients) >= num_network_players:
		if not shuffle_completion_signal_emitted:
			shuffle_completion_signal_emitted = true
			Global.dbg("StartRoundShuffleState: All network clients shuffle complete! Emitting signal.")
			all_clients_shuffle_complete_signal.emit()

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
