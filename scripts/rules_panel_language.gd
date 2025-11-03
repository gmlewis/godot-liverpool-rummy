extends Control

func _ready() -> void:
	Global.dbg('RulesPanel: ENTER')
	if Global.LANGUAGE in title_text:
		$Title.text = title_text.get(Global.LANGUAGE, '')
	if Global.LANGUAGE in rules_text:
		$ScrollContainer/Label.text = rules_text.get(Global.LANGUAGE, '')

func _exit_tree() -> void:
	Global.dbg('RulesPanel: LEAVE')

const title_text = {
	'de': 'Regeln für Moonridge Rummy',
	'en': 'Rules for Moonridge Rummy',
}

const rules_text = {
	'de': """# Moonridge Rummy: Alle Runden und ihre Anforderungen

Moonridge Rummy wird über sieben Runden gespielt, wobei jede Runde eine bestimmte  
Kombination aus Sätzen (Büchern) und Folgen (Sequenzen) erfordert, die ein Spieler
ablegen muss, um auszusteigen. Die Anforderungen werden mit jeder Runde anspruchsvoller.
Hier sind die Anforderungen für jede Runde:

      |                                                                     | Karten gesamt
Runde | Anforderung                                                         | benötigt
------|--------------------------------------------------------------------|-------------
  1   | Zwei Sätze zu drei Karten (2 Gruppen à 3 Karten)                    | 6
  2   | Ein Satz zu drei und eine Folge von vier Karten                     | 7
  3   | Zwei Folgen von vier Karten                                         | 8
  4   | Drei Sätze zu drei Karten                                           | 9
  5   | Zwei Sätze zu drei und eine Folge von vier Karten                   | 10
  6   | Ein Satz zu drei und zwei Folgen von vier Karten                    | 11
  7   | Drei Folgen von vier Karten (keine Restkarten, kein Abwurf erlaubt) | 12

## Erklärung der Begriffe

* Satz (Gruppe/Buch):
  Drei oder mehr Karten gleichen Rangs (z. B. 8♥ 8♣ 8♠).

* Folge (Sequenz):
  Vier oder mehr aufeinanderfolgende Karten derselben Farbe (z. B. 3♥ 4♥ 5♥ 6♥).
  Asse können hoch oder niedrig sein, aber Folgen dürfen nicht „umlaufen“
(z. B. König–Ass–2).

## Besondere Hinweise

* In der letzten Runde (Runde 7) müssen alle Karten in den geforderten
  Kombinationen verwendet werden, und ein Abwurf am Ende ist nicht erlaubt.

* Die Vorgaben für jede Runde müssen exakt erfüllt werden, bevor
Karten abgelegt werden können.
""",
	'en': """# Moonridge Rummy: All Rounds and Their Requirements

Moonridge Rummy is a variation of Liverpool Rummy that is played
over seven rounds, each with a specific combination of sets (books)
and runs (sequences) that players must lay down to go out. The
requirements for each round become progressively more
challenging. Here are the round-by-round requirements:

      |                                                             | Total Cards
Round | Requirement                                                 | Needed
------|------------------------------------------------------------|------------
  1   | Two books of three (2 sets of 3 cards)                      | 6
  2   | One book of three and one run of four                       | 7
  3   | Two runs of four                                            | 8
  4   | Three books of three                                        | 9
  5   | Two books of three and one run of four                      | 10
  6   | One book of three and two runs of four                      | 11
  7   | Three runs of four (no remaining cards, no discard allowed) | 12

## Explanation of Terms

* Book (Set/Group):
  Three or more cards of the same rank (e.g., 8♥ 8♣ 8♠).

* Run (Sequence):
  Four or more consecutive cards of the same suit (e.g., 3♥ 4♥ 5♥ 6♥).
  Aces can be high or low, but runs cannot "wraparound" from King to Ace to 2.

## Special Notes

* In the final round (Round 7), you must use all your cards in the required
  melds and cannot finish with a discard.

* The contract for each round must be met exactly as specified before you
  can lay down your cards.
""",
}