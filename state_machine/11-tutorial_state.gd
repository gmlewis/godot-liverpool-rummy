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
		texture_path = "res://svgs/main-menu-de.svg"
	else:
		texture_path = "res://svgs/main-menu-en.svg"

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
		'ja': 'マルチプレイヤー対応の Moonridge Rummy は、AI 相手にひとりで遊ぶことも、プラットフォームを問わず友だちとオンラインで遊ぶこともできます。ボットを追加しても追加しなくても OK です。

ひとりで遊ぶときは、メインメニューで「新しいゲームをホスト」を押して、ロビーにボットを1体以上追加しましょう。

友だちと遊ぶなら、全員が同じ Wi-Fi やテザリングにつながっているとスムーズです。誰かがホストになり、ほかのメンバーはロビー一覧にゲームが表示されたら参加します。

自動で表示されない場合は、ホストがロビーに表示されているローカル IP を共有してください。ほかの人はその IP を入力して「ゲームに参加」をタップすれば参加できます。
',
		'fr': 'Le Moonridge Rummy multijoueur se joue soit en solo contre l\'IA, soit en ligne avec tes amis sur n\'importe quelle plateforme, avec ou sans bots supplémentaires.

Pour jouer seul, clique sur « Héberger une nouvelle partie » dans le menu principal et ajoute un ou plusieurs bots à ton salon.

Pour jouer avec des amis, c\'est plus simple si tout le monde est sur le même Wi-Fi ou hotspot. Un joueur héberge, les autres rejoignent dès que la partie apparaît dans leur liste.

Si elle n\'apparaît pas, l\'hôte peut partager son IP locale (affichée dans le salon) afin que les autres la saisissent puis appuient sur « Rejoindre la partie ».
',
		'it': 'Il Moonridge Rummy multigiocatore può essere giocato da solo contro l\'IA oppure online con gli amici su qualsiasi piattaforma, con o senza bot extra.

Per una partita in solitaria, premi « Ospita Nuova Partita » dal menu principale e aggiungi uno o più bot alla lobby.

Per giocare con gli amici conviene che tutti siano sulla stessa rete Wi-Fi o hotspot. Uno fa da host e gli altri si uniscono quando vedono la partita nella loro lista.

Se non compare in automatico, l\'host può condividere il proprio IP locale (lo vedi nella lobby) così gli altri lo inseriscono e toccano « Unisciti alla Partita ».
',
		'es': 'El Moonridge Rummy multijugador se puede jugar solo contra la IA o en línea con tus amigos en cualquier plataforma, con o sin bots adicionales.

Para jugar solo, toca « Crear nueva partida » en el menú principal y agrega uno o más bots a tu lobby.

Para jugar con amigos, lo ideal es que todos estén en la misma red Wi-Fi o punto de acceso. Una persona crea la partida y el resto se une cuando aparece en su lista.

Si no se muestra automáticamente, el anfitrión puede compartir su IP local (sale en la lobby) para que los demás la escriban y pulsen « Unirse a la partida ».
',
		'pt': 'O Moonridge Rummy multijogador pode ser jogado sozinho contra a IA ou online com os amigos em qualquer plataforma, com ou sem bots extras.

Para jogar sozinho, toque em « Hospedar Novo Jogo » no menu principal e adicione um ou mais bots ao lobby.

Para jogar com amigos, ajuda se todo mundo estiver na mesma rede Wi-Fi ou hotspot. Uma pessoa hospeda e o restante entra quando a partida aparecer na lista.

Se não aparecer automaticamente, o anfitrião pode compartilhar o IP local (mostrado no lobby) para que os outros digitem e toquem em « Entrar no Jogo ».
',
		'ru': 'Многопользовательский Moonridge Rummy можно играть в одиночку против ИИ или онлайн с друзьями на любой платформе — с дополнительными ботами или без них.

Чтобы сыграть соло, нажми « Создать новую игру » в главном меню и добавь в лобби одного или нескольких ботов.

Для игры с друзьями лучше всего, чтобы все были в одной сети Wi-Fi или точке доступа. Один игрок хостит, остальные подключаются, когда игра появляется в их списке.

Если игра не показалась автоматически, хост может поделиться своим локальным IP (он виден в лобби), чтобы остальные ввели его и нажали « Присоединиться к игре ».
',
		'zh-Hans': '多人 Moonridge Rummy 可以单人对战 AI，也可以跨平台和朋友在线同乐，可选是否加入更多机器人。

单人游玩时，在主菜单点“主持新游戏”，再往大厅里加上一个或多个机器人。

和朋友一起玩时，大家连在同一个 Wi-Fi 或热点会最顺。有人负责开房，其他人在大厅列表看到游戏后就能加入。

如果列表里没有自动出现，房主可以把大厅里显示的本地 IP 告诉大家，其他人输入后点“加入游戏”即可。
',
		'zh-Hant': '多人 Moonridge Rummy 可以單人對戰 AI，也可以跨平台和朋友線上同樂，可選是否加入更多機器人。

單人遊玩時，在主選單點「主持新遊戲」，再往大廳裡加上一個或多個機器人。

和朋友一起玩時，大家連在同一個 Wi-Fi 或熱點會最順。有人負責開房，其他人在大廳列表看到遊戲後就能加入。

如果列表裡沒有自動出現，房主可以把大廳裡顯示的本地 IP 告訴大家，其他人輸入後點「加入遊戲」即可。
',
		'ar': 'يمكنك لعب Moonridge Rummy الجماعية بمفردك ضد خصوم ذكاء اصطناعي، أو عبر الإنترنت مع أصدقائك على أي منصة، مع أو بدون روبوتات إضافية.

للعب منفردًا، اضغط على « استضافة لعبة جديدة » في القائمة الرئيسية وأضف بوتًا واحدًا أو أكثر إلى الردهة.

للعب مع الأصدقاء، من الأفضل أن يكون الجميع على نفس شبكة الـWi-Fi أو نقطة الاتصال. أحدهم يستضيف، والبقية ينضمون عندما تظهر اللعبة في قائمة الردهة لديهم.

إذا لم تظهر اللعبة تلقائيًا، يمكن للمضيف مشاركة عنوان الـIP المحلي (المعروض في الردهة) ليكتبه الآخرون ثم يضغطوا « الانضمام للعبة ».
',
		'ko': '멀티플레이어 Moonridge Rummy는 AI 봇과 1인으로 즐길 수도 있고, 어떤 플랫폼이든 친구들과 온라인으로 즐길 수도 있어요. 봇을 더 넣어도 되고 안 넣어도 돼요.

혼자 놀고 싶다면 메인 메뉴에서 « 새 게임 호스트 »를 눌러 로비에 봇을 한 명 이상 추가하세요.

친구들과 할 때는 모두가 같은 Wi-Fi나 핫스팟에 있으면 가장 편해요. 한 명이 호스트를 열면, 나머지는 로비 목록에 게임이 뜨는 순간 참가하면 됩니다.

자동으로 안 뜬다면, 호스트가 로비에 표시된 로컬 IP를 공유하면 돼요. 다른 친구들은 그 주소를 입력하고 « 게임 참가 »를 눌러서 합류하세요.
',
		'he': 'את Moonridge Rummy מרובה־המשתתפים אפשר לשחק לבד מול בוטים או עם חברים אונליין בכל פלטפורמה, עם או בלי בוטים נוספים.

למשחק סולו, לחץ על « אירוח משחק חדש » בתפריט הראשי והוסף אחד או יותר בוטים ללובי.

למשחק עם חברים, הכי נוח שכולם יהיו על אותה רשת Wi-Fi או הוטספוט. אחד מאחסן, והשאר נכנסים כשהמשחק מופיע ברשימת הלובי שלהם.

אם זה לא מופיע אוטומטית, המארח יכול לשתף את כתובת ה-IP המקומית (שמופיעה בלובי), והאחרים מקלידים אותה ולוחצים על « הצטרף למשחק ».
',
		'hi': 'मल्टीप्लेयर मूनरिज रम्मी को अकेले AI विरोधियों के खिलाफ या दोस्तों के साथ ऑनलाइन किसी भी प्लेटफॉर्म पर खेला जा सकता है — अतिरिक्त बॉट्स के साथ या बिना।

अकेले खेलने के लिए, मुख्य मेनू पर "नई गेम होस्ट करें" पर क्लिक करें और अपनी लॉबी में एक या अधिक बॉट जोड़ें।

