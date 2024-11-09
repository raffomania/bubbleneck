extends Node2D

var spawned_devices = []
var player_scene = preload("res://Player/player.tscn")

# this incurs weird behavior for me that the others don't have
# the players spawrned from this are spawned outside the arena bounds
# and if they die, they respawn outside again, 
# their whole transform dimensions seems to be shifted
# it is prob. related to time time when this function is called (too early for the viewport rect?)
# also it is different on my end because my mouse/trackpad seems to be recognized as an input device
func _ready() -> void:
    # Wait until everything's ready
    await get_tree().create_timer(0.1).timeout
    # 2 for keyboard
    var num_devices = Input.get_connected_joypads().size() + 2

    for device in Input.get_connected_joypads():
        spawn_player(device, num_devices)

    # Spawn keyboard players
    for device in [-1, -2]:
        spawn_player(device, num_devices)

    Input.joy_connection_changed.connect(self.joy_connection_changed, num_devices)

func joy_connection_changed(device, connected: bool, num_devices: int):
    if connected and device not in spawned_devices:
        spawn_player(device, num_devices)

func spawn_player(device: int, num_devices: int):
    print("spawning player with device ", device, " and num_devices ", num_devices)
       
    var player = player_scene.instantiate()
    player.name = "Player" + str(device)
    player.device = device
    player.player_color = random_player_color(device, num_devices)
    player.global_position = get_viewport_rect().size / 2
    $'..'.add_child(player)
    spawned_devices.append(device)

func random_player_color(player_index: int, num_players: int):
    # +2 because of 2 negative keyboard devices
    var hue = (float(player_index + 2) / float(num_players))
    print("hue: ", hue, " player_index: ", player_index, " num_players: ", num_players)
    return Color.from_hsv(hue, 0.8, 0.9, 1)

