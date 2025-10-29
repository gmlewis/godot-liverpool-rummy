class_name TestPostMeldLogic
extends Node

var test_framework: TestFramework

func _ready():
	test_framework = TestFramework.new()
	add_child(test_framework)

func run_all_tests() -> bool:
	return test_framework.discover_and_run_test_suite("Post-Meld Logic Tests", self)

func cleanup_test_resources() -> void:
	if test_framework and is_instance_valid(test_framework):
		if test_framework.is_inside_tree():
			remove_child(test_framework)
		test_framework.queue_free()
	test_framework = null

func test_get_all_meld_possibilities() -> bool:
	var test_cases = [
		{
			'name': 'Check to replace joker with 4-diamonds',
			'meld_area_1_keys': ['4-diamonds-0'],
			'post_meld_data': {'meld_area_1_complete': true, 'meld_area_1_type': 'run', 'meld_area_2_complete': false, 'meld_area_2_type': 'run', 'meld_area_3_complete': false, 'meld_area_3_type': '', 'all_public_group_ranks': {}, 'all_public_run_suits': {'diamonds': [ {'target_player_id': '1', 'type': 'run', 'suit': 'diamonds', 'card_keys': ['3-diamonds-2', 'JOKER-2-3', '5-diamonds-3', '6-diamonds-3', '7-diamonds-3', '8-diamonds-3'], 'meld_group_index': 0}, {'target_player_id': 'bot9', 'type': 'run', 'suit': 'diamonds', 'card_keys': ['8-diamonds-0', '9-diamonds-2', '10-diamonds-2', 'J-diamonds-1'], 'meld_group_index': 0}], 'clubs': [ {'target_player_id': '1', 'type': 'run', 'suit': 'clubs', 'card_keys': ['10-clubs-3', 'J-clubs-1', 'Q-clubs-0', 'K-clubs-3', 'JOKER-2-0'], 'meld_group_index': 1}], 'spades': [ {'target_player_id': 'bot5', 'type': 'run', 'suit': 'spades', 'card_keys': ['9-spades-3', '10-spades-2', 'J-spades-3', 'Q-spades-1', 'JOKER-1-3'], 'meld_group_index': 0}], 'hearts': [ {'target_player_id': 'bot5', 'type': 'run', 'suit': 'hearts', 'card_keys': ['7-hearts-2', '8-hearts-3', 'JOKER-2-2', '10-hearts-0', 'J-hearts-1', 'Q-hearts-0'], 'meld_group_index': 1}, {'target_player_id': 'bot9', 'type': 'run', 'suit': 'hearts', 'card_keys': ['2-hearts-3', '3-hearts-2', '4-hearts-0', '5-hearts-2', '6-hearts-3'], 'meld_group_index': 1}]}},
			'expected': [
				{
					'card_key': '4-diamonds-0',
					'target_player_id': '1',
					'type': 'run',
					'suit': 'diamonds',
					'card_keys': [
					'3-diamonds-2',
					'JOKER-2-3',
					'5-diamonds-3',
					'6-diamonds-3',
					'7-diamonds-3',
					'8-diamonds-3'
					],
					'meld_group_index': 0
				},
			],
		},
		{
			'name': 'Add JOKER to run',
			'meld_area_1_keys': ['JOKER-1-0'],
			'post_meld_data': {'meld_area_1_complete': true, 'meld_area_1_type': 'run', 'meld_area_2_complete': false, 'meld_area_2_type': 'run', 'meld_area_3_complete': false, 'meld_area_3_type': '', 'all_public_group_ranks': {}, 'all_public_run_suits': {'diamonds': [ {'target_player_id': '1', 'type': 'run', 'suit': 'diamonds', 'card_keys': ['3-diamonds-2', 'JOKER-2-3', '5-diamonds-3', '6-diamonds-3', '7-diamonds-3', '8-diamonds-3'], 'meld_group_index': 0}, {'target_player_id': 'bot9', 'type': 'run', 'suit': 'diamonds', 'card_keys': ['8-diamonds-0', '9-diamonds-2', '10-diamonds-2', 'J-diamonds-1'], 'meld_group_index': 0}], 'clubs': [ {'target_player_id': '1', 'type': 'run', 'suit': 'clubs', 'card_keys': ['10-clubs-3', 'J-clubs-1', 'Q-clubs-0', 'K-clubs-3', 'JOKER-2-0'], 'meld_group_index': 1}], 'spades': [ {'target_player_id': 'bot5', 'type': 'run', 'suit': 'spades', 'card_keys': ['9-spades-3', '10-spades-2', 'J-spades-3', 'Q-spades-1', 'JOKER-1-3'], 'meld_group_index': 0}], 'hearts': [ {'target_player_id': 'bot5', 'type': 'run', 'suit': 'hearts', 'card_keys': ['7-hearts-2', '8-hearts-3', 'JOKER-2-2', '10-hearts-0', 'J-hearts-1', 'Q-hearts-0'], 'meld_group_index': 1}, {'target_player_id': 'bot9', 'type': 'run', 'suit': 'hearts', 'card_keys': ['2-hearts-3', '3-hearts-2', '4-hearts-0', '5-hearts-2', '6-hearts-3'], 'meld_group_index': 1}]}},
			'expected': [
				{"target_player_id": "1", "type": "run", "suit": "diamonds", "card_keys": ["3-diamonds-2", "JOKER-2-3", "5-diamonds-3", "6-diamonds-3", "7-diamonds-3", "8-diamonds-3"], "meld_group_index": 0, "card_key": "JOKER-1-0"},
				{"target_player_id": "bot9", "type": "run", "suit": "diamonds", "card_keys": ["8-diamonds-0", "9-diamonds-2", "10-diamonds-2", "J-diamonds-1"], "meld_group_index": 0, "card_key": "JOKER-1-0"},
				{"target_player_id": "1", "type": "run", "suit": "clubs", "card_keys": ["10-clubs-3", "J-clubs-1", "Q-clubs-0", "K-clubs-3", "JOKER-2-0"], "meld_group_index": 1, "card_key": "JOKER-1-0"},
				{"target_player_id": "bot5", "type": "run", "suit": "spades", "card_keys": ["9-spades-3", "10-spades-2", "J-spades-3", "Q-spades-1", "JOKER-1-3"], "meld_group_index": 0, "card_key": "JOKER-1-0"},
				{"target_player_id": "bot5", "type": "run", "suit": "hearts", "card_keys": ["7-hearts-2", "8-hearts-3", "JOKER-2-2", "10-hearts-0", "J-hearts-1", "Q-hearts-0"], "meld_group_index": 1, "card_key": "JOKER-1-0"},
				{"target_player_id": "bot9", "type": "run", "suit": "hearts", "card_keys": ["2-hearts-3", "3-hearts-2", "4-hearts-0", "5-hearts-2", "6-hearts-3"], "meld_group_index": 1, "card_key": "JOKER-1-0"},
			],
		},
		{
			'name': 'Add JOKER to group',
			'meld_area_1_keys': ['JOKER-1-0'],
			'post_meld_data': {'meld_area_1_complete': true, 'meld_area_1_type': 'group', 'meld_area_2_complete': false, 'meld_area_2_type': 'run', 'meld_area_3_complete': false, 'meld_area_3_type': '', 'all_public_group_ranks': {'7': [ {'target_player_id': '1', 'type': 'group', 'rank': '7', 'card_keys': ['JOKER-2-0', 'JOKER-2-3', '7-diamonds-3'], 'meld_group_index': 0}]}, 'all_public_run_suits': {}},
			'expected': [
				{"target_player_id": "1", "type": "group", "rank": "7", "card_keys": ['JOKER-2-0', 'JOKER-2-3', '7-diamonds-3'], "meld_group_index": 0, "card_key": "JOKER-1-0"},
			],
		},
	]

	var player = load("res://players/player.gd")
	for test_case in test_cases:
		if test_case.has('meld_area_1_keys'):
			Global.private_player_info['meld_area_1_keys'] = test_case.meld_area_1_keys
		var got = player.get_all_meld_possibilities(test_case.post_meld_data)
		test_framework.assert_array_size(got, len(test_case.expected), "Test case '%s' failed: expected %d possibilities, got %d" % [test_case.name, len(test_case.expected), len(got)])
		for i in range(len(test_case.expected)):
			test_framework.assert_dict_deep_equal(test_case.expected[i], got[i], "Test case '%s' failed at possibility %d" % [test_case.name, i])
	return true
