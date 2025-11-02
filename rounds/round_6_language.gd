extends Control

func _ready() -> void:
	match Global.LANGUAGE:
		'de':
			$RoundLabel.text = 'Runde 6: Ein Drilling (3) und zwei Straßen (je 4)'
			$MeldArea/Book1/Book1Label.text = 'Drilling 1'
			$MeldArea/Run1/Run1Label.text = 'Straße 1'
			$MeldArea/Run2/Run2Label.text = 'Straße 2'
		_:
			pass

func _exit_tree() -> void:
	pass
