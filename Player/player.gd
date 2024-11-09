extends Area2D

class_name Player

var weapon_scene = preload("res://Weapon/weapon.tscn")
var minigame_scene = preload("res://Minigame/Minigame.tscn")

@export
var device := 0
@export
var movespeed := 400
@export
var player_color := Color.VIOLET
@export
var radius := 1.5
@export
var dead := false
@export
var respawn_time := 3.0

@onready
var bubble_sprite := $BubbleSprite

var is_in_bounce_back := false

var weapon
var dead_color := Color.BLACK

# ----- Minigame ----- 
var minigame = null

# ----- Dash related variables ----- 
# The curve that represents the the player dash movement.
@export
var dash_curve: Curve
var is_dashing := false
# The timer that tracks how far we're in a dash.

var dash_timer: float = 0.0
# How far the player should be able to dash.
@export
var dash_speed := 6
# The time how long a dash should last.
@export
var dash_duration: float = 0.10
# The timer that tracks how long the dash is on cooldown.
var dash_cooldown: float = 0.0
@export
# How long a player needs to wait until they can dash again
var dash_cooldown_seconds: float = 1.0

# ----- Invincibility related variables ----- 
var spawn_protection_duration: float = 1.5
var dash_protection_duration: float = 0.5
var invincibility_countdown: float = 0.0

func _ready():
    add_to_group('players')
    get_new_weapon()
    set_player_color(player_color)

    # Spawn protection
    make_invincible(spawn_protection_duration)
    
    scale = Vector2(radius, radius)

func _process(delta: float) -> void:
    if (dead):
        return

    handle_invincibility(delta)

    var direction: Vector2
    if is_keyboard_player():
        var prefix = get_keyboard_player_prefix()
        direction = Input.get_vector(prefix + "_left", prefix + "_right", prefix + "_up", prefix + "_down")

        if Input.is_action_pressed(prefix + "_throw"):
            $'GooglyEyes'.raise_eye()
            if is_instance_valid(weapon):
                weapon.set_attack_button_pressed(true)
        elif Input.is_action_pressed(prefix + "_stab"):
            if is_instance_valid(weapon):
                weapon.stab()
        elif is_instance_valid(weapon):
                weapon.set_attack_button_pressed(false)

    else:
        # Player is using a controller
        direction = Vector2(1, 0) * Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
        direction.y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
        
        if Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) > 0.5:
            $'GooglyEyes'.raise_eye()
            if is_instance_valid(weapon):
                weapon.set_attack_button_pressed(true)
        elif Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT) > 0.5 and is_instance_valid(weapon):
            weapon.stab()
        elif is_instance_valid(weapon):
                weapon.set_attack_button_pressed(false)

    var dash_offset = handle_dash(delta, direction)

    # Rotate in the direction we're walking
    if direction != Vector2.ZERO:
        rotation = direction.angle()
        bubble_sprite.rotation = direction.angle()

    if is_movement_allowed():
        # Move into the direction indicated by controller or keyboard
        position += dash_offset + direction * delta * movespeed
    
    # fix player sprite rotation so sprite highlight doesn't rotate
    $BubbleSprite.global_rotation_degrees = 0

    # Googly eyes
    if direction:
        $GooglyEyes.walking_animation()
    else:
        $GooglyEyes.reset_googly_position()


# Handle the player dash
# Returns a Vector that indicates the dash direction.
# The vector is empty if no dash is active.
func handle_dash(delta: float, direction: Vector2) -> Vector2:
    var dash_offset = Vector2()

    # The dash is still on cooldown, reduce the cooldown.
    if dash_cooldown > 0:
        dash_cooldown -= delta
        return dash_offset

    # The player isn't dashing yet and the cooldown is not active.
    # Check whether we should start a new dash.
    if not is_dashing:
        if is_keyboard_player():
            var prefix = get_keyboard_player_prefix()
            if Input.is_action_just_pressed(prefix + "_dash"):
                is_dashing = true
                make_invincible(dash_protection_duration)
        else:
            if Input.is_joy_button_pressed(device, JOY_BUTTON_A):
                is_dashing = true
                make_invincible(dash_protection_duration)

        # Return early if no button is pressed
        if not is_dashing:
            return dash_offset

    # Dash is active, increment the timer
    dash_timer += delta

    bubble_sprite.skew = 0.6

    # Move according to the dash curve.
    # The dash curve expects values from `0-1`
    # To get the correct position on the curve, we simply calculate the curve position
    # Based on the relative elapsed time to the total dash time.
    var relative_elapsed_time = dash_timer / dash_duration
    var curve_value = dash_curve.sample(relative_elapsed_time)
    dash_offset.x = curve_value * direction.x
    dash_offset.y = curve_value * direction.y
    dash_offset *= dash_speed

    # If we reached the end of the dashing duration.
    # Cancel the dash and start the cooldown.
    if dash_timer >= dash_duration:
        # Reset the dashing logic.
        dash_timer = 0
        is_dashing = false
        bubble_sprite.skew = 0
        # Start the cooldown
        dash_cooldown = dash_cooldown_seconds

    return dash_offset

# Handle all logic around the player's invincibility (blinking + timer)
func handle_invincibility(delta: float):
    if is_invincible():
        invincibility_countdown -= delta


func make_invincible(duration: float):
    invincibility_countdown = duration


func is_invincible() -> bool:
    return invincibility_countdown > 0.0


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
    # Don't kill invincible players.
    if is_invincible():
        return

    dead = true
    stop_minigame()
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
    # Spawn protection
    make_invincible(spawn_protection_duration)

    set_player_color(player_color)
    find_child('deathParticles').emitting = false
    $BubbleSprite.visible = true
    $GooglyEyes.respawn()
    global_position = get_respawn_position()
    # if not is_instance_valid(weapon):
    #     get_new_weapon()
    queue_redraw()

func get_respawn_position() -> Vector2:
    var rand_offset = Vector2(randf() * 100 - 50, randf() * 100 - 50)

    if (false):
        return get_viewport_rect().size / 2
    else:
        var bottle = get_tree().root.get_node("Main/PlayerSpawner").bottle
        return bottle.get_bottle_floor(200) + rand_offset
    
func is_keyboard_player():
    return device < 0

func get_keyboard_player_prefix():
    return "kb" + str(abs(device))

func is_in_minigame():
    return is_instance_valid(minigame)

func start_minigame():
    if is_in_minigame():
        return minigame

    minigame = minigame_scene.instantiate()
    minigame.color = player_color
    minigame.device = device
    add_child(minigame)

    minigame.finished.connect(self.win)

    return minigame

func stop_minigame():
    if not is_in_minigame():
        return
    
    minigame.queue_free()

func win():
    if is_instance_valid(weapon):
        weapon.queue_free()
    for player in get_tree().get_nodes_in_group("players"):
        if player != self:
            player.kill()

func bounce_back(direction: Vector2):
    var tween = get_tree().create_tween()
    is_in_bounce_back = true
    tween.tween_property(self, "global_position", global_position + direction, 0.05)
    tween.tween_callback(func(): is_in_bounce_back = false)

func is_movement_allowed():
    var is_attacking = is_instance_valid(weapon) and (weapon.is_stabbing or weapon.attack_button_pressed)
    return !is_attacking and !is_in_minigame() and !is_in_bounce_back
