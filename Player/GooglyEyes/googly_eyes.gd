extends Node2D

class_name GogglyEyes

# the time factor variable speeds up the googleronies movement, if increased
@export
var time_factor := 1000

var raising = false
var blinking = false

@onready
var base_right_eye_position = Vector2($RightOuter.position)
@onready
var base_left_eye_position = Vector2($LeftOuter.position)
@onready
var base_left_eye_scale  = Vector2($LeftOuter.scale)
@onready
var base_right_eye_scale  = Vector2($RightOuter.scale)

var left_eye_tween 
var right_eye_tween 

func set_player_direction(dir: Vector2, delta: float) -> void:
    var strength = dir.length()
    $LeftOuter/LeftInner.position.y = strength * delta * 5000
    $RightOuter/RightInner.position.y = strength * delta * 5000

func reset() -> void:
    $LeftOuter.position = base_right_eye_position
    $RightOuter.position = base_left_eye_position
    $LeftOuter.scale = base_left_eye_scale
    $RightOuter.scale = base_right_eye_scale

    if is_instance_valid(left_eye_tween):
        left_eye_tween.stop()
        left_eye_tween = null

    if is_instance_valid(right_eye_tween):
        right_eye_tween.stop()
        right_eye_tween = null


func walking_animation() -> void:
    $LeftOuter.position.y = sin(Time.get_ticks_msec() * time_factor) 
    $RightOuter.position.y = -sin(Time.get_ticks_msec() * time_factor) 
    
func raise_eye() -> void:
    var stretch = 2
    var dur = 0.2

    if not is_instance_valid(right_eye_tween):
        right_eye_tween = get_tree().create_tween()
        right_eye_tween.tween_property($RightOuter, "scale:y", base_right_eye_scale.y * stretch, dur)

    if not is_instance_valid(left_eye_tween):
        left_eye_tween = get_tree().create_tween()
        left_eye_tween.tween_property($LeftOuter, "scale:y", base_left_eye_scale.y * stretch, dur)

    
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

