extends Control

func _ready() -> void:
	match Global.LANGUAGE:
		'de':
			$RoundLabel.text = 'Runde 1: Zwei Drillinge (6 Karten)'
			$MeldArea/Book1/Book1Label.text = 'Drilling 1'
			$MeldArea/Book2/Book2Label.text = 'Drilling 2'
		_:
			pass

func _exit_tree() -> void:
	pass
