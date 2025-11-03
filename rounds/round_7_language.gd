extends Control

func _ready() -> void:
	match Global.LANGUAGE:
		'ar':
			$RoundLabel.text = 'الجولة 7: ثلاث جولات من 4 (12 بطاقة - لا يوجد تجاهل)'
			$MeldArea/Run1/Run1Label.text = 'تشغيل 1'
			$MeldArea/Run2/Run2Label.text = 'تشغيل 2'
			$MeldArea/Run3/Run3Label.text = 'تشغيل 3'
		'bn':
			$RoundLabel.text = 'রাউন্ড 7: তিনটি 4-এর রান (12টি কার্ড - কোনো বাতিল নয়)'
			$MeldArea/Run1/Run1Label.text = 'রান 1'
			$MeldArea/Run2/Run2Label.text = 'রান 2'
			$MeldArea/Run3/Run3Label.text = 'রান 3'
		'de':
			$RoundLabel.text = 'Runde 7: Drei Vierer-Straßen (12 Karten - kein Abwurf)'
			$MeldArea/Run1/Run1Label.text = 'Straße 1'
			$MeldArea/Run2/Run2Label.text = 'Straße 2'
			$MeldArea/Run3/Run3Label.text = 'Straße 3'
		'es':
			$RoundLabel.text = 'Ronda 7: Tres escaleras de 4 (12 cartas - sin descarte)'
			$MeldArea/Run1/Run1Label.text = 'Escalera 1'
			$MeldArea/Run2/Run2Label.text = 'Escalera 2'
			$MeldArea/Run3/Run3Label.text = 'Escalera 3'
		'fr':
			$RoundLabel.text = 'Manche 7 : Trois suites de 4 (12 cartes - pas de défausse)'
			$MeldArea/Run1/Run1Label.text = 'Suite 1'
			$MeldArea/Run2/Run2Label.text = 'Suite 2'
			$MeldArea/Run3/Run3Label.text = 'Suite 3'
		'he':
			$RoundLabel.text = 'סיבוב 7: שלוש ריצות של 4 (12 קלפים - אין השלכה)'
			$MeldArea/Run1/Run1Label.text = 'ריצה 1'
			$MeldArea/Run2/Run2Label.text = 'ריצה 2'
			$MeldArea/Run3/Run3Label.text = 'ריצה 3'
		'hi':
			$RoundLabel.text = 'राउंड 7: 4 के तीन रन (12 कार्ड - कोई डिस्कार्ड नहीं)'
			$MeldArea/Run1/Run1Label.text = 'रन 1'
			$MeldArea/Run2/Run2Label.text = 'रन 2'
			$MeldArea/Run3/Run3Label.text = 'रन 3'
		'id':
			$RoundLabel.text = 'Ronde 7: Tiga Seri 4 (12 kartu - tanpa buangan)'
			$MeldArea/Run1/Run1Label.text = 'Seri 1'
			$MeldArea/Run2/Run2Label.text = 'Seri 2'
			$MeldArea/Run3/Run3Label.text = 'Seri 3'
		'it':
			$RoundLabel.text = 'Round 7: Tre scale di 4 (12 carte - nessuno scarto)'
			$MeldArea/Run1/Run1Label.text = 'Scala 1'
			$MeldArea/Run2/Run2Label.text = 'Scala 2'
			$MeldArea/Run3/Run3Label.text = 'Scala 3'
		'ja':
			$RoundLabel.text = 'ラウンド7：4枚のラン3組（12枚 - 捨て札なし）'
			$MeldArea/Run1/Run1Label.text = 'ラン1'
			$MeldArea/Run2/Run2Label.text = 'ラン2'
			$MeldArea/Run3/Run3Label.text = 'ラン3'
		'ko':
			$RoundLabel.text = '라운드 7: 4장짜리 런 3개(12장 - 버리기 없음)'
			$MeldArea/Run1/Run1Label.text = '런 1'
			$MeldArea/Run2/Run2Label.text = '런 2'
			$MeldArea/Run3/Run3Label.text = '런 3'
		'nl':
			$RoundLabel.text = 'Ronde 7: Drie Runs van 4 (12 kaarten - niet afleggen)'
			$MeldArea/Run1/Run1Label.text = 'Run 1'
			$MeldArea/Run2/Run2Label.text = 'Run 2'
			$MeldArea/Run3/Run3Label.text = 'Run 3'
		'pl':
			$RoundLabel.text = 'Runda 7: Trzy biegi po 4 (12 kart - bez odrzucania)'
			$MeldArea/Run1/Run1Label.text = 'Bieg 1'
			$MeldArea/Run2/Run2Label.text = 'Bieg 2'
			$MeldArea/Run3/Run3Label.text = 'Bieg 3'
		'pt':
			$RoundLabel.text = 'Rodada 7: Três Corridas de 4 (12 cartas - sem descarte)'
			$MeldArea/Run1/Run1Label.text = 'Corrida 1'
			$MeldArea/Run2/Run2Label.text = 'Corrida 2'
			$MeldArea/Run3/Run3Label.text = 'Corrida 3'
		'ru':
			$RoundLabel.text = 'Раунд 7: Три ряда по 4 (12 карт - без сброса)'
			$MeldArea/Run1/Run1Label.text = 'Ряд 1'
			$MeldArea/Run2/Run2Label.text = 'Ряд 2'
			$MeldArea/Run3/Run3Label.text = 'Ряд 3'
		'th':
			$RoundLabel.text = 'รอบที่ 7: วิ่ง 4 สามครั้ง (12 ใบ - ไม่มีการทิ้ง)'
			$MeldArea/Run1/Run1Label.text = 'วิ่ง 1'
			$MeldArea/Run2/Run2Label.text = 'วิ่ง 2'
			$MeldArea/Run3/Run3Label.text = 'วิ่ง 3'
		'tr':
			$RoundLabel.text = 'Tur 7: Üç 4\'lü Koşu (12 kart - atma yok)'
			$MeldArea/Run1/Run1Label.text = 'Koşu 1'
			$MeldArea/Run2/Run2Label.text = 'Koşu 2'
			$MeldArea/Run3/Run3Label.text = 'Koşu 3'
		'zh-Hans':
			$RoundLabel.text = '第 7 回合：三个 4 张的顺子（12 张牌 - 无弃牌）'
			$MeldArea/Run1/Run1Label.text = '顺子 1'
			$MeldArea/Run2/Run2Label.text = '顺子 2'
			$MeldArea/Run3/Run3Label.text = '顺子 3'
		'zh-Hant':
			$RoundLabel.text = '第 7 回合：三個 4 張的順子（12 張牌 - 無棄牌）'
			$MeldArea/Run1/Run1Label.text = '順子 1'
			$MeldArea/Run2/Run2Label.text = '順子 2'
			$MeldArea/Run3/Run3Label.text = '順子 3'
		_:
			pass

func _exit_tree() -> void:
	pass