दोस्तों के साथ खेलने के लिए, यह सबसे अच्छा काम करता है यदि सभी एक ही वाई-फाई या हॉटस्पॉट पर हों। एक खिलाड़ी होस्ट करता है, और दूसरे तब शामिल होते हैं जब गेम उनकी लॉबी सूची में दिखाई देता है।

यदि यह स्वचालित रूप से दिखाई नहीं देता है, तो होस्ट अपना स्थानीय आईपी (यह लॉबी में दिखाया गया है) साझा कर सकता है ताकि अन्य लोग इसे टाइप कर सकें और "गेम में शामिल हों" पर टैप कर सकें।
',
		'id': 'Multiplayer Moonridge Rummy dapat dimainkan sendiri melawan lawan AI atau online dengan teman di platform apa pun — dengan atau tanpa bot tambahan.

Untuk bermain solo, klik "Host New Game" di menu utama dan tambahkan satu atau lebih bot ke lobi Anda.

Untuk bermain dengan teman, paling baik jika semua orang berada di Wi-Fi atau hotspot yang sama. Satu pemain menjadi tuan rumah, dan yang lain bergabung ketika game muncul di daftar lobi mereka.

Jika tidak muncul secara otomatis, tuan rumah dapat membagikan IP lokal mereka (ditampilkan di lobi) sehingga orang lain dapat mengetiknya dan mengetuk "Join Game".
',
		'bn': 'মাল্টিপ্লেয়ার মুনরিজ রামি একা এআই প্রতিপক্ষের বিরুদ্ধে বা বন্ধুদের সাথে অনলাইনে যেকোনো প্ল্যাটফর্মে খেলা যায় — অতিরিক্ত বট সহ বা ছাড়া।

একা খেলতে, প্রধান মেনুতে "নতুন গেম হোস্ট করুন" এ ক্লিক করুন এবং আপনার লবিতে এক বা একাধিক বট যুক্ত করুন।

বন্ধুদের সাথে খেলতে, সবাই একই Wi-Fi বা হটস্পটে থাকলে সবচেয়ে ভালো হয়। একজন খেলোয়াড় হোস্ট করে, এবং অন্যরা যখন তাদের লবি তালিকায় গেমটি উপস্থিত হয় তখন যোগদান করে।

যদি এটি স্বয়ংক্রিয়ভাবে প্রদর্শিত না হয়, হোস্ট তাদের স্থানীয় আইপি (এটি লবিতে দেখানো হয়েছে) শেয়ার করতে পারে যাতে অন্যরা এটি টাইپ করতে এবং "গেমে যোগ দিন" ট্যাপ করতে পারে।
',
		'tr': 'Çok oyunculu Moonridge Rummy, yapay zeka rakiplere karşı tek başınıza veya arkadaşlarınızla çevrimiçi olarak herhangi bir platformda oynanabilir — ek botlarla veya botsuz.

Tek başınıza oynamak için ana menüde "Yeni Oyun Kur" seçeneğine tıklayın ve lobinize bir veya daha fazla bot ekleyin.

Arkadaşlarınızla oynamak için herkesin aynı Wi-Fi veya ortak erişim noktasında olması en iyisidir. Bir oyuncu ev sahipliği yapar ve diğerleri oyun lobi listelerinde göründüğünde katılır.

Otomatik olarak görünmezse, ev sahibi yerel IP\'sini (lobide gösterilir) paylaşabilir, böylece diğerleri bunu yazıp "Oyuna Katıl" a dokunabilir.
',
		'pl': 'Wieloosobową grę Moonridge Rummy można rozgrywać solo przeciwko przeciwnikom AI lub online z przyjaciółmi na dowolnej platformie — z dodatkowymi botami lub bez.

Aby grać solo, kliknij "Host New Game" w menu głównym i dodaj jednego lub więcej botów do swojego lobby.

Aby grać z przyjaciółmi, najlepiej, jeśli wszyscy są w tej samej sieci Wi-Fi lub hotspocie. Jeden gracz jest gospodarzem, a pozostali dołączają, gdy gra pojawi się na ich liście w lobby.

Jeśli nie pojawi się automatycznie, gospodarz może udostępnić swój lokalny adres IP (jest on pokazany w lobby), aby inni mogli go wpisać i dotknąć "Join Game".
',
		'nl': 'Multiplayer Moonridge Rummy kan solo worden gespeeld tegen AI-tegenstanders of online met vrienden op elk platform — met of zonder extra bots.

Om solo te spelen, klik op "Host New Game" in het hoofdmenu en voeg een of meer bots toe aan je lobby.

Om met vrienden te spelen, werkt het het beste als iedereen op dezelfde Wi-Fi of hotspot zit. Eén speler host, en de anderen doen mee wanneer het spel in hun lobbylijst verschijnt.

Als het niet automatisch verschijnt, kan de host zijn lokale IP delen (het wordt getoond in de lobby) zodat anderen het kunnen intypen en op "Join Game" kunnen tikken.
',
		'th': 'มัลติเพลเยอร์ Moonridge Rummy สามารถเล่นคนเดียวกับคู่ต่อสู้ AI หรือเล่นออนไลน์กับเพื่อน ๆ บนแพลตฟอร์มใดก็ได้ — มีหรือไม่มีบอทเสริมก็ได้

ในการเล่นคนเดียว คลิก "โฮสต์เกมใหม่" บนเมนูหลักและเพิ่มบอทหนึ่งตัวหรือมากกว่าในล็อบบี้ของคุณ

ในการเล่นกับเพื่อน ๆ จะดีที่สุดถ้าทุกคนอยู่ใน Wi-Fi หรือฮอตสปอตเดียวกัน ผู้เล่นคนหนึ่งเป็นโฮสต์ และคนอื่น ๆ จะเข้าร่วมเมื่อเกมปรากฏในรายการล็อบบี้ของพวกเขา

หากไม่ปรากฏขึ้นโดยอัตโนมัติ โฮสต์สามารถแชร์ IP ท้องถิ่นของตน (ที่แสดงในล็อบบี้) เพื่อให้ผู้อื่นสามารถพิมพ์และแตะ "เข้าร่วมเกม" ได้
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
		'ru': 'Пока игроки подключаются, хост может добавлять или удалять ботов (или игроков), нажимая «Добавить бота» либо перетаскивая значок игрока на «Удалить».

Когда все готовы в лобби, хост нажимает «Начать игру» — и поехали!
',
		'zh-Hans': '玩家陆续加入时，房主可以点“添加机器人”来增删机器人（或把玩家头像拖到“移除”来移除玩家）。

等大厅里的人都准备好后，房主点一下“开始游戏”就能开局！
',
		'zh-Hant': '玩家陸續加入時，房主可以點「新增機器人」來增刪機器人（或把玩家頭像拖到「移除」來移除玩家）。

等大廳裡的人都準備好後，房主點一下「開始遊戲」就能開局！
',
		'ar': 'بينما ينضم اللاعبون، يمكن للمضيف إضافة أو إزالة بوتات (أو لاعبين) بالضغط على « إضافة بوت » أو بسحب أيقونة لاعب إلى « إزالة ».

عندما يكون الجميع جاهزًا في الردهة، يضغط المضيف « بدء اللعبة » ونبدأ!
',
		'ko': '플레이어들이 들어오는 동안, 호스트는 « 봇 추가 »를 눌러 봇을 추가하거나, 플레이어 아이콘을 « 제거 »로 끌어다 제거할 수 있어요.

모두 준비가 끝나면 호스트가 « 게임 시작 »을 눌러서 바로 시작!
',
		'he': 'בזמן שהשחקנים מצטרפים, המארח יכול להוסיף או להסיר בוטים (או שחקנים) בלחיצה על « הוסף בוט » או על ידי גרירת האווטאר של השחקן אל « הסר ».

כשכולם מוכנים בלובי, המארח לוחץ על « התחל משחק » ויוצאים לדרך!
',
		'hi': 'जब खिलाड़ी शामिल हो रहे हों, तो होस्ट "बॉट जोड़ें" पर क्लिक करके या खिलाड़ी के आइकन को "निकालें" पर खींचकर बॉट (या खिलाड़ियों) को जोड़ या हटा सकता है।

जब सभी लॉबी में तैयार हों, तो होस्ट शुरू करने के लिए "गेम शुरू करें" पर क्लिक करता है!
',
		'id': 'Saat pemain bergabung, tuan rumah dapat menambah atau menghapus bot (atau pemain) dengan mengklik "Tambah Bot" atau dengan menyeret ikon pemain ke "Hapus".

