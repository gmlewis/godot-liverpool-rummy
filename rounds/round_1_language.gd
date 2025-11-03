extends Control

func _ready() -> void:
	match Global.LANGUAGE:
		'ar':
			$RoundLabel.text = 'الجولة 1: كتابان (6 بطاقات)'
			$MeldArea/Book1/Book1Label.text = 'كتاب 1'
			$MeldArea/Book2/Book2Label.text = 'كتاب 2'
		'bn':
			$RoundLabel.text = 'রাউন্ড 1: দুটি বই (6টি কার্ড)'
			$MeldArea/Book1/Book1Label.text = 'বই 1'
			$MeldArea/Book2/Book2Label.text = 'বই 2'
		'de':
			$RoundLabel.text = 'Runde 1: Zwei Drillinge (6 Karten)'
			$MeldArea/Book1/Book1Label.text = 'Drilling 1'
			$MeldArea/Book2/Book2Label.text = 'Drilling 2'
		'es':
			$RoundLabel.text = 'Ronda 1: Dos tríos (6 cartas)'
			$MeldArea/Book1/Book1Label.text = 'Trío 1'
			$MeldArea/Book2/Book2Label.text = 'Trío 2'
		'fr':
			$RoundLabel.text = 'Manche 1 : Deux brelans (6 cartes)'
			$MeldArea/Book1/Book1Label.text = 'Brelan 1'
			$MeldArea/Book2/Book2Label.text = 'Brelan 2'
		'he':
			$RoundLabel.text = 'סיבוב 1: שני ספרים (6 קלפים)'
			$MeldArea/Book1/Book1Label.text = 'ספר 1'
			$MeldArea/Book2/Book2Label.text = 'ספר 2'
		'hi':
			$RoundLabel.text = 'राउंड 1: दो किताबें (6 कार्ड)'
			$MeldArea/Book1/Book1Label.text = 'किताब 1'
			$MeldArea/Book2/Book2Label.text = 'किताब 2'
		'id':
			$RoundLabel.text = 'Ronde 1: Dua Buku (6 kartu)'
			$MeldArea/Book1/Book1Label.text = 'Buku 1'
			$MeldArea/Book2/Book2Label.text = 'Buku 2'
		'it':
			$RoundLabel.text = 'Round 1: Due tris (6 carte)'
			$MeldArea/Book1/Book1Label.text = 'Tris 1'
			$MeldArea/Book2/Book2Label.text = 'Tris 2'
		'ja':
			$RoundLabel.text = 'ラウンド1：ブック2組（6枚）'
			$MeldArea/Book1/Book1Label.text = 'ブック1'
			$MeldArea/Book2/Book2Label.text = 'ブック2'
		'ko':
			$RoundLabel.text = '라운드 1: 북 2개 (카드 6장)'
			$MeldArea/Book1/Book1Label.text = '북 1'
			$MeldArea/Book2/Book2Label.text = '북 2'
		'nl':
			$RoundLabel.text = 'Ronde 1: Twee Boeken (6 kaarten)'
			$MeldArea/Book1/Book1Label.text = 'Boek 1'
			$MeldArea/Book2/Book2Label.text = 'Boek 2'
		'pl':
			$RoundLabel.text = 'Runda 1: Dwie książki (6 kart)'
			$MeldArea/Book1/Book1Label.text = 'Książka 1'
			$MeldArea/Book2/Book2Label.text = 'Książka 2'
		'pt':
			$RoundLabel.text = 'Rodada 1: Dois Livros (6 cartas)'
			$MeldArea/Book1/Book1Label.text = 'Livro 1'
			$MeldArea/Book2/Book2Label.text = 'Livro 2'
		'ru':
			$RoundLabel.text = 'Раунд 1: Две книги (6 карт)'
			$MeldArea/Book1/Book1Label.text = 'Книга 1'
			$MeldArea/Book2/Book2Label.text = 'Книга 2'
		'th':
			$RoundLabel.text = 'รอบที่ 1: หนังสือสองเล่ม (6 ใบ)'
			$MeldArea/Book1/Book1Label.text = 'หนังสือ 1'
			$MeldArea/Book2/Book2Label.text = 'หนังสือ 2'
		'tr':
			$RoundLabel.text = 'Tur 1: İki Kitap (6 kart)'
			$MeldArea/Book1/Book1Label.text = 'Kitap 1'
			$MeldArea/Book2/Book2Label.text = 'Kitap 2'
		'zh-Hans':
			$RoundLabel.text = '第 1 回合：两本书（6 张牌）'
			$MeldArea/Book1/Book1Label.text = '书 1'
			$MeldArea/Book2/Book2Label.text = '书 2'
		'zh-Hant':
			$RoundLabel.text = '第 1 回合：兩本書（6 張牌）'
			$MeldArea/Book1/Book1Label.text = '書 1'
			$MeldArea/Book2/Book2Label.text = '書 2'
		_:
			pass

func _exit_tree() -> void:
	pass
