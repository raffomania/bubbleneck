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
var radius := 20
@export
var dead := false
@export
var respawn_time := 3.0

@onready
var bubble_sprite := $BubbleSprite

var weapon
var dead_color := Color.BLACK
var is_in_minigame := false

# ----- Dash related variables ----- 
# The curve that represents the the player dash movement.
@export
var dash_curve: Curve
var is_dashing := false
# The timer that tracks how far we're in a dash.
@export
var dash_timer := 0.0
# How far the player should be able to dash.
@export
var dash_speed := 10
# The time how long a dash should last.
var dash_duration := 0.05
# The timer that tracks how long the dash is on cooldown.
var dash_cooldown := 0
# How long a player needs to wait until they can dash again
var dash_cooldown_seconds := 1.0

func _ready():
    add_to_group('players')
    get_new_weapon()
    set_player_color(player_color)

func _process(delta: float) -> void:
    if (dead):
        return

    var direction: Vector2
    if is_keyboard_player():
        var prefix = get_keyboard_player_prefix()
        direction = Input.get_vector(prefix + "_left", prefix + "_right", prefix + "_up", prefix + "_down")

        if Input.is_action_pressed(prefix + "_throw") and is_instance_valid(weapon):
            weapon.set_attack_button_pressed(true)
        elif is_instance_valid(weapon):
            weapon.set_attack_button_pressed(false)

    else:
        # Player is using a controller
        direction = Vector2(1, 0) * Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
        direction.y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
        
        if Input.is_joy_button_pressed(device, JOY_BUTTON_B) and is_instance_valid(weapon):
            weapon.set_attack_button_pressed(true)
        elif is_instance_valid(weapon):
            weapon.set_attack_button_pressed(false)

    var dash_offset = handle_dash(delta, direction)

    # Rotate in the direction we're walking
    if direction != Vector2.ZERO:
        rotation = direction.angle()
        bubble_sprite.rotation = direction.angle()

    var is_attacking = is_instance_valid(weapon) and (weapon.is_stabbing or weapon.attack_button_pressed)
    if not is_attacking:
        # Move into the direction indicated by controller or keyboard
        position += dash_offset + direction * delta * movespeed
    
    # fix player sprite rotation so sprite highlight doesn't rotate
    $BubbleSprite.global_rotation_degrees = 0

    # Googly eyes
    $GooglyEyes.set_player_direction(direction, delta)

# Handle the player dash
# Returns a Vector that indicates the dash direction.
# The vector is empty if no dash is active.
func handle_dash(delta: float, direction: Vector2) -> Vector2:
    var dash_offset = Vector2()

    # The dash is still on cooldown, reduce the cooldown.
    if dash_cooldown > 0:
        print("dash_cooldown active: %s, ms: %s, curve: %s" % [dash_cooldown])
        dash_cooldown -= delta
        return dash_offset

    # The player isn't dashing yet and the cooldown is not active.
    # Check whether we should start a new dash.
    if not is_dashing:
        if is_keyboard_player():
            var prefix = get_keyboard_player_prefix()
            if Input.is_action_just_pressed(prefix + "_dash"):
                print("Activating dash")
                is_dashing = true
        else:
            if Input.is_joy_button_pressed(device, JOY_BUTTON_A):
                print("Activating dash")
                is_dashing = true

        # Return early if no button is pressed
        if not is_dashing:
            return dash_offset

    # Dash is active, increment the timer
    dash_timer += delta

    # Move according to the dash curve.
    # The dash curve expects values from `0-1`
    # To get the correct position on the curve, we simply calculate the curve position
    # Based on the relative elapsed time to the total dash time.
    var relative_elapsed_time = dash_timer / dash_duration
    var curve_value = dash_curve.sample(relative_elapsed_time)
    print("timer: %s, ms: %s, curve: %s" % [dash_timer, relative_elapsed_time, curve_value])
    dash_offset.x = curve_value * direction.x
    dash_offset.y = curve_value * direction.y
    dash_offset *= dash_speed

    # If we reached the end of the dashing duration.
    # Cancel the dash and start the cooldown.
    if dash_timer >= dash_duration:
        print("Stopping dash timer")
        # Reset the dashing logic.
        dash_timer = 0
        is_dashing = false
        # Start the cooldown
        dash_cooldown = dash_cooldown_seconds

    return dash_offset

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
    if dead:
        return

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
    $GooglyEyes.respawn()
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

