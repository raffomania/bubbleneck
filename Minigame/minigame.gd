extends Node2D

class_name Minigame

var label_scene = preload("res://Minigame/PressLabel.tscn")

var available_directions = ["up", "down", "left", "right"]
var label_children: Array[PressLabel] = []
var player: Player
var axis_threshold = 0.5
var color := Color.HOT_PINK

static var max_labels := 8
static var min_labels := 2

var on_cooldown := false

var is_finished := false

signal finished
signal aborted

func create_labels():
    var label_position = Vector2.ZERO
    for _i in range(0, get_amount_labels()):
        var dir = available_directions[randi() % available_directions.size()]
        var label: PressLabel = label_scene.instantiate()
        label.set_color(color)
        label.set_direction(dir)
        label.position = label_position
        label_position.x += 120
        add_child(label)
        label_children.append(label)

# Move the minigame to make sure it doesn't reach outside the available screen area.
# Also make sure not to cover the player
func calculate_global_position(global_player_position: Vector2) -> Vector2:
    var result = Vector2(global_player_position)

    # Calculate size of minigame
    var first_label = label_children.front() as PressLabel
    var last_label = label_children.back() as PressLabel
    var global_width = last_label.global_position.x + last_label.get_global_size().x - first_label.global_position.x

    # Center on player
    result.x -= global_width / 2

    # Move slightly below or above player
    var viewport = get_viewport_rect()
    var to_center = sign(viewport.size.y / 2 - global_player_position.y)
    result.y += to_center * 100

    # Move away from the side of the screen if necessary
    if global_position.x < viewport.position.x:
        result.x = viewport.position.x
    if global_position.x + global_width > viewport.size.x:
        result.x = viewport.size.x

    return result

func _process(_delta: float) -> void:
    global_rotation = 0

    if is_finished:
        return

    # If there's no next label to press, there's nothing to do.
    var label_to_press = find_next_label_to_press()
    if label_to_press == null:
        return

    var pressed_direction = get_pressed_direction()

    # Player has released the stick, reset the cooldown and then do nothing.
    if pressed_direction == "":
        on_cooldown = false
        return

    # We're on cooldown, but player hasn't released the stick yet.
    if on_cooldown:
        return

    # correct direction pressed
    if pressed_direction == label_to_press.dir:
        label_to_press.set_pressed(true)
        on_cooldown = true
        if find_next_label_to_press() == null:
            finish()
        return
    
    # wrong direction pressed
    var last_pressed = find_last_pressed_label()
    if is_instance_valid(last_pressed):
        last_pressed.set_pressed(false)
        label_to_press.wrong_direction_pressed_animation()
        on_cooldown = true


func finish():
    is_finished = true
    finished.emit()
    for label in label_children:
        await get_tree().create_timer(0.02).timeout
        await label.vanish_animation()
        label.queue_free()
    queue_free()

func abort():
    aborted.emit()
    queue_free()

func find_next_label_to_press():
    for child in label_children:
        if not child.is_pressed:
            return child

    return null

func find_last_pressed_label():
    for i in range(label_children.size() - 1, -1, -1):
        if label_children[i].is_pressed:
            return label_children[i]

    return null

func get_pressed_direction() -> String:
    var dir
    if is_keyboard_player():
        var prefix = get_keyboard_player_prefix()
        dir = Input.get_vector(prefix + "_left", prefix + "_right", prefix + "_up", prefix + "_down")
    else:
        # Player is using a controller
        dir = Vector2(1, 0) * Input.get_joy_axis(player.controller_device_index, JOY_AXIS_LEFT_X)
        dir.y = Input.get_joy_axis(player.controller_device_index, JOY_AXIS_LEFT_Y)
        # TODO: directional pads

    if dir.x > axis_threshold:
        return "right"
    elif dir.x < -axis_threshold:
        return "left"
    elif dir.y > axis_threshold:
        return "down"
    elif dir.y < -axis_threshold:
        return "up"

    return ""

func is_keyboard_player():
    return player.controller_device_index < 0

func get_keyboard_player_prefix():
    return "kb" + str(abs(player.controller_device_index))

func get_amount_labels():
    var spawner: PlayerSpawner = get_node("/root/Main/PlayerSpawner")
    var total_players = spawner.get_total_players()

    var kill_streak_reduction = floor(player.kill_streak / 2)
    return max(3, max_labels - kill_streak_reduction - (total_players / 2))
