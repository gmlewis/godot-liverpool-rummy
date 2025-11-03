extends Control

func _ready() -> void:
	match Global.LANGUAGE:
		'ar':
			$RoundLabel.text = 'الجولة 3: جولتان من 4 (8 بطاقات)'
			$MeldArea/Run1/Run1Label.text = 'تشغيل 1'
			$MeldArea/Run2/Run2Label.text = 'تشغيل 2'
		'bn':
			$RoundLabel.text = 'রাউন্ড 3: দুটি 4-এর রান (8টি কার্ড)'
			$MeldArea/Run1/Run1Label.text = 'রান 1'
			$MeldArea/Run2/Run2Label.text = 'রান 2'
		'de':
			$RoundLabel.text = 'Runde 3: Zwei Vierer-Straßen (8 Karten)'
			$MeldArea/Run1/Run1Label.text = 'Straße 1'
			$MeldArea/Run2/Run2Label.text = 'Straße 2'
		'es':
			$RoundLabel.text = 'Ronda 3: Dos escaleras de 4 (8 cartas)'
			$MeldArea/Run1/Run1Label.text = 'Escalera 1'
			$MeldArea/Run2/Run2Label.text = 'Escalera 2'
		'fr':
			$RoundLabel.text = 'Manche 3 : Deux suites de 4 (8 cartes)'
			$MeldArea/Run1/Run1Label.text = 'Suite 1'
			$MeldArea/Run2/Run2Label.text = 'Suite 2'
		'he':
			$RoundLabel.text = 'סיבוב 3: שתי ריצות של 4 (8 קלפים)'
			$MeldArea/Run1/Run1Label.text = 'ריצה 1'
			$MeldArea/Run2/Run2Label.text = 'ריצה 2'
		'hi':
			$RoundLabel.text = 'राउंड 3: 4 के दो रन (8 कार्ड)'
			$MeldArea/Run1/Run1Label.text = 'रन 1'
			$MeldArea/Run2/Run2Label.text = 'रन 2'
		'id':
			$RoundLabel.text = 'Ronde 3: Dua Seri 4 (8 kartu)'
			$MeldArea/Run1/Run1Label.text = 'Seri 1'
			$MeldArea/Run2/Run2Label.text = 'Seri 2'
		'it':
			$RoundLabel.text = 'Round 3: Due scale di 4 (8 carte)'
			$MeldArea/Run1/Run1Label.text = 'Scala 1'
			$MeldArea/Run2/Run2Label.text = 'Scala 2'
		'ja':
			$RoundLabel.text = 'ラウンド3：4枚のラン2組（8枚）'
			$MeldArea/Run1/Run1Label.text = 'ラン1'
			$MeldArea/Run2/Run2Label.text = 'ラン2'
		'ko':
			$RoundLabel.text = '라운드 3: 4장짜리 런 2개(8장)'
			$MeldArea/Run1/Run1Label.text = '런 1'
			$MeldArea/Run2/Run2Label.text = '런 2'
		'nl':
			$RoundLabel.text = 'Ronde 3: Twee Runs van 4 (8 kaarten)'
			$MeldArea/Run1/Run1Label.text = 'Run 1'
			$MeldArea/Run2/Run2Label.text = 'Run 2'
		'pl':
			$RoundLabel.text = 'Runda 3: Dwa biegi po 4 (8 kart)'
			$MeldArea/Run1/Run1Label.text = 'Bieg 1'
			$MeldArea/Run2/Run2Label.text = 'Bieg 2'
		'pt':
			$RoundLabel.text = 'Rodada 3: Duas Corridas de 4 (8 cartas)'
			$MeldArea/Run1/Run1Label.text = 'Corrida 1'
			$MeldArea/Run2/Run2Label.text = 'Corrida 2'
		'ru':
			$RoundLabel.text = 'Раунд 3: Два ряда по 4 (8 карт)'
			$MeldArea/Run1/Run1Label.text = 'Ряд 1'
			$MeldArea/Run2/Run2Label.text = 'Ряд 2'
		'th':
			$RoundLabel.text = 'รอบที่ 3: วิ่ง 4 สองครั้ง (8 ใบ)'
			$MeldArea/Run1/Run1Label.text = 'วิ่ง 1'
			$MeldArea/Run2/Run2Label.text = 'วิ่ง 2'
		'tr':
			$RoundLabel.text = 'Tur 3: İki 4\'lü Koşu (8 kart)'
			$MeldArea/Run1/Run1Label.text = 'Koşu 1'
			$MeldArea/Run2/Run2Label.text = 'Koşu 2'
		'zh-Hans':
			$RoundLabel.text = '第 3 回合：两个 4 张的顺子（8 张牌）'
			$MeldArea/Run1/Run1Label.text = '顺子 1'
			$MeldArea/Run2/Run2Label.text = '顺子 2'
		'zh-Hant':
			$RoundLabel.text = '第 3 回合：兩個 4 張的順子（8 張牌）'
			$MeldArea/Run1/Run1Label.text = '順子 1'
			$MeldArea/Run2/Run2Label.text = '順子 2'
		_:
			pass

func _exit_tree() -> void:
	pass
