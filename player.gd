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
    var dir
    if device == -1:
        dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    else:
        dir = Vector2(1, 0) * Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
        dir.y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)

    position += dir * delta * movespeed
