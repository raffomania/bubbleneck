extends Area2D

class_name Player

var colors = {
    0: 'Cyan',
    1: 'Orange',
    2: 'Purple',
    3: 'Pink',
    4: 'Green',
    5: 'Yellow',
    6: 'Cyan',
    7: 'Orange',
    8: 'Purple',
}

var weapon_scene = preload("res://Weapon/weapon.tscn")
var minigame_scene = preload("res://Minigame/Minigame.tscn")

@export
var controller_device_index := 0

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

# When bouncing off the wall or bottle, disable movement
var stun_countdown := 0.0

# This is null when player is not carrying a weapon
var weapon
var stage_lost := false

# ----- Minigame ----- 
# This is set if the player is currently in a minigame
var minigame = null
var kill_streak := 0

# ----- Movement ------
@export
var max_movespeed := 400
var rotation_speed := 5
var look_direction := Vector2(1, 0)
@export var deadzone := 0.4

# ----- Dash related variables ----- 
# The curve that represents the the player dash movement.
@export
var dash_curve: Curve
var is_dashing := false
var dash_direction: Vector2
# The timer that tracks how far we're in a dash.

var dash_timer: float = 0.0
# How far the player should be able to dash.
@export
var dash_speed := 6
# The time how long a dash should last
@export
var dash_duration: float = 0.10
# The timer that tracks how long the dash is on cooldown.
var dash_disabled_countdown: float = 0.0
@export
# How long a player needs to wait until they can dash again
var dash_cooldown_seconds: float = 1.0

# ----- Invincibility related variables ----- 
var spawn_protection_duration: float = 3.5
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

    stun_countdown = max(0, stun_countdown - delta)
    handle_invincibility(delta)

    # var look_direction: Vector2
    var pressed_direction
    var move_strength := 0.0
    if is_keyboard_player():
        var prefix = get_keyboard_player_prefix()
        pressed_direction = Input.get_vector(prefix + "_left", prefix + "_right", prefix + "_up", prefix + "_down")
        look_direction = look_direction.rotated(rotation_speed * delta * pressed_direction.x)
        if pressed_direction.y <= -0.5:
            move_strength = 1.0
            
        if is_instance_valid(weapon):
            if Input.is_action_pressed(prefix + "_throw") and not is_in_minigame():
                $'GooglyEyes'.raise_eye()
                weapon.set_attack_button_pressed(true)
            elif Input.is_action_pressed(prefix + "_stab") and not is_in_minigame():
                weapon.stab()
            else:
                weapon.set_attack_button_pressed(false)

    else:
        # Player is using a controller
        var controller_vector = Vector2()
        controller_vector.x = Input.get_joy_axis(controller_device_index, JOY_AXIS_LEFT_X)
        controller_vector.y = Input.get_joy_axis(controller_device_index, JOY_AXIS_LEFT_Y)
        if (controller_vector.length() < deadzone):
            controller_vector = Vector2.ZERO

        look_direction = controller_vector.normalized()
        move_strength = controller_vector.length()
        
        if is_instance_valid(weapon):
            if Input.get_joy_axis(controller_device_index, JOY_AXIS_TRIGGER_RIGHT) > 0.5 and not is_in_minigame():
                $'GooglyEyes'.raise_eye()
                weapon.set_attack_button_pressed(true)
            elif Input.get_joy_axis(controller_device_index, JOY_AXIS_TRIGGER_LEFT) > 0.5 and not is_in_minigame():
                weapon.stab()
            else:
                weapon.set_attack_button_pressed(false)

    var dash_offset = handle_dash(delta, look_direction)

    update_weapon_visibility()

    # Rotate in the look_direction we're walking
    if look_direction != Vector2.ZERO:
        rotation = look_direction.angle()
        bubble_sprite.rotation = look_direction.angle()

    if is_movement_allowed():
        # Move in the look_direction we're dashing
        if is_dashing:
            position += dash_offset
        # Move into the look_direction indicated by controller or keyboard
        else:
            position += look_direction * delta * move_strength * max_movespeed
        
    if move_strength > 0.0 and is_movement_allowed():
        animate_wobble(2.0)
        $GooglyEyes.walking_animation()
    else:
        animate_wobble(1.0)
        $GooglyEyes.reset()
    
    # fix player sprite rotation so sprite highlight doesn't rotate
    $BubbleSprite.global_rotation_degrees = 0


