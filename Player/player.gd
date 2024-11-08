extends Node2D

@export
var device := 0
@export
var movespeed := 400

@export
var player_color := Color.VIOLET

@export
var dash_curve: Curve

@export
var time_factor := 20

@export
var radius := 20

var dash_range := 10
var time := 0.0
var is_dashing := false

@export
var dead := false
    
func _draw() -> void:
    draw_circle(Vector2.ZERO, radius, player_color, 2)

func _ready():
    print(Input.get_connected_joypads())
    add_to_group('players')
    setup_weapon()

func _process(delta: float) -> void:
    var dash_offset = Vector2()
    var dir: Vector2
    if is_dashing:
        time += delta * time_factor

    if is_keyboard_player():
        var prefix = get_keyboard_player_prefix()
        dir = Input.get_vector(prefix + "_left", prefix + "_right", prefix + "_up", prefix + "_down")

        if Input.is_action_just_pressed(prefix + "_dash"):
            is_dashing = true

    else:
        # Player is using a controller
        dir = Vector2(1, 0) * Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
        dir.y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
        
        if Input.is_joy_button_pressed(device, JOY_BUTTON_A):
            is_dashing = true

    set_weapon_rotation(dir)

    var curve_value = dash_curve.sample(time)
    dash_offset.x = curve_value * dir.x
    dash_offset.y = curve_value * dir.y
    dash_offset *= dash_range
    if time >= 1:
        time = 0
        is_dashing = false
        create_tween().tween_property(self, "scale", Vector2.ONE, 0.1)

    if is_dashing:
        scale.y = 0.6
        rotation = dir.angle()

    position += dash_offset + dir * delta * movespeed

func is_keyboard_player():
    return device < 0

func get_keyboard_player_prefix():
    return "kb" + str(abs(device))

func setup_weapon():
    var weapon = $Weapon
    weapon.material.set("shader_parameter/color", player_color)
    var weapon_offset = 10
    weapon.position.x += radius + weapon_offset

func set_weapon_rotation(dir):
    if (dir == Vector2.ZERO):
        return
    rotation = dir.angle() + PI / 2

func kill():
    dead = true
    player_color = Color.RED
    queue_redraw()    queue_redraw()
