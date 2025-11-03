extends Control

func _ready() -> void:
	match Global.LANGUAGE:
		'ar':
			$RoundLabel.text = 'انتهت اللعبة! - النتائج النهائية'
		'bn':
			$RoundLabel.text = 'খেলা শেষ! - চূড়ান্ত স্কোর'
		'de':
			$RoundLabel.text = 'Spiel vorbei! – Endstand'
		'es':
			$RoundLabel.text = '¡Juego terminado! - Puntuaciones finales'
		'fr':
			$RoundLabel.text = 'Partie terminée ! - Scores finaux'
		'he':
			$RoundLabel.text = 'המשחק נגמר! - תוצאות סופיות'
		'hi':
			$RoundLabel.text = 'खेल खत्म! - अंतिम स्कोर'
		'id':
			$RoundLabel.text = 'Permainan Selesai! - Skor Akhir'
		'it':
			$RoundLabel.text = 'Partita finita! - Punteggi finali'
		'ja':
			$RoundLabel.text = 'ゲーム終了！ - 最終スコア'
		'ko':
			$RoundLabel.text = '게임 종료! - 최종 점수'
		'nl':
			$RoundLabel.text = 'Spel voorbij! - Eindscores'
		'pl':
			$RoundLabel.text = 'Koniec gry! - Końcowe wyniki'
		'pt':
			$RoundLabel.text = 'Fim de jogo! - Pontuações finais'
		'ru':
			$RoundLabel.text = 'Игра окончена! - Итоговые очки'
		'th':
			$RoundLabel.text = 'จบเกม! - คะแนนสุดท้าย'
		'tr':
			$RoundLabel.text = 'Oyun Bitti! - Final Skorları'
		'zh-Hans':
			$RoundLabel.text = '游戏结束！ - 最终得分'
		'zh-Hant':
			$RoundLabel.text = '遊戲結束！ - 最終得分'
		_:
			pass

func _exit_tree() -> void:
	pass
