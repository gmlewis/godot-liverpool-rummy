extends Control

func _ready() -> void:
	match Global.LANGUAGE:
		'de':
			$RoundLabel.text = 'Spiel vorbei! – Endstand'
		_:
			pass

func _exit_tree() -> void:
	pass
