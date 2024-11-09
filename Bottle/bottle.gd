extends Node2D

# Describes whether the Bottle is popped.
var popped = false
# Seconds until bottle pops.
var pop_countdown = 0
# Min/Max Time until bottle pops.
var pop_countdown_min = 30
var pop_countdown_max = 60

# The current rotational speed of the bottle
var rotation_speed: float = 0.5
# The max speed with which the bottle can rotate.
# `1` equals rotation per second in radians.
var max_rotation_speed: float = 1

var bottleneck_particles: GPUParticles2D
var pop_particles: GPUParticles2D
var inside_particles: GPUParticles2D

@onready
var entrance_area: Area2D = $EntranceArea
@onready
var bottle_cap: Sprite2D = $BottleCap
@onready
var body_area: Area2D = $BodyArea

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # center the bottle
    var viewport = get_viewport_rect()

    position.x = viewport.size.x / 2
    position.y = viewport.size.y / 2

    var rng = RandomNumberGenerator.new()
    rng.seed = Time.get_unix_time_from_system()
    pop_countdown = rng.randi_range(pop_countdown_min, pop_countdown_max)

    bottleneck_particles = $BottleneckParticles
    pop_particles = $PopParticles
    inside_particles = $Sprite2D/InsideParticles
    entrance_area.area_entered.connect(_on_area_entered_entrance)
    body_area.area_entered.connect(_on_area_entered_body)


 
func _process(delta: float) -> void:
    if not popped:
        rotation += rotation_speed * delta
        pop_countdown -= delta

    # Check if the bottle should pop.
    if pop_countdown <= 0 or Input.is_action_just_pressed("debug_pop_bottle"):
        popped = true
        pop_bottle()


# Emits the popping particles.
func pop_bottle() -> void:
    bottle_cap.visible = false
    inside_particles.lifetime = 1
    inside_particles.emitting = false

    bottleneck_particles.emitting = true
    await get_tree().create_timer(0.7).timeout
    pop_particles.emitting = true
    await get_tree().create_timer(0.3).timeout
    bottleneck_particles.emitting = false
    # without this it breaks. do not ask why.
    await get_tree().create_timer(0.6).timeout
    pop_particles.emitting = false

# Call this to hit the bottle.
# Reduces the countdown until pop and adds some impulse to the bottle.
#
# `impulse`: equals the added rotations per second in radian.
# `countdown_reduction` (Optional): Set an explicit value for the countdown reduction.
#                                   If not provided, the impulse will be used to calculate this value.
func hit(impulse: float, countdown_reduction = null) -> void:
    if countdown_reduction != null:
        pop_countdown -= countdown_reduction
    else:
        pop_countdown -= impulse
    add_impulse(impulse)

# Adds an impulse to the rotation of the bottle.
# The impulse cannot be faster than `max_rotation_speed`.
#
# `impulse`: equals the added rotations per second in radian.
func add_impulse(impulse: float) -> void:
    rotation_speed += impulse

    # Limit the bottle rotation to the max possible speed
    if rotation_speed > max_rotation_speed:
        rotation_speed = max_rotation_speed
    elif rotation_speed < -max_rotation_speed:
        rotation_speed = -max_rotation_speed

func _on_area_entered_entrance(area: Area2D) -> void:
    if not is_instance_of(area, Player) or not popped:
        return

    var player = area as Player
    var minigame = player.start_minigame()
    minigame.finished.connect(func(): self.minigame_finished(player, minigame))


func minigame_finished(player, minigame):
    minigame.queue_free()

    var camera = get_tree().root.get_camera_2d()
    var zoom_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
    zoom_tween.tween_property(camera, "zoom", Vector2(5, 5), 3.0)

    create_tween().tween_property(player, "rotation", player.rotation + PI * 2, 2.0)

    var tween = create_tween()
    tween.tween_property(player, "global_position", entrance_area.global_position, 0.4)
    await tween.finished

    tween = create_tween().parallel()
    tween.tween_property(player, "scale", player.scale * 0.6, 1.0)
    tween.tween_property(player, "global_position", global_position, 2.0)

    await zoom_tween.finished
    get_tree().root.get_node("Main").restart()

func _on_area_entered_body(area: Area2D) -> void:
    if is_instance_of(area, Player):
        var player = area
        var direction = player.global_position - get_viewport_rect().size / 2
        var strenght_factor = 1
        player.bounce_back(direction * strenght_factor)


func get_bottle_floor(offset: int) -> Vector2:
    var bottle_size = $Sprite2D.get_rect().size
    return to_global(Vector2(0, (bottle_size.y / 2) + offset))
