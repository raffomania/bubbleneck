extends Node2D

var spawned_devices = []
var player_scene = preload("res://Player/player.tscn")

func _ready() -> void:
    for device in Input.get_connected_joypads():
        spawn_player(device)
    
    Input.joy_connection_changed.connect(self.joy_connection_changed)

func joy_connection_changed(device, connected: bool):
    if connected and device not in spawned_devices:
        spawn_player(device)

func spawn_player(device: int):
    print("spawning player with device ", device)
    var player = player_scene.instantiate()
    player.device = device
    add_child(player)
    spawned_devices.append(device)
