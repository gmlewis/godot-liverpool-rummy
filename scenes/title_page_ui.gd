extends Control

signal start_button_pressed_signal

var current_ip_address_idx = 0
var ip_addresses = []
var remote_host_player_name = {} # Keyed by host IP address.
var udp_discovery_server: UDPServer
var udp_discovery_client_scan_timer: Timer

func _ready() -> void:
	# Note that _ready happens way after the GSM has already cycled past its
	# initial two states, so all these signals are initially missed.
	# Therefore, call all initialization in from this _ready function.
	_on_reset_game_signal()
	generate_new_random_name()
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	Global.connect('player_connected_signal', _on_player_connected_signal)
	Global.connect('player_disconnected_signal', _on_player_disconnected_signal)
	Global.connect('reset_game_signal', _on_reset_game_signal)
	if Global.LANGUAGE == 'de':
		$PanelPositionControl/WelcomePanel/WelcomeLabel.text = 'Willkommen!'
		$PanelPositionControl/WelcomePanel/WhatIsYourNameLabel.text = 'Wie heißt du?'
		$PanelPositionControl/StartGamePanel/HostNewGameButton.text = HOST_NEW_GAME_TEXT
		$PanelPositionControl/StartGamePanel/JoinGameButton.text = JOIN_GAME_TEXT

func _exit_tree():
	multiplayer.connection_failed.disconnect(_on_connection_failed)
	multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	Global.disconnect('player_connected_signal', _on_player_connected_signal)
	Global.disconnect('player_disconnected_signal', _on_player_disconnected_signal)
	Global.disconnect('reset_game_signal', _on_reset_game_signal)

func _on_reset_game_signal() -> void:
	_stop_udp_discovery()
	$StatusLabel.text = 'Version %s' % [Global.VERSION]
	$PanelPositionControl/WelcomePanel.show()
	$PanelPositionControl/StartGamePanel.hide()
	$'../PlayingCardsControl'.hide()
	$PanelPositionControl/StartGamePanel/HostNewGameButton.text = HOST_NEW_GAME_TEXT
	$PanelPositionControl/StartGamePanel/HostNewGameButton.disabled = false
	# Initially hide the Join Game button until a host is discovered.
	$PanelPositionControl/StartGamePanel/JoinGameButton.hide()
	$PanelPositionControl/StartGamePanel/JoinGameButton.text = JOIN_GAME_TEXT
	$PanelPositionControl/StartGamePanel/JoinGameButton.disabled = false
	$PanelPositionControl/StartGamePanel/NextIPAddressButton.show()
	get_local_ip_addresses()
	$PanelPositionControl/StartGamePanel/IPLineEdit.text = ip_addresses[current_ip_address_idx]
	show()
	# focus_on_name_line_edit()
	_start_udp_discovery_client()

func _restart_host_or_join() -> void:
	_stop_udp_discovery()
	$PanelPositionControl/WelcomePanel.hide()
	$PanelPositionControl/StartGamePanel.show()
	$StatusLabel.text = 'Version %s' % [Global.VERSION]
	$PanelPositionControl/StartGamePanel/HostNewGameButton.text = HOST_NEW_GAME_TEXT
	$PanelPositionControl/StartGamePanel/HostNewGameButton.disabled = false
	$PanelPositionControl/StartGamePanel/HostNewGameButton.show()
	$PanelPositionControl/StartGamePanel/JoinGameButton.hide()
	_start_udp_discovery_client()

func generate_new_random_name() -> void:
	var rng = RandomNumberGenerator.new()
	var sn = $SillyNamesNode
	var random_name = sn.silly_names[rng.randi_range(0, len(sn.silly_names) - 1)]
	$PanelPositionControl/WelcomePanel/NameLineEdit.text = random_name
	# focus_on_name_line_edit()

func focus_on_name_line_edit():
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	var input_rect = $PanelPositionControl/WelcomePanel/NameLineEdit.get_global_rect()
	click_event.position = input_rect.position + input_rect.size - Vector2(2, 2) # lower right corner click
	click_event.global_position = click_event.position
	Input.parse_input_event(click_event)
	await get_tree().process_frame
	var unclick_event = click_event.duplicate()
	unclick_event.pressed = false
	Input.parse_input_event(unclick_event)

