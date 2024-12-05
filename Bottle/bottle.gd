extends Node2D

class_name Bottle

# Seconds until bottle pops.
var pop_countdown = 0
var pop_countdown_start = 0
# Min/Max Time until bottle pops.
var pop_countdown_min = 20
var pop_countdown_max = 40
# Min/Max rate at which the countdown runs.
var pop_countdown_min_speed = 0.5
var pop_countdown_max_speed = 1.5

var shake_bottle_from_hit = false

# Sudden death

# The current rotational speed of the bottle
var rotation_speed: float = 0.5
# The max speed with which the bottle can rotate.
# `1` equals rotation per second in radians.
var max_rotation_speed: float = 1
@export
var movement_type: String = "spin"

var bottleneck_particles: GPUParticles2D
var pop_particles: GPUParticles2D
var max_inner_particle_lifetime = 10.0
var min_inner_particle_lifetime = 0.01
var min_lifetime_start_time = 12.0
var inside_particles: GPUParticles2D

# Parameters to adjust the shaking effect 
var max_shake_intensity = 5.0 # Maximum shake amount in pixels
var shake_start_time = 8
var viewpoint_center: Vector2

var player_has_entered := false
var minigame = null

@onready
var entrance_area: Area2D = $EntranceArea
@onready
var bottle_cap: Sprite2D = $BottleCap
@onready
var body_area: Area2D = $BodyArea
@onready
var top_left_area: Area2D = $BodyTopLeft
@onready
var top_right_area: Area2D = $BodyTopRight
@onready
var bottom_left_area: Area2D = $BodyBottomLeft
@onready
var bottom_right_area: Area2D = $BodyBottomRight

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # center the bottle
    var viewport = get_viewport_rect()

    viewpoint_center = Vector2(viewport.size.x / 2, viewport.size.y / 2)
    position = viewpoint_center

    var rng = RandomNumberGenerator.new()
    rng.seed = Time.get_unix_time_from_system()
    pop_countdown = rng.randi_range(pop_countdown_min, pop_countdown_max)
    pop_countdown_start = pop_countdown

    bottleneck_particles = $BottleneckParticles
    pop_particles = $PopParticles
    inside_particles = $Line2D/InsideParticles
    entrance_area.area_entered.connect(_on_area_entered_entrance)
    body_area.area_entered.connect(_on_area_entered_body)
    top_left_area.area_entered.connect(_on_top_left_entered_body)
    top_right_area.area_entered.connect(_on_top_right_entered_body)
    bottom_left_area.area_entered.connect(_on_bottom_left_entered_body)
    bottom_right_area.area_entered.connect(_on_bottom_right_entered_body)
    
func process_popped_bottle(delta: float) -> void:
    Globals.state.sudden_death_countdown -= delta

    if Globals.state.sudden_death_countdown <= 0:
        Globals.state = Globals.SuddenDeath.new()
        var players = get_tree().get_nodes_in_group('players')
        var player_angle = 0
        for node in players:
            var player = node as Player
            if player.state is Player.Dead:
                player.respawn()
            if player.state is Player.InMinigame:
                player.stop_minigame()
            node.position = viewpoint_center + Vector2.from_angle(player_angle) * 400
            player_angle += (2 * PI) / players.size()


func _process(delta: float) -> void:
    if Globals.state is Globals.SuddenDeath:
        var players = get_tree().get_nodes_in_group('players')
        if players.all(func(player: Player): return player.state is Player.Dead):
            Globals.state = Globals.Tie.new()
            var camera = get_tree().root.get_camera_2d()
            var zoom_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
            zoom_tween.tween_property(camera, "zoom", Vector2(10, 10), 3.0)
            await zoom_tween.finished
            get_tree().root.get_node("Main").next_stage()
        
    if Globals.state is not Globals.RoundRunning:
        return 

    if Globals.state.popped:
        process_popped_bottle(delta)
        return

    if movement_type == "spin":
        spin(delta)
    elif movement_type == "orbit":
        orbit(delta)
    elif movement_type == "spin_orbit":
        spin_orbit(delta)

    # Calculate countdown and countdown speed depending on rotation speed.
    var pop_countdown_speed = (abs(rotation_speed) / max_rotation_speed) * pop_countdown_max_speed + pop_countdown_min_speed
    pop_countdown -= delta * pop_countdown_speed
    #print("Countdown: %s, Speed: %s, Rotation: %s" % [pop_countdown, pop_countdown_speed, rotation_speed])

    # Calculate particle lifetime depending on pop countdown.
    var countdown_percentage = pop_countdown / pop_countdown_start
    inside_particles.lifetime = max_inner_particle_lifetime * countdown_percentage + min_inner_particle_lifetime

    # Calculate the new lifetime of the particles inside the bottle based on the countdown
    if pop_countdown > min_lifetime_start_time:
        inside_particles.lifetime = lerp(min_inner_particle_lifetime, max_inner_particle_lifetime, (pop_countdown - min_lifetime_start_time) / (pop_countdown_start - min_lifetime_start_time))
    else:
        # Stop decreasing at minimum lifetime
        inside_particles.lifetime = min_inner_particle_lifetime

    # Reset position to original position if pop countdown is zero
    if pop_countdown == 0:
        position = Vector2(0, 0) + viewpoint_center

    var shake_intensity = 0
    if pop_countdown < shake_start_time:
        shake_intensity = lerp(0.0, max_shake_intensity, 1 - (pop_countdown / shake_start_time))

    if shake_bottle_from_hit:
        shake_intensity = lerp(0.0, max_shake_intensity, 1)

    # Apply random shake to position
    if shake_intensity > 0:
        var shake_x = randf_range(-shake_intensity, shake_intensity)
        var shake_y = randf_range(-shake_intensity, shake_intensity)
        position = Vector2(shake_x, shake_y) + position

    # Check if the bottle should pop.
    if pop_countdown <= 0 or Input.is_action_just_pressed("debug_pop_bottle"):
        pop_bottle()
    return

