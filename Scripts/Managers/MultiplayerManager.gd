extends Node

const PORT = 9999
var peer = ENetMultiplayerPeer.new()
var Player = preload("res://Scenes/player.tscn")

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var address_label = $CanvasLayer/HUD/AddressHost

func _on_host_button_pressed():
	main_menu.hide()
	
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())
	
	#upnp_setup()


func _on_join_button_pressed():
	main_menu.hide()
	peer.create_client("127.0.0.1", PORT)
	multiplayer.multiplayer_peer = peer


func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)


func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()


func exit_game(peer_id):
	multiplayer.peer_disconnected.connect(remove_player)
	remove_player(peer_id)


func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Siscover Failed! Error %s" % discover_result)
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), "UPNP Invalid Gataway")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address %s" % upnp.query_external_address())
	address_label.text = upnp.query_external_address()
	



