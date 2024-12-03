extends Area2D

class_name Player

class State:
    pass

class InMinigame:
    extends State

    var minigame: Minigame

class Moving:
    extends State

    var direction: Vector2

class Dead:
    extends State

class Idle:
    extends State

class Dashing:
    extends State

    var dash_direction: Vector2
    # The timer that tracks how far we're in a dash.
    var dash_timer: float = 0.0

class ChargingThrow:
    extends State

class Stabbing:
    extends State

class Stunned:
    extends State

class WonRound:
    extends State

var state: State = Idle.new()

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

var kill_streak_label_scene = preload("res://Player/KillStreakLabel/kill_streak_label.tscn")

var weapon_scene = preload("res://Weapon/weapon.tscn")
var minigame_scene = preload("res://Minigame/Minigame.tscn")

@export
var controller_device_index := 0

@export
var player_color := Color.VIOLET
@export
var radius := 1.5

@export
var respawn_time := 3.0

@onready
var bubble_sprite := $BubbleSprite

# This is null when player is not carrying a weapon
var weapon
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
# How far the player should be able to dash.
@export
var dash_speed := 6
# The time how long a dash should last
@export
var dash_duration: float = 0.10
@export
# How long a player needs to wait until they can dash again
var dash_cooldown_seconds: float = 1.0
# The timer that tracks how long the dash is on cooldown.
var dash_disabled_countdown: float = 0.0

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
    if (state is Dead):
        return

    handle_invincibility(delta)

    # var look_direction: Vector2
    var move_strength := 0.0
    var prefix = get_keyboard_player_prefix()
    if can_rotate():
        if is_keyboard_player():
            var rotation_direction = Input.get_axis(prefix + "_left", prefix + "_right")
            look_direction = look_direction.rotated(rotation_speed * delta * rotation_direction)
            move_strength = max(0, Input.get_axis(prefix + "_up", prefix + "_down") * -1)
        else:
            # Player is using a controller
            var controller_vector = Vector2()
            controller_vector.x = Input.get_joy_axis(controller_device_index, JOY_AXIS_LEFT_X)
            controller_vector.y = Input.get_joy_axis(controller_device_index, JOY_AXIS_LEFT_Y)
            if (controller_vector.length() < deadzone):
                controller_vector = Vector2.ZERO

            look_direction = controller_vector.normalized()
            move_strength = controller_vector.length()

        if move_strength > 0.0 and can_move():
            state = Moving.new()

    if is_keyboard_player():
        if Input.is_action_pressed(prefix + "_throw"):
            if can_attack():
                $'GooglyEyes'.raise_eye()
                weapon.set_attack_button_pressed(true)
                state = ChargingThrow.new()
        elif Input.is_action_pressed(prefix + "_stab"):
            if can_attack():
                weapon.stab()
                state = Stabbing.new()
        elif state is ChargingThrow or (state is Stabbing and not weapon.is_stabbing):
            weapon.set_attack_button_pressed(false)
            state = Idle.new()
    else:
        if Input.get_joy_axis(controller_device_index, JOY_AXIS_TRIGGER_RIGHT) > 0.5:
            if can_attack():
                $'GooglyEyes'.raise_eye()
                weapon.set_attack_button_pressed(true)
                state = ChargingThrow.new()
        elif Input.get_joy_axis(controller_device_index, JOY_AXIS_TRIGGER_LEFT) > 0.5:
            if can_attack():
                weapon.stab()
                state = Stabbing.new()
        elif state is ChargingThrow or (state is Stabbing and not weapon.is_stabbing):
            weapon.set_attack_button_pressed(false)
            state = Idle.new()

    var dash_offset = handle_dash(delta, look_direction)

    update_weapon_visibility()

    # Rotate in the look_direction we're walking
    if look_direction != Vector2.ZERO and can_rotate():
        rotation = look_direction.angle()
        bubble_sprite.rotation = look_direction.angle()

    if state is Dashing:
        position += dash_offset
    elif can_move():
        # Move in the look_direction we're dashing
        # Move into the look_direction indicated by controller or keyboard
        position += look_direction * delta * move_strength * max_movespeed
        
    if move_strength > 0.0 and can_move():
        animate_wobble(2.0)
        $GooglyEyes.walking_animation()
    elif state is Idle:
        animate_wobble(1.0)
        $GooglyEyes.reset()
    
    # fix player sprite rotation so sprite highlight doesn't rotate
    $BubbleSprite.global_rotation_degrees = 0


