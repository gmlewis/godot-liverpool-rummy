extends GameState

@onready var state_advance_button: TextureButton = $'../../HUDLayer/Control/StateAdvanceButton'

const LABEL_TEXT_SIZE = 50
const TUTORIAL_TEXT_SIZE = 45

# Tutorial UI components
var tutorial_popup: Panel
var step_label: Label
var progress_label: Label
var progress_container: HBoxContainer
var back_button: Button
var next_button: Button
var progress_rectangles: Array[ColorRect] = []

var current_step: int = 0

func enter(_params: Dictionary):
	Global.dbg("ENTER TutorialState")

	current_step = 0
	_create_tutorial_popup()
	_update_tutorial_display()

	# Setup and show the "Main Menu" button
	_setup_main_menu_button()
	state_advance_button.show()

func exit():
	Global.dbg("LEAVE TutorialState")

	# Free tutorial resources
	_free_tutorial_popup()

	# Hide the button and disconnect signal when leaving state
	if state_advance_button.visible:
		state_advance_button.hide()
		if state_advance_button.pressed.is_connected(_on_main_menu_button_pressed):
			state_advance_button.pressed.disconnect(_on_main_menu_button_pressed)

func _create_tutorial_popup() -> void:
	# Create main popup panel
	tutorial_popup = Panel.new()
	tutorial_popup.position = Vector2(Global.screen_size.x * 0.3, Global.screen_size.y * 0.1)
	tutorial_popup.size = Vector2(Global.screen_size.x * 0.7, Global.screen_size.y * 0.8)
	tutorial_popup.z_index = 2000

	# Style the panel with a semi-transparent background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style_box.border_color = Color(0.5, 0.3, 0.8, 1.0) # Purple border
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	tutorial_popup.add_theme_stylebox_override("panel", style_box)

	# Create VBoxContainer for layout
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = tutorial_popup.size - Vector2(40, 40)
	vbox.add_theme_constant_override("separation", 20)
	tutorial_popup.add_child(vbox)

	# Progress label (1/7)
	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", LABEL_TEXT_SIZE)
	progress_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	vbox.add_child(progress_label)

	# Step text label
	step_label = Label.new()
	step_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	step_label.custom_minimum_size = Vector2(0, Global.screen_size.y * 0.5)
	step_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	step_label.add_theme_font_size_override("font_size", TUTORIAL_TEXT_SIZE)
	step_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	vbox.add_child(step_label)

	# Add spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	# Progress indicator container with back/next buttons
	var nav_container = HBoxContainer.new()
	nav_container.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_container.add_theme_constant_override("separation", 10)
	vbox.add_child(nav_container)

	# Back button (left arrow)
	back_button = Button.new()
	back_button.text = "◄"
	back_button.custom_minimum_size = Vector2(60, 60)
	back_button.add_theme_font_size_override("font_size", LABEL_TEXT_SIZE)
	back_button.pressed.connect(_on_back_pressed)
	nav_container.add_child(back_button)

	# Progress rectangles container
	progress_container = HBoxContainer.new()
	progress_container.alignment = BoxContainer.ALIGNMENT_CENTER
	progress_container.add_theme_constant_override("separation", 8)
	nav_container.add_child(progress_container)

	# Create progress rectangles
	for i in range(steps.size()):
		var rect = ColorRect.new()
		rect.custom_minimum_size = Vector2(80, 40)
		rect.color = Color(0.2, 0.8, 0.2, 1.0) # Green outline initially
		progress_container.add_child(rect)
		progress_rectangles.append(rect)

	# Next button (right arrow)
	next_button = Button.new()
	next_button.text = "►"
	next_button.custom_minimum_size = Vector2(160, 80)
	next_button.add_theme_font_size_override("font_size", LABEL_TEXT_SIZE)
	next_button.pressed.connect(_on_next_pressed)
	nav_container.add_child(next_button)

	# Add popup to the scene tree
	add_child(tutorial_popup)

func _update_tutorial_display() -> void:
	# Update progress label
	progress_label.text = "%d/%d" % [current_step + 1, steps.size()]

	# Update step text
	var language_key = Global.LANGUAGE if steps[current_step].has(Global.LANGUAGE) else 'en'
	step_label.text = steps[current_step][language_key]

	# Update progress rectangles
	for i in range(progress_rectangles.size()):
		if i == current_step:
			# Current step: solid purple
			progress_rectangles[i].color = Color(0.5, 0.3, 0.8, 1.0)
		else:
			# Other steps: green outline (simulate with thin green rect)
			progress_rectangles[i].color = Color(0.2, 0.8, 0.2, 0.3)

	# Show/hide navigation buttons
	back_button.visible = current_step > 0
	next_button.visible = current_step < steps.size() - 1

func _on_back_pressed() -> void:
	if current_step > 0:
		current_step -= 1
		_update_tutorial_display()

func _on_next_pressed() -> void:
	if current_step < steps.size() - 1:
		current_step += 1
		_update_tutorial_display()

func _free_tutorial_popup() -> void:
	if tutorial_popup:
		tutorial_popup.queue_free()
		tutorial_popup = null
	step_label = null
	progress_label = null
	progress_container = null
	back_button = null
	next_button = null
	progress_rectangles.clear()

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
	Global.reset_game()

