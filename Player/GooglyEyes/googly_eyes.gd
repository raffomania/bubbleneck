extends Node2D

class_name GogglyEyes

# the time factor variable speeds up the googleronies movement, if increased
@export
var time_factor := 1
# this variable always grows
var eternal_time_variable := 0.0

var raising = false
var blinking = false

var base_right_eye_position

var base_left_eye_position

func _ready() -> void:
    base_right_eye_position = $LeftOuter.position
    base_left_eye_position = $RightOuter.position

func _process(delta: float) -> void:
    eternal_time_variable += delta

func set_player_direction(dir: Vector2, delta: float) -> void:
    var strength = dir.length()
    $LeftOuter/LeftInner.position.y = strength * delta * 5000
    $RightOuter/RightInner.position.y = strength * delta * 5000

func reset_googly_position() -> void:
    $LeftOuter.position = base_right_eye_position
    $RightOuter.position = base_left_eye_position

func walking_animation() -> void:
    $LeftOuter.position.y -= sin(eternal_time_variable * time_factor) * 0.5
    # $LeftOuter.scale.x += sin(eternal_time_variable * time_factor * 0.5) * 0.001
    # $RightOuter.scale.y -= sin(eternal_time_variable * time_factor * 0.5) * 0.001
    $RightOuter.position.y += sin(eternal_time_variable * time_factor) * 0.5
    
func raise_eye() -> void:
    if raising:
        return
    raising = true
    var prevL = ($LeftOuter as Node2D).scale.y
    var prevR = ($RightOuter as Node2D).scale.y
    ($RightOuter as Node2D).scale.y *= 2.0
    ($LeftOuter as Node2D).scale.y *= 2.0
    await get_tree().create_timer(0.2).timeout
    ($RightOuter as Node2D).scale.y = prevL
    ($LeftOuter as Node2D).scale.y = prevR
    raising = false
    
func blink(duration: float) -> void:
    if blinking:
        return
    blinking = true
    var prevL = ($LeftOuter as Node2D).scale.y
    var prevR = ($RightOuter as Node2D).scale.y
    ($RightOuter as Node2D).scale.y = 0.0
    ($LeftOuter as Node2D).scale.y = 0.0
    await get_tree().create_timer(duration).timeout
    ($RightOuter as Node2D).scale.y = prevL
    ($LeftOuter as Node2D).scale.y = prevR
    
    blinking = false

func kill():
    visible = false

func respawn():
    visible = true