func _input(_event):
    if state is InMinigame:
        if is_keyboard_player():
            var prefix = get_keyboard_player_prefix()
            if Input.is_action_just_pressed(prefix + "_dash"):
                stop_minigame()
        else:
            if Input.is_joy_button_pressed(controller_device_index, JOY_BUTTON_A):
                print("stop minigame")
                stop_minigame()

func update_weapon_visibility():
    if not is_instance_valid(weapon):
        return
    if state is Dashing:
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
    if not state is Dashing and can_move():
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
            state = Dashing.new()
            state.dash_direction = Vector2(current_player_direction).normalized()
            $'GooglyEyes'.blink(dash_duration)
            make_invincible(dash_protection_duration)
            $AudioStreamPlayer2D_Dash.play()

    # Return early if no button is pressed
    if not state is Dashing:
        return dash_offset

    # Dash is active, increment the timer
    state.dash_timer += delta

    bubble_sprite.skew = 0.6

    # Move according to the dash curve.
    # The dash curve expects values from `0-1`
    # To get the correct position on the curve, we simply calculate the curve position
    # Based on the relative elapsed time to the total dash time.
    # var relative_elapsed_time = dash_timer / dash_duration
    # var curve_value = dash_curve.sample(relative_elapsed_time)
    # TODO fix this
    var curve_value = 50 * delta
    dash_offset.x = curve_value * state.dash_direction.x
    dash_offset.y = curve_value * state.dash_direction.y
    dash_offset *= dash_speed

    # If we reached the end of the dashing duration.
    # Cancel the dash and start the cooldown.
    if state.dash_timer >= dash_duration:
        # Reset the dashing logic.
        state.dash_timer = 0
        state = Idle.new()
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

func kill():
    # Always die, no matter the circumstances
    var regular_kill = Globals.state is not Globals.RoundOver

    if state is Dead:
        return
    # Don't kill invincible players.
    if is_invincible() and regular_kill:
        return


    if is_instance_valid(weapon):
        weapon.drop()

        weapon = null

    kill_streak = 0

    if regular_kill:
        play_death_sound()

    stop_minigame()
    find_child('deathParticles').restart()

    $BubbleSprite.visible = false
    $GooglyEyes.kill()
    state = Dead.new()
    Globals.player_killed.emit(self)

    await get_tree().create_timer(respawn_time).timeout
    respawn()

func respawn():
    if Globals.state is not Globals.RoundRunning:
        return

    var bottle = get_tree().root.get_node("Main/PlayerSpawner").bottle

    state = Idle.new()
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

func start_minigame() -> Minigame:
    if state is not Moving:
        return

    if state is InMinigame:
        return state.minigame

    var new_minigame: Minigame = minigame_scene.instantiate()
    new_minigame.color = player_color
    new_minigame.player = self
    var direction_to_center = ((get_viewport_rect().size / 2) - global_position).normalized()
    get_parent().add_child(new_minigame)
    new_minigame.create_labels()
    new_minigame.global_position = global_position + direction_to_center * 200

    new_minigame.finished.connect(self.win)

    state = InMinigame.new()
    state.minigame = new_minigame

    return new_minigame

func stop_minigame():
    if state is not InMinigame:
        return
    
    state.minigame.abort()

    state = Idle.new()

func win():
    make_invincible(5.0)

    state = WonRound.new()
    Globals.state = Globals.RoundOver.new()

    # $AudioStreamPlayer2D_Win.play()

    if is_instance_valid(weapon):
        weapon.queue_free()
    for player in get_tree().get_nodes_in_group("players"):
        if player != self:
            player.kill()

func bounce_back(bounce_direction: Vector2):
    if state is InMinigame:
        return
    state = Stunned.new()
    var tween = get_tree().create_tween()
    var bounce_duration = 0.05
    tween.tween_property(self, "global_position", global_position + bounce_direction, bounce_duration)
    await tween.finished
    state = Idle.new()

func can_move() -> bool:
    return state is Moving or state is Idle

func can_rotate() -> bool:
    return state is Moving or state is Idle or state is ChargingThrow

func can_attack() -> bool:
    return is_instance_valid(weapon) and (state is Idle or state is Moving or state is Dashing)

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

    var label: KillStreakLabel = kill_streak_label_scene.instantiate()
    label.set_color(player_color)
    label.set_text("[center]" + str(kill_streak))
    get_node('/root/Main').add_child(label)
    label.set_global_position(global_position - get_label_offset())
    label.init()

func get_label_offset() -> Vector2:
    var padding = 30
    return Vector2(0, $BubbleSprite.texture.get_height() * $BubbleSprite.scale.y * radius / 2 + padding)
