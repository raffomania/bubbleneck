extends Node2D

class_name Weapon

@export
var throw_distance := 0.0
@export
var throw_curve: Curve
@export
var time_factor := 1.0
@export
var throw_range_factor := 1.0
@export
var stab_cooldown_seconds: float = 0.5
@export
var stab_duration_seconds: float
@export
var stab_button_press_threshold_seconds: float
@export
var stab_distance: float = 50
@export
var base_weapon_position: Vector2
@export
var max_throwing_range_seconds: float

var throwing_time := 0.0
var throwing_range_seconds := 0.0
@export
var is_throwing := false
var is_checking_for_throw_collisions := false
var is_stabbing := false
var stab_on_cooldown := false
var dir
var weapon_owner
var attack_button_pressed := false
var attack_button_pressed_since: float
var base_weapon_scale: Vector2
var hit_bottle: bool = false

signal on_throw

# Called when the node enters the scene tree for the first throwing_time.
func _ready() -> void:
    base_weapon_scale = $WeaponSprite.scale
    add_to_group('weapons')


# Called every frame. 'delta' is the elapsed throwing_time since the previous frame.
func _process(delta: float) -> void:
    if is_throwing:
        throwing_time += delta * time_factor
        var curve_value = throw_curve.sample(throwing_time)
        throw_distance = curve_value * throw_range_factor
        global_position += dir * delta * throw_distance

    if throwing_time > throwing_range_seconds:
        $Hitbox.check_now()
        is_throwing = false

        await get_tree().create_timer(0.2).timeout
        throwing_time = 0
        weapon_owner = null
        is_checking_for_throw_collisions = false

    if attack_button_pressed:
        attack_button_pressed_since = min(max_throwing_range_seconds, attack_button_pressed_since + delta)
        if attack_button_pressed_since >= stab_button_press_threshold_seconds:
            $Highlight.visible = true
        position.x = base_weapon_position.x - attack_button_pressed_since * 20
        $WeaponSprite.scale.x = base_weapon_scale.x + attack_button_pressed_since * 0.2
        queue_redraw()


func _draw() -> void:
    if attack_button_pressed and weapon_owner:
        var rotation = Vector2.from_angle(PI / 2 + 0.07)
        var start = Vector2.ZERO
        var direction_vector = rotation * (attack_button_pressed_since * 300 )
        var end = position - direction_vector
        draw_line(start, end, weapon_owner.player_color, -1.0, true)
        print("Start %s, Owner: %s, Rotation %s, Pressed since %s, Direction %s, End %s" % [start, weapon_owner.rotation, rotation, attack_button_pressed_since , direction_vector, end])


func set_attack_button_pressed(now_pressed: bool) -> void:
    var just_pressed = not attack_button_pressed and now_pressed
    var just_released = attack_button_pressed and not now_pressed

    if just_pressed:
        attack_button_pressed = true
    if just_released:
        $WeaponSprite.scale.x = base_weapon_scale.x
        $Highlight.visible = false
        if attack_button_pressed_since >= stab_button_press_threshold_seconds:
            throw()
        attack_button_pressed = false
        attack_button_pressed_since = 0.0

func cancel_attack_charge():
    attack_button_pressed = false
    attack_button_pressed_since = 0.0
    $Highlight.visible = false
    $WeaponSprite.scale.x = base_weapon_scale.x
    position.x = base_weapon_position.x

func throw() -> void:
    dir = Vector2(0, -1).rotated(global_rotation)
    var main_scene = get_tree().get_root().get_node("Main")
    reparent(main_scene)
    is_throwing = true
    is_checking_for_throw_collisions = true
    throwing_range_seconds = attack_button_pressed_since
    $Hitbox.check_now()
    on_throw.emit()
    
func stick() -> void:
    is_throwing = false
    is_checking_for_throw_collisions = false
    throwing_time = 0
    weapon_owner = null


func attach_to_player(area) -> void:
    var player = area as Player

    if throwing_time == 0 and not is_instance_valid(player.weapon) and not is_instance_valid(weapon_owner):
        weapon_owner = player
        player.pick_up_weapon.call_deferred(self)

func hit_player(player: Player) -> void:
    # Weapon cannot kill owner and only while throwing or stabbing
    if not player == weapon_owner and (is_checking_for_throw_collisions or is_stabbing):
        print(player, weapon_owner)
        player.kill()

        # When a player kills another player with a throw, give them a new spear.
        if is_throwing and not player.is_invincible():
            if weapon_owner:
                weapon_owner.get_new_weapon()
                weapon_owner = null

func drop() -> void:
    for connection in on_throw.get_connections():
        on_throw.disconnect(connection.callable)
    weapon_owner = null
    var main_scene = get_tree().get_root().get_node("Main")
    reparent.call_deferred(main_scene)

func stab() -> void:
    if is_stabbing or stab_on_cooldown:
        return

    is_stabbing = true

    $Hitbox.check_now()

    var pos_before = Vector2(position)
    var tween = create_tween().tween_property(self, "position", position + Vector2(stab_distance, 0), stab_duration_seconds / 2)
    await tween.finished
    tween = create_tween().tween_property(self, "position", pos_before, stab_duration_seconds / 2)
    await tween.finished

    is_stabbing = false
    stab_on_cooldown = true
    hit_bottle = false

    await get_tree().create_timer(stab_cooldown_seconds).timeout

    stab_on_cooldown = false
