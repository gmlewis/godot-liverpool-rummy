extends Control

func _ready() -> void:
	match Global.LANGUAGE:
		'ar':
			$RoundLabel.text = 'الجولة 5: مجموعتان من 3 وجولة من 4 (10 بطاقات)'
			$MeldArea/Book1/Book1Label.text = 'المجموعة 1'
			$MeldArea/Book2/Book2Label.text = 'المجموعة 2'
			$MeldArea/Run1/Run1Label.text = 'تشغيل 1'
		'bn':
			$RoundLabel.text = 'রাউন্ড 5: দুটি 3-এর সেট এবং একটি 4-এর রান (10টি কার্ড)'
			$MeldArea/Book1/Book1Label.text = 'সেট 1'
			$MeldArea/Book2/Book2Label.text = 'সেট 2'
			$MeldArea/Run1/Run1Label.text = 'রান 1'
		'de':
			$RoundLabel.text = 'Runde 5: Zwei Drillinge und eine Vierer-Straße (10 Karten)'
			$MeldArea/Book1/Book1Label.text = 'Drilling 1'
			$MeldArea/Book2/Book2Label.text = 'Drilling 2'
			$MeldArea/Run1/Run1Label.text = 'Straße 1'
		'es':
			$RoundLabel.text = 'Ronda 5: Dos tríos y una escalera de 4 (10 cartas)'
			$MeldArea/Book1/Book1Label.text = 'Trío 1'
			$MeldArea/Book2/Book2Label.text = 'Trío 2'
			$MeldArea/Run1/Run1Label.text = 'Escalera 1'
		'fr':
			$RoundLabel.text = 'Manche 5 : Deux brelans et une suite de 4 (10 cartes)'
			$MeldArea/Book1/Book1Label.text = 'Brelan 1'
			$MeldArea/Book2/Book2Label.text = 'Brelan 2'
			$MeldArea/Run1/Run1Label.text = 'Suite 1'
		'he':
			$RoundLabel.text = 'סיבוב 5: שתי סדרות של 3 וריצה של 4 (10 קלפים)'
			$MeldArea/Book1/Book1Label.text = 'סדרה 1'
			$MeldArea/Book2/Book2Label.text = 'סדרה 2'
			$MeldArea/Run1/Run1Label.text = 'ריצה 1'
		'hi':
			$RoundLabel.text = 'राउंड 5: 3 के दो सेट और 4 का एक रन (10 कार्ड)'
			$MeldArea/Book1/Book1Label.text = 'सेट 1'
			$MeldArea/Book2/Book2Label.text = 'सेट 2'
			$MeldArea/Run1/Run1Label.text = 'रन 1'
		'id':
			$RoundLabel.text = 'Ronde 5: Dua Set 3 dan Satu Seri 4 (10 kartu)'
			$MeldArea/Book1/Book1Label.text = 'Set 1'
			$MeldArea/Book2/Book2Label.text = 'Set 2'
			$MeldArea/Run1/Run1Label.text = 'Seri 1'
		'it':
			$RoundLabel.text = 'Round 5: Due tris e una scala di 4 (10 carte)'
			$MeldArea/Book1/Book1Label.text = 'Tris 1'
			$MeldArea/Book2/Book2Label.text = 'Tris 2'
			$MeldArea/Run1/Run1Label.text = 'Scala 1'
		'ja':
			$RoundLabel.text = 'ラウンド5：3枚組のセット2組と4枚組のラン1組（10枚）'
			$MeldArea/Book1/Book1Label.text = 'セット1'
			$MeldArea/Book2/Book2Label.text = 'セット2'
			$MeldArea/Run1/Run1Label.text = 'ラン1'
		'ko':
			$RoundLabel.text = '라운드 5: 3장짜리 세트 2개와 4장짜리 런 1개(10장)'
			$MeldArea/Book1/Book1Label.text = '세트 1'
			$MeldArea/Book2/Book2Label.text = '세트 2'
			$MeldArea/Run1/Run1Label.text = '런 1'
		'nl':
			$RoundLabel.text = 'Ronde 5: Twee Sets van 3 en een Run van 4 (10 kaarten)'
			$MeldArea/Book1/Book1Label.text = 'Set 1'
			$MeldArea/Book2/Book2Label.text = 'Set 2'
			$MeldArea/Run1/Run1Label.text = 'Run 1'
		'pl':
			$RoundLabel.text = 'Runda 5: Dwa zestawy po 3 i jeden bieg po 4 (10 kart)'
			$MeldArea/Book1/Book1Label.text = 'Zestaw 1'
			$MeldArea/Book2/Book2Label.text = 'Zestaw 2'
			$MeldArea/Run1/Run1Label.text = 'Bieg 1'
		'pt':
			$RoundLabel.text = 'Rodada 5: Dois Conjuntos de 3 e uma Corrida de 4 (10 cartas)'
			$MeldArea/Book1/Book1Label.text = 'Conjunto 1'
			$MeldArea/Book2/Book2Label.text = 'Conjunto 2'
			$MeldArea/Run1/Run1Label.text = 'Corrida 1'
		'ru':
			$RoundLabel.text = 'Раунд 5: Два набора по 3 и один ряд из 4 (10 карт)'
			$MeldArea/Book1/Book1Label.text = 'Набор 1'
			$MeldArea/Book2/Book2Label.text = 'Набор 2'
			$MeldArea/Run1/Run1Label.text = 'Ряд 1'
		'th':
			$RoundLabel.text = 'รอบที่ 5: สองชุดของ 3 และหนึ่งวิ่งของ 4 (10 ใบ)'
			$MeldArea/Book1/Book1Label.text = 'ชุดที่ 1'
			$MeldArea/Book2/Book2Label.text = 'ชุดที่ 2'
			$MeldArea/Run1/Run1Label.text = 'วิ่ง 1'
		'tr':
			$RoundLabel.text = 'Tur 5: İki 3\'lü Set ve bir 4\'lü Koşu (10 kart)'
			$MeldArea/Book1/Book1Label.text = 'Set 1'
			$MeldArea/Book2/Book2Label.text = 'Set 2'
			$MeldArea/Run1/Run1Label.text = 'Koşu 1'
		'zh-Hans':
			$RoundLabel.text = '第 5 回合：两个 3 张的套牌和一个 4 张的顺子（10 张牌）'
			$MeldArea/Book1/Book1Label.text = '套牌 1'
			$MeldArea/Book2/Book2Label.text = '套牌 2'
			$MeldArea/Run1/Run1Label.text = '顺子 1'
		'zh-Hant':
			$RoundLabel.text = '第 5 回合：兩個 3 張的套牌和一個 4 張的順子（10 張牌）'
			$MeldArea/Book1/Book1Label.text = '套牌 1'
			$MeldArea/Book2/Book2Label.text = '套牌 2'
			$MeldArea/Run1/Run1Label.text = '順子 1'
		_:
			pass

func _exit_tree() -> void:
	pass