func _on_line_edit_text_submitted(new_text: String) -> void:
	Global.private_player_info['name'] = new_text
	$PanelPositionControl/WelcomePanel.hide()
	$PanelPositionControl/StartGamePanel.show()

func _on_host_new_game_button_pressed() -> void:
	_start_udp_discovery_server()
	if $PanelPositionControl/StartGamePanel/HostNewGameButton.text == START_GAME_TEXT:
		_on_start_button_pressed()
		return
	$StatusLabel.text = '' # Hosting!'
	$PanelPositionControl/StartGamePanel/HostNewGameButton.text = START_GAME_TEXT
	var n = len(Global.game_state.public_players_info)
	$PanelPositionControl/StartGamePanel/HostNewGameButton.disabled = n < 2 # Must have 2 players
	$PanelPositionControl/StartGamePanel/JoinGameButton.text = ADD_BOT_TEXT
	$PanelPositionControl/StartGamePanel/JoinGameButton.show()
	$PanelPositionControl/StartGamePanel/NextIPAddressButton.hide()
	_update_add_bot_button_state()
	Global.create_game()

func _on_start_button_pressed() -> void:
	_stop_udp_discovery()
	$PanelPositionControl/StartGamePanel.hide()
	_rpc_hide_title_page_ui.rpc()
	start_button_pressed_signal.emit()

@rpc('call_local', 'authority', 'reliable')
func _rpc_hide_title_page_ui():
	hide()
	$'../PlayingCardsControl'.show()

func _on_join_game_button_pressed() -> void:
	if $PanelPositionControl/StartGamePanel/JoinGameButton.text == ADD_BOT_TEXT:
		_on_add_bot_button_pressed()
		return
	$PanelPositionControl/StartGamePanel.hide()
	Global.join_game($PanelPositionControl/StartGamePanel/IPLineEdit.text)
	$StatusLabel.text = CONNECTING_TEXT # 'Connecting...'

func _on_add_bot_button_pressed() -> void:
	#Global.dbg('Add Bot button pressed')
	var n = len(Global.game_state.public_players_info)
	if n < Global.MAX_PLAYERS:
		Global.add_bot_to_game()
	_update_add_bot_button_state()

func _on_player_connected_signal(_id, _player_info) -> void:
	var n = len(Global.game_state.public_players_info)
	Global.dbg('title_page_ui._on_player_connected_signal: n=%d' % [n])
	_update_add_bot_button_state()

func _update_add_bot_button_state():
	var n = len(Global.game_state.public_players_info)
	if n >= Global.MAX_PLAYERS:
		#Global.dbg('disabling Add Bot button')
		$PanelPositionControl/StartGamePanel/JoinGameButton.disabled = true
	else:
		#Global.dbg('re-enabling Add Bot button')
		$PanelPositionControl/StartGamePanel/JoinGameButton.disabled = false
	# Also update the state of the 'Start Game' button
	$PanelPositionControl/StartGamePanel/HostNewGameButton.disabled = n < 2 # Must have 2 players

func _on_player_disconnected_signal(_id) -> void:
	var n = len(Global.game_state.public_players_info)
	Global.dbg('title_page_ui._on_player_disconnected_signal: n=%d' % [n])
	_update_add_bot_button_state()

func _on_refresh_name_button_pressed() -> void:
	generate_new_random_name()

func _on_connected_to_server() -> void:
	$StatusLabel.text = CONNECTED_WAITING_FOR_HOST_TEXT # 'Connected! Waiting for host...'

func _on_connection_failed() -> void:
	$StatusLabel.text = FAILED_TO_CONNECT_TEXT # 'Failed to connect.'
	$PanelPositionControl/StartGamePanel.show()

func get_local_ip_addresses() -> void:
	Global.dbg('Searching for IP addresses...')
	current_ip_address_idx = 0
	ip_addresses = []
	for address in IP.get_local_addresses():
		Global.dbg('Found IP address: ' + address)
		var parts = address.split('.')
		if len(parts) != 4 || parts[0] == '127':
			continue
		if parts[0] == '10' || parts[0] == '100' || parts[0] == '172' || parts[0] == '192':
			ip_addresses.append(address)
	# Sort IP addresses lexicographically in descending order
	ip_addresses.sort_custom(func(a, b): return a > b)
	ip_addresses.append('localhost') # for standalone play

