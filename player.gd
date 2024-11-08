extends Node2D

@export
var device := 0
@export
var movespeed := 700

func _ready():
    print(Input.get_connected_joypads())

func _draw() -> void:
    draw_circle(position, 20, Color.WEB_GREEN)

func _process(delta: float) -> void:
    var dir = Vector2(1, 0) * Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
    dir.y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)

    position += dir * delta * movespeed
