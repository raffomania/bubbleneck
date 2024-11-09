extends Area2D

var weapon_scene = preload("res://Weapon/weapon.tscn")

@export
var device := 0
@export
var movespeed := 400
@export
var player_color := Color.VIOLET
@export
var dash_curve: Curve
@export
var dash_cooldown_seconds := 0.5
@export
var time_factor := 20
@export
var radius := 20
@export
var dead := false
@export
var respawn_time := 3.0

@onready
var bubble_sprite := $BubbleSprite

var dead_color := Color.RED
var dash_range := 10
var time := 0.0
var is_dashing := false
var dash_on_cooldown := false
var is_holding_weapon := true
    
func _draw() -> void:
    if (dead):
        return
    var color = dead_color if dead else player_color
    draw_circle(Vector2.ZERO, radius, color, 2)

func _ready():
    add_to_group('players')
    setup_weapon()

func _process(delta: float) -> void:
    if (dead):
        return
    var dash_offset = Vector2()
    var dir: Vector2
    if is_dashing:
        time += delta * time_factor

    if is_keyboard_player():
        var prefix = get_keyboard_player_prefix()
        dir = Input.get_vector(prefix + "_left", prefix + "_right", prefix + "_up", prefix + "_down")

        if Input.is_action_just_pressed(prefix + "_dash") and not dash_on_cooldown:
            is_dashing = true

        if Input.is_action_just_pressed(prefix + "_throw"):
            throw_weapon(dir)

    else:
        # Player is using a controller
        dir = Vector2(1, 0) * Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
        dir.y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
        
        if Input.is_joy_button_pressed(device, JOY_BUTTON_A) and not dash_on_cooldown:
            is_dashing = true

        if Input.is_joy_button_pressed(device, JOY_BUTTON_B):
            throw_weapon(dir)

    var curve_value = dash_curve.sample(time)
    dash_offset.x = curve_value * dir.x
    dash_offset.y = curve_value * dir.y
    dash_offset *= dash_range
    if time >= 1:
        time = 0
        stop_dashing()

    if is_dashing:
        bubble_sprite.scale.y = 0.6

    if dir != Vector2.ZERO:
        rotation = dir.angle()
        bubble_sprite.rotation = dir.angle()
    position += dash_offset + dir * delta * movespeed

func stop_dashing():
    is_dashing = false
    dash_on_cooldown = true
    create_tween().tween_property(bubble_sprite, "scale", Vector2.ONE, 0.1)
    await get_tree().create_timer(dash_cooldown_seconds).timeout
    dash_on_cooldown = false

func setup_weapon():
    var weapon = $'Weapon/WeaponSprite'
    weapon.material.set("shader_parameter/color", player_color)
    
func throw_weapon(direction: Vector2):
    if is_holding_weapon:
        var weapon = weapon_scene.instantiate()
        var main_scene = get_tree().get_root().get_node("Main")
        main_scene.add_child(weapon)
        weapon.global_position = global_position
        weapon.throw(direction)
        weapon.rotation = direction.angle() + PI / 2

    is_holding_weapon = false

func kill():
    dead = true
    queue_redraw()
    find_child('deathParticles').emitting = true
    $BubbleSprite.visible = false
    await get_tree().create_timer(respawn_time).timeout
    print('respawn')
    respawn()

func respawn():
    dead = false
    find_child('deathParticles').emitting = false
    $BubbleSprite.visible = true
    var viewport = get_viewport_rect()
    global_position.x = viewport.size.x / 2
    global_position.y = viewport.size.y / 2
    queue_redraw()

func is_keyboard_player():
    return device < 0

func get_keyboard_player_prefix():
    return "kb" + str(abs(device))