extends Node2D

class_name GooglyEye

# the time factor variable speeds up the googleronies movement, if increased
@export
var time_factor := 1000

var raising = false
var blinking = false

@onready
var base_eye_position = Vector2(position)

@onready
var base_eye_scale  = Vector2(scale)

var eye_tween 

func reset() -> void:
    position = base_eye_position
    scale = base_eye_scale

    if is_instance_valid(eye_tween):
        eye_tween.stop()
        eye_tween = null
        print("tween stopped")

func walking_animation() -> void:
    $LeftOuter.position.y = sin(Time.get_ticks_msec() * time_factor) 
    $RightOuter.position.y = -sin(Time.get_ticks_msec() * time_factor) 
    
func raise_eye() -> void:
    var stretch = 2
    var dur = 0.2

    if not is_instance_valid(eye_tween):
        eye_tween = get_tree().create_tween()
        eye_tween.tween_property(self, "scale:y", base_eye_scale.y * stretch, dur)
