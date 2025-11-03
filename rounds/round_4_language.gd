extends Control

func _ready() -> void:
	match Global.LANGUAGE:
		'ar':
			$RoundLabel.text = 'الجولة 4: ثلاث مجموعات من 3 (9 بطاقات)'
			$MeldArea/Book1/Book1Label.text = 'المجموعة 1'
			$MeldArea/Book2/Book2Label.text = 'المجموعة 2'
			$MeldArea/Book3/Book3Label.text = 'المجموعة 3'
		'bn':
			$RoundLabel.text = 'রাউন্ড 4: তিনটি 3-এর সেট (9টি কার্ড)'
			$MeldArea/Book1/Book1Label.text = 'সেট 1'
			$MeldArea/Book2/Book2Label.text = 'সেট 2'
			$MeldArea/Book3/Book3Label.text = 'সেট 3'
		'de':
			$RoundLabel.text = 'Runde 4: Drei Drillinge (9 Karten)'
			$MeldArea/Book1/Book1Label.text = 'Drilling 1'
			$MeldArea/Book2/Book2Label.text = 'Drilling 2'
			$MeldArea/Book3/Book3Label.text = 'Drilling 3'
		'es':
			$RoundLabel.text = 'Ronda 4: Tres tríos (9 cartas)'
			$MeldArea/Book1/Book1Label.text = 'Trío 1'
			$MeldArea/Book2/Book2Label.text = 'Trío 2'
			$MeldArea/Book3/Book3Label.text = 'Trío 3'
		'fr':
			$RoundLabel.text = 'Manche 4 : Trois brelans (9 cartes)'
			$MeldArea/Book1/Book1Label.text = 'Brelan 1'
			$MeldArea/Book2/Book2Label.text = 'Brelan 2'
			$MeldArea/Book3/Book3Label.text = 'Brelan 3'
		'he':
			$RoundLabel.text = 'סיבוב 4: שלוש סדרות של 3 (9 קלפים)'
			$MeldArea/Book1/Book1Label.text = 'סדרה 1'
			$MeldArea/Book2/Book2Label.text = 'סדרה 2'
			$MeldArea/Book3/Book3Label.text = 'סדרה 3'
		'hi':
			$RoundLabel.text = 'राउंड 4: 3 के तीन सेट (9 कार्ड)'
			$MeldArea/Book1/Book1Label.text = 'सेट 1'
			$MeldArea/Book2/Book2Label.text = 'सेट 2'
			$MeldArea/Book3/Book3Label.text = 'सेट 3'
		'id':
			$RoundLabel.text = 'Ronde 4: Tiga Set 3 (9 kartu)'
			$MeldArea/Book1/Book1Label.text = 'Set 1'
			$MeldArea/Book2/Book2Label.text = 'Set 2'
			$MeldArea/Book3/Book3Label.text = 'Set 3'
		'it':
			$RoundLabel.text = 'Round 4: Tre tris (9 carte)'
			$MeldArea/Book1/Book1Label.text = 'Tris 1'
			$MeldArea/Book2/Book2Label.text = 'Tris 2'
			$MeldArea/Book3/Book3Label.text = 'Tris 3'
		'ja':
			$RoundLabel.text = 'ラウンド4：3枚組のセット3組（9枚）'
			$MeldArea/Book1/Book1Label.text = 'セット1'
			$MeldArea/Book2/Book2Label.text = 'セット2'
			$MeldArea/Book3/Book3Label.text = 'セット3'
		'ko':
			$RoundLabel.text = '라운드 4: 3장짜리 세트 3개(9장)'
			$MeldArea/Book1/Book1Label.text = '세트 1'
			$MeldArea/Book2/Book2Label.text = '세트 2'
			$MeldArea/Book3/Book3Label.text = '세트 3'
		'nl':
			$RoundLabel.text = 'Ronde 4: Drie Sets van 3 (9 kaarten)'
			$MeldArea/Book1/Book1Label.text = 'Set 1'
			$MeldArea/Book2/Book2Label.text = 'Set 2'
			$MeldArea/Book3/Book3Label.text = 'Set 3'
		'pl':
			$RoundLabel.text = 'Runda 4: Trzy zestawy po 3 (9 kart)'
			$MeldArea/Book1/Book1Label.text = 'Zestaw 1'
			$MeldArea/Book2/Book2Label.text = 'Zestaw 2'
			$MeldArea/Book3/Book3Label.text = 'Zestaw 3'
		'pt':
			$RoundLabel.text = 'Rodada 4: Três Conjuntos de 3 (9 cartas)'
			$MeldArea/Book1/Book1Label.text = 'Conjunto 1'
			$MeldArea/Book2/Book2Label.text = 'Conjunto 2'
			$MeldArea/Book3/Book3Label.text = 'Conjunto 3'
		'ru':
			$RoundLabel.text = 'Раунд 4: Три набора по 3 (9 карт)'
			$MeldArea/Book1/Book1Label.text = 'Набор 1'
			$MeldArea/Book2/Book2Label.text = 'Набор 2'
			$MeldArea/Book3/Book3Label.text = 'Набор 3'
		'th':
			$RoundLabel.text = 'รอบที่ 4: สามชุดของ 3 (9 ใบ)'
			$MeldArea/Book1/Book1Label.text = 'ชุดที่ 1'
			$MeldArea/Book2/Book2Label.text = 'ชุดที่ 2'
			$MeldArea/Book3/Book3Label.text = 'ชุดที่ 3'
		'tr':
			$RoundLabel.text = 'Tur 4: Üç 3\'lü Set (9 kart)'
			$MeldArea/Book1/Book1Label.text = 'Set 1'
			$MeldArea/Book2/Book2Label.text = 'Set 2'
			$MeldArea/Book3/Book3Label.text = 'Set 3'
		'zh-Hans':
			$RoundLabel.text = '第 4 回合：三个 3 张的套牌（9 张牌）'
			$MeldArea/Book1/Book1Label.text = '套牌 1'
			$MeldArea/Book2/Book2Label.text = '套牌 2'
			$MeldArea/Book3/Book3Label.text = '套牌 3'
		'zh-Hant':
			$RoundLabel.text = '第 4 回合：三個 3 張的套牌（9 張牌）'
			$MeldArea/Book1/Book1Label.text = '套牌 1'
			$MeldArea/Book2/Book2Label.text = '套牌 2'
			$MeldArea/Book3/Book3Label.text = '套牌 3'
		_:
			pass

func _exit_tree() -> void:
	pass