func _on_next_ip_address_button_pressed() -> void:
	current_ip_address_idx = (current_ip_address_idx + 1) % len(ip_addresses)
	$PanelPositionControl/StartGamePanel/IPLineEdit.text = ip_addresses[current_ip_address_idx]
	_restart_host_or_join()

const ADD_BOT_TEXT = 'Add Bot' if Global.LANGUAGE != 'de' else 'Bot\nHinzufügen'
const CONNECTED_WAITING_FOR_HOST_TEXT = 'Connected! Waiting for host...' if Global.LANGUAGE != 'de' else 'Verbunden! Warte auf den Host...'
const CONNECTING_TEXT = 'Connecting...' if Global.LANGUAGE != 'de' else 'Verbinde...'
const FAILED_TO_CONNECT_TEXT = 'Failed to connect.' if Global.LANGUAGE != 'de' else 'Verbindung fehlgeschlagen.'
const HOST_NEW_GAME_TEXT = 'Host New\nGame' if Global.LANGUAGE != 'de' else 'Neues Spiel\nStarten'
const START_GAME_TEXT = 'Start Game' if Global.LANGUAGE != 'de' else 'Spiel\nStarten'
# Allow this text to change based on discovered hosts, e.g. "Join\nBo Peep".
var JOIN_GAME_TEXT = 'Join\nGame' if Global.LANGUAGE != 'de' else 'Spiel\nBeitreten'

func _on_accept_name_button_pressed() -> void:
	var new_name = $PanelPositionControl/WelcomePanel/NameLineEdit.text
	_on_line_edit_text_submitted(new_name)

################################################################################
## UDP Discovery Server
################################################################################

func _start_udp_discovery_server():
	_stop_udp_discovery()
	udp_discovery_server = UDPServer.new()
	var result = udp_discovery_server.listen(Global.DISCOVERY_PORT, "0.0.0.0")
	if result == OK:
		Global.dbg("Discovery server listening on port: %s" % Global.DISCOVERY_PORT)
	else:
		Global.dbg("ERROR: Failed to start discovery server: %s" % result)

func _start_udp_discovery_client():
	_stop_udp_discovery()
	remote_host_player_name = {}
	udp_discovery_client_scan_timer = Timer.new()
	udp_discovery_client_scan_timer.wait_time = 1.1 # Scan every 1.1 seconds
	udp_discovery_client_scan_timer.timeout.connect(_scan_for_servers)
	add_child(udp_discovery_client_scan_timer)
	udp_discovery_client_scan_timer.start()
	_scan_for_servers()

func _stop_udp_discovery():
	if udp_discovery_server:
		udp_discovery_server.stop()
		udp_discovery_server = null
	if udp_discovery_client_scan_timer:
		udp_discovery_client_scan_timer.stop()
		udp_discovery_client_scan_timer.queue_free()
		udp_discovery_client_scan_timer = null

func _process(_delta):
	if udp_discovery_server and udp_discovery_server.is_listening():
		udp_discovery_server.poll()
		if udp_discovery_server.is_connection_available():
			var peer = udp_discovery_server.take_connection()
			Global.dbg("Discovery request received from: %s" % peer.get_packet_ip())
			_handle_discovery_request(peer)

func _handle_discovery_request(peer: PacketPeerUDP):
	var packet = peer.get_packet()
	if packet.size() > 0:
		var message = packet.get_string_from_utf8()
		var sender_ip = peer.get_packet_ip()
		var sender_port = peer.get_packet_port()
		Global.dbg("Received discovery request: %s from %s:%d" % [message, sender_ip, sender_port])

		if message == "DISCOVER_SERVERS":
			# Create a new UDP socket to send response
			var response_socket = PacketPeerUDP.new()

			# Set destination and send response
			if response_socket.set_dest_address(sender_ip, sender_port) == OK:
				var host_name = $PanelPositionControl/WelcomePanel/NameLineEdit.text
				var server_info = {'host_name': host_name}
				var response = JSON.stringify(server_info)

				if response_socket.put_packet(response.to_utf8_buffer()) == OK:
					Global.dbg("Sent server info to: %s:%d" % [sender_ip, sender_port])
				else:
					Global.dbg("Failed to send response to: %s:%d" % [sender_ip, sender_port])
			else:
				Global.dbg("Failed to set destination address: %s:%d" % [sender_ip, sender_port])

			response_socket.close()

