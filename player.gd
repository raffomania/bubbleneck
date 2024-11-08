extends Node2D

@export
var device := 0
@export
var movespeed := 700

func _ready():
    print(Input.get_connected_joypads())

func _draw() -> void:
    draw_circle(position, 30, Color.VIOLET, 2)

func _process(delta: float) -> void:
    var dir: Vector2
    if is_keyboard_player():
        var prefix = get_keyboard_player_prefix()
        dir = Input.get_vector(prefix + "_left", prefix + "_right", prefix + "_up", prefix + "_down")
    else:
        dir = Vector2(1, 0) * Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
        dir.y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)

    position += dir * delta * movespeed

func is_keyboard_player():
    return device < 0

func get_keyboard_player_prefix():
    return "kb" + str(abs(device))