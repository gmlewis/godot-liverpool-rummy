extends Control

func _ready() -> void:
	Global.dbg('Options: ENTER')
	match Global.LANGUAGE:
		'de':
			$RoundLabel.text = 'Optionen'
			$GracePeriodLabel.text = 'Nachlass-Zeit'
		_:
			pass

func _exit_tree() -> void:
	Global.dbg('Options: LEAVE')
