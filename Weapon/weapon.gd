extends Node2D

class_name Weapon

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

var throwing_time := 0.0
var throwing_range_seconds := 0.0
@export
var is_throwing := false
var is_stabbing := false
var stab_on_cooldown := false
var stab_tween
var throw_direction
var weapon_owner
var charging_throw_since: float
var base_weapon_scale: Vector2
var hit_bottle: bool = false

var base_weapon_position: Vector2


signal on_throw

func is_charging_throw():
    return weapon_owner and (weapon_owner as Player).state is Player.ChargingThrow

# Called when the node enters the scene tree for the first throwing_time.
func _ready() -> void:
    base_weapon_scale = $WeaponSprite.scale
    add_to_group('weapons')


# Called every frame. 'delta' is the elapsed throwing_time since the previous frame.
func _process(delta: float) -> void:
    if is_throwing:
        throwing_time += delta * time_factor
        throw_distance = throw_speed
        global_position += throw_direction * delta * throw_distance

    if throwing_time > throwing_range_seconds:
        end_throw()

    if is_charging_throw():
        charging_throw_since = min(max_throwing_range_seconds, charging_throw_since + delta)
        if charging_throw_since >= stab_button_press_threshold_seconds:
            $Highlight.visible = true
        position.x = base_weapon_position.x - charging_throw_since * 20
        $WeaponSprite.scale.x = base_weapon_scale.x + charging_throw_since * 0.2
        queue_redraw()

    if is_instance_valid(weapon_owner) and not is_throwing and not is_stabbing:
        var wobble_strength = 4
        if is_charging_throw() and is_instance_valid(weapon_owner):
            wobble_strength = 2
        position = base_weapon_position + Vector2.UP * sin(Time.get_ticks_msec() * 0.01) * wobble_strength


func _draw() -> void:
    if is_charging_throw() and is_instance_valid(weapon_owner):
        var start = Vector2.RIGHT * 30
        var direction_vector = Vector2.RIGHT * (charging_throw_since * 600)
        var end = start + direction_vector
        draw_line(start, end, weapon_owner.player_color, -1.0, true)

func release_charge() -> void:
    if charging_throw_since >= stab_button_press_threshold_seconds:
        throw()
    cancel_attack_charge()
    queue_redraw()

func cancel_attack_charge():
    charging_throw_since = 0.0
    $Highlight.visible = false
    $WeaponSprite.scale.x = base_weapon_scale.x

func throw() -> void:
    throw_direction = Vector2.RIGHT.rotated(global_rotation)
    var main_scene = get_tree().get_root().get_node("Main")
    reparent(main_scene)
    is_stabbing = false
    is_throwing = true
    throwing_range_seconds = charging_throw_since * 1.5
    $Hitbox.check_now()
    on_throw.emit()

func end_throw() -> void:
    $Hitbox.check_now()
    is_throwing = false
    throwing_time = 0
    weapon_owner = null
    
func stick() -> void:
    is_throwing = false
    throwing_time = 0
    weapon_owner = null

func attach_to_player(area) -> void:
    var player = area as Player

    if throwing_time == 0 and not is_instance_valid(player.weapon) and not is_instance_valid(weapon_owner):
        weapon_owner = player
        player.pick_up_weapon.call_deferred(self)

func hit_player(target: Player) -> void:
    # Weapon cannot kill owner and only while throwing or stabbing
    var is_attacking = is_throwing or is_stabbing
    var is_target_killable = target.state is not Player.Dead and not target.is_invincible() and target != weapon_owner
    if not is_attacking or not is_target_killable:
        return

    # It's a hit on a parrying opponent
    if target.state is Player.Parrying:
        if is_stabbing:
            disarm()
        elif is_throwing:
            deflect_throw(target)
        return

    # It's a kill
    if weapon_owner:
        weapon_owner.increment_kill_streak()
        # When a player kills another player with a throw, give them a new spear.
        if is_throwing:
            weapon_owner.get_new_weapon()
            weapon_owner = null

    target.kill()

func drop() -> void:
    cancel_attack_charge()
    if stab_tween != null:
        (stab_tween as Tween).kill()
    # position.x = base_weapon_position.x
    is_stabbing = false
    for connection in on_throw.get_connections():
        on_throw.disconnect(connection.callable)
    if is_instance_valid(weapon_owner):
        weapon_owner.weapon = null
    weapon_owner = null
    var main_scene = get_tree().get_root().get_node("Main")
    reparent.call_deferred(main_scene)

func stab() -> void:
    if is_stabbing or stab_on_cooldown:
        return

    is_stabbing = true

    $Hitbox.check_now()

    var pos_before = Vector2(position)
    var stab_direction = Vector2.RIGHT.rotated(rotation) * stab_distance
    stab_tween = create_tween()
    stab_tween.tween_property(self, "position", pos_before - stab_direction * 0.4, stab_duration_seconds * 0.4)
    await stab_tween.finished
    stab_tween = create_tween()
    stab_tween.tween_property(self, "position", pos_before + stab_direction, stab_duration_seconds * 0.2)
    await stab_tween.finished
    stab_tween = create_tween()
    stab_tween.tween_property(self, "position", pos_before, stab_duration_seconds * 0.4)
    await stab_tween.finished
    stab_tween = null

    is_stabbing = false
    stab_on_cooldown = true
    hit_bottle = false

    await get_tree().create_timer(stab_cooldown_seconds).timeout

    stab_on_cooldown = false

func disarm() -> void:
    if not is_instance_valid(weapon_owner):
        return

    drop()

    # TODO prevent pickup during this time
    var drop_offset = Vector2.ONE.rotated(randf_range(0, 2 * PI)) * 50
    var tween = create_tween().set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "global_position", global_position + drop_offset, 0.5)
    tween.parallel().tween_property(self, "rotation", self.rotation + PI, 0.6)

func deflect_throw(new_owner: Player) -> void:
    weapon_owner = new_owner
    throw_direction = throw_direction.rotated(PI)
    throwing_range_seconds += 0.1
    rotation += PI

func bounce_back() -> void:
    var bounce_back_duration = 1.0
    var num_repeats = 3
    var tween = create_tween()
    var initial_rot = $WeaponSprite.rotation

    tween.tween_property($WeaponSprite, "rotation", initial_rot + 2 * num_repeats * PI, bounce_back_duration / (num_repeats))
    await tween.finished
    $WeaponSprite.rotation = initial_rot
