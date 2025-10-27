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
		# Step 1 – Starting a Game
		'en': 'Multiplayer Liverpool Rummy can be played either solo against AI opponents or online with friends — with or without extra bots.

To play solo, click “Host New Game” on the main menu and add one or more bots to your lobby.

To play with friends, it works best if everyone’s on the same Wi‑Fi or hotspot. One player hosts, and the others join when the game appears in their lobby list.

If it doesn’t show up automatically, the host can share their local IP (it’s shown in the lobby) so others can type it in and tap “Join Game”.
',
		'de': 'Mehrspieler‑Liverpool Rummy kannst du entweder alleine gegen Computergegner oder online mit Freunden spielen – mit oder ohne zusätzliche Bots.

Um solo zu spielen, klicke im Hauptmenü auf „Neues Spiel hosten“ und füge einen oder mehrere Bots zu deiner Lobby hinzu.

Zum Spielen mit Freunden klappt es am besten, wenn alle im selben WLAN oder Hotspot sind. Ein Spieler hostet, und die anderen können beitreten, sobald das Spiel in ihrer Lobby‑Liste erscheint.

Falls es nicht automatisch angezeigt wird, kann der Gastgeber seine lokale IP‑Adresse (in der Lobby zu sehen) an andere weitergeben. Diese geben die IP‑Adresse ein und klicken dann auf „Spiel beitreten“.
',
	},
	{
		# Step 2 – Managing Players and Bots
		'en': 'While players are joining, the host can add or remove bots (or players) by clicking “Add Bot” or by dragging a player’s icon to “Remove”.

When everyone’s ready in the lobby, the host clicks “Start Game” to begin!
',
		'de': 'Während die Spieler beitreten, kann der Gastgeber Bots (oder Spieler) hinzufügen oder entfernen, indem er auf „Bot hinzufügen“ klickt oder das Spielersymbol zum „Entfernen“-Button zieht.

Wenn alle bereit sind, klickt der Gastgeber auf „Spiel starten“, um loszulegen!
',
	},
	{
		# Step 3 – Round Requirements
		'en': 'Each round has its own melding requirements that must be met to win.

At the top of each round’s screen, you’ll see how many books (groups of 3+ cards of the same rank) and runs (sequences of 4+ cards of the same suit) are needed.

In rounds 1–6, you must meet your own melding requirements before you can meld on other players’ melds.

Round 7 is special — you have to finish your hand completely with no cards left to win!
',
		'de': 'Jede Runde hat eigene Anforderungen zum Ablegen, die du erfüllen musst, um zu gewinnen.

Oben auf dem Rundenscreen siehst du, wie viele Bücher (Gruppen aus 3 oder mehr Karten mit gleichem Wert) und Folgen (Reihen aus 4 oder mehr Karten derselben Farbe) nötig sind.

In den Runden 1–6 musst du erst deine eigenen Anforderungen erfüllen, bevor du an andere Meldungen anlegen darfst.

Runde 7 ist besonders – du musst alle Karten ablegen und darfst keine mehr auf der Hand haben, um zu gewinnen!
',
	},
	{
		# Step 4 – Game Area
		'en': 'The game area has two main parts.
The top shows every player’s public melds, while the bottom is private to you. You can move and arrange your cards any way you like.

On the left are meld areas — drag cards there to build your melds. Once a card is in a meld area, you can’t tap it by mistake during your turn.

Cards in the lower-right can still be tapped to discard them during your turn.
',
		'de': 'Das Spielfeld hat zwei Hauptbereiche.
Oben siehst du die öffentlichen Meldungen aller Spieler, unten deinen privaten Bereich. Dort kannst du deine Karten beliebig verschieben und anordnen.

Links befinden sich die Ablageflächen – ziehe Karten dorthin, um deine Meldungen zu bilden. Karten, die dort liegen, können nicht versehentlich angetippt werden.

Karten im unteren rechten Bereich kannst du an‑tippen, um sie während deines Zugs abzuwerfen.
',
	},
	{
		# Step 5 – Player’s Turn
		'en': 'When it’s your turn, your player icon at the top will glow with a pulsing orange border.

First, draw a card — tap the left pile to draw from stock, or the right pile to take the top discard.

Then, try to meet the current round’s requirements. Drag cards into the meld zones until they sparkle. When you’re ready, tap the “Meld!” icon to lay down your hand.

After melding, keep adding cards to your melds or to others’. Tap “Meld!” again to confirm.

In rounds 1–6, end your turn by tapping a card in the lower-right to discard it. If you’ve got no cards left, you’ve won the round!

In round 7, the first person to meld must finish their hand completely and can’t add to others’ melds.
',
		'de': 'Wenn du an der Reihe bist, leuchtet dein Spielersymbol oben mit einem orangefarbenen, pulsierenden Rahmen.

Ziehe zuerst eine Karte – tippe auf den linken Stapel, um vom Nachziehstapel zu ziehen, oder auf den rechten, um die oberste Karte vom Ablagestapel zu nehmen.

Versuche dann, die Anforderungen der Runde zu erfüllen. Ziehe Karten in die Ablageflächen, bis sie funkeln. Wenn du bereit bist, tippe auf „Melden!“, um deine Hand auszulegen.

Danach kannst du weiter Karten an deine eigenen oder die Meldungen anderer Spieler anlegen. Tippe erneut auf „Melden!“, um das zu bestätigen.

In den Runden 1–6 beendest du deinen Zug, indem du im unteren rechten Bereich auf eine Karte tippst, um sie abzuwerfen. Wenn du danach keine Karten mehr auf der Hand hast, hast du die Runde gewonnen!

In Runde 7 muss der erste Spieler alle seine Karten ablegen und darf danach nicht mehr an andere Meldungen anlegen.
',
	},
	{
		# Step 6 – Scoring
		'en': 'After each round, the host taps “Tally Scores” to total all cards and update each player’s score.

Then tap “Next Round” (or “Final Scores” after round 7).

After all seven rounds, the player with the lowest total wins!

A scoreboard appears with each round’s scores and the final results — complete with trophies for 3rd, 2nd, and 1st place.

When you’re done, tap “Main Menu” to go back and start a new game anytime.
',
		'de': 'Nach jeder Runde tippt der Gastgeber auf „Punkte zählen“, um alle Karten zusammenzurechnen und die Punktestände zu aktualisieren.

Danach tippe auf „Nächste Runde“ (oder nach Runde 7 auf „Endergebnisse“).

Nach allen sieben Runden gewinnt der Spieler mit der niedrigsten Gesamtpunktzahl!

Die Endwertung zeigt alle Runden‑ und Gesamtpunkte – mit Pokalen für den 3., 2. und 1. Platz.

Wenn du fertig bist, tippe auf „Hauptmenü“, um zurückzukehren und ein neues Spiel zu starten.
',
	},
	{
		# Step 7 – Extra Buttons and Wrap‑Up
		'en': 'Every round has two helpful buttons.

In the top-left corner, tap the button to change your card back design.

In the top-right corner, tap “?” to open a quick help screen with Liverpool Rummy’s rules.

That’s it — you’re ready to play! Have fun playing Liverpool Rummy solo or with friends, and good luck!
',
		'de': 'Jede Runde hat zwei nützliche Buttons.

Oben links kannst du das Design der Kartenrückseiten ändern.

Oben rechts öffnet das „?“-Symbol eine Hilfe mit den Regeln von Liverpool Rummy.

Und das war’s – du bist bereit zu spielen! Viel Spaß beim Liverpool Rummy, allein oder mit Freunden, und viel Glück!
',
	},
]
