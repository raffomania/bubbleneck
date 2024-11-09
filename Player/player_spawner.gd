extends Node2D

var spawned_devices = []
var player_scene = preload("res://Player/player.tscn")

# TODO check this again tomorrow
# this fixes a problem on my device where 2 players are spawned
# outside of the arena bounds and after they die, they respawn outside again
# the fix seems to work because _Input() is called before _ready()
func _Input() -> void:
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
