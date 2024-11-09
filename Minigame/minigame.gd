extends Node2D

var label_scene = preload("res://Minigame/PressLabel.tscn")

var key_sequence = ["up", "up", "down", "left", "right"]
var label_children: Array[PressLabel] = []
var device: int = -1
var axis_threshold = 0.5
var color := Color.HOT_PINK

var is_finished := false

signal finished

func _ready() -> void:
    create_labels()
    modulate = color

func create_labels():
    var label_position = Vector2.ZERO
    for dir in key_sequence:
        var label: PressLabel = label_scene.instantiate()
        label.set_direction(dir)
        label.position = label_position
        label_position.x += 60
        add_child(label)
        label_children.append(label)

func _process(_delta: float) -> void:
    global_rotation = 0

    if is_finished:
        return

    var label_to_press = find_next_label_to_press()
    if label_to_press == null:
        return

    if get_pressed_direction() == label_to_press.dir:
        label_to_press.set_pressed(true)
        if find_next_label_to_press() == null:
            is_finished = true
            finished.emit()

func find_next_label_to_press():
    for child in label_children:
        if not child.is_pressed:
            return child

    return null

func get_pressed_direction() -> String:
    var dir
    if is_keyboard_player():
        var prefix = get_keyboard_player_prefix()
        dir = Input.get_vector(prefix + "_left", prefix + "_right", prefix + "_up", prefix + "_down")

    else:
        # Player is using a controller
        dir = Vector2(1, 0) * Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
        dir.y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)

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
    return device < 0

func get_keyboard_player_prefix():
    return "kb" + str(abs(device))