Ketika semua orang siap di lobi, tuan rumah mengklik "Mulai Game" untuk memulai!
',
		'bn': 'খেলোয়াড়রা যখন যোগদান করছে, হোস্ট "বট যোগ করুন" এ ক্লিক করে বা খেলোয়াড়ের আইকনটিকে "সরান" এ টেনে বট (বা খেলোয়াড়) যোগ বা সরাতে পারে।

যখন সবাই লবিতে প্রস্তুত, হোস্ট শুরু করার জন্য "গেম শুরু করুন" এ ক্লিক করে!
',
		'tr': 'Oyuncular katılırken, ev sahibi "Bot Ekle" seçeneğine tıklayarak veya bir oyuncunun simgesini "Kaldır" seçeneğine sürükleyerek bot (veya oyuncu) ekleyebilir veya kaldırabilir.

Herkes lobide hazır olduğunda, ev sahibi başlamak için "Oyunu Başlat" seçeneğine tıklar!
',
		'pl': 'Podczas gdy gracze dołączają, gospodarz może dodawać lub usuwać boty (lub graczy), klikając "Dodaj bota" lub przeciągając ikonę gracza na "Usuń".

Gdy wszyscy będą gotowi w lobby, gospodarz klika "Rozpocznij grę", aby rozpocząć!
',
		'nl': 'Terwijl spelers meedoen, kan de host bots (of spelers) toevoegen of verwijderen door op "Bot toevoegen" te klikken of door het icoon van een speler naar "Verwijderen" te slepen.

Wanneer iedereen klaar is in de lobby, klikt de host op "Start Spel" om te beginnen!
',
		'th': 'ในขณะที่ผู้เล่นกำลังเข้าร่วม โฮสต์สามารถเพิ่มหรือลบพอท (หรือผู้เล่น) ได้โดยคลิก "เพิ่มพอท" หรือโดยการลากไอคอนของผู้เล่นไปที่ "ลบ"

เมื่อทุกคนพร้อมในล็อบบี้ โฮสต์จะคลิก "เริ่มเกม" เพื่อเริ่มต้น!
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
		'zh-Hans': '每一回合都有自己必须完成的组牌条件才能获胜。

在回合界面的顶部会显示需要多少个“书”（3 张以上同点数）和多少个“顺子”（4 张以上同花）的组合。

在第 1 到 6 回合里，你得先完成自己的要求，才能往别人已经下的牌堆里加牌。

第 7 回合很特别——必须把整手牌全部打光才能赢！
',
		'zh-Hant': '每一回合都有自己必須完成的組牌條件才能獲勝。

在回合介面的頂部會顯示需要多少個「書」（3 張以上同點數）和多少個「順子」（4 張以上同花）的組合。

在第 1 到 6 回合裡，你得先完成自己的要求，才能往別人已經下的牌堆裡加牌。

第 7 回合很特別——必須把整手牌全部打光才能贏！
',
		'ar': 'كل جولة لها متطلبات طرح خاصة يجب تحقيقها للفوز.

في أعلى شاشة الجولة سترى عدد الكتب (مجموعات من 3 أوراق أو أكثر بنفس القيمة) وعدد السلاسل (متتاليات من 4 أوراق أو أكثر بنفس اللون) المطلوبة.

في الجولات 1‑6 يجب أن تحقق متطلباتك الخاصة قبل أن تضيف إلى مجموعات اللاعبين الآخرين.

الجولة 7 مميزة — عليك إنهاء يدك بالكامل بدون أي ورقة لتفوز!
',
		'ko': '각 라운드마다 승리하려면 채워야 하는 멜드 조건이 있어요.

라운드 화면 위쪽에는 필요한 북(같은 숫자 3장 이상)과 런(같은 무늬 4장 이상)이 몇 개인지 보여 줘요.

1~6라운드에서는 내 조건을 먼저 만족해야 다른 플레이어의 멜드에 카드를 추가할 수 있습니다.

7라운드는 특별해요 — 손패를 전부 털어야 승리합니다!
',
		'he': 'לכל סיבוב יש דרישות קלפים משלו שצריך להשלים כדי לנצח.

בחלק העליון של מסך הסיבוב תראה כמה "ספרים" (שלשות או יותר באותו ערך) וכמה "ריצות" (רצפים של ארבעה קלפים או יותר באותו הצבע) צריך.

בסיבובים 1‑6 אתה חייב להשלים קודם את הדרישות שלך לפני שתוסיף לקלפים של אחרים.

סיבוב 7 מיוחד — צריך להתרוקן מכל הקלפים כדי לנצח!
',
		'hi': 'प्रत्येक दौर की अपनी मेल्डिंग आवश्यकताएं होती हैं जिन्हें जीतने के लिए पूरा करना होता है।

प्रत्येक दौर की स्क्रीन के शीर्ष पर, आपको दिखाई देगा कि कितनी किताबें (एक ही रैंक के 3+ कार्ड के समूह) और रन (एक ही सूट के 4+ कार्ड के क्रम) की आवश्यकता है।

दौर 1-6 में, आपको अन्य खिलाड़ियों के मेल्ड पर मेल्ड करने से पहले अपनी खुद की मेल्डिंग आवश्यकताओं को पूरा करना होगा।

दौर 7 विशेष है - आपको जीतने के लिए बिना किसी कार्ड के अपना हाथ पूरी तरह से खत्म करना होगा!
',
		'id': 'Setiap putaran memiliki persyaratan meld sendiri yang harus dipenuhi untuk menang.

Di bagian atas layar setiap putaran, Anda akan melihat berapa banyak buku (kelompok 3+ kartu dengan peringkat yang sama) dan lari (urutan 4+ kartu dengan jenis yang sama) yang dibutuhkan.

Di putaran 1–6, Anda harus memenuhi persyaratan meld Anda sendiri sebelum Anda dapat meld di meld pemain lain.

Putaran 7 istimewa — Anda harus menyelesaikan tangan Anda sepenuhnya tanpa kartu tersisa untuk menang!
',
		'bn': 'প্রতিটি রাউন্ডের নিজস্ব মেল্ডিং প্রয়োজনীয়তা রয়েছে যা জিততে পূরণ করতে হবে।

প্রতিটি রাউন্ডের স্ক্রিনের শীর্ষে, আপনি দেখতে পাবেন কতগুলি বই (একই র‍্যাঙ্কের 3+ কার্ডের গ্রুপ) এবং রান (একই স্যুটের 4+ কার্ডের ক্রম) প্রয়োজন।

রাউন্ড 1-6-এ, আপনাকে অন্য খেলোয়াড়দের মেল্ডে মেল্ড করার আগে আপনার নিজের মেল্ডিং প্রয়োজনীয়তা পূরণ করতে হবে।

রাউন্ড 7 বিশেষ — আপনাকে জিততে কোনো কার্ড ছাড়াই আপনার হাত পুরোপুরি শেষ করতে হবে!
',
		'tr': 'Her turun kazanmak için karşılanması gereken kendi birleştirme gereksinimleri vardır.

Her turun ekranının üst kısmında, kaç tane kitap (aynı değerde 3+ kart grubu) ve kaç tane dizi (aynı türden 4+ kart dizisi) gerektiği gösterilir.

1-6. turlarda, diğer oyuncuların birleştirmelerine birleştirme yapmadan önce kendi birleştirme gereksinimlerinizi karşılamanız gerekir.

7. tur özeldir — kazanmak için elinizi tamamen bitirmeniz ve hiç kartınızın kalmaması gerekir!
',
		'pl': 'Każda runda ma swoje własne wymagania dotyczące meldunku, które muszą zostać spełnione, aby wygrać.

Na górze ekranu każdej rundy zobaczysz, ile książek (grup 3+ kart o tej samej wartości) i ile sekwensów (sekwencji 4+ kart tego samego koloru) jest potrzebnych.

W rundach 1-6 musisz spełnić własne wymagania dotyczące meldunku, zanim będziesz mógł meldować na meldunki innych graczy.

Runda 7 jest wyjątkowa — musisz całkowicie zakończyć rękę bez żadnych kart, aby wygrać!
',
		'nl': 'Elke ronde heeft zijn eigen meldvereisten waaraan moet worden voldaan om te winnen.

Bovenaan het scherm van elke ronde zie je hoeveel boeken (groepen van 3+ kaarten van dezelfde waarde) en runs (reeksen van 4+ kaarten van dezelfde soort) nodig zijn.

In rondes 1-6 moet je aan je eigen meldvereisten voldoen voordat je op de melds van andere spelers kunt meldden.

