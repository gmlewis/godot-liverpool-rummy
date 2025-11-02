extends Control

func _ready() -> void:
	match Global.LANGUAGE:
		'de':
			$RoundLabel.text = 'Runde 7: Drei Vierer-Straßen (kein Abwurf)'
			$MeldArea/Run1/Run1Label.text = 'Straße 1'
			$MeldArea/Run2/Run2Label.text = 'Straße 2'
			$MeldArea/Run3/Run3Label.text = 'Straße 3'
		_:
			pass

func _exit_tree() -> void:
	pass
