extends GameState

@onready var state_advance_button: TextureButton = $'../../HUDLayer/Control/StateAdvanceButton'

func enter(_params: Dictionary):
	Global.dbg("ENTER TutorialState")

	# Setup and show the "Main Menu" button
	_setup_main_menu_button()
	state_advance_button.show()

func exit():
	Global.dbg("LEAVE TutorialState")
	# Hide the button and disconnect signal when leaving state
	if state_advance_button.visible:
		state_advance_button.hide()
		if state_advance_button.pressed.is_connected(_on_main_menu_button_pressed):
			state_advance_button.pressed.disconnect(_on_main_menu_button_pressed)

func _setup_main_menu_button() -> void:
	# Load the appropriate SVG based on language
	var texture_path: String
	if Global.LANGUAGE == 'de':
		texture_path = "res://svgs/main-menu-german.svg"
	else:
		texture_path = "res://svgs/main-menu-english.svg"

	var texture = load(texture_path)
	state_advance_button.texture_normal = texture
	state_advance_button.texture_pressed = texture
	state_advance_button.texture_hover = texture

	# Enable texture scaling
	state_advance_button.ignore_texture_size = true
	state_advance_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

	# Resize button to 25% of screen width while maintaining aspect ratio
	var target_width = Global.screen_size.x * 0.25
	var texture_size = texture.get_size()
	var aspect_ratio = texture_size.y / texture_size.x
	var target_height = target_width * aspect_ratio

	state_advance_button.custom_minimum_size = Vector2(target_width, target_height)
	state_advance_button.size = Vector2(target_width, target_height)

	# Position button at 15% of screen width (left side), centered vertically
	# Calculate position offset from center anchor (0.5, 0.5)
	var target_x_center = Global.screen_size.x * 0.15
	var screen_center_x = Global.screen_size.x * 0.5
	var x_offset_from_center = target_x_center - screen_center_x

	state_advance_button.offset_left = x_offset_from_center - target_width / 2.0
	state_advance_button.offset_top = - target_height / 2.0
	state_advance_button.offset_right = x_offset_from_center + target_width / 2.0
	state_advance_button.offset_bottom = target_height / 2.0

	# Set z_index to be visible
	state_advance_button.z_index = 1000

	# Connect the button press signal
	if not state_advance_button.pressed.is_connected(_on_main_menu_button_pressed):
		state_advance_button.pressed.connect(_on_main_menu_button_pressed)

func _on_main_menu_button_pressed() -> void:
	Global.dbg("Main Menu button pressed from tutorial, resetting game")
	Global.reset_game_signal.emit()

var steps = [
	{
		'en': 'Multiplayer Liverpool Rummy can be played either solo against AI opponents or with friends online (with or without additional AI opponents). To play solo, simply click "Host New Game" from the main menu and add one or more "bots" to your game lobby. To play online with friends, it works best if all players are on the same WiFi network or hotspot. One player should click "Host New Game" from the main menu then other players should detect that the game is available and can click "Join Game" if it automatically appears in their game lobby list. If it does not appear automatically, the host player can share their local IP address (displayed in the game lobby) with other players who can then manually enter that IP address and then click "Join Game".',
		'de': '',
	},
	{
		'en': 'As players are joining the host’s game, the host may add or remove bots (or players) by clicking on "Add Bot" or by dragging the player’s icon to the "Remove" button. Once all players have joined the game lobby, the host player can click "Start Game" to begin playing.',
		'de': '',
	},
	{
		'en': 'Each round has a specific set of requirements for melding that must be met for a player to win that round. The exact number of books (groups or sets of 3 or more cards of the same rank) and runs (sequences of 4 or more cards in the same suit) required to win each round is displayed on each round’s screen at the top. Note that in rounds 1-6, players must meet the round’s melding requirements and personally meld their own hand before they can meld on other players’ melds. Round 7 is the only round where players must meld their own hand and have no cards remaining in order to win the round.',
		'de': '',
	},
	{
		'en': 'The game area is divided into two main sections: the top section of the screen displays all players’ public melds, while the bottom section is private to the local player and cards can be moved at any time and arranged in any way the player desires. To the left of the bottom section are meld areas where players can drag and drop cards to build up their own melds. Cards that have been moved to one of the meld areas can not be accidentally tapped on which would otherwise cause them to be discarded during the player’s turn. Cards in the lower right area, however, can be tapped on to discard them during the player’s turn.',
		'de': '',
	},
	{
		'en': 'A player’s turn is indicated by a pulsing orange border around their player icon in the upper section of the screen. On a player’s turn, they must first draw a card either from the stock pile on the left or from the discard pile on the right by tapping on the desired pile. Once a player has completely satisfied the round’s melding requirements by dragging cards into the meld areas such that they are all sparkling, a "Meld!" indicator will appear on the player’s icon in the top section of the screen. The player can then tap on this "Meld!" indicator to meld their hand. After melding, the player may then drag cards from their private hand area into the meld areas on the left (whether for books or runs) and then publicly meld these cards when the "Meld!" indicator appears on any player icon in the top section (including possibly their own). Finally, for rounds 1-6, the player must discard a card by tapping on it in the lower right area to complete their turn. If the player has no cards remaining after discarding, then they have won the round. Note that in round 7, the first person to meld must have no cards remaining, and therefore they do not meld on other players’ melds (since they were the first to meld).',
		'de': '',
	},
	{
		'en': 'After each round, the host clicks the "Tally Scores" button where all players’ cards are totaled and counted against their scores. The host then clicks "Next Round" (or "Final Scores" after round 7). After all 7 rounds have been played, the player with the lowest score wins the game! A final scoreboard is displayed showing all players’ scores for each round as well as their total scores along with 3rd, 2nd, and 1st place trophies being awarded. After this, each player can click "Main Menu" to return to the main menu and start a new game if desired.',
		'de': '',
	},
]