Ronde 7 is speciaal — je moet je hand volledig afmaken zonder kaarten over om te winnen!
',
		'th': 'แต่ละรอบมีข้อกำหนดการรวมกลุ่มของตัวเองที่ต้องทำให้สำเร็จเพื่อที่จะชนะ

ที่ด้านบนของหน้าจอแต่ละรอบ คุณจะเห็นว่าต้องใช้หนังสือกี่เล่ม (กลุ่มไพ่ 3+ ใบที่มีแต้มเท่ากัน) และวิ่งกี่ครั้ง (ลำดับไพ่ 4+ ใบที่มีดอกเดียวกัน)

ในรอบที่ 1-6 คุณต้องปฏิบัติตามข้อกำหนดการรวมกลุ่มของคุณเองก่อนจึงจะสามารถรวมกลุ่มกับผู้เล่นคนอื่นได้

รอบที่ 7 เป็นรอบพิเศษ — คุณต้องจบไพ่ในมือให้หมดโดยไม่เหลือไพ่เลยจึงจะชนะ!
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
		'zh-Hans': '游戏界面主要分成两块。
上方显示所有玩家的公开合牌，下方是你的私有区域，可以随意整理手牌。

左侧是合牌区，把牌拖过去即可组合。放在合牌区的牌，在你的回合中不会被误点到弃掉。

右下角的牌仍然可以在你的回合轻点来弃牌。
',
		'zh-Hant': '遊戲介面主要分成兩塊。
上方顯示所有玩家的公開合牌，下方是你的私有區域，可以隨意整理手牌。

左側是合牌區，把牌拖過去即可組合。放在合牌區的牌，在你的回合中不會被誤點到棄掉。

右下角的牌仍然可以在你的回合輕點來棄牌。
',
		'ar': 'منطقة اللعب لها جزأين رئيسيين.
الجزء العلوي يعرض مجموعات كل لاعب العامة، بينما الجزء السفلي خاص بك. يمكنك تحريك وترتيب أوراقك بأي طريقة تريد.

على اليسار توجد مناطق الطرح — اسحب الأوراق إلى هناك لبناء مجموعاتك. بمجرد أن تكون الورقة في منطقة الطرح، لا يمكنك التخلص منها عن طريق الخطأ أثناء دورك بالضغط عليها.

لا يزال من الممكن الضغط على الأوراق في أسفل اليمين للتخلص منها أثناء دورك.
',
		'ko': '게임 영역은 크게 두 부분으로 나뉩니다.
상단에는 모든 플레이어의 공개 멜드가 표시되고 하단은 당신에게만 비공개입니다. 원하는 방식으로 카드를 이동하고 배열할 수 있습니다.

왼쪽에는 멜드 영역이 있습니다. 카드를 그곳으로 끌어 멜드를 만드세요. 카드가 멜드 영역에 있으면 턴 중에 실수로 탭하여 버릴 수 없습니다.

오른쪽 하단에 있는 카드는 턴 중에 탭하여 버릴 수 있습니다.
',
		'he': 'לאזור המשחק שני חלקים עיקריים.
החלק העליון מציג את המלדים הציבוריים של כל שחקן, בעוד שהחלק התחתון פרטי לך. אתה יכול להזיז ולסדר את הקלפים שלך בכל דרך שתרצה.

בצד שמאל נמצאים אזורי המלד - גרור לשם קלפים כדי לבנות את המלדים שלך. ברגע שקלף נמצא באזור מלד, אינך יכול להשליך אותו בטעות במהלך תורך על ידי הקשה עליו.

עדיין ניתן להקיש על קלפים בפינה הימנית התחתונה כדי להשליך אותם במהלך תורך.
',
		'hi': 'खेल क्षेत्र के दो मुख्य भाग हैं।
शीर्ष पर हर खिलाड़ी के सार्वजनिक मेल्ड दिखाई देते हैं, जबकि नीचे का भाग आपके लिए निजी है। आप अपने कार्ड को किसी भी तरह से स्थानांतरित और व्यवस्थित कर सकते हैं।

बाईं ओर मेल्ड क्षेत्र हैं - अपने मेल्ड बनाने के लिए कार्ड वहां खींचें। एक बार जब कोई कार्ड मेल्ड क्षेत्र में होता है, तो आप अपनी बारी के दौरान गलती से उस पर टैप करके उसे त्याग नहीं सकते।

आपकी बारी के दौरान उन्हें त्यागने के लिए निचले-दाएं कोने में कार्ड पर अभी भी टैप किया जा सकता है।
',
		'id': 'Area permainan memiliki dua bagian utama.
Bagian atas menunjukkan meld publik setiap pemain, sedangkan bagian bawah bersifat pribadi bagi Anda. Anda dapat memindahkan dan mengatur kartu Anda sesuka Anda.

Di sebelah kiri adalah area meld — seret kartu ke sana untuk membangun meld Anda. Setelah kartu berada di area meld, Anda tidak dapat secara tidak sengaja membuangnya secara tidak sengaja selama giliran Anda dengan mengetuknya.

Kartu di kanan bawah masih bisa diketuk untuk dibuang selama giliran Anda.
',
		'bn': 'খেলার ক্ষেত্রটির দুটি প্রধান অংশ রয়েছে।
শীর্ষে প্রতিটি খেলোয়াড়ের পাবলিক মেল্ডগুলি দেখানো হয়, যখন নীচের অংশটি আপনার জন্য ব্যক্তিগত। আপনি আপনার পছন্দ মতো আপনার কার্ডগুলি সরাতে এবং সাজাতে পারেন।

বাম দিকে মেল্ড অঞ্চল রয়েছে — আপনার মেল্ডগুলি তৈরি করতে সেখানে কার্ডগুলি টেনে আনুন। একবার কোনও কার্ড মেল্ড অঞ্চলে থাকলে, আপনি আপনার পালা চলাকালীন ভুলবশত এটিতে ট্যাপ করে বাতিল করতে পারবেন না।

আপনার পালা চলাকালীন সেগুলি বাতিল করতে নীচের-ডানদিকের কার্ডগুলিতে এখনও ট্যাপ করা যেতে পারে।
',
		'tr': 'Oyun alanının iki ana bölümü vardır.
Üst kısım her oyuncunun genel birleştirmelerini gösterirken, alt kısım size özeldir. Kartlarınızı istediğiniz gibi taşıyabilir ve düzenleyebilirsiniz.

Solda birleştirme alanları bulunur — birleştirmelerinizi oluşturmak için kartları oraya sürükleyin. Bir kart birleştirme alanına girdiğinde, sıranız sırasında yanlışlıkla üzerine dokunarak atamazsınız.

Sıranız sırasında atmak için sağ alttaki kartlara hala dokunulabilir.
',
		'pl': 'Obszar gry ma dwie główne części.
Górna część pokazuje publiczne meldunki każdego gracza, podczas gdy dolna jest prywatna dla Ciebie. Możesz przesuwać i układać swoje karty w dowolny sposób.

Po lewej stronie znajdują się obszary meldunku — przeciągnij tam karty, aby zbudować swoje meldunki. Gdy karta znajdzie się w obszarze meldunku, nie możesz jej przypadkowo odrzucić przez pomyłkę podczas swojej tury, dotykając jej.

Karty w prawym dolnym rogu nadal można dotknąć, aby je odrzucić podczas swojej tury.
',
		'nl': 'Het speelveld heeft twee hoofdonderdelen.
De bovenkant toont de openbare melds van elke speler, terwijl de onderkant privé voor jou is. Je kunt je kaarten verplaatsen en rangschikken zoals je wilt.

Aan de linkerkant zijn meldgebieden — sleep kaarten daarheen om je melds te bouwen. Zodra een kaart zich in een meldgebied bevindt, kun je deze tijdens je beurt niet per ongeluk weggooien door erop te tikken.

Kaarten rechtsonder kunnen nog steeds worden aangetikt om ze tijdens je beurt weg te gooien.
',
		'th': 'พื้นที่เกมมีสองส่วนหลัก
ด้านบนแสดงการรวมกลุ่มสาธารณะของผู้เล่นทุกคน ในขณะที่ด้านล่างเป็นส่วนตัวสำหรับคุณ คุณสามารถย้ายและจัดเรียงไพ่ของคุณได้ตามที่คุณต้องการ

ทางด้านซ้ายคือพื้นที่รวมกลุ่ม — ลากไพ่ไปที่นั่นเพื่อสร้างการรวมกลุ่มของคุณ เมื่อไพ่อยู่ในพื้นที่รวมกลุ่มแล้ว คุณจะไม่สามารถทิ้งไพ่โดยไม่ได้ตั้งใจในระหว่างตาของคุณโดยการแตะที่ไพ่

