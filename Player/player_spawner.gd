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

    for device in Input.get_connected_joypads():
        spawn_player(device)

    # Spawn keyboard players
    for device in [-1, -2]:
        spawn_player(device)

    Input.joy_connection_changed.connect(self.joy_connection_changed)

func joy_connection_changed(device, connected: bool):
    if connected and not device in spawned_devices:
        spawn_player(device)

func spawn_player(device: int):
    print("spawning player with device ", device)
       
    var player = player_scene.instantiate()
    player.name = "Player" + str(device)
    player.device = device
    player.player_color = random_player_color(device)
    
    # player.global_position = player.get_respawn_position()
    var rand_offset = Vector2(randf() * 100 -50 , randf() * 100 - 50)
    player.global_position = $"../Bottle".get_bottle_floor(200) + rand_offset 

    $'..'.add_child(player)
    spawned_devices.append(device)

func random_player_color(player_index: int):
    # +2 because of 2 negative keyboard devices
    var color_index = (player_index + 2) % 5

    var hue = color_index / 5.0
    if (player_index + 2) > 5:
        hue += 1 / 10.0

    return Color.from_hsv(hue, 0.8, 0.9, 1)
