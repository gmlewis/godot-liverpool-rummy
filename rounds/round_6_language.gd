extends Control

func _ready() -> void:
	match Global.LANGUAGE:
		'ar':
			$RoundLabel.text = 'الجولة 6: مجموعة واحدة من 3 وجولتين من 4 (11 بطاقة)'
			$MeldArea/Book1/Book1Label.text = 'المجموعة 1'
			$MeldArea/Run1/Run1Label.text = 'تشغيل 1'
			$MeldArea/Run2/Run2Label.text = 'تشغيل 2'
		'bn':
			$RoundLabel.text = 'রাউন্ড 6: একটি 3-এর সেট এবং দুটি 4-এর রান (11টি কার্ড)'
			$MeldArea/Book1/Book1Label.text = 'সেট 1'
			$MeldArea/Run1/Run1Label.text = 'রান 1'
			$MeldArea/Run2/Run2Label.text = 'রান 2'
		'de':
			$RoundLabel.text = 'Runde 6: Ein Drilling und zwei Vierer-Straßen (11 Karten)'
			$MeldArea/Book1/Book1Label.text = 'Drilling 1'
			$MeldArea/Run1/Run1Label.text = 'Straße 1'
			$MeldArea/Run2/Run2Label.text = 'Straße 2'
		'es':
			$RoundLabel.text = 'Ronda 6: Un trío y dos escaleras de 4 (11 cartas)'
			$MeldArea/Book1/Book1Label.text = 'Trío 1'
			$MeldArea/Run1/Run1Label.text = 'Escalera 1'
			$MeldArea/Run2/Run2Label.text = 'Escalera 2'
		'fr':
			$RoundLabel.text = 'Manche 6 : Un brelan et deux suites de 4 (11 cartes)'
			$MeldArea/Book1/Book1Label.text = 'Brelan 1'
			$MeldArea/Run1/Run1Label.text = 'Suite 1'
			$MeldArea/Run2/Run2Label.text = 'Suite 2'
		'he':
			$RoundLabel.text = 'סיבוב 6: סדרה אחת של 3 ושתי ריצות של 4 (11 קלפים)'
			$MeldArea/Book1/Book1Label.text = 'סדרה 1'
			$MeldArea/Run1/Run1Label.text = 'ריצה 1'
			$MeldArea/Run2/Run2Label.text = 'ריצה 2'
		'hi':
			$RoundLabel.text = 'राउंड 6: 3 का एक सेट और 4 के दो रन (11 कार्ड)'
			$MeldArea/Book1/Book1Label.text = 'सेट 1'
			$MeldArea/Run1/Run1Label.text = 'रन 1'
			$MeldArea/Run2/Run2Label.text = 'रन 2'
		'id':
			$RoundLabel.text = 'Ronde 6: Satu Set 3 dan dua Seri 4 (11 kartu)'
			$MeldArea/Book1/Book1Label.text = 'Set 1'
			$MeldArea/Run1/Run1Label.text = 'Seri 1'
			$MeldArea/Run2/Run2Label.text = 'Seri 2'
		'it':
			$RoundLabel.text = 'Round 6: Un tris e due scale di 4 (11 carte)'
			$MeldArea/Book1/Book1Label.text = 'Tris 1'
			$MeldArea/Run1/Run1Label.text = 'Scala 1'
			$MeldArea/Run2/Run2Label.text = 'Scala 2'
		'ja':
			$RoundLabel.text = 'ラウンド6：3枚組のセット1組と4枚組のラン2組（11枚）'
			$MeldArea/Book1/Book1Label.text = 'セット1'
			$MeldArea/Run1/Run1Label.text = 'ラン1'
			$MeldArea/Run2/Run2Label.text = 'ラン2'
		'ko':
			$RoundLabel.text = '라운드 6: 3장짜리 세트 1개와 4장짜리 런 2개(11장)'
			$MeldArea/Book1/Book1Label.text = '세트 1'
			$MeldArea/Run1/Run1Label.text = '런 1'
			$MeldArea/Run2/Run2Label.text = '런 2'
		'nl':
			$RoundLabel.text = 'Ronde 6: Eén Set van 3 en twee Runs van 4 (11 kaarten)'
			$MeldArea/Book1/Book1Label.text = 'Set 1'
			$MeldArea/Run1/Run1Label.text = 'Run 1'
			$MeldArea/Run2/Run2Label.text = 'Run 2'
		'pl':
			$RoundLabel.text = 'Runda 6: Jeden zestaw 3 i dwa biegi po 4 (11 kart)'
			$MeldArea/Book1/Book1Label.text = 'Zestaw 1'
			$MeldArea/Run1/Run1Label.text = 'Bieg 1'
			$MeldArea/Run2/Run2Label.text = 'Bieg 2'
		'pt':
			$RoundLabel.text = 'Rodada 6: Um Conjunto de 3 e duas Corridas de 4 (11 cartas)'
			$MeldArea/Book1/Book1Label.text = 'Conjunto 1'
			$MeldArea/Run1/Run1Label.text = 'Corrida 1'
			$MeldArea/Run2/Run2Label.text = 'Corrida 2'
		'ru':
			$RoundLabel.text = 'Раунд 6: Один набор из 3 и два ряда по 4 (11 карт)'
			$MeldArea/Book1/Book1Label.text = 'Набор 1'
			$MeldArea/Run1/Run1Label.text = 'Ряд 1'
			$MeldArea/Run2/Run2Label.text = 'Ряд 2'
		'th':
			$RoundLabel.text = 'รอบที่ 6: หนึ่งชุดของ 3 และสองวิ่งของ 4 (11 ใบ)'
			$MeldArea/Book1/Book1Label.text = 'ชุดที่ 1'
			$MeldArea/Run1/Run1Label.text = 'วิ่ง 1'
			$MeldArea/Run2/Run2Label.text = 'วิ่ง 2'
		'tr':
			$RoundLabel.text = 'Tur 6: Bir 3\'lü Set ve iki 4\'lü Koşu (11 kart)'
			$MeldArea/Book1/Book1Label.text = 'Set 1'
			$MeldArea/Run1/Run1Label.text = 'Koşu 1'
			$MeldArea/Run2/Run2Label.text = 'Koşu 2'
		'zh-Hans':
			$RoundLabel.text = '第 6 回合：一个 3 张的套牌和两个 4 张的顺子（11 张牌）'
			$MeldArea/Book1/Book1Label.text = '套牌 1'
			$MeldArea/Run1/Run1Label.text = '顺子 1'
			$MeldArea/Run2/Run2Label.text = '顺子 2'
		'zh-Hant':
			$RoundLabel.text = '第 6 回合：一個 3 張的套牌和兩個 4 張的順子（11 張牌）'
			$MeldArea/Book1/Book1Label.text = '套牌 1'
			$MeldArea/Run1/Run1Label.text = '順子 1'
			$MeldArea/Run2/Run2Label.text = '順子 2'
		_:
			pass

func _exit_tree() -> void:
	pass