ไพ่ที่มุมล่างขวายังคงสามารถแตะเพื่อทิ้งได้ในระหว่างตาของคุณ
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

そのあと、今のラウンドの条件を満たせるようにカードをメルドゾーンへドラッグ。きらっと光ったら準備OK。用意ができたら「メルド！」アイコンをタップして手札を場に出します。
',
		'fr': 'Quand vient ton tour, ton icône en haut s\'illumine avec un contour orange pulsé.

Commence par piocher une carte : tape sur la pile de gauche pour piocher dans la pioche, ou sur celle de droite pour prendre la défausse.

Ensuite essaye de remplir les exigences de la manche. Fais glisser tes cartes dans les zones de meld jusqu\'à ce qu\'elles scintillent. Quand tu es prêt, tape sur l\'icône « Meld ! » pour poser ta main.
',
		'it': 'Quando è il tuo turno, la tua icona in alto lampeggia con un bordo arancione.

Per prima cosa pesca una carta: tocca il mazzo a sinistra per pescare dal tallone oppure quello a destra per prendere la carta scartata.

Poi cerca di soddisfare i requisiti del round. Trascina le carte nelle zone meld finché non brillano. Quando sei pronto, tocca l\'icona « Meld! » per calare la mano.
',
		'es': 'Cuando te toca, tu icono arriba brilla con un borde naranja pulsante.

Primero roba una carta: toca el montón izquierdo para robar del mazo, o el derecho para tomar la carta de descarte.

Luego intenta cumplir los requisitos de la ronda. Arrastra cartas a las zonas de meld hasta que brillen. Cuando estés listo, toca el icono « ¡Meld! » para bajar tu mano.
',
		'pt': 'Quando é a sua vez, seu ícone no topo fica com uma borda laranja pulsante.

Primeiro compre uma carta: toque no monte da esquerda para comprar do baralho ou no da direita para pegar a carta do descarte.

Depois tente cumprir os requisitos da rodada. Arraste as cartas para as zonas de meld até elas brilharem. Quando estiver pronto, toque no ícone « Meld! » para baixar sua mão.
',
		'ru': 'Когда ход переходит к тебе, твой значок наверху подсвечивается пульсирующей оранжевой рамкой.

Сначала возьми карту: тапни левую стопку, чтобы взять из колоды, или правую, чтобы забрать верхнюю карту сброса.

Затем постарайся выполнить требования раунда. Перетаскивай карты в зоны раскладок, пока они не начнут сиять. Как только готов, нажимай на значок « Выложить! » и выкладывай руку.
',
		'zh-Hans': '轮到你时，顶部的头像会亮起一圈橙色光晕。

先抽一张牌：点左边的牌堆从库存抓牌，或点右边的牌堆拿走顶牌。

接着尝试完成这一回合的要求，把牌拖到合牌区域，直到它们闪烁。准备好了就点“合牌！”图标，把手牌打出去。
',
		'zh-Hant': '輪到你時，頂部的頭像會亮起一圈橙色光暈。

先抽一張牌：點左邊的牌堆從庫存抓牌，或點右邊的牌堆拿走頂牌。

接著嘗試完成這一回合的要求，把牌拖到合牌區域，直到它們閃爍。準備好了就點「合牌！」圖示，把手牌打出去。
',
		'ar': 'عندما يحين دورك سيضيء رمز اللاعب الخاص بك في الأعلى بإطار برتقالي نابض.

أولًا اسحب ورقة — اضغط على الكومة اليسرى للسحب من الرزمة، أو على الكومة اليمنى لأخذ أعلى ورقة من الرمي.

بعدها حاول تحقيق متطلبات الجولة الحالية. اسحب الأوراق إلى مناطق الطرح حتى تلمع. عندما تكون جاهزًا اضغط على أيقونة « اطرح! » لوضع يدك على الطاولة.
',
		'ko': '내 차례가 되면, 화면 위 플레이어 아이콘에 주황색 테두리가 반짝여요.

먼저 카드를 한 장 뽑으세요. 왼쪽 더미를 탭하면 덱에서, 오른쪽 더미를 탭하면 버린 카드 맨 위를 가져옵니다.

그다음 이번 라운드 조건을 맞춰 보세요. 카드가 반짝일 때까지 멜드 존으로 끌어다 놓고, 준비가 되면 « 멜드! » 아이콘을 눌러 손패를 내려놓아요.
',
		'he': 'כשהתור שלך מגיע, האווטאר שלך למעלה זוהר במסגרת כתומה ומחויכת.

קודם שולפים קלף — הקש על הערימה השמאלית כדי לשלוף מהחפיסה, או על הימנית כדי לקחת את הקלף העליון מהשלכה.

אחר כך נסה לעמוד בדרישות של הסיבוב. גרור קלפים לאזורי המלט עד שהם מנצנצים. כשאתה מוכן, לחץ על « הנח! » כדי להניח את היד.
',
		'hi': 'जब आपकी बारी आती है, तो शीर्ष पर आपका खिलाड़ी आइकन एक धड़कते नारंगी बॉर्डर के साथ चमकता है।

सबसे पहले, एक कार्ड बनाएं - स्टॉक से ड्रॉ करने के लिए बाएं ढेर पर टैप करें, या शीर्ष डिस्कार्ड को लेने के लिए दाएं ढेर पर टैप करें।

फिर, चालू दौर की आवश्यकताओं को पूरा करने का प्रयास करें। जब तक वे चमक न जाएं, तब तक कार्ड को मेल्ड ज़ोन में खींचें। जब आप तैयार हों, तो अपना हाथ नीचे रखने के लिए "मेल्ड!" आइकन पर टैप करें।
',
		'id': 'Saat giliran Anda, ikon pemain Anda di bagian atas akan bersinar dengan batas oranye yang berdenyut.

Pertama, ambil kartu — ketuk tumpukan kiri untuk mengambil dari stok, atau tumpukan kanan untuk mengambil kartu buangan teratas.

Kemudian, coba penuhi persyaratan putaran saat ini. Seret kartu ke zona meld hingga berkilau. Saat Anda siap, ketuk ikon "Meld!" untuk meletakkan tangan Anda.
',
		'bn': 'যখন আপনার পালা, শীর্ষে আপনার প্লেয়ার আইকনটি একটি স্পন্দিত কমলা সীমানা দিয়ে জ্বলজ্বল করবে।

প্রথমে, একটি কার্ড আঁকুন — স্টক থেকে আঁকতে বাম স্তূপে আলতো চাপুন, বা উপরের বাতিলটি নিতে ডান স্তূপে আলতো চাপুন।

তারপরে, বর্তমান রাউন্ডের প্রয়োজনীয়তাগুলি পূরণ করার চেষ্টা করুন। কার্ডগুলিকে মেল্ড জোনে টেনে আনুন যতক্ষণ না সেগুলি ঝকঝকে হয়। আপনি যখন প্রস্তুত হন, আপনার হাত নিচে রাখতে "মেল্ড!" আইকনে আলতো চাপুন।
',
		'tr': 'Sıra size geldiğinde, üstteki oyuncu simgeniz titreşen turuncu bir kenarlıkla parlayacaktır.

İlk olarak, bir kart çekin — stoktan çekmek için sol desteye veya en üstteki atılanı almak için sağ desteye dokunun.

Ardından, mevcut turun gereksinimlerini karşılamaya çalışın. Parıldayana kadar kartları birleştirme bölgelerine sürükleyin. Hazır olduğunuzda, elinizi açmak için "Birleştir!" simgesine dokunun.
',
		'pl': 'Kiedy nadejdzie Twoja kolej, Twoja ikona gracza na górze zaświeci się pulsującą pomarańczową ramką.

Najpierw dobierz kartę — dotknij lewego stosu, aby dobrać ze stosu, lub prawego stosu, aby wziąć wierzchnią kartę odrzuconą.

Następnie spróbuj spełnić wymagania bieżącej rundy. Przeciągaj karty do stref meldunku, aż zaczną błyszczeć. Kiedy będziesz gotowy, dotknij ikony "Meld!", aby wyłożyć rękę.
',
		'nl': 'Wanneer het jouw beurt is, zal je spelericoon bovenaan oplichten met een pulserende oranje rand.

Trek eerst een kaart — tik op de linkerstapel om uit de voorraad te trekken, of op de rechterstapel om de bovenste aflegger te nemen.

