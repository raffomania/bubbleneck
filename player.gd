extends Node2D

@export
var device := 0
@export
var movespeed := 700

@export
var dash_curve : Curve

@export 
var factor := 10

var dash_range := 2
var time := 0.0
var space_was_pressed = false
var dash_finished = false

func _ready():
    print(Input.get_connected_joypads())

func _draw() -> void:
    draw_circle(position, 30, Color.VIOLET, 2)

func _process(delta: float) -> void:
    var dash_offset = Vector2()
    var dir: Vector2
    if space_was_pressed and not dash_finished:
        time += delta * 2
    if is_keyboard_player():
        var prefix = get_keyboard_player_prefix()
        dir = Input.get_vector(prefix + "_left", prefix + "_right", prefix + "_up", prefix + "_down")
        if Input.is_action_just_pressed("ui_accept"):
            space_was_pressed = true
        var curve_value = dash_curve.sample(time) * factor
        dash_offset.x = curve_value * dir.x
        dash_offset.y = curve_value * dir.y
        dash_offset *= dash_range
        if time >= 1:
            time = 0
            space_was_pressed = false
        print(curve_value)

    else:
        dir = Vector2(1, 0) * Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
        dir.y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)

    position += dash_offset + dir * delta * movespeed

func is_keyboard_player():
    return device < 0

func get_keyboard_player_prefix():
    return "kb" + str(abs(device))
