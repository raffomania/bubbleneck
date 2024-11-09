extends Node2D

var spawned_devices = []
var player_scene = preload("res://Player/player.tscn")
var bottle: Bottle

# todo: this is broken
func _ready():
    Input.joy_connection_changed.connect(self.joy_connection_changed)

func spawn_all_players() -> void:
    for device in Input.get_connected_joypads():
        spawn_player(device)

    # Spawn keyboard players
    for device in [-1, -2]:
        spawn_player(device)

func remove_all_players():
    get_tree().call_group("players", "queue_free")
    spawned_devices = []

func joy_connection_changed(device, connected: bool):
    if connected and not device in spawned_devices:
        spawn_player(device)

func spawn_player(device: int):
    if device in spawned_devices:
        return

    print("spawning player with device ", device)
       
    var player = player_scene.instantiate()
    player.name = "Player" + str(device)
    player.device = device
    player.player_color = random_player_color(device)
    
    var rand_offset = Vector2(randf() * 100 - 50, randf() * 100 - 50)
    player.global_position = bottle.get_bottle_floor(200) + rand_offset

    $'..'.add_child(player)
    spawned_devices.append(device)

func random_player_color(player_index: int):
    # +2 because of 2 negative keyboard devices
    var color_index = (player_index + 2) % 5

    var hue = color_index / 5.0
    if (player_index + 2) > 5:
        hue += 1 / 10.0

    return Color.from_hsv(hue, 0.8, 0.9, 1)