Probeer vervolgens te voldoen aan de vereisten van de huidige ronde. Sleep kaarten naar de meldzones totdat ze fonkelen. Wanneer je klaar bent, tik je op het "Meld!"-icoon om je hand neer te leggen.
',
		'th': 'เมื่อถึงตาของคุณ ไอคอนผู้เล่นของคุณที่ด้านบนจะสว่างขึ้นพร้อมกับเส้นขอบสีส้มที่กะพริบ

ขั้นแรก จั่วไพ่ — แตะกองซ้ายเพื่อจั่วจากสต็อก หรือกองขวาเพื่อหยิบไพ่ที่ทิ้งบนสุด

จากนั้น พยายามทำตามข้อกำหนดของรอบปัจจุบัน ลากไพ่ไปยังโซนรวมกลุ่มจนกว่าไพ่จะเปล่งประกาย เมื่อคุณพร้อมแล้ว ให้แตะไอคอน "รวมกลุ่ม!" เพื่อวางไพ่ในมือของคุณ
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
		'ja': 'メルドしたあとも、自分や他プレイヤーのメルドにカードをどんどん追加できます。確定させるときはもう一度「メルド！」をタップ。

ラウンド1〜6では、右下のカードをタップして捨て札にし、ターンを終わらせます。手札がゼロになればそのラウンドの勝者です！

ラウンド7では、最初にメルドしたプレイヤーは手札を完全に出し切らなければならず、他人のメルドに追加することもできません。
',
		'fr': 'Après avoir meldé, continue d\'ajouter des cartes sur tes melds ou ceux des autres. Tape à nouveau sur « Meld ! » pour confirmer.

Dans les manches 1 à 6, termine ton tour en tapant une carte en bas à droite pour la défausser. Si tu restes sans cartes, tu gagnes la manche !

À la manche 7, le premier à meld doit finir sa main complètement et ne peut plus ajouter sur les melds adverses.
',
		'it': 'Dopo aver calato, puoi continuare ad aggiungere carte ai tuoi meld o a quelli degli altri. Tocca di nuovo « Meld! » per confermare.

Nei round 1-6 chiudi il turno toccando una carta in basso a destra per scartarla. Se resti senza carte, hai vinto il round!

Nel round 7 chi cala per primo deve liberarsi di tutta la mano e non può attaccarsi alle combinazioni altrui.
',
		'es': 'Después de bajar tus cartas, sigue sumando a tus melds o a los de los demás. Toca otra vez « ¡Meld! » para confirmar.

En las rondas 1 a 6 termina tu turno tocando una carta en la esquina inferior derecha para descartarla. ¡Si te quedas sin cartas, ganas la ronda!

En la ronda 7, quien baja primero debe acabar la mano completa y no puede engancharse a las bajadas ajenas.
',
		'pt': 'Depois de baixar suas cartas, continue adicionando às suas combinações ou às dos outros. Toque « Meld! » de novo para confirmar.

Nas rodadas 1 a 6, termine o turno tocando uma carta no canto inferior direito para descartá-la. Se ficar sem cartas, você vence a rodada!

Na rodada 7, o primeiro a meldar precisa esvaziar a mão inteira e não pode mais anexar cartas aos melds dos outros.
',
		'ru': 'После выкладки продолжай добавлять карты к своим комбинациям или к чужим. Нажми « Выложить! » ещё раз, чтобы подтвердить.

В раундах 1–6 заверши ход, тапнув карту в правом нижнем углу и отправив её в сброс. Если карт не осталось — раунд твой!

В раунде 7 игрок, который выложил первым, должен полностью разыграть руку и не может добавлять карты к чужим раскладкам.
',
		'zh-Hans': '合牌之后，还可以继续往自己的牌堆或别人的牌堆加牌。再点一次“合牌！”来确认。

在第 1～6 回合，点右下角的一张牌把它弃掉，就结束回合。手牌清空就算赢得这一回合！

第 7 回合里，最先合牌的玩家必须把整手牌都打完，不能再往别人牌堆里加牌。
',
		'zh-Hant': '合牌之後，還可以繼續往自己的牌堆或別人的牌堆加牌。再點一次「合牌！」來確認。

在第 1～6 回合，點右下角的一張牌把它棄掉，就結束回合。手牌清空就算贏得這一回合！

第 7 回合裡，最先合牌的玩家必須把整手牌都打完，不能再往別人牌堆裡加牌。
',
		'ar': 'بعد أن تطرح أوراقك، يمكنك الاستمرار في إضافة أوراق إلى مجموعاتك أو إلى مجموعات الآخرين. اضغط « اطرح! » مرة ثانية للتأكيد.

في الجولات 1‑6 أنهِ دورك بالضغط على ورقة في الركن السفلي الأيمن لرميها. إذا لم يتبق أي ورق فقد فزت بالجولة!

في الجولة 7 يجب على أول شخص يطرح أن ينهي يده بالكامل ولا يمكنه الإضافة إلى مجموعات الآخرين.
',
		'ko': '멜드를 끝낸 뒤에도 내 멜드나 다른 사람 멜드에 계속 카드를 붙일 수 있어요. 확정하려면 « 멜드! »를 한 번 더 눌러 주세요.

1~6라운드에서는 오른쪽 아래 카드 하나를 탭해 버리면 차례가 끝나요. 손패가 0장이라면 그 라운드를 이긴 거예요!

7라운드에서는 먼저 멜드한 사람이 손패를 완전히 털어야 하고, 다른 사람 멜드에 붙일 수 없어요.
',
		'he': 'אחרי שהנחת מלט, אפשר להמשיך להוסיף קלפים למלטים שלך או של אחרים. לחץ שוב על « הנח! » כדי לאשר.

בסיבובים 1‑6 מסיימים את התור בלחיצה על קלף בפינה הימנית־תחתונה כדי להשליך אותו. אם נשארת בלי קלפים – ניצחת בסיבוב!

בסיבוב 7 מי שמניח ראשון חייב לגמור את כל היד ואסור לו להוסיף למלטים של אחרים.
',
		'hi': 'मेल्डिंग के बाद, अपने मेल्ड में या दूसरों के मेल्ड में कार्ड जोड़ते रहें। पुष्टि करने के लिए फिर से "मेल्ड!" पर टैप करें।

राउंड 1-6 में, इसे त्यागने के लिए निचले-दाएं कोने में एक कार्ड पर टैप करके अपनी बारी समाप्त करें। यदि आपके पास कोई कार्ड नहीं बचा है, तो आपने राउंड जीत लिया है!

राउंड 7 में, मेल्ड करने वाले पहले व्यक्ति को अपना हाथ पूरी तरह से खत्म करना होगा और वह दूसरों के मेल्ड में नहीं जोड़ सकता है।
',
'id': 'Setelah melakukan meld, terus tambahkan kartu ke meld Anda atau ke milik orang lain. Ketuk "Meld!" lagi untuk mengonfirmasi.

Di ronde 1–6, akhiri giliran Anda dengan mengetuk kartu di kanan bawah untuk membuangnya. Jika Anda tidak punya kartu tersisa, Anda telah memenangkan ronde tersebut!

Di ronde 7, orang pertama yang melakukan meld harus menyelesaikan tangannya sepenuhnya dan tidak dapat menambahkan ke meld orang lain.
',
		'bn': 'মেল্ডিংয়ের পরে, আপনার মেল্ডগুলিতে বা অন্যদের মেল্ডগুলিতে কার্ড যুক্ত করতে থাকুন। নিশ্চিত করতে আবার "মেল্ড!" এ আলতো চাপুন।

রাউন্ড 1-6-এ, এটি বাতিল করতে নীচের-ডানদিকের একটি কার্ডে ট্যাপ করে আপনার পালা শেষ করুন। যদি আপনার কোনও কার্ড বাকি না থাকে তবে আপনি রাউন্ডটি জিতেছেন!

রাউন্ড 7-এ, প্রথম যে ব্যক্তি মেল্ড করে তাকে অবশ্যই তার হাত পুরোপুরি শেষ করতে হবে এবং অন্যের মেল্ডে যোগ করতে পারবে না।
',
		'tr': 'Birleştirdikten sonra, birleştirmelerinize veya başkalarınınkine kart eklemeye devam edin. Onaylamak için tekrar "Birleştir!" e dokunun.

1-6. turlarda, atmak için sağ alttaki bir karta dokunarak sıranızı bitirin. Hiç kartınız kalmadıysa, turu kazandınız!

7. turda, ilk birleştiren kişi elini tamamen bitirmeli ve başkalarının birleştirmelerine ekleme yapamaz.
',
		'pl': 'Po zameldowniu kontynuuj dodawanie kart do swoich meldunków lub do meldunków innych. Stuknij ponownie "Meld!", aby potwierdzić.

