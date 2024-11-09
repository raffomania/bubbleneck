extends Area2D

class_name Player

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
@export
var dash_range := 10

@onready
var bubble_sprite := $BubbleSprite

var weapon
var dead_color := Color.BLACK
var time := 0.0
var is_dashing := false
var dash_on_cooldown := false
    
func _ready():
    add_to_group('players')
    get_new_weapon()
    set_player_color(player_color)

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

        if Input.is_action_pressed(prefix + "_throw") and is_instance_valid(weapon):
            weapon.set_attack_button_pressed(true)
        elif is_instance_valid(weapon):
            weapon.set_attack_button_pressed(false)

    else:
        # Player is using a controller
        dir = Vector2(1, 0) * Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
        dir.y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
        
        if Input.is_joy_button_pressed(device, JOY_BUTTON_A) and not dash_on_cooldown:
            is_dashing = true

        if Input.is_joy_button_pressed(device, JOY_BUTTON_B) and is_instance_valid(weapon):
            weapon.set_attack_button_pressed(true)
        elif is_instance_valid(weapon):
            weapon.set_attack_button_pressed(false)

    # Move according to the dash curve, if dashing
    var curve_value = dash_curve.sample(time)
    dash_offset.x = curve_value * dir.x
    dash_offset.y = curve_value * dir.y
    dash_offset *= dash_range
    if time >= 1:
        time = 0
        stop_dashing()

    # While dashing, squish
    if is_dashing:
        bubble_sprite.scale.y = 0.6

    # Rotate in the direction we're walking
    if dir != Vector2.ZERO:
        rotation = dir.angle()
        bubble_sprite.rotation = dir.angle()

    # Move into the direction indicated by controller or keyboard
    position += dash_offset + dir * delta * movespeed
    
    # fix player sprite rotation so sprite highlight doesn't rotate
    $BubbleSprite.global_rotation_degrees = 0

    # Googly eyes
    $GooglyEyes.set_player_direction(dir, delta)

func stop_dashing():
    is_dashing = false
    dash_on_cooldown = true
    create_tween().tween_property(bubble_sprite, "scale", Vector2.ONE, 0.1)
    await get_tree().create_timer(dash_cooldown_seconds).timeout
    dash_on_cooldown = false

func set_player_color(color: Color):
    $BubbleSprite.self_modulate = color
    if is_instance_valid(weapon):
        var sprite = weapon.get_node('WeaponSprite')
        sprite.material.set("shader_parameter/color", color)

func get_new_weapon() -> void:
    var new_weapon = weapon_scene.instantiate()
    add_child(new_weapon)
    pick_up_weapon(new_weapon)

func pick_up_weapon(new_weapon) -> void:
    weapon = new_weapon
    var sprite = weapon.get_node('WeaponSprite')
    sprite.material.set("shader_parameter/color", player_color)
    weapon.reparent(self)
    weapon.rotation = PI / 2.0
    weapon.weapon_owner = self
    weapon.position = Vector2(8, 25)

    weapon.on_throw.connect(on_throw_weapon)

func on_throw_weapon():
    if weapon.on_throw.is_connected(on_throw_weapon):
        weapon.on_throw.disconnect(on_throw_weapon)
    weapon = null

func kill():
    dead = true
    set_player_color(dead_color)
    find_child('deathParticles').restart()
    find_child('deathParticles').emitting = true
    $BubbleSprite.visible = false
    $GooglyEyes.kill()
    await get_tree().create_timer(respawn_time).timeout
    print('respawn')
    respawn()

func respawn():
    dead = false
    set_player_color(player_color)
    find_child('deathParticles').emitting = false
    $BubbleSprite.visible = true
    var viewport = get_viewport_rect()
    global_position.x = viewport.size.x / 2
    global_position.y = viewport.size.y / 2
    if not is_instance_valid(weapon):
        get_new_weapon()
    queue_redraw()

func is_keyboard_player():
    return device < 0

func get_keyboard_player_prefix():
    return "kb" + str(abs(device))