func _input(_event):
    if is_in_minigame():
        if is_keyboard_player():
            var prefix = get_keyboard_player_prefix()
            if Input.is_action_just_pressed(prefix + "_dash"):
                stop_minigame()
        else:
            if Input.is_joy_button_pressed(controller_device_index, JOY_BUTTON_A):
                stop_minigame()

func update_weapon_visibility():
    if not is_instance_valid(weapon):
        return
    if is_dashing:
        weapon.visible = false
    else:
        weapon.visible = true

# Handle the player dash
# Returns a Vector that indicates the dash look_direction.
# The vector is empty if no dash is active.
func handle_dash(delta: float, current_player_direction: Vector2) -> Vector2:
    var dash_offset = Vector2()

    # The dash is still on cooldown, reduce the cooldown.
    if dash_disabled_countdown > 0:
        dash_disabled_countdown -= delta
        return dash_offset

    # The player isn't dashing yet and the cooldown is not active.
    # Check whether we should start a new dash.
    if not is_dashing and is_movement_allowed():
        var just_started_dashing = false
        if is_keyboard_player():
            var prefix = get_keyboard_player_prefix()
            if Input.is_action_just_pressed(prefix + "_dash"):
                just_started_dashing = true
        else:
            if Input.is_joy_button_pressed(controller_device_index, JOY_BUTTON_A):
                just_started_dashing = true

        # If we are now dashing, update some stuff.
        if just_started_dashing:
            is_dashing = true
            dash_direction = Vector2(current_player_direction).normalized()
            $'GooglyEyes'.blink(dash_duration)
            make_invincible(dash_protection_duration)
            $AudioStreamPlayer2D_Dash.play()

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
    # var relative_elapsed_time = dash_timer / dash_duration
    # var curve_value = dash_curve.sample(relative_elapsed_time)
    # TODO fix this
    var curve_value = 50 * delta
    dash_offset.x = curve_value * dash_direction.x
    dash_offset.y = curve_value * dash_direction.y
    dash_offset *= dash_speed

    # If we reached the end of the dashing duration.
    # Cancel the dash and start the cooldown.
    if dash_timer >= dash_duration:
        # Reset the dashing logic.
        dash_timer = 0
        is_dashing = false
        bubble_sprite.skew = 0
        # Start the cooldown
        dash_disabled_countdown = dash_cooldown_seconds

    return dash_offset


func animate_wobble(multiplier: float):
    var skew_intensity = 0.25
    var skew_speed = 0.005 * multiplier
    $BubbleSprite.skew = sin(Time.get_ticks_msec() * skew_speed) * skew_intensity

# Handle all logic around the player's invincibility (blinking + timer)
func handle_invincibility(delta: float):
    if is_invincible():
        invincibility_countdown -= delta


func make_invincible(duration: float):
    invincibility_countdown = duration
    var tween = get_tree().create_tween()
    var color = Color(player_color)
    color.a = 0.2
    var flash_duration = 0.4
    tween.tween_property($BubbleSprite, "self_modulate", color, flash_duration / 2)
    tween.tween_property($BubbleSprite, "self_modulate", player_color, flash_duration / 2)
    tween.set_trans(Tween.TransitionType.TRANS_SINE)
    var loops = floori(duration / flash_duration)
    tween.set_loops(loops)


func is_invincible() -> bool:
    return invincibility_countdown > 0.0


func set_player_color(color: Color):
    $BubbleSprite.self_modulate = color
    $GooglyEyes.modulate = color.lightened(0.1)
    if is_instance_valid(weapon):
        var sprite = weapon.get_node('WeaponSprite')
        sprite.material.set("shader_parameter/color", color)