# Emits the popping particles.
func pop_bottle() -> void:
    if Globals.state is not Globals.RoundRunning:
        return

    Globals.state.popped = true
    bottle_cap.visible = false
    inside_particles.lifetime = 1
    inside_particles.emitting = false

    $AudioStreamPlayer2D.play()
    bottleneck_particles.emitting = true
    await get_tree().create_timer(0.7).timeout
    pop_particles.emitting = true
    await get_tree().create_timer(0.3).timeout
    bottleneck_particles.emitting = false
    # without this it breaks. do not ask why.
    await get_tree().create_timer(0.6).timeout
    pop_particles.emitting = false

    Globals.state.sudden_death_countdown = Globals.state.sudden_death_timeout

# Call this to hit the bottle.
# Reduces the countdown until pop and adds some impulse to the bottle.
#
# `impulse`: equals the added rotations per second in radian.
func hit(impulse: float) -> void:
    add_impulse(impulse)

    $AudioStreamPlayer2DBottleSound.play()

    pop_countdown = max(0, pop_countdown - 1)
    shake_bottle_from_hit = true
    await get_tree().create_timer(0.1).timeout
    shake_bottle_from_hit = false

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
    if not (Globals.state is Globals.SuddenDeath or Globals.state is Globals.RoundRunning and Globals.state.popped): 
        return
    if not is_instance_of(area, Player) or player_has_entered or minigame_in_progress():
        return

    var player = area as Player
    minigame = player.start_minigame()

    var tween = create_tween()
    tween.tween_property(player, "global_position", entrance_area.global_position, 0.2)

    if is_instance_valid(minigame):
        minigame.finished.connect(func(): self.minigame_finished(player))

func minigame_in_progress() -> bool:
    return is_instance_valid(minigame)


func minigame_finished(player: Player):
    if player_has_entered:
        return

    player_has_entered = true

    get_tree().root.get_node('Main').get_node('ScoringSystem').increase_score(player)

    # wait for minigame to disappear
    await get_tree().create_timer(1.0).timeout

    var camera = get_tree().root.get_camera_2d()
    var zoom_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
    zoom_tween.tween_property(camera, "zoom", Vector2(10, 10), 3.0)

    create_tween().tween_property(player, "rotation", player.rotation + PI * 2, 2.0)

    var tween = create_tween()
    tween.tween_property(player, "global_position", global_position, 2.0)
    tween.parallel().tween_property(player, "scale", player.scale * 0.6, 1.0)
    await zoom_tween.finished

    get_tree().root.get_node("Main").next_stage()

func _on_area_entered_body(area: Area2D) -> void:
    if is_instance_of(area, Player) and not player_has_entered:
        var player = area
        var direction = (player.global_position - position).normalized()
        var strenght_factor = 100
        player.bounce_back(direction * strenght_factor)
       
func _on_top_left_entered_body(area: Area2D) -> void:
    hit_bottle(area, "topleft")

func _on_top_right_entered_body(area: Area2D) -> void:
    hit_bottle(area, "topright")

func _on_bottom_left_entered_body(area: Area2D) -> void:
    hit_bottle(area, "bottomleft")

func _on_bottom_right_entered_body(area: Area2D) -> void:
    hit_bottle(area, "bottomright")

func hit_bottle(area: Area2D, direction: String) -> void:
    var impulse_direction = 0
    if direction == "topleft":
        impulse_direction = 1
    elif direction == "topright":
        impulse_direction = -1
    elif direction == "bottomleft":
        impulse_direction = -1
    elif direction == "bottomright":
        impulse_direction = 1
    
    if is_instance_of(area, WeaponHitbox) and not player_has_entered:
        var weapon = area.get_parent() as Weapon
        if weapon.is_throwing or weapon.is_stabbing:
            #print("Hit impulse %s from direction %s" % [impulse_direction, direction])
            weapon.hit_bottle = true
            hit(0.25 * impulse_direction)

func get_bottle_floor(offset: int) -> Vector2:
    var bottle_size = $Line2D.get_viewport_rect().size
    return to_global(Vector2(0, (bottle_size.y / 2) + offset))

func spin(delta):
    rotation += rotation_speed * delta
    position = viewpoint_center

    if rotation_speed > 0:
        rotation_speed -= delta * 0.05
    elif rotation_speed < 0:
        rotation_speed += delta * 0.05

func orbit(delta):
    rotation += rotation_speed * delta
    var radius = viewpoint_center.y
    position = Vector2(cos(rotation + PI / 2) * radius, sin(rotation + PI / 2) * radius) + viewpoint_center

    if rotation_speed > 0:
        rotation_speed -= delta * 0.05
    elif rotation_speed < 0:
        rotation_speed += delta * 0.05

func spin_orbit(delta):
    rotation += rotation_speed * delta
    var radius = viewpoint_center.y / 2
    position = Vector2(sin(rotation) * radius, cos(rotation) * radius) + viewpoint_center

    if rotation_speed > 0:
        rotation_speed -= delta * 0.05
    elif rotation_speed < 0:
        rotation_speed += delta * 0.05

func get_respawn_position():
    # Apply a random offset to the spawn position
    var rand_offset = Vector2(randf() * 100 - 50, randf() * 100 - 50)

    if movement_type == 'spin':
        return get_bottle_floor(200) + rand_offset
    elif movement_type == 'spin_orbit':
        return viewpoint_center + -1 * (position - viewpoint_center) + rand_offset
    elif movement_type == 'orbit':
        return viewpoint_center + -1 * (position - viewpoint_center) + rand_offset