var steps = [
	{
		# Step 1 – Starting a Game
		'en': 'Multiplayer Moonridge Rummy can be played either solo against AI opponents or online with friends on any platform — with or without extra bots.

To play solo, click “Host New Game” on the main menu and add one or more bots to your lobby.

To play with friends, it works best if everyone’s on the same Wi‑Fi or hotspot. One player hosts, and the others join when the game appears in their lobby list.

If it doesn’t show up automatically, the host can share their local IP (it’s shown in the lobby) so others can type it in and tap “Join Game”.
',
		'de': 'Mehrspieler‑Moonridge Rummy kannst du entweder alleine gegen Computergegner oder online mit Freunden spielen – mit oder ohne zusätzliche Bots.
Um solo zu spielen, klicke im Hauptmenü auf „Neues Spiel hosten“ und füge einen oder mehrere Bots zu deiner Lobby hinzu.
Zum Spielen mit Freunden klappt es am besten, wenn alle im selben WLAN oder Hotspot sind. Ein Spieler hostet, und die anderen können beitreten, sobald das Spiel in ihrer Lobby‑Liste erscheint.
Falls es nicht automatisch angezeigt wird, kann der Gastgeber seine lokale IP‑Adresse (in der Lobby zu sehen) an andere weitergeben. Diese geben die IP‑Adresse ein und klicken dann auf „Spiel beitreten“.
',
		'ja': 'マルチプレイ対応の Moonridge Rummy は、AI 相手にひとりで遊ぶことも、プラットフォームを問わず友だちとオンラインで遊ぶこともできます。ボットを追加しても追加しなくても OK です。

ひとりで遊ぶときは、メインメニューで "Host New Game" を押して、ロビーにボットを1体以上追加しましょう。

友だちと遊ぶなら、全員が同じ Wi-Fi やテザリングにつながっているとスムーズです。誰かがホストになり、ほかのメンバーはロビー一覧にゲームが表示されたら参加します。

自動で表示されない場合は、ホストがロビーに表示されているローカル IP を共有してください。ほかの人はその IP を入力して "Join Game" をタップすれば参加できます。
',
		'fr': 'Multiplayer Moonridge Rummy se joue soit en solo contre l\'IA, soit en ligne avec tes amis sur n\'importe quelle plateforme, avec ou sans bots supplémentaires.

Pour jouer seul, clique sur "Host New Game" dans le menu principal et ajoute un ou plusieurs bots à ton salon.

Pour jouer avec des amis, c\'est plus simple si tout le monde est sur le même Wi-Fi ou hotspot. Un joueur héberge, les autres rejoignent dès que la partie apparaît dans leur liste.

Si elle n\'apparaît pas, l\'hôte peut partager son IP locale (affichée dans le salon) afin que les autres la saisissent puis appuient sur "Join Game".
',
		'it': 'Multiplayer Moonridge Rummy può essere giocato da solo contro l\'IA oppure online con gli amici su qualsiasi piattaforma, con o senza bot extra.

Per una partita in solitaria, premi "Host New Game" dal menu principale e aggiungi uno o più bot alla lobby.

Per giocare con gli amici conviene che tutti siano sulla stessa rete Wi-Fi o hotspot. Uno fa da host e gli altri si uniscono quando vedono la partita nella loro lista.

Se non compare in automatico, l\'host può condividere il proprio IP locale (lo vedi nella lobby) così gli altri lo inseriscono e toccano "Join Game".
',
		'es': 'Multiplayer Moonridge Rummy se puede jugar solo contra la IA o en línea con tus amigos en cualquier plataforma, con o sin bots adicionales.

Para jugar solo, toca "Host New Game" en el menú principal y agrega uno o más bots a tu lobby.

Para jugar con amigos, lo ideal es que todos estén en la misma red Wi-Fi o punto de acceso. Una persona crea la partida y el resto se une cuando aparece en su lista.

Si no se muestra automáticamente, el anfitrión puede compartir su IP local (sale en la lobby) para que los demás la escriban y pulsen "Join Game".
',
		'pt': 'Multiplayer Moonridge Rummy pode ser jogado sozinho contra a IA ou online com os amigos em qualquer plataforma, com ou sem bots extras.

Para jogar sozinho, toque em "Host New Game" no menu principal e adicione um ou mais bots ao lobby.

Para jogar com amigos, ajuda se todo mundo estiver na mesma rede Wi-Fi ou hotspot. Uma pessoa hospeda e o restante entra quando a partida aparecer na lista.

Se não aparecer automaticamente, o anfitrião pode compartilhar o IP local (mostrado no lobby) para que os outros digitem e toquem em "Join Game".
',
		'ru': 'Multiplayer Moonridge Rummy можно играть в одиночку против ИИ или онлайн с друзьями на любой платформе — с дополнительными ботами или без них.

Чтобы сыграть соло, нажми "Host New Game" в главном меню и добавь в лобби одного или нескольких ботов.

Для игры с друзьями лучше всего, чтобы все были в одной сети Wi-Fi или точке доступа. Один игрок хостит, остальные подключаются, когда игра появляется в их списке.

Если игра не показалась автоматически, хост может поделиться своим локальным IP (он виден в лобби), чтобы остальные ввели его и нажали "Join Game".
',
		'zh': 'Multiplayer Moonridge Rummy 可以单人对战 AI，也可以跨平台和朋友在线同乐，可选是否加入更多机器人。

单人游玩时，在主菜单点“Host New Game”，再往大厅里加上一个或多个机器人。

和朋友一起玩时，大家连在同一个 Wi-Fi 或热点会最顺。有人负责开房，其他人在大厅列表看到游戏后就能加入。

如果列表里没有自动出现，房主可以把大厅里显示的本地 IP 告诉大家，其他人输入后点“Join Game”即可。
',
		'ar': 'يمكنك لعب Moonridge Rummy الجماعية بمفردك ضد خصوم ذكاء اصطناعي، أو عبر الإنترنت مع أصدقائك على أي منصة، مع أو بدون روبوتات إضافية.

للعب منفردًا، اضغط على "Host New Game" في القائمة الرئيسية وأضف بوتًا واحدًا أو أكثر إلى الردهة.

للعب مع الأصدقاء، من الأفضل أن يكون الجميع على نفس شبكة الـWi-Fi أو نقطة الاتصال. أحدهم يستضيف، والبقية ينضمون عندما تظهر اللعبة في قائمة الردهة لديهم.

إذا لم تظهر اللعبة تلقائيًا، يمكن للمضيف مشاركة عنوان الـIP المحلي (المعروض في الردهة) ليكتبه الآخرون ثم يضغطوا "Join Game".
',
		'ko': '멀티플레이 Moonridge Rummy는 AI 봇과 1인으로 즐길 수도 있고, 어떤 플랫폼이든 친구들과 온라인으로 즐길 수도 있어요. 봇을 더 넣어도 되고 안 넣어도 돼요.

혼자 놀고 싶다면 메인 메뉴에서 "Host New Game"을 눌러 로비에 봇을 한 명 이상 추가하세요.

친구들과 할 때는 모두가 같은 Wi-Fi나 핫스팟에 있으면 가장 편해요. 한 명이 호스트를 열면, 나머지는 로비 목록에 게임이 뜨는 순간 참가하면 됩니다.

자동으로 안 뜬다면, 호스트가 로비에 표시된 로컬 IP를 공유하면 돼요. 다른 친구들은 그 주소를 입력하고 "Join Game"을 눌러서 합류하세요.
',
		'he': 'את Moonridge Rummy מרובי־השחקנים אפשר לשחק לבד מול בוטים או עם חברים אונליין בכל פלטפורמה, עם או בלי בוטים נוספים.

למשחק סולו, לחץ על "Host New Game" בתפריט הראשי והוסף אחד או יותר בוטים ללובי.

למשחק עם חברים, הכי נוח שכולם יהיו על אותה רשת Wi-Fi או הוטספוט. אחד מאחסן, והשאר נכנסים כשהמשחק מופיע ברשימת הלובי שלהם.

אם זה לא מופיע אוטומטית, המארח יכול לשתף את כתובת ה-IP המקומית (שמופיעה בלובי), והאחרים מקלידים אותה ולוחצים על "Join Game".
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
		'ja': 'プレイヤーが参加している間、ホストは "Add Bot" を押したり、プレイヤーのアイコンを "Remove" にドラッグしたりして、ボットやプレイヤーを追加・削除できます。

全員の準備が整ったら、ホストが "Start Game" をクリックすればスタート！
',
		'fr': 'Pendant que les joueurs rejoignent la partie, l\'hôte peut ajouter ou retirer des bots (ou des joueurs) en cliquant sur "Add Bot" ou en faisant glisser une icône vers "Remove".

Quand tout le monde est prêt dans le lobby, l\'hôte clique sur "Start Game" pour lancer la partie !
',
		'it': 'Mentre i giocatori stanno entrando, l\'host può aggiungere o rimuovere bot (o giocatori) cliccando "Add Bot" oppure trascinando l\'icona di un giocatore su "Remove".

Quando tutti sono pronti nella lobby, l\'host preme "Start Game" e si parte!
',
		'es': 'Mientras los jugadores se van uniendo, el anfitrión puede añadir o quitar bots (o jugadores) tocando "Add Bot" o arrastrando el icono de un jugador a "Remove".

Cuando todos estén listos en la sala, el anfitrión toca "Start Game" para empezar.
',
		'pt': 'Enquanto os jogadores estão entrando, o anfitrião pode adicionar ou remover bots (ou jogadores) tocando "Add Bot" ou arrastando o ícone de um jogador até "Remove".

Quando todo mundo estiver pronto no lobby, o anfitrião toca "Start Game" para começar!
',
		'ru': 'Пока игроки подключаются, хост может добавлять или удалять ботов (или игроков), нажимая "Add Bot" либо перетаскивая значок игрока на "Remove".

Когда все готовы в лобби, хост нажимает "Start Game" — и поехали!
',
		'zh': '玩家陆续加入时，房主可以点“Add Bot”来增删机器人（或把玩家头像拖到“Remove”来移除玩家）。

等大厅里的人都准备好后，房主点一下“Start Game”就能开局！
',
		'ar': 'بينما ينضم اللاعبون، يمكن للمضيف إضافة أو إزالة بوتات (أو لاعبين) بالضغط على "Add Bot" أو بسحب أيقونة لاعب إلى "Remove".

عندما يكون الجميع جاهزًا في الردهة، يضغط المضيف "Start Game" ونبدأ!
',
		'ko': '플레이어들이 들어오는 동안, 호스트는 "Add Bot"을 눌러 봇을 추가하거나, 플레이어 아이콘을 "Remove"로 끌어다 제거할 수 있어요.

모두 준비가 끝나면 호스트가 "Start Game"을 눌러서 바로 시작!
',
		'he': 'בזמן שהשחקנים מצטרפים, המארח יכול להוסיף או להסיר בוטים (או שחקנים) בלחיצה על "Add Bot" או על ידי גרירת האווטאר של השחקן אל "Remove".

כשכולם מוכנים בלובי, המארח לוחץ על "Start Game" ויוצאים לדרך!
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
		'ja': '各ラウンドには勝つために満たすべき役の条件があります。

ラウンド画面の上部に、本がいくつ（同じランク3枚以上）と、ストレートがいくつ（同じスート4枚以上）必要かが表示されます。

ラウンド1〜6では、自分の条件を満たすまでは他のプレイヤーの場にカードを出せません。

ラウンド7は特別で、手札をすべて出し切らないと勝てません！
',
		'fr': 'Chaque manche a ses propres exigences d\'assemblage pour pouvoir gagner.

En haut de l\'écran de la manche, tu vois combien de livres (groupes de 3 cartes ou plus de même valeur) et de suites (séquences de 4 cartes ou plus de la même couleur) il faut.

Dans les manches 1 à 6, tu dois valider tes propres combinaisons avant de pouvoir poser sur celles des autres.

La manche 7 est spéciale : il faut vider complètement ta main pour gagner !
',
		'it': 'Ogni round ha requisiti di calata specifici che devi soddisfare per vincere.

In alto nello schermo del round trovi quanti libri (gruppi di 3+ carte dello stesso valore) e quante scale (sequenze di 4+ carte dello stesso seme) servono.

Nei round 1-6 devi completare i tuoi requisiti prima di poter appoggiare carte sulle combinazioni altrui.

Il round 7 è speciale: devi liberarti di tutta la mano per vincere!
',
		'es': 'Cada ronda tiene sus propios requisitos de bajada que debes cumplir para ganar.

En la parte superior de la pantalla verás cuántos tríos (grupos de 3+ cartas del mismo valor) y cuántas escaleras (secuencias de 4+ cartas del mismo palo) hacen falta.

En las rondas 1 a 6 tienes que cumplir tus propias bajadas antes de poder engancharte a las de otros.

La ronda 7 es especial: ¡tienes que quedarte sin cartas en la mano para ganar!
',
		'pt': 'Cada rodada tem requisitos de meld próprios que você precisa cumprir para vencer.

No topo da tela da rodada aparece quantos livros (grupos de 3+ cartas do mesmo valor) e quantas sequências (4+ cartas do mesmo naipe) são necessários.

Nas rodadas 1 a 6, você precisa fechar suas próprias combinações antes de poder jogar em melds de outros jogadores.

A rodada 7 é especial: você precisa esvaziar totalmente a mão para ganhar!
',
		'ru': 'В каждом раунде свои условия для раскладок, которые нужно выполнить, чтобы победить.

В верхней части экрана показано, сколько "книг" (групп по 3+ карты одного достоинства) и "рядов" (последовательностей из 4+ карт одной масти) требуется.

В раундах 1–6 сначала собери свои собственные комбинации, и только потом сможешь добавлять карты к чужим.

Раунд 7 особенный — чтобы выиграть, нужно полностью избавиться от карт в руке!
',
		'zh': '每一回合都有自己必须完成的组牌条件才能获胜。

在回合界面的顶部会显示需要多少个“书”（3 张以上同点数）和多少个“顺子”（4 张以上同花）的组合。

在第 1 到 6 回合里，你得先完成自己的要求，才能往别人已经下的牌堆里加牌。

第 7 回合很特别——必须把整手牌全部打光才能赢！
',
		'ar': 'كل جولة لها متطلبات طرح خاصة يجب تحقيقها للفوز.

في أعلى شاشة الجولة سترى عدد الكتب (مجموعات من 3 أوراق أو أكثر بنفس القيمة) وعدد السلاسل (متتاليات من 4 أوراق أو أكثر بنفس اللون) المطلوبة.

في الجولات 1‑6 يجب أن تحقق متطلباتك الخاصة قبل أن تضيف إلى مجموعات اللاعبين الآخرين.

الجولة 7 مميزة — عليك إنهاء يدك بالكامل بدون أي ورقة لتفوز!
',
		'ko': '각 라운드마다 승리하려면 채워야 하는 멜드 조건이 있어요.

라운드 화면 위쪽에는 필요한 북(같은 숫자 3장 이상)과 런(같은 무늬 4장 이상)이 몇 개인지 보여 줘요.

1~6라운드에서는 내 조건

7라운드는 특별해요 — 손패를 전부 털어야 승리합니다!
',
		'he': 'לכל סיבוב יש דרישות קלפים משלו שצריך להשלים כדי לנצח.

בחלק העליון של מסך הסיבוב תראה כמה "ספרים" (שלשות או יותר באותו ערך) וכמה "ריצות" (רצפים של ארבעה קלפים או יותר באותו הצבע) צריך.

בסיבובים 1‑6 אתה חייב להשלים קודם את הדרישות שלך לפני שתוסיף לקלפים של אחרים.

סיבוב 7 מיוחד — צריך להתרוקן מכל הקלפים כדי לנצח!
',
	},
	{
		# Step 4 – Game Area
		'en': 'The game area has two main parts.
The top shows every player’s public melds, while the bottom is private to you. You can move and arrange your cards any way you like.

On the left are meld areas — drag cards there to build your melds. Once a card is in a meld area, you can’t accidentally discard it by mistake during your turn by tapping on it.

Cards in the lower-right can still be tapped to discard them during your turn.
',
		'de': 'Das Spielfeld hat zwei Hauptbereiche.
Oben siehst du die öffentlichen Meldungen aller Spieler, unten deinen privaten Bereich. Dort kannst du deine Karten beliebig verschieben und anordnen.

Links befinden sich die Ablageflächen – ziehe Karten dorthin, um deine Meldungen zu bilden. Karten, die dort liegen, können nicht versehentlich angetippt werden.

Karten im unteren rechten Bereich kannst du an‑tippen, um sie während deines Zugs abzuwerfen.
',
		'ja': 'フィールドは大きく2つの領域に分かれています。
上段には全プレイヤーの公開メルドが表示され、下段は自分専用エリアです。カードは好きなように並べ替えできます。

左側にはメルドエリアがあり、そこへドラッグして役を作ります。メルドエリアに置いたカードは、自分のターンに誤って捨ててしまうことはありません。

右下のカードは、自分のターン中にタップすれば捨て札にできます。
',
		'fr': 'Le plateau de jeu se divise en deux zones.
En haut s\'affichent les melds publics de tout le monde, en bas c\'est ton espace privé où tu peux bouger tes cartes comme tu veux.

À gauche se trouvent les zones de meld — fais glisser tes cartes dessus pour construire tes combinaisons. Une carte posée là ne peut plus partir à la défausse par erreur pendant ton tour.

Les cartes en bas à droite peuvent toujours être tapées pour les défausser quand c\'est ton tour.
',
		'it': 'L\'area di gioco è divisa in due sezioni principali.
In alto vedi i meld pubblici di tutti, mentre in basso c\'è la tua zona privata dove puoi ordinare le carte come preferisci.

A sinistra trovi le aree meld: trascina lì le carte per costruire le combinazioni. Una volta piazzata, una carta in quell\'area non può essere scartata per sbaglio durante il tuo turno.

Le carte nell\'angolo in basso a destra possono ancora essere toccate per scartarle durante il turno.
',
		'es': 'El área de juego tiene dos partes principales.
Arriba ves las bajadas públicas de todos los jugadores; abajo está tu zona privada, donde puedes mover tus cartas como quieras.

A la izquierda están las zonas de meld: arrastra cartas allí para armar tus combinaciones. Una carta colocada allí ya no se puede descartar por accidente durante tu turno.

Las cartas de la esquina inferior derecha siguen pudiendo tocarse para descartarlas cuando te toca.
',
		'pt': 'A área de jogo tem duas partes principais.
No topo ficam os melds públicos de todos, e embaixo está a sua área privada para organizar as cartas do jeito que quiser.

À esquerda há as zonas de meld — arraste as cartas para lá para montar suas combinações. Depois que uma carta está nessa zona, você não corre o risco de descartá-la sem querer no seu turno.

As cartas no canto inferior direito ainda podem ser tocadas para descartá-las no seu turno.
',
		'ru': 'Игровое поле состоит из двух частей.
Сверху показаны открытые раскладки всех игроков, а снизу — твоя личная зона, где можно свободно раскладывать карты.

Слева располагаются зоны для раскладок: перетаскивай туда карты, чтобы собирать комбинации. Карты, лежащие там, нельзя случайно сбросить во время своего хода.

Карты в правом нижнем углу всё ещё можно тапнуть, чтобы сбросить их в свой ход.
',
		'zh': '游戏界面主要分成两块。
上方显示所有玩家的公开合牌，下方是你的私有区域，可以随意整理手牌。

左侧是合牌区，把牌拖过去即可组合。放在合牌区的牌，在你的回合中不会被误点到弃掉。

右下角的牌仍然可以在你的回合轻点来弃牌。
',
	},
	{
		# Step 5 – Player’s Turn
		'en': 'When it’s your turn, your player icon at the top will glow with a pulsing orange border.

First, draw a card — tap the left pile to draw from stock, or the right pile to take the top discard.

Then, try to meet the current round’s requirements. Drag cards into the meld zones until they sparkle. When you’re ready, tap the “Meld!” icon to lay down your hand.
',
		'de': 'Wenn du an der Reihe bist, leuchtet dein Spielersymbol oben mit einem orangefarbenen, pulsierenden Rahmen.

Ziehe zuerst eine Karte – tippe auf den linken Stapel, um vom Nachziehstapel zu ziehen, oder auf den rechten, um die oberste Karte vom Ablagestapel zu nehmen.

Versuche dann, die Anforderungen der Runde zu erfüllen. Ziehe Karten in die Ablageflächen, bis sie funkeln. Wenn du bereit bist, tippe auf „Melden!“, um deine Hand auszulegen.
',
		'ja': '自分の番になると、画面上部のプレイヤーアイコンがオレンジの枠でふわっと光ります。

まずはカードを1枚引きましょう。左の山をタップすると山札、右の山をタップすると捨て札の一番上が取れます。

そのあと、今のラウンドの条件を満たせるようにカードをメルドゾーンへドラッグ。きらっと光ったら準備OK。用意ができたら「Meld!」アイコンをタップして手札を場に出します。
',
		'fr': 'Quand vient ton tour, ton icône en haut s\'illumine avec un contour orange pulsé.

Commence par piocher une carte : tape sur la pile de gauche pour piocher dans la pioche, ou sur celle de droite pour prendre la défausse.

Ensuite essaye de remplir les exigences de la manche. Fais glisser tes cartes dans les zones de meld jusqu\'à ce qu\'elles scintillent. Quand tu es prêt, tape sur l\'icône "Meld!" pour poser ta main.
',
		'it': 'Quando è il tuo turno, la tua icona in alto lampeggia con un bordo arancione.

Per prima cosa pesca una carta: tocca il mazzo a sinistra per pescare dal tallone oppure quello a destra per prendere la carta scartata.

Poi cerca di soddisfare i requisiti del round. Trascina le carte nelle zone meld finché non brillano. Quando sei pronto, tocca l\'icona "Meld!" per calare la mano.
',
		'es': 'Cuando te toca, tu icono arriba brilla con un borde naranja pulsante.

Primero roba una carta: toca el montón izquierdo para robar del mazo, o el derecho para tomar la carta de descarte.

Luego intenta cumplir los requisitos de la ronda. Arrastra cartas a las zonas de meld hasta que brillen. Cuando estés listo, toca el icono "Meld!" para bajar tu mano.
',
		'pt': 'Quando é a sua vez, seu ícone no topo fica com uma borda laranja pulsante.

Primeiro compre uma carta: toque no monte da esquerda para comprar do baralho ou no da direita para pegar a carta do descarte.

Depois tente cumprir os requisitos da rodada. Arraste as cartas para as zonas de meld até elas brilharem. Quando estiver pronto, toque no ícone "Meld!" para baixar sua mão.
',
		'ru': 'Когда ход переходит к тебе, твой значок наверху подсвечивается пульсирующей оранжевой рамкой.

Сначала возьми карту: тапни левую стопку, чтобы взять из колоды, или правую, чтобы забрать верхнюю карту сброса.

Затем постарайся выполнить требования раунда. Перетаскивай карты в зоны раскладок, пока они не начнут сиять. Как только готов, нажимай на значок "Meld!" и выкладывай руку.
',
		'zh': '轮到你时，顶部的头像会亮起一圈橙色光晕。

先抽一张牌：点左边的牌堆从库存抓牌，或点右边的牌堆拿走顶牌。

接着尝试完成这一回合的要求，把牌拖到合牌区域，直到它们闪烁。准备好了就点“Meld!”图标，把手牌打出去。
',
		'ar': 'عندما يحين دورك سيضيء رمز اللاعب الخاص بك في الأعلى بإطار برتقالي نابض.

أولًا اسحب ورقة — اضغط على الكومة اليسرى للسحب من الرزمة، أو على الكومة اليمنى لأخذ أعلى ورقة من الرمي.

بعدها حاول تحقيق متطلبات الجولة الحالية. اسحب الأوراق إلى مناطق الطرح حتى تلمع. عندما تكون جاهزًا اضغط على أيقونة "Meld!" لوضع يدك على الطاولة.
',
		'ko': '내 차례가 되면, 화면 위 플레이어 아이콘에 주황색 테두리가 반짝여요.

먼저 카드를 한 장 뽑으세요. 왼쪽 더미를 탭하면 덱에서, 오른쪽 더미를 탭하면 버린 카드 맨 위를 가져옵니다.

그다음 이번 라운드 조건을 맞춰 보세요. 카드가 반짝일 때까지 멜드 존으로 끌어다 놓고, 준비가 되면 "Meld!" 아이콘을 눌러 손패를 내려놓아요.
',
		'he': 'כשהתור שלך מגיע, האווטאר שלך למעלה זוהר במסגרת כתומה ומחויכת.

קודם שולפים קלף — הקש על הערימה השמאלית כדי לשלוף מהחפיסה, או על הימנית כדי לקחת את הקלף העליון מהשלכה.

אחר כך נסה לעמוד בדרישות של הסיבוב. גרור קלפים לאזורי המלט עד שהם מנצנצים. כשאתה מוכן, לחץ על "Meld!" כדי להניח את היד.
',
	},
		{
		# Step 6 – After melding
		'en': 'After melding, keep adding cards to your melds or to others’. Tap “Meld!” again to confirm.

In rounds 1–6, end your turn by tapping a card in the lower-right to discard it. If you’ve got no cards left, you’ve won the round!

In round 7, the first person to meld must finish their hand completely and can’t add to others’ melds.
',
		'de': 'Danach kannst du weiter Karten an deine eigenen oder die Meldungen anderer Spieler anlegen. Tippe erneut auf „Melden!“, um das zu bestätigen.

In den Runden 1–6 beendest du deinen Zug, indem du im unteren rechten Bereich auf eine Karte tippst, um sie abzuwerfen. Wenn du danach keine Karten mehr auf der Hand hast, hast du die Runde gewonnen!

In Runde 7 muss der erste Spieler alle seine Karten ablegen und darf danach nicht mehr an andere Meldungen anlegen.
',
		'ja': 'メルドしたあとも、自分や他プレイヤーのメルドにカードをどんどん追加できます。確定させるときはもう一度「Meld!」をタップ。

ラウンド1〜6では、右下のカードをタップして捨て札にし、ターンを終わらせます。手札がゼロになればそのラウンドの勝者です！

ラウンド7では、最初にメルドしたプレイヤーは手札を完全に出し切らなければならず、他人のメルドに追加することもできません。
',
		'fr': 'Après avoir meldé, continue d\'ajouter des cartes sur tes melds ou ceux des autres. Tape à nouveau sur "Meld!" pour confirmer.

Dans les manches 1 à 6, termine ton tour en tapant une carte en bas à droite pour la défausser. Si tu restes sans cartes, tu gagnes la manche !

À la manche 7, le premier à meld doit finir sa main complètement et ne peut plus ajouter sur les melds adverses.
',
		'it': 'Dopo aver calato, puoi continuare ad aggiungere carte ai tuoi meld o a quelli degli altri. Tocca di nuovo "Meld!" per confermare.

Nei round 1-6 chiudi il turno toccando una carta in basso a destra per scartarla. Se resti senza carte, hai vinto il round!

Nel round 7 chi cala per primo deve liberarsi di tutta la mano e non può attaccarsi alle combinazioni altrui.
',
		'es': 'Después de bajar tus cartas, sigue sumando a tus melds o a los de los demás. Toca otra vez "Meld!" para confirmar.

En las rondas 1 a 6 termina tu turno tocando una carta en la esquina inferior derecha para descartarla. ¡Si te quedas sin cartas, ganas la ronda!

En la ronda 7, quien baja primero debe acabar la mano completa y no puede engancharse a las bajadas ajenas.
',
		'pt': 'Depois de baixar suas cartas, continue adicionando às suas combinações ou às dos outros. Toque "Meld!" de novo para confirmar.

Nas rodadas 1 a 6, termine o turno tocando uma carta no canto inferior direito para descartá-la. Se ficar sem cartas, você vence a rodada!

Na rodada 7, o primeiro a meldar precisa esvaziar a mão inteira e não pode mais anexar cartas aos melds dos outros.
',
		'ru': 'После выкладки продолжай добавлять карты к своим комбинациям или к чужим. Нажми "Meld!" ещё раз, чтобы подтвердить.

В раундах 1–6 заверши ход, тапнув карту в правом нижнем углу и отправив её в сброс. Если карт не осталось — раунд твой!

В раунде 7 игрок, который meldнул первым, должен полностью разыграть руку и не может добавлять карты к чужим раскладкам.
',
		'zh': '合牌之后，还可以继续往自己的牌堆或别人的牌堆加牌。再点一次“Meld!”来确认。

在第 1～6 回合，点右下角的一张牌把它弃掉，就结束回合。手牌清空就算赢得这一回合！

第 7 回合里，最先合牌的玩家必须把整手牌都打完，不能再往别人牌堆里加牌。
',
		'ar': 'بعد أن تطرح أوراقك، يمكنك الاستمرار في إضافة أوراق إلى مجموعاتك أو إلى مجموعات الآخرين. اضغط "Meld!" مرة ثانية للتأكيد.

في الجولات 1‑6 أنهِ دورك بالضغط على ورقة في الركن السفلي الأيمن لرميها. إذا لم يتبق أي ورق فقد فزت بالجولة!

في الجولة 7 يجب على أول شخص يطرح أن ينهي يده بالكامل ولا يمكنه الإضافة إلى مجموعات الآخرين.
',
		'ko': '멜드를 끝낸 뒤에도 내 멜드나 다른 사람 멜드에 계속 카드를 붙일 수 있어요. 확정하려면 "Meld!"를 한 번 더 눌러 주세요.

1~6라운드에서는 오른쪽 아래 카드 하나를 탭해 버리면 차례가 끝나요. 손패가 0장이라면 그 라운드를 이긴 거예요!

7라운드에서는 먼저 멜드한 사람이 손패를 완전히 털어야 하고, 다른 사람 멜드에 붙일 수 없어요.
',
		'he': 'אחרי שהנחת מלט, אפשר להמשיך להוסיף קלפים למלטים שלך או של אחרים. לחץ שוב על "Meld!" כדי לאשר.

בסיבובים 1‑6 מסיימים את התור בלחיצה על קלף בפינה הימנית־תחתונה כדי להשליך אותו. אם נשארת בלי קלפים – ניצחת בסיבוב!

בסיבוב 7 מי שמניח ראשון חייב לגמור את כל היד ואסור לו להוסיף למלטים של אחרים.
',
	},
	{
		# Step 7 – Scoring
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
		'ja': '各ラウンド終了後は、ホストが「Tally Scores」をタップしてカードを集計し、スコアを更新します。

そのあと「Next Round」を押せば次のラウンドへ。（ラウンド7のあとなら「Final Scores」）

7ラウンドの合計が一番少ない人が優勝！

スコアボードには各ラウンドの点数と最終結果が表示され、3位・2位・1位にはトロフィーも付きます。

終わったら「Main Menu」を押して、いつでも新しいゲームを始めましょう。
',
		'fr': 'Après chaque manche, l\'hôte tape sur "Tally Scores" pour compter toutes les cartes et mettre à jour les scores.

Ensuite, tape sur "Next Round" (ou sur "Final Scores" après la manche 7).

Après les sept manches, le joueur avec le total le plus bas l\'emporte !

Un tableau s\'affiche avec les scores de chaque manche et le résultat final — avec des trophées pour la 3e, 2e et 1re place.

Quand c\'est fini, tape sur "Main Menu" pour revenir et relancer une partie quand tu veux.
',
		'it': 'Dopo ogni round, l\'host tocca "Tally Scores" per sommare tutte le carte e aggiornare i punteggi.

Poi tocca "Next Round" (o "Final Scores" dopo il round 7).

Dopo i sette round, vince chi ha il totale più basso!

Appare un tabellone con i punteggi di ogni round e il risultato finale, completo di trofei per terzo, secondo e primo posto.

Quando hai finito, tocca "Main Menu" per tornare indietro e avviare una nuova partita quando vuoi.
',
		'es': 'Al final de cada ronda, el anfitrión toca "Tally Scores" para sumar las cartas y actualizar los puntos.

Luego toca "Next Round" (o "Final Scores" después de la ronda 7).

Tras las siete rondas, gana quien tenga el total más bajo.

Verás un marcador con los puntos de cada ronda y el resultado final, con trofeos para 3.º, 2.º y 1.º lugar.

Cuando terminen, toca "Main Menu" para volver y arrancar otra partida cuando quieras.
',
		'pt': 'Depois de cada rodada, o anfitrião toca "Tally Scores" para somar as cartas e atualizar os pontos de todo mundo.

Em seguida toque "Next Round" (ou "Final Scores" depois da rodada 7).

Após as sete rodadas, vence quem tiver o menor total!

Um placar aparece com os pontos de cada rodada e o resultado final — incluindo troféus para 3º, 2º e 1º lugar.

Quando terminar, toque "Main Menu" para voltar e iniciar outra partida quando quiser.
',
		'ru': 'После каждой раздачи хост нажимает "Tally Scores", чтобы подсчитать карты и обновить очки игроков.

Затем жми "Next Round" (или "Final Scores" после 7-го раунда).

После всех семи раундов побеждает тот, у кого общий счет минимальный!

Появится таблица с результатами каждого раунда и финальным итогом — с трофеями за 3-е, 2-е и 1-е места.

Когда все закончено, нажми "Main Menu", чтобы вернуться и запустить новую игру в любое время.
',
		'zh': '每回合结束后，房主会点“Tally Scores”把牌面分数相加并更新所有人的积分。

然后点“Next Round”（第 7 回合之后改点“Final Scores”）。

七个回合打完后，总分最低的玩家获胜！

榜单会显示每回合的得分和最终结果，还会给第 3、2、1 名配上奖杯。

结束时点“Main Menu”，随时可以回到主菜单再开一局。
',
		'ar': 'بعد كل جولة يضغط المضيف على "Tally Scores" لحساب كل الأوراق وتحديث نقاط اللاعبين.

بعدها اضغط "Next Round" (أو "Final Scores" بعد الجولة السابعة).

بعد سبع جولات يفوز من لديه أقل مجموع!

ستظهر لوحة نتائج تعرض نقاط كل جولة والنتيجة النهائية، مع كؤوس للمركز الثالث والثاني والأول.

عندما تنتهي، اضغط "Main Menu" للعودة وبدء لعبة جديدة في أي وقت.
',
		'ko': '라운드가 끝날 때마다 호스트가 "Tally Scores"를 눌러 모든 카드를 합산하고 점수를 갱신해요.

그다음 "Next Round"를 누르세요. 7라운드가 끝났다면 "Final Scores"를 누르면 됩니다.

일곱 라운드가 끝났을 때 총점이 제일 낮은 사람이 우승!

라운드별 점수와 최종 결과가 표시되는 점수판이 뜨고, 3등·2등·1등에게 트로피도 붙어요.

다 끝나면 "Main Menu"를 눌러 돌아가고, 언제든 새 게임을 시작하세요.
',
		'he': 'אחרי כל סיבוב המארח לוחץ על "Tally Scores" כדי לסכם את הקלפים ולעדכן את הניקוד של כולם.

אחר כך לוחצים על "Next Round" (או על "Final Scores" אחרי סיבוב 7).

בסוף שבעת הסיבובים מנצח מי שסך הנקודות שלו הנמוך ביותר!

תופיע טבלת ניקוד עם תוצאות כל הסיבובים והגמר — כולל גביעים למקום שלישי, שני וראשון.

כשתסיימו, לחצו על "Main Menu" כדי לחזור ולפתוח משחק חדש מתי שרוצים.
',
	},
	{
		# Step 8 – Extra Buttons and Wrap‑Up
		'en': 'Every round has two helpful buttons.

In the top-left corner, tap the button to change your card back design.

In the top-right corner, tap “?” to open a quick help screen with Moonridge Rummy’s rules.

That’s it — you’re ready to play! Have fun playing Moonridge Rummy solo or with friends, and good luck!
',
		'de': 'Jede Runde hat zwei nützliche Buttons.

Oben links kannst du das Design der Kartenrückseiten ändern.

Oben rechts öffnet das „?“-Symbol eine Hilfe mit den Regeln von Moonridge Rummy.

Und das war’s – du bist bereit zu spielen! Viel Spaß beim Moonridge Rummy, allein oder mit Freunden, und viel Glück!
',
		'ja': '各ラウンドには便利なボタンが2つあります。

左上のボタンを押すとカードの裏面デザインを変えられます。

右上の「?」を押すと Moonridge Rummy のルールをまとめたクイックヘルプが開きます。

これで準備完了！ Moonridge Rummy をひとりでも友だちとでも楽しんで、幸運を祈っています！
',
		'fr': 'Chaque manche a deux boutons bien pratiques.

En haut à gauche, tape sur le bouton pour changer le dos de tes cartes.

En haut à droite, tape sur "?" pour afficher une aide rapide avec les règles de Moonridge Rummy.

Voilà, tu es prêt ! Amuse-toi sur Moonridge Rummy en solo ou avec tes amis, et bonne chance !
',
		'it': 'Ogni round offre due pulsanti utili.

In alto a sinistra puoi toccare il pulsante per cambiare il dorso delle carte.

In alto a destra tocca "?" per aprire un aiuto rapido con le regole di Moonridge Rummy.

E questo è tutto: sei pronto a giocare! Divertiti con Moonridge Rummy da solo o con gli amici, e buona fortuna!
',
		'es': 'Cada ronda tiene dos botones útiles.

En la esquina superior izquierda puedes tocar el botón para cambiar el dorso de las cartas.

En la esquina superior derecha toca "?" para abrir una ayuda rápida con las reglas de Moonridge Rummy.

¡Listo, a jugar! Disfruta Moonridge Rummy solo o con amigos, y mucha suerte.
',
		'pt': 'Cada rodada tem dois botões úteis.

No canto superior esquerdo dá para tocar no botão e trocar o verso das cartas.

No canto superior direito, toque "?" para abrir uma ajuda rápida com as regras do Moonridge Rummy.

É isso aí — pronto para jogar! Aproveite o Moonridge Rummy sozinho ou com os amigos e boa sorte!
',
		'ru': 'В каждом раунде есть два полезных значка.

В левом верхнем углу нажми кнопку, чтобы сменить рубашку карт.

В правом верхнем углу тапни "?", чтобы открыть короткую справку с правилами Moonridge Rummy.

Вот и всё — можно играть! Наслаждайся Moonridge Rummy в одиночку или с друзьями, удачи!
',
		'zh': '每回合都有两个实用的小按钮。

左上角的按钮可以切换牌背样式。

右上角点一下“?”，就能打开 Moonridge Rummy 的快速规则说明。

就这些啦——准备好开玩吧！无论单人还是和朋友一起玩，都祝你好运！
',
		'ar': 'كل جولة فيها زرين مفيدين.

في الزاوية العلوية اليسرى اضغط على الزر لتغيير تصميم ظهر الورق.

في الزاوية العلوية اليمنى اضغط على "?" لفتح شاشة مساعدة سريعة فيها قواعد Moonridge Rummy.

هذا كل شيء — أنت جاهز للعب! استمتع بـ Moonridge Rummy وحدك أو مع الأصدقاء وبالتوفيق!
',
		'ko': '각 라운드마다 유용한 버튼이 두 개 있어요.

왼쪽 위 버튼을 누르면 카드 뒷면 디자인을 바꿀 수 있고,

오른쪽 위의 "?"를 누르면 Moonridge Rummy 규칙을 빠르게 볼 수 있는 도움말이 열려요.

이제 준비 완료! 혼자든 친구들과든 Moonridge Rummy를 마음껏 즐기고 행운을 빌어요!
',
		'he': 'בכל סיבוב מחכים לך שני כפתורים שימושיים.

בפינה השמאלית־עליונה יש כפתור שמחליף את עיצוב גב הקלפים.

בפינה הימנית־עליונה הקשה על "?" תפתח מסך עזרה קצר עם חוקי Moonridge Rummy.

וזהו — מוכנים לשחק! תיהנו מ‑Moonridge Rummy לבד או עם חברים, ובהצלחה!
',
	},
]
