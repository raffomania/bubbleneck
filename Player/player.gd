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

class Parrying:
    extends State

    var parry_timer := 0.3

class Stunned:
    extends State

class WonRound:
    extends State


class ActionInput:
    var dash_pressed: bool
    var stab_pressed: bool
    var charge_pressed: bool
    var parry_pressed: bool
    var look_direction: Vector2
    # How far a player will move towards look_direction in a given frame.
    var drive: float


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
var shield_scene = preload("res://Player/shield.tscn")

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
var uncapped_kill_streak := 0

# ----- Movement ------
@export
var max_movespeed := 400
var rotation_speed := 5
var previous_look_direction := Vector2(1, 0)
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

func can_move() -> bool:
    return state is Moving or state is Idle

func can_rotate() -> bool:
    return state is Moving or state is Idle or state is ChargingThrow

func can_attack() -> bool:
    return is_instance_valid(weapon) and (state is Idle or state is Moving or state is Dashing)

func can_start_stab() -> bool:
    return can_attack() and is_instance_valid(weapon) and not weapon.stab_on_cooldown

func can_start_dash() -> bool:
    return state is Moving or state is Idle and dash_disabled_countdown > 0.0

func can_start_parry() -> bool:
    return state is Idle or state is Moving

# Returns the player inputs.
func get_action_inputs(delta: float) -> ActionInput:
    var inputs = ActionInput.new()
    if is_keyboard_player():
        var prefix = get_keyboard_player_prefix()

        var rotation_direction = Input.get_axis(prefix + "_left", prefix + "_right")
        inputs.look_direction = previous_look_direction.rotated(rotation_speed * delta * rotation_direction)
        inputs.drive = max(0, Input.get_axis(prefix + "_up", prefix + "_down") * -1)

        inputs.stab_pressed = Input.is_action_pressed(prefix + "_stab")
        inputs.charge_pressed = Input.is_action_pressed(prefix + "_throw")
        inputs.dash_pressed = Input.is_action_just_pressed(prefix + "_dash") and inputs.drive > 0.0
        inputs.parry_pressed = Input.is_action_just_pressed(prefix + "_dash") and not inputs.dash_pressed
    else:
        var controller_vector = Vector2()
        controller_vector.x = Input.get_joy_axis(controller_device_index, JOY_AXIS_LEFT_X)
        controller_vector.y = Input.get_joy_axis(controller_device_index, JOY_AXIS_LEFT_Y)
        if (controller_vector.length() < deadzone):
            controller_vector = Vector2.ZERO

        inputs.look_direction = controller_vector.normalized()
        inputs.drive = controller_vector.length()

        inputs.stab_pressed = Input.get_joy_axis(controller_device_index, JOY_AXIS_TRIGGER_RIGHT) > 0.5
        inputs.charge_pressed = Input.get_joy_axis(controller_device_index, JOY_AXIS_TRIGGER_LEFT) > 0.5
        inputs.dash_pressed = Input.is_joy_button_pressed(controller_device_index, JOY_BUTTON_A) and inputs.drive > 0.0
        inputs.parry_pressed = Input.is_joy_button_pressed(controller_device_index, JOY_BUTTON_A) and not inputs.dash_pressed


    return inputs

func update_eyes(actions: ActionInput) -> void:
    if actions.charge_pressed:
        $GooglyEyes.squint()
    elif actions.stab_pressed:
        $GooglyEyes.raise_eyes()
    else:
        $GooglyEyes.reset()


func _process(delta: float) -> void:
    if (state is Dead):
        return

    var actions = get_action_inputs(delta)

    handle_dash(delta, actions, actions.look_direction)
    handle_parry(delta, actions)
    update_invincibility(delta)
    handle_vulnerable_on_attack()
    update_weapon_visibility()
    update_eyes(actions)

    # Rotate in the look_direction we're walking
    if can_rotate() and actions.look_direction != Vector2.ZERO:
        previous_look_direction = actions.look_direction
        rotation = actions.look_direction.angle()
        bubble_sprite.rotation = actions.look_direction.angle()

        # fix player sprite rotation so sprite highlight doesn't rotate
        $BubbleSprite.global_rotation_degrees = 0

    if can_attack():
        if actions.charge_pressed:
            state = ChargingThrow.new()
        elif actions.stab_pressed and can_start_stab():
            weapon.stab()
            state = Stabbing.new()

    if state is Moving:
        animate_wobble(2.0)
        if actions.drive <= 0.0:
            state = Idle.new()
        # Move into the look_direction indicated by controller or keyboard
        position += actions.look_direction * delta * actions.drive * max_movespeed
        $GooglyEyes.walking_animation()
    elif state is Stabbing and not weapon.is_stabbing:
        # Stab is now finished
        state = Idle.new()
    elif state is ChargingThrow and not actions.charge_pressed:
        weapon.release_charge()
        state = Idle.new()
    elif state is Idle:
        animate_wobble(1.0)
        if actions.drive > 0.0:
            state = Moving.new()


