extends Node2D

var minigame_scene = preload("res://Minigame/Minigame.tscn")

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
    inside_particles.lifetime = 0.8
    inside_particles.emitting = false

    bottleneck_particles.emitting = true
    pop_particles.emitting = true
    await get_tree().create_timer(1.0).timeout
    bottleneck_particles.emitting = false
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

    start_minigame(area)

func start_minigame(player: Player):
    if player.is_in_minigame:
        return

    var minigame = minigame_scene.instantiate()
    minigame.color = player.player_color
    minigame.device = player.device
    player.is_in_minigame = true
    player.add_child(minigame)
    await minigame.finished
    player.is_in_minigame = false
    minigame.queue_free()

func get_bottle_floor(offset: int) -> Vector2:
    var bottle_size = $Sprite2D.get_rect().size
    return to_global(Vector2(0, (bottle_size.y / 2) + offset))
