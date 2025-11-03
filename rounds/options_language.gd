extends Control

func _ready() -> void:
	Global.dbg('Options: ENTER')
	match Global.LANGUAGE:
		'ar':
			$RoundLabel.text = 'خيارات'
			$GracePeriodLabel.text = 'فترة السماح'
		'bn':
			$RoundLabel.text = 'বিকল্প'
			$GracePeriodLabel.text = 'গ্রেস পিরিয়ড'
		'de':
			$RoundLabel.text = 'Optionen'
			$GracePeriodLabel.text = 'Nachlass-Zeit'
		'es':
			$RoundLabel.text = 'Opciones'
			$GracePeriodLabel.text = 'Período de gracia'
		'fr':
			$RoundLabel.text = 'Options'
			$GracePeriodLabel.text = 'Période de grâce'
		'he':
			$RoundLabel.text = 'אפשרויות'
			$GracePeriodLabel.text = 'תקופת חסד'
		'hi':
			$RoundLabel.text = 'विकल्प'
			$GracePeriodLabel.text = 'रियायती अवधि'
		'id':
			$RoundLabel.text = 'Pilihan'
			$GracePeriodLabel.text = 'Masa Tenggang'
		'it':
			$RoundLabel.text = 'Opzioni'
			$GracePeriodLabel.text = 'Periodo di grazia'
		'ja':
			$RoundLabel.text = 'オプション'
			$GracePeriodLabel.text = '猶予期間'
		'ko':
			$RoundLabel.text = '옵션'
			$GracePeriodLabel.text = '유예 기간'
		'nl':
			$RoundLabel.text = 'Opties'
			$GracePeriodLabel.text = 'Gratieperiode'
		'pl':
			$RoundLabel.text = 'Opcje'
			$GracePeriodLabel.text = 'Okres karencji'
		'pt':
			$RoundLabel.text = 'Opções'
			$GracePeriodLabel.text = 'Período de carência'
		'ru':
			$RoundLabel.text = 'Опции'
			$GracePeriodLabel.text = 'Льготный период'
		'th':
			$RoundLabel.text = 'ตัวเลือก'
			$GracePeriodLabel.text = 'ระยะเวลาผ่อนผัน'
		'tr':
			$RoundLabel.text = 'Seçenekler'
			$GracePeriodLabel.text = 'Yetkisiz Kullanım Süresi'
		'zh-Hans':
			$RoundLabel.text = '选项'
			$GracePeriodLabel.text = '宽限期'
		'zh-Hant':
			$RoundLabel.text = '選項'
			$GracePeriodLabel.text = '寬限期'
		_:
			pass

func _exit_tree() -> void:
	Global.dbg('Options: LEAVE')