W rundach 1-6 zakończ swoją turę, dotykając karty w prawym dolnym rogu, aby ją odrzucić. Jeśli nie masz już żadnych kart, wygrałeś rundę!

W rundzie 7 pierwsza osoba, która zamelduje, musi całkowicie zakończyć swoją rękę i nie może dodawać do meldunków innych.
',
		'nl': 'Na het melden, blijf kaarten toevoegen aan je melds of aan die van anderen. Tik nogmaals op "Meld!" om te bevestigen.

In rondes 1-6, beëindig je beurt door op een kaart rechtsonder te tikken om deze af te leggen. Als je geen kaarten meer over hebt, heb je de ronde gewonnen!

In ronde 7 moet de eerste persoon die meldt zijn hand volledig afmaken en kan hij niet toevoegen aan de melds van anderen.
',
		'th': 'หลังจากรวมกลุ่มแล้ว ให้เพิ่มไพ่ลงในกลุ่มของคุณหรือของคนอื่นต่อไป แตะ "รวมกลุ่ม!" อีกครั้งเพื่อยืนยัน

ในรอบที่ 1-6 จบตาของคุณโดยการแตะไพ่ที่มุมล่างขวาเพื่อทิ้ง หากคุณไม่เหลือไพ่แล้ว แสดงว่าคุณชนะในรอบนั้น!

ในรอบที่ 7 ผู้ที่รวมกลุ่มเป็นคนแรกจะต้องจบไพ่ในมือให้หมดและไม่สามารถเพิ่มไพ่ลงในกลุ่มของคนอื่นได้
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
		'ja': '各ラウンド終了後は、ホストが「スコアを集計」をタップしてカードを集計し、スコアを更新します。

そのあと「次のラウンド」を押せば次のラウンドへ。（ラウンド7のあとなら「最終スコア」）

7ラウンドの合計が一番少ない人が優勝！

スコアボードには各ラウンドの点数と最終結果が表示され、3位・2位・1位にはトロフィーも付きます。

終わったら「メインメニュー」を押して、いつでも新しいゲームを始めましょう。
',
		'fr': 'Après chaque manche, l\'hôte tape sur « Compter les scores » pour compter toutes les cartes et mettre à jour les scores.

Ensuite, tape sur « Manche suivante » (ou sur « Scores finaux » après la manche 7).

Après les sept manches, le joueur avec le total le plus bas l\'emporte !

Un tableau s\'affiche avec les scores de chaque manche et le résultat final — avec des trophées pour la 3e, 2e et 1re place.

Quand c\'est fini, tape sur « Menu principal » pour revenir et relancer une partie quand tu veux.
',
		'it': 'Dopo ogni round, l\'host tocca « Calcola Punteggi » per sommare tutte le carte e aggiornare i punteggi.

Poi tocca « Prossimo Round » (o « Punteggi Finali » dopo il round 7).

Dopo i sette round, vince chi ha il totale più basso!

Appare un tabellone con i punteggi di ogni round e il risultato finale, completo di trofei per terzo, secondo e primo posto.

Quando hai finito, tocca « Menu Principale » per tornare indietro e avviare una nuova partita quando vuoi.
',
		'es': 'Al final de cada ronda, el anfitrión toca « Contar puntos » para sumar las cartas y actualizar los puntos.

Luego toca « Siguiente ronda » (o « Puntos finales » después de la ronda 7).

Tras las siete rondas, gana quien tenga el total más bajo.

Verás un marcador con los puntos de cada ronda y el resultado final, con trofeos para 3.º, 2.º y 1.º lugar.

Cuando terminen, toca « Menú principal » para volver y arrancar otra partida cuando quieras.
',
		'pt': 'Depois de cada rodada, o anfitrião toca « Contar Pontos » para somar as cartas e atualizar os pontos de todo mundo.

Em seguida toque « Próxima Rodada » (ou « Pontuações Finais » depois da rodada 7).

Após as sete rodadas, vence quem tiver o menor total!

Um placar aparece com os pontos de cada rodada e o resultado final — incluindo troféus para 3º, 2º e 1º lugar.

Quando terminar, toque « Menu Principal » para voltar e iniciar outra partida quando quiser.
',
		'ru': 'После каждой раздачи хост нажимает « Подсчитать очки », чтобы подсчитать карты и обновить очки игроков.

Затем жми « Следующий раунд » (или « Итоговые очки » после 7-го раунда).

После всех семи раундов побеждает тот, у кого общий счет минимальный!

Появится таблица с результатами каждого раунда и финальным итогом — с трофеями за 3-е, 2-е и 1-е места.

Когда все закончено, нажми « Главное меню », чтобы вернуться и запустить новую игру в любое время.
',
		'zh-Hans': '每回合结束后，房主会点“计分”把牌面分数相加并更新所有人的积分。

然后点“下一回合”（第 7 回合之后改点“最终分数”）。

七个回合打完后，总分最低的玩家获胜！

榜单会显示每回合的得分和最终结果，还会给第 3、2、1 名配上奖杯。

结束时点“主菜单”，随时可以回到主菜单再开一局。
',
		'zh-Hant': '每回合結束後，房主會點「計分」把牌面分數相加並更新所有人的積分。

然後點「下一回合」（第 7 回合之後改點「最終分數」）。

七個回合打完後，總分最低的玩家獲勝！

榜單會顯示每回合的得分和最終結果，還會給第 3、2、1 名配上獎杯。

結束時點「主選單」，隨時可以回到主選單再開一局。
',
		'ar': 'بعد كل جولة يضغط المضيف على « إحصاء النقاط » لحساب كل الأوراق وتحديث نقاط اللاعبين.

بعدها اضغط « الجولة التالية » (أو « النقاط النهائية » بعد الجولة السابعة).

بعد سبع جولات يفوز من لديه أقل مجموع!

ستظهر لوحة نتائج تعرض نقاط كل جولة والنتيجة النهائية، مع كؤوس للمركز الثالث والثاني والأول.

عندما تنتهي، اضغط « القائمة الرئيسية » للعودة وبدء لعبة جديدة في أي وقت.
',
		'ko': '라운드가 끝날 때마다 호스트가 « 점수 집계 »를 눌러 모든 카드를 합산하고 점수를 갱신해요.

그다음 « 다음 라운드 »를 누르세요. 7라운드가 끝났다면 « 최종 점수 »를 누르면 됩니다.

일곱 라운드가 끝났을 때 총점이 제일 낮은 사람이 우승!

라운드별 점수와 최종 결과가 표시되는 점수판이 뜨고, 3등·2등·1등에게 트로피도 붙어요.

다 끝나면 « 메인 메뉴 »를 눌러 돌아가고, 언제든 새 게임을 시작하세요.
',
		'he': 'אחרי כל סיבוב המארח לוחץ על « ספירת נקודות » כדי לסכם את הקלפים ולעדכן את הניקוד של כולם.

אחר כך לוחצים על « סיבוב הבא » (או על « תוצאות סופיות » אחרי סיבוב 7).

בסוף שבעת הסיבובים מנצח מי שסך הנקודות שלו הנמוך ביותר!

תופיע טבלת ניקוד עם תוצאות כל הסיבובים והגמר — כולל גביעים למקום שלישי, שני וראשון.

כשתסיימו, לחצו על « תפריט ראשי » כדי לחזור ולפתוח משחק חדש מתי שרוצים.
',
		'hi': 'प्रत्येक दौर के बाद, मेजबान सभी कार्डों को जोड़ने और प्रत्येक खिलाड़ी के स्कोर को अपडेट करने के लिए "स्कोर टैली करें" पर टैप करता है।

फिर "अगला दौर" (या दौर 7 के बाद "अंतिम स्कोर") पर टैप करें।

सभी सात दौरों के बाद, सबसे कम कुल वाला खिलाड़ी जीतता है!

एक स्कोरबोर्ड प्रत्येक दौर के स्कोर और अंतिम परिणामों के साथ दिखाई देता है - तीसरे, दूसरे और पहले स्थान के लिए ट्रॉफी के साथ पूरा।

जब आप समाप्त कर लें, तो वापस जाने के लिए "मुख्य मेनू" पर टैप करें और किसी भी समय एक नया गेम शुरू करें।
',
		'id': 'Setelah setiap putaran, tuan rumah mengetuk "Tally Skor" untuk menjumlahkan semua kartu dan memperbarui skor setiap pemain.