func get_new_weapon() -> void:
    if is_instance_valid(weapon):
        return

    var new_weapon: Weapon = weapon_scene.instantiate()
    add_child.call_deferred(new_weapon)
    pick_up_weapon.call_deferred(new_weapon)

func pick_up_weapon(new_weapon) -> void:
    weapon = new_weapon
    var sprite = weapon.get_node('WeaponSprite')
    sprite.material.set("shader_parameter/color", player_color)
    if weapon.get_parent() != null:
        weapon.reparent(self)
    weapon.rotation = 0
    weapon.weapon_owner = self
    weapon.base_weapon_position = Vector2($WeaponPosition.position)
    weapon.on_throw.connect(on_throw_weapon)

func on_throw_weapon():
    if weapon.on_throw.is_connected(on_throw_weapon):
        weapon.on_throw.disconnect(on_throw_weapon)
    weapon = null

func kill(muted = false):
    if dead:
        return
    # Don't kill invincible players.
    if is_invincible():
        return

    if is_instance_valid(weapon):
        weapon.drop()

        weapon = null

    dead = true
    kill_streak = 0

    if not muted:
        play_death_sound()

    stop_minigame()
    find_child('deathParticles').restart()

    $BubbleSprite.visible = false
    $GooglyEyes.kill()
    Globals.player_killed.emit(self)

    await get_tree().create_timer(respawn_time).timeout
    respawn()

func respawn():
    if stage_lost:
        return

    var bottle = get_tree().root.get_node("Main/PlayerSpawner").bottle
    # Stay dead on sudden death
    if bottle.sudden_death:
        return

    dead = false
    # Spawn protection
    make_invincible(spawn_protection_duration)
    get_new_weapon()

    set_player_color(player_color)
    find_child('deathParticles').emitting = false
    $BubbleSprite.visible = true
    $GooglyEyes.respawn()

    # Set the respawn position based on current level.
    global_position = bottle.get_respawn_position()

    # if not is_instance_valid(weapon):
    #     get_new_weapon()
    queue_redraw()

func is_keyboard_player():
    return controller_device_index < 0

func get_keyboard_player_prefix():
    return "kb" + str(abs(controller_device_index))

func is_in_minigame() -> bool:
    return is_instance_valid(minigame)

func start_minigame() -> Minigame:
    if dead:
        return

    if is_in_minigame():
        return minigame

    var new_minigame: Minigame = minigame_scene.instantiate()
    new_minigame.color = player_color
    new_minigame.player = self
    var direction_to_center = ((get_viewport_rect().size / 2) - global_position).normalized()
    get_parent().add_child(new_minigame)
    new_minigame.create_labels()
    new_minigame.global_position = global_position + direction_to_center * 200

    new_minigame.finished.connect(self.win)

    minigame = new_minigame

    return new_minigame

func stop_minigame():
    if not is_in_minigame():
        return
    
    minigame.abort()

func win():
    make_invincible(5.0)

    # $AudioStreamPlayer2D_Win.play()

    if is_instance_valid(weapon):
        weapon.queue_free()
    for player in get_tree().get_nodes_in_group("players"):
        if player != self:
            player.stage_lost = true
            player.kill(true)

func bounce_back(bounce_direction: Vector2):
    if is_in_minigame():
        return
    var tween = get_tree().create_tween()
    var bounce_duration = 0.05
    stun_countdown = bounce_duration
    tween.tween_property(self, "global_position", global_position + bounce_direction, bounce_duration)

func is_movement_allowed():
    var is_attacking = is_instance_valid(weapon) and (weapon.is_stabbing or weapon.is_charging_throw)
    var is_stunned = stun_countdown > 0
    return !is_attacking and !is_in_minigame() and !is_stunned

func play_death_sound():
    var num: int = randi() % 3
    get_node("AudioStreamPlayer2D_Pop_" + str(num)).play()
    
# Returns an id that is offset by 2, as the controller_device_index starts at -2 for keyboards.
func get_id() -> int:
    return controller_device_index + 2

# Returns the name of a player.
func get_player_name() -> String:
    return 'Player %s' % colors[get_id()]


func increment_kill_streak():
    kill_streak += 1

