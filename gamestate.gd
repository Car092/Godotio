extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 10567

# Max number of players.
const MAX_PEERS = 12

var peer = null

# Name for my player.
var player_name = "The Warrior"

# Names for remote players in id:name format.
var players = {}

var _refresh_clients_timer = null
const PlayerTroll = preload("res://troll.gd")

# Signals to let lobby GUI know what's going on.
signal connection_failed()
signal game_error(what)

# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	rpc_id(1, "register_player", player_name)
	var world = load("res://dungeon.tscn").instance()
	get_tree().get_root().add_child(world)

	get_tree().get_root().get_node("Lobby").hide()

# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")

# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")

remote func refresh_players(refreshed_players):
	var world = get_tree().get_root().get_node("Dungeon")
	for p_id in refreshed_players:
		var player: PlayerTroll = world.get_node("Players").get_node(str(p_id))
		player.position = refreshed_players[p_id].position
		player.virtualPosition = refreshed_players[p_id].virtual_position
		player.movingDirection = refreshed_players[p_id].moving_direction

remote func add_player(playerData):
	var world = get_tree().get_root().get_node("Dungeon")
	var player_scene = load("res://troll.tscn")

	var player = player_scene.instance()
	player.set_name(str(playerData.id))

	player.position = playerData.position
	player.set_player_name(playerData.name)
	world.get_node("Players").add_child(player)

remote func add_current_players(players):
	var world = get_tree().get_root().get_node("Dungeon")
	var player_scene = load("res://troll.tscn")
	for p_id in players:
		var player = player_scene.instance()
		player.set_name(str(p_id))
		player.position = players[p_id].position
		player.set_player_name(players[p_id].name)
		world.get_node("Players").add_child(player)
	
func join_game(ip, new_player_name):
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(peer)
	
# Server

remote func register_player(new_player_name):
	var world = get_tree().get_root().get_node("Dungeon")
	var id = get_tree().get_rpc_sender_id()
	var spawnPosition = world.get_node("SpawnPoints/spawn0").global_position
	rpc_id(id, "add_current_players", players)
	
	players[id] = {
		"name": new_player_name,
		"position": spawnPosition,
		"input_action": "",
		"moving_direction": Vector2(),
		"virtual_position": spawnPosition
	}
	print(players)
	
	var playerData = players[id].duplicate()
	playerData.id = id
	
	rpc("add_player", playerData)
	add_player(playerData)

# Callback from SceneTree.
func _player_disconnected(id):
	print("player disconnected: ", players[id])
	players.erase(id)
	rpc("remove_player", id)
	
remotesync func remove_player(id):
	var world = get_tree().get_root().get_node("Dungeon")
	var player: KinematicBody2D = world.get_node("Players").get_node(str(id))
	player.queue_free()

func host_game():
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(peer)
	
remote func set_player_input(input_action):
	var id = get_tree().get_rpc_sender_id()
	players[id].input_action = input_action
	
func get_player_input_action(id):
	return players[int(id)].input_action

func set_player_position(id, position):
	players[int(id)].position = position
	
func set_player_moving_direction(id, move_dir):
	players[int(id)].moving_direction = move_dir

func set_player_virtual_pos(id, virtual_position):
	players[int(id)].virtual_position = virtual_position
	
func _on_refresh_clients():
	rpc_unreliable("refresh_players", players)

func _ready():
	if "--server" in OS.get_cmdline_args():
		host_game()
		var world = load("res://dungeon.tscn").instance()
		get_tree().get_root().call_deferred("add_child", world)
		get_tree().get_root().get_node("Lobby").hide()
		get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
		_refresh_clients_timer = Timer.new()
		add_child(_refresh_clients_timer)

		_refresh_clients_timer.connect("timeout", self, "_on_refresh_clients")
		_refresh_clients_timer.set_wait_time(0.0333)
		_refresh_clients_timer.set_one_shot(false) 
		_refresh_clients_timer.start()

	else:
		get_tree().connect("connected_to_server", self, "_connected_ok")
		get_tree().connect("connection_failed", self, "_connected_fail")
		get_tree().connect("server_disconnected", self, "_server_disconnected")