Kemudian ketuk "Putaran Berikutnya" (atau "Skor Akhir" setelah putaran 7).

Setelah tujuh putaran, pemain dengan total terendah menang!

Papan skor muncul dengan skor setiap putaran dan hasil akhir — lengkap dengan piala untuk juara ke-3, ke-2, dan ke-1.

Setelah selesai, ketuk "Menu Utama" untuk kembali dan memulai permainan baru kapan saja.
',
		'bn': 'প্রতিটি রাউন্ডের পরে, হোস্ট সমস্ত কার্ডের যোগফল এবং প্রতিটি খেলোয়াড়ের স্কোর আপডেট করতে "স্কোর গণনা করুন" এ ট্যাপ করে।

তারপরে "পরবর্তী রাউন্ড" (বা রাউন্ড 7 এর পরে "চূড়ান্ত স্কোর") এ আলতো চাপুন।

সাতটি রাউন্ডের পরে, সর্বনিম্ন মোট সহ খেলোয়াড় জয়ী হয়!

একটি স্কোরবোর্ড প্রতিটি রাউন্ডের স্কোর এবং চূড়ান্ত ফলাফল সহ উপস্থিত হয় — ৩য়, ২য় এবং ১ম স্থানের জন্য ট্রফি সহ সম্পূর্ণ।

আপনি যখন শেষ করেন, ফিরে যেতে "প্রধান মেনু" তে আলতো চাপুন এবং যেকোনো সময় একটি নতুন গেম শুরু করুন।
',
		'tr': 'Her turdan sonra, ev sahibi tüm kartları toplamak ve her oyuncunun puanını güncellemek için "Puanları Say" a dokunur.

Ardından "Sonraki Tur" a (veya 7. turdan sonra "Nihai Puanlar" a) dokunun.

Yedi turun ardından en düşük toplam puana sahip oyuncu kazanır!

Her turun puanlarını ve nihai sonuçları içeren bir puan tablosu belirir — 3., 2. ve 1.lik için kupalarla tamamlanır.

Bitirdiğinizde, geri dönmek ve istediğiniz zaman yeni bir oyuna başlamak için "Ana Menü" ye dokunun.
',
		'pl': 'Po każdej rundzie gospodarz dotyka "Podlicz wyniki", aby zsumować wszystkie karty i zaktualizować wynik każdego gracza.

Następnie dotknij "Następna runda" (lub "Wyniki końcowe" po rundzie 7).

Po siedmiu rundach wygrywa gracz z najniższym łącznym wynikiem!

Pojawi się tablica wyników z wynikami każdej rundy i wynikami końcowymi — wraz z trofeami za 3., 2. i 1. miejsce.

Gdy skończysz, dotknij "Menu główne", aby wrócić i rozpocząć nową grę w dowolnym momencie.
',
		'nl': 'Na elke ronde tikt de host op "Scores tellen" om alle kaarten op te tellen en de score van elke speler bij te werken.

Tik vervolgens op "Volgende ronde" (of "Eindscores" na ronde 7).

Na alle zeven rondes wint de speler met de laagste totaalscore!

Er verschijnt een scorebord met de scores van elke ronde en de eindresultaten — compleet met trofeeën voor de 3e, 2e en 1e plaats.

Als je klaar bent, tik je op "Hoofdmenu" om terug te gaan en op elk moment een nieuw spel te starten.
',
		'th': 'หลังจากแต่ละรอบ โฮสต์จะแตะ "นับคะแนน" เพื่อรวมไพ่ทั้งหมดและอัปเดตคะแนนของผู้เล่นแต่ละคน

จากนั้นแตะ "รอบถัดไป" (หรือ "คะแนนสุดท้าย" หลังจากรอบที่ 7)

หลังจากเจ็ดรอบ ผู้เล่นที่มีคะแนนรวมต่ำที่สุดจะเป็นผู้ชนะ!

ป้ายคะแนนจะปรากฏขึ้นพร้อมกับคะแนนของแต่ละรอบและผลลัพธ์สุดท้าย — พร้อมถ้วยรางวัลสำหรับอันดับที่ 3, 2 และ 1

เมื่อคุณทำเสร็จแล้ว ให้แตะ "เมนูหลัก" เพื่อย้อนกลับและเริ่มเกมใหม่ได้ทุกเมื่อ
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
		'zh-Hans': '每回合都有两个实用的小按钮。

左上角的按钮可以切换牌背样式。

右上角点一下“?”，就能打开 Moonridge Rummy 的快速规则说明。

就这些啦——准备好开玩吧！无论单人还是和朋友一起玩，都祝你好运！
',
		'zh-Hant': '每回合都有兩個實用的小按鈕。

左上角的按鈕可以切換牌背樣式。

右上角點一下「?」，就能打開 Moonridge Rummy 的快速規則說明。

就這些啦——準備好開玩吧！無論單人還是和朋友一起玩，都祝你好運！
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
		'hi': 'हर दौर में दो सहायक बटन होते हैं।

ऊपरी-बाएँ कोने में, अपने कार्ड के पिछले डिज़ाइन को बदलने के लिए बटन पर टैप करें।

ऊपरी-दाएँ कोने में, मूनरिज रम्मी के नियमों के साथ एक त्वरित सहायता स्क्रीन खोलने के लिए "?" पर टैप करें।

बस इतना ही - आप खेलने के लिए तैयार हैं! अकेले या दोस्तों के साथ मूनरिज रम्मी खेलने का मज़ा लें, और शुभकामनाएँ!
',
		'id': 'Setiap putaran memiliki dua tombol yang membantu.

Di sudut kiri atas, ketuk tombol untuk mengubah desain belakang kartu Anda.

Di sudut kanan atas, ketuk "?" untuk membuka layar bantuan cepat dengan aturan Moonridge Rummy.

Itu saja — Anda siap bermain! Bersenang-senang bermain Moonridge Rummy sendirian atau bersama teman, dan semoga berhasil!
',
		'bn': 'প্রতিটি রাউন্ডে দুটি সহায়ক বোতাম রয়েছে।

উপরের-বাম কোণে, আপনার কার্ডের পিছনের নকশা পরিবর্তন করতে বোতামটিতে আলতো চাপুন।

উপরের-ডান কোণে, মুনরিজ রামি-এর নিয়মাবলী সহ একটি দ্রুত সহায়তা স্ক্রিন খুলতে "?" এ আলতো চাপুন।

এটাই — আপনি খেলতে প্রস্তুত! একা বা বন্ধুদের সাথে মুনরিজ রামি খেলতে মজা নিন, এবং সৌভাগ্য!
',
		'tr': 'Her turda iki yardımcı düğme bulunur.

Sol üst köşede, kartınızın arka tasarımını değiştirmek için düğmeye dokunun.

Sağ üst köşede, Moonridge Rummy kurallarıyla hızlı bir yardım ekranı açmak için "?" simgesine dokunun.

İşte bu kadar — oynamaya hazırsınız! Moonridge Rummy\'yi tek başınıza veya arkadaşlarınızla oynarken iyi eğlenceler ve iyi şanslar!
',
		'pl': 'Każda runda ma dwa pomocne przyciski.

W lewym górnym rogu dotknij przycisku, aby zmienić wygląd rewersu karty.

W prawym górnym rogu dotknij "?", aby otworzyć ekran szybkiej pomocy z zasadami gry Moonridge Rummy.

To wszystko — jesteś gotowy do gry! Baw się dobrze grając w Moonridge Rummy solo lub z przyjaciółmi i powodzenia!
',
		'nl': 'Elke ronde heeft twee handige knoppen.

Tik in de linkerbovenhoek op de knop om het ontwerp van de achterkant van je kaart te wijzigen.

Tik in de rechterbovenhoek op "?" om een snel helpscherm te openen met de regels van Moonridge Rummy.

Dat is alles — je bent klaar om te spelen! Veel plezier met het spelen van Moonridge Rummy, alleen of met vrienden, en veel geluk!
',
		'th': 'แต่ละรอบมีปุ่มที่เป็นประโยชน์สองปุ่ม

ที่มุมซ้ายบน แตะปุ่มเพื่อเปลี่ยนดีไซน์หลังไพ่ของคุณ

ที่มุมขวาบน แตะ "?" เพื่อเปิดหน้าจอช่วยเหลือด่วนพร้อมกฎของ Moonridge Rummy

เพียงเท่านี้ — คุณก็พร้อมที่จะเล่นแล้ว! ขอให้สนุกกับการเล่น Moonridge Rummy คนเดียวหรือกับเพื่อน ๆ และขอให้โชคดี!
',
	},
]