func _input(_event):
    if state is InMinigame:
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
    if state is Dashing:
        weapon.visible = false
    else:
        weapon.visible = true

# Handle the player dash and dash cooldown.
func handle_dash(delta: float, actions: ActionInput, current_player_direction: Vector2) -> void:
    var dash_offset = Vector2()

    # The dash is still on cooldown, reduce the cooldown.
    if dash_disabled_countdown > 0:
        dash_disabled_countdown -= delta
        if dash_disabled_countdown <= 0:
            visualize_dashing_is_allowed_again()
        return

    # The player isn't dashing yet and the cooldown is not active.
    # Check whether we should start a new dash.
    if can_start_dash():
        # If we are now dashing, update some stuff.
        if actions.dash_pressed:
            state = Dashing.new()
            state.dash_direction = Vector2(current_player_direction).normalized()
            $'GooglyEyes'.blink(dash_duration)
            make_invincible(dash_protection_duration)
            $AudioStreamPlayer2D_Dash.play()

    # Return early if not dashing.
    if not state is Dashing:
        return

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


    # Update player position when in dash.
    if state is Dashing:
        position += dash_offset

func handle_parry(delta: float, actions: ActionInput):
    # Start a new parry
    if can_start_parry() and actions.parry_pressed:
        state = Parrying.new()
        var duration = state.parry_timer
        var scale_before = Vector2($BubbleSprite.scale)
        var tween = create_tween()
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.tween_property($BubbleSprite, "scale", scale_before * 1.3, duration * 0.2)
        tween.tween_property($BubbleSprite, "scale", scale_before, duration * 0.9)

    if state is not Parrying:
        return

    # Parry is still running
    state.parry_timer -= delta

    # Parry is now finished
    if state.parry_timer <= 0.0:
        state = Idle.new()

func animate_wobble(multiplier: float):
    var skew_intensity = 0.25
    var skew_speed = 0.005 * multiplier
    $BubbleSprite.skew = sin(Time.get_ticks_msec() * skew_speed) * skew_intensity

func update_invincibility(delta: float):
    if is_invincible():
        invincibility_countdown -= delta
        if invincibility_countdown <= 0:
            invincibility_countdown = 0
            make_vulnerable()

func handle_vulnerable_on_attack():
    if is_invincible() and (state is Stabbing or state is ChargingThrow):
        invincibility_countdown = 0

func make_invincible(duration: float):
    if (is_invincible()):
        return
    invincibility_countdown = duration
    var shield = shield_scene.instantiate()
    shield.get_node("Panel").material.set_shader_parameter("color", player_color)
    add_child(shield)

func visualize_dashing_is_allowed_again():
    var tween = get_tree().create_tween()
    var color = player_color.lightened(0.5)
    var flash_duration = 0.2
    tween.tween_property($BubbleSprite, "self_modulate", color, flash_duration / 2)
    tween.tween_property($BubbleSprite, "self_modulate", player_color, flash_duration / 2)
    tween.set_trans(Tween.TransitionType.TRANS_SINE)
    var loops = 2
    tween.set_loops(loops)

func make_vulnerable():
    $Shield.queue_free()
    #disconect shield area entered?

func is_invincible() -> bool:
    return get_node_or_null("Shield") != null


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
    uncapped_kill_streak = 0

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
    $Shield.queue_free()

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

func play_death_sound():
    var num: int = randi() % 3
    get_node("AudioStreamPlayer2D_Pop_" + str(num)).play()
    
# Returns an id that is offset by 2, as the controller_device_index starts at -2 for keyboards.
func get_id() -> int:
    return controller_device_index + 2

# Returns the name of a player.
func get_player_name() -> String:
    return 'Player %s' % get_color_description()

func get_color_description() -> String:
    return colors[get_id()]

func increment_kill_streak():
    radius = radius * 1.2
    scale = Vector2(radius, radius)
    uncapped_kill_streak += 1
    kill_streak = min(get_max_kill_streak(), kill_streak + 1)
    Globals.kill_streak_changed.emit(self)

    var label: KillStreakLabel = kill_streak_label_scene.instantiate()
    label.set_color(player_color)
    label.set_text("[center]" + str(kill_streak))
    get_node('/root/Main').add_child(label)
    label.set_global_position(global_position - get_label_offset())
    label.init()

func get_label_offset() -> Vector2:
    var padding = 30
    return Vector2(0, floor(get_height() / 2.0) + padding)

func get_max_kill_streak() -> int:
    var spawner: PlayerSpawner = get_node("/root/Main/PlayerSpawner")
    var total_players = spawner.get_total_players()
    var min_minigame_labels = Minigame.min_labels
    var max_minigame_labels = Minigame.max_labels

    return abs(min_minigame_labels - max_minigame_labels) - floor(total_players / 2)

func get_width() -> int:
    return $BubbleSprite.texture.get_width() * $BubbleSprite.scale.x * radius

func get_height() -> int:
    return $BubbleSprite.texture.get_height() * $BubbleSprite.scale.y * radius
