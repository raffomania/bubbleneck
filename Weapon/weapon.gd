extends Node2D

class_name Weapon

class State:
    pass

class Carrying:
    extends State

class ChargingStab:
    extends State

class Stabbing:
    extends State
    var stab_tween : Tween

class ChargingThrow:
    extends State
    var charging_throw_since: float

class Flying:
    extends State
    var throwing_time := 0.0
    var throwing_range_seconds := 0.0
    var throw_direction

class LyingOnGround:
    extends State

class Disarming:
    extends State

var state: State = Carrying.new()

var stab_is_on_cooldown := false
var weapon_owner: Player

@export
var throw_distance := 0.0
@export
var throw_curve: Curve
@export
var time_factor := 1.0
@export
var throw_speed := 2000.0
@export
var stab_cooldown_seconds: float = 0.5
@export
var stab_duration_seconds: float
@export
var stab_button_press_threshold_seconds: float
@export
var stab_distance: float = 50
@export
var max_throwing_range_seconds: float

var base_weapon_scale: Vector2
var base_weapon_position: Vector2

signal on_throw

func _ready() -> void:
    base_weapon_scale = $WeaponSprite.scale
    add_to_group('weapons')

func _process(delta: float) -> void:
    process_flying(delta)
    process_charging_throw(delta)
    wobble()

func _draw() -> void:
    if state is ChargingThrow and is_instance_valid(weapon_owner):
        var start = Vector2.RIGHT * 30
        # TODO exact laserpointer lenght
        var direction_vector = Vector2.RIGHT * (state.charging_throw_since * 600)
        var end = start + direction_vector
        draw_line(start, end, weapon_owner.player_color, -1.0, true)

func process_flying(delta):
    if not state is Flying:
        return
    state.throwing_time += delta * time_factor
    throw_distance = throw_speed
    global_position += state.throw_direction * delta * throw_distance

    if state.throwing_time > state.throwing_range_seconds:
        end_throw()

func process_charging_throw(delta):
    if not state is ChargingThrow:
        return
    state.charging_throw_since = min(max_throwing_range_seconds, state.charging_throw_since + delta)
    if state.charging_throw_since >= stab_button_press_threshold_seconds:
        $Highlight.visible = true
    position.x = base_weapon_position.x - state.charging_throw_since * 20
    $WeaponSprite.scale.x = base_weapon_scale.x + state.charging_throw_since * 0.2
    queue_redraw()

func wobble():
    var wobble_strength = 0
    if state is Carrying:
        wobble_strength = 4 

    if state is ChargingThrow:
        wobble_strength = 2

    if wobble_strength > 0:
        position = base_weapon_position + Vector2.UP * sin(Time.get_ticks_msec() * 0.01) * wobble_strength

func release_charge() -> void:
    if state is ChargingThrow and state.charging_throw_since >= stab_button_press_threshold_seconds:
        throw()
    else:
        state = Carrying.new()
    end_attack_charge()
    queue_redraw()

func end_attack_charge():
    $Highlight.visible = false
    $WeaponSprite.scale.x = base_weapon_scale.x

func throw() -> void:
    if not state is ChargingThrow:
        return
    var charged_for_seconds = state.charging_throw_since  
    state = Flying.new()
    state.throw_direction = Vector2.RIGHT.rotated(global_rotation)
    var main_scene = get_tree().get_root().get_node("Main")
    reparent(main_scene)
    state.throwing_range_seconds = charged_for_seconds  * 1.5
    $Hitbox.check_now()
    on_throw.emit()

func end_throw() -> void:
    $Hitbox.check_now()
    state = LyingOnGround.new()
    weapon_owner = null
    
func stick() -> void:
    state = LyingOnGround.new()

func attach_to_player(player: Player) -> void:
    if not state is LyingOnGround:
        return
    if player.has_weapon():
        return

    weapon_owner = player
    player.pick_up_weapon.call_deferred(self)

func hit_player(target: Player) -> void:
    # Weapon cannot kill owner and only while throwing or stabbing
    var is_attacking = state is Flying or state is Stabbing
    var is_target_killable = target.state is not Player.Dead and not target.is_invincible() and target != weapon_owner
    if not is_attacking or not is_target_killable:
        return

    # It's a hit on a parrying opponent
    if target.state is Player.Parrying:
        if state is Stabbing:
            disarm()
        elif state is Flying:
            deflect_throw(target)
        return

    # It's a kill
    if is_instance_valid(weapon_owner):
        weapon_owner.increment_kill_streak()
        # When a player kills another player with a throw, give them a new spear.
        if state is Flying:
            weapon_owner.get_new_weapon()
            weapon_owner = null

    target.kill()

func drop() -> void:
    if state is Stabbing and state.stab_tween != null:
        state.stab_tween.kill()
    
    # local rotation and position
    state = LyingOnGround.new()
    end_attack_charge()
    for connection in on_throw.get_connections():
        on_throw.disconnect(connection.callable)
    if is_instance_valid(weapon_owner):
        weapon_owner.weapon = null
    weapon_owner = null
    var main_scene = get_tree().get_root().get_node("Main")
    reparent.call_deferred(main_scene)

func stab() -> void:
    if state is Stabbing or stab_is_on_cooldown:
        return

    state = Stabbing.new()

    $Hitbox.check_now()

    var pos_before = Vector2(position)
    var stab_direction = Vector2.RIGHT.rotated(rotation) * stab_distance
    state.stab_tween = create_tween()
    state.stab_tween.tween_property(self, "position", pos_before - stab_direction * 0.4, stab_duration_seconds * 0.4)
    await state.stab_tween.finished
    state.stab_tween = create_tween()
    state.stab_tween.tween_property(self, "position", pos_before + stab_direction, stab_duration_seconds * 0.2)
    await state.stab_tween.finished
    state.stab_tween = create_tween()
    state.stab_tween.tween_property(self, "position", pos_before, stab_duration_seconds * 0.4)
    await state.stab_tween.finished
    state.stab_tween = null

    state = Carrying.new()
    stab_is_on_cooldown = true

    await get_tree().create_timer(stab_cooldown_seconds).timeout

    stab_is_on_cooldown = false

func disarm() -> void:
    if not is_instance_valid(weapon_owner):
        return

    state = Disarming.new()
    var drop_offset = Vector2.ONE.rotated(randf_range(0, 2 * PI)) * 50
    var tween = create_tween().set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "global_position", global_position + drop_offset, 0.5)
    tween.parallel().tween_property(self, "rotation", self.rotation + PI, 0.6)
    await tween.finished
    drop()

func deflect_throw(new_owner: Player) -> void:
    if not state is Flying:
        return
    weapon_owner = new_owner
    state.throw_direction = state.throw_direction.rotated(PI)
    state.throwing_range_seconds += 0.1
    rotation += PI

func bounce_back() -> void:
    var bounce_back_duration = 1.0
    var num_repeats = 3
    var tween = create_tween()
    var initial_rot = $WeaponSprite.rotation

    tween.tween_property($WeaponSprite, "rotation", initial_rot + 2 * num_repeats * PI, bounce_back_duration / (num_repeats))
    await tween.finished
    $WeaponSprite.rotation = initial_rot
