extends Node2D

var spawned_devices = []
var player_scene = preload("res://Player/player.tscn")
var bottle: Bottle

@export
var player_colors: Array[Color]

var keyboard_actions = {"kb1": [], "kb2": []}
var keyboard_devices = []


# todo: this is broken
func _ready():
    get_keyboard_actions()
    Input.joy_connection_changed.connect(self.joy_connection_changed)

func spawn_all_players() -> void:
    for device in Input.get_connected_joypads():
        spawn_player(device)

    # Spawn keyboard players
    # for device in [-1, -2]:
    #     spawn_player(device)

    get_tree().root.get_node('Main').get_node('ScoringSystem').init_scores()

func remove_all_players():
    get_tree().call_group("players", "queue_free")
    spawned_devices = []

func joy_connection_changed(device, connected: bool):
    if connected and not device in spawned_devices:
        spawn_player(device)
    get_tree().root.get_node('Main').get_node('ScoringSystem').init_scores()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.is_action_type() and event.is_pressed():
        for prefix in keyboard_actions.keys():
            var device = int(prefix[2]) * -1
            if device in keyboard_devices:
                continue
            for action in keyboard_actions[prefix]:
                if event.is_action(action):
                    add_keyboard_device(device)
                    print("keyboard device added: ", device)

                    


func get_keyboard_actions():
    var kb_prefixes = ["kb1", "kb2"]
    var actions = InputMap.get_actions()
    for prefix in kb_prefixes:
        var relevant_actions = actions.filter(func(action: String): return action.contains(prefix))
        keyboard_actions[prefix] = relevant_actions

func add_keyboard_device(device: int):
    if not device in keyboard_devices:
        keyboard_devices.append(device)
        spawn_player(device)
    get_tree().root.get_node('Main').get_node('ScoringSystem').init_scores()

func spawn_player(device: int):
    if device in spawned_devices:
        return

    print("spawning player with device ", device)
       
    var player = player_scene.instantiate()
    player.name = "Player" + str(device)
    player.device = device
    player.player_color = random_player_color(device)
    
    player.global_position = bottle.get_respawn_position()

    $'..'.add_child(player)
    spawned_devices.append(device)

func random_player_color(player_index: int):
    # +2 because of 2 negative keyboard devices
    var color_index = (player_index + 2) % player_colors.size()

    return player_colors[color_index]
