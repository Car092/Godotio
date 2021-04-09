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

# Signals to let lobby GUI know what's going on.
signal connection_failed()
signal game_error(what)

# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	rpc_id(1, "register_player", player_name)

# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")

# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")

remote func add_current_players(current_players):
	# Change scene.
	var world = load("res://dungeon.tscn").instance()
	get_tree().get_root().add_child(world)

	get_tree().get_root().get_node("Lobby").hide()
	
	var player_scene = load("res://troll.tscn")

	for p_id in current_players:
		var player = player_scene.instance()
		player.set_name(str(p_id)) # Use unique ID as node name.
		player.position = world.get_node("SpawnPoints/spawn0").position

		if p_id == get_tree().get_network_unique_id():
			# If node for this peer id, set name.
			player.set_player_name(player_name)
		else:
			# Otherwise set name from peer.
			player.set_player_name(players[p_id])

		world.get_node("Players").add_child(player)

# Lobby management functions.

remote func register_player(new_player_name):
	var id = get_tree().get_rpc_sender_id()
	players[id] = new_player_name
	print(players)
	rpc_id(id, "add_current_players", players)

# Callback from SceneTree.
func _player_disconnected(id):
	#todo: delete player and refresh clients
	unregister_player(id)

func unregister_player(id):
	players.erase(id)

func host_game():
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(peer)


func join_game(ip, new_player_name):
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(peer)


func get_player_list():
	return players.values()


func get_player_name():
	return player_name

func _ready():
	if "--server" in OS.get_cmdline_args():
		host_game()
		var world = load("res://dungeon.tscn").instance()
		get_tree().get_root().call_deferred("add_child", world)

		get_tree().get_root().get_node("Lobby").hide()
		get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

	else:
		get_tree().connect("connected_to_server", self, "_connected_ok")
		get_tree().connect("connection_failed", self, "_connected_fail")
		get_tree().connect("server_disconnected", self, "_server_disconnected")
