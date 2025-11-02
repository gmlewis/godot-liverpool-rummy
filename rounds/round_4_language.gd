extends Control

func _ready() -> void:
	match Global.LANGUAGE:
		'de':
			$RoundLabel.text = 'Runde 4: Drei Drillinge (9 Karten)'
			$MeldArea/Book1/Book1Label.text = 'Drilling 1'
			$MeldArea/Book2/Book2Label.text = 'Drilling 2'
			$MeldArea/Book3/Book3Label.text = 'Drilling 3'
		_:
			pass

func _exit_tree() -> void:
	pass
