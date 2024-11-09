extends Area2D

@export
var throw_distance := 0.0
@export
var throw_curve: Curve
@export
var time_factor := 1.0
@export
var throw_range_factor := 1.0
@export
var stab_cooldown_seconds: float
@export
var stab_duration_seconds: float
@export
var stab_button_press_threshold_seconds: float
@export
var stab_distance: int = 30
@export
var base_weapon_position: Vector2
@export
var max_throwing_range_seconds: float

var throwing_time := 0.0
var throwing_range_seconds := 0.0
@export
var is_throwing := false
var is_stabbing := false
var stab_on_cooldown := false
var dir
var weapon_owner
var attack_button_pressed := false
var attack_button_pressed_since: float

signal on_throw

# Called when the node enters the scene tree for the first throwing_time.
func _ready() -> void:
    area_entered.connect(_on_area_entered)
    add_to_group('weapons')


# Called every frame. 'delta' is the elapsed throwing_time since the previous frame.
func _process(delta: float) -> void:
    if is_throwing:
        throwing_time += delta * time_factor
        var curve_value = throw_curve.sample(throwing_time)
        throw_distance = curve_value * throw_range_factor
        global_position += dir * delta * throw_distance

    if throwing_time > throwing_range_seconds:
        is_throwing = false
        throwing_time = 0

    if attack_button_pressed:
        attack_button_pressed_since = min(max_throwing_range_seconds, attack_button_pressed_since + delta)
        position.x = base_weapon_position.x - attack_button_pressed_since * 20


func set_attack_button_pressed(now_pressed: bool) -> void:
    var just_pressed = not attack_button_pressed and now_pressed
    var just_released = attack_button_pressed and not now_pressed
    if just_pressed:
        attack_button_pressed = true
    if just_released:
        if attack_button_pressed_since < stab_button_press_threshold_seconds:
            stab()
        else:
            throw()
        attack_button_pressed = false
        attack_button_pressed_since = 0.0

func throw() -> void:
    dir = Vector2(0, -1).rotated(global_rotation)
    var main_scene = get_tree().get_root().get_node("Main")
    reparent(main_scene)
    is_throwing = true
    throwing_range_seconds = attack_button_pressed_since
    weapon_owner = null
    on_throw.emit()
    
func stick() -> void:
    is_throwing = false
    throwing_time = 0


func _on_area_entered(area) -> void:
    if not is_instance_of(area, Player):
        return

    var player = area as Player
    if throwing_time <= 1 and throwing_time > 0 and not player == weapon_owner:
         player.kill()

    if throwing_time == 0 and not is_instance_valid(player.weapon) and not is_instance_valid(weapon_owner):
        weapon_owner = player
        player.pick_up_weapon.call_deferred(self)

    if is_stabbing:
        player.kill()

func stab() -> void:
    if is_stabbing or stab_on_cooldown:
        return

    is_stabbing = true

    var x_before = position.x
    position.x += stab_distance

    await get_tree().create_timer(stab_duration_seconds).timeout

    position.x = x_before
    is_stabbing = false
    stab_on_cooldown = true

    await get_tree().create_timer(stab_cooldown_seconds).timeout

    stab_on_cooldown = false
