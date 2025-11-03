extends Control

func _ready() -> void:
	match Global.LANGUAGE:
		'ar':
			$RoundLabel.text = 'الجولة 2: كتاب واحد (3) وتشغيل واحد (4)'
			$MeldArea/Book1/Book1Label.text = 'كتاب 1'
			$MeldArea/Run1/Run1Label.text = 'تشغيل 1'
		'bn':
			$RoundLabel.text = 'রাউন্ড 2: একটি বই (3) এবং একটি রান (4)'
			$MeldArea/Book1/Book1Label.text = 'বই 1'
			$MeldArea/Run1/Run1Label.text = 'রান 1'
		'de':
			$RoundLabel.text = 'Runde 2: Ein Drilling (3) und eine Straße (4)'
			$MeldArea/Book1/Book1Label.text = 'Drilling 1'
			$MeldArea/Run1/Run1Label.text = 'Straße 1'
		'es':
			$RoundLabel.text = 'Ronda 2: Un trío (3) y una escalera (4)'
			$MeldArea/Book1/Book1Label.text = 'Trío 1'
			$MeldArea/Run1/Run1Label.text = 'Escalera 1'
		'fr':
			$RoundLabel.text = 'Manche 2 : Un brelan (3) et une suite (4)'
			$MeldArea/Book1/Book1Label.text = 'Brelan 1'
			$MeldArea/Run1/Run1Label.text = 'Suite 1'
		'he':
			$RoundLabel.text = 'סיבוב 2: ספר אחד (3) וריצה אחת (4)'
			$MeldArea/Book1/Book1Label.text = 'ספר 1'
			$MeldArea/Run1/Run1Label.text = 'ריצה 1'
		'hi':
			$RoundLabel.text = 'राउंड 2: एक किताब (3) और एक रन (4)'
			$MeldArea/Book1/Book1Label.text = 'किताब 1'
			$MeldArea/Run1/Run1Label.text = 'रन 1'
		'id':
			$RoundLabel.text = 'Ronde 2: Satu Buku (3) dan satu Seri (4)'
			$MeldArea/Book1/Book1Label.text = 'Buku 1'
			$MeldArea/Run1/Run1Label.text = 'Seri 1'
		'it':
			$RoundLabel.text = 'Round 2: Un tris (3) e una scala (4)'
			$MeldArea/Book1/Book1Label.text = 'Tris 1'
			$MeldArea/Run1/Run1Label.text = 'Scala 1'
		'ja':
			$RoundLabel.text = 'ラウンド2：ブック1組（3枚）とラン1組（4枚）'
			$MeldArea/Book1/Book1Label.text = 'ブック1'
			$MeldArea/Run1/Run1Label.text = 'ラン1'
		'ko':
			$RoundLabel.text = '라운드 2: 북 1개(3)와 런 1개(4)'
			$MeldArea/Book1/Book1Label.text = '북 1'
			$MeldArea/Run1/Run1Label.text = '런 1'
		'nl':
			$RoundLabel.text = 'Ronde 2: Eén Boek (3) en één Run (4)'
			$MeldArea/Book1/Book1Label.text = 'Boek 1'
			$MeldArea/Run1/Run1Label.text = 'Run 1'
		'pl':
			$RoundLabel.text = 'Runda 2: Jedna książka (3) i jeden bieg (4)'
			$MeldArea/Book1/Book1Label.text = 'Książka 1'
			$MeldArea/Run1/Run1Label.text = 'Bieg 1'
		'pt':
			$RoundLabel.text = 'Rodada 2: Um Livro (3) e uma Corrida (4)'
			$MeldArea/Book1/Book1Label.text = 'Livro 1'
			$MeldArea/Run1/Run1Label.text = 'Corrida 1'
		'ru':
			$RoundLabel.text = 'Раунд 2: Одна книга (3) и один ряд (4)'
			$MeldArea/Book1/Book1Label.text = 'Книга 1'
			$MeldArea/Run1/Run1Label.text = 'Ряд 1'
		'th':
			$RoundLabel.text = 'รอบที่ 2: หนังสือหนึ่งเล่ม (3) และวิ่งหนึ่งครั้ง (4)'
			$MeldArea/Book1/Book1Label.text = 'หนังสือ 1'
			$MeldArea/Run1/Run1Label.text = 'วิ่ง 1'
		'tr':
			$RoundLabel.text = 'Tur 2: Bir Kitap (3) ve bir Koşu (4)'
			$MeldArea/Book1/Book1Label.text = 'Kitap 1'
			$MeldArea/Run1/Run1Label.text = 'Koşu 1'
		'zh-Hans':
			$RoundLabel.text = '第 2 回合：一本书（3）和一个顺子（4）'
			$MeldArea/Book1/Book1Label.text = '书 1'
			$MeldArea/Run1/Run1Label.text = '顺子 1'
		'zh-Hant':
			$RoundLabel.text = '第 2 回合：一本書（3）和一個順子（4）'
			$MeldArea/Book1/Book1Label.text = '書 1'
			$MeldArea/Run1/Run1Label.text = '順子 1'
		_:
			pass

func _exit_tree() -> void:
	pass