func _scan_for_servers():
	var current_ip_address = ip_addresses[current_ip_address_idx]
	# If this current_ip_address already has a host server, skip it.
	if current_ip_address in remote_host_player_name:
		# Global.dbg("Skipping scan for current IP address: %s (already has a host server)" % current_ip_address)
		return
	var parts = current_ip_address.split('.')
	if len(parts) != 4:
		if current_ip_address != 'localhost':
			Global.dbg("Invalid IP address format: %s" % current_ip_address)
		return
	var broadcast_ip = "%s.%s.%s.255" % [parts[0], parts[1], parts[2]]

	# Use the same socket for sending and receiving
	var client_socket = PacketPeerUDP.new()

	# Try to bind to any available port
	var client_port = 0
	for attempt in range(10):
		client_port = Global.DISCOVERY_PORT + randi_range(1000, 9999)
		if client_socket.bind(client_port, current_ip_address) == OK:
			# Global.dbg("Bound client to port: %s:%d" % [current_ip_address, client_port])
			break
		if attempt == 9:
			Global.dbg("ERROR: Failed to bind client socket")
			return

	client_socket.set_broadcast_enabled(true)

	if client_socket.set_dest_address(broadcast_ip, Global.DISCOVERY_PORT) != OK:
		Global.dbg("ERROR: Failed to set destination address")
		client_socket.close()
		return

	var message = "DISCOVER_SERVERS"
	# Global.dbg("Sending discovery request from port %d to %s:%d" % [client_port, broadcast_ip, Global.DISCOVERY_PORT])

	if client_socket.put_packet(message.to_utf8_buffer()) != OK:
		Global.dbg("ERROR: Failed to send discovery request")
		client_socket.close()
		return

	# Listen for responses on the same socket for 1 second.
	var listen_time = 1000.0
	var start_time = Global.get_system_time_msec()

	while true:
		# Process ALL available packets in this iteration
		while client_socket.get_available_packet_count() > 0:
			var packet = client_socket.get_packet()
			var sender_ip = client_socket.get_packet_ip()
			Global.dbg("Received response from server: %s" % sender_ip)
			if packet.size() > 0:
				var response = packet.get_string_from_utf8()
				Global.dbg("response: '%s'" % response)
				parse_server_response(response, sender_ip)

		await get_tree().create_timer(0.005).timeout # wait for 5ms.
		var elapsed = Global.get_system_time_msec() - start_time
		if elapsed >= listen_time:
			break

	client_socket.close()

func parse_server_response(response: String, ip: String):
	var json = JSON.new()
	var parse_result = json.parse(response)

	if parse_result == OK:
		if ip in remote_host_player_name: return # already discovered this server
		var server_data = json.data
		if 'host_name' in server_data:
			var host_name = server_data['host_name']
			remote_host_player_name[ip] = host_name
			Global.dbg("Discovered server: %s at %s" % [host_name, ip])
			# Update the Join Game button text with the discovered host name
			# JOIN_GAME_TEXT = "Join\n%s" % host_name if Global.LANGUAGE != 'de' else "Spiel\n%s beitreten" % host_name
			$PanelPositionControl/StartGamePanel/JoinGameButton.text = JOIN_GAME_TEXT
			$PanelPositionControl/StartGamePanel/JoinGameButton.show()
			$PanelPositionControl/StartGamePanel/HostNewGameButton.hide()
			var lookup_ip_address_idx = -1
			for idx in range(len(ip_addresses)):
				if ip_addresses[idx] == ip:
					lookup_ip_address_idx = idx
					break
			if lookup_ip_address_idx != -1:
				current_ip_address_idx = lookup_ip_address_idx
			else:
				Global.dbg("Adding new IP address to the list: %s" % ip)
				ip_addresses.push_front(ip)
				current_ip_address_idx = 0
			$PanelPositionControl/StartGamePanel/IPLineEdit.text = ip_addresses[current_ip_address_idx]
			Global.dbg("Updated IP addresses: %s" % str(ip_addresses))
		else:
			Global.dbg("ERROR: 'host_name' not found in server response: %s" % response)
	else:
		Global.dbg("ERROR: Failed to parse server response: %s" % response)
