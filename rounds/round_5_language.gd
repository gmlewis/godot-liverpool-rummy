extends Control

func _ready() -> void:
	match Global.LANGUAGE:
		'de':
			$RoundLabel.text = 'Runde 5: Zwei Drillinge (je 3) und eine Straße (4)'
			$MeldArea/Book1/Book1Label.text = 'Drilling 1'
			$MeldArea/Book2/Book2Label.text = 'Drilling 2'
			$MeldArea/Run1/Run1Label.text = 'Straße 1'
		_:
			pass

func _exit_tree() -> void:
	pass
